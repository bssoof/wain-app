const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || "demo-wain-revoke-script";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const { backfillMerchantAnalytics } = require("../../lib/index.js");
const { revokeMerchantLink } = require("../../scripts/revoke_merchant_link.js");

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

function tsNow() {
  return admin.firestore.Timestamp.now();
}

async function expectHttpsError(action, expectedCode) {
  let error = null;
  try {
    await action();
  } catch (err) {
    error = err;
  }
  assert.ok(error, `Expected error ${expectedCode}`);
  assert.match(String(error.code || ""), new RegExp(expectedCode));
  return error;
}

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("revokeMerchantLink atomically clears user link and blocks J1b self-heal path", async () => {
  const uid = "merchant-a";
  const venueId = "venue-a";
  const logs = [];

  await db.collection("users").doc(uid).set({
    merchant_venue_id: venueId,
    is_merchant: true,
    updated_at: tsNow(),
  });

  await db.collection("merchants").doc(uid).set({
    uid,
    venue_id: venueId,
    created_at: tsNow(),
    updated_at: tsNow(),
  });

  const result = await revokeMerchantLink({
    uid,
    logger: {
      log(entry) {
        logs.push(entry);
      },
    },
  });

  assert.equal(result.result, "revoked");
  assert.equal(result.uid, uid);
  assert.equal(result.venueId, venueId);
  assert.equal(logs[0].venueId, venueId);

  const [userDoc, merchantDoc] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("merchants").doc(uid).get(),
  ]);

  assert.equal(merchantDoc.exists, false);
  assert.equal(userDoc.exists, true);
  assert.equal(userDoc.data().is_merchant, false);
  assert.equal("merchant_venue_id" in userDoc.data(), false);

  await expectHttpsError(
    () => backfillMerchantAnalytics.run(
      { days: 7 },
      {
        auth: { uid, token: {} },
        app: { appId: "emu-app" },
      },
    ),
    "permission-denied",
  );

  const healedMerchant = await db.collection("merchants").doc(uid).get();
  assert.equal(healedMerchant.exists, false);
});
