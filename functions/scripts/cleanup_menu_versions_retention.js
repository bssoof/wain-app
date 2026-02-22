#!/usr/bin/env node
/*
 * Menu versions retention cleanup runner.
 *
 * Policy:
 * - Keep active version.
 * - Keep current draft version.
 * - Keep latest N archived versions (default: 5).
 * - Delete older archived versions (and their nested docs).
 *
 * Usage:
 *   npm run menu:cleanup
 *   npm run menu:cleanup -- --dry-run
 *   npm run menu:cleanup -- --venue azure_01
 *   npm run menu:cleanup -- --keep-archived 5 --retention-days 30 --run-all
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const DAY_MS = 24 * 60 * 60 * 1000;
const DEFAULT_KEEP_ARCHIVED = 5;
const DEFAULT_RETENTION_DAYS = 30;
const DEFAULT_BATCH_SIZE = 20;
const DEFAULT_MAX_BATCHES = 1;
const DELETE_BATCH_SIZE = 350;

function printHelp() {
  console.log(`
Menu versions retention cleanup

Options:
  --venue <id>            Clean a single venue id
  --keep-archived <n>     Keep latest archived versions (default: ${DEFAULT_KEEP_ARCHIVED})
  --retention-days <n>    Age threshold for reporting (default: ${DEFAULT_RETENTION_DAYS})
  --batch-size <n>        Venues per page (default: ${DEFAULT_BATCH_SIZE})
  --max-batches <n>       Number of pages to process (default: ${DEFAULT_MAX_BATCHES})
  --run-all               Process all pages
  --dry-run               Compute only, no writes
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

function timestampToMs(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (typeof value.seconds === "number") return value.seconds * 1000;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function versionSortMs(data) {
  return Math.max(
    timestampToMs(data.published_at),
    timestampToMs(data.archived_at),
    timestampToMs(data.updated_at),
    timestampToMs(data.created_at),
  );
}

function parseArgs(argv) {
  const opts = {
    venueId: "",
    keepArchived: DEFAULT_KEEP_ARCHIVED,
    retentionDays: DEFAULT_RETENTION_DAYS,
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
    const consume = !inlineValue;

    switch (key) {
      case "--help":
        printHelp();
        process.exit(0);
        break;
      case "--venue":
        opts.venueId = asString(value);
        if (consume) i += 1;
        break;
      case "--keep-archived":
        opts.keepArchived = Math.max(0, asNumber(value, DEFAULT_KEEP_ARCHIVED));
        if (consume) i += 1;
        break;
      case "--retention-days":
        opts.retentionDays = Math.max(0, asNumber(value, DEFAULT_RETENTION_DAYS));
        if (consume) i += 1;
        break;
      case "--batch-size":
        opts.batchSize = Math.max(1, asNumber(value, DEFAULT_BATCH_SIZE));
        if (consume) i += 1;
        break;
      case "--max-batches":
        opts.maxBatches = Math.max(1, asNumber(value, DEFAULT_MAX_BATCHES));
        if (consume) i += 1;
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

  return opts;
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

async function countCollectionDocs(collectionRef) {
  try {
    const aggregate = await collectionRef.count().get();
    return aggregate.data().count;
  } catch {
    return (await collectionRef.get()).size;
  }
}

async function deleteCollectionDocs(collectionRef, dryRun) {
  let deleted = 0;
  while (true) {
    const snap = await collectionRef.limit(DELETE_BATCH_SIZE).get();
    if (snap.empty) break;

    deleted += snap.size;
    if (!dryRun) {
      const batch = collectionRef.firestore.batch();
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }
    if (snap.size < DELETE_BATCH_SIZE) break;
  }
  return deleted;
}

async function deleteVersionTree(versionRef, dryRun) {
  const collections = await versionRef.listCollections();
  const deletedByCollection = {};

  for (const subCollection of collections) {
    const deletedCount = dryRun
      ? await countCollectionDocs(subCollection)
      : await deleteCollectionDocs(subCollection, dryRun);
    deletedByCollection[subCollection.id] = deletedCount;
  }

  if (!dryRun) {
    await versionRef.delete();
  }

  return deletedByCollection;
}

async function cleanupVenueMenuVersions({
  db,
  venueId,
  keepArchived,
  retentionDays,
  dryRun,
  nowMs = Date.now(),
}) {
  const venueRef = db.collection("venues").doc(venueId);
  const configRef = venueRef.collection("menu_config").doc("main");
  const versionsRef = venueRef.collection("menu_versions");

  const [venueSnap, configSnap, archivedSnap] = await Promise.all([
    venueRef.get(),
    configRef.get(),
    versionsRef.where("status", "==", "archived").get(),
  ]);

  if (!venueSnap.exists) {
    return {
      venueId,
      status: "missing_venue",
      scannedArchived: 0,
      deletedVersions: 0,
      deletedItemsCount: 0,
      deletedCategoriesCount: 0,
    };
  }

  const activeVersionId = asString(venueSnap.data()?.active_menu_version_id);
  const draftVersionId = asString(configSnap.data()?.draft_version_id);
  const cutoffMs = nowMs - Math.max(0, retentionDays) * DAY_MS;

  const archivedVersions = archivedSnap.docs
    .map((doc) => ({
      id: doc.id,
      ref: doc.ref,
      sortMs: versionSortMs(doc.data() || {}),
    }))
    .sort((a, b) => (b.sortMs - a.sortMs) || a.id.localeCompare(b.id));

  const keepSet = new Set(archivedVersions.slice(0, keepArchived).map((v) => v.id));
  const deletable = archivedVersions.filter((version) => (
    !keepSet.has(version.id) &&
    version.id !== activeVersionId &&
    version.id !== draftVersionId
  ));

  let deletedVersions = 0;
  let deletedItemsCount = 0;
  let deletedCategoriesCount = 0;
  let oldArchivedCount = 0;

  for (const version of archivedVersions) {
    if (version.sortMs > 0 && version.sortMs <= cutoffMs) oldArchivedCount += 1;
  }

  for (const version of deletable) {
    const deletedByCollection = await deleteVersionTree(version.ref, dryRun);
    deletedVersions += 1;
    deletedItemsCount += asNumber(deletedByCollection.items, 0);
    deletedCategoriesCount += asNumber(deletedByCollection.categories, 0);
  }

  return {
    venueId,
    status: dryRun ? "dry_run" : "cleaned",
    scannedArchived: archivedVersions.length,
    keptArchived: Math.min(archivedVersions.length, keepArchived),
    oldArchivedCount,
    deletedVersions,
    deletedItemsCount,
    deletedCategoriesCount,
  };
}

async function runMenuVersionRetentionCleanup({
  db,
  venueId = "",
  keepArchived = DEFAULT_KEEP_ARCHIVED,
  retentionDays = DEFAULT_RETENTION_DAYS,
  dryRun = false,
  batchSize = DEFAULT_BATCH_SIZE,
  maxBatches = DEFAULT_MAX_BATCHES,
  runAll = false,
}) {
  const effectiveMaxBatches = runAll ? Number.POSITIVE_INFINITY : Math.max(1, maxBatches);
  const results = [];

  if (venueId) {
    const result = await cleanupVenueMenuVersions({
      db,
      venueId,
      keepArchived,
      retentionDays,
      dryRun,
    });
    results.push(result);
  } else {
    let cursorId = "";
    let batchesDone = 0;
    let hasMore = true;

    while (hasMore && batchesDone < effectiveMaxBatches) {
      let query = db.collection("venues")
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(batchSize);

      if (cursorId) {
        query = query.startAfter(cursorId);
      }

      const snap = await query.get();
      if (snap.empty) break;
      if (snap.size < batchSize) hasMore = false;
      batchesDone += 1;

      for (const venueDoc of snap.docs) {
        cursorId = venueDoc.id;
        const result = await cleanupVenueMenuVersions({
          db,
          venueId: venueDoc.id,
          keepArchived,
          retentionDays,
          dryRun,
        });
        results.push(result);
      }
    }
  }

  const summary = {
    status: "completed",
    dryRun,
    scannedVenues: results.length,
    deletedVersions: results.reduce((sum, r) => sum + asNumber(r.deletedVersions, 0), 0),
    deletedItemsCount: results.reduce((sum, r) => sum + asNumber(r.deletedItemsCount, 0), 0),
    deletedCategoriesCount: results.reduce((sum, r) => sum + asNumber(r.deletedCategoriesCount, 0), 0),
    venuesWithDeletes: results.filter((r) => asNumber(r.deletedVersions, 0) > 0).length,
    results,
  };

  return summary;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  initAdmin();

  const db = admin.firestore();
  const summary = await runMenuVersionRetentionCleanup({
    db,
    venueId: opts.venueId,
    keepArchived: opts.keepArchived,
    retentionDays: opts.retentionDays,
    dryRun: opts.dryRun,
    batchSize: opts.batchSize,
    maxBatches: opts.maxBatches,
    runAll: opts.runAll,
  });

  for (const row of summary.results) {
    console.log(
      `[${row.status}] ${row.venueId} ` +
        `(archived=${row.scannedArchived}, deleted_versions=${row.deletedVersions}, ` +
        `deleted_items=${row.deletedItemsCount}, deleted_categories=${row.deletedCategoriesCount})`,
    );
  }

  console.log("\nCleanup summary:");
  console.table({
    status: summary.status,
    dry_run: summary.dryRun,
    scanned_venues: summary.scannedVenues,
    deleted_versions: summary.deletedVersions,
    deleted_items_count: summary.deletedItemsCount,
    deleted_categories_count: summary.deletedCategoriesCount,
    venues_with_deletes: summary.venuesWithDeletes,
  });
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      const message = error instanceof Error ? error.stack || error.message : String(error);
      console.error(message);
      process.exit(1);
    });
}

module.exports = {
  cleanupVenueMenuVersions,
  runMenuVersionRetentionCleanup,
};
