const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || "demo-wain-security-surface";
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
  trackVenueEvent,
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

async function seedVenue(venueId, { isActive = true } = {}) {
  await db.collection("venues").doc(venueId).set({
    name_ar: `Venue ${venueId}`,
    lat: 31.9,
    lng: 35.2,
    is_active: isActive,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
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

async function seedStory({ storyId, venueId, expiresOffsetMs = 60 * 60 * 1000 }) {
  await db.collection("stories").doc(storyId).set({
    venue_id: venueId,
    media_url: "https://example.com/story.jpg",
    media_type: "image",
    expires_at: tsFromNow(expiresOffsetMs),
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  });
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
  }, { merge: true });
}

async function seedStoryPromotionPricing() {
  await db.collection("wallet_feature_pricing").doc("default").set({
    currency: "ILS",
    story_promote_1d: 3,
    story_promote_3d: 7,
    story_promote_7d: 14,
    updated_at: tsFromNow(-60_000),
  });
}

function parseHttpsError(error) {
  return {
    code: String(error?.code || ""),
    message: String(error?.message || ""),
  };
}

async function captureAuditLogs(fn) {
  const originalLog = console.log;
  const captured = [];
  console.log = (...args) => {
    captured.push(args.map((arg) => {
      if (typeof arg === "string") return arg;
      return JSON.stringify(arg);
    }).join(" "));
  };

  try {
    const result = await fn();
    return { result, logs: captured };
  } finally {
    console.log = originalLog;
  }
}

function findAuditEvent(logs, eventName) {
  for (const entry of logs) {
    try {
      const parsed = JSON.parse(entry);
      if (parsed && parsed.event === eventName) {
        return parsed;
      }
    } catch {
      // ignore non-JSON logs
    }
  }
  return null;
}

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("M1 invalid invite code error stays generic", async () => {
  await assert.rejects(
    () => redeemInviteCode.run({ code: "WAIN-LEAK-777" }, callableContext({ uid: "user-a" })),
    (error) => {
      const parsed = parseHttpsError(error);
      assert.equal(parsed.code, "not-found");
      assert.doesNotMatch(parsed.message, /WAIN-LEAK-777|venue-/i);
      return true;
    },
  );
});

test("M2 createClaimToken venue mismatch does not leak actual venue ids", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-m2", venueId: "venue-a" });

  await assert.rejects(
    () => createClaimToken.run(
      { offerId: "offer-m2", venueId: "venue-b", deviceId: "device-a", city: "ramallah", source: "test" },
      callableContext({ uid: "user-a" }),
    ),
    (error) => {
      const parsed = parseHttpsError(error);
      assert.equal(parsed.code, "invalid-argument");
      assert.equal(parsed.message, "venue_mismatch");
      assert.doesNotMatch(parsed.message, /venue-a|venue-b/i);
      return true;
    },
  );
});

test("M3 invalid token responses do not echo raw token", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");

  for (const callable of [validateToken, redeemToken]) {
    await assert.rejects(
      () => callable.run({ token: "secret-invalid-token-123" }, callableContext({ uid: "merchant-a" })),
      (error) => {
        const parsed = parseHttpsError(error);
        assert.match(parsed.code, /not-found/);
        assert.doesNotMatch(parsed.message, /secret-invalid-token-123/i);
        return true;
      },
    );
  }
});

test("N1 unauthenticated merchant callables are blocked", async () => {
  const cases = [
    () => validateToken.run({ token: "x" }, callableContext()),
    () => redeemToken.run({ token: "x" }, callableContext()),
    () => redeemInviteCode.run({ code: "WAIN-123" }, callableContext()),
    () => promoteStory.run(
      { storyId: "story-a", durationDays: 1, requestId: "promo_unauthenticated" },
      callableContext(),
    ),
    () => backfillMerchantAnalytics.run({ days: 7 }, callableContext()),
  ];

  for (const invoke of cases) {
    await assert.rejects(invoke, (error) => {
      const parsed = parseHttpsError(error);
      assert.equal(parsed.code, "unauthenticated");
      return true;
    });
  }
});

test("trackVenueEvent accepts Phase 3 event types and omits user_id by default", async () => {
  await seedVenue("venue-track");

  await trackVenueEvent.run(
    {
      venueId: "venue-track",
      eventType: "offer_detail_view",
      offerId: "offer-track",
      source: "offer_details",
    },
    callableContext({ uid: "user-track" }),
  );

  await trackVenueEvent.run(
    {
      venueId: "venue-track",
      eventType: "nav_click",
      navApp: "google_maps",
      source: "venue_details",
    },
    callableContext({ uid: "user-track" }),
  );

  const detailSnap = await db.collection("venue_events")
    .where("event_type", "==", "offer_detail_view")
    .limit(1)
    .get();
  const navSnap = await db.collection("venue_events")
    .where("event_type", "==", "nav_click")
    .limit(1)
    .get();

  assert.equal(detailSnap.empty, false);
  assert.equal(navSnap.empty, false);

  const detail = detailSnap.docs[0].data();
  const nav = navSnap.docs[0].data();

  assert.equal(detail.offer_id, "offer-track");
  assert.equal(detail.source, "offer_details");
  assert.equal(Object.prototype.hasOwnProperty.call(detail, "user_id"), false);

  assert.equal(nav.nav_app, "google_maps");
  assert.equal(nav.source, "venue_details");
  assert.equal(Object.prototype.hasOwnProperty.call(nav, "user_id"), false);
});

