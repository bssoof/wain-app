const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-security";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.FIREBASE_STORAGE_EMULATOR_HOST =
  process.env.FIREBASE_STORAGE_EMULATOR_HOST || "127.0.0.1:9199";

const admin = require("firebase-admin");
const { StorageEmulator } = require(path.join(
  process.env.APPDATA,
  "npm",
  "node_modules",
  "firebase-tools",
  "lib",
  "emulator",
  "storage",
));
const { EmulatorRegistry } = require(path.join(
  process.env.APPDATA,
  "npm",
  "node_modules",
  "firebase-tools",
  "lib",
  "emulator",
  "registry",
));
const {
  createClaimToken,
  validateToken,
  redeemToken,
  redeemInviteCode,
  promoteStory,
  pinOffer,
  backfillMerchantAnalytics,
  createMerchantTopUpRequest,
  reviewMerchantTopUpRequest,
  runWalletLifecycleMaintenance,
  runWalletExpiryReminderMaintenance,
  rebuildWalletReportForVenue,
  reverseWalletEntry,
  approveWalletReversalRequest,
  verifyWalletOperationalReadiness,
  listMerchantTopUpRequestsForAdmin,
  listMerchantWalletLedgerEntriesForAdmin,
  getAdminVenueWorkspaceReadBundle,
  listVenueReviewsForAdmin,
  moderateVenueReviewForAdmin,
  getAdminMediaInventoryReadBundle,
  mediaSoftDeleteAsset,
  mediaQuarantineAsset,
  mediaReferenceCheckAsset,
  mediaPurgeAsset,
  getAdminConfigGovernanceBundle,
  configUpsertDraft,
  configReviewDraft,
  configPublishDraft,
  configRollbackVersion,
} = require("../../lib/index.js");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
const [storageHost, storagePortValue] =
  process.env.FIREBASE_STORAGE_EMULATOR_HOST.split(":");
const storagePort = Number(storagePortValue);
const storageRules = fs.readFileSync(
  path.resolve(__dirname, "../../../storage.rules"),
  "utf8",
);
const storageBucketName = `${projectId}.appspot.com`;
let storageEmulator;

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

function callableContext({ uid = null, appCheck = true, token = {} } = {}) {
  return {
    auth: uid ? { uid, token } : null,
    app: appCheck ? { appId: "emu-app" } : undefined,
  };
}

async function clearStorageBucket() {
  const [files] = await admin.storage().bucket(storageBucketName).getFiles({
    prefix: "venues/",
  });
  await Promise.all(files.map((file) => file.delete().catch(() => undefined)));
}

async function getUserNotifications(uid, type = null) {
  const snap = await db.collection("users").doc(uid).collection("notifications").get();
  return snap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((notification) => !type || notification.type === type);
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

async function seedVenueReview({
  venueId,
  reviewId,
  rating = 5,
  status = "published",
  comment = "Great venue experience",
  userName = "Reviewer",
} = {}) {
  await seedVenue(venueId);
  await db.collection("venues").doc(venueId).collection("reviews").doc(reviewId).set({
    user_id: `user_${reviewId}`,
    user_name: userName,
    rating,
    comment,
    status,
    hidden: status === "hidden",
    is_hidden: status === "hidden",
    flagged: status === "flagged",
    is_flagged: status === "flagged",
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
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

async function seedUserNotificationPrefs(uid, prefs) {
  await db.collection("users").doc(uid).set({
    ...prefs,
    updated_at: tsFromNow(-60_000),
  }, { merge: true });
}

async function seedWallet(venueId, { balance = 0, status = "active" } = {}) {
  await db.collection("merchant_wallets").doc(venueId).set({
    venue_id: venueId,
    currency: "ILS",
    status,
    available_balance: balance,
    low_balance_threshold: 10,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
    last_entry_at: null,
    last_top_up_at: null,
  }, { merge: true });
}

async function seedStoryPromotionPricing({
  currency = "ILS",
  oneDay = 3,
  threeDays = 7,
  sevenDays = 14,
  offerOneDay = 4,
  offerThreeDays = 9,
  offerSevenDays = 16,
} = {}) {
  await db.collection("wallet_feature_pricing").doc("default").set({
    currency,
    story_promote_1d: oneDay,
    story_promote_3d: threeDays,
    story_promote_7d: sevenDays,
    offer_pin_1d: offerOneDay,
    offer_pin_3d: offerThreeDays,
    offer_pin_7d: offerSevenDays,
    updated_at: tsFromNow(-60_000),
  });
}

async function seedAdmin(uid, { active = true, role = null } = {}) {
  const adminData = {
    active,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  };
  if (role) {
    adminData.role = role;
    adminData.roles = [role];
  }

  await db.collection("admins").doc(uid).set(adminData, { merge: true });
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

async function seedReversibleDebitEntry({
  venueId = "venue-a",
  entryId,
  amount,
  balanceBefore = 600,
  featureKey = "story_promotion",
  referenceType = "story",
  referenceId = null,
} = {}) {
  const resolvedReferenceId = referenceId || `${referenceType}-${entryId}`;
  const balanceAfter = balanceBefore - amount;
  await seedVenue(venueId);
  await seedWallet(venueId, { balance: balanceAfter, status: "active" });
  await db
    .collection("merchant_wallets")
    .doc(venueId)
    .collection("entries")
    .doc(entryId)
    .set({
      venue_id: venueId,
      type: "debit",
      amount,
      currency: "ILS",
      balance_after: balanceAfter,
      feature_key: featureKey,
      reference_type: referenceType,
      reference_id: resolvedReferenceId,
      created_by_type: "merchant",
      created_by_uid: "merchant-a",
      metadata: { request_id: `seed_${entryId}` },
      created_at: tsFromNow(-2_000),
    });

  return {
    balanceAfter,
    balanceBefore,
  };
}

async function seedProofObject(storagePath) {
  await admin.storage().bucket(storageBucketName).file(storagePath).save(
    Buffer.from("proof-image"),
    { metadata: { contentType: "image/jpeg" } },
  );
}

function mediaAssetDocIdFromKey(assetKey) {
  return crypto.createHash("sha1").update(assetKey).digest("hex");
}

async function seedHealthyMediaReferenceIndex() {
  await db.collection("media_reference_index").doc("health").set({
    current_health_status: "healthy",
    last_successful_build_at: tsFromNow(-2_000),
    updated_at: tsFromNow(-2_000),
  });
}

async function seedTrustedGovernanceAsset({
  storagePath,
  sourceCollection = "merchant_topup_requests",
  sourceDocumentId,
  targetType = "topup_proof",
  targetId = sourceDocumentId,
  venueId = "venue-a",
  currentState = "quarantined",
}) {
  await db
    .collection("media_governance_assets")
    .doc(mediaAssetDocIdFromKey(storagePath))
    .set({
      asset_key: storagePath,
      target_type: targetType,
      target_id: targetId,
      venue_id: venueId,
      source_collection: sourceCollection,
      source_document_id: sourceDocumentId,
      source_path: `${sourceCollection}/${sourceDocumentId}`,
      media_url: storagePath,
      storage_path: storagePath,
      reference_type: "topup_request",
      reference_id: sourceDocumentId,
      current_state: currentState,
      trusted_source_bound: true,
      discovered_via_reference_index: true,
      created_at: tsFromNow(-60_000),
      updated_at: tsFromNow(-2_000),
    });
}

async function storageObjectExists(storagePath) {
  const [exists] = await admin.storage().bucket(storageBucketName).file(storagePath).exists();
  return exists;
}

test.before(async () => {
  storageEmulator = new StorageEmulator({
    host: storageHost,
    port: storagePort,
    projectId,
    rules: {
      name: path.resolve(__dirname, "../../../storage.rules"),
      content: storageRules,
    },
  });
  await EmulatorRegistry.start(storageEmulator);
});

test.beforeEach(async () => {
  await clearFirestore();
  await clearStorageBucket();
  await seedAdmin("admin-a", { role: "finance_admin" });
  await seedAdmin("admin-b", { role: "finance_admin" });
  await seedAdmin("admin-super", { role: "super_admin" });
});

test.after(async () => {
  await EmulatorRegistry.stop("storage");
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
      { storyId: "story-b", durationDays: 1, requestId: "promo_other_venue" },
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
      { storyId: "story-a", durationDays: 1, requestId: "promo_revoked_merchant" },
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
      { storyId: "story-inactive-venue", durationDays: 1, requestId: "promo_inactive_venue" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "venue_inactive",
  );

  const storyDoc = await db.collection("stories").doc("story-inactive-venue").get();
  assert.equal(storyDoc.data().is_promoted, false);
});

test("J2c missing venue is_active does not block validate, redeem, or story promotion", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-missing-venue-active", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 50 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-missing-venue-active", venueId: "venue-a" });

  const claim = await createClaimToken.run(
    { offerId: "offer-missing-venue-active", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  await db.collection("venues").doc("venue-a").set({
    is_active: admin.firestore.FieldValue.delete(),
  }, { merge: true });

  const validation = await validateToken.run(
    { token: claim.token },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(validation.valid, true);

  const redeem = await redeemToken.run(
    { token: claim.token },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(redeem.success, true);

  const promote = await promoteStory.run(
    {
      storyId: "story-missing-venue-active",
      durationDays: 3,
      requestId: "promo_missing_venue_active",
    },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(promote.success, true);
  assert.equal(promote.charged_amount, 7);

  const [storyDoc, walletDoc, entriesSnap] = await Promise.all([
    db.collection("stories").doc("story-missing-venue-active").get(),
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(storyDoc.data().is_promoted, true);
  assert.equal(walletDoc.data().available_balance, 43);
  assert.equal(entriesSnap.size, 1);
  assert.equal(entriesSnap.docs[0].data().type, "debit");
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

test("W5 createMerchantTopUpRequest requires auth and merchant link", async () => {
  await expectHttpsError(
    () => createMerchantTopUpRequest.run(
      { amount: 100 },
      callableContext(),
    ),
    "unauthenticated",
  );

  await expectHttpsError(
    () => createMerchantTopUpRequest.run(
      { amount: 100 },
      callableContext({ uid: "user-a" }),
    ),
    "permission-denied",
    "Not a merchant",
  );

  const requests = await db.collection("merchant_topup_requests").get();
  assert.equal(requests.size, 0);
});

test("W6 createMerchantTopUpRequest creates pending request and zero-state wallet", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedProofObject("venues/venue-a/wallet_topups/proof-1.jpg");

  const result = await createMerchantTopUpRequest.run(
    {
      amount: 100,
      proof_image_url: "venues/venue-a/wallet_topups/proof-1.jpg",
      transfer_reference: "BANK-123",
      note: "manual transfer",
    },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(result.success, true);

  const [walletDoc, requestSnap] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_topup_requests")
      .where("venue_id", "==", "venue-a")
      .get(),
  ]);

  assert.equal(walletDoc.exists, true);
  assert.equal(walletDoc.data().available_balance, 0);
  assert.equal(walletDoc.data().status, "active");
  assert.equal(requestSnap.size, 1);

  const requestData = requestSnap.docs[0].data();
  assert.equal(requestData.requested_by_uid, "merchant-a");
  assert.equal(requestData.amount, 100);
  assert.equal(requestData.status, "pending");
  assert.equal(requestData.transfer_reference, "BANK-123");
  assert.equal(requestData.proof_image_url, "venues/venue-a/wallet_topups/proof-1.jpg");
  assert.ok(requestData.proof_uploaded_at);
  assert.ok(requestData.proof_retention_until);
});

test("W6d createMerchantTopUpRequest is idempotent for the same client requestId", async () => {
  await seedMerchant("merchant-a", "venue-a");

  const payload = {
    amount: 100,
    requestId: "topup_client_retry_1",
    transfer_reference: "BANK-RETRY-1",
    note: "manual transfer",
  };
  const first = await createMerchantTopUpRequest.run(
    payload,
    callableContext({ uid: "merchant-a" }),
  );
  const second = await createMerchantTopUpRequest.run(
    payload,
    callableContext({ uid: "merchant-a" }),
  );

  assert.equal(first.success, true);
  assert.equal(first.idempotent, false);
  assert.equal(first.requestId, "topup_venue-a_topup_client_retry_1");
  assert.equal(second.success, true);
  assert.equal(second.idempotent, true);
  assert.equal(second.requestId, first.requestId);
  assert.equal(second.status, "pending");

  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .get();
  assert.equal(requestSnap.size, 1);
  assert.equal(requestSnap.docs[0].id, first.requestId);
  assert.equal(requestSnap.docs[0].data().client_request_id, "topup_client_retry_1");

  await expectHttpsError(
    () => createMerchantTopUpRequest.run(
      { ...payload, amount: 110 },
      callableContext({ uid: "merchant-a" }),
    ),
    "already-exists",
    "topup_request_conflict",
  );
});

test("W6b createMerchantTopUpRequest rejects invalid proof storage path", async () => {
  await seedMerchant("merchant-a", "venue-a");

  await expectHttpsError(
    () => createMerchantTopUpRequest.run(
      { amount: 100, proof_image_url: "https://example.com/external-proof.jpg" },
      callableContext({ uid: "merchant-a" }),
    ),
    "invalid-argument",
    "invalid_proof_storage_path",
  );
});

test("W6c createMerchantTopUpRequest rejects missing proof object", async () => {
  await seedMerchant("merchant-a", "venue-a");

  await expectHttpsError(
    () => createMerchantTopUpRequest.run(
      { amount: 100, proof_image_url: "venues/venue-a/wallet_topups/missing-proof.jpg" },
      callableContext({ uid: "merchant-a" }),
    ),
    "invalid-argument",
    "proof_file_not_found",
  );

  const requests = await db.collection("merchant_topup_requests").get();
  assert.equal(requests.size, 0);
});

test("W7 reviewMerchantTopUpRequest credits pending request once", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await createMerchantTopUpRequest.run(
    { amount: 120, note: "credit me" },
    callableContext({ uid: "merchant-a" }),
  );

  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const requestId = requestSnap.docs[0].id;

  const result = await reviewMerchantTopUpRequest.run(
    { requestId, decision: "credit", adminNote: "approved" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );
  assert.equal(result.success, true);

  const [walletDoc, requestDoc, entriesSnap] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_topup_requests").doc(requestId).get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);

  assert.equal(walletDoc.data().available_balance, 120);
  assert.equal(requestDoc.data().status, "credited");
  assert.equal(requestDoc.data().reviewed_by_uid, "admin-a");
  assert.ok(requestDoc.data().linked_entry_id);
  assert.equal(entriesSnap.size, 1);
  assert.equal(requestDoc.data().linked_entry_id, entriesSnap.docs[0].id);
  const entryData = entriesSnap.docs[0].data();
  assert.equal(entryData.reference_id, requestId);
  assert.equal(entryData.balance_after, 120);
  assert.equal(entryData.created_by_type, "admin");
  assert.equal(entryData.idempotency_key, `topup_credit_${requestId}`);
  assert.deepEqual(entryData.metadata ?? {}, {});

  await expectHttpsError(
    () => reviewMerchantTopUpRequest.run(
      { requestId, decision: "credit" },
      callableContext({ uid: "admin-a", token: { admin: true } }),
    ),
    "failed-precondition",
    "already processed",
  );

  const entriesAfterRetry = await db.collection("merchant_wallets")
    .doc("venue-a")
    .collection("entries")
    .get();
  assert.equal(entriesAfterRetry.size, 1);
});

test("W8 reviewMerchantTopUpRequest denies non-admin reviewers", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await createMerchantTopUpRequest.run(
    { amount: 70 },
    callableContext({ uid: "merchant-a" }),
  );

  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const requestId = requestSnap.docs[0].id;

  await expectHttpsError(
    () => reviewMerchantTopUpRequest.run(
      { requestId, decision: "credit" },
      callableContext({ uid: "staff-a" }),
    ),
    "permission-denied",
    "admin",
  );
});

test("W8b reviewMerchantTopUpRequest reject requires admin note", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedProofObject("venues/venue-a/wallet_topups/proof-reject.jpg");
  await createMerchantTopUpRequest.run(
    { amount: 70, proof_image_url: "venues/venue-a/wallet_topups/proof-reject.jpg" },
    callableContext({ uid: "merchant-a" }),
  );

  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const requestId = requestSnap.docs[0].id;

  await expectHttpsError(
    () => reviewMerchantTopUpRequest.run(
      { requestId, decision: "reject" },
      callableContext({ uid: "admin-a", token: { admin: true } }),
    ),
    "invalid-argument",
    "admin_note_required_for_reject",
  );
});

test("W9 reviewMerchantTopUpRequest accepts admins collection fallback", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedAdmin("admin-doc");
  await createMerchantTopUpRequest.run(
    { amount: 55 },
    callableContext({ uid: "merchant-a" }),
  );

  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const requestId = requestSnap.docs[0].id;

  const result = await reviewMerchantTopUpRequest.run(
    { requestId, decision: "reject", adminNote: "missing proof" },
    callableContext({ uid: "admin-doc" }),
  );
  assert.equal(result.success, true);

  const requestDoc = await db.collection("merchant_topup_requests").doc(requestId).get();
  assert.equal(requestDoc.data().status, "rejected");
  assert.equal(requestDoc.data().reviewed_by_uid, "admin-doc");
});

test("W10 promoteStory debits wallet and updates story in one transaction", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 20 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-wallet-success", venueId: "venue-a" });

  const result = await promoteStory.run(
    {
      storyId: "story-wallet-success",
      durationDays: 1,
      requestId: "promo_wallet_success",
    },
    callableContext({ uid: "merchant-a" }),
  );

  assert.equal(result.success, true);
  assert.equal(result.charged_amount, 3);
  assert.equal(result.balance_after, 17);
  assert.equal(result.idempotent, false);

  const [storyDoc, walletDoc, entryDoc] = await Promise.all([
    db.collection("stories").doc("story-wallet-success").get(),
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets")
      .doc("venue-a")
      .collection("entries")
      .doc("story_promotion_promo_wallet_success")
      .get(),
  ]);

  assert.equal(storyDoc.data().is_promoted, true);
  assert.equal(walletDoc.data().available_balance, 17);
  assert.equal(entryDoc.exists, true);
  assert.equal(entryDoc.data().amount, 3);
  assert.equal(entryDoc.data().feature_key, "story_promotion");
});

test("W11 promoteStory rejects insufficient balance without partial writes", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 2 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-wallet-low", venueId: "venue-a" });

  await expectHttpsError(
    () => promoteStory.run(
      {
        storyId: "story-wallet-low",
        durationDays: 1,
        requestId: "promo_wallet_low",
      },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "insufficient_wallet_balance",
  );

  const [storyDoc, walletDoc, entriesSnap] = await Promise.all([
    db.collection("stories").doc("story-wallet-low").get(),
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(storyDoc.data().is_promoted, false);
  assert.equal(walletDoc.data().available_balance, 2);
  assert.equal(entriesSnap.size, 0);
});

test("W12 promoteStory is idempotent for the same requestId", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 30 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-wallet-idempotent", venueId: "venue-a" });

  const payload = {
    storyId: "story-wallet-idempotent",
    durationDays: 3,
    requestId: "promo_wallet_idempotent",
  };

  const first = await promoteStory.run(payload, callableContext({ uid: "merchant-a" }));
  const second = await promoteStory.run(payload, callableContext({ uid: "merchant-a" }));

  assert.equal(first.success, true);
  assert.equal(first.idempotent, false);
  assert.equal(second.success, true);
  assert.equal(second.idempotent, true);

  const [walletDoc, entriesSnap] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(walletDoc.data().available_balance, 23);
  assert.equal(entriesSnap.size, 1);
});

test("W13 promoteStory fails when pricing config is missing", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 30 });
  await seedStory({ storyId: "story-wallet-no-pricing", venueId: "venue-a" });

  await expectHttpsError(
    () => promoteStory.run(
      {
        storyId: "story-wallet-no-pricing",
        durationDays: 1,
        requestId: "promo_wallet_no_pricing",
      },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "pricing_unavailable",
  );

  const entriesSnap = await db.collection("merchant_wallets")
    .doc("venue-a")
    .collection("entries")
    .get();
  assert.equal(entriesSnap.size, 0);
});

test("W14 promoteStory rejects inactive wallet", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 30, status: "suspended" });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-wallet-inactive", venueId: "venue-a" });

  await expectHttpsError(
    () => promoteStory.run(
      {
        storyId: "story-wallet-inactive",
        durationDays: 1,
        requestId: "promo_wallet_inactive",
      },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "wallet_inactive",
  );
});

test("W15 pinOffer debits wallet and updates offer in one transaction", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 30 });
  await seedStoryPromotionPricing();
  await seedOffer({ offerId: "offer-pin-success", venueId: "venue-a", endOffsetMs: 10 * 24 * 60 * 60 * 1000 });

  const result = await pinOffer.run(
    { offerId: "offer-pin-success", durationDays: 3, requestId: "pin_offer_success" },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(result.success, true);
  assert.equal(result.idempotent, false);
  assert.equal(result.charged_amount, 9);
  assert.equal(result.balance_after, 21);

  const [offerDoc, walletDoc, entryDoc] = await Promise.all([
    db.collection("offers").doc("offer-pin-success").get(),
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_pin_offer_success").get(),
  ]);
  assert.equal(offerDoc.data().is_featured, true);
  assert.ok(offerDoc.data().featured_until);
  assert.equal(walletDoc.data().available_balance, 21);
  assert.equal(entryDoc.data().feature_key, "offer_pin");
  assert.equal(entryDoc.data().reference_type, "offer");
  assert.equal(entryDoc.data().reference_id, "offer-pin-success");
  assert.equal(entryDoc.data().metadata.duration_days, 3);
});

