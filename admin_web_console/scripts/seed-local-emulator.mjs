#!/usr/bin/env node

import { createRequire } from "node:module";

import {
  parseOutputOptions,
  redactSecrets,
  writeSeedFile,
} from "./seed-output.mjs";

const require = createRequire(import.meta.url);
const admin = require("firebase-admin");
const {
  WALLET_PRICING_DEFAULTS,
} = require("../../functions/src/wallet_config_utils.js");

const PROJECT_ID = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "wain-d2e28";
const AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
const ADMIN_EMAIL = process.env.WAIN_LOCAL_ADMIN_EMAIL || "local.admin@wain.test";
const ADMIN_PASSWORD =
  process.env.WAIN_LOCAL_ADMIN_PASSWORD || "WainLocalAdmin!2026";
const APP_CHECK_TOKEN =
  process.env.WAIN_LOCAL_APP_CHECK_TOKEN || "local-dev-app-check";

process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_EMULATOR_HOST;
process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;
process.env.GCLOUD_PROJECT = PROJECT_ID;

function assertLocalHostPort(value, label) {
  const normalized = String(value ?? "").trim();
  const withoutProtocol = normalized.replace(/^https?:\/\//i, "");
  const host = withoutProtocol.split("/")[0]?.split(":")[0] ?? "";
  const loopbackHosts = new Set(["127.0.0.1", "localhost", "::1", "[::1]"]);

  if (!loopbackHosts.has(host)) {
    throw new Error(
      `${label} must point at a local emulator host. Received: ${normalized}`,
    );
  }
}

function assertLocalEmulatorConfig() {
  assertLocalHostPort(AUTH_EMULATOR_HOST, "FIREBASE_AUTH_EMULATOR_HOST");
  assertLocalHostPort(FIRESTORE_EMULATOR_HOST, "FIRESTORE_EMULATOR_HOST");
}

function initializeAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  return admin.initializeApp({ projectId: PROJECT_ID });
}

async function ensureAdminUser(auth, db) {
  let user;
  try {
    user = await auth.getUserByEmail(ADMIN_EMAIL);
    await auth.updateUser(user.uid, {
      password: ADMIN_PASSWORD,
      emailVerified: true,
      disabled: false,
      displayName: "مدير محلي",
    });
  } catch (error) {
    if (error?.code !== "auth/user-not-found") {
      throw error;
    }

    user = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      emailVerified: true,
      disabled: false,
      displayName: "مدير محلي",
    });
  }

  await auth.setCustomUserClaims(user.uid, {
    admin: true,
    isAdmin: true,
    role: "super_admin",
    roles: ["super_admin"],
    super_admin: true,
    finance_admin: true,
    content_admin: true,
  });

  await db.collection("admins").doc(user.uid).set(
    {
      active: true,
      role: "super_admin",
      roles: ["super_admin"],
      name: "مدير محلي",
      email: ADMIN_EMAIL,
      updated_at: new Date().toISOString(),
    },
    { merge: true },
  );

  return user;
}

