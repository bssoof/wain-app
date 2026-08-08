"use strict";

// Publishes the demo café to Firestore as a normal, visible venue.
//
//   flutter test --no-pub test/tools/export_demo_seed_test.dart
//   node scripts/publish_demo_venue.js --project wain-d2e28
//   node scripts/publish_demo_venue.js --project wain-d2e28 \
//     --confirm-production wain-d2e28 --owner-approved --apply
//
// The seed is produced by the Dart exporter, never typed here: the demo
// catalogs stay the single source of truth, and the merchant dashboard keeps
// reading them after this runs. Two hand-maintained copies of the same café is
// how the venue header came to claim a 4.6 rating while its own reviews
// averaged 3.8.
//
// Guards match publish_verified_ramallah_cafes.js: dry run unless --apply,
// explicit project match, explicit production confirmation, and a refusal to
// run while the Firestore emulator is configured.
//
// What this does NOT do: it publishes documents, it does not remove the demo
// interception in the app. Do that afterwards, once the data is confirmed
// present — removing it first leaves the venue page empty.

const fs = require("node:fs");
const path = require("node:path");

const TARGET_PROJECT_ID = "wain-d2e28";
const EXPECTED_VENUE_ID = "wain-demo-cafe-showcase";
const DEFAULT_SEED_PATH = path.resolve(
  __dirname,
  "..",
  ".tmp",
  "demo_seed.json",
);

function parseArguments(argv) {
  const options = {
    apply: false,
    confirmProduction: "",
    ownerApproved: false,
    linkMerchantUid: "",
    projectId: "",
    seedPath: DEFAULT_SEED_PATH,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === "--apply") {
      options.apply = true;
    } else if (value === "--owner-approved") {
      options.ownerApproved = true;
    } else if (
      value === "--project" ||
      value === "--confirm-production" ||
      value === "--seed" ||
      value === "--link-merchant-uid"
    ) {
      const next = argv[index + 1];
      if (!next) {
        throw new Error(`argument_value_required:${value}`);
      }
      if (value === "--project") options.projectId = next;
      if (value === "--confirm-production") options.confirmProduction = next;
      if (value === "--seed") options.seedPath = path.resolve(next);
      if (value === "--link-merchant-uid") options.linkMerchantUid = next;
      index += 1;
    } else {
      throw new Error(`unknown_argument:${value}`);
    }
  }

  if (options.projectId !== TARGET_PROJECT_ID) {
    throw new Error("production_project_mismatch");
  }
  if (
    options.apply &&
    (!options.ownerApproved || options.confirmProduction !== TARGET_PROJECT_ID)
  ) {
    throw new Error("explicit_production_confirmation_required");
  }
  return options;
}

function assertProductionEnvironment() {
  if (String(process.env.FIRESTORE_EMULATOR_HOST || "").trim()) {
    throw new Error("firestore_emulator_must_be_disabled");
  }
}

function readSeed(seedPath) {
  if (!fs.existsSync(seedPath)) {
    throw new Error(`seed_not_found:${seedPath}`);
  }

  const seed = JSON.parse(fs.readFileSync(seedPath, "utf8"));

  // The seed is generated, so a mismatch here means it was hand-edited or is
  // stale — either way it must not reach production unnoticed.
  if (seed.venue_id !== EXPECTED_VENUE_ID) {
    throw new Error(`unexpected_venue_id:${seed.venue_id}`);
  }
  for (const key of ["venue", "offers", "stories", "reviews", "menu"]) {
    if (!seed[key]) throw new Error(`seed_missing_section:${key}`);
  }
  if (!Array.isArray(seed.venue.photos) || seed.venue.photos.length === 0) {
    throw new Error("seed_missing_photos");
  }

  return seed;
}

const ISO_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/;

/// The exporter writes timestamps as ISO strings so the seed stays plain JSON.
/// They become real Firestore Timestamps here, walking the tree rather than
/// naming fields so a field added to an entity later is converted too.
function reviveTimestamps(admin, value) {
  if (typeof value === "string" && ISO_PATTERN.test(value)) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return admin.firestore.Timestamp.fromDate(parsed);
    }
  }
  if (Array.isArray(value)) {
    return value.map((entry) => reviveTimestamps(admin, entry));
  }
  if (value && typeof value === "object") {
    const out = {};
    for (const [key, entry] of Object.entries(value)) {
      out[key] = reviveTimestamps(admin, entry);
    }
    return out;
  }
  return value;
}

