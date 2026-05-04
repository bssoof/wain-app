const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT =
  process.env.GCLOUD_PROJECT || "demo-wain-wallet-config-scripts";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  validateWalletPricingConfig,
  WALLET_PRICING_DEFAULTS,
} = require("../../src/wallet_config_utils.js");
const { seedWalletConfig } = require("../../scripts/seed_wallet_config.js");
const {
  verifyWalletEnv,
  LEVEL,
  isCredentialBootstrapError,
  resolveProjectId,
  readFirebaseCliAccessToken,
} = require("../../scripts/verify_wallet_env.js");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
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

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("wallet pricing validation rejects zero-only config", async () => {
  const invalid = {
    ...WALLET_PRICING_DEFAULTS,
    story_promote_1d: 0,
    story_promote_3d: 0,
    story_promote_7d: 0,
    offer_pin_1d: 0,
    offer_pin_3d: 0,
    offer_pin_7d: 0,
  };
  const result = validateWalletPricingConfig(invalid);
  assert.equal(result.valid, false);
  assert.ok(result.issues.some((issue) => issue.code === "zero_only_pricing"));
});

test("seedWalletConfig writes normalized pricing document", async () => {
  const seeded = await seedWalletConfig({
    pricingInput: {
      ...WALLET_PRICING_DEFAULTS,
      story_promote_1d: "3.219",
      offer_pin_1d: "4.889",
      currency: "ils",
    },
    dbInstance: db,
    logger: { log() {}, error() {} },
  });
  assert.equal(seeded.ok, true);
  const pricingDoc = await db.collection("wallet_feature_pricing").doc("default").get();
  assert.equal(pricingDoc.exists, true);
  assert.equal(pricingDoc.data().story_promote_1d, 3.22);
  assert.equal(pricingDoc.data().offer_pin_1d, 4.89);
  assert.equal(pricingDoc.data().currency, "ILS");
});

test("verifyWalletEnv fails when pricing document is missing", async () => {
  const logs = [];
  const report = await verifyWalletEnv({
    dbInstance: db,
    logger: {
      log(value) {
        logs.push(value);
      },
    },
  });
  assert.equal(report.status, LEVEL.FAIL);
  assert.ok(report.checks.some((check) =>
    check.name === "wallet_pricing_document" && check.level === LEVEL.FAIL));
  assert.ok(logs.length > 0);
});

test("verifyWalletEnv passes pricing check with valid setup", async () => {
  await db.collection("wallet_feature_pricing").doc("default").set({
    ...WALLET_PRICING_DEFAULTS,
    created_at: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });
  await db.collection("admins").doc("admin-a").set({
    active: true,
    created_at: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });

  const report = await verifyWalletEnv({
    dbInstance: db,
    logger: { log() {} },
  });
  const pricingCheck = report.checks.find((check) => check.name === "wallet_pricing_document");
  assert.equal(pricingCheck.level, LEVEL.PASS);
  assert.notEqual(report.status, LEVEL.FAIL);
});

test("verifyWalletEnv reads maintenance schedule from wallet_runtime_maintenance module", async () => {
  await db.collection("wallet_feature_pricing").doc("default").set({
    ...WALLET_PRICING_DEFAULTS,
    created_at: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });
  await db.collection("admins").doc("admin-a").set({
    active: true,
    created_at: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });

  const fs = require("fs");
  const fakeFsModule = {
    readFileSync(filePath, encoding) {
      const normalizedPath = String(filePath).replace(/\\/g, "/");
      if (normalizedPath.endsWith("functions/lib/wallet_runtime_maintenance.js")) {
        return [
          "exports.walletLifecycleMaintenance = functions.pubsub.schedule(\"every 60 minutes\").onRun(async () => null);",
          "exports.walletExpiryReminderMaintenance = functions.pubsub.schedule(\"every 60 minutes\").onRun(async () => null);",
        ].join("\n");
      }
      if (normalizedPath.endsWith("functions/src/index.ts")) {
        return "// intentionally does not include maintenance schedules";
      }
      return fs.readFileSync(filePath, encoding);
    },
  };

  const report = await verifyWalletEnv({
    dbInstance: db,
    fsModule: fakeFsModule,
    logger: { log() {} },
  });

  const maintenanceCheck = report.checks.find((check) =>
    check.name === "maintenance_schedules_declared");
  assert.equal(maintenanceCheck.level, LEVEL.PASS);
  assert.match(maintenanceCheck.detail, /wallet_runtime_maintenance/);
});

test("verifyWalletEnv fails when wallet indexes are missing", async () => {
  await db.collection("wallet_feature_pricing").doc("default").set({
    ...WALLET_PRICING_DEFAULTS,
    created_at: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });
  await db.collection("admins").doc("admin-a").set({
    active: true,
    created_at: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });

  const fs = require("fs");
  const fakeFsModule = {
    readFileSync(filePath, encoding) {
      if (String(filePath).endsWith("firestore.indexes.json")) {
        return JSON.stringify({ indexes: [] });
      }
      return fs.readFileSync(filePath, encoding);
    },
  };

  const report = await verifyWalletEnv({
    dbInstance: db,
    fsModule: fakeFsModule,
    logger: { log() {} },
  });
  const indexesCheck = report.checks.find((check) => check.name === "wallet_indexes_repo_config");
  assert.equal(indexesCheck.level, LEVEL.FAIL);
  assert.equal(report.status, LEVEL.FAIL);
});

test("resolveProjectId falls back to .firebaserc default project", () => {
  const fakeFsModule = {
    existsSync(filePath) {
      return String(filePath).endsWith(".firebaserc");
    },
    readFileSync(filePath) {
      assert.match(String(filePath), /\.firebaserc$/);
      return JSON.stringify({
        projects: {
          default: "wain-d2e28",
        },
      });
    },
  };

  const projectId = resolveProjectId({
    env: {},
    fsModule: fakeFsModule,
    rootDir: "C:/fake-root",
  });

  assert.equal(projectId, "wain-d2e28");
});

test("readFirebaseCliAccessToken reads token from firebase-tools config", () => {
  const fakeFsModule = {
    existsSync(filePath) {
      return String(filePath).includes("firebase-tools.json");
    },
    readFileSync(filePath) {
      assert.match(String(filePath), /firebase-tools\.json$/);
      return JSON.stringify({
        tokens: {
          access_token: "token-from-config",
        },
      });
    },
  };

  const accessToken = readFirebaseCliAccessToken({
    env: {
      USERPROFILE: "C:/Users/tester",
      APPDATA: "C:/Users/tester/AppData/Roaming",
    },
    fsModule: fakeFsModule,
  });

  assert.equal(accessToken, "token-from-config");
});

test("isCredentialBootstrapError matches missing service-account file errors", () => {
  const missingFileError = new Error(
    "The file at C:\\path\\to\\service-account.json does not exist, or it is not a file. ENOENT: no such file or directory, lstat 'C:\\path'",
  );

  assert.equal(isCredentialBootstrapError(missingFileError), true);
});
