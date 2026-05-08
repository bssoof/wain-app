import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as functions from "firebase-functions/v1";

const QUOTE_TTL_MS = 120000;
const MAX_DISTANCE_METERS = 100000;
const MAX_QUOTES_PER_REQUEST = 6;
const ROAD_DISTANCE_MULTIPLIER = 1.3;
const DEFAULT_ALLOWED_DEEP_LINK_SCHEMES = new Set(["https"]);
const KNOWN_TRANSPORT_APP_SCHEMES = new Set([
  "uber",
  "lyft",
  "careem",
  "bolt",
]);
const REJECTED_DEEP_LINK_SCHEMES = new Set([
  "javascript",
  "file",
  "intent",
  "data",
  "ftp",
  "about",
  "vbscript",
]);
const MIGRATION_ALLOWED_HTTPS_HOSTS = [
  "wa.me",
  "api.whatsapp.com",
  "uber.com",
  "*.uber.com",
  "lyft.com",
  "*.lyft.com",
  "careem.com",
  "*.careem.com",
  "bolt.eu",
  "*.bolt.eu",
];

function getDb(): FirebaseFirestore.Firestore {
  return admin.firestore();
}


type QuoteSource = "managed" | "api" | "cached";
type PriceConfidence = "estimate" | "fixed";
type HandoffType = "deep_link" | "whatsapp" | "phone" | "api";

type QuoteRecord = {
  quote_id: string;
  quote_log_id: string;
  venue_id: string;
  partner_id: string;
  partner_name: string;
  service_type: string;
  estimated_price: number;
  price_min: number;
  price_max: number;
  currency: string;
  eta_minutes: number;
  trip_minutes: number;
  generated_at: Timestamp;
  expires_at: Timestamp;
  price_confidence: PriceConfidence;
  quote_source: QuoteSource;
  pricing_version: string;
  handoff_type: HandoffType;
  origin_lat: number;
  origin_lng: number;
  destination_lat: number;
  destination_lng: number;
  destination_name: string;
  contact_phone: string;
  contact_whatsapp: string;
  deep_link_url_template: string;
  deep_link_allowed_schemes?: string[];
  deep_link_allowed_hosts?: string[];
  deep_link_allowlist_configured?: boolean;
  source: string;
};

type DeepLinkPolicy = {
  partnerId?: string;
  allowedSchemes?: string[];
  allowedHosts?: string[];
  allowlistConfigured?: boolean;
};

function requireAppCheck(
  context: functions.https.CallableContext,
  message: string = "App Check verification failed",
): void {
  if (!context.app) {
    throw new functions.https.HttpsError("failed-precondition", message);
  }
}

function normalizeString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeCityKey(value: unknown): string {
  return normalizeString(value).toLowerCase();
}

function normalizeStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => normalizeString(item))
    .filter((item) => item.length > 0);
}

function normalizeDeepLinkScheme(value: string): string {
  return value.trim().toLowerCase().replace(/:$/, "");
}

function normalizeDeepLinkHostPattern(value: string): string {
  const trimmed = value.trim().toLowerCase();
  if (!trimmed) {
    return "";
  }

  const withoutScheme = trimmed.includes("://")
    ? (() => {
        try {
          return new URL(trimmed).hostname;
        } catch {
          return "";
        }
      })()
    : trimmed;
  return withoutScheme
    .split("/")[0]
    .replace(/:\d+$/, "")
    .replace(/\.$/, "");
}

function normalizeDeepLinkSchemes(value: unknown): string[] {
  return normalizeStringArray(value)
    .map(normalizeDeepLinkScheme)
    .filter((scheme) => scheme.length > 0);
}

function normalizeDeepLinkHostPatterns(value: unknown): string[] {
  return normalizeStringArray(value)
    .map(normalizeDeepLinkHostPattern)
    .filter((host) => host.length > 0);
}

function partnerDeepLinkPolicyConfigured(
  partnerData: FirebaseFirestore.DocumentData,
): boolean {
  return (
    "allowed_schemes" in partnerData ||
    "allowedSchemes" in partnerData ||
    "deep_link_allowed_schemes" in partnerData ||
    "deepLinkAllowedSchemes" in partnerData ||
    "allowed_hosts" in partnerData ||
    "allowedHosts" in partnerData ||
    "deep_link_allowed_hosts" in partnerData ||
    "deepLinkAllowedHosts" in partnerData
  );
}

