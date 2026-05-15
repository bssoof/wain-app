#!/usr/bin/env node
/* eslint-disable no-console */

import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const require = createRequire(import.meta.url);

let admin;
try {
  admin = require("../functions/node_modules/firebase-admin");
} catch (error) {
  console.error(
    "Unable to load firebase-admin from functions/node_modules. Run `npm --prefix functions install` first.",
  );
  console.error(error?.message ?? error);
  process.exit(2);
}

const LEVEL = {
  PASS: "PASS",
  WARN: "WARN",
  FAIL: "FAIL",
};

function parseArgs(argv) {
  const args = {
    venues: [],
    strict: false,
    allowLive: false,
    limit: 100,
    projectId: "",
  };

  for (const token of argv) {
    if (token === "--help" || token === "-h") {
      args.help = true;
      continue;
    }
    if (token === "--strict") {
      args.strict = true;
      continue;
    }
    if (token === "--allow-live") {
      args.allowLive = true;
      continue;
    }
    if (token.startsWith("--project=")) {
      args.projectId = token.slice("--project=".length).trim();
      continue;
    }
    if (token.startsWith("--venue=")) {
      const values = token.slice("--venue=".length)
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean);
      args.venues.push(...values);
      continue;
    }
    if (token.startsWith("--limit=")) {
      const parsed = Number(token.slice("--limit=".length));
      if (Number.isFinite(parsed) && parsed > 0) {
        args.limit = Math.min(Math.floor(parsed), 1000);
      }
    }
  }

  return args;
}

function printHelp() {
  console.log(`
Usage:
  node scripts/qa-verify-finance.mjs --project=demo-wain --venue=venue_qa_01

Environment:
  FIRESTORE_EMULATOR_HOST=127.0.0.1:8080   Prefer emulator/staging for QA.

Options:
  --project=<id>      Firebase project id. Falls back to GCLOUD_PROJECT or .firebaserc.
  --venue=<id[,id]>   Verify specific venue wallet(s). Can be repeated.
  --limit=<n>         Max wallets to scan when --venue is omitted. Default: 100.
  --strict           Exit non-zero on warnings.
  --allow-live       Permit running without FIRESTORE_EMULATOR_HOST.
`);
}

function readDefaultProjectId() {
  const candidates = [
    process.env.QA_FIREBASE_PROJECT,
    process.env.GCLOUD_PROJECT,
    process.env.GOOGLE_CLOUD_PROJECT,
  ];
  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }

  const firebasercPath = path.resolve(".firebaserc");
  if (!fs.existsSync(firebasercPath)) {
    return "";
  }
  try {
    const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, "utf8"));
    return typeof firebaserc?.projects?.default === "string"
      ? firebaserc.projects.default.trim()
      : "";
  } catch {
    return "";
  }
}

function toNumber(value) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function roundMoney(value) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function moneyEquals(a, b) {
  return Math.abs(roundMoney(a) - roundMoney(b)) <= 0.01;
}

function timestampMillis(value) {
  if (value && typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  return 0;
}

function entryDelta(entry) {
  const amount = toNumber(entry.amount);
  if (amount == null) return null;

  const normalized = Math.abs(amount);
  if (entry.type === "credit") return normalized;
  if (entry.type === "debit") return -normalized;
  if (entry.type === "reversal") return normalized;
  return null;
}

function reversalOriginalId(entry) {
  const metadata = entry.metadata && typeof entry.metadata === "object"
    ? entry.metadata
    : {};
  const candidates = [
    metadata.reversal_of_entry_id,
    entry.reversal_of_entry_id,
    entry.original_entry_id,
  ];
  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }
  return "";
}

function addFinding(findings, level, code, message, extra = {}) {
  findings.push({ level, code, message, ...extra });
}

async function getWalletDocs(db, venues, limit) {
  if (venues.length > 0) {
    const docs = [];
    for (const venueId of venues) {
      docs.push(await db.collection("merchant_wallets").doc(venueId).get());
    }
    return docs.filter((doc) => doc.exists);
  }

  const snap = await db.collection("merchant_wallets").limit(limit).get();
  return snap.docs;
}

