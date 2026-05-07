const test = require("node:test");
const assert = require("node:assert/strict");

const {
  validateAndScopeInputFiles,
} = require("../lib/menu_import.js");

const bucketName = "demo-wain.firebasestorage.app";

function validUri(venueId, fileName = "menu_import_a.jpg") {
  return `gs://${bucketName}/venues/${venueId}/photos/${fileName}`;
}

async function expectInvalid(action, pattern) {
  let caught = null;
  try {
    await action();
  } catch (error) {
    caught = error;
  }

  assert.ok(caught, "Expected inputFiles validation to fail.");
  assert.equal(caught.code, "invalid-argument");
  if (pattern) {
    assert.match(caught.message, pattern);
  }
}

test("menu import inputFiles allows an empty array", () => {
  assert.deepEqual(validateAndScopeInputFiles([], "venue-a", bucketName), []);
});

test("menu import inputFiles allows caller venue menu_import photo prefix", () => {
  assert.deepEqual(
    validateAndScopeInputFiles([validUri("venue-a")], "venue-a", bucketName),
    [validUri("venue-a")],
  );
});

test("menu import inputFiles denies cross-venue gs:// URIs", async () => {
  await expectInvalid(
    () => validateAndScopeInputFiles([validUri("venue-b")], "venue-a", bucketName),
    /venue menu import photo prefix/,
  );
});

test("menu import inputFiles denies wrong storage buckets", async () => {
  await expectInvalid(
    () =>
      validateAndScopeInputFiles(
        ["gs://other-bucket/venues/venue-a/photos/menu_import_a.jpg"],
        "venue-a",
        bucketName,
      ),
    /configured storage bucket/,
  );
});

test("menu import inputFiles denies non-gs schemes", async () => {
  await expectInvalid(
    () => validateAndScopeInputFiles(["https://example.com/x.jpg"], "venue-a", bucketName),
    /gs:\/\//,
  );
});

test("menu import inputFiles denies more than 20 files", async () => {
  const files = Array.from({ length: 21 }, (_, index) =>
    validUri("venue-a", `menu_import_${index}.jpg`),
  );

  await expectInvalid(
    () => validateAndScopeInputFiles(files, "venue-a", bucketName),
    /more than 20/,
  );
});

test("menu import inputFiles denies duplicate URIs", async () => {
  const uri = validUri("venue-a");
  await expectInvalid(
    () => validateAndScopeInputFiles([uri, uri], "venue-a", bucketName),
    /duplicate/,
  );
});