function buildPartnerDeepLinkPolicy(
  partnerId: string,
  partnerData: FirebaseFirestore.DocumentData,
): DeepLinkPolicy {
  return {
    partnerId,
    allowedSchemes: normalizeDeepLinkSchemes(
      partnerData.allowed_schemes ??
        partnerData.allowedSchemes ??
        partnerData.deep_link_allowed_schemes ??
        partnerData.deepLinkAllowedSchemes,
    ),
    allowedHosts: normalizeDeepLinkHostPatterns(
      partnerData.allowed_hosts ??
        partnerData.allowedHosts ??
        partnerData.deep_link_allowed_hosts ??
        partnerData.deepLinkAllowedHosts,
    ),
    allowlistConfigured: partnerDeepLinkPolicyConfigured(partnerData),
  };
}

function hostMatchesPattern(host: string, pattern: string): boolean {
  const normalizedPattern = normalizeDeepLinkHostPattern(pattern);
  if (!normalizedPattern) {
    return false;
  }
  if (normalizedPattern.startsWith("*.")) {
    const suffix = normalizedPattern.slice(1);
    const apex = normalizedPattern.slice(2);
    return host === apex || host.endsWith(suffix);
  }
  return host === normalizedPattern;
}

function isHostAllowed(host: string, patterns: string[]): boolean {
  return patterns.some((pattern) => hostMatchesPattern(host, pattern));
}

export function validateDeepLinkUrl(
  finalUrl: string,
  partner: DeepLinkPolicy = {},
): void {
  let parsed: URL;
  try {
    parsed = new URL(finalUrl);
  } catch {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "transport_deep_link_invalid_url",
    );
  }

  const scheme = normalizeDeepLinkScheme(parsed.protocol);
  if (REJECTED_DEEP_LINK_SCHEMES.has(scheme)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "transport_deep_link_scheme_rejected",
    );
  }

  const configuredSchemes = normalizeDeepLinkSchemes(partner.allowedSchemes);
  const configuredHosts = normalizeDeepLinkHostPatterns(partner.allowedHosts);
  const allowlistConfigured =
    partner.allowlistConfigured === true ||
    configuredSchemes.length > 0 ||
    configuredHosts.length > 0;
  const allowedSchemes = new Set(DEFAULT_ALLOWED_DEEP_LINK_SCHEMES);
  for (const configuredScheme of configuredSchemes) {
    if (KNOWN_TRANSPORT_APP_SCHEMES.has(configuredScheme)) {
      allowedSchemes.add(configuredScheme);
    }
  }

  if (!allowedSchemes.has(scheme)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "transport_deep_link_scheme_not_allowed",
    );
  }

  if (scheme !== "https") {
    return;
  }

  const host = parsed.hostname.toLowerCase();
  if (configuredHosts.length > 0 && isHostAllowed(host, configuredHosts)) {
    return;
  }

  if (
    !allowlistConfigured &&
    isHostAllowed(host, MIGRATION_ALLOWED_HTTPS_HOSTS)
  ) {
    functions.logger.warn("transport_deep_link_migration_allowlist_used", {
      partnerId: partner.partnerId ?? null,
      host,
    });
    return;
  }

  throw new functions.https.HttpsError(
    "invalid-argument",
    "transport_deep_link_host_not_allowed",
  );
}

function toFiniteNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return null;
}

function toSafeInt(value: unknown, fallback: number): number {
  const num = toFiniteNumber(value);
  if (num == null) return fallback;
  return Math.max(0, Math.round(num));
}

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

function sanitizePhone(value: string): string {
  return value.replace(/[^\d+]/g, "");
}

function sanitizeWhatsApp(value: string): string {
  return value.replace(/[^\d]/g, "");
}

function isValidLatitude(value: number): boolean {
  return Number.isFinite(value) && value >= -90 && value <= 90;
}

function isValidLongitude(value: number): boolean {
  return Number.isFinite(value) && value >= -180 && value <= 180;
}

function toOriginGeohash(lat: number, lng: number): string {
  return `${lat.toFixed(2)}:${lng.toFixed(2)}`;
}

function haversineDistanceMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRadians = (deg: number) => deg * Math.PI / 180;
  const earthRadiusMeters = 6371000;
  const deltaLat = toRadians(lat2 - lat1);
  const deltaLng = toRadians(lng2 - lng1);

  const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

async function enforceTransportRateLimit(
  bucketPrefix: string,
  actorId: string,
  limit: number,
): Promise<void> {
  const bucketId = `${bucketPrefix}_${actorId}_${Math.floor(Date.now() / 60000)}`;
  const rateRef = getDb().collection("rate_limits").doc(bucketId);

  await getDb().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(rateRef);
    const count = snapshot.exists ? toSafeInt(snapshot.data()?.count, 0) : 0;
    if (count >= limit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Rate limit exceeded",
      );
    }
    transaction.set(rateRef, {
      count: count + 1,
      updated_at: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

function buildWhatsAppUrl(
  phone: string,
  venueName: string,
  destLat: number,
  destLng: number,
): string {
  const sanitized = sanitizeWhatsApp(phone);
  const mapsUrl =
    `https://www.google.com/maps/search/?api=1&query=${destLat},${destLng}`;
  const text =
    `مرحبا، أريد توصيلة إلى ${venueName}. الموقع: ${mapsUrl}`;
  return `https://wa.me/${sanitized}?text=${encodeURIComponent(text)}`;
}

function buildDeepLinkUrl(
  template: string,
  replacements: Record<string, string>,
): string {
  let url = template;
  for (const [key, value] of Object.entries(replacements)) {
    url = url.split(`{${key}}`).join(encodeURIComponent(value));
  }
  return url;
}

function deepLinkReplacementsForQuote(
  quote: QuoteRecord,
): Record<string, string> {
  return {
    pickup_lat: quote.origin_lat.toString(),
    pickup_lng: quote.origin_lng.toString(),
    dropoff_lat: quote.destination_lat.toString(),
    dropoff_lng: quote.destination_lng.toString(),
    venue_name: quote.destination_name,
  };
}

function deepLinkPolicyForQuote(quote: QuoteRecord): DeepLinkPolicy {
  return {
    partnerId: quote.partner_id,
    allowedSchemes: quote.deep_link_allowed_schemes ?? [],
    allowedHosts: quote.deep_link_allowed_hosts ?? [],
    allowlistConfigured: quote.deep_link_allowlist_configured === true,
  };
}

function resolveHandoffType(raw: string): HandoffType | null {
  switch (raw) {
  case "deep_link":
  case "whatsapp":
  case "phone":
  case "api":
    return raw;
  default:
    return null;
  }
}

function assertVenueTransportAvailable(
  venueData: FirebaseFirestore.DocumentData,
): void {
  if (venueData.is_active === false) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "venue_inactive",
    );
  }

  if (venueData.transport_enabled !== true) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "transport_disabled",
    );
  }
}

function extractVenueCoordinates(
  venueData: FirebaseFirestore.DocumentData,
): { lat: number; lng: number } | null {
  const lat = toFiniteNumber(venueData.lat);
  const lng = toFiniteNumber(venueData.lng);
  if (lat != null && lng != null) {
    return { lat, lng };
  }

  const location = venueData.location;
  if (location &&
      typeof location.latitude === "number" &&
      typeof location.longitude === "number") {
    return {
      lat: location.latitude,
      lng: location.longitude,
    };
  }

  return null;
}

function buildHandoffUrl(
  quote: QuoteRecord,
): string {
  switch (quote.handoff_type) {
  case "phone":
    if (!quote.contact_phone) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "partner_contact_missing",
      );
    }
    return `tel:${sanitizePhone(quote.contact_phone)}`;
  case "whatsapp":
    if (!quote.contact_whatsapp) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "partner_contact_missing",
      );
    }
    return buildWhatsAppUrl(
      quote.contact_whatsapp,
      quote.destination_name,
      quote.destination_lat,
      quote.destination_lng,
    );
  case "deep_link":
    if (!quote.deep_link_url_template) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "partner_contact_missing",
      );
    }
    {
      const handoffUrl = buildDeepLinkUrl(
        quote.deep_link_url_template,
        deepLinkReplacementsForQuote(quote),
      );
      validateDeepLinkUrl(handoffUrl, deepLinkPolicyForQuote(quote));
      return handoffUrl;
    }
  case "api":
    throw new functions.https.HttpsError(
      "failed-precondition",
      "api_handoff_not_supported",
    );
  }
}