test("trackVenueEvent tolerates missing Phase 3 optional metadata and still records venue-level events", async () => {
  await seedVenue("venue-track");

  await trackVenueEvent.run(
    {
      venueId: "venue-track",
      eventType: "offer_detail_view",
      source: "offer_details",
    },
    callableContext({ uid: "user-track" }),
  );

  await trackVenueEvent.run(
    {
      venueId: "venue-track",
      eventType: "nav_click",
      source: "venue_details",
    },
    callableContext({ uid: "user-track" }),
  );

  const detailSnap = await db.collection("venue_events")
    .where("event_type", "==", "offer_detail_view")
    .limit(1)
    .get();
  const navSnap = await db.collection("venue_events")
    .where("event_type", "==", "nav_click")
    .limit(1)
    .get();

  assert.equal(detailSnap.empty, false);
  assert.equal(navSnap.empty, false);

  const detail = detailSnap.docs[0].data();
  const nav = navSnap.docs[0].data();

  assert.equal(detail.venue_id, "venue-track");
  assert.equal(detail.source, "offer_details");
  assert.equal(Object.prototype.hasOwnProperty.call(detail, "offer_id"), false);

  assert.equal(nav.venue_id, "venue-track");
  assert.equal(nav.source, "venue_details");
  assert.equal(Object.prototype.hasOwnProperty.call(nav, "nav_app"), false);
});

test("N2 stale session after linkage change is denied", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await db.collection("merchants").doc("merchant-a").delete();
  await db.collection("users").doc("merchant-a").delete();

  await assert.rejects(
    () => backfillMerchantAnalytics.run({ days: 7 }, callableContext({ uid: "merchant-a" })),
    (error) => {
      const parsed = parseHttpsError(error);
      assert.equal(parsed.code, "permission-denied");
      return true;
    },
  );
});

test("I1 redeemInviteCode emits audit log with minimum fields", async () => {
  await seedInvite({ inviteId: "invite-i1", code: "WAIN-I1", venueId: "venue-a" });

  const { logs } = await captureAuditLogs(() =>
    redeemInviteCode.run({ code: "WAIN-I1" }, callableContext({ uid: "merchant-a" })),
  );

  const audit = findAuditEvent(logs, "redeemInviteCode");
  assert.ok(audit, logs.join("\n"));
  assert.equal(audit.uid, "merchant-a");
  assert.equal(audit.inviteId, "invite-i1");
  assert.equal(audit.venueId, "venue-a");
  assert.equal(audit.result, "success");
  assert.equal(typeof audit.timestamp, "number");
});

test("I2 redeemToken emits audit log with minimum fields", async () => {
  await seedVenue("venue-a");
  await seedOffer({ offerId: "offer-i2", venueId: "venue-a" });
  await seedMerchant("merchant-a", "venue-a");
  const claim = await createClaimToken.run(
    { offerId: "offer-i2", venueId: "venue-a", deviceId: "device-a", city: "ramallah", source: "test" },
    callableContext({ uid: "user-a" }),
  );

  const { logs } = await captureAuditLogs(() =>
    redeemToken.run({ token: claim.token, deviceId: "scanner-a" }, callableContext({ uid: "merchant-a" })),
  );

  const audit = findAuditEvent(logs, "redeemToken");
  assert.ok(audit, logs.join("\n"));
  assert.equal(audit.uid, "merchant-a");
  assert.equal(audit.claimId, claim.claimId);
  assert.equal(audit.offerId, "offer-i2");
  assert.equal(audit.venueId, "venue-a");
  assert.equal(audit.result, "redeemed");
  assert.equal(typeof audit.timestamp, "number");
});

test("I3 promoteStory emits audit log with minimum fields", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");
  await seedWallet("venue-a", { balance: 20 });
  await seedStoryPromotionPricing();
  await seedStory({ storyId: "story-i3", venueId: "venue-a" });

  const { logs } = await captureAuditLogs(() =>
    promoteStory.run(
      {
        storyId: "story-i3",
        durationDays: 1,
        requestId: "promo_audit_story",
      },
      callableContext({ uid: "merchant-a" }),
    ),
  );

  const audit = findAuditEvent(logs, "promoteStory");
  assert.ok(audit, logs.join("\n"));
  assert.equal(audit.uid, "merchant-a");
  assert.equal(audit.storyId, "story-i3");
  assert.equal(audit.venueId, "venue-a");
  assert.equal(audit.durationDays, 1);
  assert.equal(audit.requestId, "promo_audit_story");
  assert.equal(audit.chargedAmount, 3);
  assert.equal(audit.balanceAfter, 17);
  assert.equal(audit.result, "success");
  assert.equal(typeof audit.timestamp, "number");
});

test("I4 backfillMerchantAnalytics emits audit log with minimum fields", async () => {
  await seedVenue("venue-a");
  await seedMerchant("merchant-a", "venue-a");

  const { logs } = await captureAuditLogs(() =>
    backfillMerchantAnalytics.run({ days: 7 }, callableContext({ uid: "merchant-a" })),
  );

  const audit = findAuditEvent(logs, "backfillMerchantAnalytics");
  assert.ok(audit, logs.join("\n"));
  assert.equal(audit.uid, "merchant-a");
  assert.equal(audit.venueId, "venue-a");
  assert.equal(audit.days, 7);
  assert.equal(audit.result, "success");
  assert.equal(typeof audit.timestamp, "number");
});
