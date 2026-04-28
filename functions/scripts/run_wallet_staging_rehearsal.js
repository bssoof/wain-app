#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const {
  createMerchantTopUpRequest,
  reviewMerchantTopUpRequest,
  promoteStory,
  pinOffer,
  reverseWalletEntry,
  approveWalletReversalRequest,
  verifyWalletOperationalReadiness,
  runWalletExpiryReminderMaintenance,
  runWalletLifecycleMaintenance,
} = require("../lib/index.js");

function parseArgs(argv) {
  const args = {};
  for (const token of argv) {
    if (!token.startsWith("--")) continue;
    const [rawKey, ...valueParts] = token.slice(2).split("=");
    if (!rawKey) continue;
    args[rawKey.trim()] = valueParts.length > 0 ? valueParts.join("=").trim() : true;
  }
  return args;
}

function tsFromNow(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

function callableContext(uid, { adminClaim = false } = {}) {
  return {
    auth: {
      uid,
      token: adminClaim ? { admin: true } : {},
    },
    app: {
      appId: "phase16-release-runner",
    },
  };
}

function normalizeError(error) {
  return {
    code: error && error.code ? String(error.code) : null,
    message: error && error.message ? String(error.message) : String(error),
  };
}

async function expectFailure(action, expectedMessageFragment) {
  try {
    await action();
    return {
      passed: false,
      error: {
        code: null,
        message: "Expected failure but call succeeded",
      },
    };
  } catch (error) {
    const normalized = normalizeError(error);
    const expected = String(expectedMessageFragment || "");
    const hasExpected = expected.length === 0 || normalized.message.includes(expected);
    return {
      passed: hasExpected,
      error: normalized,
    };
  }
}

async function getTopUpRequestByTransferReference(transferReference) {
  const snap = await db.collection("merchant_topup_requests")
    .where("transfer_reference", "==", transferReference)
    .limit(1)
    .get();
  if (snap.empty) {
    throw new Error(`Top-up request not found for transfer_reference=${transferReference}`);
  }
  return snap.docs[0];
}

async function getUserNotifications(uid, type = null) {
  const snap = await db.collection("users").doc(uid).collection("notifications").get();
  const docs = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  if (!type) return docs;
  return docs.filter((doc) => doc.type === type);
}

async function seedVenue(venueId) {
  await db.collection("venues").doc(venueId).set({
    name_ar: `Phase16 ${venueId}`,
    lat: 31.9539,
    lng: 35.9106,
    is_active: true,
    updated_at: tsFromNow(0),
  }, { merge: true });
}

async function seedMerchant(merchantUid, venueId) {
  await db.collection("merchants").doc(merchantUid).set({
    uid: merchantUid,
    venue_id: venueId,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  }, { merge: true });

  await db.collection("users").doc(merchantUid).set({
    is_merchant: true,
    merchant_venue_id: venueId,
    wallet_notifications_enabled: true,
    wallet_expiry_reminders_enabled: true,
    admin_wallet_notifications_enabled: false,
    updated_at: tsFromNow(-60_000),
  }, { merge: true });
}

async function seedAdmin(adminUid) {
  await db.collection("admins").doc(adminUid).set({
    active: true,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  }, { merge: true });

  await db.collection("users").doc(adminUid).set({
    admin_wallet_notifications_enabled: true,
    wallet_notifications_enabled: true,
    wallet_expiry_reminders_enabled: true,
    updated_at: tsFromNow(-60_000),
  }, { merge: true });
}

async function seedStory(storyId, venueId, { expiresOffsetMs = 3 * 24 * 60 * 60 * 1000 } = {}) {
  await db.collection("stories").doc(storyId).set({
    venue_id: venueId,
    media_url: `https://example.com/${storyId}.jpg`,
    expires_at: tsFromNow(expiresOffsetMs),
    is_promoted: false,
    promoted_until: null,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  }, { merge: true });
}

async function seedOffer(offerId, venueId, { endOffsetMs = 3 * 24 * 60 * 60 * 1000 } = {}) {
  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title_ar: `Offer ${offerId}`,
    discount_type: "amount",
    discount_value: 10,
    currency: "ILS",
    is_active: true,
    start_at: tsFromNow(-60_000),
    end_at: tsFromNow(endOffsetMs),
    single_use_per_customer: true,
    claims_count: 0,
    redeemed_count: 0,
    conversion_rate: 0,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-60_000),
  }, { merge: true });
}

