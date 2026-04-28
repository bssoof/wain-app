const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-analytics";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  aggregateVenueAnalytics,
  backfillMerchantAnalytics,
  createClaimToken,
  redeemToken,
} = require("../../lib/index.js");
const {
  dayOffsetKey,
  dayKeyInTimezone,
  weekStartKey,
} = require("../../lib/analytics_helpers.js");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
const timezone = "Asia/Jerusalem";

function callableContext({ uid = null, appCheck = true } = {}) {
  return {
    auth: uid ? { uid, token: {} } : null,
    app: appCheck ? { appId: "emu-app" } : undefined,
  };
}

function dateFromDayKeyAtNoonUtc(dayKey) {
  return new Date(`${dayKey}T12:00:00.000Z`);
}

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

test.before(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("aggregateVenueAnalytics: seed -> aggregate -> assert summary and daily docs", async () => {
  await clearFirestore();

  const venueId = "venue-emu-1";
  const now = new Date();
  const todayKey = dayKeyInTimezone(now, timezone);
  const thisWeekStartKey = weekStartKey(now, timezone);
  const thisWeekKey = thisWeekStartKey;
  const lastWeekKey = dayOffsetKey(thisWeekStartKey, -1);
  const current7dStartKey = dayOffsetKey(todayKey, -6);
  const prev7dStartKey = dayOffsetKey(todayKey, -13);
  const prev7dEndKey = current7dStartKey;
  const currentOfferKey = todayKey;
  const prevOfferKey = dayOffsetKey(todayKey, -8);

  const thisWeekDate = dateFromDayKeyAtNoonUtc(thisWeekKey);
  const lastWeekDate = dateFromDayKeyAtNoonUtc(lastWeekKey);
  const currentOfferDate = dateFromDayKeyAtNoonUtc(currentOfferKey);
  const prevOfferDate = dateFromDayKeyAtNoonUtc(prevOfferKey);
  const isCurrent7d = (key) => key >= current7dStartKey && key < dayOffsetKey(todayKey, 1);
  const isPrev7d = (key) => key >= prev7dStartKey && key < prev7dEndKey;

  await db.collection("merchants").doc("merchant-a").set({
    uid: "merchant-a",
    venue_id: venueId,
  });
  await db.collection("merchants").doc("merchant-b").set({
    uid: "merchant-b",
    venue_id: "   ",
  });
  await db.collection("offers").doc("offer-phase3").set({
    venue_id: venueId,
    title_ar: "Offer Phase 3",
    is_active: true,
  });

  await db.collection("venue_events").doc("ev-1").set({
    venue_id: venueId,
    event_type: "view",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(thisWeekDate),
  });
  await db.collection("venue_events").doc("ev-2").set({
    venue_id: venueId,
    event_type: "view",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(lastWeekDate),
  });
  await db.collection("venue_events").doc("ev-3").set({
    venue_id: venueId,
    event_type: "call",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(lastWeekDate),
  });
  await db.collection("venue_events").doc("ev-4").set({
    venue_id: venueId,
    event_type: "story_view",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(thisWeekDate),
  });

  await db.collection("venue_events").doc("ev-noise").set({
    venue_id: "venue-other",
    event_type: "view",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(thisWeekDate),
  });
  await db.collection("venue_events").doc("ev-phase3-nav").set({
    venue_id: venueId,
    event_type: "nav_click",
    source: "test",
    nav_app: "google_maps",
    created_at: admin.firestore.Timestamp.fromDate(thisWeekDate),
  });
  await db.collection("venue_events").doc("ev-phase3-detail").set({
    venue_id: venueId,
    event_type: "offer_detail_view",
    offer_id: "offer-phase3",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(currentOfferDate),
  });
  await db.collection("venue_events").doc("ev-phase4-detail-prev").set({
    venue_id: venueId,
    event_type: "offer_detail_view",
    offer_id: "offer-phase3",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(prevOfferDate),
  });
  await db.collection("venue_events").doc("ev-phase4-claim-click").set({
    venue_id: venueId,
    event_type: "offer_claim_click",
    offer_id: "offer-phase3",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(currentOfferDate),
  });
  await db.collection("venue_events").doc("ev-phase4-claim-created").set({
    venue_id: venueId,
    event_type: "offer_claim_created",
    offer_id: "offer-phase3",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(currentOfferDate),
  });
  await db.collection("venue_events").doc("ev-phase4-redeemed").set({
    venue_id: venueId,
    event_type: "offer_redeemed",
    offer_id: "offer-phase3",
    source: "redeem_token",
    created_at: admin.firestore.Timestamp.fromDate(currentOfferDate),
  });

  await db.collection("navigation_clicks").doc("nav-1").set({
    venue_id: venueId,
    nav_app: "google_maps",
    timestamp: admin.firestore.Timestamp.fromDate(thisWeekDate),
  });
  await db.collection("navigation_clicks").doc("nav-2").set({
    venue_id: venueId,
    nav_app: "waze",
    timestamp: admin.firestore.Timestamp.fromDate(lastWeekDate),
  });

  await aggregateVenueAnalytics.run();

  const summarySnap = await db.collection("venue_analytics").doc(venueId).get();
  assert.equal(summarySnap.exists, true);
  const summary = summarySnap.data();
  assert.ok(summary);

  assert.equal(summary.venue_id, venueId);
  assert.equal(summary.views_total, 2);
  assert.equal(summary.calls_total, 1);
  assert.equal(summary.story_views_total, 1);
  assert.equal(summary.navs_total, 2);
  assert.equal(summary.views_this_week, 1);
  assert.equal(summary.views_last_week, 1);
  assert.equal(summary.calls_this_week, 0);
  assert.equal(summary.calls_last_week, 1);
  assert.equal(summary.navs_this_week, 1);
  assert.equal(summary.navs_last_week, 1);
  assert.equal(summary.story_views_this_week, 1);
  assert.equal(summary.offer_detail_views_total, 2);
  assert.equal(summary.offer_detail_views_7d, 1);
  assert.equal(summary.offer_detail_views_prev_7d, 1);
  assert.equal(summary.claim_clicks_total, 1);
  assert.equal(summary.claim_clicks_7d, 1);
  assert.equal(summary.claim_clicks_prev_7d, 0);
  assert.equal(summary.claims_created_total, 1);
  assert.equal(summary.claims_created_7d, 1);
  assert.equal(summary.claims_created_prev_7d, 0);
  assert.equal(summary.redemptions_total, 1);
  assert.equal(summary.redemptions_7d, 1);
  assert.equal(summary.redemptions_prev_7d, 0);

  const expectedCalls7d = isCurrent7d(lastWeekKey) ? 1 : 0;
  const expectedCallsPrev7d = isPrev7d(lastWeekKey) ? 1 : 0;
  const expectedNavs7d =
    (isCurrent7d(thisWeekKey) ? 1 : 0) +
    (isCurrent7d(lastWeekKey) ? 1 : 0);
  const expectedNavsPrev7d =
    (isPrev7d(thisWeekKey) ? 1 : 0) +
    (isPrev7d(lastWeekKey) ? 1 : 0);
  const expectedViews7d =
    (isCurrent7d(thisWeekKey) ? 1 : 0) +
    (isCurrent7d(lastWeekKey) ? 1 : 0);
  const expectedContactIntent7d = expectedCalls7d + expectedNavs7d;
  const expectedContactIntentPrev7d = expectedCallsPrev7d + expectedNavsPrev7d;

  assert.equal(summary.contact_intent_7d, expectedContactIntent7d);
  assert.equal(summary.contact_intent_prev_7d, expectedContactIntentPrev7d);
  assert.equal(
    summary.contact_rate_7d,
    expectedViews7d > 0 ? expectedContactIntent7d / expectedViews7d : 0,
  );
  assert.equal(summary.detail_to_claim_click_rate_7d, 1);
  assert.equal(summary.view_to_claim_rate_7d, 1);
  assert.equal(summary.claim_to_redemption_rate_7d, 1);

  const thisDayKey = dayKeyInTimezone(thisWeekDate, timezone);
  const lastDayKey = dayKeyInTimezone(lastWeekDate, timezone);

  const thisDaySnap = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .doc(thisDayKey)
    .get();
  const lastDaySnap = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .doc(lastDayKey)
    .get();

  assert.equal(thisDaySnap.exists, true);
  assert.equal(lastDaySnap.exists, true);

  const thisDay = thisDaySnap.data();
  const lastDay = lastDaySnap.data();
  assert.ok(thisDay);
  assert.ok(lastDay);

  assert.equal(thisDay.views, 1);
  assert.equal(thisDay.calls, 0);
  assert.equal(thisDay.story_views, 1);
  assert.equal(thisDay.navs, 1);
  assert.equal(thisDay.offer_detail_views, currentOfferKey === thisDayKey ? 1 : 0);
  assert.equal(thisDay.claim_clicks, currentOfferKey === thisDayKey ? 1 : 0);
  assert.equal(thisDay.claims_created, currentOfferKey === thisDayKey ? 1 : 0);
  assert.equal(thisDay.redemptions, currentOfferKey === thisDayKey ? 1 : 0);
  assert.equal(lastDay.views, 1);
  assert.equal(lastDay.calls, 1);
  assert.equal(lastDay.story_views, 0);
  assert.equal(lastDay.navs, 1);

  const currentOfferSnap = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .doc(currentOfferKey)
    .get();
  const prevOfferSnap = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .doc(prevOfferKey)
    .get();
  assert.equal(currentOfferSnap.exists, true);
  assert.equal(prevOfferSnap.exists, true);
  assert.equal(currentOfferSnap.data().offer_detail_views, 1);
  assert.equal(currentOfferSnap.data().claim_clicks, 1);
  assert.equal(currentOfferSnap.data().claims_created, 1);
  assert.equal(currentOfferSnap.data().redemptions, 1);
  assert.equal(prevOfferSnap.data().offer_detail_views, 1);
  assert.equal(prevOfferSnap.data().claim_clicks, 0);
  assert.equal(prevOfferSnap.data().claims_created, 0);
  assert.equal(prevOfferSnap.data().redemptions, 0);

  const offerAnalyticsSnap = await db.collection("venue_offer_analytics")
    .doc(venueId)
    .collection("offers")
    .doc("offer-phase3")
    .get();
  assert.equal(offerAnalyticsSnap.exists, true);
  const offerAnalytics = offerAnalyticsSnap.data();
  assert.ok(offerAnalytics);
  assert.equal(offerAnalytics.offer_id, "offer-phase3");
  assert.equal(offerAnalytics.offer_title_ar, "Offer Phase 3");
  assert.equal(offerAnalytics.status, "available");
  assert.equal(offerAnalytics.detail_views_7d, 1);
  assert.equal(offerAnalytics.detail_views_30d, 2);
  assert.equal(offerAnalytics.claim_clicks_7d, 1);
  assert.equal(offerAnalytics.claim_clicks_30d, 1);
  assert.equal(offerAnalytics.claims_created_7d, 1);
  assert.equal(offerAnalytics.claims_created_30d, 1);
  assert.equal(offerAnalytics.redemptions_7d, 1);
  assert.equal(offerAnalytics.redemptions_30d, 1);
  assert.equal(offerAnalytics.claim_to_redemption_rate_7d, 1);
  assert.equal(offerAnalytics.claim_to_redemption_rate_30d, 1);
});

test("aggregateVenueAnalytics: no events -> zero summary and stable daily docs", async () => {
  await clearFirestore();

  const venueId = "venue-emu-empty";
  await db.collection("merchants").doc("merchant-empty").set({
    uid: "merchant-empty",
    venue_id: venueId,
  });

  await aggregateVenueAnalytics.run();

  const summarySnap = await db.collection("venue_analytics").doc(venueId).get();
  assert.equal(summarySnap.exists, true);
  const summary = summarySnap.data();
  assert.ok(summary);

  assert.equal(summary.venue_id, venueId);
  assert.equal(summary.views_total, 0);
  assert.equal(summary.calls_total, 0);
  assert.equal(summary.story_views_total, 0);
  assert.equal(summary.navs_total, 0);
  assert.equal(summary.views_this_week, 0);
  assert.equal(summary.views_last_week, 0);
  assert.equal(summary.calls_this_week, 0);
  assert.equal(summary.calls_last_week, 0);
  assert.equal(summary.navs_this_week, 0);
  assert.equal(summary.navs_last_week, 0);
  assert.equal(summary.story_views_this_week, 0);
  assert.equal(summary.offer_detail_views_total, 0);
  assert.equal(summary.claim_clicks_total, 0);
  assert.equal(summary.claims_created_total, 0);
  assert.equal(summary.redemptions_total, 0);
  assert.equal(summary.contact_intent_7d, 0);
  assert.equal(summary.contact_rate_7d, 0);
  assert.equal(summary.detail_to_claim_click_rate_7d, 0);
  assert.equal(summary.view_to_claim_rate_7d, 0);
  assert.equal(summary.claim_to_redemption_rate_7d, 0);

  const dailySnap = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .get();

  assert.equal(dailySnap.empty, false);
  assert.equal(dailySnap.size, 30);

  const todayKey = dayKeyInTimezone(new Date(), timezone);
  const todaySnap = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .doc(todayKey)
    .get();

  assert.equal(todaySnap.exists, true);
  const today = todaySnap.data();
  assert.ok(today);
  assert.equal(today.views, 0);
  assert.equal(today.calls, 0);
  assert.equal(today.story_views, 0);
  assert.equal(today.navs, 0);
  assert.equal(today.offer_detail_views, 0);
  assert.equal(today.claim_clicks, 0);
  assert.equal(today.claims_created, 0);
  assert.equal(today.redemptions, 0);
});

test("backfillMerchantAnalytics: falls back to users link and heals merchant profile", async () => {
  await clearFirestore();

  const uid = "merchant-user-link-only";
  const venueId = "venue-backfill-user-link";
  const eventDate = new Date();
  const offerId = "offer-backfill-user-link";

  await db.collection("users").doc(uid).set({
    merchant_venue_id: venueId,
    is_merchant: true,
  });
  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: "Backfill Offer",
    is_active: true,
  });

  await db.collection("venue_events").doc("ev-user-link-1").set({
    venue_id: venueId,
    event_type: "view",
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(eventDate),
  });
  await db.collection("venue_events").doc("ev-user-link-2").set({
    venue_id: venueId,
    event_type: "offer_detail_view",
    offer_id: offerId,
    source: "test",
    created_at: admin.firestore.Timestamp.fromDate(eventDate),
  });

  const result = await backfillMerchantAnalytics.run(
    { days: 7 },
    callableContext({ uid }),
  );

  assert.equal(result.success, true);
  assert.equal(result.venueId, venueId);
  assert.equal(result.days, 7);
  assert.equal(result.summary.views_total, 1);

  const healedMerchant = await db.collection("merchants").doc(uid).get();
  assert.equal(healedMerchant.exists, true);
  assert.equal(healedMerchant.data().venue_id, venueId);

  const offerAnalyticsSnap = await db.collection("venue_offer_analytics")
    .doc(venueId)
    .collection("offers")
    .doc(offerId)
    .get();
  assert.equal(offerAnalyticsSnap.exists, true);
  assert.equal(offerAnalyticsSnap.data().detail_views_7d, 1);
});

