#!/usr/bin/env node

/**
 * Operational admin script for reviewing merchant top-up requests.
 *
 * Usage:
 *   node scripts/review_topup_request.js --requestId=<id> --decision=credit --adminUid=<uid> [--adminNote="..."]
 *   node scripts/review_topup_request.js --requestId=<id> --decision=reject --adminUid=<uid> [--adminNote="..."]
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function parseArgs(argv) {
  const args = {};
  for (const token of argv.slice(2)) {
    if (!token.startsWith("--")) continue;
    const [rawKey, ...rawValue] = token.slice(2).split("=");
    const key = rawKey.trim();
    const value = rawValue.join("=").trim();
    if (key) args[key] = value;
  }
  return args;
}

function roundMoney(value) {
  return Math.round(value * 100) / 100;
}

async function run() {
  const args = parseArgs(process.argv);
  const requestId = args.requestId;
  const decision = args.decision;
  const adminUid = args.adminUid;
  const adminNote = args.adminNote || null;

  if (!requestId || !adminUid || !["credit", "reject"].includes(decision)) {
    throw new Error(
      "Invalid arguments. Required: --requestId, --decision=(credit|reject), --adminUid",
    );
  }

  const requestRef = db.collection("merchant_topup_requests").doc(requestId);
  const adminRef = db.collection("admins").doc(adminUid);
  const now = admin.firestore.Timestamp.now();

  const result = await db.runTransaction(async (tx) => {
    const adminSnap = await tx.get(adminRef);
    if (!adminSnap.exists || adminSnap.data()?.active === false) {
      throw new Error(`Admin ${adminUid} is not active in admins collection`);
    }

    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) {
      throw new Error(`Top-up request not found: ${requestId}`);
    }

    const requestData = requestSnap.data();
    if (requestData.status !== "pending") {
      throw new Error(
        `Top-up request ${requestId} already processed (status=${requestData.status})`,
      );
    }

    if (decision === "reject") {
      tx.update(requestRef, {
        status: "rejected",
        admin_note: adminNote,
        reviewed_at: now,
        reviewed_by_uid: adminUid,
        updated_at: now,
      });
      return { requestId, decision, venueId: requestData.venue_id };
    }

    const venueId = requestData.venue_id;
    const amount = Number(requestData.amount || 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new Error(`Invalid request amount for ${requestId}`);
    }

    const walletRef = db.collection("merchant_wallets").doc(venueId);
    const walletSnap = await tx.get(walletRef);
    const currentBalance = Number(walletSnap.data()?.available_balance || 0);
    const newBalance = roundMoney(currentBalance + amount);
    const entryRef = walletRef.collection("entries").doc();

    if (!walletSnap.exists) {
      tx.set(walletRef, {
        venue_id: venueId,
        currency: "ILS",
        status: "active",
        available_balance: 0,
        low_balance_threshold: 10,
        last_entry_at: null,
        last_top_up_at: null,
        created_at: now,
        updated_at: now,
      });
    } else if (walletSnap.data()?.status !== "active") {
      throw new Error(`Wallet for venue ${venueId} is not active`);
    }

    tx.set(entryRef, {
      venue_id: venueId,
      type: "credit",
      amount,
      currency: "ILS",
      balance_after: newBalance,
      feature_key: null,
      reference_type: "topup_request",
      reference_id: requestId,
      idempotency_key: `topup_credit_${requestId}`,
      created_by_type: "admin",
      created_by_uid: adminUid,
      note: adminNote || "Approved top-up request",
      metadata: {},
      created_at: now,
    });

    tx.update(walletRef, {
      available_balance: newBalance,
      last_entry_at: now,
      last_top_up_at: now,
      updated_at: now,
    });

    tx.update(requestRef, {
      status: "credited",
      admin_note: adminNote,
      reviewed_at: now,
      reviewed_by_uid: adminUid,
      linked_entry_id: entryRef.id,
      updated_at: now,
    });

    return { requestId, decision, venueId, entryId: entryRef.id, newBalance };
  });

  console.log(JSON.stringify({ ok: true, ...result }, null, 2));
}

run().catch((error) => {
  console.error(JSON.stringify({ ok: false, error: String(error) }, null, 2));
  process.exitCode = 1;
});
