#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const {
  validateWalletPricingConfig,
  formatIssues,
} = require("../src/wallet_config_utils.js");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const LEVEL = {
  PASS: "PASS",
  WARN: "WARN",
  FAIL: "FAIL",
};

function normalizeLevel(value) {
  if (value === LEVEL.FAIL) return LEVEL.FAIL;
  if (value === LEVEL.WARN) return LEVEL.WARN;
  return LEVEL.PASS;
}

function summarizeLevel(results) {
  let finalLevel = LEVEL.PASS;
  for (const result of results) {
    const level = normalizeLevel(result.level);
    if (level === LEVEL.FAIL) return LEVEL.FAIL;
    if (level === LEVEL.WARN) finalLevel = LEVEL.WARN;
  }
  return finalLevel;
}

function resolveProjectId({
  env = process.env,
  fsModule = fs,
  rootDir = path.resolve(__dirname, "../.."),
}) {
  const envProjectId = env.GOOGLE_CLOUD_PROJECT || env.GCLOUD_PROJECT;
  if (typeof envProjectId === "string" && envProjectId.trim().length > 0) {
    return envProjectId.trim();
  }

  if (typeof env.FIREBASE_CONFIG === "string" && env.FIREBASE_CONFIG.trim().length > 0) {
    try {
      const firebaseConfig = JSON.parse(env.FIREBASE_CONFIG);
      if (typeof firebaseConfig.projectId === "string" && firebaseConfig.projectId.trim().length > 0) {
        return firebaseConfig.projectId.trim();
      }
    } catch {
      // Ignore malformed FIREBASE_CONFIG here; caller gets a project-id-specific error if still unresolved.
    }
  }

  const firebasercPath = path.join(rootDir, ".firebaserc");
  if (fsModule.existsSync(firebasercPath)) {
    try {
      const firebaserc = JSON.parse(fsModule.readFileSync(firebasercPath, "utf8"));
      const defaultProjectId = firebaserc?.projects?.default;
      if (typeof defaultProjectId === "string" && defaultProjectId.trim().length > 0) {
        return defaultProjectId.trim();
      }
    } catch {
      // Ignore parse errors here; caller gets a project-id-specific error if still unresolved.
    }
  }

  return null;
}

function resolveFirebaseToolsConfigPaths(env = process.env) {
  const paths = [];
  if (typeof env.USERPROFILE === "string" && env.USERPROFILE.trim().length > 0) {
    paths.push(path.join(env.USERPROFILE.trim(), ".config", "configstore", "firebase-tools.json"));
  }
  if (typeof env.APPDATA === "string" && env.APPDATA.trim().length > 0) {
    paths.push(path.join(env.APPDATA.trim(), "configstore", "firebase-tools.json"));
  }
  return [...new Set(paths)];
}

function readFirebaseCliAccessToken({
  env = process.env,
  fsModule = fs,
}) {
  if (typeof env.FIREBASE_TOKEN === "string" && env.FIREBASE_TOKEN.trim().length > 0) {
    return env.FIREBASE_TOKEN.trim();
  }

  for (const configPath of resolveFirebaseToolsConfigPaths(env)) {
    if (!fsModule.existsSync(configPath)) {
      continue;
    }

    try {
      const config = JSON.parse(fsModule.readFileSync(configPath, "utf8"));
      const accessToken = config?.tokens?.access_token;
      if (typeof accessToken === "string" && accessToken.trim().length > 0) {
        return accessToken.trim();
      }
    } catch {
      // Continue trying other known config paths.
    }
  }

  throw new Error(
    "Firebase CLI credentials are unavailable. Run `firebase login` or set FIREBASE_TOKEN for read-only verification.",
  );
}

function encodeFirestoreValue(value) {
  if (value === null) {
    return { nullValue: null };
  }
  if (typeof value === "boolean") {
    return { booleanValue: value };
  }
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === "string") {
    return { stringValue: value };
  }
  throw new Error(`Unsupported Firestore value type for REST fallback: ${typeof value}`);
}

