#!/usr/bin/env node
/*
 * Legacy menu migration runner (one-off, resumable, idempotent).
 *
 * Usage examples:
 *   npm run menu:migrate
 *   npm run menu:migrate -- --resume run_20260217_101500
 *   npm run menu:migrate -- --from-venue azure_01 --run-all
 *   npm run menu:migrate -- --batch-size 20 --max-batches 3
 *   npm run menu:migrate -- --dry-run --run-all
 *
 * Defaults:
 *   batch-size = 20 venues
 *   max-batches = 1 (single cycle), then resume in next run
 */

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const admin = require("firebase-admin");

const VERSION_ID = "migrated_v1";
const DEFAULT_BATCH_SIZE = 20;
const DEFAULT_MAX_BATCHES = 1;
const MAX_BATCH_WRITES = 400;

function printHelp() {
  console.log(`
Legacy menu migration runner

Options:
  --run-id <id>         Explicit run id (new run)
  --resume <runId>      Resume existing run id
  --from-venue <id>     Start from this venue id (inclusive)
  --batch-size <n>      Venues per Firestore page (default: ${DEFAULT_BATCH_SIZE})
  --max-batches <n>     Number of pages to process (default: ${DEFAULT_MAX_BATCHES})
  --run-all             Process until all venues are done
  --dry-run             Read/compute only, no writes
  --help                Show this help
`);
}

function parseArgs(argv) {
  const opts = {
    runId: null,
    resume: null,
    fromVenue: null,
    batchSize: DEFAULT_BATCH_SIZE,
    maxBatches: DEFAULT_MAX_BATCHES,
    runAll: false,
    dryRun: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;

    const [key, inlineValue] = token.split("=");
    const value = inlineValue ?? argv[i + 1];

    switch (key) {
      case "--help":
        printHelp();
        process.exit(0);
        break;
      case "--run-id":
        opts.runId = value;
        if (!inlineValue) i += 1;
        break;
      case "--resume":
        opts.resume = value;
        if (!inlineValue) i += 1;
        break;
      case "--from-venue":
        opts.fromVenue = value;
        if (!inlineValue) i += 1;
        break;
      case "--batch-size":
        opts.batchSize = Math.max(1, Number.parseInt(value, 10) || DEFAULT_BATCH_SIZE);
        if (!inlineValue) i += 1;
        break;
      case "--max-batches":
        opts.maxBatches = Math.max(1, Number.parseInt(value, 10) || DEFAULT_MAX_BATCHES);
        if (!inlineValue) i += 1;
        break;
      case "--run-all":
        opts.runAll = true;
        break;
      case "--dry-run":
        opts.dryRun = true;
        break;
      default:
        console.warn(`[WARN] Unknown argument ignored: ${key}`);
        break;
    }
  }

  if (opts.runAll) {
    opts.maxBatches = Number.POSITIVE_INFINITY;
  }

  if (opts.resume && opts.runId) {
    throw new Error("Use either --resume or --run-id, not both.");
  }

  return opts;
}

function nowIsoCompact() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, "0");
  return (
    `${d.getUTCFullYear()}${p(d.getUTCMonth() + 1)}${p(d.getUTCDate())}_` +
    `${p(d.getUTCHours())}${p(d.getUTCMinutes())}${p(d.getUTCSeconds())}`
  );
}

function asString(value) {
  if (typeof value !== "string") return null;
  const t = value.trim();
  return t.length ? t : null;
}