async function buildManagedQuote(
  partnerId: string,
  venueId: string,
  venueData: FirebaseFirestore.DocumentData,
  city: string,
  originLat: number,
  originLng: number,
  source: string,
  isRealLocation: boolean,
  quoteLogId: string,
): Promise<QuoteRecord | null> {
  const partnerSnapshot = await getDb().collection("transport_partners")
    .doc(partnerId)
    .get();

  if (!partnerSnapshot.exists) {
    return null;
  }

  const partnerData = partnerSnapshot.data() ?? {};
  if (partnerData.is_active === false) {
    return null;
  }
  const deepLinkPolicy = buildPartnerDeepLinkPolicy(partnerId, partnerData);

  const supportedCities = normalizeStringArray(partnerData.supported_cities);
  const normalizedCity = normalizeCityKey(city);
  if (supportedCities.length > 0 &&
      !supportedCities.map((item) => item.toLowerCase()).includes(normalizedCity)) {
    return null;
  }

  const quoteMode = normalizeString(partnerData.quote_mode || "managed");
  if (quoteMode !== "managed") {
    return null;
  }

  const contactMode = resolveHandoffType(
    normalizeString(partnerData.contact_mode),
  );
  if (contactMode == null || contactMode === "api") {
    return null;
  }

  const rulesSnapshot = await getDb().collection("transport_partner_rules")
    .where("partner_id", "==", partnerId)
    .limit(MAX_QUOTES_PER_REQUEST)
    .get();

  const matchingRule = rulesSnapshot.docs
    .map((doc) => doc.data())
    .find(
      (rule) => normalizeCityKey(rule.city) == normalizedCity && rule.is_active !== false,
    );

  if (!matchingRule) {
    return null;
  }

  const coords = extractVenueCoordinates(venueData);
  if (coords == null) {
    return null;
  }

  const straightLineDistanceMeters = haversineDistanceMeters(
    originLat,
    originLng,
    coords.lat,
    coords.lng,
  );
  const pricingDistanceMeters = straightLineDistanceMeters * ROAD_DISTANCE_MULTIPLIER;
  const distanceKm = pricingDistanceMeters / 1000;

  const baseFare = toFiniteNumber(matchingRule.base_fare) ?? 0;
  const perKmRate = toFiniteNumber(matchingRule.per_km_rate) ?? 0;
  const minimumFare = toFiniteNumber(matchingRule.minimum_fare) ?? 0;
  const serviceFee = toFiniteNumber(matchingRule.service_fee) ?? 0;

  const estimatedPrice = roundMoney(
    Math.max(minimumFare, baseFare + (distanceKm * perKmRate) + serviceFee),
  );

  const priceMin = isRealLocation
    ? estimatedPrice
    : roundMoney(Math.max(minimumFare, estimatedPrice * 0.9));
  const priceMax = isRealLocation
    ? estimatedPrice
    : roundMoney(Math.max(priceMin, estimatedPrice * 1.15));

  const etaMinutes = toSafeInt(
    partnerData.min_eta_minutes ?? 6,
    6,
  );
  const tripMinutes = Math.max(
    5,
    Math.round((distanceKm / 28) * 60),
  );
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(now.toMillis() + QUOTE_TTL_MS);
  const quoteId = getDb().collection("transport_quotes").doc().id;

  const quote: QuoteRecord = {
    quote_id: quoteId,
    quote_log_id: quoteLogId,
    venue_id: venueId,
    partner_id: partnerId,
    partner_name: normalizeString(partnerData.name),
    service_type: normalizeString(partnerData.service_type || "standard"),
    estimated_price: estimatedPrice,
    price_min: priceMin,
    price_max: priceMax,
    currency: normalizeString(partnerData.currency || venueData.currency || "ILS") || "ILS",
    eta_minutes: etaMinutes,
    trip_minutes: tripMinutes,
    generated_at: now,
    expires_at: expiresAt,
    price_confidence: "estimate",
    quote_source: "managed",
    pricing_version: normalizeString(matchingRule.pricing_version || "v1"),
    handoff_type: contactMode,
    origin_lat: originLat,
    origin_lng: originLng,
    destination_lat: coords.lat,
    destination_lng: coords.lng,
    destination_name: normalizeString(
      venueData.name_ar || venueData.name_en || venueId,
    ),
    contact_phone: normalizeString(partnerData.phone),
    contact_whatsapp: normalizeString(partnerData.whatsapp),
    deep_link_url_template: normalizeString(
      partnerData.deep_link_url_template,
    ),
    deep_link_allowed_schemes: deepLinkPolicy.allowedSchemes ?? [],
    deep_link_allowed_hosts: deepLinkPolicy.allowedHosts ?? [],
    deep_link_allowlist_configured: deepLinkPolicy.allowlistConfigured === true,
    source,
  };

  if (quote.handoff_type === "deep_link") {
    buildHandoffUrl(quote);
  }

  await getDb().collection("transport_quotes").doc(quoteId).set({
    ...quote,
    created_at: FieldValue.serverTimestamp(),
    straight_line_distance_meters: straightLineDistanceMeters,
    pricing_distance_meters: pricingDistanceMeters,
  });

  return quote;
}

