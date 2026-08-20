"use strict";

// node --test scripts/publish_demo_venue.test.js

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  EXPECTED_VENUE_ID,
  TARGET_PROJECT_ID,
  assertProductionEnvironment,
  parseArguments,
  readSeed,
  reviveTimestamps,
} = require("./publish_demo_venue");

function writeSeed(seed) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "wain-seed-"));
  const file = path.join(dir, "demo_seed.json");
  fs.writeFileSync(file, JSON.stringify(seed), "utf8");
  return file;
}

function validSeed(overrides = {}) {
  return {
    venue_id: EXPECTED_VENUE_ID,
    venue: { photos: ["asset://a.jpg"], visibility_status: "visible" },
    offers: [],
    stories: [],
    reviews: [],
    menu: { sections: [], items: [] },
    ...overrides,
  };
}

test("dry run is the default", () => {
  const options = parseArguments(["--project", TARGET_PROJECT_ID]);
  assert.equal(options.apply, false);
});

test("the project must be named and must match", () => {
  assert.throws(() => parseArguments([]), /production_project_mismatch/);
  assert.throws(
    () => parseArguments(["--project", "some-other-project"]),
    /production_project_mismatch/,
  );
});

test("applying needs both the confirmation and the owner flag", () => {
  const base = ["--project", TARGET_PROJECT_ID, "--apply"];
  assert.throws(
    () => parseArguments(base),
    /explicit_production_confirmation_required/,
  );
  assert.throws(
    () => parseArguments([...base, "--owner-approved"]),
    /explicit_production_confirmation_required/,
  );
  assert.throws(
    () => parseArguments([...base, "--confirm-production", "wrong-project"]),
    /explicit_production_confirmation_required/,
  );

  const ok = parseArguments([
    ...base,
    "--owner-approved",
    "--confirm-production",
    TARGET_PROJECT_ID,
  ]);
  assert.equal(ok.apply, true);
});

test("an unknown argument is refused rather than ignored", () => {
  assert.throws(
    () => parseArguments(["--project", TARGET_PROJECT_ID, "--force"]),
    /unknown_argument/,
  );
});

test("it refuses to run against the emulator", () => {
  const previous = process.env.FIRESTORE_EMULATOR_HOST;
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
  try {
    assert.throws(
      () => assertProductionEnvironment(),
      /firestore_emulator_must_be_disabled/,
    );
  } finally {
    if (previous === undefined) delete process.env.FIRESTORE_EMULATOR_HOST;
    else process.env.FIRESTORE_EMULATOR_HOST = previous;
  }
});

test("a seed for the wrong venue is refused", () => {
  // The seed is generated, so this can only mean it was hand-edited or is
  // stale — neither should reach production quietly.
  const file = writeSeed(validSeed({ venue_id: "some-real-venue" }));
  assert.throws(() => readSeed(file), /unexpected_venue_id/);
});

test("an incomplete seed is refused", () => {
  const missingSection = validSeed();
  delete missingSection.reviews;
  assert.throws(
    () => readSeed(writeSeed(missingSection)),
    /seed_missing_section:reviews/,
  );

  const noPhotos = validSeed({ venue: { photos: [] } });
  assert.throws(() => readSeed(writeSeed(noPhotos)), /seed_missing_photos/);
});

test("a missing seed file names itself", () => {
  assert.throws(() => readSeed("/no/such/seed.json"), /seed_not_found/);
});

test("a valid seed reads back", () => {
  const seed = readSeed(writeSeed(validSeed()));
  assert.equal(seed.venue_id, EXPECTED_VENUE_ID);
});

test("ISO strings become Timestamps, anywhere in the tree", () => {
  const calls = [];
  const admin = {
    firestore: {
      Timestamp: {
        fromDate: (date) => {
          calls.push(date.toISOString());
          return { __timestamp: date.toISOString() };
        },
      },
    },
  };

  const revived = reviveTimestamps(admin, {
    created_at: "2026-07-01T08:00:00.000Z",
    text: "not a date",
    count: 3,
    nested: [{ expires_at: "2099-01-01T00:00:00.000Z" }],
  });

  assert.equal(revived.text, "not a date");
  assert.equal(revived.count, 3);
  assert.equal(revived.created_at.__timestamp, "2026-07-01T08:00:00.000Z");
  assert.equal(
    revived.nested[0].expires_at.__timestamp,
    "2099-01-01T00:00:00.000Z",
  );
  assert.equal(calls.length, 2);
});
