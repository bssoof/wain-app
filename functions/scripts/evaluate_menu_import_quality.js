/* eslint-disable no-console */
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-analytics";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const { createMenuImportJob, processMenuImport } = require("../lib/index.js");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
}

const db = admin.firestore();

function asText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeText(value) {
  return asText(value)
    .toLowerCase()
    .replace(/[\u064B-\u0652]/g, "")
    .replace(/[^a-z0-9\u0600-\u06FF]+/gi, " ")
    .trim();
}

function toNum(value) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

async function clearFirestore() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const projectId = process.env.GCLOUD_PROJECT;
  const url = `http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`;
  const response = await fetch(url, { method: "DELETE" });
  if (!response.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${response.status}`);
  }
}

function ensureArray(value) {
  return Array.isArray(value) ? value : [];
}

async function seedVenue({
  uid,
  venueId,
  versionId,
  dropCategories = [],
}) {
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

  const categories = [
    { id: "appetizers", key: "appetizers", name_ar: "مقبلات", name_en: "Appetizers", sort_order: 1 },
    { id: "main_courses", key: "main_courses", name_ar: "أطباق رئيسية", name_en: "Main Courses", sort_order: 2 },
    { id: "grills", key: "grills", name_ar: "مشاوي", name_en: "Grills", sort_order: 3 },
    { id: "desserts", key: "desserts", name_ar: "حلويات", name_en: "Desserts", sort_order: 4 },
    { id: "drinks", key: "drinks", name_ar: "مشروبات", name_en: "Drinks", sort_order: 5 },
    { id: "food", key: "food", name_ar: "أكل", name_en: "Food", sort_order: 6 },
  ];

  for (const category of categories) {
    if (dropCategories.includes(category.id)) continue;
    await versionRef.collection("categories").doc(category.id).set({
      ...category,
      is_custom: false,
    });
  }

  await db
    .collection("venues")
    .doc(venueId)
    .collection("menu_config")
    .doc("main")
    .set({
      draft_version_id: versionId,
      venue_type: "restaurant",
      currency: "ILS",
      updated_at: admin.firestore.Timestamp.now(),
    });

  await db.collection("merchants").doc(uid).set({ uid, venue_id: venueId });
  await db.collection("users").doc(uid).set({
    merchant_venue_id: venueId,
    is_merchant: true,
  });
}

function buildIdempotencyKey({ caseId, versionId, inputFiles }) {
  return `quality_v1|${caseId}|${versionId}|${inputFiles.join("|")}`;
}

function hasForbiddenNoise(name, forbiddenTokens) {
  const normalized = normalizeText(name);
  return forbiddenTokens.some((token) => normalized.includes(normalizeText(token)));
}

function computeDupRate(items) {
  if (!items.length) return 0;
  const seen = new Set();
  let duplicates = 0;
  for (const item of items) {
    const key = normalizeText(item.name_ar || "");
    if (!key) continue;
    if (seen.has(key)) duplicates += 1;
    else seen.add(key);
  }
  return duplicates / items.length;
}

function findBestMatch(items, expectedName) {
  const target = normalizeText(expectedName);
  if (!target) return null;
  return items.find((item) => normalizeText(item.name_ar || "").includes(target)) || null;
}

function almostEqual(a, b, epsilon = 0.011) {
  return Math.abs(a - b) <= epsilon;
}

function evaluateCase(caseDef, items) {
  const expectedItems = ensureArray(caseDef.expected_items);
  const forbidden = ensureArray(caseDef.forbidden_name_contains);
  const requiredCategoryIds = ensureArray(caseDef.required_category_ids);
  const requiredCategoryAnyOf = ensureArray(caseDef.required_category_ids_any_of);
  const thresholds = caseDef.thresholds || {};

  let matchedItems = 0;
  let matchedPrices = 0;
  let expectedPrices = 0;

  for (const expected of expectedItems) {
    const match = findBestMatch(items, expected.name_contains);
    if (!match) continue;
    matchedItems += 1;

    const expectedPrice = toNum(expected.price);
    if (expectedPrice !== null) {
      expectedPrices += 1;
      if (almostEqual(toNum(match.price) ?? 0, expectedPrice)) {
        matchedPrices += 1;
      }
    }
  }

  const noiseCount = items.filter((item) =>
    hasForbiddenNoise(item.name_ar || "", forbidden),
  ).length;

  const categories = new Set(items.map((item) => asText(item.category_id)));
  const requiredCategoryCheck = requiredCategoryIds.every((categoryId) =>
    categories.has(categoryId),
  );
  const requiredAnyOfCheck = requiredCategoryAnyOf.every((group) =>
    ensureArray(group).some((categoryId) => categories.has(asText(categoryId))),
  );

  const itemRecall = expectedItems.length > 0 ? matchedItems / expectedItems.length : 1;
  const priceRecall = expectedPrices > 0 ? matchedPrices / expectedPrices : 1;
  const noiseRate = items.length > 0 ? noiseCount / items.length : 0;
  const dupRate = computeDupRate(items);

  const pass =
    itemRecall >= (thresholds.item_recall_min ?? 0) &&
    priceRecall >= (thresholds.price_recall_min ?? 0) &&
    noiseRate <= (thresholds.noise_rate_max ?? 1) &&
    dupRate <= (thresholds.dup_rate_max ?? 1) &&
    requiredCategoryCheck &&
    requiredAnyOfCheck;

  return {
    pass,
    counts: {
      imported_items: items.length,
      expected_items: expectedItems.length,
      expected_prices: expectedPrices,
      noise_count: noiseCount,
    },
    metrics: {
      item_recall: Number(itemRecall.toFixed(4)),
      price_recall: Number(priceRecall.toFixed(4)),
      noise_rate: Number(noiseRate.toFixed(4)),
      dup_rate: Number(dupRate.toFixed(4)),
    },
    categories: [...categories].filter(Boolean).sort(),
    checks: {
      required_category_ids_ok: requiredCategoryCheck,
      required_category_ids_any_of_ok: requiredAnyOfCheck,
    },
  };
}

function printCaseSummary(caseId, result) {
  const m = result.metrics;
  console.log(
    `[${result.pass ? "PASS" : "FAIL"}] ${caseId} | ` +
      `item_recall=${m.item_recall} price_recall=${m.price_recall} ` +
      `noise_rate=${m.noise_rate} dup_rate=${m.dup_rate} ` +
      `items=${result.counts.imported_items}`,
  );
}

async function run() {
  const datasetPath = path.resolve(__dirname, "../testdata/menu_import_quality_cases.json");
  const reportPath = path.resolve(__dirname, "../reports/menu_import_quality_report.json");
  fs.mkdirSync(path.dirname(reportPath), { recursive: true });

  const cases = JSON.parse(fs.readFileSync(datasetPath, "utf8"));
  if (!Array.isArray(cases) || !cases.length) {
    throw new Error("Quality dataset is empty.");
  }

  await clearFirestore();

  const results = [];
  for (let index = 0; index < cases.length; index += 1) {
    const caseDef = cases[index];
    const caseId = asText(caseDef.id) || `case_${index + 1}`;
    const venueId = `quality_venue_${index + 1}`;
    const uid = `quality_merchant_${index + 1}`;
    const versionId = `quality_draft_${index + 1}`;
    const inputFiles = ensureArray(caseDef.input_files).map(asText).filter(Boolean);

    if (!inputFiles.length) {
      throw new Error(`Case ${caseId} has no input_files.`);
    }

    await seedVenue({
      uid,
      venueId,
      versionId,
      dropCategories: ensureArray(caseDef.drop_categories).map(asText),
    });

    const idempotencyKey = buildIdempotencyKey({ caseId, versionId, inputFiles });
    const created = await createMenuImportJob.run(
      {
        venueId,
        versionId,
        inputFiles,
        idempotencyKey,
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

    if (!processed.success || processed.status !== "review_required") {
      throw new Error(
        `Case ${caseId} failed to reach review_required. status=${processed.status}`,
      );
    }

    const itemsSnap = await db
      .collection("venues")
      .doc(venueId)
      .collection("menu_versions")
      .doc(versionId)
      .collection("items")
      .where("import_job_id", "==", created.jobId)
      .get();

    const items = itemsSnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    const evaluation = evaluateCase(caseDef, items);

    const jobSnap = await db
      .collection("venues")
      .doc(venueId)
      .collection("menu_import_jobs")
      .doc(created.jobId)
      .get();
    const jobData = jobSnap.data() || {};

    const caseResult = {
      case_id: caseId,
      venue_id: venueId,
      job_id: created.jobId,
      status: processed.status,
      evaluation,
      stage_metrics: {
        ocr_line_count: toNum(jobData.ocr_line_count),
        ocr_average_confidence: toNum(jobData.ocr_average_confidence),
        extracted_candidate_count: toNum(jobData.extracted_candidate_count),
        extracted_skipped_lines: toNum(jobData.extracted_skipped_lines),
        extracted_price_signals: toNum(jobData.extracted_price_signals),
        extracted_coverage: toNum(jobData.extracted_coverage),
        extracted_quality: asText(jobData.extracted_quality),
        mapped_imported_item_count: toNum(jobData.imported_item_count),
        mapped_needs_review_count: toNum(jobData.mapped_needs_review_count),
      },
      sample_items: items.slice(0, 5).map((item) => ({
        name_ar: asText(item.name_ar),
        price: toNum(item.price),
        category_id: asText(item.category_id),
      })),
    };

    results.push(caseResult);
    printCaseSummary(caseId, evaluation);
  }

  const avg = (values) =>
    values.length
      ? Number((values.reduce((acc, value) => acc + value, 0) / values.length).toFixed(4))
      : 0;

  const summary = {
    generated_at: new Date().toISOString(),
    total_cases: results.length,
    passed_cases: results.filter((result) => result.evaluation.pass).length,
    failed_cases: results.filter((result) => !result.evaluation.pass).length,
    avg_item_recall: avg(results.map((result) => result.evaluation.metrics.item_recall)),
    avg_price_recall: avg(results.map((result) => result.evaluation.metrics.price_recall)),
    avg_noise_rate: avg(results.map((result) => result.evaluation.metrics.noise_rate)),
    avg_dup_rate: avg(results.map((result) => result.evaluation.metrics.dup_rate)),
  };

  const report = { summary, cases: results };
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2), "utf8");

  console.log("\nQuality summary:");
  console.table(summary);
  console.log(`Report written to: ${reportPath}`);

  if (summary.failed_cases > 0) {
    process.exitCode = 1;
  }
}

run().catch((error) => {
  console.error("Failed to evaluate menu import quality:", error);
  process.exitCode = 1;
});