test("aggregateVenueAnalytics zeroes stale per-offer docs instead of deleting them", async () => {
  await clearFirestore();

  const venueId = "venue-stale-offer";
  const offerId = "offer-stale-1";

  await db.collection("merchants").doc("merchant-stale").set({
    uid: "merchant-stale",
    venue_id: venueId,
  });
  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: "Stale Offer",
    is_active: true,
  });
  await db.collection("venue_offer_analytics")
    .doc(venueId)
    .collection("offers")
    .doc(offerId)
    .set({
      offer_id: offerId,
      offer_title_ar: "Old Title",
      status: "available",
      detail_views_7d: 9,
      claim_clicks_7d: 4,
      claims_created_7d: 2,
      redemptions_7d: 1,
      claim_to_redemption_rate_7d: 0.5,
    });

  await aggregateVenueAnalytics.run();

  const staleSnap = await db.collection("venue_offer_analytics")
    .doc(venueId)
    .collection("offers")
    .doc(offerId)
    .get();
  assert.equal(staleSnap.exists, true);
  const stale = staleSnap.data();
  assert.ok(stale);
  assert.equal(stale.offer_title_ar, "Stale Offer");
  assert.equal(stale.status, "available");
  assert.equal(stale.detail_views_7d, 0);
  assert.equal(stale.claim_clicks_7d, 0);
  assert.equal(stale.claims_created_7d, 0);
  assert.equal(stale.redemptions_7d, 0);
  assert.equal(stale.claim_to_redemption_rate_7d, 0);
});