async function verifyWallet(db, walletDoc) {
  const venueId = walletDoc.id;
  const wallet = walletDoc.data() ?? {};
  const findings = [];
  const currentBalance = toNumber(wallet.available_balance);

  if (currentBalance == null) {
    addFinding(findings, LEVEL.FAIL, "wallet_missing_available_balance", "Wallet has no numeric available_balance.", { venueId });
    return findings;
  }

  const entriesSnap = await walletDoc.ref.collection("entries").get();
  const entries = entriesSnap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((a, b) => {
      const byTime = timestampMillis(a.created_at) - timestampMillis(b.created_at);
      return byTime !== 0 ? byTime : String(a.id).localeCompare(String(b.id));
    });

  if (entries.length === 0) {
    addFinding(findings, LEVEL.WARN, "wallet_has_no_entries", "Wallet has no ledger entries to verify.", { venueId });
    return findings;
  }

  const firstDelta = entryDelta(entries[0]);
  const firstBalanceAfter = toNumber(entries[0].balance_after);
  if (firstDelta == null || firstBalanceAfter == null) {
    addFinding(
      findings,
      LEVEL.FAIL,
      "wallet_first_entry_not_verifiable",
      "First wallet entry is missing numeric amount/type/balance_after.",
      { venueId, entryId: entries[0].id },
    );
  } else {
    let computed = roundMoney(firstBalanceAfter - firstDelta);
    for (const entry of entries) {
      const delta = entryDelta(entry);
      const balanceAfter = toNumber(entry.balance_after);
      if (delta == null || balanceAfter == null) {
        addFinding(
          findings,
          LEVEL.FAIL,
          "wallet_entry_not_verifiable",
          "Wallet entry is missing numeric amount/type/balance_after.",
          { venueId, entryId: entry.id, type: entry.type },
        );
        continue;
      }

      computed = roundMoney(computed + delta);
      if (!moneyEquals(computed, balanceAfter)) {
        addFinding(
          findings,
          LEVEL.FAIL,
          "wallet_entry_balance_chain_mismatch",
          "Entry balance_after does not match previous balance plus entry delta.",
          { venueId, entryId: entry.id, expected: computed, actual: balanceAfter },
        );
      }
    }

    if (!moneyEquals(computed, currentBalance)) {
      addFinding(
        findings,
        LEVEL.FAIL,
        "wallet_available_balance_mismatch",
        "Wallet available_balance does not match final ledger balance_after.",
        { venueId, expected: computed, actual: currentBalance },
      );
    }
  }

  const idempotencyKeys = new Map();
  const reversalsByOriginal = new Map();
  for (const entry of entries) {
    if (typeof entry.idempotency_key === "string" && entry.idempotency_key.trim()) {
      const key = entry.idempotency_key.trim();
      const existing = idempotencyKeys.get(key) ?? [];
      existing.push(entry.id);
      idempotencyKeys.set(key, existing);
    }

    const originalId = reversalOriginalId(entry);
    if (originalId) {
      const existing = reversalsByOriginal.get(originalId) ?? [];
      existing.push(entry.id);
      reversalsByOriginal.set(originalId, existing);
    }
  }

  for (const [key, ids] of idempotencyKeys.entries()) {
    if (ids.length > 1) {
      addFinding(
        findings,
        LEVEL.FAIL,
        "duplicate_idempotency_key",
        "Multiple wallet entries share the same idempotency_key.",
        { venueId, idempotencyKey: key, entryIds: ids },
      );
    }
  }

  for (const [originalId, reversalIds] of reversalsByOriginal.entries()) {
    if (reversalIds.length > 1) {
      addFinding(
        findings,
        LEVEL.FAIL,
        "duplicate_reversal_entries",
        "Multiple reversal entries point to the same original entry.",
        { venueId, originalEntryId: originalId, reversalEntryIds: reversalIds },
      );
    }
  }

  await verifyTopUps(db, venueId, walletDoc.ref, findings);
  await verifyReversalRequests(db, venueId, walletDoc.ref, findings);
  await verifyNonExecutedReversalsClean(db, venueId, findings);

  if (!findings.some((finding) => finding.level === LEVEL.FAIL)) {
    addFinding(findings, LEVEL.PASS, "wallet_finance_invariants_ok", "Wallet finance invariants passed.", {
      venueId,
      entries: entries.length,
      availableBalance: currentBalance,
    });
  }

  return findings;
}