test("W16 pinOffer fails on insufficient balance without partial writes", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 1 });
  await seedStoryPromotionPricing();
  await seedOffer({ offerId: "offer-pin-low", venueId: "venue-a" });

  await expectHttpsError(
    () => pinOffer.run(
      { offerId: "offer-pin-low", durationDays: 1, requestId: "pin_offer_low" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "insufficient_wallet_balance",
  );

  const [offerDoc, walletDoc, entriesSnap] = await Promise.all([
    db.collection("offers").doc("offer-pin-low").get(),
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(offerDoc.data().is_featured, undefined);
  assert.equal(walletDoc.data().available_balance, 1);
  assert.equal(entriesSnap.size, 0);
});

test("W17 pinOffer is idempotent and does not double-charge", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 40 });
  await seedStoryPromotionPricing();
  await seedOffer({ offerId: "offer-pin-idempotent", venueId: "venue-a" });

  const payload = { offerId: "offer-pin-idempotent", durationDays: 1, requestId: "pin_offer_idempotent" };
  const first = await pinOffer.run(payload, callableContext({ uid: "merchant-a" }));
  const second = await pinOffer.run(payload, callableContext({ uid: "merchant-a" }));
  assert.equal(first.idempotent, false);
  assert.equal(second.idempotent, true);

  const [walletDoc, entriesSnap] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(walletDoc.data().available_balance, 36);
  assert.equal(entriesSnap.size, 1);
});

test("W18 pinOffer blocks inactive wallet and missing pricing", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 40, status: "suspended" });
  await seedStoryPromotionPricing();
  await seedOffer({ offerId: "offer-pin-wallet-inactive", venueId: "venue-a" });

  await expectHttpsError(
    () => pinOffer.run(
      { offerId: "offer-pin-wallet-inactive", durationDays: 1, requestId: "pin_offer_wallet_inactive" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "wallet_inactive",
  );

  await seedWallet("venue-a", { balance: 40, status: "active" });
  await db.collection("wallet_feature_pricing").doc("default").delete();
  await expectHttpsError(
    () => pinOffer.run(
      { offerId: "offer-pin-wallet-inactive", durationDays: 1, requestId: "pin_offer_no_pricing" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "pricing_unavailable",
  );
});

test("W19 pinOffer rejects other venue and inactive/expired offers", async () => {
  await seedVenue("venue-a");
  await seedVenue("venue-b");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 40 });
  await seedStoryPromotionPricing();
  await seedOffer({ offerId: "offer-pin-other-venue", venueId: "venue-b" });
  await seedOffer({ offerId: "offer-pin-inactive", venueId: "venue-a", isActive: false });
  await seedOffer({ offerId: "offer-pin-expired", venueId: "venue-a", endOffsetMs: -10_000 });

  await expectHttpsError(
    () => pinOffer.run(
      { offerId: "offer-pin-other-venue", durationDays: 1, requestId: "pin_offer_other_venue" },
      callableContext({ uid: "merchant-a" }),
    ),
    "permission-denied",
    "another venue",
  );
  await expectHttpsError(
    () => pinOffer.run(
      { offerId: "offer-pin-inactive", durationDays: 1, requestId: "pin_offer_inactive_offer" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "offer_inactive",
  );
  await expectHttpsError(
    () => pinOffer.run(
      { offerId: "offer-pin-expired", durationDays: 1, requestId: "pin_offer_expired_offer" },
      callableContext({ uid: "merchant-a" }),
    ),
    "failed-precondition",
    "offer_expired",
  );
});

test("W20 pinOffer clamps featured_until to offer end_at", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 50 });
  await seedStoryPromotionPricing();
  await seedOffer({ offerId: "offer-pin-clamp", venueId: "venue-a", endOffsetMs: 24 * 60 * 60 * 1000 });

  const result = await pinOffer.run(
    { offerId: "offer-pin-clamp", durationDays: 7, requestId: "pin_offer_clamp" },
    callableContext({ uid: "merchant-a" }),
  );
  assert.equal(result.success, true);
  assert.equal(result.clamped, true);

  const entryDoc = await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_pin_offer_clamp").get();
  assert.equal(entryDoc.data().metadata.duration_days, 7);
  assert.equal(entryDoc.data().metadata.clamped, true);
});

