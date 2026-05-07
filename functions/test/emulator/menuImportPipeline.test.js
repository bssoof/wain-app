const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-analytics";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  createMenuImportJob,
  processMenuImport,
  enqueueMenuImport,
  runMenuOcr,
  extractMenuCandidates,
} = require("../../lib/index.js");
const { getDefaultStorageBucket } = require("../../lib/shared/storage.js");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

function menuImportUri(venueId, fileName) {
  return `gs://${getDefaultStorageBucket().name}/venues/${venueId}/photos/${fileName}`;
}

async function expectHttpsError(action, code, messagePattern) {
  await assert.rejects(action, (error) => {
    assert.equal(error.code, code);
    if (messagePattern) {
      assert.match(error.message, messagePattern);
    }
    return true;
  });
}

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

async function seedMerchantVenue({ uid, venueId, versionId = "draft_test_1" }) {
  const versionRef = db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId);

  await db.collection("venues").doc(venueId).set({
    active_menu_version_id: versionId,
  });
  await versionRef.set({
    status: "draft",
    source: "manual",
    created_at: admin.firestore.Timestamp.now(),
  });
  await versionRef.collection("categories").doc("appetizers").set({
    key: "appetizers",
    name_ar: "مقبلات",
    name_en: "Appetizers",
    sort_order: 1,
    is_custom: false,
  });
  await versionRef.collection("categories").doc("main_courses").set({
    key: "main_courses",
    name_ar: "أطباق رئيسية",
    name_en: "Main Courses",
    sort_order: 2,
    is_custom: false,
  });
  await versionRef.collection("categories").doc("desserts").set({
    key: "desserts",
    name_ar: "حلويات",
    name_en: "Desserts",
    sort_order: 3,
    is_custom: false,
  });
  await versionRef.collection("categories").doc("drinks").set({
    key: "drinks",
    name_ar: "مشروبات",
    name_en: "Drinks",
    sort_order: 4,
    is_custom: false,
  });
  await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_config")
    .doc("main")
    .set({
      draft_version_id: versionId,
      venue_type: "restaurant",
      updated_at: admin.firestore.Timestamp.now(),
    });
  await db.collection("merchants").doc(uid).set({
    uid,
    venue_id: venueId,
  });
  await db.collection("users").doc(uid).set({
    merchant_venue_id: venueId,
    is_merchant: true,
  });
}

test.before(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("menu import: create job allows empty inputFiles", async () => {
  await clearFirestore();
  const uid = "merchant-import-empty";
  const venueId = "venue-import-empty";
  await seedMerchantVenue({ uid, venueId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [],
      idempotencyKey: "job_key_empty",
    },
    { auth: { uid } },
  );

  assert.equal(created.success, true);
  const jobSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_jobs")
    .doc(created.jobId)
    .get();
  assert.deepEqual(jobSnap.data().input_files, []);
});

test("menu import: create job allows caller venue menu_import photo URI", async () => {
  await clearFirestore();
  const uid = "merchant-import-valid-uri";
  const venueId = "venue-import-valid-uri";
  await seedMerchantVenue({ uid, venueId });

  const inputFile = menuImportUri(venueId, "menu_import_allowed.jpg");
  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [inputFile],
      idempotencyKey: "job_key_valid_uri",
    },
    { auth: { uid } },
  );

  assert.equal(created.success, true);
  const jobSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_jobs")
    .doc(created.jobId)
    .get();
  assert.deepEqual(jobSnap.data().input_files, [inputFile]);
});

test("menu import: create job denies cross-venue inputFiles URI", async () => {
  await clearFirestore();
  const uid = "merchant-import-cross-venue";
  const venueId = "venue-import-cross-venue";
  await seedMerchantVenue({ uid, venueId });

  await expectHttpsError(
    () =>
      createMenuImportJob.run(
        {
          venueId,
          inputFiles: [menuImportUri("venue-import-other", "menu_import_cross.jpg")],
          idempotencyKey: "job_key_cross_venue",
        },
        { auth: { uid } },
      ),
    "invalid-argument",
    /venue menu import photo prefix/,
  );
});