async function signInWithPassword() {
  const response = await fetch(
    `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-emulator-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        returnSecureToken: true,
      }),
    },
  );

  const body = await response.json();
  if (!response.ok || !body.idToken) {
    throw new Error(`Auth emulator sign-in failed: ${JSON.stringify(body)}`);
  }

  return body.idToken;
}

function timestamp(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

async function seedVenue(db) {
  const venueId = "local_emulator_venue_01";
  await db.collection("venues").doc(venueId).set(
    {
      name_ar: "مقهى التجربة المحلي",
      name_en: "Local Emulator Cafe",
      city: "رام الله",
      status: "active",
      visibility_status: "visible",
      operational_status: "open",
      subscription_status: "active",
      created_at: timestamp(-60 * 60_000),
      updated_at: timestamp(),
    },
    { merge: true },
  );

  await db.collection("merchant_wallets").doc(venueId).set(
    {
      venue_id: venueId,
      currency: "ILS",
      status: "active",
      available_balance: 25,
      low_balance_threshold: 10,
      created_at: timestamp(-60 * 60_000),
      updated_at: timestamp(),
    },
    { merge: true },
  );

  return venueId;
}

async function seedReviews(db, venueId) {
  const rows = [
    {
      id: "local_review_publish",
      status: "hidden",
      hidden: true,
      flagged: false,
      comment: "مراجعة مخفية للتأكد من زر النشر.",
      rating: 4,
      author_name: "زائر النشر",
      created_at: timestamp(-1_000),
    },
    {
      id: "local_review_hide",
      status: "published",
      hidden: false,
      flagged: false,
      comment: "مراجعة منشورة للتأكد من زر الإخفاء.",
      rating: 2,
      author_name: "زائر الإخفاء",
      created_at: timestamp(-2_000),
    },
    {
      id: "local_review_escalate",
      status: "published",
      hidden: false,
      flagged: false,
      comment: "مراجعة منشورة للتأكد من زر الإرسال للمراجعة.",
      rating: 3,
      author_name: "زائر المراجعة",
      created_at: timestamp(-3_000),
    },
  ];

  await Promise.all(
    rows.map((row) =>
      db
        .collection("venues")
        .doc(venueId)
        .collection("reviews")
        .doc(row.id)
        .set(
          {
            ...row,
            updated_at: timestamp(),
          },
          { merge: true },
        ),
    ),
  );

  return rows.map((row) => row.id);
}

async function seedContent(db, venueId) {
  const offerRows = [
    ["local_offer_approve", "عرض محلي للاعتماد"],
    ["local_offer_reject", "عرض محلي للرفض"],
    ["local_offer_pause", "عرض محلي للإيقاف"],
  ];
  const storyRows = [
    ["local_story_approve", "قصة محلية للاعتماد"],
    ["local_story_reject", "قصة محلية للرفض"],
    ["local_story_pause", "قصة محلية للإيقاف"],
  ];

  await Promise.all([
    ...offerRows.map(([id, title], index) =>
      db.collection("offers").doc(id).set(
        {
          venue_id: venueId,
          title_ar: title,
          description_ar: "بيانات محلية لاختبار قرار المحتوى.",
          admin_state: "pending",
          is_active: false,
          created_at: timestamp(-10_000 - index * 1_000),
          updated_at: timestamp(-10_000 - index * 1_000),
        },
        { merge: true },
      ),
    ),
    ...storyRows.map(([id, caption], index) =>
      db.collection("stories").doc(id).set(
        {
          venue_id: venueId,
          caption,
          admin_state: "pending",
          is_active: false,
          created_at: timestamp(-20_000 - index * 1_000),
          updated_at: timestamp(-20_000 - index * 1_000),
        },
        { merge: true },
      ),
    ),
  ]);

  return {
    offers: offerRows.map(([id]) => id),
    stories: storyRows.map(([id]) => id),
  };
}

async function seedTopups(db, venueId, adminUid) {
  const rows = [
    ["local_topup_approve", 35, "LOCAL-APPROVE-001"],
    ["local_topup_reject", 20, "LOCAL-REJECT-001"],
  ];

  await Promise.all(
    rows.map(([id, amount, reference], index) =>
      db.collection("merchant_topup_requests").doc(id).set(
        {
          venue_id: venueId,
          requested_by_uid: `${adminUid}_merchant`,
          amount,
          currency: "ILS",
          status: "pending",
          transfer_reference: reference,
          proof_image_url: "https://example.test/local-proof.jpg",
          proof_retention_until: timestamp(7 * 24 * 60 * 60_000),
          created_at: timestamp(-30_000 - index * 1_000),
          updated_at: timestamp(-30_000 - index * 1_000),
        },
        { merge: true },
      ),
    ),
  );

  return rows.map(([id]) => id);
}

async function seedReadinessSignals(db, venueId) {
  await Promise.all([
    db.collection("merchant_wallet_reports").doc(venueId).set(
      {
        venue_id: venueId,
        currency: "ILS",
        total_credited: 35,
        topup_total_credited: 35,
        total_debited: 0,
        last_30d_debited: 0,
        debit_by_feature: {},
        debit_count_by_feature: {},
        most_used_debit_feature: "other",
        last_top_up_amount: 35,
        updated_at: timestamp(),
      },
      { merge: true },
    ),
    db.collection("wallet_notification_events").doc(`${venueId}_story_expiring_seed`).set(
      {
        event_key: `${venueId}_story_expiring_seed`,
        user_uid: `${venueId}_merchant`,
        type: "wallet_story_promotion_expiring",
        title: "تنبيه محلي",
        body: "تنبيه تجريبي لتأكيد جاهزية الإشعارات في البيئة المحلية.",
        created_by_uid: "system",
        created_at: timestamp(),
        updated_at: timestamp(),
      },
      { merge: true },
    ),
  ]);
}

async function seedWalletPricing(db, adminUid) {
  await db.collection("wallet_feature_pricing").doc("default").set(
    {
      ...WALLET_PRICING_DEFAULTS,
      live_version: 1,
      updated_by_uid: adminUid,
      updated_by_role: "super_admin",
      created_at: timestamp(-60 * 60_000),
      updated_at: timestamp(),
    },
    { merge: true },
  );
}

async function main() {
  // Parsed before anything is seeded: a mistyped flag should fail on an empty
  // emulator, not after the write pass, and its message should come out of the
  // handler below rather than as a bare module-load stack trace.
  const { outPath, printSecrets } = parseOutputOptions(process.argv.slice(2));

  assertLocalEmulatorConfig();

  const app = initializeAdmin();
  const auth = app.auth();
  const db = app.firestore();

  const user = await ensureAdminUser(auth, db);
  const venueId = await seedVenue(db);
  const [reviews, content, topups] = await Promise.all([
    seedReviews(db, venueId),
    seedContent(db, venueId),
    seedTopups(db, venueId, user.uid),
  ]);
  await seedReadinessSignals(db, venueId);
  await seedWalletPricing(db, user.uid);
  const idToken = await signInWithPassword();

  const result = {
    projectId: PROJECT_ID,
    emulatorHosts: {
      auth: AUTH_EMULATOR_HOST,
      firestore: FIRESTORE_EMULATOR_HOST,
      functionsBaseUrl: `http://127.0.0.1:5001/${PROJECT_ID}/us-central1`,
    },
    admin: {
      uid: user.uid,
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      role: "super_admin",
    },
    tokens: {
      authToken: idToken,
      appCheckToken: APP_CHECK_TOKEN,
    },
    seeded: {
      venueId,
      reviews,
      offers: content.offers,
      stories: content.stories,
      topups,
      pricingDoc: "wallet_feature_pricing/default",
      readinessSignalsSeeded: true,
    },
  };

  if (outPath) {
    const written = await writeSeedFile(outPath, result);
    console.error(
      `Full seed — admin password, ID token, App Check token — written to ${written}`,
    );
  }

  if (printSecrets) {
    console.error(
      "--print-secrets: the ID token, App Check token and admin password follow on stdout.",
    );
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  console.log(JSON.stringify(redactSecrets(result), null, 2));

  if (!outPath) {
    console.error(
      "Secrets redacted. Use --out FILE to capture them, or --print-secrets to accept them on stdout.",
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