export const getTransportQuotes = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);

  const venueId = normalizeString(data?.venueId);
  const originLat = toFiniteNumber(data?.originLat);
  const originLng = toFiniteNumber(data?.originLng);
  const source = normalizeString(data?.source || "venue_details") || "venue_details";
  const isRealLocation = data?.isRealLocation !== false;
  const cityHint = normalizeString(data?.city);
  const deviceId = normalizeString(data?.deviceId);

  if (!venueId || originLat == null || originLng == null) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing_transport_quote_fields",
    );
  }

  if (!context.auth?.uid && !deviceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "device_id_required",
    );
  }

  if (!isValidLatitude(originLat) || !isValidLongitude(originLng)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_coordinates",
    );
  }

  const actorId = context.auth?.uid ?? deviceId;
  await enforceTransportRateLimit("transport_quotes", actorId, 15);

  const venueSnapshot = await getDb().collection("venues").doc(venueId).get();
  if (!venueSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "venue_not_found");
  }

  const venueData = venueSnapshot.data() ?? {};
  assertVenueTransportAvailable(venueData);

  const coords = extractVenueCoordinates(venueData);
  if (coords == null) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "venue_location_missing",
    );
  }

  const distanceMeters = haversineDistanceMeters(
    originLat,
    originLng,
    coords.lat,
    coords.lng,
  );
  if (distanceMeters > MAX_DISTANCE_METERS) {
    throw new functions.https.HttpsError(
      "out-of-range",
      "distance_too_far",
    );
  }

  const city = normalizeCityKey(cityHint || venueData.city);
  const partnerIds = normalizeStringArray(venueData.transport_partner_ids);
  const providersQueried = [...partnerIds];
  const providersSucceeded: string[] = [];
  const providersFailed: string[] = [];
  const quoteLogId = getDb().collection("transport_quote_logs").doc().id;
  const startedAt = Date.now();

  const results = await Promise.allSettled(
    partnerIds.map((partnerId) =>
      buildManagedQuote(
        partnerId,
        venueId,
        venueData,
        city,
        originLat,
        originLng,
        source,
        isRealLocation,
        quoteLogId,
      )),
  );

  const quotes: QuoteRecord[] = [];
  for (let index = 0; index < results.length; index++) {
    const partnerId = partnerIds[index];
    const result = results[index];
    if (result.status === "fulfilled" && result.value) {
      providersSucceeded.push(partnerId);
      quotes.push(result.value);
    } else {
      providersFailed.push(partnerId);
    }
  }

  quotes.sort((a, b) => {
    if (a.estimated_price != b.estimated_price) {
      return a.estimated_price - b.estimated_price;
    }
    if (a.eta_minutes != b.eta_minutes) {
      return a.eta_minutes - b.eta_minutes;
    }
    return a.partner_name.localeCompare(b.partner_name);
  });

  const latencyMs = Date.now() - startedAt;
  await getDb().collection("transport_quote_logs").doc(quoteLogId).set({
    venue_id: venueId,
    city,
    origin_geohash: toOriginGeohash(originLat, originLng),
    quotes_count: quotes.length,
    providers_queried: providersQueried,
    providers_succeeded: providersSucceeded,
    providers_failed: providersFailed,
    latency_ms: latencyMs,
    user_authenticated: Boolean(context.auth?.uid),
    created_at: FieldValue.serverTimestamp(),
  });

  const firstQuote = quotes[0];
  return {
    originMode: isRealLocation ? "real_location" : "city_fallback",
    generatedAt: firstQuote?.generated_at.toMillis() ?? Timestamp.now().toMillis(),
    expiresAt: firstQuote?.expires_at.toMillis() ??
      Timestamp.fromMillis(Date.now() + QUOTE_TTL_MS).toMillis(),
    quotes: quotes.map((quote) => ({
      quoteId: quote.quote_id,
      partnerId: quote.partner_id,
      partnerName: quote.partner_name,
      serviceType: quote.service_type,
      estimatedPrice: quote.estimated_price,
      priceMin: quote.price_min,
      priceMax: quote.price_max,
      currency: quote.currency,
      etaMinutes: quote.eta_minutes,
      tripMinutes: quote.trip_minutes,
      generatedAt: quote.generated_at.toMillis(),
      expiresAt: quote.expires_at.toMillis(),
      priceConfidence: quote.price_confidence,
      quoteSource: quote.quote_source,
      pricingVersion: quote.pricing_version,
      handoffType: quote.handoff_type,
    })),
  };
});

