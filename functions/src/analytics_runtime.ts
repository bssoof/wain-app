import * as functions from "firebase-functions/v1";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

import {
  ANALYTICS_TIMEZONE,
  bucketAnalyticsByDay,
  dayKeyInTimezone,
  dayOffsetKey,
  keyInRange,
} from "./analytics_helpers";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { db } from "./shared/firestore-db";

function toInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  return 0;
}

function getOfferAvailabilityState(
  offerData: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "available" | "inactive" | "not_started" | "expired" {
  if (offerData.is_active === false) return "inactive";

  const startAt = offerData.start_at;
  if (startAt instanceof Timestamp &&
      startAt.toMillis() > now.toMillis()) {
    return "not_started";
  }

  const endAt = offerData.end_at;
  if (endAt instanceof Timestamp &&
      endAt.toMillis() <= now.toMillis()) {
    return "expired";
  }

  return "available";
}

function dayFromTimestamp(ts: unknown): Date | null {
  if (ts instanceof Timestamp) {
    return ts.toDate();
  }
  if (ts instanceof Date) {
    return ts;
  }
  return null;
}

function safeRatio(numerator: number, denominator: number): number {
  if (denominator <= 0) return 0;
  return numerator / denominator;
}

type OfferWindowCounts = {
  detailViews7d: number;
  detailViews30d: number;
  claimClicks7d: number;
  claimClicks30d: number;
  claimsCreated7d: number;
  claimsCreated30d: number;
  redemptions7d: number;
  redemptions30d: number;
};

function emptyOfferWindowCounts(): OfferWindowCounts {
  return {
    detailViews7d: 0,
    detailViews30d: 0,
    claimClicks7d: 0,
    claimClicks30d: 0,
    claimsCreated7d: 0,
    claimsCreated30d: 0,
    redemptions7d: 0,
    redemptions30d: 0,
  };
}

async function countQuery(query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData>): Promise<number> {
  try {
    const aggregate = await query.count().get();
    return aggregate.data().count;
  } catch (e) {
    // Fallback for environments where count aggregate is unavailable.
    const snap = await query.get();
    return snap.size;
  }
}

async function aggregateVenueAnalyticsForVenue(venueId: string, lookbackDays: number = 30): Promise<void> {
  const nowDate = new Date();
  const nowTs = Timestamp.now();
  const safeLookback = Math.max(lookbackDays, 1);
  const todayKey = dayKeyInTimezone(nowDate, ANALYTICS_TIMEZONE);
  const periodStartKey = dayOffsetKey(todayKey, -(safeLookback - 1));
  const periodStartDate = new Date(`${periodStartKey}T00:00:00.000Z`);
  const current7dStartKey = dayOffsetKey(todayKey, -6);
  const current7dEndKey = dayOffsetKey(todayKey, 1);

  const [recentEventsSnap, recentNavsSnap] = await Promise.all([
    db.collection("venue_events")
      .where("venue_id", "==", venueId)
      .where("created_at", ">=", Timestamp.fromDate(periodStartDate))
      .get(),
    db.collection("navigation_clicks")
      .where("venue_id", "==", venueId)
      .where("timestamp", ">=", Timestamp.fromDate(periodStartDate))
      .get(),
  ]);

  const events = recentEventsSnap.docs
    .map((doc) => {
      const data = doc.data();
      const eventType = data.event_type as string | undefined;
      const createdAt = dayFromTimestamp(data.created_at);
      if (!eventType || !createdAt) return null;
      return { eventType, at: createdAt };
    })
    .filter((event): event is { eventType: string; at: Date } => event !== null);

  const navigationClicks = recentNavsSnap.docs
    .map((doc) => {
      const data = doc.data();
      return dayFromTimestamp(data.timestamp);
    })
    .filter((ts): ts is Date => ts !== null);

  const bucketed = bucketAnalyticsByDay({
    nowDate,
    lookbackDays: safeLookback,
    events,
    navigationClicks,
    timeZone: ANALYTICS_TIMEZONE,
  });

  const offerWindowCountsById = new Map<string, OfferWindowCounts>();
  for (const doc of recentEventsSnap.docs) {
    const data = doc.data();
    const eventType = typeof data.event_type === "string" ? data.event_type : "";
    const offerId = typeof data.offer_id === "string" ? data.offer_id.trim() : "";
    const createdAt = dayFromTimestamp(data.created_at);

    if (!offerId || !createdAt) continue;

    const counts = offerWindowCountsById.get(offerId) ?? emptyOfferWindowCounts();
    if (eventType === "offer_detail_view") counts.detailViews30d += 1;
    if (eventType === "offer_claim_click") counts.claimClicks30d += 1;
    if (eventType === "offer_claim_created") counts.claimsCreated30d += 1;
    if (eventType === "offer_redeemed") counts.redemptions30d += 1;

    const dayKey = dayKeyInTimezone(createdAt, ANALYTICS_TIMEZONE);
    if (!keyInRange(dayKey, current7dStartKey, current7dEndKey)) {
      offerWindowCountsById.set(offerId, counts);
      continue;
    }

    if (eventType === "offer_detail_view") counts.detailViews7d += 1;
    if (eventType === "offer_claim_click") counts.claimClicks7d += 1;
    if (eventType === "offer_claim_created") counts.claimsCreated7d += 1;
    if (eventType === "offer_redeemed") counts.redemptions7d += 1;
    offerWindowCountsById.set(offerId, counts);
  }

  const [
    viewsTotal,
    callsTotal,
    storyViewsTotal,
    navsTotal,
    offerDetailViewsTotal,
    claimClicksTotal,
    claimsCreatedTotal,
    redemptionsTotal,
  ] = await Promise.all([
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "view"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "call"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "story_view"),
    ),
    countQuery(
      db.collection("navigation_clicks")
        .where("venue_id", "==", venueId),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "offer_detail_view"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "offer_claim_click"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "offer_claim_created"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "offer_redeemed"),
    ),
  ]);

  const contactIntent7d = bucketed.calls7d + bucketed.navs7d;
  const contactIntentPrev7d = bucketed.callsPrev7d + bucketed.navsPrev7d;

  const summaryRef = db.collection("venue_analytics").doc(venueId);
  await summaryRef.set({
    venue_id: venueId,
    views_total: viewsTotal,
    views_this_week: bucketed.viewsThisWeek,
    views_last_week: bucketed.viewsLastWeek,
    calls_total: callsTotal,
    calls_this_week: bucketed.callsThisWeek,
    calls_last_week: bucketed.callsLastWeek,
    navs_total: navsTotal,
    navs_this_week: bucketed.navsThisWeek,
    navs_last_week: bucketed.navsLastWeek,
    story_views_total: storyViewsTotal,
    story_views_this_week: bucketed.storyViewsThisWeek,
    offer_detail_views_total: offerDetailViewsTotal,
    offer_detail_views_7d: bucketed.offerDetailViews7d,
    offer_detail_views_prev_7d: bucketed.offerDetailViewsPrev7d,
    claim_clicks_total: claimClicksTotal,
    claim_clicks_7d: bucketed.claimClicks7d,
    claim_clicks_prev_7d: bucketed.claimClicksPrev7d,
    claims_created_total: claimsCreatedTotal,
    claims_created_7d: bucketed.claimsCreated7d,
    claims_created_prev_7d: bucketed.claimsCreatedPrev7d,
    redemptions_total: redemptionsTotal,
    redemptions_7d: bucketed.redemptions7d,
    redemptions_prev_7d: bucketed.redemptionsPrev7d,
    contact_intent_7d: contactIntent7d,
    contact_intent_prev_7d: contactIntentPrev7d,
    contact_rate_7d: safeRatio(contactIntent7d, bucketed.views7d),
    detail_to_claim_click_rate_7d: safeRatio(
      bucketed.claimClicks7d,
      bucketed.offerDetailViews7d,
    ),
    view_to_claim_rate_7d: safeRatio(
      bucketed.claimsCreated7d,
      bucketed.views7d,
    ),
    claim_to_redemption_rate_7d: safeRatio(
      bucketed.redemptions7d,
      bucketed.claimsCreated7d,
    ),
    updated_at: nowTs,
  }, { merge: true });

  const existingOfferAnalyticsSnap = await db.collection("venue_offer_analytics")
    .doc(venueId)
    .collection("offers")
    .get();
  const existingOfferAnalyticsById = new Map(
    existingOfferAnalyticsSnap.docs.map((doc) => [doc.id, doc.data()] as const),
  );
  const offerIdsToRefresh = new Set<string>([
    ...offerWindowCountsById.keys(),
    ...existingOfferAnalyticsById.keys(),
  ]);
  const offerDocsById = new Map<
    string,
    FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>
  >();
  await Promise.all(
    [...offerIdsToRefresh].map(async (offerId) => {
      const offerSnap = await db.collection("offers").doc(offerId).get();
      offerDocsById.set(offerId, offerSnap);
    }),
  );

  const batch = db.batch();
  for (const [key, bucket] of bucketed.dailyBuckets.entries()) {
    const dayRef = db.collection("venue_analytics_daily")
      .doc(venueId)
      .collection("days")
      .doc(key);

    batch.set(dayRef, {
      venue_id: venueId,
      date_key: key,
      views: bucket.views,
      calls: bucket.calls,
      navs: bucket.navs,
      story_views: bucket.story_views,
      offer_detail_views: bucket.offer_detail_views,
      claim_clicks: bucket.claim_clicks,
      claims_created: bucket.claims_created,
      redemptions: bucket.redemptions,
      updated_at: nowTs,
    }, { merge: true });
  }

  for (const offerId of offerIdsToRefresh) {
    const counts = offerWindowCountsById.get(offerId) ?? emptyOfferWindowCounts();
    const offerSnap = offerDocsById.get(offerId);
    const existingOfferAnalytics = existingOfferAnalyticsById.get(offerId) ?? {};
    const offerData = offerSnap?.exists ? offerSnap.data() ?? {} : null;
    const fallbackTitle = typeof existingOfferAnalytics.offer_title_ar === "string"
      ? existingOfferAnalytics.offer_title_ar
      : "";
    const offerTitleAr = offerData ?
      (typeof offerData.title_ar === "string" && offerData.title_ar.trim().length > 0
        ? offerData.title_ar
        : (typeof offerData.title === "string" ? offerData.title : fallbackTitle)) :
      fallbackTitle;
    const fallbackStatus = typeof existingOfferAnalytics.status === "string"
      ? existingOfferAnalytics.status
      : "unknown";
    const status = offerData
      ? getOfferAvailabilityState(offerData, nowTs)
      : fallbackStatus;

    const offerAnalyticsRef = db.collection("venue_offer_analytics")
      .doc(venueId)
      .collection("offers")
      .doc(offerId);

    batch.set(offerAnalyticsRef, {
      offer_id: offerId,
      offer_title_ar: offerTitleAr,
      status,
      detail_views_7d: counts.detailViews7d,
      detail_views_30d: counts.detailViews30d,
      claim_clicks_7d: counts.claimClicks7d,
      claim_clicks_30d: counts.claimClicks30d,
      claims_created_7d: counts.claimsCreated7d,
      claims_created_30d: counts.claimsCreated30d,
      redemptions_7d: counts.redemptions7d,
      redemptions_30d: counts.redemptions30d,
      claim_to_redemption_rate_7d: safeRatio(
        counts.redemptions7d,
        counts.claimsCreated7d,
      ),
      claim_to_redemption_rate_30d: safeRatio(
        counts.redemptions30d,
        counts.claimsCreated30d,
      ),
      updated_at: nowTs,
    }, { merge: true });
  }

  await batch.commit();
}