function decodeFirestoreValue(value) {
  if (!value || typeof value !== "object") return undefined;
  if ("nullValue" in value) return null;
  if ("stringValue" in value) return value.stringValue;
  if ("booleanValue" in value) return value.booleanValue;
  if ("integerValue" in value) return Number(value.integerValue);
  if ("doubleValue" in value) return value.doubleValue;
  if ("timestampValue" in value) return value.timestampValue;
  if ("mapValue" in value) {
    const fields = value.mapValue?.fields || {};
    return Object.fromEntries(
      Object.entries(fields).map(([key, fieldValue]) => [key, decodeFirestoreValue(fieldValue)]),
    );
  }
  if ("arrayValue" in value) {
    const values = value.arrayValue?.values || [];
    return values.map((entry) => decodeFirestoreValue(entry));
  }
  return undefined;
}

function decodeFirestoreDocument(document) {
  const fields = document?.fields || {};
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, decodeFirestoreValue(value)]),
  );
}

function mapFirestoreOperator(operator) {
  if (operator === "!=") return "NOT_EQUAL";
  if (operator === "==") return "EQUAL";
  throw new Error(`Unsupported Firestore operator for REST fallback: ${operator}`);
}

function createFirestoreRestFallback({ projectId, accessToken, fetchImpl = fetch }) {
  const baseUrl =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

  async function performRequest(url, options = {}) {
    const response = await fetchImpl(url, {
      ...options,
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "x-goog-user-project": projectId,
        ...(options.headers || {}),
      },
    });

    if (response.status === 404) {
      return { status: 404, json: null };
    }

    if (!response.ok) {
      const responseText = await response.text();
      throw new Error(`Firestore REST request failed (${response.status}): ${responseText}`);
    }

    return {
      status: response.status,
      json: await response.json(),
    };
  }

  function createQueryBuilder(collectionName, fieldPath, operator, comparisonValue) {
    let limitValue = null;
    return {
      limit(value) {
        limitValue = value;
        return this;
      },
      async get() {
        const queryUrl = `${baseUrl}:runQuery`;
        const payload = {
          structuredQuery: {
            from: [{ collectionId: collectionName }],
            where: {
              fieldFilter: {
                field: { fieldPath },
                op: mapFirestoreOperator(operator),
                value: encodeFirestoreValue(comparisonValue),
              },
            },
          },
        };
        if (limitValue != null) {
          payload.structuredQuery.limit = limitValue;
        }

        const { json } = await performRequest(queryUrl, {
          method: "POST",
          body: JSON.stringify(payload),
        });
        const envelopes = Array.isArray(json) ? json : [];
        const docs = envelopes
          .filter((entry) => entry?.document)
          .map((entry) => entry.document)
          .map((document) => ({
            exists: true,
            id: document.name.split("/").pop(),
            data: () => decodeFirestoreDocument(document),
          }));

        return {
          empty: docs.length === 0,
          docs,
        };
      },
    };
  }

  return {
    collection(collectionName) {
      return {
        doc(docId) {
          return {
            async get() {
              const { status, json } = await performRequest(
                `${baseUrl}/${collectionName}/${docId}`,
                { method: "GET" },
              );
              if (status === 404) {
                return {
                  exists: false,
                  id: docId,
                  data: () => undefined,
                };
              }
              return {
                exists: true,
                id: docId,
                data: () => decodeFirestoreDocument(json),
              };
            },
          };
        },
        where(fieldPath, operator, value) {
          return createQueryBuilder(collectionName, fieldPath, operator, value);
        },
      };
    },
  };
}

function isCredentialBootstrapError(error) {
  const message = String(error?.message || "");
  return message.includes("Could not load the default credentials") ||
    message.includes("Unable to detect a Project Id") ||
    message.includes("does not exist, or it is not a file") ||
    message.includes("ENOENT: no such file or directory");
}

function tryReadTextFile(fsModule, filePath) {
  try {
    return fsModule.readFileSync(filePath, "utf8");
  } catch {
    return null;
  }
}

function hasScheduledFunction(source, functionName, cadence) {
  const escapedName = functionName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const escapedCadence = cadence.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(
    `${escapedName}[\\s\\S]{0,400}schedule\\((?:\"|')${escapedCadence}(?:\"|')\\)`,
  );
  return pattern.test(source);
}