/// Refuses a credential that belongs to some other project.
///
/// GOOGLE_APPLICATION_CREDENTIALS is ambient — it may well be pointing at an
/// unrelated project's service account, as it was here. Forcing projectId at
/// init means such a credential cannot write anywhere else, but it fails with a
/// bare PERMISSION_DENIED that says nothing about why. Checking the file says
/// why.
function assertCredentialMatchesProject(credentialPath, projectId) {
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(credentialPath, "utf8"));
  } catch {
    throw new Error(`credential_unreadable:${credentialPath}`);
  }

  // Only service-account keys carry a project_id. User ADC does not, and is
  // scoped by the account rather than the file, so it is left to Google to
  // accept or refuse.
  if (parsed.type === "service_account" && parsed.project_id !== projectId) {
    throw new Error(
      `credential_project_mismatch:${parsed.project_id}:expected:${projectId}`,
    );
  }
}

function resolveCredentialPath(rootDir, projectId) {
  const configured = String(
    process.env.GOOGLE_APPLICATION_CREDENTIALS || "",
  ).trim();
  if (configured) {
    assertCredentialMatchesProject(configured, projectId);
    return configured;
  }

  const fallback = path.join(rootDir, ".tmp", "service-account.json");
  if (fs.existsSync(fallback)) {
    assertCredentialMatchesProject(fallback, projectId);
    return fallback;
  }

  // No key file. Fall through to whatever `applicationDefault()` finds —
  // typically a gcloud user login. That is scoped by the account rather than by
  // a file, so Google decides whether it may touch this project; returning null
  // just means "do not pin a file".
  return null;
}

async function createFirestore(rootDir, projectId) {
  assertProductionEnvironment();
  const credentialPath = resolveCredentialPath(rootDir, projectId);
  if (credentialPath) {
    process.env.GOOGLE_APPLICATION_CREDENTIALS = credentialPath;
  } else {
    delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
  }
  const admin = require(
    path.join(rootDir, "functions", "node_modules", "firebase-admin"),
  );
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
  }
  return { admin, db: admin.firestore() };
}

/// Every document this run would touch, as {ref, data} pairs.
///
/// Built before anything is written so the dry run reports exactly what the
/// apply would do, rather than a summary of it.
function planWrites(admin, db, seed) {
  const venueId = seed.venue_id;
  const now = admin.firestore.FieldValue.serverTimestamp();
  const writes = [];

  writes.push({
    label: `venues/${venueId}`,
    ref: db.collection("venues").doc(venueId),
    data: {
      ...reviveTimestamps(admin, seed.venue),
      created_at: now,
      updated_at: now,
    },
  });

  for (const offer of seed.offers) {
    const { id, ...data } = offer;
    writes.push({
      label: `offers/${id}`,
      ref: db.collection("offers").doc(id),
      data: { ...reviveTimestamps(admin, data), updated_at: now },
    });
  }

  for (const story of seed.stories) {
    const { id, ...data } = story;
    writes.push({
      label: `stories/${id}`,
      ref: db.collection("stories").doc(id),
      data: reviveTimestamps(admin, data),
    });
  }

  for (const review of seed.reviews) {
    const { id, ...data } = review;
    writes.push({
      label: `venues/${venueId}/reviews/${id}`,
      ref: db.collection("venues").doc(venueId).collection("reviews").doc(id),
      data: reviveTimestamps(admin, data),
    });
  }

  for (const section of seed.menu.sections) {
    writes.push({
      label: `venues/${venueId}/menu_sections/${section.id}`,
      ref: db
        .collection("venues")
        .doc(venueId)
        .collection("menu_sections")
        .doc(section.id),
      data: reviveTimestamps(admin, section),
    });
  }

  for (const item of seed.menu.items) {
    const { id, ...data } = item;
    writes.push({
      label: `venues/${venueId}/menu_items/${id}`,
      ref: db
        .collection("venues")
        .doc(venueId)
        .collection("menu_items")
        .doc(id),
      data: { ...reviveTimestamps(admin, data), venue_id: venueId },
    });
  }

  const m = seed.merchant;
  if (m) {
    const wallet = db.collection("merchant_wallets").doc(venueId);
    writes.push({
      label: `merchant_wallets/${venueId}`,
      ref: wallet,
      data: reviveTimestamps(admin, m.wallet),
    });
    for (const entry of m.wallet_entries) {
      const { id, ...data } = entry;
      writes.push({
        label: `merchant_wallets/${venueId}/entries/${id}`,
        ref: wallet.collection("entries").doc(id),
        data: reviveTimestamps(admin, data),
      });
    }
    writes.push({
      label: `merchant_wallet_reports/${venueId}`,
      ref: db.collection("merchant_wallet_reports").doc(venueId),
      data: reviveTimestamps(admin, m.wallet_report),
    });
    for (const request of m.topup_requests) {
      const { id, ...data } = request;
      writes.push({
        label: `merchant_topup_requests/${id}`,
        ref: db.collection("merchant_topup_requests").doc(id),
        data: reviveTimestamps(admin, data),
      });
    }
    writes.push({
      label: `venue_analytics/${venueId}`,
      ref: db.collection("venue_analytics").doc(venueId),
      data: reviveTimestamps(admin, m.analytics),
    });
    for (const point of m.analytics_daily) {
      const { id, ...data } = point;
      writes.push({
        label: `venue_analytics_daily/${venueId}/days/${id}`,
        ref: db
          .collection("venue_analytics_daily")
          .doc(venueId)
          .collection("days")
          .doc(id),
        data: reviveTimestamps(admin, data),
      });
    }
    for (const row of m.offer_analytics) {
      const { id, ...data } = row;
      writes.push({
        label: `venue_offer_analytics/${venueId}/offers/${id}`,
        ref: db
          .collection("venue_offer_analytics")
          .doc(venueId)
          .collection("offers")
          .doc(id),
        data: reviveTimestamps(admin, data),
      });
    }
  }

  return writes;
}