test("menu import: create job denies wrong bucket inputFiles URI", async () => {
  await clearFirestore();
  const uid = "merchant-import-wrong-bucket";
  const venueId = "venue-import-wrong-bucket";
  await seedMerchantVenue({ uid, venueId });

  await expectHttpsError(
    () =>
      createMenuImportJob.run(
        {
          venueId,
          inputFiles: [`gs://other-bucket/venues/${venueId}/photos/menu_import_wrong.jpg`],
          idempotencyKey: "job_key_wrong_bucket",
        },
        { auth: { uid } },
      ),
    "invalid-argument",
    /configured storage bucket/,
  );
});

test("menu import: create job denies non-gs inputFiles URI", async () => {
  await clearFirestore();
  const uid = "merchant-import-wrong-scheme";
  const venueId = "venue-import-wrong-scheme";
  await seedMerchantVenue({ uid, venueId });

  await expectHttpsError(
    () =>
      createMenuImportJob.run(
        {
          venueId,
          inputFiles: ["https://example.com/x.jpg"],
          idempotencyKey: "job_key_wrong_scheme",
        },
        { auth: { uid } },
      ),
    "invalid-argument",
    /gs:\/\//,
  );
});

test("menu import: create job denies more than 20 inputFiles", async () => {
  await clearFirestore();
  const uid = "merchant-import-too-many";
  const venueId = "venue-import-too-many";
  await seedMerchantVenue({ uid, venueId });
  const files = Array.from({ length: 21 }, (_, index) =>
    menuImportUri(venueId, `menu_import_${index}.jpg`),
  );

  await expectHttpsError(
    () =>
      createMenuImportJob.run(
        {
          venueId,
          inputFiles: files,
          idempotencyKey: "job_key_too_many",
        },
        { auth: { uid } },
      ),
    "invalid-argument",
    /more than 20/,
  );
});

test("menu import: create job denies duplicate inputFiles", async () => {
  await clearFirestore();
  const uid = "merchant-import-duplicate";
  const venueId = "venue-import-duplicate";
  await seedMerchantVenue({ uid, venueId });
  const inputFile = menuImportUri(venueId, "menu_import_duplicate.jpg");

  await expectHttpsError(
    () =>
      createMenuImportJob.run(
        {
          venueId,
          inputFiles: [inputFile, inputFile],
          idempotencyKey: "job_key_duplicate",
        },
        { auth: { uid } },
      ),
    "invalid-argument",
    /duplicate/,
  );
});

test("menu import: create job is idempotent per idempotency key", async () => {
  await clearFirestore();
  const uid = "merchant-import-1";
  const venueId = "venue-import-1";
  await seedMerchantVenue({ uid, venueId });

  const first = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_1.jpg")],
      idempotencyKey: "job_key_1",
    },
    { auth: { uid } },
  );

  assert.equal(first.success, true);
  assert.equal(first.status, "uploaded");
  assert.equal(first.idempotent, false);
  assert.ok(first.jobId);

  const second = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_1.jpg")],
      idempotencyKey: "job_key_1",
    },
    { auth: { uid } },
  );

  assert.equal(second.success, true);
  assert.equal(second.idempotent, true);
  assert.equal(second.jobId, first.jobId);

  const jobSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_jobs")
    .doc(first.jobId)
    .get();
  assert.equal(jobSnap.exists, true);
  const job = jobSnap.data();
  assert.ok(job);
  assert.equal(job.status, "uploaded");
  assert.equal(job.idempotency_key, "job_key_1");
  assert.equal(job.version_id, "draft_test_1");
});