async function verifyTopUps(db, venueId, walletRef, findings) {
  const snap = await db.collection("merchant_topup_requests")
    .where("venue_id", "==", venueId)
    .where("status", "==", "credited")
    .get();

  for (const doc of snap.docs) {
    const data = doc.data() ?? {};
    const linkedEntryId = typeof data.linked_entry_id === "string" ? data.linked_entry_id.trim() : "";
    if (!linkedEntryId) {
      addFinding(findings, LEVEL.FAIL, "credited_topup_missing_linked_entry", "Credited top-up has no linked_entry_id.", {
        venueId,
        requestId: doc.id,
      });
      continue;
    }

    const entryDoc = await walletRef.collection("entries").doc(linkedEntryId).get();
    if (!entryDoc.exists) {
      addFinding(findings, LEVEL.FAIL, "credited_topup_missing_entry", "Credited top-up linked_entry_id does not exist.", {
        venueId,
        requestId: doc.id,
        linkedEntryId,
      });
      continue;
    }

    const entry = entryDoc.data() ?? {};
    if (entry.type !== "credit" || entry.reference_id !== doc.id) {
      addFinding(findings, LEVEL.FAIL, "credited_topup_entry_mismatch", "Credited top-up linked entry is not a matching credit entry.", {
        venueId,
        requestId: doc.id,
        linkedEntryId,
      });
    }
  }
}

async function verifyReversalRequests(db, venueId, walletRef, findings) {
  const snap = await db.collection("wallet_reversal_requests")
    .where("venue_id", "==", venueId)
    .where("status", "==", "approved_and_executed")
    .get();

  for (const doc of snap.docs) {
    const data = doc.data() ?? {};
    const reversalEntryId = [
      data.executed_reversal_entry_id,
      data.reversal_entry_id,
    ].find((value) => typeof value === "string" && value.trim());

    if (!reversalEntryId) {
      addFinding(findings, LEVEL.FAIL, "approved_reversal_missing_entry_id", "Approved reversal request has no reversal entry id.", {
        venueId,
        requestId: doc.id,
      });
      continue;
    }

    const entryDoc = await walletRef.collection("entries").doc(reversalEntryId).get();
    if (!entryDoc.exists) {
      addFinding(findings, LEVEL.FAIL, "approved_reversal_entry_missing", "Approved reversal entry is missing from wallet ledger.", {
        venueId,
        requestId: doc.id,
        reversalEntryId,
      });
    }
  }
}

async function verifyNonExecutedReversalsClean(db, venueId, findings) {
  const nonExecutedStatuses = new Set(["expired", "rejected"]);
  const snap = await db.collection("wallet_reversal_requests")
    .where("venue_id", "==", venueId)
    .get();

  for (const doc of snap.docs) {
    const data = doc.data() ?? {};
    if (!nonExecutedStatuses.has(data.status)) continue;

    for (const field of ["executed_reversal_entry_id", "reversal_entry_id"]) {
      const value = data[field];
      if (typeof value === "string" && value.trim()) {
        addFinding(
          findings,
          LEVEL.FAIL,
          "non_executed_reversal_has_entry_link",
          `Reversal request with status=${data.status} has populated ${field}. This indicates state corruption.`,
          { venueId, requestId: doc.id, status: data.status, field, value },
        );
      }
    }
  }
}

function printFindings(findings) {
  for (const finding of findings) {
    const prefix = `[${finding.level}] ${finding.code}`;
    const context = Object.entries(finding)
      .filter(([key]) => !["level", "code", "message"].includes(key))
      .map(([key, value]) => `${key}=${JSON.stringify(value)}`)
      .join(" ");
    console.log(`${prefix}: ${finding.message}${context ? ` (${context})` : ""}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const projectId = args.projectId || readDefaultProjectId();
  if (!projectId) {
    console.error("Missing Firebase project id. Pass --project=<id>.");
    process.exit(2);
  }

  const usingEmulator = typeof process.env.FIRESTORE_EMULATOR_HOST === "string" &&
    process.env.FIRESTORE_EMULATOR_HOST.trim().length > 0;
  if (!usingEmulator && !args.allowLive) {
    console.error(
      "Refusing to verify a live Firestore without --allow-live. Prefer QA/staging or set FIRESTORE_EMULATOR_HOST.",
    );
    process.exit(2);
  }

  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }

  const db = admin.firestore();
  const walletDocs = await getWalletDocs(db, args.venues, args.limit);
  if (walletDocs.length === 0) {
    console.error("No merchant_wallets found for the requested scope.");
    process.exit(args.strict ? 1 : 0);
  }

  const allFindings = [];
  for (const walletDoc of walletDocs) {
    allFindings.push(...await verifyWallet(db, walletDoc));
  }

  printFindings(allFindings);

  const failCount = allFindings.filter((finding) => finding.level === LEVEL.FAIL).length;
  const warnCount = allFindings.filter((finding) => finding.level === LEVEL.WARN).length;
  console.log(`\nQA finance verifier summary: wallets=${walletDocs.length} fail=${failCount} warn=${warnCount}`);

  if (failCount > 0 || (args.strict && warnCount > 0)) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error?.stack ?? error);
  process.exit(1);
});