test("createClaimToken increments claims_count once for same pending user claim", async () => {
  await clearFirestore();

  const venueId = "venue-counter-1";
  const offerId = "offer-counter-1";

  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: "Test Offer",
    is_active: true,
    claims_count: 0,
    redeemed_count: 0,
  });

  const first = await createClaimToken.run(
    {
      offerId,
      venueId,
      city: "Ramallah",
      source: "emulator_test",
      deviceId: "device-1",
    },
    callableContext({ uid: "user-1" }),
  );

  const second = await createClaimToken.run(
    {
      offerId,
      venueId,
      city: "Ramallah",
      source: "emulator_test",
      deviceId: "device-1",
    },
    callableContext({ uid: "user-1" }),
  );

  assert.ok(first.claimId);
  assert.ok(first.token);
  assert.equal(first.token.length, 32);
  assert.equal(typeof first.expiresAt, "number");

  // Same pending claim should be resumed, not duplicated.
  assert.equal(second.claimId, first.claimId);
  assert.equal(second.token, first.token);

  const offerSnap = await db.collection("offers").doc(offerId).get();
  const offer = offerSnap.data();
  assert.ok(offer);
  assert.equal(offer.claims_count, 1);
  assert.equal(offer.redeemed_count || 0, 0);
  assert.equal(offer.conversion_rate, 0);

  const claimSnap = await db.collection("offer_claims").doc(first.claimId).get();
  const claim = claimSnap.data();
  assert.ok(claim);
  assert.equal(claim.offer_id, offerId);
  assert.equal(claim.venue_id, venueId);
  assert.equal(claim.user_id, "user-1");
  assert.equal(claim.device_id, "device-1");
  assert.equal(claim.status, "pending");

  const claimEventsSnap = await db.collection("venue_events")
    .where("event_type", "==", "offer_claim_created")
    .get();
  assert.equal(claimEventsSnap.size, 1);
  assert.equal(claimEventsSnap.docs[0].data().offer_id, offerId);
});

