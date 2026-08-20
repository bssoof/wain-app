"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  TARGET_PROJECT_ID,
  assertProductionEnvironment,
  buildProductionVenueDocument,
  parseArguments,
  selectVerifiedVenues,
} = require("./publish_verified_ramallah_cafes");

function venue(placeId) {
  return {
    name_ar: `مقهى ${placeId}`,
    name_en: `Cafe ${placeId}`,
    city_key: "ramallah",
    categories: ["cafe"],
    google_place_id: placeId,
    lat: 31.9,
    lng: 35.2,
  };
}

function review(placeId, overrides = {}) {
  return {
    google_place_id: placeId,
    identity_confidence: "high",
    identity_status: "verified",
    safe_fields: ["name", "category", "old_city_location"],
    ...overrides,
  };
}

test("requires the exact production project", () => {
  assert.throws(() => parseArguments([]), /production_project_mismatch/);
  assert.throws(
    () => parseArguments(["--project", "another-project"]),
    /production_project_mismatch/,
  );
});

test("requires owner and project confirmation before apply", () => {
  assert.throws(
    () => parseArguments(["--project", TARGET_PROJECT_ID, "--apply"]),
    /explicit_production_confirmation_required/,
  );
  const options = parseArguments([
    "--project",
    TARGET_PROJECT_ID,
    "--apply",
    "--owner-approved",
    "--confirm-production",
    TARGET_PROJECT_ID,
  ]);
  assert.equal(options.apply, true);
  assert.equal(options.ownerApproved, true);
});

test("selects high-confidence venues with an exact verified location", () => {
  const draft = { venues: [venue("a"), venue("b"), venue("c")] };
  const verification = {
    venues: [
      review("a"),
      review("b", { identity_status: "verified_contact_conflict" }),
      review("c", { safe_fields: ["name", "category", "ramallah_presence"] }),
    ],
  };
  const selected = selectVerifiedVenues(draft, verification, 2);
  assert.deepEqual(selected.map(({ venue: item }) => item.google_place_id), ["a", "b"]);
});

test("production documents exclude unapproved mutable Google fields", () => {
  const now = new Date("2026-08-01T00:00:00.000Z");
  const document = buildProductionVenueDocument(venue("a"), review("a"), now);
  assert.equal(document.preview_only, false);
  assert.equal(document.verification_status, "verified_minimal");
  assert.equal(document.phone, "");
  assert.equal(document.rating, 0);
  assert.deepEqual(document.photos, []);
  assert.deepEqual(document.hours, {});
  assert.equal(document.visibility_status, "visible");
  assert.equal(document.operational_status, "active");
});

test("refuses to run against an emulator", () => {
  const previous = process.env.FIRESTORE_EMULATOR_HOST;
  try {
    process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
    assert.throws(assertProductionEnvironment, /firestore_emulator_must_be_disabled/);
    delete process.env.FIRESTORE_EMULATOR_HOST;
    assert.doesNotThrow(assertProductionEnvironment);
  } finally {
    if (previous === undefined) {
      delete process.env.FIRESTORE_EMULATOR_HOST;
    } else {
      process.env.FIRESTORE_EMULATOR_HOST = previous;
    }
  }
});
