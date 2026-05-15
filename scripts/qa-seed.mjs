#!/usr/bin/env node
/* eslint-disable no-console */

import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const require = createRequire(import.meta.url);

let admin;
let walletConfig;
try {
  admin = require("../functions/node_modules/firebase-admin");
  walletConfig = require("../functions/src/wallet_config_utils.js");
} catch (error) {
  console.error(
    "Unable to load firebase-admin or wallet config from functions/. Run `npm --prefix functions install` first.",
  );
  console.error(error?.message ?? error);
  process.exit(2);
}

const { WALLET_PRICING_DEFAULTS } = walletConfig;

const QA_PASSWORDS = {
  user: "UserQA!2026",
  merchant: "MerchantQA!2026",
  admin: "AdminQA!2026",
};

const QA_USERS = [
  {
    key: "user_qa_01",
    email: "user.qa.01@wain.test",
    password: QA_PASSWORDS.user,
    displayName: "QA User 01",
    role: "user",
    claims: { is_qa_test_user: true },
  },
  {
    key: "user_qa_02",
    email: "user.qa.02@wain.test",
    password: QA_PASSWORDS.user,
    displayName: "QA User 02",
    role: "user",
    claims: { is_qa_test_user: true },
  },
  {
    key: "merchant_qa_01",
    email: "merchant.qa.01@wain.test",
    password: QA_PASSWORDS.merchant,
    displayName: "QA Merchant 01",
    role: "merchant",
    venueId: "venue_qa_01",
    claims: { merchant: true, is_qa_test_user: true },
  },
  {
    key: "merchant_qa_02",
    email: "merchant.qa.02@wain.test",
    password: QA_PASSWORDS.merchant,
    displayName: "QA Merchant 02",
    role: "merchant",
    venueId: "venue_qa_02",
    claims: { merchant: true, is_qa_test_user: true },
  },
  {
    key: "admin_finance_01",
    email: "finance.admin.qa.01@wain.test",
    password: QA_PASSWORDS.admin,
    displayName: "QA Finance Admin 01",
    role: "finance_admin",
    claims: {
      admin: true,
      role: "finance_admin",
      finance_admin: true,
      is_qa_test_user: true,
    },
  },
  {
    key: "admin_finance_02",
    email: "finance.admin.qa.02@wain.test",
    password: QA_PASSWORDS.admin,
    displayName: "QA Finance Admin 02",
    role: "finance_admin",
    claims: {
      admin: true,
      role: "finance_admin",
      finance_admin: true,
      is_qa_test_user: true,
    },
  },
  {
    key: "admin_super_01",
    email: "super.admin.qa.01@wain.test",
    password: QA_PASSWORDS.admin,
    displayName: "QA Super Admin 01",
    role: "super_admin",
    claims: {
      admin: true,
      role: "super_admin",
      super_admin: true,
      finance_admin: true,
      is_qa_test_user: true,
    },
  },
];

const QA_VENUES = [
  {
    id: "venue_qa_01",
    merchantKey: "merchant_qa_01",
    nameAr: "مطعم QA الأول",
    nameEn: "QA Restaurant One",
    city: "رام الله",
    categories: ["restaurant"],
    lat: 31.9038,
    lng: 35.2034,
    phone: "0599000001",
    whatsapp: "972599000001",
  },
  {
    id: "venue_qa_02",
    merchantKey: "merchant_qa_02",
    nameAr: "كافيه QA الثاني",
    nameEn: "QA Cafe Two",
    city: "البيرة",
    categories: ["cafe"],
    lat: 31.9104,
    lng: 35.2163,
    phone: "0599000002",
    whatsapp: "972599000002",
  },
];

const REVERSIBLE_AMOUNTS = [50, 99, 100, 250, 600];

function parseArgs(argv) {
  const args = {
    reset: false,
    allowLive: false,
    out: ".tmp/qa-seed-output.json",
    projectId: "",
    help: false,
  };

  for (const token of argv) {
    if (token === "--help" || token === "-h") {
      args.help = true;
      continue;
    }
    if (token === "--reset") {
      args.reset = true;
      continue;
    }
    if (token === "--allow-live") {
      args.allowLive = true;
      continue;
    }
    if (token.startsWith("--project=")) {
      args.projectId = token.slice("--project=".length).trim();
      continue;
    }
    if (token.startsWith("--out=")) {
      args.out = token.slice("--out=".length).trim() || args.out;
    }
  }

  return args;
}

