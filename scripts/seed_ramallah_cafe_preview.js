"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const DEFAULT_INPUT = path.resolve(
  __dirname,
  "..",
  ".tmp",
  "ramallah_cafes_import_draft_2026-08-01.json",
);

function makeVenueId(googlePlaceId) {
  return `ramallah-cafe-${crypto
    .createHash("sha256")
    .update(googlePlaceId)
    .digest("hex")
    .slice(0, 20)}`;
}

function readDraft(inputPath) {
  const parsed = JSON.parse(fs.readFileSync(inputPath, "utf8"));
  return validateDraft(parsed);
}

function validateDraft(parsed) {
  const venues = Array.isArray(parsed.venues) ? parsed.venues : [];
  if (parsed.firebase_write_allowed !== false || parsed.publish_allowed !== false) {
    throw new Error("draft_safety_flags_invalid");
  }
  if (venues.length === 0) {
    throw new Error("draft_has_no_venues");
  }

  const placeIds = new Set();
  for (const venue of venues) {
    if (
      typeof venue.name_ar !== "string" ||
      venue.name_ar.trim() === "" ||
      typeof venue.google_place_id !== "string" ||
      venue.google_place_id.trim() === "" ||
      venue.city_key !== "ramallah" ||
      !Array.isArray(venue.categories) ||
      venue.categories.length !== 1 ||
      venue.categories[0] !== "cafe" ||
      !Number.isFinite(venue.lat) ||
      !Number.isFinite(venue.lng)
    ) {
      throw new Error("draft_venue_invalid");
    }
    if (placeIds.has(venue.google_place_id)) {
      throw new Error("draft_place_id_duplicate");
    }
    placeIds.add(venue.google_place_id);
  }

  return { ...parsed, venues };
}

function buildVenueDocument(venue, now) {
  const nameAr = venue.name_ar.trim();
  const nameEn = String(venue.name_en || "").trim();
  return {
    name_ar: nameAr,
    name_en: nameEn,
    name: nameAr,
    name_ar_norm: nameAr.toLowerCase(),
    name_en_norm: nameEn.toLowerCase(),
    lat: venue.lat,
    lng: venue.lng,
    city: "رام الله",
    city_key: "ramallah",
    categories: ["cafe"],
    tags: {
      mood: [],
      occasion: [],
      timeOfDay: [],
      meal: [],
    },
    all_tags: [],
    min_price: 0,
    max_price: 0,
    currency: "ILS",
    rating: 0,
    phone: "",
    instagram: "",
    whatsapp: "",
    facebook: "",
    website: "",
    photos: [],
    menu_images: [],
    hours: {},
    is_24h: false,
    partner: {
      is_partner: false,
      tier: "C",
    },
    has_active_offers: false,
    transport_enabled: false,
    transport_partner_ids: [],
    transport_notes_ar: "",
    transport_notes_en: "",
    is_active: true,
    subscription_status: "active",
    visibility_status: "visible",
    operational_status: "active",
    preview_only: true,
    verification_status: "needs_manual_review",
    external_source: {
      provider: "google_places",
      place_id: venue.google_place_id,
      observed_on: "2026-08-01",
    },
    created_at: now,
    updated_at: now,
  };
}

function parseArguments(argv) {
  const options = {
    confirmEmulator: false,
    dryRun: false,
    inputPath: DEFAULT_INPUT,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === "--confirm-emulator") {
      options.confirmEmulator = true;
    } else if (value === "--dry-run") {
      options.dryRun = true;
    } else if (value === "--input") {
      const next = argv[index + 1];
      if (!next) {
        throw new Error("input_path_required");
      }
      options.inputPath = path.resolve(next);
      index += 1;
    } else {
      throw new Error(`unknown_argument:${value}`);
    }
  }
  return options;
}

function requireLocalEmulator(confirmEmulator) {
  const host = String(process.env.FIRESTORE_EMULATOR_HOST || "").trim();
  const localHost = /^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(host);
  if (!confirmEmulator || !localHost) {
    throw new Error("local_firestore_emulator_required");
  }
  return host;
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const draft = readDraft(options.inputPath);
  const payloadHash = crypto
    .createHash("sha256")
    .update(JSON.stringify(draft.venues))
    .digest("hex");

  if (options.dryRun) {
    console.log(JSON.stringify({
      mode: "dry-run",
      venues: draft.venues.length,
      payload_sha256: payloadHash,
      firebase_writes: 0,
    }, null, 2));
    return;
  }

  const emulatorHost = requireLocalEmulator(options.confirmEmulator);
  const admin = require(path.resolve(
    __dirname,
    "..",
    "functions",
    "node_modules",
    "firebase-admin",
  ));
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: "demo-wain-ramallah" });
  }

  const db = admin.firestore();
  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();
  const ids = [];
  for (const venue of draft.venues) {
    const venueId = makeVenueId(venue.google_place_id);
    ids.push(venueId);
    batch.set(
      db.collection("venues").doc(venueId),
      buildVenueDocument(venue, now),
      { merge: false },
    );
  }
  await batch.commit();

  console.log(JSON.stringify({
    mode: "emulator-preview",
    emulator_host: emulatorHost,
    venues_written: ids.length,
    venue_ids: ids,
    payload_sha256: payloadHash,
  }, null, 2));
}

module.exports = {
  buildVenueDocument,
  makeVenueId,
  parseArguments,
  readDraft,
  requireLocalEmulator,
  validateDraft,
};

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