function asNumber(value, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeCategoryKey(value) {
  const raw = asString(value) ?? "other";
  const safe = raw.toLowerCase().replace(/[^a-z0-9_]+/g, "_");
  const compact = safe.replace(/_+/g, "_").replace(/^_|_$/g, "");
  return compact || "other";
}

function humanizeCategoryKey(key) {
  const text = key.replace(/_/g, " ").trim();
  if (!text) return "Other";
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function venueTypeFromDoc(venueData) {
  const explicit = asString(venueData.venue_type);
  if (explicit) return explicit.toLowerCase();
  const categories = Array.isArray(venueData.categories) ? venueData.categories : [];
  if (categories.length > 0 && asString(categories[0])) {
    return categories[0].trim().toLowerCase();
  }
  return "other";
}

const DEFAULT_CATEGORY_KEYS_BY_TYPE = {
  cafe: ["hot_drinks", "cold_drinks", "juices", "hookah", "desserts", "snacks"],
  restaurant: ["appetizers", "main_courses", "grills", "soups", "desserts", "drinks"],
  fast_food: ["burgers", "shawarma", "pizza", "sandwiches", "sides", "drinks"],
  sweets: ["eastern_sweets", "western_sweets", "ice_cream", "drinks"],
  juice_bar: ["fresh_juices", "smoothies", "cocktails", "milkshakes"],
  other: ["food", "drinks", "other"],
};

function defaultCategoriesForVenueType(venueType) {
  const keys = DEFAULT_CATEGORY_KEYS_BY_TYPE[venueType] ?? DEFAULT_CATEGORY_KEYS_BY_TYPE.other;
  return keys.map((key, idx) => ({
    id: key,
    data: {
      key,
      name_ar: humanizeCategoryKey(key),
      name_en: humanizeCategoryKey(key),
      sort_order: idx + 1,
      is_custom: false,
    },
  }));
}

function buildMigrationHash(legacyDocs) {
  const h = crypto.createHash("sha1");
  for (const doc of legacyDocs) {
    const data = doc.data() || {};
    const line = [
      doc.id,
      String(asNumber(data.sort_order, 0)),
      String(asNumber(data.price, 0)),
      String(normalizeCategoryKey(data.category)),
      String(asString(data.name_ar) ?? ""),
      String(asString(data.name_en) ?? ""),
    ].join("|");
    h.update(line);
  }
  return h.digest("hex");
}

function normalizeLegacyItemsAndCategories(legacyDocs, venueType) {
  const defaultCategorySet = new Set(
    (DEFAULT_CATEGORY_KEYS_BY_TYPE[venueType] ?? DEFAULT_CATEGORY_KEYS_BY_TYPE.other).map((v) => v.toLowerCase()),
  );
  const categoryMap = new Map();
  const normalizedItems = [];

  legacyDocs.forEach((doc, idx) => {
    const raw = doc.data() || {};
    const category = normalizeCategoryKey(raw.category);

    if (!categoryMap.has(category)) {
      const sortOrder = categoryMap.size + 1;
      categoryMap.set(category, {
        id: category,
        data: {
          key: category,
          name_ar: humanizeCategoryKey(category),
          name_en: humanizeCategoryKey(category),
          sort_order: sortOrder,
          is_custom: !defaultCategorySet.has(category),
        },
      });
    }

    normalizedItems.push({
      id: doc.id,
      data: {
        ...raw,
        category,
        sort_order: asNumber(raw.sort_order, idx),
        price: asNumber(raw.price, 0),
        currency: asString(raw.currency) ?? "ILS",
        is_available: typeof raw.is_available === "boolean" ? raw.is_available : true,
        is_featured: typeof raw.is_featured === "boolean" ? raw.is_featured : false,
        source: "migration",
      },
    });
  });

  if (categoryMap.size === 0) {
    for (const category of defaultCategoriesForVenueType(venueType)) {
      categoryMap.set(category.id, category);
    }
  }

  const categories = Array.from(categoryMap.values()).sort(
    (a, b) => asNumber(a.data.sort_order, 0) - asNumber(b.data.sort_order, 0),
  );

  return { categories, items: normalizedItems };
}

function chunkArray(items, chunkSize) {
  const chunks = [];
  for (let i = 0; i < items.length; i += chunkSize) {
    chunks.push(items.slice(i, i + chunkSize));
  }
  return chunks;
}

function initAdmin() {
  if (admin.apps.length) return;

  const serviceAccountPath = path.resolve(__dirname, "../../service-account-key.json");
  if (fs.existsSync(serviceAccountPath)) {
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    return;
  }

  admin.initializeApp();
}

async function writeRunCheckpoint(runRef, payload, dryRun) {
  if (dryRun) return;
  await runRef.set(
    {
      ...payload,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function migrateVenue({
  db,
  runId,
  venueDoc,
  dryRun,
}) {
  const venueId = venueDoc.id;
  const venueData = venueDoc.data() || {};
  const venueType = venueTypeFromDoc(venueData);

  const venueRef = db.collection("venues").doc(venueId);
  const configRef = venueRef.collection("menu_config").doc("main");
  const versionRef = venueRef.collection("menu_versions").doc(VERSION_ID);
  const legacyItemsRef = venueRef.collection("menu_items");
  const versionItemsRef = versionRef.collection("items");
  const versionCategoriesRef = versionRef.collection("categories");

  const legacySnap = await legacyItemsRef.orderBy("sort_order").get();
  const expectedItemsCount = legacySnap.size;
  const legacyDocs = legacySnap.docs;
  const migrationHash = buildMigrationHash(legacyDocs);

  const [configSnap, versionSnap] = await Promise.all([
    configRef.get(),
    versionRef.get(),
  ]);

  const existingVersion = versionSnap.data() || {};
  const alreadyDone =
    versionSnap.exists &&
    asString(existingVersion.migration_hash) === migrationHash &&
    asNumber(existingVersion.expected_items_count, -1) === expectedItemsCount &&
    asString(existingVersion.status) === "active";

  if (alreadyDone) {
    if (!dryRun) {
      await Promise.all([
        venueRef.set(
          {
            active_menu_version_id: VERSION_ID,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
        configRef.set(
          {
            migration_status: "done",
            last_migration_run_id: runId,
            venue_type: venueType,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
      ]);
    }

    return {
      venueId,
      status: "skipped",
      expectedItemsCount,
      migratedItemsCount: expectedItemsCount,
      reason: "already_done",
    };
  }

  if (dryRun) {
    return {
      venueId,
      status: "dry_run",
      expectedItemsCount,
      migratedItemsCount: expectedItemsCount,
      reason: "computed_only",
    };
  }

  await configRef.set(
    {
      migration_status: "in_progress",
      last_migration_run_id: runId,
      venue_type: venueType,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  const normalized = normalizeLegacyItemsAndCategories(legacyDocs, venueType);
  const categories = normalized.categories;
  const items = normalized.items;

  const writeOps = [];
  writeOps.push({
    ref: versionRef,
    data: {
      status: "draft",
      source: "migration",
      created_by: "migration_runner",
      created_at: existingVersion.created_at ?? admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      expected_items_count: expectedItemsCount,
      migrated_items_count: items.length,
      migration_hash: migrationHash,
      last_counted_at: admin.firestore.FieldValue.serverTimestamp(),
    },
  });

  for (const category of categories) {
    writeOps.push({
      ref: versionCategoriesRef.doc(category.id),
      data: {
        ...category.data,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    });
  }

  for (const item of items) {
    writeOps.push({
      ref: versionItemsRef.doc(item.id),
      data: {
        ...item.data,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    });
  }

  for (const chunk of chunkArray(writeOps, MAX_BATCH_WRITES)) {
    const batch = db.batch();
    for (const op of chunk) {
      batch.set(op.ref, op.data, { merge: true });
    }
    await batch.commit();
  }

  const [migratedItemsSnap, categorySnap] = await Promise.all([
    versionItemsRef.get(),
    versionCategoriesRef.get(),
  ]);
  const migratedItemsCount = migratedItemsSnap.size;
  const migratedCategoriesCount = categorySnap.size;

  if (migratedItemsCount !== expectedItemsCount) {
    const message = `verification_failed: expected=${expectedItemsCount}, migrated=${migratedItemsCount}`;
    await configRef.set(
      {
        migration_status: "failed",
        migration_error: message,
        last_migration_run_id: runId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    throw new Error(message);
  }

  await db.runTransaction(async (tx) => {
    const [txVenueSnap, txVersionSnap, txConfigSnap] = await Promise.all([
      tx.get(venueRef),
      tx.get(versionRef),
      tx.get(configRef),
    ]);

    if (!txVersionSnap.exists) {
      throw new Error("migration version missing during activation");
    }

    const currentActive = asString(txVenueSnap.data()?.active_menu_version_id);
    if (currentActive && currentActive !== VERSION_ID) {
      const currentActiveRef = venueRef.collection("menu_versions").doc(currentActive);
      const currentActiveSnap = await tx.get(currentActiveRef);
      if (currentActiveSnap.exists) {
        tx.set(
          currentActiveRef,
          {
            status: "archived",
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    }

    tx.set(
      versionRef,
      {
        status: "active",
        source: "migration",
        published_at: txVersionSnap.data().published_at ?? admin.firestore.FieldValue.serverTimestamp(),
        item_count: migratedItemsCount,
        category_count: migratedCategoriesCount,
        expected_items_count: expectedItemsCount,
        migrated_items_count: migratedItemsCount,
        verified_at: admin.firestore.FieldValue.serverTimestamp(),
        migration_hash: migrationHash,
        last_counted_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(
      venueRef,
      {
        active_menu_version_id: VERSION_ID,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(
      configRef,
      {
        draft_version_id: txConfigSnap.data()?.draft_version_id ?? null,
        migration_status: "done",
        last_migration_run_id: runId,
        venue_type: venueType,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return {
    venueId,
    status: "migrated",
    expectedItemsCount,
    migratedItemsCount,
    categoryCount: migratedCategoriesCount,
  };
}

async function run() {
  const opts = parseArgs(process.argv.slice(2));
  initAdmin();

  const db = admin.firestore();
  const runId = opts.resume || opts.runId || `run_${nowIsoCompact()}`;
  const runRef = db.collection("menu_migration_runs").doc(runId);
  const runSnap = await runRef.get();
  const existing = runSnap.data() || {};

  if (opts.resume && !runSnap.exists) {
    throw new Error(`Run "${runId}" not found for --resume.`);
  }

  if (!opts.resume && runSnap.exists) {
    throw new Error(`Run "${runId}" already exists. Use --resume ${runId} instead.`);
  }

  if (!opts.dryRun && !runSnap.exists) {
    await runRef.set({
      run_id: runId,
      status: "running",
      started_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      batch_size: opts.batchSize,
      max_batches: Number.isFinite(opts.maxBatches) ? opts.maxBatches : null,
      dry_run: opts.dryRun,
      from_venue: opts.fromVenue ?? null,
      processed_count: 0,
      failed_count: 0,
      skipped_count: 0,
      last_processed_venue_id: null,
    });
  } else if (!opts.dryRun) {
    await runRef.set(
      {
        status: "running",
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  let processedCount = asNumber(existing.processed_count, 0);
  let failedCount = asNumber(existing.failed_count, 0);
  let skippedCount = asNumber(existing.skipped_count, 0);

  let cursorId = null;
  let startMode = "none"; // none | after | at
  if (opts.fromVenue) {
    cursorId = opts.fromVenue;
    startMode = "at";
  } else if (opts.resume && asString(existing.last_processed_venue_id)) {
    cursorId = asString(existing.last_processed_venue_id);
    startMode = "after";
  }

  let hasMore = true;
  let batchesDone = 0;

  while (hasMore && batchesDone < opts.maxBatches) {
    let query = db.collection("venues")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(opts.batchSize);

    if (cursorId && startMode === "at") {
      query = query.startAt(cursorId);
    } else if (cursorId && startMode === "after") {
      query = query.startAfter(cursorId);
    }

    const snap = await query.get();
    if (snap.empty) {
      hasMore = false;
      break;
    }
    if (snap.size < opts.batchSize) {
      // Last page reached (fewer docs than requested page size).
      hasMore = false;
    }

    batchesDone += 1;

    for (const venueDoc of snap.docs) {
      const venueId = venueDoc.id;
      try {
        const result = await migrateVenue({
          db,
          runId,
          venueDoc,
          dryRun: opts.dryRun,
        });

        if (result.status === "skipped" || result.status === "dry_run") {
          skippedCount += 1;
        } else {
          processedCount += 1;
        }

        console.log(
          `[OK] ${venueId} -> ${result.status} ` +
            `(expected=${result.expectedItemsCount}, migrated=${result.migratedItemsCount})`,
        );
      } catch (error) {
        failedCount += 1;
        const message = error instanceof Error ? error.message : String(error);
        console.error(`[FAIL] ${venueId}: ${message}`);

        if (!opts.dryRun) {
          await venueDoc.ref.collection("menu_config").doc("main").set(
            {
              migration_status: "failed",
              migration_error: message,
              last_migration_run_id: runId,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }
      }

      cursorId = venueId;
      startMode = "after";

      await writeRunCheckpoint(
        runRef,
        {
          run_id: runId,
          processed_count: processedCount,
          failed_count: failedCount,
          skipped_count: skippedCount,
          last_processed_venue_id: cursorId,
          last_batch_no: batchesDone,
        },
        opts.dryRun,
      );
    }
  }

  const finished = !hasMore;
  const status = finished ? "completed" : "paused";
  const summary = {
    run_id: runId,
    status,
    processed_count: processedCount,
    failed_count: failedCount,
    skipped_count: skippedCount,
    last_processed_venue_id: cursorId,
  };

  if (!opts.dryRun) {
    await runRef.set(
      {
        ...summary,
        completed_at: finished ? admin.firestore.FieldValue.serverTimestamp() : null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  console.log("\nMigration summary:");
  console.table(summary);
}

run()
  .then(() => process.exit(0))
  .catch((error) => {
    const message = error instanceof Error ? error.stack || error.message : String(error);
    console.error(message);
    process.exit(1);
  });
