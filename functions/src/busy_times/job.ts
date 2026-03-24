import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import * as functions from "firebase-functions/v1";
import {
  BUSY_TIMES_JOB_CRON,
  BUSY_TIMES_JOB_TIMEZONE,
  BUSY_TIMES_WINDOW_DAYS,
  type VenueSignal,
} from "./types";
import {
  buildInsufficientBusyTimesDoc,
  buildSuccessfulBusyTimesDoc,
  bucketSignalsToHistogram,
  computeBestVisitWindowsByDay,
  computeCurrentTypicalLabel,
  computePeakWindow,
  dedupeSignals,
  determineConfidence,
  determineInsufficientReason,
  smoothHistogram,
} from "./aggregation";
import { normalizeOpeningHours } from "./opening_hours";
import { resolveVenueTimezone } from "./timezone";

function getDb(): FirebaseFirestore.Firestore {
  return admin.firestore();
}

function normalizeVenueId(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function getTimestampDate(value: unknown): Date | null {
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  return null;
}

function getIdentity(data: FirebaseFirestore.DocumentData): string | null {
  const deviceId = typeof data.device_id === "string" ? data.device_id.trim() : "";
  if (deviceId) {
    return deviceId;
  }

  const userId = typeof data.user_id === "string" ? data.user_id.trim() : "";
  if (userId) {
    return userId;
  }

  return null;
}

function getDaysCovered(venueData: FirebaseFirestore.DocumentData, computedFromDate: Date, computedToDate: Date): number {
  const createdAt = getTimestampDate(venueData.created_at);
  const effectiveStart = createdAt && createdAt > computedFromDate ? createdAt : computedFromDate;
  const ms = computedToDate.getTime() - effectiveStart.getTime();
  const days = Math.floor(ms / (24 * 60 * 60 * 1000));
  return Math.max(1, Math.min(BUSY_TIMES_WINDOW_DAYS, days + 1));
}

async function fetchOfferClaimSignals(
  venueId: string,
  computedFromTs: Timestamp,
): Promise<VenueSignal[]> {
  const snapshot = await getDb()
    .collection("offer_claims")
    .where("venue_id", "==", venueId)
    .where("created_at", ">=", computedFromTs)
    .get();

  return snapshot.docs.flatMap((doc) => {
    const data = doc.data();
    const identity = getIdentity(data);
    const eventAt = getTimestampDate(data.created_at);
    if (!identity || !eventAt) {
      return [];
    }

    return [{
      venueId,
      identity,
      eventType: "offer_claim" as const,
      eventAt,
      sourceWeight: 0.5,
    }];
  });
}

async function fetchQrRedemptionSignals(
  venueId: string,
  computedFromTs: Timestamp,
): Promise<VenueSignal[]> {
  const snapshot = await getDb()
    .collection("offer_claims")
    .where("venue_id", "==", venueId)
    .where("status", "==", "redeemed")
    .where("redeemed_at", ">=", computedFromTs)
    .get();

  return snapshot.docs.flatMap((doc) => {
    const data = doc.data();
    const identity = getIdentity(data);
    const eventAt = getTimestampDate(data.redeemed_at);
    if (!identity || !eventAt) {
      return [];
    }

    return [{
      venueId,
      identity,
      eventType: "qr_redemption" as const,
      eventAt,
      sourceWeight: 1.0,
    }];
  });
}

async function fetchDirectionsSignals(
  venueId: string,
  computedFromTs: Timestamp,
): Promise<VenueSignal[]> {
  const snapshot = await getDb()
    .collection("navigation_clicks")
    .where("venue_id", "==", venueId)
    .where("timestamp", ">=", computedFromTs)
    .get();

  return snapshot.docs.flatMap((doc) => {
    const data = doc.data();
    const identity = getIdentity(data);
    const eventAt = getTimestampDate(data.timestamp);
    if (!identity || !eventAt) {
      return [];
    }

    return [{
      venueId,
      identity,
      eventType: "directions_click" as const,
      eventAt,
      sourceWeight: 0.7,
    }];
  });
}

async function buildSignalsForVenue(
  venueId: string,
  computedFromTs: Timestamp,
): Promise<VenueSignal[]> {
  const [offerClaims, qrRedemptions, directions] = await Promise.all([
    fetchOfferClaimSignals(venueId, computedFromTs),
    fetchQrRedemptionSignals(venueId, computedFromTs),
    fetchDirectionsSignals(venueId, computedFromTs),
  ]);

  return dedupeSignals([
    ...offerClaims,
    ...qrRedemptions,
    ...directions,
  ]);
}

async function resolveMerchantVenueId(uid: string): Promise<string> {
  const db = getDb();
  const [merchantDoc, userDoc] = await Promise.all([
    db.collection("merchants").doc(uid).get(),
    db.collection("users").doc(uid).get(),
  ]);

  const merchantVenueId = normalizeVenueId(merchantDoc.data()?.venue_id);
  const userVenueId = normalizeVenueId(userDoc.data()?.merchant_venue_id);
  return userVenueId || merchantVenueId;
}

export function resolveAuthorizedBackfillVenueId(params: {
  requestedVenueId: string;
  merchantVenueId: string;
}): string {
  const requestedVenueId = normalizeVenueId(params.requestedVenueId);
  const merchantVenueId = normalizeVenueId(params.merchantVenueId);

  if (!merchantVenueId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Not a linked merchant account",
    );
  }

  if (!requestedVenueId) {
    return merchantVenueId;
  }

  if (requestedVenueId !== merchantVenueId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Cannot backfill another merchant venue",
    );
  }

  return merchantVenueId;
}