test("W20b renew promoteStory starts from now and debits exactly once per requestId", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 40 });
  await seedStoryPromotionPricing();
  await seedStory({
    storyId: "story-renew-active",
    venueId: "venue-a",
    expiresOffsetMs: 10 * 24 * 60 * 60 * 1000,
  });
  await db.collection("stories").doc("story-renew-active").set({
    is_promoted: true,
    promoted_until: tsFromNow(72 * 60 * 60 * 1000),
  }, { merge: true });

  const beforeCall = Date.now();
  const first = await promoteStory.run(
    {
      storyId: "story-renew-active",
      durationDays: 1,
      requestId: "promo_renew_story_a",
    },
    callableContext({ uid: "merchant-a" }),
  );
  const afterCall = Date.now();
  const second = await promoteStory.run(
    {
      storyId: "story-renew-active",
      durationDays: 1,
      requestId: "promo_renew_story_a",
    },
    callableContext({ uid: "merchant-a" }),
  );

  assert.equal(first.idempotent, false);
  assert.equal(second.idempotent, true);
  const promotedUntilMs = Date.parse(first.promoted_until);
  const expectedUpperBound = afterCall + 26 * 60 * 60 * 1000;
  const expectedLowerBound = beforeCall + 23 * 60 * 60 * 1000;
  assert.ok(promotedUntilMs >= expectedLowerBound);
  assert.ok(promotedUntilMs <= expectedUpperBound);

  const [walletDoc, entriesSnap] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(walletDoc.data().available_balance, 37);
  assert.equal(entriesSnap.size, 1);
});

test("W20c renew pinOffer starts from now and stays idempotent per requestId", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 40 });
  await seedStoryPromotionPricing();
  await seedOffer({
    offerId: "offer-renew-active",
    venueId: "venue-a",
    endOffsetMs: 10 * 24 * 60 * 60 * 1000,
  });
  await db.collection("offers").doc("offer-renew-active").set({
    is_featured: true,
    featured_until: tsFromNow(96 * 60 * 60 * 1000),
  }, { merge: true });

  const beforeCall = Date.now();
  const first = await pinOffer.run(
    {
      offerId: "offer-renew-active",
      durationDays: 1,
      requestId: "renew_offer_active_1d",
    },
    callableContext({ uid: "merchant-a" }),
  );
  const afterCall = Date.now();
  const second = await pinOffer.run(
    {
      offerId: "offer-renew-active",
      durationDays: 1,
      requestId: "renew_offer_active_1d",
    },
    callableContext({ uid: "merchant-a" }),
  );

  assert.equal(first.idempotent, false);
  assert.equal(second.idempotent, true);
  const featuredUntilMs = Date.parse(first.featured_until);
  const expectedUpperBound = afterCall + 26 * 60 * 60 * 1000;
  const expectedLowerBound = beforeCall + 23 * 60 * 60 * 1000;
  assert.ok(featuredUntilMs >= expectedLowerBound);
  assert.ok(featuredUntilMs <= expectedUpperBound);

  const [walletDoc, entriesSnap] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").get(),
  ]);
  assert.equal(walletDoc.data().available_balance, 36);
  assert.equal(entriesSnap.size, 1);
});

test("W21 lifecycle cleanup expires featured offers and promoted stories", async () => {
  await seedOffer({
    offerId: "offer-featured-expired",
    venueId: "venue-a",
    endOffsetMs: 5 * 24 * 60 * 60 * 1000,
  });
  await db.collection("offers").doc("offer-featured-expired").set({
    is_featured: true,
    featured_until: tsFromNow(-1_000),
    updated_at: tsFromNow(-2_000),
  }, { merge: true });

  await seedStory({
    storyId: "story-promoted-expired",
    venueId: "venue-a",
    expiresOffsetMs: 5 * 24 * 60 * 60 * 1000,
  });
  await db.collection("stories").doc("story-promoted-expired").set({
    is_promoted: true,
    promoted_until: tsFromNow(-1_000),
    updated_at: tsFromNow(-2_000),
  }, { merge: true });

  const result = await runWalletLifecycleMaintenance();
  assert.equal(result.offersExpired, 1);
  assert.equal(result.storiesExpired, 1);

  const [offerDoc, storyDoc] = await Promise.all([
    db.collection("offers").doc("offer-featured-expired").get(),
    db.collection("stories").doc("story-promoted-expired").get(),
  ]);
  assert.equal(offerDoc.data().is_featured, false);
  assert.equal(storyDoc.data().is_promoted, false);
  assert.ok(offerDoc.data().featured_until);
  assert.ok(storyDoc.data().promoted_until);
});

test("W22 lifecycle cleanup deletes expired internal proof and updates request", async () => {
  await seedMerchant("merchant-a", "venue-a");
  const proofPath = "venues/venue-a/wallet_topups/proof-cleanup.jpg";
  await seedProofObject(proofPath);

  const requestRef = db.collection("merchant_topup_requests").doc("request-proof-cleanup");
  await requestRef.set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 123,
    currency: "ILS",
    status: "pending",
    proof_image_url: proofPath,
    proof_retention_until: tsFromNow(-60_000),
    created_at: tsFromNow(-120_000),
    updated_at: tsFromNow(-120_000),
  });

  const result = await runWalletLifecycleMaintenance();
  assert.equal(result.proofsDeleted, 1);
  assert.equal(result.proofStorageDeleted, 1);
  assert.equal(result.proofLegacyCleared, 0);

  const [updatedRequest, fileExists] = await Promise.all([
    requestRef.get(),
    admin.storage().bucket(storageBucketName).file(proofPath).exists(),
  ]);
  assert.equal(updatedRequest.data().proof_image_url, null);
  assert.equal(updatedRequest.data().proof_storage_deleted, true);
  assert.ok(updatedRequest.data().proof_deleted_at);
  assert.equal(fileExists[0], false);
});

test("W23 lifecycle cleanup is idempotent on rerun", async () => {
  await seedOffer({ offerId: "offer-idempotent", venueId: "venue-a", endOffsetMs: 3 * 24 * 60 * 60 * 1000 });
  await db.collection("offers").doc("offer-idempotent").set({
    is_featured: true,
    featured_until: tsFromNow(-1_000),
  }, { merge: true });

  await seedStory({ storyId: "story-idempotent", venueId: "venue-a", expiresOffsetMs: 3 * 24 * 60 * 60 * 1000 });
  await db.collection("stories").doc("story-idempotent").set({
    is_promoted: true,
    promoted_until: tsFromNow(-1_000),
  }, { merge: true });

  const proofPath = "venues/venue-a/wallet_topups/proof-idempotent.jpg";
  await seedProofObject(proofPath);
  await db.collection("merchant_topup_requests").doc("request-idempotent").set({
    venue_id: "venue-a",
    amount: 100,
    status: "pending",
    proof_image_url: proofPath,
    proof_retention_until: tsFromNow(-2_000),
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-5_000),
  });

  const first = await runWalletLifecycleMaintenance();
  const second = await runWalletLifecycleMaintenance();
  assert.equal(first.offersExpired, 1);
  assert.equal(first.storiesExpired, 1);
  assert.equal(first.proofsDeleted, 1);
  assert.equal(second.offersExpired, 0);
  assert.equal(second.storiesExpired, 0);
  assert.equal(second.proofsDeleted, 0);
});

test("W24 lifecycle cleanup handles legacy external proof URL safely", async () => {
  await db.collection("merchant_topup_requests").doc("request-legacy-proof").set({
    venue_id: "venue-a",
    amount: 50,
    status: "pending",
    proof_image_url: "https://example.com/legacy-proof.jpg",
    proof_retention_until: tsFromNow(-1_000),
    created_at: tsFromNow(-3_000),
    updated_at: tsFromNow(-3_000),
  });

  const result = await runWalletLifecycleMaintenance();
  assert.equal(result.proofsDeleted, 1);
  assert.equal(result.proofStorageDeleted, 0);
  assert.equal(result.proofLegacyCleared, 1);

  const requestDoc = await db.collection("merchant_topup_requests").doc("request-legacy-proof").get();
  assert.equal(requestDoc.data().proof_image_url, null);
  assert.equal(requestDoc.data().proof_storage_deleted, false);
  assert.ok(requestDoc.data().proof_deleted_at);
});