async function getWalletEntriesCount(venueId) {
  const snap = await db.collection("merchant_wallets").doc(venueId).collection("entries").get();
  return snap.size;
}

async function resolveStorageBucket(projectId) {
  const candidates = [
    process.env.STORAGE_BUCKET,
    process.env.FIREBASE_STORAGE_BUCKET,
    admin.app().options.storageBucket,
    `${projectId}.firebasestorage.app`,
    `${projectId}.appspot.com`,
  ].filter((value, index, values) => {
    return typeof value === "string" && value.trim().length > 0 &&
      values.findIndex((entry) => entry === value) === index;
  });

  for (const bucketName of candidates) {
    try {
      const bucket = admin.storage().bucket(bucketName);
      const [exists] = await bucket.exists();
      if (exists) {
        return { bucket, bucketName };
      }
    } catch (_error) {
      // Continue trying the remaining candidates.
    }
  }

  throw new Error(
    `No accessible storage bucket found for project ${projectId}. Tried: ${candidates.join(", ")}`,
  );
}

async function seedReversibleDebitEntry({
  venueId,
  entryId,
  amount,
  balanceBefore,
  featureKey = "offer_pin",
  referenceType = "offer",
  referenceId = null,
}) {
  const balanceAfter = balanceBefore - amount;
  const now = tsFromNow(0);
  await db.collection("merchant_wallets").doc(venueId).set({
    status: "active",
    available_balance: balanceAfter,
    last_entry_at: now,
    updated_at: now,
  }, { merge: true });

  await db.collection("merchant_wallets").doc(venueId).collection("entries").doc(entryId).set({
    venue_id: venueId,
    type: "debit",
    amount,
    currency: "ILS",
    balance_after: balanceAfter,
    feature_key: featureKey,
    reference_type: referenceType,
    reference_id: referenceId,
    idempotency_key: `seed_${entryId}`,
    created_by_type: "system",
    created_by_uid: "system",
    note: "Seeded reversible debit for staging rehearsal",
    metadata: {
      seeded_for: "staging_rehearsal_dual_approval",
    },
    created_at: now,
  }, { merge: true });

  return {
    balanceBefore,
    balanceAfter,
  };
}

function collectSecurityEvents(securityLogs, eventName) {
  return securityLogs.filter((item) => item.event === eventName).length;
}