export const createTransportHandoff = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);

  const venueId = normalizeString(data?.venueId);
  const quoteId = normalizeString(data?.quoteId);
  const source = normalizeString(data?.source || "venue_details") || "venue_details";
  const deviceId = normalizeString(data?.deviceId);

  if (!venueId || !quoteId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing_transport_handoff_fields",
    );
  }

  if (!context.auth?.uid && !deviceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "device_id_required",
    );
  }

  const actorId = context.auth?.uid ?? deviceId;
  await enforceTransportRateLimit("transport_handoff", actorId, 10);

  const quoteSnapshot = await getDb().collection("transport_quotes").doc(quoteId).get();
  if (!quoteSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "quote_not_found");
  }

  const quoteData = quoteSnapshot.data() as QuoteRecord | undefined;
  if (!quoteData) {
    throw new functions.https.HttpsError("not-found", "quote_not_found");
  }

  if (quoteData.venue_id !== venueId) {
    throw new functions.https.HttpsError("permission-denied", "quote_venue_mismatch");
  }

  if (quoteData.expires_at.toMillis() <= Date.now()) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "quote_expired",
    );
  }

  const venueSnapshot = await getDb().collection("venues").doc(venueId).get();
  if (!venueSnapshot.exists) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "transport_disabled",
    );
  }

  const venueData = venueSnapshot.data() ?? {};
  try {
    assertVenueTransportAvailable(venueData);
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "failed-precondition",
      "transport_disabled",
    );
  }

  const handoffUrl = buildHandoffUrl(quoteData);
  const handoffId = getDb().collection("transport_handoffs").doc().id;

  await getDb().collection("transport_handoffs").doc(handoffId).set({
    user_id: context.auth?.uid ?? null,
    device_id: deviceId || null,
    venue_id: venueId,
    partner_id: quoteData.partner_id,
    origin: {
      lat: quoteData.origin_lat,
      lng: quoteData.origin_lng,
    },
    destination: {
      lat: quoteData.destination_lat,
      lng: quoteData.destination_lng,
      name: quoteData.destination_name,
    },
    selected_quote_id: quoteData.quote_id,
    selected_price: quoteData.estimated_price,
    currency: quoteData.currency,
    quote_confidence: quoteData.price_confidence,
    quote_source: quoteData.quote_source,
    handoff_type: quoteData.handoff_type,
    request_channel: source,
    status: "handed_off",
    failure_reason: null,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });

  if (quoteData.quote_log_id) {
    await getDb().collection("transport_quote_logs").doc(quoteData.quote_log_id).set({
      selected_partner_id: quoteData.partner_id,
      selected_price: quoteData.estimated_price,
      selected_at: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  return {
    handoffId,
    handoffType: quoteData.handoff_type,
    handoffUrl,
  };
});