test("redeemToken updates redeemed counters, conversion and visit/notification docs", async () => {
  await clearFirestore();

  const venueId = "venue-counter-2";
  const offerId = "offer-counter-2";
  const merchantUid = "merchant-1";

  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: "Offer Counter",
    is_active: true,
    claims_count: 0,
    redeemed_count: 0,
  });

  await db.collection("merchants").doc(merchantUid).set({
    uid: merchantUid,
    venue_id: venueId,
  });

  const claimResult = await createClaimToken.run(
    {
      offerId,
      venueId,
      city: "Jerusalem",
      source: "emulator_test",
      deviceId: "customer-device-1",
    },
    callableContext({ uid: "customer-1" }),
  );

  const redeemed = await redeemToken.run(
    { token: claimResult.token, deviceId: "scanner-device-1" },
    callableContext({ uid: merchantUid }),
  );

  assert.equal(redeemed.success, true);

  const offerSnap = await db.collection("offers").doc(offerId).get();
  const offer = offerSnap.data();
  assert.ok(offer);
  assert.equal(offer.claims_count, 1);
  assert.equal(offer.redeemed_count, 1);
  assert.equal(offer.conversion_rate, 1);
  assert.ok(offer.last_redeemed_at);

  const claimSnap = await db.collection("offer_claims").doc(claimResult.claimId).get();
  const claim = claimSnap.data();
  assert.ok(claim);
  assert.equal(claim.status, "redeemed");
  assert.equal(claim.merchant_id, merchantUid);
  assert.ok(claim.redeemed_at);

  const visitSnap = await db
    .collection("visits")
    .where("claim_id", "==", claimResult.claimId)
    .limit(1)
    .get();
  assert.equal(visitSnap.empty, false);
  const visit = visitSnap.docs[0].data();
  assert.equal(visit.offer_id, offerId);
  assert.equal(visit.venue_id, venueId);
  assert.equal(visit.merchant_id, merchantUid);
  assert.equal(visit.scanner_device_id, "scanner-device-1");

  const merchantNotificationsSnap = await db
    .collection("users")
    .doc(merchantUid)
    .collection("notifications")
    .where("type", "==", "offer_redeemed")
    .limit(1)
    .get();
  assert.equal(merchantNotificationsSnap.empty, false);
  const notification = merchantNotificationsSnap.docs[0].data();
  assert.equal(notification.data.offer_id, offerId);

  const redeemedEventsSnap = await db.collection("venue_events")
    .where("event_type", "==", "offer_redeemed")
    .get();
  assert.equal(redeemedEventsSnap.size, 1);
  assert.equal(redeemedEventsSnap.docs[0].data().offer_id, offerId);
});