test("W25 wallet report aggregation updates after topup + debits", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 20 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-report-1", venueId: "venue-a" });
  await seedOffer({
    offerId: "offer-report-1",
    venueId: "venue-a",
    endOffsetMs: 10 * 24 * 60 * 60 * 1000,
  });

  await createMerchantTopUpRequest.run(
    { amount: 100, note: "report topup" },
    callableContext({ uid: "merchant-a" }),
  );
  const topupSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const topupId = topupSnap.docs[0].id;
  await reviewMerchantTopUpRequest.run(
    { requestId: topupId, decision: "credit", adminNote: "ok" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  await promoteStory.run(
    { storyId: "story-report-1", durationDays: 1, requestId: "report_story_1" },
    callableContext({ uid: "merchant-a" }),
  );
  await pinOffer.run(
    { offerId: "offer-report-1", durationDays: 3, requestId: "report_offer_1" },
    callableContext({ uid: "merchant-a" }),
  );

  const report = await rebuildWalletReportForVenue("venue-a");
  assert.equal(report.total_credited, 100);
  assert.equal(report.topup_total_credited, 100);
  assert.equal(report.total_debited, 12);
  assert.equal(report.last_30d_debited, 12);
  assert.equal(report.debit_by_feature.story_promotion, 3);
  assert.equal(report.debit_by_feature.offer_pin, 9);
  assert.equal(report.most_used_debit_feature !== null, true);

  const reportDoc = await db.collection("merchant_wallet_reports").doc("venue-a").get();
  assert.equal(reportDoc.exists, true);
  assert.equal(reportDoc.data().total_credited, 100);
  assert.equal(reportDoc.data().topup_total_credited, 100);
  assert.equal(reportDoc.data().total_debited, 12);
});

test("W26 topup approval writes audit read model with linked entry", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await createMerchantTopUpRequest.run(
    { amount: 90, note: "audit link" },
    callableContext({ uid: "merchant-a" }),
  );

  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const requestId = requestSnap.docs[0].id;
  await reviewMerchantTopUpRequest.run(
    { requestId, decision: "credit", adminNote: "approved for audit" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const auditDoc = await db.collection("wallet_audit_events")
    .doc(`topup_review_${requestId}`)
    .get();
  assert.equal(auditDoc.exists, true);
  assert.equal(auditDoc.data().event_type, "topup_request_approved");
  assert.equal(auditDoc.data().request_id, requestId);
  assert.equal(typeof auditDoc.data().linked_entry_id, "string");
});

test("W26b createMerchantTopUpRequest sends exactly one admin notification", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedAdmin("admin-a");

  await createMerchantTopUpRequest.run(
    { amount: 80, note: "notify admins" },
    callableContext({ uid: "merchant-a" }),
  );

  const adminNotifications = await getUserNotifications(
    "admin-a",
    "wallet_topup_request_created",
  );
  assert.equal(adminNotifications.length, 1);
  assert.equal(adminNotifications[0].data.request_id != null, true);
  assert.equal(adminNotifications[0].data.venue_id, "venue-a");
});

test("W26c topup approval and rejection each notify merchant once", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedAdmin("admin-a");

  await createMerchantTopUpRequest.run(
    { amount: 120, note: "approve me" },
    callableContext({ uid: "merchant-a" }),
  );
  let requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  const approveRequestId = requestSnap.docs[0].id;
  await reviewMerchantTopUpRequest.run(
    { requestId: approveRequestId, decision: "credit", adminNote: "approved" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  await createMerchantTopUpRequest.run(
    { amount: 30, note: "reject me" },
    callableContext({ uid: "merchant-a" }),
  );
  requestSnap = await db.collection("merchant_topup_requests")
    .where("status", "==", "pending")
    .limit(1)
    .get();
  const rejectRequestId = requestSnap.docs[0].id;
  await reviewMerchantTopUpRequest.run(
    { requestId: rejectRequestId, decision: "reject", adminNote: "receipt mismatch" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const approvedNotifications = await getUserNotifications(
    "merchant-a",
    "wallet_topup_request_approved",
  );
  const rejectedNotifications = await getUserNotifications(
    "merchant-a",
    "wallet_topup_request_rejected",
  );
  assert.equal(approvedNotifications.length, 1);
  assert.equal(rejectedNotifications.length, 1);
  assert.equal(approvedNotifications[0].data.request_id, approveRequestId);
  assert.equal(rejectedNotifications[0].data.request_id, rejectRequestId);
});

test("W27 reverseWalletEntry creates compensating credit and links entries", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 50 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-reversal", venueId: "venue-a" });
  await promoteStory.run(
    { storyId: "story-reversal", durationDays: 1, requestId: "reverse_story_1" },
    callableContext({ uid: "merchant-a" }),
  );

  const result = await reverseWalletEntry.run(
    { entryId: "story_promotion_reverse_story_1", venueId: "venue-a", reason: "invalid_charge", adminNote: "manual correction" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );
  assert.equal(result.success, true);
  assert.equal(result.reversalEntryId, "reversal_story_promotion_reverse_story_1");

  const [walletDoc, originalEntryDoc, reversalEntryDoc] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("story_promotion_reverse_story_1").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("reversal_story_promotion_reverse_story_1").get(),
  ]);

  assert.equal(walletDoc.data().available_balance, 50);
  assert.ok(originalEntryDoc.data().reversed_at);
  assert.equal(originalEntryDoc.data().reversed_by_uid, "admin-a");
  assert.equal(originalEntryDoc.data().reversal_entry_id, "reversal_story_promotion_reverse_story_1");
  assert.equal(reversalEntryDoc.data().type, "credit");
  assert.equal(reversalEntryDoc.data().amount, 3);
  assert.equal(reversalEntryDoc.data().feature_key, "story_promotion");
  assert.equal(reversalEntryDoc.data().metadata.reversal_of_entry_id, "story_promotion_reverse_story_1");
  assert.equal(reversalEntryDoc.data().metadata.reversal_reason, "invalid_charge");
  assert.equal(reversalEntryDoc.data().metadata.original_feature_key, "story_promotion");
  assert.equal(reversalEntryDoc.data().metadata.original_amount, 3);

  const storyDoc = await db.collection("stories").doc("story-reversal").get();
  assert.equal(storyDoc.data().is_promoted, false);
});

test("W28 reverseWalletEntry blocks double reversal", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 50 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-reversal-double", venueId: "venue-a" });
  await promoteStory.run(
    { storyId: "story-reversal-double", durationDays: 1, requestId: "reverse_story_2" },
    callableContext({ uid: "merchant-a" }),
  );
  await reverseWalletEntry.run(
    { entryId: "story_promotion_reverse_story_2", venueId: "venue-a", reason: "first" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  await expectHttpsError(
    () => reverseWalletEntry.run(
      { entryId: "story_promotion_reverse_story_2", venueId: "venue-a", reason: "second" },
      callableContext({ uid: "admin-a", token: { admin: true } }),
    ),
    "failed-precondition",
    "entry_already_reversed",
  );
});

test("W29 reverseWalletEntry blocks non-debit entries", async () => {
  await seedWallet("venue-a", { balance: 0 });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("credit-1").set({
    venue_id: "venue-a",
    type: "credit",
    amount: 100,
    currency: "ILS",
    balance_after: 100,
    feature_key: null,
    reference_type: "topup_request",
    reference_id: "request-1",
    created_by_type: "admin",
    created_by_uid: "admin-a",
    metadata: {},
    created_at: tsFromNow(-1_000),
  });

  await expectHttpsError(
    () => reverseWalletEntry.run(
      { entryId: "credit-1", venueId: "venue-a", reason: "not debit" },
      callableContext({ uid: "admin-a", token: { admin: true } }),
    ),
    "failed-precondition",
    "reversal_only_for_debit",
  );
});

test("W30 reverseWalletEntry blocks non-admin", async () => {
  await seedWallet("venue-a", { balance: 10 });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_x").set({
    venue_id: "venue-a",
    type: "debit",
    amount: 4,
    currency: "ILS",
    balance_after: 6,
    feature_key: "offer_pin",
    reference_type: "offer",
    reference_id: "offer-a",
    created_by_type: "merchant",
    created_by_uid: "merchant-a",
    metadata: {},
    created_at: tsFromNow(-1_000),
  });

  await expectHttpsError(
    () => reverseWalletEntry.run(
      { entryId: "offer_pin_x", venueId: "venue-a", reason: "admin only" },
      callableContext({ uid: "merchant-a" }),
    ),
    "permission-denied",
    "admin",
  );
});

test("W31 reverseWalletEntry preserves audit links and exact balance", async () => {
  await seedWallet("venue-a", { balance: 30 });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_test").set({
    venue_id: "venue-a",
    type: "debit",
    amount: 9,
    currency: "ILS",
    balance_after: 21,
    feature_key: "offer_pin",
    reference_type: "offer",
    reference_id: "offer-ref",
    created_by_type: "merchant",
    created_by_uid: "merchant-a",
    metadata: { request_id: "req-offer" },
    created_at: tsFromNow(-1_000),
  });
  await db.collection("merchant_wallets").doc("venue-a").update({
    available_balance: 21,
  });

  await reverseWalletEntry.run(
    { entryId: "offer_pin_test", venueId: "venue-a", reason: "fraud_check" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const [walletDoc, auditDoc, entryAuditDoc] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("wallet_audit_events").doc("wallet_reversal_offer_pin_test").get(),
    db.collection("wallet_audit_events").doc("entry_offer_pin_test").get(),
  ]);
  assert.equal(walletDoc.data().available_balance, 30);
  assert.equal(auditDoc.data().reversal_entry_id, "reversal_offer_pin_test");
  assert.equal(auditDoc.data().entry_id, "offer_pin_test");
  assert.equal(entryAuditDoc.data().reversal_entry_id, "reversal_offer_pin_test");
});

test("W32 reverseWalletEntry reverts featured offer state", async () => {
  await seedOffer({
    offerId: "offer-reversal-flag",
    venueId: "venue-a",
    endOffsetMs: 7 * 24 * 60 * 60 * 1000,
  });
  await seedWallet("venue-a", { balance: 50 });
  await db.collection("offers").doc("offer-reversal-flag").set({
    is_featured: true,
    featured_until: tsFromNow(2 * 24 * 60 * 60 * 1000),
  }, { merge: true });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_flag").set({
    venue_id: "venue-a",
    type: "debit",
    amount: 9,
    currency: "ILS",
    balance_after: 41,
    feature_key: "offer_pin",
    reference_type: "offer",
    reference_id: "offer-reversal-flag",
    created_by_type: "merchant",
    created_by_uid: "merchant-a",
    metadata: {},
    created_at: tsFromNow(-2_000),
  });
  await db.collection("merchant_wallets").doc("venue-a").update({
    available_balance: 41,
  });

  await reverseWalletEntry.run(
    { entryId: "offer_pin_flag", venueId: "venue-a", reason: "feature_revert" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const offerDoc = await db.collection("offers").doc("offer-reversal-flag").get();
  assert.equal(offerDoc.data().is_featured, false);
});

test("W33 reverseWalletEntry sends exactly one merchant notification", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 30 });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_notify").set({
    venue_id: "venue-a",
    type: "debit",
    amount: 9,
    currency: "ILS",
    balance_after: 21,
    feature_key: "offer_pin",
    reference_type: "offer",
    reference_id: "offer-ref",
    created_by_type: "merchant",
    created_by_uid: "merchant-a",
    metadata: { request_id: "req-notify" },
    created_at: tsFromNow(-1_000),
  });
  await db.collection("merchant_wallets").doc("venue-a").update({
    available_balance: 21,
  });

  await reverseWalletEntry.run(
    { entryId: "offer_pin_notify", venueId: "venue-a", reason: "support_fix" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_entry_reversed",
  );
  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].data.entry_id, "offer_pin_notify");
});

test("W34 low-balance notification fires once when threshold is crossed", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 12 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-low-balance", venueId: "venue-a" });

  await promoteStory.run(
    { storyId: "story-low-balance", durationDays: 1, requestId: "low_balance_story_1" },
    callableContext({ uid: "merchant-a" }),
  );
  await promoteStory.run(
    { storyId: "story-low-balance", durationDays: 1, requestId: "low_balance_story_1" },
    callableContext({ uid: "merchant-a" }),
  );

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_low_balance",
  );
  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].data.request_id, "low_balance_story_1");
  assert.equal(notifications[0].data.feature_key, "story_promotion");
});

test("W35 admin wallet notifications respect admin preferences", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedAdmin("admin-a");
  await seedUserNotificationPrefs("admin-a", {
    admin_wallet_notifications_enabled: false,
  });

  await createMerchantTopUpRequest.run(
    { amount: 80, note: "do not notify disabled admin" },
    callableContext({ uid: "merchant-a" }),
  );

  const adminNotifications = await getUserNotifications(
    "admin-a",
    "wallet_topup_request_created",
  );
  assert.equal(adminNotifications.length, 0);
});

test("W36 merchant wallet activity notifications respect wallet preference", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedAdmin("admin-a");
  await seedUserNotificationPrefs("merchant-a", {
    wallet_notifications_enabled: false,
  });

  await createMerchantTopUpRequest.run(
    { amount: 120, note: "approved silently" },
    callableContext({ uid: "merchant-a" }),
  );
  const requestSnap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", "venue-a")
    .limit(1)
    .get();
  await reviewMerchantTopUpRequest.run(
    { requestId: requestSnap.docs[0].id, decision: "credit", adminNote: "approved" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_topup_request_approved",
  );
  assert.equal(notifications.length, 0);
});

test("W37 reversal notifications respect wallet activity preference", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedUserNotificationPrefs("merchant-a", {
    wallet_notifications_enabled: false,
  });
  await seedWallet("venue-a", { balance: 30 });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("offer_pin_notify_disabled").set({
    venue_id: "venue-a",
    type: "debit",
    amount: 9,
    currency: "ILS",
    balance_after: 21,
    feature_key: "offer_pin",
    reference_type: "offer",
    reference_id: "offer-ref",
    created_by_type: "merchant",
    created_by_uid: "merchant-a",
    metadata: { request_id: "req-notify-disabled" },
    created_at: tsFromNow(-1_000),
  });
  await db.collection("merchant_wallets").doc("venue-a").update({
    available_balance: 21,
  });

  await reverseWalletEntry.run(
    { entryId: "offer_pin_notify_disabled", venueId: "venue-a", reason: "support_fix" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_entry_reversed",
  );
  assert.equal(notifications.length, 0);
});

test("W38 low-balance notifications respect wallet activity preference", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedUserNotificationPrefs("merchant-a", {
    wallet_notifications_enabled: false,
  });
  await seedWallet("venue-a", { balance: 12 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-low-balance-disabled", venueId: "venue-a" });

  await promoteStory.run(
    {
      storyId: "story-low-balance-disabled",
      durationDays: 1,
      requestId: "low_balance_story_disabled",
    },
    callableContext({ uid: "merchant-a" }),
  );

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_low_balance",
  );
  assert.equal(notifications.length, 0);
});

test("W39 expiry reminder sends exactly one story reminder", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedStory({
    storyId: "story-expiring-reminder",
    venueId: "venue-a",
    expiresOffsetMs: 3 * 24 * 60 * 60 * 1000,
  });
  await db.collection("stories").doc("story-expiring-reminder").set({
    is_promoted: true,
    promoted_until: tsFromNow(6 * 60 * 60 * 1000),
    updated_at: tsFromNow(-1_000),
  }, { merge: true });

  const result = await runWalletExpiryReminderMaintenance();
  assert.equal(result.storyRemindersSent, 1);

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_story_promotion_expiring",
  );
  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].data.story_id, "story-expiring-reminder");
});

