const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || "demo-wain-security-concurrency";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  createClaimToken,
  validateToken,
  redeemToken,
  redeemInviteCode,
} = require("../../lib/index.js");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
}

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

function tsFromNow(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

function callableContext({ uid = null, appCheck = true } = {}) {
  return {
    auth: uid ? { uid, token: {} } : null,
    app: appCheck ? { appId: "emu-app" } : undefined,
  };
}

async function seedVenue(venueId) {
  await db.collection("venues").doc(venueId).set({
    name_ar: `Venue ${venueId}`,
    lat: 31.9,
    lng: 35.2,
    is_active: true,
  }, { merge: true });
}

async function seedOffer({
  offerId,
  venueId,
  discountType = "amount",
  discountValue = 15,
  isActive = true,
  startOffsetMs = -60_000,
  endOffsetMs = 60 * 60 * 1000,
  singleUsePerCustomer = true,
}) {
  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: `Offer ${offerId}`,
    discount_type: discountType,
    discount_value: discountValue,
    currency: "ILS",
    is_active: isActive,
    start_at: tsFromNow(startOffsetMs),
    end_at: tsFromNow(endOffsetMs),
    single_use_per_customer: singleUsePerCustomer,
    claims_count: 0,
    redeemed_count: 0,
    conversion_rate: 0,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  });
}

async function seedMerchant(uid, venueId) {
  await db.collection("merchants").doc(uid).set({
    uid,
    venue_id: venueId,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  }, { merge: true });

  await db.collection("users").doc(uid).set({
    is_merchant: true,
    merchant_venue_id: venueId,
    updated_at: tsFromNow(-60_000),
  }, { merge: true });
}

async function seedInvite({ inviteId, code, venueId }) {
  await db.collection("merchant_invites").doc(inviteId).set({
    code,
    venue_id: venueId,
    status: "active",
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
    expires_at: tsFromNow(60 * 60 * 1000),
  });
}

function summarizeSettled(results) {
  return results.map((entry) => {
    if (entry.status === "fulfilled") {
      return { status: "fulfilled", value: entry.value };
    }

    const reason = entry.reason || {};
    return {
      status: "rejected",
      code: String(reason.code || ""),
      message: String(reason.message || ""),
    };
  });
}

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("H1 concurrent redeemToken only applies once", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-h1", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-h1", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  const results = await Promise.allSettled([
    redeemToken.run({ token: claim.token, deviceId: "scanner-1" }, callableContext({ uid: "merchant-a" })),
    redeemToken.run({ token: claim.token, deviceId: "scanner-2" }, callableContext({ uid: "merchant-a" })),
  ]);

  const fulfilled = results.filter((entry) => entry.status === "fulfilled");
  const rejected = results.filter((entry) => entry.status === "rejected");

  assert.equal(fulfilled.length, 1, JSON.stringify(summarizeSettled(results), null, 2));
  assert.equal(rejected.length, 1, JSON.stringify(summarizeSettled(results), null, 2));

  const rejection = rejected[0].reason || {};
  assert.match(String(rejection.code || ""), /failed-precondition|aborted/);

  const [claimDoc, offerDoc] = await Promise.all([
    db.collection("offer_claims").doc(claim.claimId).get(),
    db.collection("offers").doc("offer-h1").get(),
  ]);
  const redeemedEventsSnap = await db.collection("venue_events")
    .where("event_type", "==", "offer_redeemed")
    .get();

  assert.equal(claimDoc.data().status, "redeemed");
  assert.equal(offerDoc.data().redeemed_count, 1);
  assert.equal(redeemedEventsSnap.size, 1);
});