export async function aggregateBusyTimesForVenue(
  venueDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> |
    FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>,
  options: {
    now?: Date;
    demoMode?: boolean;
  } = {},
): Promise<void> {
  const venueData = venueDoc.data();
  if (!venueData) {
    return;
  }

  const computedToDate = options.now ?? new Date();
  const computedFromDate = new Date(computedToDate.getTime() - (BUSY_TIMES_WINDOW_DAYS * 24 * 60 * 60 * 1000));
  const computedToTs = Timestamp.fromDate(computedToDate);
  const computedFromTs = Timestamp.fromDate(computedFromDate);
  const lastComputedAt = Timestamp.now();

  const timezoneResolution = resolveVenueTimezone({
    venueTimezone: venueData.timezone,
    venueCity: venueData.city,
  });

  const normalizedHours = normalizeOpeningHours(venueData as Record<string, unknown>);
  const daysCovered = getDaysCovered(venueData, computedFromDate, computedToDate);
  const busyTimesRef = getDb().collection("venue_busy_times").doc(venueDoc.id);

  if (timezoneResolution.timezone === null || normalizedHours.openingHours === null) {
    const insufficientDoc = buildInsufficientBusyTimesDoc({
      venueId: venueDoc.id,
      demoOverrideActive: options.demoMode === true,
      timezone: typeof venueData.timezone === "string" ? venueData.timezone : null,
      resolvedTimezone: timezoneResolution.timezone,
      computedFrom: computedFromTs,
      computedTo: computedToTs,
      insufficientReason: timezoneResolution.insufficientReason ?? normalizedHours.insufficientReason ?? "missing_opening_hours",
      daysCovered,
      lastComputedAt,
    });
    await busyTimesRef.set(insufficientDoc, { merge: true });
    return;
  }

  const signals = await buildSignalsForVenue(venueDoc.id, computedFromTs);
  const histogramBuild = bucketSignalsToHistogram({
    signals,
    timeZone: timezoneResolution.timezone,
    openingHours: normalizedHours.openingHours,
  });

  const insufficientReason = determineInsufficientReason({
    resolvedTimezone: timezoneResolution.timezone,
    openingHours: normalizedHours.openingHours,
    totalSignals30d: histogramBuild.totalSignals30d,
    distinctActiveDays30d: histogramBuild.distinctActiveDays30d,
    daysCovered,
    demoMode: options.demoMode === true,
  });

  if (insufficientReason) {
    const insufficientDoc = buildInsufficientBusyTimesDoc({
      venueId: venueDoc.id,
      demoOverrideActive: options.demoMode === true,
      timezone: typeof venueData.timezone === "string" ? venueData.timezone : null,
      resolvedTimezone: timezoneResolution.timezone,
      computedFrom: computedFromTs,
      computedTo: computedToTs,
      insufficientReason,
      totalSignals30d: histogramBuild.totalSignals30d,
      distinctActiveDays30d: histogramBuild.distinctActiveDays30d,
      daysCovered,
      sourceBreakdown30d: histogramBuild.sourceBreakdown30d,
      lastComputedAt,
    });
    await busyTimesRef.set(insufficientDoc, { merge: true });
    return;
  }

  const smoothedHistogram = smoothHistogram(histogramBuild.histogram);
  const confidence = determineConfidence({
    insufficientReason: null,
    totalSignals30d: histogramBuild.totalSignals30d,
    distinctActiveDays30d: histogramBuild.distinctActiveDays30d,
  });
  const currentTypicalLabel = computeCurrentTypicalLabel({
    histogram: smoothedHistogram,
    timeZone: timezoneResolution.timezone,
    openingHours: normalizedHours.openingHours,
    now: computedToDate,
  });
  const { peakDay, peakHour } = computePeakWindow(smoothedHistogram);
  const bestVisitWindowsByDay = computeBestVisitWindowsByDay({
    histogram: smoothedHistogram,
    openingHours: normalizedHours.openingHours,
  });

  const doc = buildSuccessfulBusyTimesDoc({
    venueId: venueDoc.id,
    demoOverrideActive: options.demoMode === true,
    timezone: typeof venueData.timezone === "string" ? venueData.timezone : null,
    resolvedTimezone: timezoneResolution.timezone,
    computedFrom: computedFromTs,
    computedTo: computedToTs,
    histogram: smoothedHistogram,
    confidence,
    totalSignals30d: histogramBuild.totalSignals30d,
    distinctActiveDays30d: histogramBuild.distinctActiveDays30d,
    daysCovered,
    currentTypicalLabel,
    peakDay,
    peakHour,
    bestVisitWindowsByDay,
    sourceBreakdown30d: histogramBuild.sourceBreakdown30d,
    lastComputedAt,
  });

  await busyTimesRef.set(doc, { merge: true });
}