test("W40 expiry reminder sends exactly one offer reminder", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedOffer({
    offerId: "offer-expiring-reminder",
    venueId: "venue-a",
    endOffsetMs: 3 * 24 * 60 * 60 * 1000,
  });
  await db.collection("offers").doc("offer-expiring-reminder").set({
    is_featured: true,
    featured_until: tsFromNow(8 * 60 * 60 * 1000),
    updated_at: tsFromNow(-1_000),
  }, { merge: true });

  const result = await runWalletExpiryReminderMaintenance();
  assert.equal(result.offerRemindersSent, 1);

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_offer_pin_expiring",
  );
  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].data.offer_id, "offer-expiring-reminder");
});

test("W41 expiry reminder maintenance is deduped across reruns", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedStory({
    storyId: "story-expiring-rerun",
    venueId: "venue-a",
    expiresOffsetMs: 3 * 24 * 60 * 60 * 1000,
  });
  await db.collection("stories").doc("story-expiring-rerun").set({
    is_promoted: true,
    promoted_until: tsFromNow(4 * 60 * 60 * 1000),
  }, { merge: true });
  await seedOffer({
    offerId: "offer-expiring-rerun",
    venueId: "venue-a",
    endOffsetMs: 3 * 24 * 60 * 60 * 1000,
  });
  await db.collection("offers").doc("offer-expiring-rerun").set({
    is_featured: true,
    featured_until: tsFromNow(5 * 60 * 60 * 1000),
  }, { merge: true });

  const first = await runWalletExpiryReminderMaintenance();
  const second = await runWalletExpiryReminderMaintenance();
  assert.equal(first.storyRemindersSent, 1);
  assert.equal(first.offerRemindersSent, 1);
  assert.equal(second.storyRemindersSent, 0);
  assert.equal(second.offerRemindersSent, 0);

  const storyNotifications = await getUserNotifications(
    "merchant-a",
    "wallet_story_promotion_expiring",
  );
  const offerNotifications = await getUserNotifications(
    "merchant-a",
    "wallet_offer_pin_expiring",
  );
  assert.equal(storyNotifications.length, 1);
  assert.equal(offerNotifications.length, 1);
});

test("W42 expiry reminders are skipped when merchant disables them", async () => {
  await seedMerchant("merchant-a", "venue-a");
  await seedUserNotificationPrefs("merchant-a", {
    wallet_expiry_reminders_enabled: false,
  });
  await seedStory({
    storyId: "story-expiring-disabled",
    venueId: "venue-a",
    expiresOffsetMs: 3 * 24 * 60 * 60 * 1000,
  });
  await db.collection("stories").doc("story-expiring-disabled").set({
    is_promoted: true,
    promoted_until: tsFromNow(2 * 60 * 60 * 1000),
  }, { merge: true });

  const result = await runWalletExpiryReminderMaintenance();
  assert.equal(result.storyRemindersSent, 0);

  const notifications = await getUserNotifications(
    "merchant-a",
    "wallet_story_promotion_expiring",
  );
  assert.equal(notifications.length, 0);
});

test("W43 verifyWalletOperationalReadiness reports FAIL on missing pricing", async () => {
  await seedAdmin("admin-a");

  const result = await verifyWalletOperationalReadiness.run(
    {},
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(result.overallStatus, "FAIL");
  assert.equal(result.pricing.status, "FAIL");
  assert.equal(result.readModels.status, "WARN");
  assert.equal(result.walletDefaults.status, "WARN");
  assert.equal(result.notifications.status, "WARN");
  assert.equal(result.pricing.exists, false);
  assert.ok(Array.isArray(result.pricing.issues));
  assert.ok(result.pricing.issues.length > 0);
  assert.ok(result.failureChecks.includes("pricing"));
  assert.equal(result.failureChecks.length, 1);
  assert.ok(result.warningChecks.includes("read_models"));
  assert.ok(result.warningChecks.includes("wallet_defaults"));
  assert.ok(result.warningChecks.includes("notifications"));
});

test("W43b verifyWalletOperationalReadiness reports WARN on valid config without live wallet activity", async () => {
  await seedAdmin("admin-a");
  await seedStoryPromotionPricing();

  const result = await verifyWalletOperationalReadiness.run(
    {},
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(result.overallStatus, "WARN");
  assert.equal(result.pricing.status, "PASS");
  assert.equal(result.readModels.status, "WARN");
  assert.equal(result.walletDefaults.status, "WARN");
  assert.equal(result.notifications.status, "WARN");
  assert.deepEqual(result.failureChecks, []);
  assert.ok(result.warningChecks.includes("read_models"));
  assert.ok(result.warningChecks.includes("wallet_defaults"));
  assert.ok(result.warningChecks.includes("notifications"));
});

test("W44 verifyWalletOperationalReadiness reports PASS on valid setup", async () => {
  await seedAdmin("admin-a");
  await seedWallet("venue-a", { balance: 25 });
  await seedStoryPromotionPricing();
  await db.collection("wallet_notification_events").doc("wallet_story_expiring_seed").set({
    type: "wallet_story_promotion_expiring",
    created_at: tsFromNow(0),
    created_by_uid: "system",
  });
  await db.collection("merchant_wallet_reports").doc("venue-a").set({
    venue_id: "venue-a",
    currency: "ILS",
    total_credited: 50,
    topup_total_credited: 50,
    total_debited: 0,
    last_30d_debited: 0,
    debit_by_feature: {},
    debit_count_by_feature: {},
    most_used_debit_feature: "other",
    last_top_up_amount: 50,
    updated_at: tsFromNow(0),
  });

  const result = await verifyWalletOperationalReadiness.run(
    {},
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(result.overallStatus, "PASS");
  assert.equal(result.pricing.status, "PASS");
  assert.equal(result.readModels.status, "PASS");
  assert.equal(result.walletDefaults.status, "PASS");
  assert.equal(result.notifications.status, "PASS");
  assert.equal(result.pricing.exists, true);
  assert.equal(result.readModels.hasAnyWalletReport, true);
  assert.deepEqual(result.failureChecks, []);
  assert.deepEqual(result.warningChecks, []);
});

test("W45 listMerchantTopUpRequestsForAdmin returns server-backed rows for admin", async () => {
  await clearFirestore();
  await seedAdmin("admin-a");
  await seedVenue("venue-a");
  await db.collection("merchant_topup_requests").doc("req-read-1").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 120,
    currency: "ILS",
    transfer_reference: "TRX-READ-1",
    status: "pending",
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-5_000),
  });

  const result = await listMerchantTopUpRequestsForAdmin.run(
    { limit: 10 },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.ok(Array.isArray(result.requests));
  assert.equal(result.requests.length, 1);
  assert.equal(result.requests[0].id, "req-read-1");
  assert.equal(result.requests[0].status, "pending");
  assert.equal(result.requests[0].providerReference, "TRX-READ-1");
  assert.ok(typeof result.checkedAt === "number");
});

test("W45b listMerchantTopUpRequestsForAdmin denies non-admin callers", async () => {
  await clearFirestore();
  await db.collection("merchant_topup_requests").doc("req-x").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 10,
    currency: "ILS",
    status: "pending",
    created_at: tsFromNow(-1_000),
    updated_at: tsFromNow(-1_000),
  });

  await assert.rejects(
    () =>
      listMerchantTopUpRequestsForAdmin.run(
        {},
        callableContext({ uid: "user-plain", token: {} }),
      ),
    (err) => err.code === "permission-denied",
  );
});

test("W46 listMerchantWalletLedgerEntriesForAdmin returns ledger rows for admin", async () => {
  await clearFirestore();
  await seedAdmin("admin-a");
  await seedWallet("venue-a", { balance: 100 });
  await db
    .collection("merchant_wallets")
    .doc("venue-a")
    .collection("entries")
    .doc("entry-read-1")
    .set({
      venue_id: "venue-a",
      type: "debit",
      amount: 15,
      currency: "ILS",
      balance_after: 85,
      feature_key: "story_promotion",
      reference_type: "story",
      reference_id: "s1",
      idempotency_key: "story_promotion_r1",
      created_by_type: "system",
      created_by_uid: "system",
      note: "Promotion debit",
      metadata: {},
      created_at: tsFromNow(-3_000),
    });

  const result = await listMerchantWalletLedgerEntriesForAdmin.run(
    { venueId: "venue-a", limit: 20 },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.ok(Array.isArray(result.entries));
  assert.equal(result.entries.length, 1);
  assert.equal(result.entries[0].id, "entry-read-1");
  assert.equal(result.entries[0].type, "debit");
  assert.ok(typeof result.checkedAt === "number");
});

test("W53 getAdminVenueWorkspaceReadBundle returns read-only workspace data for admin", async () => {
  await clearFirestore();
  await seedAdmin("admin-a");
  await seedVenue("venue-a");
  await seedWallet("venue-a", { balance: 180 });
  await db.collection("merchant_wallet_reports").doc("venue-a").set({
    venue_id: "venue-a",
    available_balance: 180,
    low_balance_threshold: 10,
    currency: "ILS",
    updated_at: tsFromNow(0),
  }, { merge: true });
  await db.collection("merchant_wallets").doc("venue-a").collection("entries").doc("workspace-entry-1").set({
    venue_id: "venue-a",
    type: "credit",
    amount: 50,
    currency: "ILS",
    reference_type: "topup_request",
    reference_id: "req-1",
    idempotency_key: "topup_workspace_1",
    created_by_type: "admin",
    created_by_uid: "admin-a",
    note: "Workspace top-up",
    metadata: {},
    created_at: tsFromNow(-2_000),
  });
  await db.collection("offers").doc("workspace-offer-1").set({
    venue_id: "venue-a",
    title_ar: "Offer workspace 1",
    is_active: true,
    start_at: tsFromNow(-10_000),
    end_at: tsFromNow(86_400_000),
  });
  await db.collection("stories").doc("workspace-story-1").set({
    venue_id: "venue-a",
    caption: "Story workspace 1",
    is_active: true,
    expires_at: tsFromNow(3_600_000),
  });
  await db.collection("venues").doc("venue-a").collection("reviews").doc("workspace-review-1").set({
    author_name: "Guest One",
    rating: 4,
    comment: "Great service",
    status: "published",
    created_at: tsFromNow(-1_000),
  });

  const result = await getAdminVenueWorkspaceReadBundle.run(
    { venueId: "venue-a" },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(result.context.venueId, "venue-a");
  assert.equal(result.context.walletCurrency, "ILS");
  assert.ok(Array.isArray(result.walletEntries));
  assert.ok(Array.isArray(result.offers));
  assert.ok(Array.isArray(result.stories));
  assert.ok(Array.isArray(result.reviews));
  assert.equal(result.walletEntries[0].id, "workspace-entry-1");
  assert.equal(result.offers[0].id, "workspace-offer-1");
  assert.equal(result.stories[0].id, "workspace-story-1");
  assert.equal(result.reviews[0].id, "workspace-review-1");
  assert.ok(typeof result.checkedAt === "number");
});

test("W54 getAdminVenueWorkspaceReadBundle denies non-admin callers", async () => {
  await clearFirestore();
  await seedVenue("venue-a");

  await assert.rejects(
    () =>
      getAdminVenueWorkspaceReadBundle.run(
        { venueId: "venue-a" },
        callableContext({ uid: "user-plain", token: {} }),
      ),
    (err) => err.code === "permission-denied",
  );
});

test("W55 getAdminMediaInventoryReadBundle returns media rows and safety metadata for admin", async () => {
  await clearFirestore();
  await seedAdmin("admin-a");
  await seedVenue("venue-a");
  await seedProofObject("venues/venue-a/wallet_topups/proof-media-1.jpg");

  await db.collection("merchant_topup_requests").doc("media-proof-1").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 70,
    currency: "ILS",
    status: "pending",
    proof_image_url: "venues/venue-a/wallet_topups/proof-media-1.jpg",
    proof_retention_until: tsFromNow(86_400_000),
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });

  await db.collection("venues").doc("venue-a").set({
    photos: [
      "venues/venue-a/photos/photo-local-1.jpg",
      "https://cdn.example.com/venue-photo-2.jpg",
    ],
    updated_at: tsFromNow(-2_000),
  }, { merge: true });

  await db.collection("offers").doc("media-offer-1").set({
    venue_id: "venue-a",
    title_ar: "Offer media 1",
    image_url: "https://cdn.example.com/offer-image-1.jpg",
    is_active: true,
    start_at: tsFromNow(-10_000),
    end_at: tsFromNow(86_400_000),
    created_at: tsFromNow(-10_000),
    updated_at: tsFromNow(-2_000),
  });

  await db.collection("stories").doc("media-story-1").set({
    venue_id: "venue-a",
    caption: "Story media 1",
    image_url: "https://cdn.example.com/story-image-1.jpg",
    expires_at: tsFromNow(86_400_000),
    created_at: tsFromNow(-8_000),
    updated_at: tsFromNow(-2_000),
  });

  await db.collection("media_reference_index").doc("health").set({
    current_health_status: "stale",
    last_successful_build_at: tsFromNow(-600_000),
    updated_at: tsFromNow(-2_000),
  });

  const result = await getAdminMediaInventoryReadBundle.run(
    {
      venueId: "venue-a",
      proofLimit: 10,
      venuePhotoLimit: 10,
      offerImageLimit: 10,
      storyImageLimit: 10,
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(result.referenceIndex.status, "stale");
  assert.ok(Array.isArray(result.topupProofs));
  assert.ok(Array.isArray(result.venuePhotos));
  assert.ok(Array.isArray(result.offerImages));
  assert.ok(Array.isArray(result.storyImages));

  const proofRow = result.topupProofs.find((entry) => entry.id === "media-proof-1");
  assert.ok(proofRow);
  assert.equal(proofRow.sourceLabel, "merchant_topup_requests/media-proof-1");
  assert.equal(proofRow.storagePath, "venues/venue-a/wallet_topups/proof-media-1.jpg");
  assert.equal(proofRow.safety.referenceIndexStatus, "stale");
  assert.equal(proofRow.safety.purgeBlocked, true);

  const venuePhotoRow = result.venuePhotos.find((entry) => entry.sourceLabel === "venues/venue-a");
  assert.ok(venuePhotoRow);
  assert.equal(venuePhotoRow.safety.referenceType, "venue");

  const offerRow = result.offerImages.find((entry) => entry.id === "media-offer-1");
  assert.ok(offerRow);
  assert.equal(offerRow.sourceLabel, "offers/media-offer-1");

  const storyRow = result.storyImages.find((entry) => entry.id === "media-story-1");
  assert.ok(storyRow);
  assert.equal(storyRow.sourceLabel, "stories/media-story-1");
});

test("W56 getAdminMediaInventoryReadBundle denies non-admin callers", async () => {
  await clearFirestore();
  await seedVenue("venue-a");

  await assert.rejects(
    () =>
      getAdminMediaInventoryReadBundle.run(
        { venueId: "venue-a" },
        callableContext({ uid: "user-plain", token: {} }),
      ),
    (err) => err.code === "permission-denied",
  );
});

test("W57 mediaSoftDeleteAsset accepts content admin and writes governed state + audit", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await db.collection("merchant_topup_requests").doc("media-soft-1").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 42,
    currency: "ILS",
    status: "pending",
    proof_image_url: "venues/venue-a/wallet_topups/proof-soft-1.jpg",
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });

  const result = await mediaSoftDeleteAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-soft-1",
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: "media-soft-1",
      mediaUrl: "venues/venue-a/wallet_topups/proof-soft-1.jpg",
      commandId: "media_soft_delete_1",
      correlationId: "media_corr_1",
      reason: "policy_violation",
      expectedState: {
        media_state: "active",
      },
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  assert.equal(result.success, true);
  assert.equal(result.action, "media_soft_delete");
  assert.equal(result.status, "soft_deleted");
  assert.equal(result.idempotent, false);
  assert.ok(typeof result.auditEventId === "string");

  const assetSnap = await db.collection("media_governance_assets")
    .where("asset_key", "==", "venues/venue-a/wallet_topups/proof-soft-1.jpg")
    .limit(1)
    .get();
  assert.equal(assetSnap.size, 1);
  const assetData = assetSnap.docs[0].data();
  assert.equal(assetData.current_state, "soft_deleted");
  assert.equal(assetData.last_action, "media_soft_delete");

  const auditDoc = await db.collection("media_audit_events").doc(result.auditEventId).get();
  assert.equal(auditDoc.exists, true);
  assert.equal(auditDoc.data().event_type, "media_soft_deleted");
});

