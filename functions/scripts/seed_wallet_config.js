#!/usr/bin/env node
/* eslint-disable no-console */

const admin = require("firebase-admin");
const {
  WALLET_PRICING_DEFAULTS,
  parseCliArgs,
  validateWalletPricingConfig,
  formatIssues,
} = require("../src/wallet_config_utils.js");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function buildPricingFromArgs(args) {
  const pricing = {
    ...WALLET_PRICING_DEFAULTS,
  };
  for (const key of Object.keys(WALLET_PRICING_DEFAULTS)) {
    if (args[key] !== undefined) {
      pricing[key] = args[key];
    }
  }
  return pricing;
}

async function seedWalletConfig({
  pricingInput,
  failIfExists = false,
  dryRun = false,
  dbInstance = db,
  logger = console,
}) {
  const validation = validateWalletPricingConfig(pricingInput);
  if (!validation.valid) {
    const message = formatIssues(validation.issues);
    logger.error(`[wallet-config] FAIL validation: ${message}`);
    throw new Error(`Invalid wallet pricing config: ${message}`);
  }

  const pricingRef = dbInstance.collection("wallet_feature_pricing").doc("default");
  const existing = await pricingRef.get();
  if (failIfExists && existing.exists) {
    throw new Error("wallet_feature_pricing/default already exists");
  }

  const payload = {
    ...validation.normalizedPricing,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (!existing.exists) {
    payload.created_at = admin.firestore.FieldValue.serverTimestamp();
  }

  if (dryRun) {
    logger.log("[wallet-config] DRY-RUN: validated payload only");
    return {
      ok: true,
      mode: "dry-run",
      existed: existing.exists,
      payloadPreview: validation.normalizedPricing,
    };
  }

  await pricingRef.set(payload, { merge: true });
  logger.log("[wallet-config] PASS seeded wallet_feature_pricing/default");
  return {
    ok: true,
    mode: "write",
    existed: existing.exists,
    payload: validation.normalizedPricing,
  };
}

async function main() {
  const args = parseCliArgs(process.argv.slice(2));
  const pricingInput = buildPricingFromArgs(args);
  const failIfExists = args["fail-if-exists"] === true;
  const dryRun = args["dry-run"] === true;
  const result = await seedWalletConfig({
    pricingInput,
    failIfExists,
    dryRun,
    dbInstance: db,
    logger: console,
  });
  console.log(JSON.stringify(result, null, 2));
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[wallet-config] FAIL ${error.message}`);
    process.exit(1);
  });
}

module.exports = {
  seedWalletConfig,
  buildPricingFromArgs,
};