test("E2E smoke: claim -> redeem -> counters -> aggregate -> dashboard read", async () => {
  await clearFirestore();

  const venueId = "venue-e2e-1";
  const offerId = "offer-e2e-1";
  const merchantUid = "merchant-e2e-1";
  const customerUid = "customer-e2e-1";

  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: "E2E Offer",
    is_active: true,
    claims_count: 0,
    redeemed_count: 0,
  });
  await db.collection("merchants").doc(merchantUid).set({
    uid: merchantUid,
    venue_id: venueId,
  });
  await db.collection("users").doc(merchantUid).set({
    merchant_venue_id: venueId,
    is_merchant: true,
  });

  // 1) claim
  const claim = await createClaimToken.run(
    {
      offerId,
      venueId,
      city: "Ramallah",
      source: "e2e_test",
      deviceId: "customer-device-e2e",
    },
    callableContext({ uid: customerUid }),
  );
  assert.ok(claim.claimId);
  assert.ok(claim.token);

  // 2) redeem
  const redeem = await redeemToken.run(
    { token: claim.token, deviceId: "scanner-device-e2e" },
    callableContext({ uid: merchantUid }),
  );
  assert.equal(redeem.success, true);

  // 3) counters after redeem
  const offerAfterRedeem = (await db.collection("offers").doc(offerId).get()).data();
  assert.ok(offerAfterRedeem);
  assert.equal(offerAfterRedeem.claims_count, 1);
  assert.equal(offerAfterRedeem.redeemed_count, 1);
  assert.equal(offerAfterRedeem.conversion_rate, 1);
  assert.ok(offerAfterRedeem.last_redeemed_at);

  // Seed analytics inputs
  const now = new Date();
  await db.collection("venue_events").doc("e2e-view").set({
    venue_id: venueId,
    event_type: "view",
    source: "e2e_test",
    created_at: admin.firestore.Timestamp.fromDate(now),
  });
  await db.collection("venue_events").doc("e2e-call").set({
    venue_id: venueId,
    event_type: "call",
    source: "e2e_test",
    created_at: admin.firestore.Timestamp.fromDate(now),
  });
  await db.collection("navigation_clicks").doc("e2e-nav").set({
    venue_id: venueId,
    nav_app: "google_maps",
    timestamp: admin.firestore.Timestamp.fromDate(now),
  });

  // 4) aggregate analytics
  await aggregateVenueAnalytics.run();

  // 5) dashboard reads (summary + daily points)
  const summarySnap = await db.collection("venue_analytics").doc(venueId).get();
  assert.equal(summarySnap.exists, true);
  const summary = summarySnap.data();
  assert.ok(summary);
  assert.equal(summary.views_total, 1);
  assert.equal(summary.calls_total, 1);
  assert.equal(summary.navs_total, 1);

  const dailyQuery = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .orderBy("date_key", "desc")
    .limit(7)
    .get();
  assert.equal(dailyQuery.empty, false);

  const todayKey = dayKeyInTimezone(now, timezone);
  const todayDoc = await db
    .collection("venue_analytics_daily")
    .doc(venueId)
    .collection("days")
    .doc(todayKey)
    .get();
  assert.equal(todayDoc.exists, true);

  const today = todayDoc.data();
  assert.ok(today);
  assert.equal(today.views, 1);
  assert.equal(today.calls, 1);
  assert.equal(today.navs, 1);

  // Aggregate step must not break counters
  const offerAfterAggregate = (await db.collection("offers").doc(offerId).get()).data();
  assert.ok(offerAfterAggregate);
  assert.equal(offerAfterAggregate.claims_count, 1);
  assert.equal(offerAfterAggregate.redeemed_count, 1);
  assert.equal(offerAfterAggregate.conversion_rate, 1);
});