export const aggregateVenueBusyTimes = functions.pubsub
  .schedule(BUSY_TIMES_JOB_CRON)
  .timeZone(BUSY_TIMES_JOB_TIMEZONE)
  .onRun(async () => {
    const venuesSnap = await getDb().collection("venues").get();

    let ok = 0;
    let failed = 0;
    for (const venueDoc of venuesSnap.docs) {
      try {
        await aggregateBusyTimesForVenue(venueDoc);
        ok += 1;
      } catch (error) {
        failed += 1;
        console.error(`Failed to aggregate busy times for venue ${venueDoc.id}`, error);
      }
    }

    console.log(`aggregateVenueBusyTimes finished. ok=${ok}, failed=${failed}`);
    return null;
  });

export const backfillVenueBusyTimes = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const requestedVenueId = normalizeVenueId(data?.venueId);
  const demoMode = data?.demoMode === true;
  const merchantVenueId = await resolveMerchantVenueId(context.auth.uid);
  const venueId = resolveAuthorizedBackfillVenueId({
    requestedVenueId,
    merchantVenueId,
  });

  const venueDoc = await getDb().collection("venues").doc(venueId).get();
  if (!venueDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Venue not found");
  }

  await aggregateBusyTimesForVenue(venueDoc, { demoMode });

  const busyTimesDoc = await getDb().collection("venue_busy_times").doc(venueId).get();
  return {
    success: true,
    venueId,
    busyTimes: busyTimesDoc.exists ? busyTimesDoc.data() : null,
  };
});