test("menu import: failed deterministic job can be retried to uploaded", async () => {
  await clearFirestore();
  const uid = "merchant-import-retry";
  const venueId = "venue-import-retry";
  await seedMerchantVenue({ uid, venueId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_retry.jpg")],
      idempotencyKey: "job_key_retry_1",
    },
    { auth: { uid } },
  );

  await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_jobs")
    .doc(created.jobId)
    .set({
      status: "failed",
      error_code: "ocr_failed",
      error_message: "seeded failure",
    }, { merge: true });

  const retried = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_retry.jpg")],
      idempotencyKey: "job_key_retry_1",
    },
    { auth: { uid } },
  );

  assert.equal(retried.success, true);
  assert.equal(retried.jobId, created.jobId);
  assert.equal(retried.status, "uploaded");
  assert.equal(retried.idempotent, false);
  assert.equal(retried.retried, true);
});

test("menu import: completed deterministic job is restartable with same idempotency key", async () => {
  await clearFirestore();
  const uid = "merchant-import-restart";
  const venueId = "venue-import-restart";
  await seedMerchantVenue({ uid, venueId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_restart.jpg")],
      idempotencyKey: "job_key_restart_1",
    },
    { auth: { uid } },
  );

  await processMenuImport.run(
    {
      venueId,
      jobId: created.jobId,
    },
    { auth: { uid } },
  );

  const restarted = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_restart.jpg")],
      idempotencyKey: "job_key_restart_1",
    },
    { auth: { uid } },
  );

  assert.equal(restarted.success, true);
  assert.equal(restarted.jobId, created.jobId);
  assert.equal(restarted.status, "uploaded");
  assert.equal(restarted.idempotent, false);
  assert.equal(restarted.restarted, true);
});

test("menu import: process pipeline advances uploaded -> review_required", async () => {
  await clearFirestore();
  const uid = "merchant-import-2";
  const venueId = "venue-import-2";
  await seedMerchantVenue({ uid, venueId, versionId: "draft_test_2" });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_cafe-menu-2.jpg")],
      idempotencyKey: "job_key_2",
    },
    { auth: { uid } },
  );

  const processed = await processMenuImport.run(
    {
      venueId,
      jobId: created.jobId,
    },
    { auth: { uid } },
  );

  assert.equal(processed.success, true);
  assert.equal(processed.status, "review_required");
  assert.equal(processed.done, true);

  const jobSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_jobs")
    .doc(created.jobId)
    .get();
  const job = jobSnap.data();
  assert.ok(job);
  assert.equal(job.status, "review_required");
  assert.ok(typeof job.ocr_output_ref === "string" && job.ocr_output_ref.length > 0);
  assert.ok(
    typeof job.extracted_output_ref === "string" &&
      job.extracted_output_ref.length > 0,
  );
  assert.ok(typeof job.mapped_output_ref === "string" && job.mapped_output_ref.length > 0);
  assert.ok(typeof job.imported_item_count === "number" && job.imported_item_count > 0);

  const processedAgain = await processMenuImport.run(
    {
      venueId,
      jobId: created.jobId,
    },
    { auth: { uid } },
  );
  assert.equal(processedAgain.status, "review_required");
  assert.equal(processedAgain.done, true);

  const importedItemsSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc("draft_test_2")
    .collection("items")
    .where("import_job_id", "==", created.jobId)
    .get();
  assert.equal(importedItemsSnap.empty, false);
  const firstItem = importedItemsSnap.docs[0].data();
  assert.equal(firstItem.source, "ocr");
  assert.ok(typeof firstItem.name_ar === "string" && firstItem.name_ar.length > 0);
  const categoryIds = new Set(importedItemsSnap.docs.map((doc) => doc.data().category_id));
  assert.ok(categoryIds.has("drinks"));
  assert.ok(categoryIds.has("desserts"));
  assert.equal(categoryIds.has("appetizers"), false);
  const importedNames = importedItemsSnap.docs
    .map((doc) => String(doc.data().name_ar || "").trim());
  assert.equal(importedNames.includes("\u062d\u0644\u0648\u064a\u0627\u062a"), false);
  assert.equal(importedNames.includes("\u0645\u0634\u0631\u0648\u0628\u0627\u062a"), false);
});