test("W58 mediaSoftDeleteAsset denies non-admin callers", async () => {
  await clearFirestore();

  await expectHttpsError(
    () => mediaSoftDeleteAsset.run(
      {
        targetType: "topup_proof",
        targetId: "media-soft-deny-1",
        sourceCollection: "merchant_topup_requests",
        sourceDocumentId: "media-soft-deny-1",
        mediaUrl: "venues/venue-a/wallet_topups/proof-soft-deny-1.jpg",
        commandId: "media_soft_delete_deny_1",
        reason: "admin_only",
      },
      callableContext({ uid: "merchant-a", token: {} }),
    ),
    "permission-denied",
    "admin",
  );
});

test("W59 mediaPurgeAsset blocks when media reference index is unhealthy", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await db.collection("merchant_topup_requests").doc("media-purge-1").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 88,
    currency: "ILS",
    status: "pending",
    proof_image_url: "venues/venue-a/wallet_topups/proof-purge-1.jpg",
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });

  await mediaQuarantineAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-purge-1",
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: "media-purge-1",
      mediaUrl: "venues/venue-a/wallet_topups/proof-purge-1.jpg",
      commandId: "media_quarantine_1",
      reason: "awaiting_reference_check",
      expectedState: {
        media_state: "active",
      },
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  await db.collection("media_reference_index").doc("health").set({
    current_health_status: "stale",
    last_successful_build_at: tsFromNow(-900_000),
    updated_at: tsFromNow(-1_000),
  });

  await expectHttpsError(
    () => mediaPurgeAsset.run(
      {
        targetType: "topup_proof",
        targetId: "media-purge-1",
        sourceCollection: "merchant_topup_requests",
        sourceDocumentId: "media-purge-1",
        mediaUrl: "venues/venue-a/wallet_topups/proof-purge-1.jpg",
        commandId: "media_purge_1",
        reason: "hard_delete_after_quarantine",
        expectedState: {
          media_state: "quarantined",
          reference_count: 0,
          reference_index_health: "healthy",
        },
      },
      callableContext({
        uid: "admin-media",
        token: { admin: true, role: "content_admin" },
      }),
    ),
    "failed-precondition",
    "media_purge_reference_index_unhealthy",
  );
});

test("W60 mediaReferenceCheckAsset returns explicit reference-check contract", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await db.collection("merchant_topup_requests").doc("media-ref-1").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 88,
    currency: "ILS",
    status: "pending",
    proof_image_url: "venues/venue-a/wallet_topups/proof-ref-1.jpg",
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });
  await db.collection("media_reference_index").doc("health").set({
    current_health_status: "healthy",
    last_successful_build_at: tsFromNow(-2_000),
    updated_at: tsFromNow(-2_000),
  });

  const result = await mediaReferenceCheckAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-ref-1",
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: "media-ref-1",
      mediaUrl: "venues/venue-a/wallet_topups/proof-ref-1.jpg",
      commandId: "media_reference_check_1",
      reason: "pre_purge_validation",
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  assert.equal(result.success, true);
  assert.equal(result.action, "media_reference_check");
  assert.equal(result.status, "checked");
  assert.ok(result.referenceCheck);
  assert.equal(result.referenceCheck.indexStatus, "healthy");
  assert.equal(result.referenceCheck.referenceCount, 1);
  assert.equal(result.referenceCheck.purgeEligible, false);
  assert.equal(result.referenceCheck.blockedReason, "references_present");
});

test("M03-01 mediaQuarantineAsset allows a trusted mediaAssetKey inventory target", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");
  const storagePath = "venues/venue-a/wallet_topups/proof-key-indexed.jpg";
  await seedTrustedGovernanceAsset({
    storagePath,
    sourceDocumentId: "media-key-indexed",
    currentState: "active",
  });

  const result = await mediaQuarantineAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-key-indexed",
      mediaAssetKey: storagePath,
      commandId: "media_quarantine_key_indexed",
      reason: "trusted_key_quarantine",
      expectedState: {
        media_state: "active",
      },
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  assert.equal(result.success, true);
  assert.equal(result.status, "quarantined");
  const assetDoc = await db.collection("media_governance_assets")
    .doc(mediaAssetDocIdFromKey(storagePath))
    .get();
  assert.equal(assetDoc.data().storage_path, storagePath);
  assert.equal(assetDoc.data().trusted_source_bound, true);
});

test("M03-02 mediaQuarantineAsset derives storagePath from the source document", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");
  const storagePath = "venues/venue-a/wallet_topups/proof-source-bound.jpg";
  await db.collection("merchant_topup_requests").doc("media-source-bound").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 90,
    currency: "ILS",
    status: "pending",
    proof_image_url: storagePath,
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });

  const result = await mediaQuarantineAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-source-bound",
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: "media-source-bound",
      commandId: "media_quarantine_source_bound",
      reason: "trusted_source_quarantine",
      expectedState: {
        media_state: "active",
      },
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  assert.equal(result.success, true);
  const assetDoc = await db.collection("media_governance_assets")
    .doc(mediaAssetDocIdFromKey(storagePath))
    .get();
  assert.equal(assetDoc.exists, true);
  assert.equal(assetDoc.data().asset_key, storagePath);
  assert.equal(assetDoc.data().storage_path, storagePath);
});

test("M03-03 mediaQuarantineAsset rejects caller storagePath without source binding", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await expectHttpsError(
    () => mediaQuarantineAsset.run(
      {
        targetType: "topup_proof",
        targetId: "media-unbound-storage",
        storagePath: "venues/venue-a/wallet_topups/unbound.jpg",
        commandId: "media_quarantine_unbound_storage",
        reason: "deny_untrusted_storage_path",
        expectedState: {
          media_state: "active",
        },
      },
      callableContext({
        uid: "admin-media",
        token: { admin: true, role: "content_admin" },
      }),
    ),
    "invalid-argument",
    "media_trusted_source_required",
  );
});

test("M03-04 mediaQuarantineAsset rejects mediaAssetKey missing from inventory", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await expectHttpsError(
    () => mediaQuarantineAsset.run(
      {
        targetType: "topup_proof",
        targetId: "media-missing-key",
        mediaAssetKey: "venues/venue-a/wallet_topups/missing-key.jpg",
        commandId: "media_quarantine_missing_key",
        reason: "deny_missing_key",
        expectedState: {
          media_state: "active",
        },
      },
      callableContext({
        uid: "admin-media",
        token: { admin: true, role: "content_admin" },
      }),
    ),
    "not-found",
    "media_asset_not_found_in_inventory",
  );
});

test("M03-05 mediaQuarantineAsset rejects missing source document", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await expectHttpsError(
    () => mediaQuarantineAsset.run(
      {
        targetType: "topup_proof",
        targetId: "media-missing-source",
        sourceCollection: "merchant_topup_requests",
        sourceDocumentId: "media-missing-source",
        commandId: "media_quarantine_missing_source",
        reason: "deny_missing_source",
        expectedState: {
          media_state: "active",
        },
      },
      callableContext({
        uid: "admin-media",
        token: { admin: true, role: "content_admin" },
      }),
    ),
    "not-found",
    "media_source_document_not_found",
  );
});

test("M03-06 mediaPurgeAsset deletes a trusted indexed storagePath", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");
  await seedHealthyMediaReferenceIndex();
  const storagePath = "venues/venue-a/wallet_topups/proof-trusted-purge.jpg";
  await seedProofObject(storagePath);
  await db.collection("merchant_topup_requests").doc("media-trusted-purge").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 95,
    currency: "ILS",
    status: "approved",
    proof_storage_deleted: true,
    proof_deleted_at: tsFromNow(-1_000),
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });
  await seedTrustedGovernanceAsset({
    storagePath,
    sourceDocumentId: "media-trusted-purge",
  });

  const result = await mediaPurgeAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-trusted-purge",
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: "media-trusted-purge",
      commandId: "media_purge_trusted_path",
      reason: "hard_delete_after_reference_removed",
      expectedState: {
        media_state: "quarantined",
        reference_count: 0,
        reference_index_health: "healthy",
      },
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  assert.equal(result.success, true);
  assert.equal(result.storageDeleteStatus, "deleted");
  assert.equal(await storageObjectExists(storagePath), false);
});

