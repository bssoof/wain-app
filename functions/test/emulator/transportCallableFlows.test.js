const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-transport";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  getTransportQuotes,
  createTransportHandoff,
} = require("../../lib/index.js");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

function callableContext({ uid = null, appCheck = true } = {}) {
  return {
    auth: uid ? { uid, token: {} } : null,
    app: appCheck ? { appId: "emu-app" } : undefined,
  };
}

function tsFromNow(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

function haversineDistanceMeters(lat1, lng1, lat2, lng2) {
  const toRadians = (deg) => deg * Math.PI / 180;
  const earthRadiusMeters = 6371000;
  const deltaLat = toRadians(lat2 - lat1);
  const deltaLng = toRadians(lng2 - lng1);

  const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

async function seedVenue({
  venueId,
  city = "ramallah",
  transportEnabled = true,
  isActive = true,
  useGeoPoint = false,
  partnerIds = ["partner-a"],
}) {
  const baseData = {
    name_ar: `Venue ${venueId}`,
    name_en: `Venue ${venueId}`,
    city,
    currency: "ILS",
    is_active: isActive,
    transport_enabled: transportEnabled,
    transport_partner_ids: partnerIds,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  };

  if (useGeoPoint) {
    baseData.location = new admin.firestore.GeoPoint(31.9038, 35.2034);
  } else {
    baseData.lat = 31.9038;
    baseData.lng = 35.2034;
  }

  await db.collection("venues").doc(venueId).set(baseData, { merge: true });
}

async function seedManagedPartner({
  partnerId = "partner-a",
  city = "ramallah",
  contactMode = "whatsapp",
}) {
  await db.collection("transport_partners").doc(partnerId).set({
    name: "Partner A",
    is_active: true,
    quote_mode: "managed",
    contact_mode: contactMode,
    supported_cities: [city],
    currency: "ILS",
    min_eta_minutes: 6,
    max_eta_minutes: 10,
    whatsapp: "972599000000",
    phone: "+972599000000",
    deep_link_url_template:
      "https://partner.example/book?pickup={pickup_lat},{pickup_lng}&dropoff={dropoff_lat},{dropoff_lng}&venue={venue_name}",
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  });

  await db.collection("transport_partner_rules").doc(`${partnerId}-rule`).set({
    partner_id: partnerId,
    city,
    base_fare: 12,
    per_km_rate: 3.5,
    minimum_fare: 15,
    service_fee: 2,
    is_active: true,
    pricing_version: "v1",
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  });
}

async function expectHttpsError(action, expectedCode, expectedMessageIncludes = null) {
  let error = null;
  try {
    await action();
  } catch (err) {
    error = err;
  }
  assert.ok(error, `Expected error ${expectedCode}`);
  assert.match(String(error.code || ""), new RegExp(expectedCode));
  if (expectedMessageIncludes) {
    assert.match(String(error.message || ""), new RegExp(expectedMessageIncludes));
  }
}

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("getTransportQuotes returns managed quotes for enabled venue", async () => {
  await seedVenue({ venueId: "venue-a" });
  await seedManagedPartner({});

  const result = await getTransportQuotes.run({
    venueId: "venue-a",
    city: "ramallah",
    originLat: 31.91,
    originLng: 35.21,
    isRealLocation: true,
    source: "venue_details",
    deviceId: "dev-1",
  }, callableContext({ uid: "user-a" }));

  assert.equal(Array.isArray(result.quotes), true);
  assert.equal(result.quotes.length, 1);
  assert.equal(result.originMode, "real_location");
  assert.equal(result.quotes[0].partnerId, "partner-a");
  assert.equal(result.quotes[0].priceConfidence, "estimate");
  const straightLineDistanceKm =
    haversineDistanceMeters(31.91, 35.21, 31.9038, 35.2034) / 1000;
  const pricingDistanceKm = straightLineDistanceKm * 1.3;
  const expectedPrice = Math.round(
    Math.max(15, 12 + (pricingDistanceKm * 3.5) + 2) * 100,
  ) / 100;
  assert.equal(result.quotes[0].estimatedPrice, expectedPrice);

  const logs = await db.collection("transport_quote_logs").get();
  assert.equal(logs.size, 1);
});

test("getTransportQuotes supports venue location stored as GeoPoint", async () => {
  await seedVenue({ venueId: "venue-geo", useGeoPoint: true });
  await seedManagedPartner({});

  const result = await getTransportQuotes.run({
    venueId: "venue-geo",
    city: "ramallah",
    originLat: 31.91,
    originLng: 35.21,
    isRealLocation: true,
    source: "venue_details",
    deviceId: "dev-1",
  }, callableContext({ uid: "user-a" }));

  assert.equal(result.quotes.length, 1);
  assert.equal(result.quotes[0].partnerId, "partner-a");
});

test("getTransportQuotes rejects missing App Check", async () => {
  await seedVenue({ venueId: "venue-a" });
  await seedManagedPartner({});

  await expectHttpsError(
    () => getTransportQuotes.run({
      venueId: "venue-a",
      city: "ramallah",
      originLat: 31.91,
      originLng: 35.21,
      deviceId: "dev-1",
    }, callableContext({ uid: "user-a", appCheck: false })),
    "failed-precondition",
    "App Check",
  );
});

test("getTransportQuotes rejects inactive venue", async () => {
  await seedVenue({ venueId: "venue-a", isActive: false });
  await seedManagedPartner({});

  await expectHttpsError(
    () => getTransportQuotes.run({
      venueId: "venue-a",
      city: "ramallah",
      originLat: 31.91,
      originLng: 35.21,
      deviceId: "dev-1",
    }, callableContext({ uid: "user-a" })),
    "failed-precondition",
    "venue_inactive",
  );
});

test("createTransportHandoff returns a WhatsApp handoff url for valid quote", async () => {
  await seedVenue({ venueId: "venue-a" });
  await seedManagedPartner({});

  const quotesResult = await getTransportQuotes.run({
    venueId: "venue-a",
    city: "ramallah",
    originLat: 31.91,
    originLng: 35.21,
    isRealLocation: false,
    source: "venue_details",
    deviceId: "dev-1",
  }, callableContext({ uid: "user-a" }));

  const handoffResult = await createTransportHandoff.run({
    venueId: "venue-a",
    quoteId: quotesResult.quotes[0].quoteId,
    source: "venue_details",
    deviceId: "dev-1",
  }, callableContext({ uid: "user-a" }));

  assert.ok(handoffResult.handoffId);
  assert.equal(handoffResult.handoffType, "whatsapp");
  assert.match(handoffResult.handoffUrl, /^https:\/\/wa\.me\//);

  const handoffDoc = await db.collection("transport_handoffs")
    .doc(handoffResult.handoffId)
    .get();
  assert.equal(handoffDoc.exists, true);
  assert.equal(handoffDoc.data().status, "handed_off");
});

test("createTransportHandoff rejects expired quote", async () => {
  await seedVenue({ venueId: "venue-a" });
  await seedManagedPartner({});

  await db.collection("transport_quotes").doc("quote-expired").set({
    quote_id: "quote-expired",
    quote_log_id: "log-expired",
    venue_id: "venue-a",
    partner_id: "partner-a",
    partner_name: "Partner A",
    service_type: "standard",
    estimated_price: 20,
    price_min: 20,
    price_max: 20,
    currency: "ILS",
    eta_minutes: 6,
    trip_minutes: 8,
    generated_at: tsFromNow(-300_000),
    expires_at: tsFromNow(-120_000),
    price_confidence: "estimate",
    quote_source: "managed",
    pricing_version: "v1",
    handoff_type: "phone",
    origin_lat: 31.91,
    origin_lng: 35.21,
    destination_lat: 31.9038,
    destination_lng: 35.2034,
    destination_name: "Venue venue-a",
    contact_phone: "+972599000000",
    contact_whatsapp: "",
    deep_link_url_template: "",
    source: "venue_details",
    created_at: tsFromNow(-300_000),
  });

  await expectHttpsError(
    () => createTransportHandoff.run({
      venueId: "venue-a",
      quoteId: "quote-expired",
      source: "venue_details",
      deviceId: "dev-1",
    }, callableContext({ uid: "user-a" })),
    "failed-precondition",
    "quote_expired",
  );
});

test("createTransportHandoff rejects venue that becomes inactive", async () => {
  await seedVenue({ venueId: "venue-a" });
  await seedManagedPartner({});

  const quotesResult = await getTransportQuotes.run({
    venueId: "venue-a",
    city: "ramallah",
    originLat: 31.91,
    originLng: 35.21,
    isRealLocation: true,
    source: "venue_details",
    deviceId: "dev-1",
  }, callableContext({ uid: "user-a" }));

  await db.collection("venues").doc("venue-a").set({
    is_active: false,
  }, { merge: true });

  await expectHttpsError(
    () => createTransportHandoff.run({
      venueId: "venue-a",
      quoteId: quotesResult.quotes[0].quoteId,
      source: "venue_details",
      deviceId: "dev-1",
    }, callableContext({ uid: "user-a" })),
    "failed-precondition",
    "venue_inactive",
  );
});