async function verifyWalletEnv({
  dbInstance = db,
  fsModule = fs,
  logger = console,
  rootDir = path.resolve(__dirname, "../.."),
}) {
  const checks = [];

  const pricingRef = dbInstance.collection("wallet_feature_pricing").doc("default");
  const pricingDoc = await pricingRef.get();
  if (!pricingDoc.exists) {
    checks.push({
      name: "wallet_pricing_document",
      level: LEVEL.FAIL,
      detail: "wallet_feature_pricing/default is missing",
    });
  } else {
    const pricingValidation = validateWalletPricingConfig(pricingDoc.data() || {});
    checks.push({
      name: "wallet_pricing_document",
      level: pricingValidation.valid ? LEVEL.PASS : LEVEL.FAIL,
      detail: pricingValidation.valid
        ? "pricing document is valid"
        : formatIssues(pricingValidation.issues),
    });
  }

  const activeAdminsSnap = await dbInstance.collection("admins")
    .where("active", "!=", false)
    .limit(1)
    .get();
  checks.push({
    name: "admin_fallback_document_policy",
    level: activeAdminsSnap.empty ? LEVEL.WARN : LEVEL.PASS,
    detail: activeAdminsSnap.empty
      ? "No active admin docs found; rely on claims-only until admins/{uid} is seeded"
      : "admins/{uid} fallback has at least one active document",
  });

  const walletMaintenanceBuildPath = path.join(
    rootDir,
    "functions",
    "lib",
    "wallet_runtime_maintenance.js",
  );
  const walletMaintenanceSourcePath = path.join(
    rootDir,
    "functions",
    "src",
    "wallet_runtime_maintenance.ts",
  );
  const firestoreRulesPath = path.join(rootDir, "firestore.rules");
  const storageRulesPath = path.join(rootDir, "storage.rules");
  const indexesPath = path.join(rootDir, "firestore.indexes.json");

  const maintenanceBuildSource = tryReadTextFile(fsModule, walletMaintenanceBuildPath);
  const maintenanceSourceFallback = tryReadTextFile(fsModule, walletMaintenanceSourcePath);
  const maintenanceSource = maintenanceBuildSource ?? maintenanceSourceFallback;
  const maintenanceSourcePathLabel = maintenanceBuildSource
    ? "functions/lib/wallet_runtime_maintenance.js"
    : "functions/src/wallet_runtime_maintenance.ts";

  const rulesSource = fsModule.readFileSync(firestoreRulesPath, "utf8");
  const storageSource = fsModule.readFileSync(storageRulesPath, "utf8");
  const indexesSource = fsModule.readFileSync(indexesPath, "utf8");

  const hasLifecycleSchedule = maintenanceSource != null && hasScheduledFunction(
    maintenanceSource,
    "walletLifecycleMaintenance",
    "every 60 minutes",
  );
  const hasReminderSchedule = maintenanceSource != null && hasScheduledFunction(
    maintenanceSource,
    "walletExpiryReminderMaintenance",
    "every 60 minutes",
  );

  const maintenanceCheckPassed = hasLifecycleSchedule && hasReminderSchedule;
  const maintenanceCheckDetail = maintenanceSource == null
    ? "missing wallet runtime maintenance module in both functions/lib and functions/src"
    : maintenanceCheckPassed
      ? `lifecycle and expiry reminder schedules are declared in ${maintenanceSourcePathLabel}`
      : `missing lifecycle and/or expiry reminder schedules in ${maintenanceSourcePathLabel}`;

  checks.push({
    name: "maintenance_schedules_declared",
    level: maintenanceCheckPassed ? LEVEL.PASS : LEVEL.FAIL,
    detail: maintenanceCheckDetail,
  });

  const hasWalletRules = rulesSource.includes("match /merchant_wallets/{venueId}") &&
    rulesSource.includes("match /merchant_wallet_reports/{venueId}") &&
    rulesSource.includes("match /wallet_audit_events/{eventId}");
  checks.push({
    name: "firestore_wallet_rules",
    level: hasWalletRules ? LEVEL.PASS : LEVEL.FAIL,
    detail: hasWalletRules
      ? "wallet rules sections are present"
      : "wallet rules sections are missing in firestore.rules",
  });

  const hasWalletProofStorageRule = storageSource.includes("match /venues/{venueId}/wallet_topups/{fileName}");
  checks.push({
    name: "storage_wallet_proof_rules",
    level: hasWalletProofStorageRule ? LEVEL.PASS : LEVEL.FAIL,
    detail: hasWalletProofStorageRule
      ? "wallet top-up proof storage rule is present"
      : "wallet top-up proof storage rule is missing",
  });

  let parsedIndexes = null;
  try {
    parsedIndexes = JSON.parse(indexesSource);
  } catch (error) {
    checks.push({
      name: "firestore_indexes_json",
      level: LEVEL.FAIL,
      detail: `failed to parse firestore.indexes.json: ${error.message}`,
    });
  }

  if (parsedIndexes) {
    const indexes = Array.isArray(parsedIndexes.indexes) ? parsedIndexes.indexes : [];
    const hasTopupIndex = indexes.some((index) =>
      index.collectionGroup === "merchant_topup_requests" &&
      Array.isArray(index.fields) &&
      index.fields.some((field) => field.fieldPath === "venue_id") &&
      index.fields.some((field) => field.fieldPath === "created_at"),
    );
    const hasFeaturedIndex = indexes.some((index) =>
      index.collectionGroup === "offers" &&
      Array.isArray(index.fields) &&
      index.fields.some((field) => field.fieldPath === "is_featured") &&
      index.fields.some((field) => field.fieldPath === "featured_until"),
    );
    const hasPromotedIndex = indexes.some((index) =>
      index.collectionGroup === "stories" &&
      Array.isArray(index.fields) &&
      index.fields.some((field) => field.fieldPath === "is_promoted") &&
      index.fields.some((field) => field.fieldPath === "promoted_until"),
    );
    const indexesOk = hasTopupIndex && hasFeaturedIndex && hasPromotedIndex;
    checks.push({
      name: "wallet_indexes_repo_config",
      level: indexesOk ? LEVEL.PASS : LEVEL.FAIL,
      detail: indexesOk
        ? "wallet-related composite indexes found in repo config"
        : "missing one or more wallet-related indexes in firestore.indexes.json",
    });
  }

  const status = summarizeLevel(checks);
  const report = {
    status,
    checks,
    generatedAt: new Date().toISOString(),
  };
  logger.log(JSON.stringify(report, null, 2));
  return report;
}

