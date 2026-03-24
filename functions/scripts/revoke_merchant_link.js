#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * revoke_merchant_link.js
 *
 * Usage: node revoke_merchant_link.js <uid>
 *
 * WARNING: Run this script only via Admin SDK with proper credentials.
 * Do NOT revoke by manually deleting merchants/{uid} from Firestore Console —
 * this leaves users/{uid}.merchant_venue_id intact and reopens J1b.
 *
 * Tested against: Firebase Emulator (demo-wain-revoke-script)
 */
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function parseArgs(argv) {
  const opts = {
    uid: "",
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--") && !opts.uid) {
      opts.uid = token.trim();
      continue;
    }
    if (!token.startsWith("--")) continue;

    const [key, inlineValue] = token.split("=");
    const value = inlineValue ?? argv[i + 1];
    const consume = !inlineValue;

    switch (key) {
      case "--uid":
        opts.uid = typeof value === "string" ? value.trim() : "";
        if (consume) i += 1;
        break;
      default:
        console.warn(`[WARN] Unknown argument ignored: ${key}`);
        break;
    }
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

function asVenueId(value) {
  return typeof value === "string" && value.trim() ? value.trim() : "";
}

async function revokeMerchantLink({ uid, db = admin.firestore(), logger = console }) {
  if (!uid || typeof uid !== "string") {
    throw new Error("Missing required uid");
  }

  const userRef = db.collection("users").doc(uid);
  const merchantRef = db.collection("merchants").doc(uid);

  const result = await db.runTransaction(async (t) => {
    const [userDoc, merchantDoc] = await Promise.all([
      t.get(userRef),
      t.get(merchantRef),
    ]);

    const userData = userDoc.data() || {};
    const merchantData = merchantDoc.data() || {};
    const venueId =
      asVenueId(userData.merchant_venue_id) ||
      asVenueId(merchantData.venue_id) ||
      "unknown";

    const hadUserLink = Boolean(asVenueId(userData.merchant_venue_id));
    const hadMerchantDoc = merchantDoc.exists;

    if (userDoc.exists) {
      t.update(userRef, {
        merchant_venue_id: admin.firestore.FieldValue.delete(),
        is_merchant: false,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    t.delete(merchantRef);

    return {
      uid,
      venueId,
      timestamp: new Date().toISOString(),
      result: hadUserLink || hadMerchantDoc ? "revoked" : "noop",
    };
  });

  logger.log(result);
  return result;
}

async function main() {
  initAdmin();
  const opts = parseArgs(process.argv.slice(2));
  await revokeMerchantLink({ uid: opts.uid });
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  revokeMerchantLink,
};