test("menu import: template OCR skips website/noise and keeps drinks + desserts", async () => {
  await clearFirestore();
  const uid = "merchant-import-template";
  const venueId = "venue-import-template";
  const versionId = "draft_test_template";
  await seedMerchantVenue({ uid, venueId, versionId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_template-menu.jpg")],
      idempotencyKey: "job_key_template_1",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: created.jobId }, { auth: { uid } });

  const importedItemsSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("items")
    .where("import_job_id", "==", created.jobId)
    .get();

  assert.ok(importedItemsSnap.size >= 6);

  const names = importedItemsSnap.docs.map((doc) => String(doc.data().name_ar || "").trim());
  const categoryIds = new Set(importedItemsSnap.docs.map((doc) => doc.data().category_id));

  assert.equal(names.some((name) => name.includes("www.reallygreatsite.com")), false);
  assert.equal(names.includes("\u0645\u0648"), false);
  assert.equal(names.includes("\u0639\u0648"), false);
  assert.equal(names.includes("\u062a\u0639\u0648"), false);

  assert.ok(names.some((name) => name.includes("\u0642\u0647\u0648\u0629 \u0633\u0627\u062f\u0629")));
  assert.ok(names.some((name) => name.includes("\u062a\u0634\u064a\u0632 \u0643\u064a\u0643")));
  assert.ok(categoryIds.has("drinks"));
  assert.ok(categoryIds.has("desserts"));
});

test("menu import: food OCR supports 3-decimal prices and maps core food items", async () => {
  await clearFirestore();
  const uid = "merchant-import-food";
  const venueId = "venue-import-food";
  const versionId = "draft_test_food";
  await seedMerchantVenue({ uid, venueId, versionId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_bukhari-food-menu.jpg")],
      idempotencyKey: "job_key_food_1",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: created.jobId }, { auth: { uid } });

  const importedItemsSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("items")
    .where("import_job_id", "==", created.jobId)
    .get();

  assert.ok(importedItemsSnap.size >= 5);

  const names = importedItemsSnap.docs.map((doc) => String(doc.data().name_ar || "").trim());
  const prices = importedItemsSnap.docs.map((doc) => Number(doc.data().price || 0));
  const categoryIds = new Set(importedItemsSnap.docs.map((doc) => doc.data().category_id));

  assert.ok(names.some((name) => name.includes("\u0628\u062e\u0627\u0631\u064a")));
  assert.ok(names.some((name) => name.includes("\u0648\u062c\u0628\u0629")));
  assert.ok(prices.some((price) => price > 0 && price <= 2));
  assert.ok(categoryIds.has("main_courses") || categoryIds.has("drinks"));
});

test("menu import: handles price-first line pairs (price then item)", async () => {
  await clearFirestore();
  const uid = "merchant-import-pricefirst";
  const venueId = "venue-import-pricefirst";
  const versionId = "draft_test_pricefirst";
  await seedMerchantVenue({ uid, venueId, versionId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_pricefirst-menu.jpg")],
      idempotencyKey: "job_key_pricefirst_1",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: created.jobId }, { auth: { uid } });

  const importedItemsSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("items")
    .where("import_job_id", "==", created.jobId)
    .get();

  const names = importedItemsSnap.docs.map((doc) => String(doc.data().name_ar || "").trim());
  const prices = importedItemsSnap.docs.map((doc) => Number(doc.data().price || 0));

  assert.ok(names.some((name) => name.includes("\u0642\u0647\u0648\u0629 \u0633\u0627\u062f\u0629")));
  assert.ok(names.some((name) => name.includes("\u0642\u0647\u0648\u0629 \u0628\u0627\u0644\u062d\u0644\u064a\u0628")));
  assert.ok(prices.includes(10));
  assert.ok(prices.includes(30));
});

