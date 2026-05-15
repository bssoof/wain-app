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

const KNOWN_EVENT_TYPES = new Set([
  "wallet_entry",
  "wallet_entry_reversed",
  "topup_request_created",
  "topup_request_approved",
  "topup_request_rejected",
  "topup_proof_deleted",
  "merchant_review_requested",
  "merchant_review_rejected",
  "merchant_review_approved_and_executed",
  "merchant_review_pending_second_approval",
  "wallet_reversal_pending_second_approval",
  "wallet_reversal_approved_and_executed",
  "story_promotion",
  "offer_pin",
]);

const VALID_CATEGORIES = new Set([
  "wallet_entry",
  "wallet_reversal",
  "wallet_debit",
  "topup_request",
  "topup_review",
  "topup_proof_lifecycle",
]);

const ACTOR_FIELDS_BY_EVENT = {
  topup_request_created: ["requested_by_uid"],
  topup_request_approved: ["reviewed_by_uid"],
  topup_request_rejected: ["reviewed_by_uid"],
  merchant_review_requested: ["requested_by_uid"],
  merchant_review_rejected: ["reviewed_by_uid"],
  merchant_review_approved_and_executed: ["reviewed_by_uid"],
  merchant_review_pending_second_approval: ["reviewed_by_uid"],
  wallet_reversal_pending_second_approval: ["requested_by_uid"],
  wallet_reversal_approved_and_executed: ["approved_by_uid"],
  wallet_entry_reversed: ["reviewed_by_uid", "reversed_by_uid"],
};

const REQUIRED_STRING_FIELDS_BY_EVENT = {
  wallet_entry: ["venue_id", "entry_id", "type"],
  wallet_entry_reversed: ["venue_id", "entry_id", "reversal_entry_id"],
  topup_request_created: ["venue_id", "request_id", "status"],
  topup_request_approved: ["venue_id", "request_id", "decision", "linked_entry_id"],
  topup_request_rejected: ["venue_id", "request_id", "decision"],
  topup_proof_deleted: ["venue_id", "request_id"],
  merchant_review_requested: ["venue_id", "request_id", "entry_id"],
  merchant_review_rejected: ["venue_id", "request_id", "entry_id"],
  merchant_review_approved_and_executed: ["venue_id", "request_id", "entry_id", "reversal_entry_id"],
  merchant_review_pending_second_approval: ["venue_id", "request_id", "entry_id", "required_second_approver_role"],
  wallet_reversal_pending_second_approval: ["venue_id", "request_id", "entry_id"],
  wallet_reversal_approved_and_executed: ["venue_id", "request_id", "entry_id", "executed_reversal_entry_id"],
  story_promotion: ["venue_id", "request_id", "entry_id", "story_id"],
  offer_pin: ["venue_id", "request_id", "entry_id", "offer_id"],
};

const REQUIRED_NUMBER_FIELDS_BY_EVENT = {
  wallet_entry: ["amount", "balance_after"],
  topup_request_created: ["amount"],
  topup_request_approved: ["amount", "balance_after"],
  merchant_review_requested: ["original_amount"],
  wallet_entry_reversed: ["original_amount"],
  wallet_reversal_pending_second_approval: ["original_amount"],
  story_promotion: ["amount", "balance_after"],
  offer_pin: ["amount", "balance_after"],
};

