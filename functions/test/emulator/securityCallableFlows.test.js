const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-security";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  createClaimToken,
  validateToken,
  redeemToken,
  redeemInviteCode,
  promoteStory,
  backfillMerchantAnalytics,
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

function tsFromNow(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

function callableContext({ uid = null, appCheck = true } = {}) {
  return {
    auth: uid ? { uid, token: {} } : null,
    app: appCheck ? { appId: "emu-app" } : undefined,
  };
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

async function seedVenue(venueId) {
  await db.collection("venues").doc(venueId).set({
    name_ar: `Venue ${venueId}`,
    lat: 31.9,
    lng: 35.2,
    is_active: true,
  }, { merge: true });
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

async function revokeMerchant(uid, { clearUserLink = true, removeMerchantDoc = true } = {}) {
  if (removeMerchantDoc) {
    await db.collection("merchants").doc(uid).delete();
  }

  if (clearUserLink) {
    await db.collection("users").doc(uid).set({
      merchant_venue_id: admin.firestore.FieldValue.delete(),
      is_merchant: admin.firestore.FieldValue.delete(),
      updated_at: tsFromNow(0),
    }, { merge: true });
  }
}

async function seedInvite({ inviteId, code, venueId, status = "active", usedBy = null, expiresOffsetMs = 60 * 60 * 1000 }) {
  const data = {
    code,
    venue_id: venueId,
    status,
    used_by: usedBy,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
    expires_at: tsFromNow(expiresOffsetMs),
  };
  if (usedBy) {
    data.used_at = tsFromNow(-30_000);
  }
  await db.collection("merchant_invites").doc(inviteId).set(data);
}

async function seedStory({ storyId, venueId, expiresOffsetMs = 60 * 60 * 1000 }) {
  await db.collection("stories").doc(storyId).set({
    venue_id: venueId,
    media_url: `https://example.com/${storyId}.jpg`,
    expires_at: tsFromNow(expiresOffsetMs),
    is_promoted: false,
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
  return error;
}

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("A1 invalid invite code leaves no merchant linkage writes", async () => {
  const ctx = callableContext({ uid: "user-a" });
  await expectHttpsError(
    () => redeemInviteCode.run({ code: "WAIN-000000" }, ctx),
    "not-found",
  );

  const [userDoc, merchantDoc] = await Promise.all([
    db.collection("users").doc("user-a").get(),
    db.collection("merchants").doc("user-a").get(),
  ]);
  assert.equal(userDoc.exists, false);
  assert.equal(merchantDoc.exists, false);
});

test("A2 expired invite code is rejected without partial writes", async () => {
  await seedInvite({
    inviteId: "invite-expired",
    code: "WAIN-EXPIRED",
    venueId: "venue-a",
    expiresOffsetMs: -60_000,
  });

  const ctx = callableContext({ uid: "user-a" });
  await expectHttpsError(
    () => redeemInviteCode.run({ code: "WAIN-EXPIRED" }, ctx),
    "failed-precondition",
    "expired",
  );

  const [inviteDoc, userDoc, merchantDoc] = await Promise.all([
    db.collection("merchant_invites").doc("invite-expired").get(),
    db.collection("users").doc("user-a").get(),
    db.collection("merchants").doc("user-a").get(),
  ]);
  assert.equal(inviteDoc.data().status, "active");
  assert.equal(userDoc.exists, false);
  assert.equal(merchantDoc.exists, false);
});

test("A3 used invite cannot be reused by another account", async () => {
  await seedInvite({
    inviteId: "invite-reuse",
    code: "WAIN-REUSE",
    venueId: "venue-a",
  });

  const first = await redeemInviteCode.run(
    { code: "WAIN-REUSE" },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(first.success, true);

  await expectHttpsError(
    () => redeemInviteCode.run({ code: "WAIN-REUSE" }, callableContext({ uid: "merchant-b" })),
    "failed-precondition",
  );

  const inviteDoc = await db.collection("merchant_invites").doc("invite-reuse").get();
  assert.equal(inviteDoc.data().used_by, "merchant-a");
  const merchantBDoc = await db.collection("merchants").doc("merchant-b").get();
  assert.equal(merchantBDoc.exists, false);
});

test("A4 already linked merchant cannot switch venue with another invite", async () => {
  await seedMerchant("merchant-a", "venue-b");
  await seedInvite({
    inviteId: "invite-switch",
    code: "WAIN-SWITCH",
    venueId: "venue-a",
  });

  await expectHttpsError(
    () => redeemInviteCode.run({ code: "WAIN-SWITCH" }, callableContext({ uid: "merchant-a" })),
    "failed-precondition",
    "another venue",
  );

  const userDoc = await db.collection("users").doc("merchant-a").get();
  assert.equal(userDoc.data().merchant_venue_id, "venue-b");
});

test("A5 invite flow rejects missing App Check", async () => {
  await seedInvite({ inviteId: "invite-appcheck", code: "WAIN-APPCHK", venueId: "venue-a" });

  await expectHttpsError(
    () => redeemInviteCode.run({ code: "WAIN-APPCHK" }, callableContext({ uid: "user-a", appCheck: false })),
    "failed-precondition",
    "App Check",
  );
});

test("A6 invite retries hit rate limit after five bad attempts", async () => {
  const ctx = callableContext({ uid: "user-a" });

  for (let i = 0; i < 5; i += 1) {
    await expectHttpsError(
      () => redeemInviteCode.run({ code: `BAD-${i}` }, ctx),
      "not-found",
    );
  }

  await expectHttpsError(
    () => redeemInviteCode.run({ code: "BAD-6" }, ctx),
    "resource-exhausted",
  );
});

test("B2 merchant from another venue cannot redeem claim", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-a", venueId: "venue-a" });
  await seedMerchant("merchant-b", "venue-b");

  const claim = await createClaimToken.run(
    { offerId: "offer-a", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  await expectHttpsError(
    () => redeemToken.run({ token: claim.token }, callableContext({ uid: "merchant-b" })),
    "permission-denied",
  );

  const claimDoc = await db.collection("offer_claims").doc(claim.claimId).get();
  assert.equal(claimDoc.data().status, "pending");
});

test("B3 merchant cannot promote another venue story", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedStory({ storyId: "story-b", venueId: "venue-b" });

  await expectHttpsError(
    () => promoteStory.run(
      { storyId: "story-b", durationDays: 2 },
      callableContext({ uid: "merchant-a" }),
    ),
    "permission-denied",
  );

  const storyDoc = await db.collection("stories").doc("story-b").get();
  assert.equal(storyDoc.data().is_promoted, false);
});

test("C1b guest claim without deviceId is rejected", async () => {
  await seedOffer({ offerId: "offer-a", venueId: "venue-a" });

  await expectHttpsError(
    () => createClaimToken.run(
      { offerId: "offer-a", venueId: "venue-a", city: "ramallah", source: "test" },
      callableContext(),
    ),
    "invalid-argument",
    "Missing required fields",
  );
});

test("C1c single-use guest cannot re-claim after redeem on same device", async () => {
  await seedVenue("venue-a");
  await seedOffer({
    offerId: "offer-single",
    venueId: "venue-a",
    singleUsePerCustomer: true,
  });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-single", venueId: "venue-a", deviceId: "guest-device", city: "ramallah", source: "test" },
    callableContext(),
  );

  await redeemToken.run(
    { token: claim.token, deviceId: "merchant-scanner" },
    callableContext({ uid: "merchant-a" }),
  );

  await expectHttpsError(
    () => createClaimToken.run(
      { offerId: "offer-single", venueId: "venue-a", deviceId: "guest-device", city: "ramallah", source: "test" },
      callableContext(),
    ),
    "failed-precondition",
    "offer_already_used",
  );
});

test("C2 repeated validateToken does not redeem claim", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-validate", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-validate", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  const first = await validateToken.run({ token: claim.token }, callableContext({ uid: "merchant-a" }));
  const second = await validateToken.run({ token: claim.token }, callableContext({ uid: "merchant-a" }));
  assert.equal(first.valid, true);
  assert.equal(second.valid, true);

  const claimDoc = await db.collection("offer_claims").doc(claim.claimId).get();
  assert.equal(claimDoc.data().status, "pending");
});

test("C3 redeem same token twice only applies once", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-redeem", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-redeem", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  const first = await redeemToken.run(
    { token: claim.token, deviceId: "merchant-scanner" },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(first.success, true);

  await expectHttpsError(
    () => redeemToken.run(
      { token: claim.token, deviceId: "merchant-scanner" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition|aborted",
  );

  const [claimDoc, offerDoc] = await Promise.all([
    db.collection("offer_claims").doc(claim.claimId).get(),
    db.collection("offers").doc("offer-redeem").get(),
  ]);
  assert.equal(claimDoc.data().status, "redeemed");
  assert.equal(offerDoc.data().redeemed_count, 1);
});

test("C3b expired token cannot be redeemed", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedOffer({ offerId: "offer-expired", venueId: "venue-a" });

  const token = "expired-token";
  const tokenHash = require("crypto").createHash("sha256").update(token).digest("hex");
  await db.collection("offer_claims").doc("claim-expired").set({
    offer_id: "offer-expired",
    venue_id: "venue-a",
    device_id: "device-a",
    user_id: "user-a",
    status: "pending",
    token,
    token_hash: tokenHash,
    created_at: tsFromNow(-60_000),
    expires_at: tsFromNow(-1_000),
  });

  await expectHttpsError(
    () => redeemToken.run({ token }, callableContext({ uid: "merchant-a" })),
    "failed-precondition",
    "Token expired",
  );

  const claimDoc = await db.collection("offer_claims").doc("claim-expired").get();
  assert.equal(claimDoc.data().status, "pending");
});

test("C7 createClaimToken rejects venue mismatch tampering", async () => {
  await seedOffer({ offerId: "offer-a", venueId: "venue-a" });

  await expectHttpsError(
    () => createClaimToken.run(
      { offerId: "offer-a", venueId: "venue-b", deviceId: "device-a", city: "ramallah", source: "test" },
      callableContext({ uid: "user-a" }),
    ),
    "invalid-argument",
    "venue_mismatch",
  );

  const claims = await db.collection("offer_claims").get();
  assert.equal(claims.size, 0);
});

test("C8 redeemToken rejects invalid bill amounts", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-percent", venueId: "venue-a", discountType: "percent", discountValue: 25 });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-percent", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  for (const bad of [0, -1, "NaN", Number.POSITIVE_INFINITY, 100001, "999999999999999999999999999"]) {
    await expectHttpsError(
      () => redeemToken.run(
        { token: claim.token, billAmount: bad, deviceId: "merchant-scanner" },
        callableContext({ uid: "merchant-a" }),
      ),
      "invalid-argument",
      "invalid_bill_amount",
    );
  }

  const claimDoc = await db.collection("offer_claims").doc(claim.claimId).get();
  assert.equal(claimDoc.data().status, "pending");
});

test("C10 deactivated offer cannot be validated or redeemed from active claim", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-deactivate", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-deactivate", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  await db.collection("offers").doc("offer-deactivate").set({
    is_active: false,
    updated_at: tsFromNow(),
  }, { merge: true });

  const validateResult = await validateToken.run(
    { token: claim.token },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(validateResult.valid, false);
  assert.equal(validateResult.reason, "offer_inactive");

  await expectHttpsError(
    () => redeemToken.run(
      { token: claim.token, deviceId: "merchant-scanner" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "offer_inactive",
  );
});

test("J1 full revocation blocks redeem, promote, and analytics backfill", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-revoke", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");
  await seedStory({ storyId: "story-a", venueId: "venue-a" });

  const claim = await createClaimToken.run(
    { offerId: "offer-revoke", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  await revokeMerchant("merchant-a", { clearUserLink: true, removeMerchantDoc: true });

  await expectHttpsError(
    () => redeemToken.run({ token: claim.token }, callableContext({ uid: "merchant-a" })),
    "permission-denied",
  );

  await expectHttpsError(
    () => promoteStory.run(
      { storyId: "story-a", durationDays: 2 },
      callableContext({ uid: "merchant-a" }),
    ),
    "permission-denied",
  );

  await expectHttpsError(
    () => backfillMerchantAnalytics.run(
      { days: 7 },
      callableContext({ uid: "merchant-a" }),
    ),
    "permission-denied",
  );
});

test("J1b partial revocation via merchant doc deletion still allows analytics self-heal from user link", async () => {
  await seedMerchant("merchant-a", "venue-a");

  await revokeMerchant("merchant-a", { clearUserLink: false, removeMerchantDoc: true });

  const result = await backfillMerchantAnalytics.run(
    { days: 7 },
    callableContext({ uid: "merchant-a" }),
  );

  assert.equal(result.success, true);
  assert.equal(result.venueId, "venue-a");

  const merchantDoc = await db.collection("merchants").doc("merchant-a").get();
  assert.equal(merchantDoc.exists, true);
  assert.equal(merchantDoc.data().venue_id, "venue-a");
});

test("J2 inactive venue blocks validate and redeem", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-inactive-venue", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-inactive-venue", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  await db.collection("venues").doc("venue-a").set({ is_active: false }, { merge: true });

  const validation = await validateToken.run(
    { token: claim.token },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(validation.valid, false);
  assert.equal(validation.reason, "venue_inactive");

  await expectHttpsError(
    () => redeemToken.run(
      { token: claim.token },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "venue_inactive",
  );

  const claimDoc = await db.collection("offer_claims").doc(claim.claimId).get();
  assert.equal(claimDoc.data().status, "pending");
});

test("J2b inactive venue blocks story promotion", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedStory({ storyId: "story-inactive-venue", venueId: "venue-a" });

  await db.collection("venues").doc("venue-a").set({ is_active: false }, { merge: true });

  await expectHttpsError(
    () => promoteStory.run(
      { storyId: "story-inactive-venue", durationDays: 2 },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "venue_inactive",
  );

  const storyDoc = await db.collection("stories").doc("story-inactive-venue").get();
  assert.equal(storyDoc.data().is_promoted, false);
});

test("J3 in-flight revocation blocks redeem after successful preview", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-preview-revoke", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");

  const claim = await createClaimToken.run(
    { offerId: "offer-preview-revoke", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  const preview = await validateToken.run(
    { token: claim.token },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(preview.valid, true);

  await revokeMerchant("merchant-a", { clearUserLink: false, removeMerchantDoc: true });

  await expectHttpsError(
    () => redeemToken.run({ token: claim.token }, callableContext({ uid: "merchant-a" })),
    "permission-denied",
  );

  const claimDoc = await db.collection("offer_claims").doc(claim.claimId).get();
  assert.equal(claimDoc.data().status, "pending");
});