async function main() {
  let dbInstance = db;
  try {
    await dbInstance.collection("wallet_feature_pricing").doc("default").get();
  } catch (error) {
    if (!isCredentialBootstrapError(error)) {
      throw error;
    }

    const projectId = resolveProjectId({
      env: process.env,
      fsModule: fs,
    });
    if (!projectId) {
      throw new Error(
        "Unable to resolve a Firebase project id. Set GOOGLE_CLOUD_PROJECT/GCLOUD_PROJECT, FIREBASE_CONFIG.projectId, or .firebaserc default before running wallet:verify-env.",
      );
    }

    const accessToken = readFirebaseCliAccessToken({
      env: process.env,
      fsModule: fs,
    });
    console.warn(
      `[wallet-verify] WARN Firebase Admin ADC is unavailable; falling back to Firebase CLI read-only verification for project ${projectId}.`,
    );
    dbInstance = createFirestoreRestFallback({
      projectId,
      accessToken,
      fetchImpl: fetch,
    });
  }

  const report = await verifyWalletEnv({
    dbInstance,
    fsModule: fs,
    logger: console,
  });
  if (report.status === LEVEL.FAIL) {
    process.exit(2);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(JSON.stringify({
      status: LEVEL.FAIL,
      error: error.message,
    }, null, 2));
    process.exit(1);
  });
}

module.exports = {
  LEVEL,
  createFirestoreRestFallback,
  decodeFirestoreDocument,
  decodeFirestoreValue,
  encodeFirestoreValue,
  isCredentialBootstrapError,
  readFirebaseCliAccessToken,
  resolveProjectId,
  summarizeLevel,
  verifyWalletEnv,
};
