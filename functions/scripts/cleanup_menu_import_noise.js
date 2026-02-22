#!/usr/bin/env node
/*
 * Menu noise cleanup runner.
 *
 * Goal:
 * - Remove OCR/error garbage menu items (URLs, API error blobs, JSON fragments).
 * - Remove noisy categories.
 * - Move valid items from deleted noisy categories into a fallback category.
 *
 * Usage:
 *   npm run menu:clean-noise -- --venue azure_01 --dry-run
 *   npm run menu:clean-noise -- --venue azure_01 --target draft
 *   npm run menu:clean-noise -- --run-all --target draft --dry-run
 *   npm run menu:clean-noise -- --venue azure_01 --target all --include-legacy
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const DEFAULT_BATCH_SIZE = 20;
const DEFAULT_MAX_BATCHES = 1;
const WRITE_BATCH_SIZE = 350;

const TARGETS = new Set(["draft", "active", "all"]);
const PREFERRED_FALLBACK_KEYS = new Set(["other", "food", "drinks"]);
const NOISE_TOKENS = [
  "http://",
  "https://",
  "www.",
  "googleapis.com",
  "type.googleapis.com",
  "console.developers.google.com",
  "cloud vision api has not been used",
  "enable it by visiting",
  "permission_denied",
  "service_disabled",
  "\"error\"",
  "\"details\"",
  "\"status\"",
  "errorinfo",
  "contact us",
];

function printHelp() {
  console.log(`
Menu import noise cleanup

Options:
  --venue <id>            Process a single venue
  --run-all               Process all venues in batches
  --target <mode>         draft | active | all (default: draft)
  --version <id>          Process a specific version id (requires --venue)
  --include-legacy        Also cleanup legacy venues/{venue}/menu_items
  --batch-size <n>        Venues per page in run-all mode (default: ${DEFAULT_BATCH_SIZE})
  --max-batches <n>       Max pages in run-all mode (default: ${DEFAULT_MAX_BATCHES})
  --dry-run               Preview only (no writes)
  --help                  Show this help
`);
}

function asString(value) {
  if (typeof value !== "string") return "";
  return value.trim();
}

function asNumber(value, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseArgs(argv) {
  const options = {
    venueId: "",
    runAll: false,
    target: "draft",
    versionId: "",
    includeLegacy: false,
    batchSize: DEFAULT_BATCH_SIZE,
    maxBatches: DEFAULT_MAX_BATCHES,
    dryRun: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;

    const [key, inlineValue] = token.split("=");
    const value = inlineValue ?? argv[i + 1];
    const consume = inlineValue == null;

    switch (key) {
      case "--help":
        printHelp();
        process.exit(0);
        break;
      case "--venue":
        options.venueId = asString(value);
        if (consume) i += 1;
        break;
      case "--run-all":
        options.runAll = true;
        break;
      case "--target":
        options.target = asString(value).toLowerCase();
        if (consume) i += 1;
        break;
      case "--version":
        options.versionId = asString(value);
        if (consume) i += 1;
        break;
      case "--include-legacy":
        options.includeLegacy = true;
        break;
      case "--batch-size":
        options.batchSize = Math.max(1, asNumber(value, DEFAULT_BATCH_SIZE));
        if (consume) i += 1;
        break;
      case "--max-batches":
        options.maxBatches = Math.max(1, asNumber(value, DEFAULT_MAX_BATCHES));
        if (consume) i += 1;
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      default:
        console.warn(`[WARN] Unknown argument ignored: ${key}`);
        break;
    }
  }

  if (!TARGETS.has(options.target)) {
    throw new Error(`Invalid --target value "${options.target}". Use draft|active|all.`);
  }
  if (options.versionId && !options.venueId) {
    throw new Error("--version requires --venue.");
  }
  if (options.runAll && options.versionId) {
    throw new Error("--version cannot be used with --run-all.");
  }
  if (!options.runAll && !options.venueId) {
    throw new Error("Specify --venue <id> or --run-all.");
  }

  return options;
}

function initAdmin() {
  if (admin.apps.length) return;
  const serviceAccountPath = path.resolve(__dirname, "../../service-account-key.json");
  if (fs.existsSync(serviceAccountPath)) {
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    return;
  }
  admin.initializeApp();
}

function hasArabicOrLatin(text) {
  return /[a-z\u0600-\u06ff]/i.test(text);
}

function hasNoiseToken(text) {
  const lower = text.toLowerCase();
  return NOISE_TOKENS.some((token) => lower.includes(token));
}

function looksLikeJsonOrErrorBlob(text) {
  const compact = text.replace(/\s+/g, " ").trim();
  if (!compact) return false;
  if (/[{}\[\]]/.test(compact)) return true;
  if (/^[:/\\-]{2,}/.test(compact)) return true;
  if (compact.includes('"}') || compact.includes('":')) return true;
  return false;
}

function normalizeCategoryKey(value) {
  return asString(value)
    .toLowerCase()
    .replace(/[^a-z0-9_]+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "");
}

function isNoisySection(sectionData) {
  const text = [
    asString(sectionData.name_ar),
    asString(sectionData.name_en),
    asString(sectionData.key),
  ]
    .filter(Boolean)
    .join(" | ");

  if (!text) return true;
  if (text.length > 80) return true;
  if (hasNoiseToken(text)) return true;
  if (looksLikeJsonOrErrorBlob(text)) return true;
  if (!hasArabicOrLatin(text)) return true;
  return false;
}

function isNoisyItem(itemData, sectionNamesLower) {
  const nameAr = asString(itemData.name_ar);
  const nameEn = asString(itemData.name_en);
  const description = asString(itemData.description_ar);
  const category = asString(itemData.category).toLowerCase();
  const text = [nameAr, nameEn, description].filter(Boolean).join(" | ");

  if (!nameAr && !nameEn) return true;
  if (text.length > 180) return true;
  if (hasNoiseToken(text)) return true;
  if (looksLikeJsonOrErrorBlob(text)) return true;

  const name = (nameAr || nameEn).trim();
  const price = Number(itemData.price ?? 0);
  if (!hasArabicOrLatin(name)) return true;
  if (name.length <= 2 && (!Number.isFinite(price) || price <= 0)) return true;
  if (sectionNamesLower.has(name.toLowerCase()) && (!Number.isFinite(price) || price <= 0)) {
    return true;
  }
  if ((category === "other" || category === "food") && name.length <= 3 && price <= 0) {
    return true;
  }

  return false;
}

function pickFallbackCategory(categories, noisyCategoryIds) {
  const clean = categories.filter((category) => !noisyCategoryIds.has(category.id));
  if (!clean.length) return null;

  for (const category of clean) {
    const key = normalizeCategoryKey(category.data.key || category.id);
    if (PREFERRED_FALLBACK_KEYS.has(key)) {
      return category.id;
    }
  }
  return clean[0].id;
}

function chunk(items, size) {
  const out = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

async function commitOperations(db, operations, dryRun) {
  if (!operations.length || dryRun) return;
  const chunks = chunk(operations, WRITE_BATCH_SIZE);

  for (const part of chunks) {
    const batch = db.batch();
    for (const op of part) {
      if (op.type === "delete") {
        batch.delete(op.ref);
      } else if (op.type === "update") {
        batch.update(op.ref, op.data);
      } else if (op.type === "set") {
        batch.set(op.ref, op.data, op.options || {});
      }
    }
    await batch.commit();
  }
}

async function cleanupVersion({ db, venueRef, venueId, versionId, dryRun }) {
  const versionRef = venueRef.collection("menu_versions").doc(versionId);
  const categoriesRef = versionRef.collection("categories");
  const itemsRef = versionRef.collection("items");

  const [versionSnap, categoriesSnap, itemsSnap] = await Promise.all([
    versionRef.get(),
    categoriesRef.get(),
    itemsRef.get(),
  ]);

  if (!versionSnap.exists) {
    return {
      venueId,
      versionId,
      status: "missing_version",
      categoriesScanned: 0,
      itemsScanned: 0,
      categoriesDeleted: 0,
      itemsDeleted: 0,
      itemsMoved: 0,
      fallbackCreated: false,
    };
  }

  const categories = categoriesSnap.docs.map((doc) => ({
    id: doc.id,
    ref: doc.ref,
    data: doc.data() || {},
  }));
  const items = itemsSnap.docs.map((doc) => ({
    id: doc.id,
    ref: doc.ref,
    data: doc.data() || {},
  }));

  const sectionNamesLower = new Set(
    categories
      .map((category) => asString(category.data.name_ar).toLowerCase())
      .filter(Boolean),
  );

  const noisyCategoryIds = new Set(
    categories.filter((category) => isNoisySection(category.data)).map((category) => category.id),
  );

  const noisyItems = items.filter((item) => isNoisyItem(item.data, sectionNamesLower));
  const noisyItemIds = new Set(noisyItems.map((item) => item.id));

  const itemsToMove = items.filter((item) => (
    noisyCategoryIds.has(asString(item.data.category)) && !noisyItemIds.has(item.id)
  ));

  let fallbackCategoryId = pickFallbackCategory(categories, noisyCategoryIds);
  let fallbackCreated = false;
  const operations = [];

  if (!fallbackCategoryId && itemsToMove.length > 0) {
    const maxSort = categories.reduce((max, category) => {
      const sort = asNumber(category.data.sort_order, 0);
      return sort > max ? sort : max;
    }, 0);

    const generatedId = `other_auto_${Date.now()}`;
    const fallbackRef = categoriesRef.doc(generatedId);
    operations.push({
      type: "set",
      ref: fallbackRef,
      data: {
        key: "other",
        name_ar: "Other",
        name_en: "Other",
        icon: "more_horiz",
        sort_order: maxSort + 1,
        is_custom: true,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    });
    fallbackCategoryId = generatedId;
    fallbackCreated = true;
  }

  for (const item of itemsToMove) {
    operations.push({
      type: "update",
      ref: item.ref,
      data: {
        category: fallbackCategoryId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    });
  }

  for (const item of noisyItems) {
    operations.push({ type: "delete", ref: item.ref });
  }

  for (const category of categories) {
    if (!noisyCategoryIds.has(category.id)) continue;
    operations.push({ type: "delete", ref: category.ref });
  }

  if (operations.length > 0) {
    operations.push({
      type: "set",
      ref: versionRef,
      data: { updated_at: admin.firestore.FieldValue.serverTimestamp() },
      options: { merge: true },
    });
  }

  await commitOperations(db, operations, dryRun);

  return {
    venueId,
    versionId,
    status: operations.length ? (dryRun ? "dry_run" : "cleaned") : "no_changes",
    categoriesScanned: categories.length,
    itemsScanned: items.length,
    categoriesDeleted: noisyCategoryIds.size,
    itemsDeleted: noisyItems.length,
    itemsMoved: itemsToMove.length,
    fallbackCreated,
  };
}

async function cleanupLegacyItems({ venueRef, venueId, dryRun }) {
  const legacyRef = venueRef.collection("menu_items");
  const itemsSnap = await legacyRef.get();
  if (itemsSnap.empty) {
    return {
      venueId,
      status: "no_legacy_items",
      scanned: 0,
      deleted: 0,
    };
  }

  const items = itemsSnap.docs.map((doc) => ({
    id: doc.id,
    ref: doc.ref,
    data: doc.data() || {},
  }));
  const noisy = items.filter((item) => isNoisyItem(item.data, new Set()));
  const operations = noisy.map((item) => ({ type: "delete", ref: item.ref }));
  await commitOperations(legacyRef.firestore, operations, dryRun);

  return {
    venueId,
    status: operations.length ? (dryRun ? "dry_run" : "cleaned") : "no_changes",
    scanned: items.length,
    deleted: noisy.length,
  };
}

async function resolveVersionIds({ venueRef, options }) {
  if (options.versionId) return [options.versionId];

  const [venueSnap, configSnap] = await Promise.all([
    venueRef.get(),
    venueRef.collection("menu_config").doc("main").get(),
  ]);
  if (!venueSnap.exists) return [];

  const activeVersionId = asString(venueSnap.data()?.active_menu_version_id);
  const draftVersionId = asString(configSnap.data()?.draft_version_id);

  if (options.target === "draft") {
    return draftVersionId ? [draftVersionId] : [];
  }
  if (options.target === "active") {
    return activeVersionId ? [activeVersionId] : [];
  }

  const allVersions = await venueRef.collection("menu_versions").get();
  return allVersions.docs.map((doc) => doc.id);
}

async function cleanupVenue({ db, venueId, options }) {
  const venueRef = db.collection("venues").doc(venueId);
  const versionIds = await resolveVersionIds({ venueRef, options });
  if (!versionIds.length && !options.includeLegacy) {
    return [{
      venueId,
      versionId: "-",
      status: "no_target_version",
      categoriesScanned: 0,
      itemsScanned: 0,
      categoriesDeleted: 0,
      itemsDeleted: 0,
      itemsMoved: 0,
      fallbackCreated: false,
    }];
  }

  const results = [];
  for (const versionId of versionIds) {
    // eslint-disable-next-line no-await-in-loop
    const result = await cleanupVersion({
      db,
      venueRef,
      venueId,
      versionId,
      dryRun: options.dryRun,
    });
    results.push(result);
  }

  if (options.includeLegacy) {
    const legacyResult = await cleanupLegacyItems({
      venueRef,
      venueId,
      dryRun: options.dryRun,
    });
    results.push({
      venueId: legacyResult.venueId,
      versionId: "legacy",
      status: legacyResult.status,
      categoriesScanned: 0,
      itemsScanned: legacyResult.scanned,
      categoriesDeleted: 0,
      itemsDeleted: legacyResult.deleted,
      itemsMoved: 0,
      fallbackCreated: false,
    });
  }

  return results;
}

async function runSingleVenue(db, options) {
  const results = await cleanupVenue({ db, venueId: options.venueId, options });
  for (const result of results) {
    console.log(
      `[${result.status}] ${result.venueId}/${result.versionId} ` +
        `(items_deleted=${result.itemsDeleted}, items_moved=${result.itemsMoved}, categories_deleted=${result.categoriesDeleted})`,
    );
  }
  return results;
}

async function runAllVenues(db, options) {
  let cursor = null;
  let batches = 0;
  const results = [];

  while (batches < options.maxBatches) {
    let query = db
      .collection("venues")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(options.batchSize);
    if (cursor) query = query.startAfter(cursor);

    // eslint-disable-next-line no-await-in-loop
    const snap = await query.get();
    if (snap.empty) break;

    for (const venueDoc of snap.docs) {
      // eslint-disable-next-line no-await-in-loop
      const venueResults = await cleanupVenue({
        db,
        venueId: venueDoc.id,
        options,
      });
      results.push(...venueResults);
      for (const result of venueResults) {
        console.log(
          `[${result.status}] ${result.venueId}/${result.versionId} ` +
            `(items_deleted=${result.itemsDeleted}, items_moved=${result.itemsMoved}, categories_deleted=${result.categoriesDeleted})`,
        );
      }
    }

    cursor = snap.docs[snap.docs.length - 1];
    batches += 1;
  }

  return results;
}

function summarize(results) {
  const summary = results.reduce(
    (acc, row) => {
      acc.scanned_versions += row.versionId === "legacy" ? 0 : 1;
      acc.items_deleted += asNumber(row.itemsDeleted, 0);
      acc.items_moved += asNumber(row.itemsMoved, 0);
      acc.categories_deleted += asNumber(row.categoriesDeleted, 0);
      if (row.fallbackCreated) acc.fallbacks_created += 1;
      if (row.status === "cleaned") acc.cleaned += 1;
      if (row.status === "dry_run") acc.dry_runs += 1;
      if (row.status === "no_changes") acc.no_changes += 1;
      return acc;
    },
    {
      scanned_versions: 0,
      cleaned: 0,
      dry_runs: 0,
      no_changes: 0,
      items_deleted: 0,
      items_moved: 0,
      categories_deleted: 0,
      fallbacks_created: 0,
    },
  );

  console.log("\nNoise cleanup summary:");
  console.table(summary);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  initAdmin();
  const db = admin.firestore();

  const results = options.runAll
    ? await runAllVenues(db, options)
    : await runSingleVenue(db, options);

  summarize(results);
}

main().catch((error) => {
  console.error("[FATAL] cleanup_menu_import_noise failed:", error);
  process.exitCode = 1;
});

