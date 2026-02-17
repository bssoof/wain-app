const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-analytics";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  aggregateVenueAnalytics,
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
  const thisWeekStartKey = weekStartKey(now, timezone);
  const thisWeekKey = thisWeekStartKey;
  const lastWeekKey = dayOffsetKey(thisWeekStartKey, -1);

  const thisWeekDate = dateFromDayKeyAtNoonUtc(thisWeekKey);
  const lastWeekDate = dateFromDayKeyAtNoonUtc(lastWeekKey);

  await db.collection("merchants").doc("merchant-a").set({
    uid: "merchant-a",
    venue_id: venueId,
  });
  await db.collection("merchants").doc("merchant-b").set({
    uid: "merchant-b",
    venue_id: "   ",
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
  assert.equal(lastDay.views, 1);
  assert.equal(lastDay.calls, 1);
  assert.equal(lastDay.story_views, 0);
  assert.equal(lastDay.navs, 1);
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
    { auth: { uid: "user-1" } },
  );

  const second = await createClaimToken.run(
    {
      offerId,
      venueId,
      city: "Ramallah",
      source: "emulator_test",
      deviceId: "device-1",
    },
    { auth: { uid: "user-1" } },
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
    { auth: { uid: "customer-1" } },
  );

  const redeemed = await redeemToken.run(
    { token: claimResult.token, deviceId: "scanner-device-1" },
    { auth: { uid: merchantUid } },
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
    { auth: { uid: customerUid } },
  );
  assert.ok(claim.claimId);
  assert.ok(claim.token);

  // 2) redeem
  const redeem = await redeemToken.run(
    { token: claim.token, deviceId: "scanner-device-e2e" },
    { auth: { uid: merchantUid } },
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