/// Links a real account to the venue, so the merchant dashboard is reachable
/// through the normal profile route rather than only through /demo/merchant.
///
/// One field, merged, on a document the app already owns. Note what it does NOT
/// bring: the dashboard then takes the production path and reads Firestore,
/// where this venue has no traffic, so analytics, the funnel and the wallet stay
/// empty until those collections are published too.
function planMerchantLink(db, uid, venueId) {
  return {
    label: `users/${uid}`,
    ref: db.collection("users").doc(uid),
    data: { merchant_venue_id: venueId },
  };
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const rootDir = path.resolve(__dirname, "..");
  const seed = readSeed(options.seedPath);
  const { admin, db } = await createFirestore(rootDir, options.projectId);

  const writes = planWrites(admin, db, seed);
  if (options.linkMerchantUid) {
    writes.push(planMerchantLink(db, options.linkMerchantUid, seed.venue_id));
  }
  const snapshots = await db.getAll(...writes.map((write) => write.ref));
  const existing = snapshots
    .map((snapshot, index) => (snapshot.exists ? writes[index].label : null))
    .filter(Boolean);

  const plan = {
    mode: options.apply ? "production-apply" : "production-dry-run",
    project_id: options.projectId,
    venue_id: seed.venue_id,
    visibility_status: seed.venue.visibility_status,
    documents: writes.length,
    already_present: existing.length,
    existing_labels: existing,
    labels: writes.map((write) => write.label),
  };

  if (!options.apply) {
    console.log(JSON.stringify({ ...plan, applied: false }, null, 2));
    console.error(
      "Dry run. Re-run with --confirm-production wain-d2e28 --owner-approved --apply to write.",
    );
    return;
  }

  // merge: true so a re-run updates rather than wiping fields something else
  // added, and so the script is safe to run twice.
  const batch = db.batch();
  for (const write of writes) {
    batch.set(write.ref, write.data, { merge: true });
  }
  await batch.commit();

  console.log(JSON.stringify({ ...plan, applied: true }, null, 2));
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
  });
}

module.exports = {
  EXPECTED_VENUE_ID,
  assertCredentialMatchesProject,
  planMerchantLink,
  TARGET_PROJECT_ID,
  assertProductionEnvironment,
  parseArguments,
  planWrites,
  readSeed,
  reviveTimestamps,
};
