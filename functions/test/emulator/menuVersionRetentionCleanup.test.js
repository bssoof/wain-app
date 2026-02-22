const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-analytics";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  runMenuVersionRetentionCleanup,
} = require("../../scripts/cleanup_menu_versions_retention.js");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

function tsDaysAgo(daysAgo) {
  return admin.firestore.Timestamp.fromMillis(Date.now() - (daysAgo * 24 * 60 * 60 * 1000));
}

async function seedVersionTree(venueRef, versionId, status, daysAgo) {
  const versionRef = venueRef.collection("menu_versions").doc(versionId);
  await versionRef.set({
    status,
    source: "test_seed",
    created_at: tsDaysAgo(daysAgo + 1),
    updated_at: tsDaysAgo(daysAgo),
    published_at: tsDaysAgo(daysAgo),
  });
  await versionRef.collection("categories").doc("cat_1").set({
    key: "test_category",
    name_ar: "فئة اختبار",
    sort_order: 1,
  });
  await versionRef.collection("items").doc("item_1").set({
    name_ar: `Item ${versionId}`,
    category: "cat_1",
    sort_order: 1,
  });
}

test.before(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("menu retention cleanup: keeps active/draft/latest5 archived and deletes older", async () => {
  await clearFirestore();

  const venueId = "venue-retention-1";
  const venueRef = db.collection("venues").doc(venueId);
  await venueRef.set({
    active_menu_version_id: "v_active",
  });
  await venueRef.collection("menu_config").doc("main").set({
    draft_version_id: "v_draft",
  });

  await seedVersionTree(venueRef, "v_active", "active", 0);
  await seedVersionTree(venueRef, "v_draft", "draft", 0);

  const archivedIds = [
    "v_arch_01",
    "v_arch_02",
    "v_arch_03",
    "v_arch_04",
    "v_arch_05",
    "v_arch_06",
    "v_arch_07",
    "v_arch_08",
  ];

  for (let i = 0; i < archivedIds.length; i += 1) {
    await seedVersionTree(venueRef, archivedIds[i], "archived", i + 1);
  }

  const firstRun = await runMenuVersionRetentionCleanup({
    db,
    venueId,
    keepArchived: 5,
    retentionDays: 30,
    dryRun: false,
  });

  assert.equal(firstRun.deletedVersions, 3);
  assert.equal(firstRun.deletedItemsCount, 3);
  assert.equal(firstRun.deletedCategoriesCount, 3);

  const versionsSnap = await venueRef.collection("menu_versions").get();
  const remainingIds = new Set(versionsSnap.docs.map((doc) => doc.id));

  assert.equal(remainingIds.has("v_active"), true);
  assert.equal(remainingIds.has("v_draft"), true);
  assert.equal(remainingIds.has("v_arch_01"), true);
  assert.equal(remainingIds.has("v_arch_02"), true);
  assert.equal(remainingIds.has("v_arch_03"), true);
  assert.equal(remainingIds.has("v_arch_04"), true);
  assert.equal(remainingIds.has("v_arch_05"), true);
  assert.equal(remainingIds.has("v_arch_06"), false);
  assert.equal(remainingIds.has("v_arch_07"), false);
  assert.equal(remainingIds.has("v_arch_08"), false);

  const deletedItemSnap = await venueRef
    .collection("menu_versions")
    .doc("v_arch_08")
    .collection("items")
    .doc("item_1")
    .get();
  assert.equal(deletedItemSnap.exists, false);

  const secondRun = await runMenuVersionRetentionCleanup({
    db,
    venueId,
    keepArchived: 5,
    retentionDays: 30,
    dryRun: false,
  });
  assert.equal(secondRun.deletedVersions, 0);
  assert.equal(secondRun.deletedItemsCount, 0);
  assert.equal(secondRun.deletedCategoriesCount, 0);
});

test("menu retention cleanup: dry-run reports deletes without mutating data", async () => {
  await clearFirestore();

  const venueId = "venue-retention-2";
  const venueRef = db.collection("venues").doc(venueId);
  await venueRef.set({ active_menu_version_id: "v_active" });
  await venueRef.collection("menu_config").doc("main").set({ draft_version_id: "v_draft" });

  await seedVersionTree(venueRef, "v_active", "active", 0);
  await seedVersionTree(venueRef, "v_draft", "draft", 0);
  await seedVersionTree(venueRef, "v_arch_01", "archived", 1);
  await seedVersionTree(venueRef, "v_arch_02", "archived", 2);
  await seedVersionTree(venueRef, "v_arch_03", "archived", 3);
  await seedVersionTree(venueRef, "v_arch_04", "archived", 4);
  await seedVersionTree(venueRef, "v_arch_05", "archived", 5);
  await seedVersionTree(venueRef, "v_arch_06", "archived", 6);

  const dryRun = await runMenuVersionRetentionCleanup({
    db,
    venueId,
    keepArchived: 5,
    retentionDays: 30,
    dryRun: true,
  });
  assert.equal(dryRun.deletedVersions, 1);
  assert.equal(dryRun.deletedItemsCount, 1);
  assert.equal(dryRun.deletedCategoriesCount, 1);

  const stillThere = await venueRef.collection("menu_versions").doc("v_arch_06").get();
  assert.equal(stillThere.exists, true);
});