test("menu import: filters address/contact noise lines from OCR", async () => {
  await clearFirestore();
  const uid = "merchant-import-noisyfood";
  const venueId = "venue-import-noisyfood";
  const versionId = "draft_test_noisyfood";
  await seedMerchantVenue({ uid, venueId, versionId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_noisyfood-menu.jpg")],
      idempotencyKey: "job_key_noisyfood_1",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: created.jobId }, { auth: { uid } });

  const importedItemsSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("items")
    .where("import_job_id", "==", created.jobId)
    .get();

  const names = importedItemsSnap.docs.map((doc) => String(doc.data().name_ar || "").trim());
  assert.ok(names.some((name) => name.includes("\u0643\u0628\u0627\u0628")));
  assert.equal(names.some((name) => name.includes("\u0634\u0627\u0631\u0639")), false);
  assert.equal(names.some((name) => name.includes("www.")), false);
  assert.equal(names.some((name) => name.includes("\u0647\u0627\u062a\u0641")), false);
});

test("menu import: breakfast hint falls back to existing food categories when main_courses is missing", async () => {
  await clearFirestore();
  const uid = "merchant-import-breakfast";
  const venueId = "venue-import-breakfast";
  const versionId = "draft_test_breakfast";
  await seedMerchantVenue({ uid, venueId, versionId });

  await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("categories")
    .doc("main_courses")
    .delete();

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_breakfast-menu.jpg")],
      idempotencyKey: "job_key_breakfast_1",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: created.jobId }, { auth: { uid } });

  const importedItemsSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("items")
    .where("import_job_id", "==", created.jobId)
    .get();

  assert.ok(importedItemsSnap.size >= 2);
  const categoryIds = new Set(importedItemsSnap.docs.map((doc) => doc.data().category_id));
  assert.equal(
    [...categoryIds].some((id) => String(id).startsWith("custom_main_courses")),
    false,
  );
  assert.equal(categoryIds.has("appetizers"), true);
});

test("menu import: new job replaces prior imported snapshot (no duplicate carry-over)", async () => {
  await clearFirestore();
  const uid = "merchant-import-dup";
  const venueId = "venue-import-dup";
  const versionId = "draft_test_dup";
  await seedMerchantVenue({ uid, venueId, versionId });

  const firstJob = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_cafe-menu-dup.jpg")],
      idempotencyKey: "job_key_dup_1",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: firstJob.jobId }, { auth: { uid } });

  const itemsRef = db
    .collection("venues")
    .doc(venueId)
    .collection("menu_versions")
    .doc(versionId)
    .collection("items");

  const firstImported = await itemsRef.where("source", "==", "ocr").get();
  assert.ok(firstImported.size > 0);

  const secondJob = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_cafe-menu-dup.jpg")],
      idempotencyKey: "job_key_dup_2",
    },
    { auth: { uid } },
  );
  await processMenuImport.run({ venueId, jobId: secondJob.jobId }, { auth: { uid } });

  const finalImported = await itemsRef.where("source", "==", "ocr").get();
  assert.ok(finalImported.size > 0);

  const jobIds = new Set(finalImported.docs.map((doc) => doc.data().import_job_id));
  assert.equal(jobIds.size, 1);
  assert.equal(jobIds.has(secondJob.jobId), true);

  const normalizedNames = finalImported.docs.map((doc) =>
    String(doc.data().name_ar || "").trim().toLowerCase(),
  );
  assert.equal(new Set(normalizedNames).size, normalizedNames.length);
});