test("M03-07 mediaPurgeAsset ignores spoofed payload storagePath", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");
  await seedHealthyMediaReferenceIndex();
  const indexedPath = "venues/venue-a/wallet_topups/proof-indexed-delete.jpg";
  const spoofedPath = "venues/venue-b/wallet_topups/proof-spoofed-keep.jpg";
  await seedProofObject(indexedPath);
  await seedProofObject(spoofedPath);
  await db.collection("merchant_topup_requests").doc("media-spoofed-purge").set({
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 95,
    currency: "ILS",
    status: "approved",
    proof_storage_deleted: true,
    proof_deleted_at: tsFromNow(-1_000),
    created_at: tsFromNow(-5_000),
    updated_at: tsFromNow(-2_000),
  });
  await seedTrustedGovernanceAsset({
    storagePath: indexedPath,
    sourceDocumentId: "media-spoofed-purge",
  });

  const result = await mediaPurgeAsset.run(
    {
      targetType: "topup_proof",
      targetId: "media-spoofed-purge",
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: "media-spoofed-purge",
      storagePath: spoofedPath,
      commandId: "media_purge_spoofed_path",
      reason: "ignore_spoofed_storage_path",
      expectedState: {
        media_state: "quarantined",
        reference_count: 0,
        reference_index_health: "healthy",
      },
    },
    callableContext({
      uid: "admin-media",
      token: { admin: true, role: "content_admin" },
    }),
  );

  assert.equal(result.success, true);
  assert.equal(result.storageDeleteStatus, "deleted");
  assert.equal(await storageObjectExists(indexedPath), false);
  assert.equal(await storageObjectExists(spoofedPath), true);
});

test("M03-08 mediaPurgeAsset rejects unbound payload storagePath", async () => {
  await clearFirestore();
  await seedAdmin("admin-media");

  await expectHttpsError(
    () => mediaPurgeAsset.run(
      {
        targetType: "topup_proof",
        targetId: "media-purge-unbound",
        storagePath: "venues/venue-a/wallet_topups/unbound-purge.jpg",
        commandId: "media_purge_unbound_storage",
        reason: "deny_untrusted_purge",
        expectedState: {
          media_state: "quarantined",
          reference_count: 0,
          reference_index_health: "healthy",
        },
      },
      callableContext({
        uid: "admin-media",
        token: { admin: true, role: "content_admin" },
      }),
    ),
    "invalid-argument",
    "media_trusted_source_required",
  );
});