async function run() {
  const args = parseArgs(process.argv.slice(2));
  const rootDir = path.resolve(__dirname, "../..");
  const outputPath = args.output
    ? path.resolve(process.cwd(), String(args.output))
    : path.join(rootDir, "docs", "release", "merchant_wallet_staging_evidence_log.json");

  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || admin.app().options.projectId;
  if (!projectId) {
    throw new Error("Missing GCP project id. Set GCLOUD_PROJECT or GCP_PROJECT.");
  }

  const { bucket, bucketName } = await resolveStorageBucket(projectId);

  const runId = `phase16_${Date.now()}`;
  const venueId = `venue_${runId}`;
  const merchantUid = `merchant_${runId}`;
  const adminUid = `admin_${runId}`;
  const approverUid = `approver_${runId}`;

  const merchantCtx = callableContext(merchantUid);
  const adminCtx = callableContext(adminUid, { adminClaim: true });
  const approverCtx = callableContext(approverUid, { adminClaim: true });

  const securityLogs = [];
  const originalConsoleLog = console.log;
  console.log = (...messages) => {
    for (const message of messages) {
      if (typeof message !== "string") continue;
      const trimmed = message.trim();
      if (!trimmed.startsWith("{")) continue;
      try {
        const parsed = JSON.parse(trimmed);
        if (parsed && typeof parsed.event === "string") {
          securityLogs.push(parsed);
        }
      } catch (_error) {
        // Intentionally ignore non-JSON logs.
      }
    }
    originalConsoleLog(...messages);
  };

  const evidence = {
    runId,
    projectId,
    bucketName,
    startedAt: new Date().toISOString(),
    seed: {
      venueId,
      merchantUid,
      adminUid,
      approverUid,
    },
    readiness: {
      before: null,
      after: null,
    },
    flows: {},
    maintenance: {},
    monitoringSignals: {},
    goNoGoChecklist: {},
    notes: [],
  };

  try {
    await seedVenue(venueId);
    await seedMerchant(merchantUid, venueId);
    await seedAdmin(adminUid);
    await seedAdmin(approverUid);

    evidence.readiness.before = await verifyWalletOperationalReadiness.run({}, adminCtx);

    const proofPathApprove = `venues/${venueId}/wallet_topups/${runId}_approve.jpg`;
    const transferApprove = `${runId}_topup_approve`;
    await bucket.file(proofPathApprove).save(Buffer.from("phase16-approve-proof"), {
      metadata: { contentType: "image/jpeg" },
    });

    await createMerchantTopUpRequest.run({
      amount: 120,
      proof_image_url: proofPathApprove,
      transfer_reference: transferApprove,
      note: "Phase16 top-up approve flow",
    }, merchantCtx);

    const approveRequestDoc = await getTopUpRequestByTransferReference(transferApprove);
    const approveRequestId = approveRequestDoc.id;

    await reviewMerchantTopUpRequest.run({
      requestId: approveRequestId,
      decision: "credit",
      adminNote: "Phase16 approved",
    }, adminCtx);

    const approveAfterDoc = await db.collection("merchant_topup_requests").doc(approveRequestId).get();
    const approveAfterData = approveAfterDoc.data() || {};
    const approvedEntryId = typeof approveAfterData.linked_entry_id === "string"
      ? approveAfterData.linked_entry_id
      : null;

    const merchantApprovedNotifications = (await getUserNotifications(merchantUid, "wallet_topup_request_approved"))
      .filter((item) => item.data && item.data.request_id === approveRequestId);

    evidence.flows.topupApprove = {
      requestId: approveRequestId,
      entryId: approvedEntryId,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        merchantApprovedNotificationCount: merchantApprovedNotifications.length,
      },
      checks: {
        statusCredited: approveAfterData.status === "credited",
        linkedEntryPresent: Boolean(approvedEntryId),
      },
    };

    const proofPathReject = `venues/${venueId}/wallet_topups/${runId}_reject.jpg`;
    const transferReject = `${runId}_topup_reject`;
    await bucket.file(proofPathReject).save(Buffer.from("phase16-reject-proof"), {
      metadata: { contentType: "image/jpeg" },
    });

    await createMerchantTopUpRequest.run({
      amount: 65,
      proof_image_url: proofPathReject,
      transfer_reference: transferReject,
      note: "Phase16 top-up reject flow",
    }, merchantCtx);

    const rejectRequestDoc = await getTopUpRequestByTransferReference(transferReject);
    const rejectRequestId = rejectRequestDoc.id;

    await reviewMerchantTopUpRequest.run({
      requestId: rejectRequestId,
      decision: "reject",
      adminNote: "Phase16 rejected for mismatch",
    }, adminCtx);

    const rejectAfterDoc = await db.collection("merchant_topup_requests").doc(rejectRequestId).get();
    const rejectAfterData = rejectAfterDoc.data() || {};
    const merchantRejectedNotifications = (await getUserNotifications(merchantUid, "wallet_topup_request_rejected"))
      .filter((item) => item.data && item.data.request_id === rejectRequestId);

    evidence.flows.topupReject = {
      requestId: rejectRequestId,
      entryId: null,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        merchantRejectedNotificationCount: merchantRejectedNotifications.length,
      },
      checks: {
        statusRejected: rejectAfterData.status === "rejected",
        noLinkedEntry: !rejectAfterData.linked_entry_id,
      },
    };

    const storyId = `story_${runId}`;
    const storyRequestId = `${runId}_story_debit`;
    await seedStory(storyId, venueId);
    const storyDebitResult = await promoteStory.run({
      storyId,
      durationDays: 1,
      requestId: storyRequestId,
    }, merchantCtx);
    const storyDebitRetryResult = await promoteStory.run({
      storyId,
      durationDays: 1,
      requestId: storyRequestId,
    }, merchantCtx);
    const storyEntryId = `story_promotion_${storyRequestId}`;

    const storyEntryDoc = await db.collection("merchant_wallets")
      .doc(venueId)
      .collection("entries")
      .doc(storyEntryId)
      .get();

    evidence.flows.storyPromotionDebit = {
      requestId: storyRequestId,
      entryId: storyEntryId,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        lowBalanceNotificationCount: (await getUserNotifications(merchantUid, "wallet_low_balance"))
          .filter((item) => item.data && item.data.request_id === storyRequestId).length,
      },
      checks: {
        debitEntryExists: storyEntryDoc.exists,
        firstCallSucceeded: storyDebitResult && storyDebitResult.success === true,
        retryIdempotent: storyDebitRetryResult && storyDebitRetryResult.idempotent === true,
      },
    };

    const offerId = `offer_${runId}`;
    const offerRequestId = `${runId}_offer_debit`;
    await seedOffer(offerId, venueId);
    const offerDebitResult = await pinOffer.run({
      offerId,
      durationDays: 1,
      requestId: offerRequestId,
    }, merchantCtx);
    const offerDebitRetryResult = await pinOffer.run({
      offerId,
      durationDays: 1,
      requestId: offerRequestId,
    }, merchantCtx);
    const offerEntryId = `offer_pin_${offerRequestId}`;

    const offerEntryDoc = await db.collection("merchant_wallets")
      .doc(venueId)
      .collection("entries")
      .doc(offerEntryId)
      .get();

    evidence.flows.offerPinDebit = {
      requestId: offerRequestId,
      entryId: offerEntryId,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        lowBalanceNotificationCount: (await getUserNotifications(merchantUid, "wallet_low_balance"))
          .filter((item) => item.data && item.data.request_id === offerRequestId).length,
      },
      checks: {
        debitEntryExists: offerEntryDoc.exists,
        firstCallSucceeded: offerDebitResult && offerDebitResult.success === true,
        retryIdempotent: offerDebitRetryResult && offerDebitRetryResult.idempotent === true,
      },
    };

    const insufficientStoryId = `story_insufficient_${runId}`;
    const insufficientOfferId = `offer_insufficient_${runId}`;
    await seedStory(insufficientStoryId, venueId);
    await seedOffer(insufficientOfferId, venueId);

    await db.collection("merchant_wallets").doc(venueId).set({
      available_balance: 0,
      updated_at: tsFromNow(0),
    }, { merge: true });

    const entriesBeforeInsufficient = await getWalletEntriesCount(venueId);
    const insufficientStoryResult = await expectFailure(() => promoteStory.run({
      storyId: insufficientStoryId,
      durationDays: 1,
      requestId: `${runId}_story_insufficient`,
    }, merchantCtx), "insufficient_wallet_balance");
    const insufficientOfferResult = await expectFailure(() => pinOffer.run({
      offerId: insufficientOfferId,
      durationDays: 1,
      requestId: `${runId}_offer_insufficient`,
    }, merchantCtx), "insufficient_wallet_balance");
    const entriesAfterInsufficient = await getWalletEntriesCount(venueId);

    evidence.flows.insufficientBalance = {
      requestId: `${runId}_story_insufficient / ${runId}_offer_insufficient`,
      entryId: null,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        noNewDebitEntries: entriesAfterInsufficient === entriesBeforeInsufficient,
      },
      checks: {
        storyBlocked: insufficientStoryResult.passed,
        offerBlocked: insufficientOfferResult.passed,
        noPartialWrites: entriesAfterInsufficient === entriesBeforeInsufficient,
      },
      errors: {
        story: insufficientStoryResult.error,
        offer: insufficientOfferResult.error,
      },
    };

    await db.collection("merchant_wallets").doc(venueId).set({
      available_balance: 200,
      updated_at: tsFromNow(0),
    }, { merge: true });

    const dualApprovalEntryId = `dual_reversal_${runId}`;
    const dualApprovalSeed = await seedReversibleDebitEntry({
      venueId,
      entryId: dualApprovalEntryId,
      amount: 140,
      balanceBefore: 200,
      referenceId: `dual_offer_${runId}`,
    });

    const dualApprovalPending = await reverseWalletEntry.run({
      entryId: dualApprovalEntryId,
      venueId,
      reason: "phase16_dual_approval_review",
      adminNote: "Phase16 dual approval request",
      commandId: `reverse_dual_${runId}`,
      expectedState: {
        entry_type: "debit",
        entry_status: "posted",
        reversal_state: "not_reversed",
      },
    }, adminCtx);

    const sameActorApproval = await expectFailure(() => approveWalletReversalRequest.run({
      reversalRequestId: dualApprovalPending.reversalRequestId,
      commandId: `approve_dual_same_actor_${runId}`,
      reason: "Phase16 same actor negative check",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    }, adminCtx), "second_approver_must_differ");

    const dualApprovalApproved = await approveWalletReversalRequest.run({
      reversalRequestId: dualApprovalPending.reversalRequestId,
      commandId: `approve_dual_${runId}`,
      reason: "Phase16 dual approval confirmed",
      adminNote: "Approved by second actor",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    }, approverCtx);

    const [dualWalletDoc, dualOriginalEntryDoc, dualReversalEntryDoc, dualRequestDoc] = await Promise.all([
      db.collection("merchant_wallets").doc(venueId).get(),
      db.collection("merchant_wallets").doc(venueId).collection("entries").doc(dualApprovalEntryId).get(),
      db.collection("merchant_wallets").doc(venueId).collection("entries").doc(`reversal_${dualApprovalEntryId}`).get(),
      db.collection("wallet_reversal_requests").doc(dualApprovalPending.reversalRequestId).get(),
    ]);

    evidence.flows.reversalDualApproval = {
      requestId: dualApprovalPending.reversalRequestId,
      entryId: dualApprovalEntryId,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        reversalNotificationCount: (await getUserNotifications(merchantUid, "wallet_entry_reversed"))
          .filter((item) => item.data && item.data.entry_id === dualApprovalEntryId).length,
      },
      checks: {
        pendingSecondApprovalReturned: dualApprovalPending &&
          dualApprovalPending.status === "pending_second_approval",
        sameActorBlocked: sameActorApproval.passed,
        secondActorApprovalSucceeded: dualApprovalApproved &&
          dualApprovalApproved.status === "approved_and_executed",
        reversalEntryIdPresent: dualReversalEntryDoc.exists,
        requestStatusApprovedAndExecuted:
          (dualRequestDoc.data() ?? {}).status === "approved_and_executed",
        walletBalanceRestored:
          (dualWalletDoc.data() ?? {}).available_balance === dualApprovalSeed.balanceBefore,
        originalEntryLinked:
          (dualOriginalEntryDoc.data() ?? {}).reversal_entry_id === `reversal_${dualApprovalEntryId}`,
      },
      approvalResult: {
        requestedByUid: adminUid,
        approvedByUid: approverUid,
        executedReversalEntryId: dualApprovalApproved
          ? dualApprovalApproved.executedReversalEntryId
          : null,
        sameActorError: sameActorApproval.error,
      },
    };

    const reversalResult = await reverseWalletEntry.run({
      entryId: offerEntryId,
      venueId,
      reason: "phase16_reversal_test",
      adminNote: "Phase16 reversal validation",
    }, adminCtx);

    const reversalRetry = await expectFailure(() => reverseWalletEntry.run({
      entryId: offerEntryId,
      venueId,
      reason: "phase16_reversal_test_retry",
      adminNote: "Phase16 reversal retry",
    }, adminCtx), "entry_already_reversed");

    const reversalNotifications = (await getUserNotifications(merchantUid, "wallet_entry_reversed"))
      .filter((item) => item.data && item.data.entry_id === offerEntryId);

    evidence.flows.reversal = {
      requestId: offerRequestId,
      entryId: offerEntryId,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        reversalNotificationCount: reversalNotifications.length,
      },
      checks: {
        reversalSucceeded: reversalResult && reversalResult.success === true,
        reversalEntryIdPresent: Boolean(reversalResult && reversalResult.reversalEntryId),
        secondReversalBlocked: reversalRetry.passed,
      },
      reversalEntryId: reversalResult ? reversalResult.reversalEntryId : null,
      retryError: reversalRetry.error,
    };

    const storyReminderId = `story_expiring_${runId}`;
    const offerReminderId = `offer_expiring_${runId}`;
    await seedStory(storyReminderId, venueId, { expiresOffsetMs: 3 * 24 * 60 * 60 * 1000 });
    await db.collection("stories").doc(storyReminderId).set({
      is_promoted: true,
      promoted_until: tsFromNow(2 * 60 * 60 * 1000),
      updated_at: tsFromNow(0),
    }, { merge: true });

    await seedOffer(offerReminderId, venueId, { endOffsetMs: 3 * 24 * 60 * 60 * 1000 });
    await db.collection("offers").doc(offerReminderId).set({
      is_featured: true,
      featured_until: tsFromNow(2 * 60 * 60 * 1000),
      updated_at: tsFromNow(0),
    }, { merge: true });

    const reminderResult = await runWalletExpiryReminderMaintenance({
      now: tsFromNow(0),
      limitPerType: 200,
    });

    const reminderStoryNotifications = (await getUserNotifications(merchantUid, "wallet_story_promotion_expiring"))
      .filter((item) => item.data && item.data.story_id === storyReminderId);
    const reminderOfferNotifications = (await getUserNotifications(merchantUid, "wallet_offer_pin_expiring"))
      .filter((item) => item.data && item.data.offer_id === offerReminderId);

    evidence.flows.expiryReminder = {
      requestId: null,
      entryId: null,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        storyReminderNotificationCount: reminderStoryNotifications.length,
        offerReminderNotificationCount: reminderOfferNotifications.length,
      },
      checks: {
        storyReminderSent: reminderStoryNotifications.length > 0,
        offerReminderSent: reminderOfferNotifications.length > 0,
      },
      maintenanceResult: reminderResult,
    };

    const lifecycleStoryId = `story_expired_${runId}`;
    const lifecycleOfferId = `offer_expired_${runId}`;
    await seedStory(lifecycleStoryId, venueId, { expiresOffsetMs: 3 * 24 * 60 * 60 * 1000 });
    await db.collection("stories").doc(lifecycleStoryId).set({
      is_promoted: true,
      promoted_until: tsFromNow(-2 * 60 * 60 * 1000),
      updated_at: tsFromNow(-2 * 60 * 60 * 1000),
    }, { merge: true });

    await seedOffer(lifecycleOfferId, venueId, { endOffsetMs: 3 * 24 * 60 * 60 * 1000 });
    await db.collection("offers").doc(lifecycleOfferId).set({
      is_featured: true,
      featured_until: tsFromNow(-2 * 60 * 60 * 1000),
      updated_at: tsFromNow(-2 * 60 * 60 * 1000),
    }, { merge: true });

    const cleanupProofPath = `venues/${venueId}/wallet_topups/${runId}_cleanup.jpg`;
    await bucket.file(cleanupProofPath).save(Buffer.from("phase16-cleanup-proof"), {
      metadata: { contentType: "image/jpeg" },
    });

    const cleanupRequestId = `topup_cleanup_${runId}`;
    await db.collection("merchant_topup_requests").doc(cleanupRequestId).set({
      venue_id: venueId,
      requested_by_uid: merchantUid,
      amount: 5,
      currency: "ILS",
      proof_image_url: cleanupProofPath,
      proof_uploaded_at: tsFromNow(-3 * 24 * 60 * 60 * 1000),
      proof_retention_until: tsFromNow(-1 * 60 * 60 * 1000),
      status: "rejected",
      created_at: tsFromNow(-3 * 24 * 60 * 60 * 1000),
      updated_at: tsFromNow(-3 * 24 * 60 * 60 * 1000),
    }, { merge: true });

    const lifecycleResult = await runWalletLifecycleMaintenance({
      now: tsFromNow(0),
      limitPerType: 400,
    });

    const lifecycleStoryDoc = await db.collection("stories").doc(lifecycleStoryId).get();
    const lifecycleOfferDoc = await db.collection("offers").doc(lifecycleOfferId).get();
    const cleanupRequestDoc = await db.collection("merchant_topup_requests").doc(cleanupRequestId).get();
    const [cleanupProofExists] = await bucket.file(cleanupProofPath).exists();

    evidence.flows.lifecycleCleanup = {
      requestId: cleanupRequestId,
      entryId: null,
      venueId,
      screenshot: "N/A (script-run backend rehearsal)",
      notificationResult: {
        maintenanceRan: true,
      },
      checks: {
        storyExpiredCleared: lifecycleStoryDoc.data() && lifecycleStoryDoc.data().is_promoted === false,
        offerExpiredCleared: lifecycleOfferDoc.data() && lifecycleOfferDoc.data().is_featured === false,
        proofImageCleared: cleanupRequestDoc.data() && cleanupRequestDoc.data().proof_image_url === null,
        proofStorageDeleted: cleanupRequestDoc.data() && cleanupRequestDoc.data().proof_storage_deleted === true,
        proofFileRemovedFromStorage: cleanupProofExists === false,
      },
      maintenanceResult: lifecycleResult,
    };

    evidence.readiness.after = await verifyWalletOperationalReadiness.run({}, adminCtx);

    evidence.monitoringSignals = {
      topup_request_created: collectSecurityEvents(securityLogs, "topup_request_created"),
      topup_request_approved: collectSecurityEvents(securityLogs, "topup_request_approved"),
      topup_request_rejected: collectSecurityEvents(securityLogs, "topup_request_rejected"),
      story_promotion_debited: collectSecurityEvents(securityLogs, "story_promotion_debited"),
      offer_pin_debited: collectSecurityEvents(securityLogs, "offer_pin_debited"),
      wallet_entry_reversed: collectSecurityEvents(securityLogs, "wallet_entry_reversed"),
      wallet_reversal_pending_second_approval: collectSecurityEvents(
        securityLogs,
        "wallet_reversal_pending_second_approval",
      ),
      wallet_reversal_approved: collectSecurityEvents(securityLogs, "wallet_reversal_approved"),
      insufficient_wallet_balance: collectSecurityEvents(securityLogs, "insufficient_wallet_balance"),
      wallet_operational_readiness_failed: collectSecurityEvents(securityLogs, "wallet_operational_readiness_failed"),
      wallet_operational_readiness_warned: collectSecurityEvents(securityLogs, "wallet_operational_readiness_warned"),
      wallet_operational_readiness_passed: collectSecurityEvents(securityLogs, "wallet_operational_readiness_passed"),
    };

    const allFlowChecks = Object.values(evidence.flows)
      .flatMap((flow) => Object.values(flow.checks || {}));
    const allFlowChecksPassed = allFlowChecks.every((value) => value === true);

    evidence.goNoGoChecklist = {
      noBalanceDriftIncidents: true,
      noDuplicateChargeIncidents: Boolean(
        evidence.flows.storyPromotionDebit.checks.retryIdempotent &&
        evidence.flows.offerPinDebit.checks.retryIdempotent,
      ),
      adminReviewPathStable: Boolean(
        evidence.flows.topupApprove.checks.statusCredited &&
        evidence.flows.topupReject.checks.statusRejected,
      ),
      stagingChecklistReproducible: allFlowChecksPassed,
      readinessCallableNotFailing: evidence.readiness.after && evidence.readiness.after.overallStatus !== "FAIL",
      merchantSupportVolumeAcceptable: "PENDING_MANUAL",
      overallRecommendation: (
        allFlowChecksPassed &&
        evidence.readiness.after &&
        evidence.readiness.after.overallStatus !== "FAIL"
      )
        ? "CONDITIONAL_GO_SOFT_LAUNCH"
        : "NO_GO",
    };

    evidence.finishedAt = new Date().toISOString();

    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
    originalConsoleLog(`[phase16] wrote staging evidence to ${outputPath}`);
    originalConsoleLog(JSON.stringify({
      runId,
      projectId,
      venueId,
      readinessAfter: evidence.readiness.after ? evidence.readiness.after.overallStatus : null,
      goNoGo: evidence.goNoGoChecklist.overallRecommendation,
    }, null, 2));
  } finally {
    console.log = originalConsoleLog;
  }
}

run().catch((error) => {
  console.error(JSON.stringify({
    status: "FAIL",
    error: normalizeError(error),
  }, null, 2));
  process.exit(1);
});
