#!/usr/bin/env node

import { createRequire } from "node:module";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  E2E_IDS,
  initializeAdmin,
  seedMerchantReversalE2E,
} from "./seed-merchant-reversal-e2e.mjs";

const require = createRequire(import.meta.url);

function callableContext(uid, role = null) {
  return {
    auth: {
      uid,
      token: {
        uid,
        ...(role
          ? {
              admin: true,
              role,
              [role]: true,
            }
          : {}),
      },
    },
    app: { appId: "merchant-reversal-e2e" },
  };
}

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${expected}, got ${actual}`);
  }
}

function assertTruthy(value, label) {
  if (!value) {
    throw new Error(`${label}: expected truthy value`);
  }
}

async function expectHttpsError(action, expectedMessage, label) {
  try {
    await action();
  } catch (error) {
    if (error?.message !== expectedMessage) {
      throw new Error(
        `${label}: expected ${expectedMessage}, got ${error?.message ?? error}`,
      );
    }
    return;
  }
  throw new Error(`${label}: expected ${expectedMessage}, but action succeeded`);
}

async function getDocData(db, pathSegments) {
  const ref = pathSegments.reduce((current, segment, index) => {
    if (index === 0) return db.collection(segment);
    if (index % 2 === 1) return current.doc(segment);
    return current.collection(segment);
  }, null);
  const doc = await ref.get();
  return doc.exists ? doc.data() : null;
}

async function writeLog(results) {
  const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
  const logPath = path.join(repoRoot, "MANUAL_E2E_LOG.md");
  const timestamp = new Date().toISOString();
  const lines = [
    "# Merchant Reversal Manual E2E Log",
    "",
    `Generated: ${timestamp}`,
    "",
    "> هذه الجولة شغّلت gate آلي على Auth/Firestore emulators باستخدام نفس callables والـ state transitions. الفحص البصري داخل Flutter/Admin UI يبقى خطوة يدوية لاحقة على نفس seed.",
    "",
    ...results.map((result) => {
      const details = result.details.map((line) => `    - ${line}`).join("\n");
      return `[${result.pass ? "x" : " "}] ${result.name} — ${result.pass ? "PASS" : "FAIL"}\n${details}`;
    }),
    "",
  ];
  await fs.writeFile(logPath, lines.join("\n"), "utf8");
  return logPath;
}

async function main() {
  const seed = await seedMerchantReversalE2E();
  const app = initializeAdmin();
  const db = app.firestore();
  const ids = E2E_IDS;

  const {
    approveWalletReversalRequest,
    createMerchantWalletReversalRequest,
    reviewMerchantWalletReversalRequest,
    reverseWalletEntry,
  } = require("../../functions/lib/wallet_runtime_mutations.js");

  const merchantCtx = callableContext(seed.users.merchant.uid);
  const admin1Ctx = callableContext(seed.users.admin1.uid, "finance_admin");
  const admin2Ctx = callableContext(seed.users.admin2.uid, "finance_admin");

  const results = [];

  async function runScenario(name, action) {
    const details = [];
    try {
      await action(details);
      results.push({ name, pass: true, details });
    } catch (error) {
      details.push(error instanceof Error ? error.message : String(error));
      results.push({ name, pass: false, details });
    }
  }

  await runScenario("السيناريو 1: direct execute <= 100 ILS", async (details) => {
    const walletBefore = await getDocData(db, ["merchant_wallets", ids.venueId]);
    const createResult = await createMerchantWalletReversalRequest.run(
      {
        venueId: ids.venueId,
        entryId: ids.directEntryId,
        reason: "الإعلان لم يُعرض",
        merchantNote: "E2E direct path",
      },
      merchantCtx,
    );
    assertEqual(createResult.status, "pending_review", "direct create status");

    const pendingSnap = await db
      .collection("wallet_reversal_requests")
      .where("source", "==", "merchant")
      .where("status", "==", "pending_review")
      .get();
    assertTruthy(
      pendingSnap.docs.some((doc) => doc.id === createResult.requestId),
      "admin web pending query contains direct request",
    );

    const reviewResult = await reviewMerchantWalletReversalRequest.run(
      {
        requestId: createResult.requestId,
        decision: "approve",
        adminNote: "verified direct",
      },
      admin1Ctx,
    );
    assertEqual(reviewResult.status, "approved_and_executed", "direct review status");

    const walletAfter = await getDocData(db, ["merchant_wallets", ids.venueId]);
    const request = await getDocData(db, [
      "wallet_reversal_requests",
      createResult.requestId,
    ]);
    const reversalEntry = await getDocData(db, [
      "merchant_wallets",
      ids.venueId,
      "entries",
      `reversal_${ids.directEntryId}`,
    ]);

    assertEqual(walletAfter.available_balance, walletBefore.available_balance + 50, "direct balance");
    assertEqual(request.status, "approved_and_executed", "direct request doc status");
    assertEqual(reversalEntry.type, "credit", "direct reversal entry type");
    details.push(`balance قبل: ${walletBefore.available_balance}, بعد: ${walletAfter.available_balance}`);
    details.push(`request status: ${request.status}`);
    details.push(`reversal entry id: reversal_${ids.directEntryId}`);
  });

  await runScenario("السيناريو 2: pending_second_approval > 100 ILS", async (details) => {
    const createResult = await createMerchantWalletReversalRequest.run(
      {
        venueId: ids.venueId,
        entryId: ids.secondApprovalEntryId,
        reason: "تثبيت العرض لم يعمل",
      },
      merchantCtx,
    );
    const firstReview = await reviewMerchantWalletReversalRequest.run(
      {
        requestId: createResult.requestId,
        decision: "approve",
      },
      admin1Ctx,
    );
    assertEqual(firstReview.status, "pending_second_approval", "second approval first status");
    assertEqual(firstReview.requiredSecondApproverRole, "finance_admin", "required second approver");

    await expectHttpsError(
      () =>
        approveWalletReversalRequest.run(
          {
            requestId: createResult.requestId,
            commandId: "e2e_same_actor_rejected",
            expectedState: {
              approval_state: "pending_second_approval",
              request_not_expired: true,
            },
          },
          admin1Ctx,
        ),
      "second_approver_must_differ",
      "same admin second approval",
    );

    const finalApproval = await approveWalletReversalRequest.run(
      {
        requestId: createResult.requestId,
        commandId: "e2e_second_approval_success",
        expectedState: {
          approval_state: "pending_second_approval",
          request_not_expired: true,
        },
      },
      admin2Ctx,
    );
    assertEqual(finalApproval.status, "approved_and_executed", "second final status");
    const request = await getDocData(db, [
      "wallet_reversal_requests",
      createResult.requestId,
    ]);
    assertEqual(request.status, "approved_and_executed", "second request doc status");
    details.push(`required role: ${firstReview.requiredSecondApproverRole}`);
    details.push("same-admin approval blocked: second_approver_must_differ");
    details.push(`executed reversal: ${finalApproval.executedReversalEntryId}`);
  });

  await runScenario("السيناريو 3: الرفض", async (details) => {
    const walletBefore = await getDocData(db, ["merchant_wallets", ids.venueId]);
    const createResult = await createMerchantWalletReversalRequest.run(
      {
        venueId: ids.venueId,
        entryId: ids.rejectEntryId,
        reason: "طلب رفض للتأكد",
      },
      merchantCtx,
    );
    await expectHttpsError(
      () =>
        reviewMerchantWalletReversalRequest.run(
          {
            requestId: createResult.requestId,
            decision: "reject",
            rejectionReason: " ",
          },
          admin1Ctx,
        ),
      "rejection_reason_required",
      "empty rejection reason",
    );
    const rejectResult = await reviewMerchantWalletReversalRequest.run(
      {
        requestId: createResult.requestId,
        decision: "reject",
        rejectionReason: "الخدمة نُفذت بنجاح، طلب غير صحيح",
        adminNote: "E2E reject",
      },
      admin1Ctx,
    );
    assertEqual(rejectResult.status, "rejected", "reject status");
    const walletAfter = await getDocData(db, ["merchant_wallets", ids.venueId]);
    const request = await getDocData(db, [
      "wallet_reversal_requests",
      createResult.requestId,
    ]);
    assertEqual(walletAfter.available_balance, walletBefore.available_balance, "reject balance unchanged");
    assertEqual(request.rejection_reason, "الخدمة نُفذت بنجاح، طلب غير صحيح", "rejection reason stored");
    details.push(`balance unchanged: ${walletAfter.available_balance}`);
    details.push(`request status: ${request.status}`);
  });

  await runScenario("السيناريو 4: حالات الحافة", async (details) => {
    await expectHttpsError(
      () =>
        createMerchantWalletReversalRequest.run(
          {
            venueId: ids.venueId,
            entryId: ids.creditEntryId,
            reason: "credit check",
          },
          merchantCtx,
        ),
      "reversal_only_for_debit",
      "credit request blocked",
    );
    await expectHttpsError(
      () =>
        createMerchantWalletReversalRequest.run(
          {
            venueId: ids.venueId,
            entryId: ids.unsupportedEntryId,
            reason: "unsupported feature check",
          },
          merchantCtx,
        ),
      "unsupported_reversal_feature",
      "unsupported feature blocked",
    );
    await expectHttpsError(
      () =>
        createMerchantWalletReversalRequest.run(
          {
            venueId: ids.venueId,
            entryId: ids.directEntryId,
            reason: "duplicate approved check",
          },
          merchantCtx,
        ),
      "entry_already_reversed",
      "already reversed request blocked",
    );
    details.push("credit entry blocked");
    details.push("unsupported feature blocked");
    details.push("already reversed entry blocked");
  });

  await runScenario("السيناريو 5: race condition", async (details) => {
    const createResult = await createMerchantWalletReversalRequest.run(
      {
        venueId: ids.venueId,
        entryId: ids.raceEntryId,
        reason: "race condition check",
      },
      merchantCtx,
    );
    const directResult = await reverseWalletEntry.run(
      {
        venueId: ids.venueId,
        entryId: ids.raceEntryId,
        reason: "admin direct race reversal",
        commandId: "e2e_race_direct_reversal",
      },
      admin2Ctx,
    );
    assertEqual(directResult.status, "reversed", "race direct reversal status");
    await expectHttpsError(
      () =>
        reviewMerchantWalletReversalRequest.run(
          {
            requestId: createResult.requestId,
            decision: "approve",
          },
          admin1Ctx,
        ),
      "entry_already_reversed",
      "race approve blocked",
    );
    const rejectResult = await reviewMerchantWalletReversalRequest.run(
      {
        requestId: createResult.requestId,
        decision: "reject",
        rejectionReason: "تم تصحيح العملية مسبقًا من مسار إداري مباشر",
      },
      admin1Ctx,
    );
    assertEqual(rejectResult.status, "rejected", "race reject status");
    const originalEntry = await getDocData(db, [
      "merchant_wallets",
      ids.venueId,
      "entries",
      ids.raceEntryId,
    ]);
    assertEqual(originalEntry.reversal_entry_id, `reversal_${ids.raceEntryId}`, "race entry linked reversal");
    details.push(`direct reversal status: ${directResult.status}`);
    details.push("merchant request approve blocked: entry_already_reversed");
    details.push(`request final status: ${rejectResult.status}`);
  });

  const logPath = await writeLog(results);
  const failed = results.filter((result) => !result.pass);
  console.log(JSON.stringify({ seed, results, logPath }, null, 2));
  if (failed.length > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
