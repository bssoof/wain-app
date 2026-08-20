"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const {
  buildVenueDocument,
  makeVenueId,
  readDraft,
} = require("./seed_ramallah_cafe_preview");

const TARGET_PROJECT_ID = "wain-d2e28";
const EXPECTED_BATCH_SIZE = 12;
const DEFAULT_DRAFT_PATH = path.resolve(
  __dirname,
  "..",
  ".tmp",
  "ramallah_cafes_import_draft_2026-08-01.json",
);
const DEFAULT_VERIFICATION_PATH = path.resolve(
  __dirname,
  "..",
  ".tmp",
  "ramallah_cafes_verification_2026-08-01.json",
);

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function parseArguments(argv) {
  const options = {
    apply: false,
    confirmProduction: "",
    draftPath: DEFAULT_DRAFT_PATH,
    ownerApproved: false,
    projectId: "",
    verificationPath: DEFAULT_VERIFICATION_PATH,
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
      value === "--input" ||
      value === "--verification"
    ) {
      const next = argv[index + 1];
      if (!next) {
        throw new Error(`argument_value_required:${value}`);
      }
      if (value === "--project") options.projectId = next;
      if (value === "--confirm-production") options.confirmProduction = next;
      if (value === "--input") options.draftPath = path.resolve(next);
      if (value === "--verification") {
        options.verificationPath = path.resolve(next);
      }
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

function hasVerifiedLocation(safeFields) {
  return safeFields.some((field) => field.endsWith("_location"));
}

function isEligibleVenue(venue, review) {
  const safeFields = Array.isArray(review.safe_fields) ? review.safe_fields : [];
  return (
    review.identity_confidence === "high" &&
    String(review.identity_status || "").startsWith("verified") &&
    safeFields.includes("name") &&
    safeFields.includes("category") &&
    hasVerifiedLocation(safeFields) &&
    venue?.google_place_id === review.google_place_id &&
    venue.city_key === "ramallah" &&
    venue.categories?.length === 1 &&
    venue.categories[0] === "cafe" &&
    Number.isFinite(venue.lat) &&
    Number.isFinite(venue.lng)
  );
}

function selectVerifiedVenues(draft, verification, expectedCount) {
  const draftByPlaceId = new Map(
    draft.venues.map((venue) => [venue.google_place_id, venue]),
  );
  const selected = verification.venues
    .map((review) => ({
      review,
      venue: draftByPlaceId.get(review.google_place_id),
    }))
    .filter(({ review, venue }) => isEligibleVenue(venue, review));

  if (selected.length !== expectedCount) {
    throw new Error(
      `verified_batch_size_mismatch:${selected.length}:${expectedCount}`,
    );
  }
  return selected;
}

function buildProductionVenueDocument(venue, review, now) {
  const preview = buildVenueDocument(venue, now);
  return {
    ...preview,
    phone: "",
    photos: [],
    hours: {},
    rating: 0,
    preview_only: false,
    verification_status: "verified_minimal",
    verified_fields: review.safe_fields.filter(
      (field) => field === "name" || field === "category" || field.endsWith("_location"),
    ),
    verified_on: "2026-08-01",
  };
}

function resolveCredentialPath(rootDir) {
  const candidates = [
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.join(rootDir, "service-account-key.json"),
    path.join(rootDir, "scripts", "serviceAccountKey.json"),
  ].filter(Boolean);
  const credentialPath = candidates.find((candidate) => fs.existsSync(candidate));
  if (!credentialPath) {
    throw new Error("service_account_path_missing");
  }
  return credentialPath;
}

function assertProductionEnvironment() {
  if (String(process.env.FIRESTORE_EMULATOR_HOST || "").trim()) {
    throw new Error("firestore_emulator_must_be_disabled");
  }
}

async function createFirestore(rootDir, projectId) {
  assertProductionEnvironment();
  process.env.GOOGLE_APPLICATION_CREDENTIALS = resolveCredentialPath(rootDir);
  const admin = require(path.join(rootDir, "functions", "node_modules", "firebase-admin"));
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
  }
  return { admin, db: admin.firestore() };
}

function payloadHash(selected) {
  const payload = selected.map(({ review, venue }) => ({
    google_place_id: venue.google_place_id,
    identity_status: review.identity_status,
    lat: venue.lat,
    lng: venue.lng,
    name_ar: venue.name_ar,
    name_en: venue.name_en,
  }));
  return crypto.createHash("sha256").update(JSON.stringify(payload)).digest("hex");
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const rootDir = path.resolve(__dirname, "..");
  const draft = readDraft(options.draftPath);
  const verification = readJson(options.verificationPath);
  const selected = selectVerifiedVenues(
    draft,
    verification,
    EXPECTED_BATCH_SIZE,
  );
  const { admin, db } = await createFirestore(rootDir, options.projectId);
  const refs = selected.map(({ venue }) =>
    db.collection("venues").doc(makeVenueId(venue.google_place_id)),
  );
  const snapshots = await db.getAll(...refs);
  const existingIds = snapshots.filter((snapshot) => snapshot.exists).map((snapshot) => snapshot.id);
  const targetIds = refs.map((ref) => ref.id);

  const preflight = {
    mode: options.apply ? "production-apply" : "production-dry-run",
    project_id: options.projectId,
    selected: selected.length,
    existing: existingIds.length,
    to_create: selected.length - existingIds.length,
    target_ids: targetIds,
    existing_ids: existingIds,
    payload_sha256: payloadHash(selected),
  };
  console.log(JSON.stringify(preflight, null, 2));

  if (!options.apply) return;
  if (existingIds.length > 0) {
    throw new Error("target_document_already_exists");
  }

  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();
  selected.forEach(({ review, venue }, index) => {
    batch.create(refs[index], buildProductionVenueDocument(venue, review, now));
  });
  await batch.commit();

  const verifiedSnapshots = await db.getAll(...refs);
  const invalid = verifiedSnapshots.filter((snapshot, index) => {
    const data = snapshot.data() || {};
    return (
      !snapshot.exists ||
      data.preview_only !== false ||
      data.visibility_status !== "visible" ||
      data.operational_status !== "active" ||
      data.external_source?.place_id !== selected[index].venue.google_place_id
    );
  });
  if (invalid.length > 0) {
    throw new Error(`post_write_verification_failed:${invalid.length}`);
  }

  console.log(JSON.stringify({
    mode: "production-verified",
    project_id: options.projectId,
    written: verifiedSnapshots.length,
    verified_ids: verifiedSnapshots.map((snapshot) => snapshot.id),
    payload_sha256: payloadHash(selected),
  }, null, 2));
}

module.exports = {
  EXPECTED_BATCH_SIZE,
  TARGET_PROJECT_ID,
  assertProductionEnvironment,
  buildProductionVenueDocument,
  hasVerifiedLocation,
  isEligibleVenue,
  parseArguments,
  payloadHash,
  selectVerifiedVenues,
};

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