function printHelp() {
  console.log(`
Usage:
  node scripts/qa-seed.mjs --project=demo-wain --reset

Environment:
  FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
  FIRESTORE_EMULATOR_HOST=127.0.0.1:8080

Options:
  --project=<id>    Firebase project id. Falls back to QA_FIREBASE_PROJECT, GCLOUD_PROJECT, or .firebaserc.
  --reset           Remove the known QA seed data and recreate it.
  --out=<path>      Output JSON file. Default: .tmp/qa-seed-output.json
  --allow-live      Permit running without emulator host env vars. Avoid this for QA.
`);
}

function readDefaultProjectId() {
  const candidates = [
    process.env.QA_FIREBASE_PROJECT,
    process.env.GCLOUD_PROJECT,
    process.env.GOOGLE_CLOUD_PROJECT,
  ];
  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }

  const firebasercPath = path.resolve(".firebaserc");
  if (!fs.existsSync(firebasercPath)) {
    return "";
  }
  try {
    const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, "utf8"));
    return typeof firebaserc?.projects?.default === "string"
      ? firebaserc.projects.default.trim()
      : "";
  } catch {
    return "";
  }
}

function assertLocalHostPort(value, label) {
  const normalized = String(value ?? "").trim();
  const withoutProtocol = normalized.replace(/^https?:\/\//i, "");
  const host = withoutProtocol.split("/")[0]?.split(":")[0] ?? "";
  const loopbackHosts = new Set(["127.0.0.1", "localhost", "::1", "[::1]"]);

  if (!loopbackHosts.has(host)) {
    throw new Error(`${label} must point at a local emulator host. Received: ${normalized}`);
  }
}

function configureEmulatorEnv({ allowLive }) {
  if (!allowLive) {
    process.env.FIREBASE_AUTH_EMULATOR_HOST =
      process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
    process.env.FIRESTORE_EMULATOR_HOST =
      process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
  }

  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
  const usingEmulators = Boolean(authHost && firestoreHost);

  if (!usingEmulators && !allowLive) {
    throw new Error(
      "Refusing to seed without Auth and Firestore emulators. Set emulator hosts or pass --allow-live explicitly.",
    );
  }

  if (usingEmulators) {
    assertLocalHostPort(authHost, "FIREBASE_AUTH_EMULATOR_HOST");
    assertLocalHostPort(firestoreHost, "FIRESTORE_EMULATOR_HOST");
  }

  return {
    usingEmulators,
    authHost,
    firestoreHost,
  };
}

function timestamp(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

function dayKey(date = new Date()) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

async function deleteDocTree(db, ref) {
  if (typeof db.recursiveDelete === "function") {
    await db.recursiveDelete(ref);
    return;
  }

  const subcollections = await ref.listCollections();
  await Promise.all(
    subcollections.map(async (collectionRef) => {
      const snap = await collectionRef.get();
      await Promise.all(snap.docs.map((doc) => deleteDocTree(db, doc.ref)));
    }),
  );
  await ref.delete().catch(() => undefined);
}

async function deleteQueryDocs(query) {
  const snap = await query.get();
  await Promise.all(snap.docs.map((doc) => deleteDocTree(doc.ref.firestore, doc.ref)));
  return snap.size;
}

async function deleteKnownAuthUsers(auth) {
  const deleted = [];
  for (const account of QA_USERS) {
    try {
      const user = await auth.getUserByEmail(account.email);
      await auth.deleteUser(user.uid);
      deleted.push({ key: account.key, uid: user.uid });
    } catch (error) {
      if (error?.code !== "auth/user-not-found") {
        throw error;
      }
    }
  }
  return deleted;
}

async function resetKnownFirestoreDocs(db, existingUsersByKey) {
  const deleteRefs = [
    db.collection("wallet_feature_pricing").doc("default"),
    ...QA_VENUES.flatMap((venue) => [
      db.collection("venues").doc(venue.id),
      db.collection("merchant_wallets").doc(venue.id),
      db.collection("merchant_wallet_reports").doc(venue.id),
      db.collection("venue_analytics").doc(venue.id),
      db.collection("venue_analytics_daily").doc(venue.id),
      db.collection("venue_offer_analytics").doc(venue.id),
    ]),
  ];

  for (const user of Object.values(existingUsersByKey)) {
    if (!user?.uid) continue;
    deleteRefs.push(
      db.collection("users").doc(user.uid),
      db.collection("merchants").doc(user.uid),
      db.collection("admins").doc(user.uid),
    );
  }

  await Promise.all(deleteRefs.map((ref) => deleteDocTree(db, ref).catch(() => undefined)));

  let queryDeleted = 0;
  for (const venue of QA_VENUES) {
    queryDeleted += await deleteQueryDocs(
      db.collection("wallet_reversal_requests").where("venue_id", "==", venue.id),
    );
    queryDeleted += await deleteQueryDocs(
      db.collection("merchant_topup_requests").where("venue_id", "==", venue.id),
    );
    queryDeleted += await deleteQueryDocs(
      db.collection("venue_events").where("venue_id", "==", venue.id),
    );
    queryDeleted += await deleteQueryDocs(
      db.collection("navigation_clicks").where("venue_id", "==", venue.id),
    );
    queryDeleted += await deleteQueryDocs(
      db.collection("offers").where("venue_id", "==", venue.id),
    );
    queryDeleted += await deleteQueryDocs(
      db.collection("stories").where("venue_id", "==", venue.id),
    );
  }

  return { docsDeletedByQuery: queryDeleted };
}

async function createOrUpdateAuthUser(auth, account) {
  let user;
  try {
    user = await auth.getUserByEmail(account.email);
    await auth.updateUser(user.uid, {
      password: account.password,
      displayName: account.displayName,
      emailVerified: true,
      disabled: false,
    });
  } catch (error) {
    if (error?.code !== "auth/user-not-found") {
      throw error;
    }
    user = await auth.createUser({
      email: account.email,
      password: account.password,
      displayName: account.displayName,
      emailVerified: true,
      disabled: false,
    });
  }

  await auth.setCustomUserClaims(user.uid, account.claims);
  return user;
}

async function seedUsersAndRoles(auth, db) {
  const usersByKey = {};
  for (const account of QA_USERS) {
    const user = await createOrUpdateAuthUser(auth, account);
    usersByKey[account.key] = {
      uid: user.uid,
      email: account.email,
      password: account.password,
      displayName: account.displayName,
      role: account.role,
      venueId: account.venueId ?? null,
    };

    await db.collection("users").doc(user.uid).set(
      {
        uid: user.uid,
        email: account.email,
        display_name: account.displayName,
        is_qa_test_user: true,
        is_merchant: account.role === "merchant",
        merchant_venue_id: account.venueId ?? null,
        role: account.role,
        updated_at: timestamp(),
      },
      { merge: true },
    );

    if (account.role === "merchant") {
      await db.collection("merchants").doc(user.uid).set(
        {
          uid: user.uid,
          email: account.email,
          venue_id: account.venueId,
          is_qa_test_user: true,
          updated_at: timestamp(),
        },
        { merge: true },
      );
    }

    if (account.role === "finance_admin" || account.role === "super_admin") {
      await db.collection("admins").doc(user.uid).set(
        {
          active: true,
          role: account.role,
          roles: [account.role],
          name: account.displayName,
          email: account.email,
          is_qa_test_user: true,
          capabilities: account.role === "super_admin"
            ? ["create_reversal", "approve_reversal"]
            : ["create_reversal", "approve_reversal"],
          updated_at: timestamp(),
        },
        { merge: true },
      );
    }
  }
  return usersByKey;
}

function venuePhoto(venueId, index = 1) {
  return `https://images.example.test/wain/${venueId}/photo_${index}.jpg`;
}

function buildVenueDoc(venue, ownerUid) {
  const now = timestamp();
  return {
    name: venue.nameEn,
    name_ar: venue.nameAr,
    name_en: venue.nameEn,
    name_ar_norm: venue.nameAr,
    name_en_norm: venue.nameEn.toLowerCase(),
    owner_uid: ownerUid,
    city: venue.city,
    lat: venue.lat,
    lng: venue.lng,
    categories: venue.categories,
    all_tags: [...venue.categories, "qa", "launch"],
    min_price: 15,
    max_price: 80,
    currency: "ILS",
    rating: 4.7,
    review_count: 3,
    phone: venue.phone,
    whatsapp: venue.whatsapp,
    instagram: "wain.qa",
    website: "https://example.test/wain-qa",
    photos: [venuePhoto(venue.id, 1), venuePhoto(venue.id, 2)],
    menu_images: [venuePhoto(venue.id, 3)],
    hours: {
      sunday: [{ open: "09:00", close: "23:00", spans_midnight: false }],
      monday: [{ open: "09:00", close: "23:00", spans_midnight: false }],
      tuesday: [{ open: "09:00", close: "23:00", spans_midnight: false }],
      wednesday: [{ open: "09:00", close: "23:00", spans_midnight: false }],
      thursday: [{ open: "09:00", close: "23:00", spans_midnight: false }],
      friday: [{ open: "12:00", close: "23:30", spans_midnight: false }],
      saturday: [{ open: "09:00", close: "23:00", spans_midnight: false }],
    },
    is_24h: false,
    has_active_offers: true,
    active_menu_version_id: "qa_active_menu_v1",
    status: "active",
    visibility_status: "visible",
    operational_status: "open",
    subscription_status: "active",
    is_qa_seed: true,
    created_at: timestamp(-7 * 24 * 60 * 60_000),
    updated_at: now,
  };
}

async function seedVenues(db, usersByKey) {
  const seeded = [];
  for (const venue of QA_VENUES) {
    const merchant = usersByKey[venue.merchantKey];
    await db.collection("venues").doc(venue.id).set(
      buildVenueDoc(venue, merchant.uid),
      { merge: true },
    );
    seeded.push({ venueId: venue.id, merchantUid: merchant.uid });
  }
  return seeded;
}

function entryData({
  venueId,
  type,
  amount,
  balanceAfter,
  featureKey,
  referenceType,
  referenceId,
  note,
  createdAt,
}) {
  return {
    venue_id: venueId,
    type,
    amount,
    currency: "ILS",
    balance_after: balanceAfter,
    feature_key: featureKey ?? null,
    reference_type: referenceType ?? null,
    reference_id: referenceId ?? null,
    reversal_entry_id: null,
    note: note ?? null,
    metadata: {},
    created_at: createdAt,
    updated_at: createdAt,
    is_qa_seed: true,
  };
}

async function seedWallet(db, venueId) {
  const walletRef = db.collection("merchant_wallets").doc(venueId);
  const now = Date.now();
  const openingAmount = 1599;
  const entries = [];
  let balance = openingAmount;

  entries.push({
    id: "entry_qa_opening_credit",
    data: entryData({
      venueId,
      type: "credit",
      amount: openingAmount,
      balanceAfter: balance,
      featureKey: null,
      referenceType: "qa_seed",
      referenceId: "qa_opening_balance",
      note: "QA opening balance",
      createdAt: admin.firestore.Timestamp.fromMillis(now - 60 * 60_000),
    }),
  });

  REVERSIBLE_AMOUNTS.forEach((amount, index) => {
    const featureKey = index === 1 || index === 3 ? "offer_pin" : "story_promotion";
    const referenceType = featureKey === "offer_pin" ? "offer" : "story";
    const referenceId = `${referenceType}_${venueId}_qa_${amount}`;
    balance -= amount;
    entries.push({
      id: `entry_qa_${amount}`,
      data: entryData({
        venueId,
        type: "debit",
        amount,
        balanceAfter: balance,
        featureKey,
        referenceType,
        referenceId,
        note: `QA reversible ${featureKey} debit ${amount} ILS`,
        createdAt: admin.firestore.Timestamp.fromMillis(now - (55 - index * 5) * 60_000),
      }),
    });
  });

  await walletRef.set(
    {
      venue_id: venueId,
      status: "active",
      currency: "ILS",
      balance,
      available_balance: balance,
      low_balance_threshold: 50,
      last_entry_at: entries[entries.length - 1].data.created_at,
      created_at: entries[0].data.created_at,
      updated_at: timestamp(),
      is_qa_seed: true,
    },
    { merge: true },
  );

  await Promise.all(
    entries.map((entry) => walletRef.collection("entries").doc(entry.id).set(entry.data, { merge: true })),
  );

  await db.collection("merchant_wallet_reports").doc(venueId).set(
    {
      venue_id: venueId,
      currency: "ILS",
      total_credited: openingAmount,
      topup_total_credited: openingAmount,
      total_debited: REVERSIBLE_AMOUNTS.reduce((sum, value) => sum + value, 0),
      last_30d_debited: REVERSIBLE_AMOUNTS.reduce((sum, value) => sum + value, 0),
      debit_by_feature: {
        story_promotion: 50 + 100 + 600,
        offer_pin: 99 + 250,
      },
      debit_count_by_feature: {
        story_promotion: 3,
        offer_pin: 2,
      },
      most_used_debit_feature: "story_promotion",
      last_top_up_amount: openingAmount,
      last_entry_at: entries[entries.length - 1].data.created_at,
      updated_at: timestamp(),
      is_qa_seed: true,
    },
    { merge: true },
  );

  return {
    venueId,
    availableBalance: balance,
    entries: entries.map((entry) => entry.id),
  };
}

async function seedWallets(db) {
  const wallets = [];
  for (const venue of QA_VENUES) {
    wallets.push(await seedWallet(db, venue.id));
  }
  return wallets;
}

function baseOffer(venueId, id, index) {
  const now = Date.now();
  return {
    venue_id: venueId,
    title_ar: index === 0 ? "خصم QA 20%" : "عرض QA للقهوة",
    title: index === 0 ? "QA 20% Discount" : "QA Coffee Offer",
    description_ar: "عرض تجريبي ثابت لجولة QA قبل الإطلاق.",
    description: "Stable QA offer for final release testing.",
    terms_ar: "متاح لحسابات QA فقط.",
    discount_type: "percent",
    discount_value: index === 0 ? 20 : 10,
    single_use_per_customer: true,
    is_active: true,
    status: "active",
    start_at: admin.firestore.Timestamp.fromMillis(now - 24 * 60 * 60_000),
    end_at: admin.firestore.Timestamp.fromMillis(now + 14 * 24 * 60 * 60_000),
    claims_count: 0,
    redeemed_count: 0,
    conversion_rate: 0,
    is_featured: index === 0,
    featured_until: index === 0
      ? admin.firestore.Timestamp.fromMillis(now + 7 * 24 * 60 * 60_000)
      : null,
    is_qa_seed: true,
    created_at: timestamp(-24 * 60 * 60_000),
    updated_at: timestamp(),
  };
}

async function seedOffers(db) {
  const offers = [];
  for (const venue of QA_VENUES) {
    for (let index = 0; index < 2; index += 1) {
      const id = `offer_${venue.id}_qa_${index + 1}`;
      await db.collection("offers").doc(id).set(baseOffer(venue.id, id, index), { merge: true });
      offers.push(id);
    }
  }
  return offers;
}

async function seedStories(db) {
  const stories = [];
  const now = Date.now();
  for (const venue of QA_VENUES) {
    for (let index = 0; index < 3; index += 1) {
      const id = `story_${venue.id}_qa_${index + 1}`;
      const createdAt = admin.firestore.Timestamp.fromMillis(now - (index + 1) * 15 * 60_000);
      const expiresAt = admin.firestore.Timestamp.fromMillis(now + (24 + index) * 60 * 60_000);
      const isPromoted = index === 0;
      await db.collection("stories").doc(id).set(
        {
          venue_id: venue.id,
          venue_name: venue.nameAr,
          venue_photo_url: venuePhoto(venue.id, 1),
          type: index === 2 ? "text" : "image",
          text: index === 0
            ? "ستوري QA مروجة"
            : `ستوري QA رقم ${index + 1}`,
          image_url: index === 2 ? null : venuePhoto(venue.id, index + 1),
          video_url: null,
          offer_ref: index === 1 ? `offer_${venue.id}_qa_1` : null,
          status: "published",
          is_active: true,
          is_promoted: isPromoted,
          promoted_until: isPromoted
            ? admin.firestore.Timestamp.fromMillis(now + 3 * 24 * 60 * 60_000)
            : null,
          view_count: index === 0 ? 5 : index,
          duration_seconds: 5,
          created_at: createdAt,
          expires_at: expiresAt,
          created_by: venue.merchantKey,
          is_qa_seed: true,
          updated_at: timestamp(),
        },
        { merge: true },
      );
      stories.push(id);
    }
    await db.collection("venues").doc(venue.id).set(
      { last_story_at: admin.firestore.Timestamp.fromMillis(now - 15 * 60_000) },
      { merge: true },
    );
  }
  return stories;
}

function menuCategoriesForVenue(venue) {
  if (venue.categories.includes("cafe")) {
    return [
      { id: "hot_drinks", nameAr: "مشروبات ساخنة", nameEn: "Hot Drinks", icon: "coffee", sort: 1 },
      { id: "desserts", nameAr: "حلويات", nameEn: "Desserts", icon: "cake", sort: 2 },
    ];
  }
  return [
    { id: "appetizers", nameAr: "مقبلات", nameEn: "Appetizers", icon: "restaurant", sort: 1 },
    { id: "main_courses", nameAr: "أطباق رئيسية", nameEn: "Main Courses", icon: "dinner_dining", sort: 2 },
    { id: "drinks", nameAr: "مشروبات", nameEn: "Drinks", icon: "local_drink", sort: 3 },
  ];
}

async function seedMenus(db) {
  const versions = [];
  for (const venue of QA_VENUES) {
    const versionId = "qa_active_menu_v1";
    const versionRef = db
      .collection("venues")
      .doc(venue.id)
      .collection("menu_versions")
      .doc(versionId);
    await versionRef.set(
      {
        status: "active",
        source: "qa_seed",
        item_count: 4,
        category_count: menuCategoriesForVenue(venue).length,
        created_at: timestamp(-3 * 24 * 60 * 60_000),
        published_at: timestamp(-3 * 24 * 60 * 60_000),
        updated_at: timestamp(),
      },
      { merge: true },
    );

    await db.collection("venues").doc(venue.id).collection("menu_config").doc("main").set(
      {
        draft_version_id: null,
        last_published_by: venue.merchantKey,
        last_published_at: timestamp(-3 * 24 * 60 * 60_000),
        updated_at: timestamp(),
      },
      { merge: true },
    );

    await Promise.all(
      menuCategoriesForVenue(venue).map((category) =>
        versionRef.collection("categories").doc(category.id).set(
          {
            key: category.id,
            name_ar: category.nameAr,
            name_en: category.nameEn,
            icon: category.icon,
            sort_order: category.sort,
            is_custom: false,
            updated_at: timestamp(),
          },
          { merge: true },
        ),
      ),
    );

    const items = venue.categories.includes("cafe")
      ? [
          ["qa_item_1", "قهوة عربية", "Arabic Coffee", "hot_drinks", 10, true],
          ["qa_item_2", "لاتيه", "Latte", "hot_drinks", 16, false],
          ["qa_item_3", "تشيز كيك", "Cheesecake", "desserts", 22, true],
          ["qa_item_4", "براوني", "Brownie", "desserts", 18, false],
        ]
      : [
          ["qa_item_1", "حمص", "Hummus", "appetizers", 14, false],
          ["qa_item_2", "مشاوي مشكلة", "Mixed Grill", "main_courses", 65, true],
          ["qa_item_3", "مقلوبة", "Maqluba", "main_courses", 45, false],
          ["qa_item_4", "ليمون ونعنع", "Mint Lemonade", "drinks", 12, true],
        ];

    await Promise.all(
      items.map(([id, nameAr, nameEn, category, price, featured], index) =>
        versionRef.collection("items").doc(String(id)).set(
          {
            name_ar: nameAr,
            name_en: nameEn,
            description_ar: "صنف QA ثابت لاختبار المنيو.",
            price,
            currency: "ILS",
            category,
            photo_url: "",
            is_available: true,
            is_featured: featured,
            sort_order: index + 1,
            source: "qa_seed",
            created_at: timestamp(-3 * 24 * 60 * 60_000),
            updated_at: timestamp(),
          },
          { merge: true },
        ),
      ),
    );

    versions.push({ venueId: venue.id, versionId });
  }
  return versions;
}

async function seedTopUpRequests(db, usersByKey) {
  const topups = [];
  for (const venue of QA_VENUES) {
    const merchant = usersByKey[venue.merchantKey];
    const id = `topup_${venue.id}_qa_pending`;
    await db.collection("merchant_topup_requests").doc(id).set(
      {
        request_id: id,
        client_request_id: "qa_seed_pending",
        venue_id: venue.id,
        requested_by_uid: merchant.uid,
        amount: 120,
        currency: "ILS",
        status: "pending",
        transfer_reference: `QA-${venue.id}-BANK-001`,
        proof_image_url: `venues/${venue.id}/wallet_topups/qa-proof.jpg`,
        note: "QA seeded pending top-up",
        proof_retention_until: timestamp(7 * 24 * 60 * 60_000),
        created_at: timestamp(-30 * 60_000),
        updated_at: timestamp(-30 * 60_000),
        is_qa_seed: true,
      },
      { merge: true },
    );
    topups.push(id);
  }
  return topups;
}

async function seedAnalyticsInputs(db) {
  const eventIds = [];
  const now = Date.now();
  for (const venue of QA_VENUES) {
    const regularViews = 4;
    const storyViews = 5;
    const storyToVenueViews = 2;
    for (let i = 0; i < regularViews; i += 1) {
      const id = `qa_${venue.id}_view_${i + 1}`;
      await db.collection("venue_events").doc(id).set({
        venue_id: venue.id,
        event_type: "view",
        source: "venue_details",
        created_at: admin.firestore.Timestamp.fromMillis(now - i * 60_000),
        is_qa_seed: true,
      });
      eventIds.push(id);
    }
    for (let i = 0; i < storyViews; i += 1) {
      const id = `qa_${venue.id}_story_view_${i + 1}`;
      await db.collection("venue_events").doc(id).set({
        venue_id: venue.id,
        event_type: "story_view",
        source: "story_viewer",
        story_id: `story_${venue.id}_qa_${(i % 3) + 1}`,
        created_at: admin.firestore.Timestamp.fromMillis(now - (10 + i) * 60_000),
        is_qa_seed: true,
      });
      eventIds.push(id);
    }
    for (let i = 0; i < storyToVenueViews; i += 1) {
      const id = `qa_${venue.id}_story_to_venue_${i + 1}`;
      await db.collection("venue_events").doc(id).set({
        venue_id: venue.id,
        event_type: "view",
        source: "story_viewer",
        story_id: `story_${venue.id}_qa_${i + 1}`,
        created_at: admin.firestore.Timestamp.fromMillis(now - (20 + i) * 60_000),
        is_qa_seed: true,
      });
      eventIds.push(id);
    }
    await db.collection("navigation_clicks").doc(`qa_${venue.id}_nav_1`).set({
      venue_id: venue.id,
      nav_app: "google_maps",
      timestamp: admin.firestore.Timestamp.fromMillis(now - 5 * 60_000),
      is_qa_seed: true,
    });
  }
  return eventIds;
}

async function seedAnalyticsSummaries(db) {
  const dateKey = dayKey();
  for (const venue of QA_VENUES) {
    await db.collection("venue_analytics").doc(venue.id).set(
      {
        venue_id: venue.id,
        views_total: 4,
        views_this_week: 4,
        views_last_week: 0,
        calls_total: 0,
        calls_this_week: 0,
        calls_last_week: 0,
        navs_total: 1,
        navs_this_week: 1,
        navs_last_week: 0,
        story_views_total: 5,
        story_views_this_week: 5,
        story_to_venue_views_total: 2,
        story_to_venue_views_this_week: 2,
        story_to_venue_views_7d: 2,
        contact_intent_7d: 1,
        contact_intent_prev_7d: 0,
        contact_rate_7d: 0.25,
        updated_at: timestamp(),
        is_qa_seed: true,
      },
      { merge: true },
    );
    await db
      .collection("venue_analytics_daily")
      .doc(venue.id)
      .collection("days")
      .doc(dateKey)
      .set(
        {
          venue_id: venue.id,
          date_key: dateKey,
          views: 4,
          calls: 0,
          navs: 1,
          story_views: 5,
          story_to_venue_views: 2,
          offer_detail_views: 0,
          claim_clicks: 0,
          claims_created: 0,
          redemptions: 0,
          updated_at: timestamp(),
          is_qa_seed: true,
        },
        { merge: true },
      );
  }
}

async function seedWalletPricing(db, usersByKey) {
  await db.collection("wallet_feature_pricing").doc("default").set(
    {
      ...WALLET_PRICING_DEFAULTS,
      live_version: 1,
      updated_by_uid: usersByKey.admin_super_01.uid,
      updated_by_role: "super_admin",
      created_at: timestamp(-24 * 60 * 60_000),
      updated_at: timestamp(),
      is_qa_seed: true,
    },
    { merge: true },
  );
}

function publicOutputUsers(usersByKey) {
  return Object.fromEntries(
    Object.entries(usersByKey).map(([key, value]) => [
      key,
      {
        uid: value.uid,
        email: value.email,
        password: value.password,
        role: value.role,
        venueId: value.venueId,
      },
    ]),
  );
}

function writeOutput(filePath, payload) {
  const resolved = path.resolve(filePath);
  fs.mkdirSync(path.dirname(resolved), { recursive: true });
  fs.writeFileSync(resolved, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
  return resolved;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const projectId = args.projectId || readDefaultProjectId();
  if (!projectId) {
    console.error("Missing Firebase project id. Pass --project=<id>.");
    process.exit(2);
  }

  const emulator = configureEmulatorEnv({ allowLive: args.allowLive });
  process.env.GCLOUD_PROJECT = projectId;
  process.env.GOOGLE_CLOUD_PROJECT = projectId;

  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }

  const auth = admin.auth();
  const db = admin.firestore();
  const seedRunId = `qa_seed_${new Date().toISOString().replace(/[:.]/g, "-")}`;

  const existingUsersByKey = {};
  for (const account of QA_USERS) {
    try {
      existingUsersByKey[account.key] = await auth.getUserByEmail(account.email);
    } catch (error) {
      if (error?.code !== "auth/user-not-found") throw error;
    }
  }

  let resetResult = null;
  if (args.reset) {
    resetResult = {
      firestore: await resetKnownFirestoreDocs(db, existingUsersByKey),
      auth: await deleteKnownAuthUsers(auth),
    };
  }

  const usersByKey = await seedUsersAndRoles(auth, db);
  const [
    venues,
    wallets,
    offers,
    stories,
    menus,
    topups,
    analyticsEvents,
  ] = await Promise.all([
    seedVenues(db, usersByKey),
    seedWallets(db),
    seedOffers(db),
    seedStories(db),
    seedMenus(db),
    seedTopUpRequests(db, usersByKey),
    seedAnalyticsInputs(db),
  ]);
  await seedWalletPricing(db, usersByKey);
  await seedAnalyticsSummaries(db);

  const output = {
    seedRunId,
    projectId,
    mode: emulator.usingEmulators ? "emulator" : "live",
    emulatorHosts: {
      auth: emulator.authHost ?? null,
      firestore: emulator.firestoreHost ?? null,
      functionsBaseUrl: emulator.usingEmulators
        ? `http://127.0.0.1:5001/${projectId}/us-central1`
        : null,
    },
    reset: resetResult,
    accounts: publicOutputUsers(usersByKey),
    seeded: {
      venues,
      wallets,
      offers,
      stories,
      menus,
      topups,
      analyticsEvents,
      pricingDoc: "wallet_feature_pricing/default",
      reversibleEntryAmounts: REVERSIBLE_AMOUNTS,
      outputFile: path.resolve(args.out),
    },
  };

  const outputPath = writeOutput(args.out, output);
  output.seeded.outputFile = outputPath;

  console.log(JSON.stringify(output, null, 2));
}

main().catch((error) => {
  console.error(error?.stack ?? error);
  process.exit(1);
});
