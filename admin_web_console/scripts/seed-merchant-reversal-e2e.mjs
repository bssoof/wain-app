#!/usr/bin/env node

import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import path from "node:path";

const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

export const PROJECT_ID =
  process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ||
  process.env.GCLOUD_PROJECT ||
  "wain-d2e28";
export const AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
export const FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

export const E2E_IDS = {
  merchantEmail: "merchant.reversal.e2e@wain.test",
  merchantPassword: "MerchantE2E!2026",
  admin1Email: "finance.admin.one@wain.test",
  admin2Email: "finance.admin.two@wain.test",
  superAdminEmail: "super.admin.e2e@wain.test",
  adminPassword: "AdminE2E!2026",
  venueId: "venue_test_1",
  directEntryId: "entry_test_50",
  secondApprovalEntryId: "entry_test_150",
  rejectEntryId: "entry_test_reject_50",
  creditEntryId: "entry_test_credit",
  unsupportedEntryId: "entry_test_unsupported",
  raceEntryId: "entry_test_race_50",
};

function assertLocalHostPort(value, label) {
  const normalized = String(value ?? "").trim();
  const withoutProtocol = normalized.replace(/^https?:\/\//i, "");
  const host = withoutProtocol.split("/")[0]?.split(":")[0] ?? "";
  const loopbackHosts = new Set(["127.0.0.1", "localhost", "::1", "[::1]"]);

  if (!loopbackHosts.has(host)) {
    throw new Error(`${label} must point at a local emulator host: ${normalized}`);
  }
}

export function configureLocalEmulatorEnv() {
  assertLocalHostPort(AUTH_EMULATOR_HOST, "FIREBASE_AUTH_EMULATOR_HOST");
  assertLocalHostPort(FIRESTORE_EMULATOR_HOST, "FIRESTORE_EMULATOR_HOST");
  process.env.GCLOUD_PROJECT = PROJECT_ID;
  process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_EMULATOR_HOST;
  process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;
}

export function initializeAdmin() {
  configureLocalEmulatorEnv();
  if (admin.apps.length > 0) {
    return admin.app();
  }
  return admin.initializeApp({ projectId: PROJECT_ID });
}

function timestamp(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

async function ensureAuthUser(auth, { email, password, displayName, claims }) {
  let user;
  try {
    user = await auth.getUserByEmail(email);
    await auth.updateUser(user.uid, {
      password,
      emailVerified: true,
      disabled: false,
      displayName,
    });
  } catch (error) {
    if (error?.code !== "auth/user-not-found") {
      throw error;
    }
    user = await auth.createUser({
      email,
      password,
      emailVerified: true,
      disabled: false,
      displayName,
    });
  }

  await auth.setCustomUserClaims(user.uid, claims);
  return user;
}

async function writeAdminProfile(db, user, role) {
  await db.collection("admins").doc(user.uid).set(
    {
      active: true,
      role,
      roles: [role],
      name: user.displayName,
      email: user.email,
      updated_at: timestamp(),
    },
    { merge: true },
  );
}

async function cleanKnownDocs(db) {
  const ids = E2E_IDS;
  const walletRef = db.collection("merchant_wallets").doc(ids.venueId);
  const deleteRefs = [
    db.collection("venues").doc(ids.venueId),
    db.collection("wallet_reversal_requests").doc(`merchant_review_${ids.directEntryId}`),
    db.collection("wallet_reversal_requests").doc(`merchant_review_${ids.secondApprovalEntryId}`),
    db.collection("wallet_reversal_requests").doc(`merchant_review_${ids.rejectEntryId}`),
    db.collection("wallet_reversal_requests").doc(`merchant_review_${ids.raceEntryId}`),
    db.collection("wallet_reversal_requests").doc(`reversal_request_${ids.raceEntryId}`),
    ...[
      ids.directEntryId,
      ids.secondApprovalEntryId,
      ids.rejectEntryId,
      ids.creditEntryId,
      ids.unsupportedEntryId,
      ids.raceEntryId,
      `reversal_${ids.directEntryId}`,
      `reversal_${ids.secondApprovalEntryId}`,
      `reversal_${ids.rejectEntryId}`,
      `reversal_${ids.raceEntryId}`,
    ].map((entryId) => walletRef.collection("entries").doc(entryId)),
  ];

  await Promise.all(deleteRefs.map((ref) => ref.delete().catch(() => undefined)));
}

async function seedWalletEntry(db, entryId, data) {
  await db
    .collection("merchant_wallets")
    .doc(E2E_IDS.venueId)
    .collection("entries")
    .doc(entryId)
    .set(
      {
        venue_id: E2E_IDS.venueId,
        currency: "ILS",
        reversal_entry_id: null,
        created_at: timestamp(-10 * 60_000),
        ...data,
      },
      { merge: true },
    );
}

export async function seedMerchantReversalE2E() {
  const app = initializeAdmin();
  const auth = app.auth();
  const db = app.firestore();
  const ids = E2E_IDS;

  const [merchant, admin1, admin2, superAdmin] = await Promise.all([
    ensureAuthUser(auth, {
      email: ids.merchantEmail,
      password: ids.merchantPassword,
      displayName: "E2E Merchant",
      claims: { merchant: true },
    }),
    ensureAuthUser(auth, {
      email: ids.admin1Email,
      password: ids.adminPassword,
      displayName: "E2E Finance Admin 1",
      claims: { admin: true, role: "finance_admin", finance_admin: true },
    }),
    ensureAuthUser(auth, {
      email: ids.admin2Email,
      password: ids.adminPassword,
      displayName: "E2E Finance Admin 2",
      claims: { admin: true, role: "finance_admin", finance_admin: true },
    }),
    ensureAuthUser(auth, {
      email: ids.superAdminEmail,
      password: ids.adminPassword,
      displayName: "E2E Super Admin",
      claims: {
        admin: true,
        role: "super_admin",
        super_admin: true,
        finance_admin: true,
      },
    }),
  ]);

  await cleanKnownDocs(db);

  await Promise.all([
    writeAdminProfile(db, admin1, "finance_admin"),
    writeAdminProfile(db, admin2, "finance_admin"),
    writeAdminProfile(db, superAdmin, "super_admin"),
    db.collection("merchants").doc(merchant.uid).set(
      {
        venue_id: ids.venueId,
        uid: merchant.uid,
        updated_at: timestamp(),
      },
      { merge: true },
    ),
    // Existing Flutter merchant screens still read this legacy hint in a few places.
    db.collection("users").doc(merchant.uid).set(
      {
        display_name: "E2E Merchant",
        email: ids.merchantEmail,
        merchant_venue_id: ids.venueId,
        updated_at: timestamp(),
      },
      { merge: true },
    ),
    db.collection("venues").doc(ids.venueId).set(
      {
        name: "E2E Reversal Venue",
        name_ar: "جهة اختبار التصحيح",
        owner_uid: merchant.uid,
        status: "active",
        visibility_status: "visible",
        operational_status: "open",
        subscription_status: "active",
        updated_at: timestamp(),
      },
      { merge: true },
    ),
    db.collection("merchant_wallets").doc(ids.venueId).set(
      {
        venue_id: ids.venueId,
        status: "active",
        currency: "ILS",
        available_balance: 800,
        balance: 800,
        updated_at: timestamp(),
      },
      { merge: true },
    ),
  ]);

  await Promise.all([
    seedWalletEntry(db, ids.directEntryId, {
      type: "debit",
      amount: 50,
      feature_key: "story_promotion",
      reference_type: "story",
      reference_id: "story_e2e_direct",
    }),
    seedWalletEntry(db, ids.secondApprovalEntryId, {
      type: "debit",
      amount: 150,
      feature_key: "offer_pin",
      reference_type: "offer",
      reference_id: "offer_e2e_second",
    }),
    seedWalletEntry(db, ids.rejectEntryId, {
      type: "debit",
      amount: 50,
      feature_key: "story_promotion",
      reference_type: "story",
      reference_id: "story_e2e_reject",
    }),
    seedWalletEntry(db, ids.creditEntryId, {
      type: "credit",
      amount: 30,
      feature_key: "story_promotion",
      reference_type: "story",
      reference_id: "story_e2e_credit",
    }),
    seedWalletEntry(db, ids.unsupportedEntryId, {
      type: "debit",
      amount: 25,
      feature_key: "manual_adjustment",
      reference_type: "manual",
      reference_id: "manual_e2e_unsupported",
    }),
    seedWalletEntry(db, ids.raceEntryId, {
      type: "debit",
      amount: 50,
      feature_key: "story_promotion",
      reference_type: "story",
      reference_id: "story_e2e_race",
    }),
    db.collection("stories").doc("story_e2e_direct").set(
      { venue_id: ids.venueId, is_promoted: true, updated_at: timestamp() },
      { merge: true },
    ),
    db.collection("stories").doc("story_e2e_reject").set(
      { venue_id: ids.venueId, is_promoted: true, updated_at: timestamp() },
      { merge: true },
    ),
    db.collection("stories").doc("story_e2e_race").set(
      { venue_id: ids.venueId, is_promoted: true, updated_at: timestamp() },
      { merge: true },
    ),
    db.collection("offers").doc("offer_e2e_second").set(
      { venue_id: ids.venueId, is_featured: true, updated_at: timestamp() },
      { merge: true },
    ),
  ]);

  return {
    projectId: PROJECT_ID,
    emulatorHosts: {
      auth: AUTH_EMULATOR_HOST,
      firestore: FIRESTORE_EMULATOR_HOST,
      functionsBaseUrl: `http://127.0.0.1:5001/${PROJECT_ID}/us-central1`,
    },
    users: {
      merchant: {
        uid: merchant.uid,
        email: ids.merchantEmail,
        password: ids.merchantPassword,
      },
      admin1: {
        uid: admin1.uid,
        email: ids.admin1Email,
        password: ids.adminPassword,
        role: "finance_admin",
      },
      admin2: {
        uid: admin2.uid,
        email: ids.admin2Email,
        password: ids.adminPassword,
        role: "finance_admin",
      },
      superAdmin: {
        uid: superAdmin.uid,
        email: ids.superAdminEmail,
        password: ids.adminPassword,
        role: "super_admin",
      },
    },
    seeded: {
      venueId: ids.venueId,
      walletBalance: 800,
      entries: [
        ids.directEntryId,
        ids.secondApprovalEntryId,
        ids.rejectEntryId,
        ids.creditEntryId,
        ids.unsupportedEntryId,
        ids.raceEntryId,
      ],
    },
  };
}

if (fileURLToPath(import.meta.url) === path.resolve(process.argv[1] ?? "")) {
  seedMerchantReversalE2E()
    .then((result) => {
      console.log(JSON.stringify(result, null, 2));
    })
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