// Scheduled: aggregate analytics for all merchant-linked venues.
export const aggregateVenueAnalytics = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const merchantSnap = await db.collection("merchants").get();
    const venueIds = new Set<string>();

    for (const doc of merchantSnap.docs) {
      const venueId = doc.data().venue_id;
      if (typeof venueId === "string" && venueId.trim().length > 0) {
        venueIds.add(venueId.trim());
      }
    }

    let ok = 0;
    let failed = 0;
    for (const venueId of venueIds) {
      try {
        await aggregateVenueAnalyticsForVenue(venueId, 30);
        ok += 1;
      } catch (e) {
        failed += 1;
        console.error(`Failed to aggregate analytics for venue ${venueId}`, e);
      }
    }

    console.log(`aggregateVenueAnalytics finished. ok=${ok}, failed=${failed}`);
    return null;
  });

// Optional one-off backfill for merchant's own venue.
// Input: { days?: number } where days is capped at 30.
export const backfillMerchantAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }
  requireAppCheck(context);

  const uid = context.auth.uid;
  const merchantRef = db.collection("merchants").doc(uid);
  const userRef = db.collection("users").doc(uid);

  const [merchantDoc, userDoc] = await Promise.all([
    merchantRef.get(),
    userRef.get(),
  ]);

  const merchantVenueId = merchantDoc.data()?.venue_id as string | undefined;
  const userVenueId = userDoc.data()?.merchant_venue_id as string | undefined;

  const normalizedMerchantVenueId = typeof merchantVenueId === "string" ? merchantVenueId.trim() : "";
  const normalizedUserVenueId = typeof userVenueId === "string" ? userVenueId.trim() : "";

  // Prefer users/{uid}.merchant_venue_id because dashboard access is based on it.
  const venueId = normalizedUserVenueId || normalizedMerchantVenueId;
  if (!venueId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Not a linked merchant account",
    );
  }

  // Auto-heal legacy accounts that have user link but no merchant profile.
  if (!normalizedMerchantVenueId || normalizedMerchantVenueId !== venueId) {
    await merchantRef.set(
      {
        uid,
        venue_id: venueId,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  const requestedDays = typeof data?.days === "number" ? Math.trunc(data.days) : 30;
  const days = Math.max(1, Math.min(requestedDays, 30));

  try {
    await aggregateVenueAnalyticsForVenue(venueId, days);
  } catch (error) {
    const rawMessage = error instanceof Error ? error.message : String(error);
    console.error("backfillMerchantAnalytics failed", { uid, venueId, rawMessage });
    const lowered = rawMessage.toLowerCase();

    if (lowered.includes("index")) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Missing Firestore index for analytics queries",
      );
    }

    throw new functions.https.HttpsError(
      "internal",
      "Failed to aggregate merchant analytics",
    );
  }

  const summarySnap = await db.collection("venue_analytics").doc(venueId).get();
  const summary = summarySnap.exists ? summarySnap.data() : null;
  logSecurityAudit("backfillMerchantAnalytics", {
    uid,
    venueId,
    days,
    timestamp: Timestamp.now().toMillis(),
    result: "success",
  });
  return {
    success: true,
    venueId,
    days,
    summary: summary ? {
      views_total: toInt(summary.views_total),
      calls_total: toInt(summary.calls_total),
      navs_total: toInt(summary.navs_total),
      story_views_total: toInt(summary.story_views_total),
    } : null,
  };
});