test("menu import: guard prevents extracted stage before OCR stage", async () => {
  await clearFirestore();
  const uid = "merchant-import-3";
  const venueId = "venue-import-3";
  await seedMerchantVenue({ uid, venueId, versionId: "draft_test_3" });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_3.jpg")],
      idempotencyKey: "job_key_3",
    },
    { auth: { uid } },
  );

  try {
    await extractMenuCandidates.run(
      {
        venueId,
        jobId: created.jobId,
      },
      { auth: { uid } },
    );
    assert.fail("Expected extractMenuCandidates to fail before OCR stage.");
  } catch (error) {
    const raw = String(error?.code || error?.message || error);
    assert.match(raw, /failed-precondition/i);
  }

  const ocrResult = await runMenuOcr.run(
    {
      venueId,
      jobId: created.jobId,
    },
    { auth: { uid } },
  );
  assert.equal(ocrResult.status, "ocr_done");

  const extractResult = await extractMenuCandidates.run(
    {
      venueId,
      jobId: created.jobId,
    },
    { auth: { uid } },
  );
  assert.equal(extractResult.status, "extracted");
});

test("menu import: enqueue creates async task doc", async () => {
  await clearFirestore();
  const uid = "merchant-import-enqueue";
  const venueId = "venue-import-enqueue";
  const versionId = "draft_test_enqueue";
  await seedMerchantVenue({ uid, venueId, versionId });

  const created = await createMenuImportJob.run(
    {
      venueId,
      inputFiles: [menuImportUri(venueId, "menu_import_cafe-menu-enqueue.jpg")],
      idempotencyKey: "job_key_enqueue_1",
    },
    { auth: { uid } },
  );

  const queued = await enqueueMenuImport.run(
    { venueId, jobId: created.jobId },
    { auth: { uid } },
  );

  assert.equal(queued.success, true);
  assert.equal(queued.queued, true);
  assert.equal(queued.status, "queued");
  assert.ok(typeof queued.taskId === "string" && queued.taskId.length > 0);

  const taskSnap = await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_tasks")
    .doc(queued.taskId)
    .get();
  assert.equal(taskSnap.exists, true);
  assert.equal(taskSnap.data().job_id, created.jobId);
  assert.equal(taskSnap.data().status, "queued");
});

test("menu import: letter-gate drops candidates without alphabetical characters and sets source to ocr", async () => {
  await clearFirestore();
  const uid = "merchant-import-letters";
  const venueId = "venue-import-letters";
  const versionId = "draft_letters";
  await seedMerchantVenue({ uid, venueId, versionId });

  const jobId = "job_letters_1";
  await db.collection("venues").doc(venueId).collection("menu_import_jobs").doc(jobId).set({
    venue_id: venueId,
    version_id: versionId,
    status: "extracted",
    input_files: [menuImportUri(venueId, "menu_import_dummy.jpg")],
    extracted_output_ref: `gs://${process.env.GCLOUD_PROJECT}.appspot.com/venues/${venueId}/jobs/${jobId}/extracted.json`
  });

  const extractedPayload = {
    source: "test",
    skipped_lines: 0,
    generated_at: new Date().toISOString(),
    candidates: [
      { name_ar: "1234 56", price: 10, currency: "ILS", market_price_flag: false, confidence: 0.9, category_hint: null },
      { name_ar: "### === ///", price: 15, currency: "ILS", market_price_flag: false, confidence: 0.9, category_hint: null },
      { name_ar: "وجبة شاورما", price: 20, currency: "ILS", market_price_flag: false, confidence: 0.9, category_hint: null }
    ]
  };

  await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_import_jobs")
    .doc(jobId)
    .collection("stage_data")
    .doc("extracted")
    .set({
      payload: extractedPayload,
      updated_at: admin.firestore.Timestamp.now(),
    });

  const { mapExtractedMenu } = require("../../lib/index.js");
  await mapExtractedMenu.run({ venueId, jobId }, { auth: { uid } });

  const itemsSnap = await db.collection("venues").doc(venueId).collection("menu_versions").doc(versionId).collection("items").get();
  
  assert.equal(itemsSnap.size, 1, "Should drop pure numbers and symbols");
  
  const item = itemsSnap.docs[0].data();
  assert.equal(item.name_ar, "وجبة شاورما");
  assert.equal(item.source, "ocr", "Extracted item should be explicitly flagged as source: ocr");
});