function parseArgs(argv) {
  const args = {
    venues: [],
    strict: false,
    allowLive: false,
    limit: 200,
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
  node scripts/qa-verify-audit-trail.mjs --project=demo-wain --venue=venue_qa_01

Environment:
  FIRESTORE_EMULATOR_HOST=127.0.0.1:8080   Prefer emulator/staging for QA.

Options:
  --project=<id>      Firebase project id. Falls back to GCLOUD_PROJECT or .firebaserc.
  --venue=<id[,id]>   Verify specific venue audit events. Can be repeated.
  --limit=<n>         Max audit docs to scan when --venue is omitted. Default: 200.
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

function isTimestamp(value) {
  return Boolean(value && typeof value.toMillis === "function");
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function isFiniteNumber(value) {
  return typeof value === "number" && Number.isFinite(value);
}

function hasAnyString(data, fields) {
  return fields.some((field) => isNonEmptyString(data[field]));
}

function addFinding(findings, level, code, message, extra = {}) {
  findings.push({ level, code, message, ...extra });
}

async function getAuditDocs(db, venues, limit) {
  const auditRef = db.collection("wallet_audit_events");
  if (venues.length === 0) {
    const snap = await auditRef.limit(limit).get();
    return snap.docs;
  }

  const docsByPath = new Map();
  for (const venueId of venues) {
    const snap = await auditRef.where("venue_id", "==", venueId).limit(limit).get();
    for (const doc of snap.docs) {
      docsByPath.set(doc.ref.path, doc);
    }
  }
  return Array.from(docsByPath.values());
}

function validateAuditDoc(doc, findings) {
  const data = doc.data() ?? {};
  const eventType = data.event_type;
  const category = data.category;

  if (!isNonEmptyString(category)) {
    addFinding(findings, LEVEL.FAIL, "audit_missing_category", "Audit event has no category.", {
      auditId: doc.id,
    });
  } else if (!VALID_CATEGORIES.has(category)) {
    addFinding(findings, LEVEL.WARN, "audit_unknown_category", "Audit event category is not in the expected QA whitelist.", {
      auditId: doc.id,
      category,
    });
  }

  if (!isNonEmptyString(eventType)) {
    addFinding(findings, LEVEL.FAIL, "audit_missing_event_type", "Audit event has no event_type.", {
      auditId: doc.id,
    });
    return;
  }

  if (!KNOWN_EVENT_TYPES.has(eventType)) {
    addFinding(findings, LEVEL.WARN, "audit_unknown_event_type", "Audit event_type is not in the expected QA whitelist.", {
      auditId: doc.id,
      eventType,
    });
  }

  if (!isTimestamp(data.created_at)) {
    addFinding(findings, LEVEL.FAIL, "audit_missing_created_at", "Audit event has no Firestore Timestamp created_at.", {
      auditId: doc.id,
      eventType,
    });
  }

  if (!isTimestamp(data.updated_at)) {
    addFinding(findings, LEVEL.WARN, "audit_missing_updated_at", "Audit event has no Firestore Timestamp updated_at.", {
      auditId: doc.id,
      eventType,
    });
  }

  const requiredStringFields = REQUIRED_STRING_FIELDS_BY_EVENT[eventType] ?? [];
  for (const field of requiredStringFields) {
    if (!isNonEmptyString(data[field])) {
      addFinding(findings, LEVEL.FAIL, "audit_missing_required_string", "Audit event is missing a required string field.", {
        auditId: doc.id,
        eventType,
        field,
      });
    }
  }

  const requiredNumberFields = REQUIRED_NUMBER_FIELDS_BY_EVENT[eventType] ?? [];
  for (const field of requiredNumberFields) {
    if (!isFiniteNumber(data[field])) {
      addFinding(findings, LEVEL.FAIL, "audit_missing_required_number", "Audit event is missing a required numeric field.", {
        auditId: doc.id,
        eventType,
        field,
      });
    }
  }

  const actorFields = ACTOR_FIELDS_BY_EVENT[eventType] ?? [];
  if (actorFields.length > 0 && !hasAnyString(data, actorFields)) {
    addFinding(findings, LEVEL.FAIL, "audit_missing_actor", "Audit event has no actor field for this financial action.", {
      auditId: doc.id,
      eventType,
      expectedAnyOf: actorFields,
    });
  }
}

function auditMatches(auditDocs, predicate) {
  return auditDocs.some((doc) => predicate(doc.data() ?? {}, doc));
}

async function verifyTopUpAuditCoverage(db, venues, findings, auditDocs) {
  for (const venueId of venues) {
    const snap = await db.collection("merchant_topup_requests")
      .where("venue_id", "==", venueId)
      .get();

    for (const doc of snap.docs) {
      const hasCreatedAudit = auditMatches(
        auditDocs,
        (audit) => audit.request_id === doc.id && audit.event_type === "topup_request_created",
      );
      if (!hasCreatedAudit) {
        addFinding(findings, LEVEL.FAIL, "topup_missing_created_audit", "Top-up request has no creation audit event.", {
          venueId,
          requestId: doc.id,
        });
      }

      const status = doc.data()?.status;
      if (status === "credited" || status === "rejected") {
        const expectedEvent = status === "credited" ? "topup_request_approved" : "topup_request_rejected";
        const hasReviewAudit = auditMatches(
          auditDocs,
          (audit) => audit.request_id === doc.id && audit.event_type === expectedEvent,
        );
        if (!hasReviewAudit) {
          addFinding(findings, LEVEL.FAIL, "topup_missing_review_audit", "Reviewed top-up has no matching review audit event.", {
            venueId,
            requestId: doc.id,
            status,
            expectedEvent,
          });
        }
      }
    }
  }
}

function expectedReversalAuditEvents(request) {
  if (request.status === "pending_review") {
    return ["merchant_review_requested"];
  }
  if (request.status === "rejected") {
    return ["merchant_review_requested", "merchant_review_rejected"];
  }
  if (request.status === "pending_second_approval") {
    return ["merchant_review_pending_second_approval", "wallet_reversal_pending_second_approval"];
  }
  if (request.status === "approved_and_executed") {
    return ["merchant_review_approved_and_executed", "wallet_reversal_approved_and_executed"];
  }
  return [];
}

function hasAnyAuditEventForRequest(auditDocs, requestId, eventTypes) {
  return auditMatches(
    auditDocs,
    (audit) => audit.request_id === requestId && eventTypes.includes(audit.event_type),
  );
}

async function verifyReversalAuditCoverage(db, venues, findings, auditDocs) {
  for (const venueId of venues) {
    const snap = await db.collection("wallet_reversal_requests")
      .where("venue_id", "==", venueId)
      .get();

    for (const doc of snap.docs) {
      const data = doc.data() ?? {};
      const expectedEvents = expectedReversalAuditEvents(data);
      for (const eventType of expectedEvents) {
        const found = hasAnyAuditEventForRequest(auditDocs, doc.id, [eventType]);
        if (!found) {
          addFinding(findings, LEVEL.FAIL, "reversal_missing_audit", "Reversal request has no matching audit event.", {
            venueId,
            requestId: doc.id,
            status: data.status,
            expectedEvent: eventType,
          });
        }
      }
    }
  }
}

async function verifyWalletEntryAuditCoverage(db, venues, findings, auditDocs) {
  for (const venueId of venues) {
    const entriesSnap = await db.collection("merchant_wallets").doc(venueId).collection("entries").get();
    for (const doc of entriesSnap.docs) {
      const hasWalletEntryAudit = auditMatches(
        auditDocs,
        (audit) =>
          audit.venue_id === venueId &&
          audit.entry_id === doc.id &&
          audit.event_type === "wallet_entry",
      );
      if (!hasWalletEntryAudit) {
        addFinding(findings, LEVEL.FAIL, "wallet_entry_missing_audit", "Wallet ledger entry has no wallet_entry audit event.", {
          venueId,
          entryId: doc.id,
        });
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
  const auditDocs = await getAuditDocs(db, args.venues, args.limit);
  if (auditDocs.length === 0) {
    console.error("No wallet_audit_events found for the requested scope.");
    process.exit(1);
  }

  const findings = [];
  for (const doc of auditDocs) {
    validateAuditDoc(doc, findings);
  }

  if (args.venues.length > 0) {
    await verifyTopUpAuditCoverage(db, args.venues, findings, auditDocs);
    await verifyReversalAuditCoverage(db, args.venues, findings, auditDocs);
    await verifyWalletEntryAuditCoverage(db, args.venues, findings, auditDocs);
  } else {
    addFinding(
      findings,
      LEVEL.WARN,
      "coverage_scope_omitted",
      "Pass --venue to enable top-up, reversal, and wallet-entry coverage checks.",
    );
  }

  if (!findings.some((finding) => finding.level === LEVEL.FAIL)) {
    addFinding(findings, LEVEL.PASS, "wallet_audit_trail_ok", "Wallet audit trail checks passed.", {
      auditEvents: auditDocs.length,
      venues: args.venues,
    });
  }

  printFindings(findings);

  const failCount = findings.filter((finding) => finding.level === LEVEL.FAIL).length;
  const warnCount = findings.filter((finding) => finding.level === LEVEL.WARN).length;
  console.log(`\nQA audit verifier summary: audit_events=${auditDocs.length} fail=${failCount} warn=${warnCount}`);

  if (failCount > 0 || (args.strict && warnCount > 0)) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error?.stack ?? error);
  process.exit(1);
});