test("W47 reversal over threshold enters pending state then executes on second approval", async () => {
  await seedAdmin("admin-a", { role: "finance_admin" });
  await seedAdmin("admin-b", { role: "finance_admin" });
  const entryId = "dual_reversal_entry_1";
  const { balanceBefore } = await seedReversibleDebitEntry({
    entryId,
    amount: 140,
    balanceBefore: 500,
  });

  const pendingResult = await reverseWalletEntry.run(
    {
      entryId,
      venueId: "venue-a",
      reason: "manual_review",
      commandId: "reverse_dual_1",
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(pendingResult.success, true);
  assert.equal(pendingResult.status, "pending_second_approval");
  assert.equal(pendingResult.requiredSecondApproverRole, "finance_admin");
  assert.ok(typeof pendingResult.reversalRequestId === "string");

  const approvedResult = await approveWalletReversalRequest.run(
    {
      reversalRequestId: pendingResult.reversalRequestId,
      commandId: "approve_dual_1",
      reason: "validated",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    },
    callableContext({ uid: "admin-b", token: { admin: true } }),
  );

  assert.equal(approvedResult.success, true);
  assert.equal(approvedResult.status, "approved_and_executed");
  assert.equal(approvedResult.executedReversalEntryId, `reversal_${entryId}`);

  const [walletDoc, originalEntryDoc, reversalEntryDoc, requestDoc] = await Promise.all([
    db.collection("merchant_wallets").doc("venue-a").get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").doc(entryId).get(),
    db.collection("merchant_wallets").doc("venue-a").collection("entries").doc(`reversal_${entryId}`).get(),
    db.collection("wallet_reversal_requests").doc(pendingResult.reversalRequestId).get(),
  ]);

  assert.equal(walletDoc.data().available_balance, balanceBefore);
  assert.equal(originalEntryDoc.data().reversal_entry_id, `reversal_${entryId}`);
  assert.equal(reversalEntryDoc.exists, true);
  assert.equal(requestDoc.data().status, "approved_and_executed");
});

test("W48 approveWalletReversalRequest blocks non-admin and same-actor approvals", async () => {
  await seedAdmin("admin-a", { role: "finance_admin" });
  const entryId = "dual_reversal_entry_2";
  await seedReversibleDebitEntry({
    entryId,
    amount: 140,
    balanceBefore: 500,
  });

  const pendingResult = await reverseWalletEntry.run(
    {
      entryId,
      venueId: "venue-a",
      reason: "manual_review",
      commandId: "reverse_dual_2",
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  await expectHttpsError(
    () =>
      approveWalletReversalRequest.run(
        {
          reversalRequestId: pendingResult.reversalRequestId,
          commandId: "approve_dual_2_non_admin",
          expectedState: {
            approval_state: "pending_second_approval",
            request_not_expired: true,
          },
        },
        callableContext({ uid: "merchant-a", token: {} }),
      ),
    "permission-denied",
    "admin",
  );

  await expectHttpsError(
    () =>
      approveWalletReversalRequest.run(
        {
          reversalRequestId: pendingResult.reversalRequestId,
          commandId: "approve_dual_2_same_admin",
          expectedState: {
            approval_state: "pending_second_approval",
            request_not_expired: true,
          },
        },
        callableContext({ uid: "admin-a", token: { admin: true } }),
      ),
    "failed-precondition",
    "second_approver_must_differ",
  );
});

test("W49 reversal above super-admin threshold enforces super-admin second approver", async () => {
  await seedAdmin("admin-a", { role: "finance_admin" });
  await seedAdmin("admin-b", { role: "finance_admin" });
  await seedAdmin("admin-super", { role: "super_admin" });
  const entryId = "dual_reversal_entry_3";
  await seedReversibleDebitEntry({
    entryId,
    amount: 600,
    balanceBefore: 1000,
  });

  const pendingResult = await reverseWalletEntry.run(
    {
      entryId,
      venueId: "venue-a",
      reason: "high_value_review",
      commandId: "reverse_dual_3",
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  assert.equal(pendingResult.requiredSecondApproverRole, "super_admin");

  await expectHttpsError(
    () =>
      approveWalletReversalRequest.run(
        {
          reversalRequestId: pendingResult.reversalRequestId,
          commandId: "approve_dual_3_finance_only",
          expectedState: {
            approval_state: "pending_second_approval",
            request_not_expired: true,
          },
        },
        callableContext({ uid: "admin-b", token: { admin: true } }),
      ),
    "permission-denied",
    "super_admin_approval_required",
  );

  const approvedResult = await approveWalletReversalRequest.run(
    {
      reversalRequestId: pendingResult.reversalRequestId,
      commandId: "approve_dual_3_super",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    },
    callableContext({
      uid: "admin-super",
      token: { admin: true, role: "super_admin", super_admin: true },
    }),
  );

  assert.equal(approvedResult.success, true);
  assert.equal(approvedResult.status, "approved_and_executed");
  assert.equal(approvedResult.executedReversalEntryId, `reversal_${entryId}`);
});

test("W50 approveWalletReversalRequest enforces expected_state precondition", async () => {
  await seedAdmin("admin-a", { role: "finance_admin" });
  await seedAdmin("admin-b", { role: "finance_admin" });
  const entryId = "dual_reversal_entry_4";
  await seedReversibleDebitEntry({
    entryId,
    amount: 140,
    balanceBefore: 500,
  });

  const pendingResult = await reverseWalletEntry.run(
    {
      entryId,
      venueId: "venue-a",
      reason: "manual_review",
      commandId: "reverse_dual_4",
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  await expectHttpsError(
    () =>
      approveWalletReversalRequest.run(
        {
          reversalRequestId: pendingResult.reversalRequestId,
          commandId: "approve_dual_4_bad_expected_state",
          expectedState: {
            approval_state: "approved_and_executed",
            request_not_expired: true,
          },
        },
        callableContext({ uid: "admin-b", token: { admin: true } }),
      ),
    "failed-precondition",
    "reversal_approval_expected_state_conflict",
  );
});

test("W51 approveWalletReversalRequest rejects expired pending approvals", async () => {
  await seedAdmin("admin-a", { role: "finance_admin" });
  await seedAdmin("admin-b", { role: "finance_admin" });
  const entryId = "dual_reversal_entry_5";
  await seedReversibleDebitEntry({
    entryId,
    amount: 140,
    balanceBefore: 500,
  });

  const pendingResult = await reverseWalletEntry.run(
    {
      entryId,
      venueId: "venue-a",
      reason: "manual_review",
      commandId: "reverse_dual_5",
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  await db.collection("wallet_reversal_requests").doc(pendingResult.reversalRequestId).set({
    status: "pending_second_approval",
    expires_at: tsFromNow(-10_000),
    updated_at: tsFromNow(-10_000),
  }, { merge: true });

  await expectHttpsError(
    () =>
      approveWalletReversalRequest.run(
        {
          reversalRequestId: pendingResult.reversalRequestId,
          commandId: "approve_dual_5_expired",
          expectedState: {
            approval_state: "pending_second_approval",
            request_not_expired: true,
          },
        },
        callableContext({ uid: "admin-b", token: { admin: true } }),
      ),
    "failed-precondition",
    "reversal_request_expired",
  );

  const requestDoc = await db.collection("wallet_reversal_requests").doc(pendingResult.reversalRequestId).get();
  assert.equal(requestDoc.data().status, "expired");
});

test("W52 approveWalletReversalRequest is idempotent on duplicate approval command", async () => {
  await seedAdmin("admin-a", { role: "finance_admin" });
  await seedAdmin("admin-b", { role: "finance_admin" });
  const entryId = "dual_reversal_entry_6";
  await seedReversibleDebitEntry({
    entryId,
    amount: 140,
    balanceBefore: 500,
  });

  const pendingResult = await reverseWalletEntry.run(
    {
      entryId,
      venueId: "venue-a",
      reason: "manual_review",
      commandId: "reverse_dual_6",
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    },
    callableContext({ uid: "admin-a", token: { admin: true } }),
  );

  const firstApproval = await approveWalletReversalRequest.run(
    {
      reversalRequestId: pendingResult.reversalRequestId,
      commandId: "approve_dual_6_retry",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    },
    callableContext({ uid: "admin-b", token: { admin: true } }),
  );
  const secondApproval = await approveWalletReversalRequest.run(
    {
      reversalRequestId: pendingResult.reversalRequestId,
      commandId: "approve_dual_6_retry",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    },
    callableContext({ uid: "admin-b", token: { admin: true } }),
  );

  assert.equal(firstApproval.success, true);
  assert.equal(secondApproval.success, true);
  assert.equal(firstApproval.status, "approved_and_executed");
  assert.equal(secondApproval.status, "approved_and_executed");
  assert.equal(secondApproval.executedReversalEntryId, firstApproval.executedReversalEntryId);
});

test("W61 listVenueReviewsForAdmin returns normalized review rows for content admin", async () => {
  await seedAdmin("content-admin");
  await seedVenueReview({
    venueId: "venue-a",
    reviewId: "review_admin_1",
    rating: 4,
    status: "published",
    comment: "Helpful staff and clean place",
    userName: "Nour",
  });
  await seedVenueReview({
    venueId: "venue-a",
    reviewId: "review_admin_2",
    rating: 2,
    status: "flagged",
    comment: "Potential abuse to review",
    userName: "Rami",
  });

  const result = await listVenueReviewsForAdmin.run(
    {
      venueId: "venue-a",
      statuses: ["published", "flagged"],
      limit: 20,
      correlationId: "reviews_admin_list_1",
    },
    callableContext({
      uid: "content-admin",
      token: { admin: true, role: "content_admin", content_admin: true },
    }),
  );

  assert.equal(result.correlationId, "reviews_admin_list_1");
  assert.equal(result.filtersApplied.venueId, "venue-a");
  assert.equal(result.items.length, 2);
  assert.equal(result.items[0].venueId, "venue-a");
  assert.ok(["published", "flagged"].includes(result.items[0].status));
});

test("W62 listVenueReviewsForAdmin denies non-content admin callers", async () => {
  await seedAdmin("support-admin");
  await expectHttpsError(
    () =>
      listVenueReviewsForAdmin.run(
        {
          venueId: "venue-a",
        },
        callableContext({
          uid: "support-admin",
          token: { admin: true, role: "support_admin" },
        }),
      ),
    "permission-denied",
    "review_moderation_role_not_authorized",
  );
});

test("W63 moderateVenueReviewForAdmin hides a review and writes audit + command docs", async () => {
  await seedAdmin("content-admin");
  await seedVenueReview({
    venueId: "venue-a",
    reviewId: "review_admin_hide_1",
    status: "published",
  });

  const result = await moderateVenueReviewForAdmin.run(
    {
      action: "review_hide",
      venueId: "venue-a",
      reviewId: "review_admin_hide_1",
      reason: "abusive_language",
      note: "Contains abusive phrasing",
      commandId: "review_hide_cmd_1",
      correlationId: "review_hide_corr_1",
      expectedState: {
        moderation_state: "published",
      },
    },
    callableContext({
      uid: "content-admin",
      token: { admin: true, role: "content_admin", content_admin: true },
    }),
  );

  assert.equal(result.status, "hidden");
  assert.equal(result.reviewId, "review_admin_hide_1");

  const reviewDoc = await db.collection("venues").doc("venue-a").collection("reviews").doc("review_admin_hide_1").get();
  assert.equal(reviewDoc.data().status, "hidden");
  assert.equal(reviewDoc.data().moderation_reason, "abusive_language");

  const auditDoc = await db.collection("review_moderation_events").doc(result.auditEventId).get();
  assert.equal(auditDoc.exists, true);
  assert.equal(auditDoc.data().target_status, "hidden");
});

test("W64 moderateVenueReviewForAdmin enforces expected_state conflict", async () => {
  await seedAdmin("content-admin");
  await seedVenueReview({
    venueId: "venue-a",
    reviewId: "review_admin_conflict_1",
    status: "flagged",
  });

  await expectHttpsError(
    () =>
      moderateVenueReviewForAdmin.run(
        {
          action: "review_publish",
          venueId: "venue-a",
          reviewId: "review_admin_conflict_1",
          reason: "appeal_approved",
          commandId: "review_publish_conflict_1",
          expectedState: {
            moderation_state: "published",
          },
        },
        callableContext({
          uid: "content-admin",
          token: { admin: true, role: "content_admin", content_admin: true },
        }),
      ),
    "failed-precondition",
    "review_moderation_expected_state_conflict",
  );
});

test("W65 moderateVenueReviewForAdmin replays identical command idempotently", async () => {
  await seedAdmin("super-admin");
  await seedVenueReview({
    venueId: "venue-a",
    reviewId: "review_admin_escalate_1",
    status: "published",
  });

  const firstResult = await moderateVenueReviewForAdmin.run(
    {
      action: "review_escalate",
      venueId: "venue-a",
      reviewId: "review_admin_escalate_1",
      reason: "manual_review",
      commandId: "review_escalate_cmd_1",
      expectedState: {
        moderation_state: "published",
      },
    },
    callableContext({
      uid: "super-admin",
      token: { admin: true, role: "super_admin", super_admin: true },
    }),
  );

  const replayResult = await moderateVenueReviewForAdmin.run(
    {
      action: "review_escalate",
      venueId: "venue-a",
      reviewId: "review_admin_escalate_1",
      reason: "manual_review",
      commandId: "review_escalate_cmd_1",
      expectedState: {
        moderation_state: "published",
      },
    },
    callableContext({
      uid: "super-admin",
      token: { admin: true, role: "super_admin", super_admin: true },
    }),
  );

  assert.equal(firstResult.status, "flagged");
  assert.equal(replayResult.status, "flagged");
  assert.equal(replayResult.auditEventId, firstResult.auditEventId);
});

test("W66 config governance lifecycle enforces review and audited publish", async () => {
  await seedAdmin("super-admin-a");
  await seedAdmin("super-admin-b");
  await seedStoryPromotionPricing({
    oneDay: 3,
    threeDays: 7,
    sevenDays: 14,
    offerOneDay: 4,
    offerThreeDays: 9,
    offerSevenDays: 16,
  });

  const reviewerCtx = callableContext({
    uid: "super-admin-a",
    token: { admin: true, role: "super_admin", super_admin: true },
  });
  const publisherCtx = callableContext({
    uid: "super-admin-b",
    token: { admin: true, role: "super_admin", super_admin: true },
  });

  const pricingDraft = {
    story_promote_1d: 5,
    story_promote_3d: 10,
    story_promote_7d: 18,
    offer_pin_1d: 6,
    offer_pin_3d: 11,
    offer_pin_7d: 20,
    currency: "ILS",
  };

  const draftResult = await configUpsertDraft.run(
    {
      commandId: "config_draft_cmd_1",
      correlationId: "config_draft_corr_1",
      reason: "phase6_draft_prepare",
      pricing: pricingDraft,
      expectedState: {
        draft_status: "none",
      },
    },
    reviewerCtx,
  );
  assert.equal(draftResult.status, "drafted");
  assert.equal(draftResult.draftVersion, 1);

  const reviewResult = await configReviewDraft.run(
    {
      commandId: "config_review_cmd_1",
      correlationId: "config_review_corr_1",
      reason: "phase6_review_gate",
      note: "Draft reviewed for publish",
      expectedState: {
        draft_status: "drafted",
        draft_version: 1,
      },
    },
    reviewerCtx,
  );
  assert.equal(reviewResult.status, "reviewed");
  assert.equal(reviewResult.draftVersion, 1);

  await expectHttpsError(
    () =>
      configPublishDraft.run(
        {
          commandId: "config_publish_same_actor_1",
          correlationId: "config_publish_same_actor_corr_1",
          reason: "phase6_publish_attempt_same_actor",
          expectedState: {
            draft_status: "reviewed",
            draft_version: 1,
            target_live_version: 0,
          },
        },
        reviewerCtx,
      ),
    "permission-denied",
    "distinct_reviewer",
  );

  const publishResult = await configPublishDraft.run(
    {
      commandId: "config_publish_cmd_1",
      correlationId: "config_publish_corr_1",
      reason: "phase6_publish_ready",
      note: "Promote reviewed draft to live",
      expectedState: {
        draft_status: "reviewed",
        draft_version: 1,
        target_live_version: 0,
      },
    },
    publisherCtx,
  );
  assert.equal(publishResult.status, "published");
  assert.equal(publishResult.liveVersion, 1);

  const [liveDoc, historyDoc, auditDoc] = await Promise.all([
    db.collection("wallet_feature_pricing").doc("default").get(),
    db.collection("config_publish_history").doc(publishResult.historyId).get(),
    db.collection("config_audit_events").doc(publishResult.auditEventId).get(),
  ]);

  assert.equal(liveDoc.exists, true);
  assert.equal(liveDoc.data().live_version, 1);
  assert.equal(liveDoc.data().story_promote_1d, 5);
  assert.equal(historyDoc.exists, true);
  assert.equal(historyDoc.data().event_type, "config_published");
  assert.equal(historyDoc.data().live_version, 1);
  assert.equal(auditDoc.exists, true);

  const bundle = await getAdminConfigGovernanceBundle.run(
    { historyLimit: 5 },
    publisherCtx,
  );
  assert.equal(bundle.live.version, 1);
  assert.equal(bundle.draft.status, "published");
  assert.ok(Array.isArray(bundle.history));
  assert.ok(bundle.history.length >= 1);
});

test("W67 configPublishDraft denies finance_admin roles", async () => {
  await seedStoryPromotionPricing();

  await db
    .collection("config_governance_drafts")
    .doc("wallet_feature_pricing_default")
    .set(
      {
        config_scope: "wallet_feature_pricing/default",
        draft_status: "reviewed",
        draft_version: 1,
        pricing: {
          story_promote_1d: 3,
          story_promote_3d: 7,
          story_promote_7d: 14,
          offer_pin_1d: 4,
          offer_pin_3d: 9,
          offer_pin_7d: 16,
          currency: "ILS",
        },
        reviewed_by_uid: "super-admin-a",
        reviewed_by_role: "super_admin",
        reviewed_at: tsFromNow(-2_000),
        updated_at: tsFromNow(-2_000),
      },
      { merge: true },
    );

  await expectHttpsError(
    () =>
      configPublishDraft.run(
        {
          commandId: "config_publish_forbidden_role_1",
          reason: "forbidden_role_check",
          expectedState: {
            draft_status: "reviewed",
            draft_version: 1,
            target_live_version: 0,
          },
        },
        callableContext({
          uid: "finance-admin-a",
          token: { admin: true, role: "finance_admin", finance_admin: true },
        }),
      ),
    "permission-denied",
    "config governance restricted to super_admin",
  );
});

test("W68 configPublishDraft enforces expected live-version conflict checks", async () => {
  await seedAdmin("super-admin-b");
  await seedStoryPromotionPricing();
  await db.collection("wallet_feature_pricing").doc("default").set(
    {
      live_version: 2,
      updated_at: tsFromNow(-5_000),
    },
    { merge: true },
  );

  await db
    .collection("config_governance_drafts")
    .doc("wallet_feature_pricing_default")
    .set(
      {
        config_scope: "wallet_feature_pricing/default",
        draft_status: "reviewed",
        draft_version: 2,
        pricing: {
          story_promote_1d: 8,
          story_promote_3d: 11,
          story_promote_7d: 19,
          offer_pin_1d: 7,
          offer_pin_3d: 12,
          offer_pin_7d: 21,
          currency: "ILS",
        },
        reviewed_by_uid: "super-admin-a",
        reviewed_by_role: "super_admin",
        reviewed_at: tsFromNow(-2_000),
        updated_at: tsFromNow(-2_000),
      },
      { merge: true },
    );

  await expectHttpsError(
    () =>
      configPublishDraft.run(
        {
          commandId: "config_publish_conflict_1",
          reason: "live_version_mismatch",
          expectedState: {
            draft_status: "reviewed",
            draft_version: 2,
            target_live_version: 1,
          },
        },
        callableContext({
          uid: "super-admin-b",
          token: { admin: true, role: "super_admin", super_admin: true },
        }),
      ),
    "failed-precondition",
    "config_live_version_conflict",
  );
});

test("W69 configRollbackVersion restores historical pricing and writes rollback history", async () => {
  await seedAdmin("super-admin-c");
  const historicalPricing = {
    story_promote_1d: 4,
    story_promote_3d: 8,
    story_promote_7d: 15,
    offer_pin_1d: 5,
    offer_pin_3d: 10,
    offer_pin_7d: 17,
    currency: "ILS",
  };

  await db.collection("wallet_feature_pricing").doc("default").set({
    story_promote_1d: 10,
    story_promote_3d: 13,
    story_promote_7d: 21,
    offer_pin_1d: 11,
    offer_pin_3d: 15,
    offer_pin_7d: 25,
    currency: "ILS",
    live_version: 3,
    updated_at: tsFromNow(-4_000),
  });

  await db.collection("config_publish_history").doc("history_live_v1").set({
    config_scope: "wallet_feature_pricing/default",
    event_type: "config_published",
    live_version: 1,
    previous_live_version: 0,
    new_pricing: historicalPricing,
    old_pricing: null,
    published_at: tsFromNow(-30_000),
    created_at: tsFromNow(-30_000),
    updated_at: tsFromNow(-30_000),
  });

  const rollbackResult = await configRollbackVersion.run(
    {
      commandId: "config_rollback_cmd_1",
      correlationId: "config_rollback_corr_1",
      reason: "rollback_post_publish_issue",
      rollbackToVersion: 1,
      expectedState: {
        current_live_version: 3,
      },
    },
    callableContext({
      uid: "super-admin-c",
      token: { admin: true, role: "super_admin", super_admin: true },
    }),
  );

  assert.equal(rollbackResult.status, "rolled_back");
  assert.equal(rollbackResult.liveVersion, 4);
  assert.equal(rollbackResult.rollbackToVersion, 1);

  const [liveDoc, historyDoc, auditDoc] = await Promise.all([
    db.collection("wallet_feature_pricing").doc("default").get(),
    db.collection("config_publish_history").doc(rollbackResult.historyId).get(),
    db.collection("config_audit_events").doc(rollbackResult.auditEventId).get(),
  ]);

  assert.equal(liveDoc.data().live_version, 4);
  assert.equal(liveDoc.data().story_promote_1d, historicalPricing.story_promote_1d);
  assert.equal(historyDoc.exists, true);
  assert.equal(historyDoc.data().event_type, "config_rollback_published");
  assert.equal(historyDoc.data().rollback_to_version, 1);
  assert.equal(auditDoc.exists, true);
});

test("W70 configUpsertDraft rejects invalid pricing payloads", async () => {
  await seedAdmin("super-admin-d");
  await expectHttpsError(
    () =>
      configUpsertDraft.run(
        {
          commandId: "config_draft_invalid_1",
          reason: "invalid_pricing_payload",
          pricing: {
            story_promote_1d: 0,
            story_promote_3d: 0,
            story_promote_7d: 0,
            offer_pin_1d: 0,
            offer_pin_3d: 0,
            offer_pin_7d: 0,
            currency: "ILS",
          },
        },
        callableContext({
          uid: "super-admin-d",
          token: { admin: true, role: "super_admin", super_admin: true },
        }),
      ),
    "invalid-argument",
    "config_validation_failed",
  );
});
