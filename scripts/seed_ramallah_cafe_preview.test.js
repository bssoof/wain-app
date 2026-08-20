"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  EMULATOR_PROJECT_ID,
  buildVenueDocument,
  makeVenueId,
  parseArguments,
  requireLocalEmulator,
  validateDraft,
} = require("./seed_ramallah_cafe_preview");

test("uses the same emulator project namespace as the app", () => {
  assert.equal(EMULATOR_PROJECT_ID, "wain-d2e28");
});

function sampleDraft() {
  return {
    firebase_write_allowed: false,
    publish_allowed: false,
    venues: [
      {
        name_ar: "كافيه ألفا",
        name_en: "Cafe Alpha",
        city_key: "ramallah",
        categories: ["cafe"],
        google_place_id: "place-alpha",
        lat: 31.9,
        lng: 35.2,
      },
      {
        name_ar: "كافيه بيتا",
        name_en: "Cafe Beta",
        city_key: "ramallah",
        categories: ["cafe"],
        google_place_id: "place-beta",
        lat: 31.91,
        lng: 35.21,
      },
    ],
  };
}

test("validates a reviewed venue draft without duplicates", () => {
  const draft = validateDraft(sampleDraft());
  assert.equal(draft.venues.length, 2);
  assert.equal(new Set(draft.venues.map((venue) => venue.google_place_id)).size, 2);
});

test("builds a visible emulator-only preview document", () => {
  const venue = validateDraft(sampleDraft()).venues[0];
  const now = new Date("2026-08-01T00:00:00.000Z");
  const document = buildVenueDocument(venue, now);
  assert.equal(document.city_key, "ramallah");
  assert.deepEqual(document.categories, ["cafe"]);
  assert.equal(document.preview_only, true);
  assert.equal(document.verification_status, "needs_manual_review");
  assert.equal(document.visibility_status, "visible");
  assert.equal(document.created_at, now);
});

test("uses stable unique document identifiers", () => {
  const draft = validateDraft(sampleDraft());
  const firstPass = draft.venues.map((venue) => makeVenueId(venue.google_place_id));
  const secondPass = draft.venues.map((venue) => makeVenueId(venue.google_place_id));
  assert.deepEqual(firstPass, secondPass);
  assert.equal(new Set(firstPass).size, 2);
});

test("requires an explicit local emulator confirmation", () => {
  const previous = process.env.FIRESTORE_EMULATOR_HOST;
  try {
    process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
    assert.equal(requireLocalEmulator(true), "127.0.0.1:8080");
    assert.throws(() => requireLocalEmulator(false), /local_firestore_emulator_required/);
    process.env.FIRESTORE_EMULATOR_HOST = "firestore.googleapis.com:443";
    assert.throws(() => requireLocalEmulator(true), /local_firestore_emulator_required/);
  } finally {
    if (previous === undefined) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = previous;
    }
  }
});

test("parses dry-run arguments without enabling writes", () => {
  const inputPath = "C:\\review\\ramallah-cafes.json";
  const options = parseArguments(["--dry-run", "--input", inputPath]);
  assert.equal(options.dryRun, true);
  assert.equal(options.confirmEmulator, false);
  assert.equal(options.inputPath, inputPath);
});