test("H2 concurrent validateToken and redeemToken keep single final state", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-h2", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-h2", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  const [validateResult, redeemResult] = await Promise.allSettled([
    validateToken.run({ token: claim.token }, callableContext({ uid: "merchant-a" })),
    redeemToken.run({ token: claim.token, deviceId: "scanner-1" }, callableContext({ uid: "merchant-a" })),
  ]);

  assert.equal(redeemResult.status, "fulfilled", JSON.stringify(summarizeSettled([validateResult, redeemResult]), null, 2));
  assert.equal(redeemResult.value.success, true);

  if (validateResult.status === "fulfilled") {
    if (validateResult.value.valid === false) {
      assert.match(String(validateResult.value.reason || ""), /already_redeemed|venue_inactive|offer_/);
    } else {
      assert.equal(validateResult.value.valid, true);
    }
  } else {
    throw validateResult.reason;
  }

  const [claimDoc, offerDoc] = await Promise.all([
    db.collection("offer_claims").doc(claim.claimId).get(),
    db.collection("offers").doc("offer-h2").get(),
  ]);
  assert.equal(claimDoc.data().status, "redeemed");
  assert.equal(offerDoc.data().redeemed_count, 1);
});

test("H3 concurrent createClaimToken should not create duplicate pending claims", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-h3", venueId: "venue-a" });

  const results = await Promise.allSettled([
    createClaimToken.run(
      { offerId: "offer-h3", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
      callableContext({ uid: "user-a" }),
    ),
    createClaimToken.run(
      { offerId: "offer-h3", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
      callableContext({ uid: "user-a" }),
    ),
  ]);

  const fulfilled = results.filter((entry) => entry.status === "fulfilled");
  assert.equal(fulfilled.length, 2, JSON.stringify(summarizeSettled(results), null, 2));
  assert.equal(
    fulfilled[0].value.claimId,
    fulfilled[1].value.claimId,
    JSON.stringify(summarizeSettled(results), null, 2),
  );
  assert.equal(
    fulfilled[0].value.token,
    fulfilled[1].value.token,
    JSON.stringify(summarizeSettled(results), null, 2),
  );

  const claimsSnap = await db.collection("offer_claims")
    .where("offer_id", "==", "offer-h3")
    .where("user_id", "==", "user-a")
    .get();
  const createdEventsSnap = await db.collection("venue_events")
    .where("event_type", "==", "offer_claim_created")
    .get();

  const offerDoc = await db.collection("offers").doc("offer-h3").get();

  assert.equal(claimsSnap.size, 1, JSON.stringify({
    results: summarizeSettled(results),
    claimIds: claimsSnap.docs.map((doc) => doc.id),
  }, null, 2));
  assert.equal(offerDoc.data().claims_count, 1);
  assert.equal(createdEventsSnap.size, 1);
});

test("H4 concurrent redeemInviteCode for same user is safe", async () => {
  await seedInvite({
    inviteId: "invite-h4",
    code: "WAIN-H4",
    venueId: "venue-a",
  });

  const results = await Promise.allSettled([
    redeemInviteCode.run({ code: "WAIN-H4" }, callableContext({ uid: "merchant-a" })),
    redeemInviteCode.run({ code: "WAIN-H4" }, callableContext({ uid: "merchant-a" })),
  ]);

  const fulfilled = results.filter((entry) => entry.status === "fulfilled");
  const rejected = results.filter((entry) => entry.status === "rejected");

  assert.equal(fulfilled.length, 1, JSON.stringify(summarizeSettled(results), null, 2));
  assert.equal(rejected.length, 1, JSON.stringify(summarizeSettled(results), null, 2));
  assert.match(String(rejected[0].reason.code || ""), /failed-precondition/);

  const [inviteDoc, userDoc, merchantDoc] = await Promise.all([
    db.collection("merchant_invites").doc("invite-h4").get(),
    db.collection("users").doc("merchant-a").get(),
    db.collection("merchants").doc("merchant-a").get(),
  ]);

  assert.equal(inviteDoc.data().used_by, "merchant-a");
  assert.equal(userDoc.data().merchant_venue_id, "venue-a");
  assert.equal(merchantDoc.data().venue_id, "venue-a");
});
