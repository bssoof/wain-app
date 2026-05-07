import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import {
  AdminAccessResult,
  requireAdminAccessWithDb,
  resolveAdminExecutionRole,
  resolveRequiredSecondApproverRole,
} from "./shared/admin-auth";
import { normalizeNumber } from "./shared/admin-surface-helpers";
import { db } from "./shared/firestore-db";
import { getDefaultStorageBucket } from "./shared/storage";
import {
  formatCurrencyAmount,
  sendWalletAdminNotification,
  sendWalletMerchantNotification,
} from "./shared/wallet-notifications";

const TOPUP_PROOF_RETENTION_DAYS = 180;
const REVERSIBLE_FEATURE_KEYS = new Set(["story_promotion", "offer_pin"]);
const REVERSAL_SINGLE_APPROVAL_LIMIT_ILS = 100;
const REVERSAL_SUPER_ADMIN_THRESHOLD_ILS = 500;
const REVERSAL_APPROVAL_REQUEST_EXPIRY_MS = 24 * 60 * 60 * 1000;

type WalletReportData = {
  venue_id: string;
  currency: string;
  total_credited: number;
  topup_total_credited: number;
  total_debited: number;
  last_30d_debited: number;
  debit_by_feature: Record<string, number>;
  debit_count_by_feature: Record<string, number>;
  most_used_debit_feature: string | null;
  last_top_up_amount: number | null;
  updated_at: Timestamp;
  last_entry_at: Timestamp | null;
};

async function requireAdminAccess(
  context: functions.https.CallableContext,
): Promise<AdminAccessResult> {
  return requireAdminAccessWithDb(context, db);
}

function resolveMostUsedDebitFeature(
  debitCountByFeature: Record<string, number>,
): string | null {
  let bestFeature: string | null = null;
  let bestCount = 0;
  for (const [feature, count] of Object.entries(debitCountByFeature)) {
    if (count > bestCount) {
      bestFeature = feature;
      bestCount = count;
    }
  }
  return bestFeature;
}

function baseWalletReport({
  venueId,
  currency,
  now,
}: {
  venueId: string;
  currency: string;
  now: Timestamp;
}): WalletReportData {
  return {
    venue_id: venueId,
    currency,
    total_credited: 0,
    topup_total_credited: 0,
    total_debited: 0,
    last_30d_debited: 0,
    debit_by_feature: {},
    debit_count_by_feature: {},
    most_used_debit_feature: null,
    last_top_up_amount: null,
    updated_at: now,
    last_entry_at: null,
  };
}

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

function normalizeAdminNote(value: unknown, maxLength: number = 500): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  if (!normalized) return null;
  return normalized.slice(0, maxLength);
}

async function upsertWalletAuditEvent(
  id: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await db.collection("wallet_audit_events").doc(id).set(payload, { merge: true });
}

export async function rebuildWalletReportForVenue(
  venueId: string,
  now: Timestamp = Timestamp.now(),
): Promise<WalletReportData> {
  const normalizedVenueId = venueId.trim();
  if (!normalizedVenueId) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_venue_id");
  }

  const cutoff30d = Timestamp.fromMillis(
    now.toMillis() - 30 * 24 * 60 * 60 * 1000,
  );
  const walletDoc = await db.collection("merchant_wallets").doc(normalizedVenueId).get();
  const walletCurrency = typeof walletDoc.data()?.currency === "string" &&
      walletDoc.data()!.currency.trim().length > 0
    ? walletDoc.data()!.currency.trim()
    : "ILS";

  const report = baseWalletReport({
    venueId: normalizedVenueId,
    currency: walletCurrency,
    now,
  });

  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let hasLatestTopUp = false;
  while (true) {
    let query = db.collection("merchant_wallets")
      .doc(normalizedVenueId)
      .collection("entries")
      .orderBy("created_at", "desc")
      .limit(300);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const entry = doc.data();
      const amount = roundMoney(normalizeNumber(entry.amount));
      const entryType = typeof entry.type === "string" ? entry.type : "debit";
      const createdAt = entry.created_at instanceof Timestamp ? entry.created_at : now;
      const featureKey = typeof entry.feature_key === "string" && entry.feature_key.trim().length > 0
        ? entry.feature_key.trim()
        : "other";

      if (!(report.last_entry_at instanceof Timestamp) ||
          createdAt.toMillis() > report.last_entry_at.toMillis()) {
        report.last_entry_at = createdAt;
      }

      if (entryType === "credit") {
        report.total_credited = roundMoney(report.total_credited + amount);
        if (entry.reference_type === "topup_request") {
          report.topup_total_credited = roundMoney(report.topup_total_credited + amount);
        }
        if (!hasLatestTopUp && entry.reference_type === "topup_request") {
          report.last_top_up_amount = amount;
          hasLatestTopUp = true;
        }
        continue;
      }

      report.total_debited = roundMoney(report.total_debited + amount);
      report.debit_by_feature[featureKey] = roundMoney(
        normalizeNumber(report.debit_by_feature[featureKey]) + amount,
      );
      report.debit_count_by_feature[featureKey] = normalizeNumber(
        report.debit_count_by_feature[featureKey],
      ) + 1;

      if (createdAt.toMillis() >= cutoff30d.toMillis()) {
        report.last_30d_debited = roundMoney(report.last_30d_debited + amount);
      }
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < 300) break;
  }

  report.most_used_debit_feature = resolveMostUsedDebitFeature(report.debit_count_by_feature);
  report.updated_at = now;

  await db.collection("merchant_wallet_reports").doc(normalizedVenueId).set(report, { merge: true });
  return report;
}

export const createMerchantTopUpRequest = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);

  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const amount = typeof data?.amount === "number" ? data.amount : 0;
  if (amount <= 0 || amount > 100000) {
    throw new functions.https.HttpsError("invalid-argument", "Valid amount is required");
  }

  const proofImageUrl = typeof data?.proof_image_url === "string" ? data.proof_image_url.trim() : null;
  const transferReference = typeof data?.transfer_reference === "string" ? data.transfer_reference.trim() : null;
  const note = typeof data?.note === "string" ? data.note.trim() : null;

  const uid = context.auth.uid;

  const merchantDoc = await db.collection("merchants").doc(uid).get();
  if (!merchantDoc.exists) {
    throw new functions.https.HttpsError("permission-denied", "Not a merchant");
  }

  const venueId = merchantDoc.data()!.venue_id;
  if (!venueId) {
    throw new functions.https.HttpsError("failed-precondition", "Merchant has no venue");
  }
  if (proofImageUrl && !proofImageUrl.startsWith(`venues/${venueId}/wallet_topups/`)) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_proof_storage_path");
  }
  if (proofImageUrl) {
    const [proofExists] = await getDefaultStorageBucket()
      .file(proofImageUrl)
      .exists();
    if (!proofExists) {
      throw new functions.https.HttpsError("invalid-argument", "proof_file_not_found");
    }
  }

  const now = Timestamp.now();
  const proofRetentionUntil = Timestamp.fromMillis(
    now.toMillis() + TOPUP_PROOF_RETENTION_DAYS * 24 * 60 * 60 * 1000,
  );

  const walletRef = db.collection("merchant_wallets").doc(venueId);
  const requestRef = db.collection("merchant_topup_requests").doc();

  await db.runTransaction(async (t) => {
    const walletDoc = await t.get(walletRef);
    if (!walletDoc.exists) {
      t.set(walletRef, {
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
    }

    t.set(requestRef, {
      venue_id: venueId,
      requested_by_uid: uid,
      amount,
      currency: "ILS",
      proof_image_url: proofImageUrl,
      proof_uploaded_at: proofImageUrl ? now : null,
      proof_retention_until: proofImageUrl ? proofRetentionUntil : null,
      transfer_reference: transferReference,
      note,
      status: "pending",
      admin_note: null,
      reviewed_at: null,
      reviewed_by_uid: null,
      linked_entry_id: null,
      created_at: now,
      updated_at: now,
    });
  });

  const topupCreatedEvent = {
    uid,
    venueId,
    requestId: requestRef.id,
    amount,
    hasProof: Boolean(proofImageUrl),
    timestamp: now.toMillis(),
  };
  logSecurityAudit("createMerchantTopUpRequest", topupCreatedEvent);
  logSecurityAudit("topup_request_created", topupCreatedEvent);
  await upsertWalletAuditEvent(
    `topup_request_${requestRef.id}`,
    {
      category: "topup_request",
      event_type: "topup_request_created",
      request_id: requestRef.id,
      venue_id: venueId,
      requested_by_uid: uid,
      amount,
      currency: "ILS",
      proof_image_url: proofImageUrl,
      proof_retention_until: proofImageUrl ? proofRetentionUntil : null,
      status: "pending",
      created_at: now,
      updated_at: now,
    },
  );
  await sendWalletAdminNotification(db, {
    venueId,
    eventKeyPrefix: `wallet_topup_created_${requestRef.id}`,
    title: "طلب شحن جديد",
    body: `يوجد طلب شحن جديد بقيمة ${formatCurrencyAmount(amount, "ILS")} للمحل ${venueId}.`,
    type: "wallet_topup_request_created",
    data: {
      venue_id: venueId,
      request_id: requestRef.id,
      amount,
      requested_by_uid: uid,
      has_proof: Boolean(proofImageUrl),
    },
  });

  return { success: true };
});

export const reviewMerchantTopUpRequest = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const { uid, source: reviewerAuthSource } = await requireAdminAccess(context);

  const requestId = data?.requestId;
  const decision = data?.decision;
  const adminNote = typeof data?.adminNote === "string" ? data.adminNote.trim() : null;

  if (!requestId || (decision !== "credit" && decision !== "reject")) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid arguments");
  }
  if (decision === "reject" && !adminNote) {
    throw new functions.https.HttpsError("invalid-argument", "admin_note_required_for_reject");
  }

  const requestRef = db.collection("merchant_topup_requests").doc(requestId);

  let auditData: Record<string, unknown> | null = null;
  let auditEvent = "reviewMerchantTopUpRequest";
  let normalizedReviewEvent: "topup_request_approved" | "topup_request_rejected" | null = null;
  let reportVenueId: string | null = null;
  let approvedRequestId: string | null = null;
  let reviewAuditEventData: Record<string, unknown> | null = null;
  let notificationPayload:
    | {
      venueId: string;
      eventKeyPrefix: string;
      title: string;
      body: string;
      type: string;
      data: Record<string, unknown>;
    }
    | null = null;

  await db.runTransaction(async (t) => {
    const reqDoc = await t.get(requestRef);
    if (!reqDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Request not found");
    }

    const reqData = reqDoc.data()!;
    if (reqData.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "Request already processed");
    }

    const venueId = reqData.venue_id;
    const amount = reqData.amount;
    const now = Timestamp.now();
    reportVenueId = typeof venueId === "string" ? venueId : null;

    if (decision === "reject") {
      t.update(requestRef, {
        status: "rejected",
        admin_note: adminNote,
        reviewed_at: now,
        reviewed_by_uid: uid,
        updated_at: now,
      });
      auditData = {
        adminUid: uid,
        authSource: reviewerAuthSource,
        venueId,
        requestId,
        decision: "reject",
        linkedEntryId: null,
        timestamp: now.toMillis(),
      };
      reviewAuditEventData = {
        category: "topup_review",
        event_type: "topup_request_rejected",
        request_id: requestId,
        venue_id: venueId,
        reviewed_by_uid: uid,
        decision: "reject",
        linked_entry_id: null,
        proof_image_url: reqData.proof_image_url ?? null,
        proof_retention_until: reqData.proof_retention_until ?? null,
        proof_deleted_at: reqData.proof_deleted_at ?? null,
        proof_storage_deleted: reqData.proof_storage_deleted ?? null,
        created_at: now,
        updated_at: now,
      };
      normalizedReviewEvent = "topup_request_rejected";
      if (typeof venueId === "string") {
        notificationPayload = {
          venueId,
          eventKeyPrefix: `wallet_topup_rejected_${requestId}`,
          title: "تم رفض طلب الشحن",
          body: adminNote
            ? `تم رفض طلب الشحن. السبب: ${adminNote}`
            : "تم رفض طلب الشحن. راجع التفاصيل داخل التطبيق.",
          type: "wallet_topup_request_rejected",
          data: {
            venue_id: venueId,
            request_id: requestId,
            decision: "reject",
          },
        };
      }
      return;
    }

    const walletRef = db.collection("merchant_wallets").doc(venueId);
    const walletDoc = await t.get(walletRef);
    let currentBalance = 0;

    if (!walletDoc.exists) {
      t.set(walletRef, {
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
    } else {
      currentBalance = walletDoc.data()!.available_balance || 0;
      if (walletDoc.data()!.status !== "active") {
        throw new functions.https.HttpsError("failed-precondition", "Wallet is suspended or closed");
      }
    }

    const newBalance = currentBalance + amount;
    const entryRef = walletRef.collection("entries").doc();

    t.set(entryRef, {
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
      created_by_uid: uid,
      note: adminNote || "Approved top-up request",
      metadata: {},
      created_at: now,
    });

    t.update(walletRef, {
      available_balance: newBalance,
      last_entry_at: now,
      last_top_up_at: now,
      updated_at: now,
    });

    t.update(requestRef, {
      status: "credited",
      admin_note: adminNote,
      reviewed_at: now,
      reviewed_by_uid: uid,
      linked_entry_id: entryRef.id,
      updated_at: now,
    });

    auditData = {
      adminUid: uid,
      authSource: reviewerAuthSource,
      venueId,
      requestId,
      decision: "credit",
      linkedEntryId: entryRef.id,
      amountAdded: amount,
      newBalance,
      timestamp: now.toMillis(),
    };
    approvedRequestId = requestId;
    reviewAuditEventData = {
      category: "topup_review",
      event_type: "topup_request_approved",
      request_id: requestId,
      venue_id: venueId,
      reviewed_by_uid: uid,
      decision: "credit",
      linked_entry_id: entryRef.id,
      amount,
      balance_after: newBalance,
      proof_image_url: reqData.proof_image_url ?? null,
      proof_retention_until: reqData.proof_retention_until ?? null,
      proof_deleted_at: reqData.proof_deleted_at ?? null,
      proof_storage_deleted: reqData.proof_storage_deleted ?? null,
      created_at: now,
      updated_at: now,
    };
    auditEvent = "reviewMerchantTopUpRequest_Credit";
    normalizedReviewEvent = "topup_request_approved";
    if (typeof venueId === "string") {
      notificationPayload = {
        venueId,
        eventKeyPrefix: `wallet_topup_approved_${requestId}`,
        title: "تم شحن رصيدك",
        body: `تمت إضافة ${formatCurrencyAmount(amount, "ILS")} إلى رصيد وين.`,
        type: "wallet_topup_request_approved",
        data: {
          venue_id: venueId,
          request_id: requestId,
          decision: "credit",
          amount,
        },
      };
    }
  });

  if (auditData) {
    logSecurityAudit(auditEvent, auditData);
    if (normalizedReviewEvent) {
      logSecurityAudit(normalizedReviewEvent, auditData);
    }
  }
  if (reviewAuditEventData) {
    await upsertWalletAuditEvent(
      `topup_review_${requestId}`,
      reviewAuditEventData,
    );
  }
  if (reportVenueId && approvedRequestId) {
    await rebuildWalletReportForVenue(reportVenueId);
  }
  if (notificationPayload) {
    await sendWalletMerchantNotification(db, notificationPayload);
  }

  return { success: true };
});

type WalletReversalExecutionParams = {
  entryId: string;
  venueId: string;
  reason: string;
  adminNote: string | null;
  adminUid: string;
  authSource: "claim" | "document";
  now: Timestamp;
};

type WalletReversalExecutionResult = {
  venueId: string;
  entryId: string;
  reversalEntryId: string;
  balanceAfter: number;
  originalAmount: number;
  originalFeatureKey: string;
  referenceType: string | null;
  referenceId: string | null;
};

async function executeWalletReversal(
  params: WalletReversalExecutionParams,
): Promise<WalletReversalExecutionResult> {
  const {
    entryId,
    venueId,
    reason,
    adminNote,
    adminUid,
    authSource,
    now,
  } = params;

  const walletRef = db.collection("merchant_wallets").doc(venueId);
  const originalEntryRef = walletRef.collection("entries").doc(entryId);
  const reversalEntryRef = walletRef.collection("entries").doc(`reversal_${entryId}`);

  let newBalance = 0;
  let originalFeatureKey = "manual_reversal";
  let originalAmount = 0;
  let referenceType: string | null = null;
  let referenceId: string | null = null;
  let reversalNotification:
    | {
      venueId: string;
      eventKeyPrefix: string;
      title: string;
      body: string;
      type: string;
      data: Record<string, unknown>;
    }
    | null = null;

  await db.runTransaction(async (t) => {
    const [walletDoc, originalEntryDoc, reversalEntryDoc] = await Promise.all([
      t.get(walletRef),
      t.get(originalEntryRef),
      t.get(reversalEntryRef),
    ]);
    if (!walletDoc.exists) {
      throw new functions.https.HttpsError("failed-precondition", "wallet_not_found");
    }
    if (!originalEntryDoc.exists) {
      throw new functions.https.HttpsError("not-found", "entry_not_found");
    }

    const walletData = walletDoc.data() ?? {};
    if (walletData.status !== "active") {
      throw new functions.https.HttpsError("failed-precondition", "wallet_inactive");
    }

    const originalEntry = originalEntryDoc.data() ?? {};
    if (originalEntry.venue_id !== venueId) {
      throw new functions.https.HttpsError("failed-precondition", "entry_venue_mismatch");
    }
    if (originalEntry.type !== "debit") {
      throw new functions.https.HttpsError("failed-precondition", "reversal_only_for_debit");
    }
    const featureKey = typeof originalEntry.feature_key === "string"
      ? originalEntry.feature_key
      : "";
    if (!REVERSIBLE_FEATURE_KEYS.has(featureKey)) {
      throw new functions.https.HttpsError("failed-precondition", "unsupported_reversal_feature");
    }
    if (typeof originalEntry.reversal_entry_id === "string" &&
        originalEntry.reversal_entry_id.trim().length > 0) {
      throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
    }
    if (reversalEntryDoc.exists) {
      throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
    }

    originalAmount = roundMoney(normalizeNumber(originalEntry.amount));
    if (originalAmount <= 0) {
      throw new functions.https.HttpsError("failed-precondition", "invalid_original_amount");
    }
    originalFeatureKey = featureKey;
    referenceType = typeof originalEntry.reference_type === "string"
      ? originalEntry.reference_type
      : null;
    referenceId = typeof originalEntry.reference_id === "string"
      ? originalEntry.reference_id
      : null;

    if (originalFeatureKey === "story_promotion" && referenceType === "story" && referenceId) {
      const storyRef = db.collection("stories").doc(referenceId);
      const storyDoc = await t.get(storyRef);
      if (storyDoc.exists) {
        const storyVenueId = storyDoc.data()?.venue_id;
        if (typeof storyVenueId === "string" && storyVenueId !== venueId) {
          throw new functions.https.HttpsError("failed-precondition", "entry_source_venue_mismatch");
        }
        t.update(storyRef, {
          is_promoted: false,
          promoted_until: now,
          updated_at: now,
        });
      }
    }
    if (originalFeatureKey === "offer_pin" && referenceType === "offer" && referenceId) {
      const offerRef = db.collection("offers").doc(referenceId);
      const offerDoc = await t.get(offerRef);
      if (offerDoc.exists) {
        const offerVenueId = offerDoc.data()?.venue_id;
        if (typeof offerVenueId === "string" && offerVenueId !== venueId) {
          throw new functions.https.HttpsError("failed-precondition", "entry_source_venue_mismatch");
        }
        t.update(offerRef, {
          is_featured: false,
          featured_until: now,
          updated_at: now,
        });
      }
    }

    const currentBalance = roundMoney(normalizeNumber(walletData.available_balance));
    newBalance = roundMoney(currentBalance + originalAmount);
    t.set(reversalEntryRef, {
      venue_id: venueId,
      type: "credit",
      amount: originalAmount,
      currency: typeof originalEntry.currency === "string" &&
          originalEntry.currency.trim().length > 0
        ? originalEntry.currency.trim()
        : "ILS",
      balance_after: newBalance,
      feature_key: originalFeatureKey || "manual_reversal",
      reference_type: referenceType,
      reference_id: referenceId,
      idempotency_key: `reversal_${entryId}`,
      created_by_type: "admin",
      created_by_uid: adminUid,
      note: adminNote ?? `Reversal for ${entryId}`,
      metadata: {
        reversal_of_entry_id: entryId,
        reversal_reason: reason,
        original_feature_key: originalFeatureKey,
        original_amount: originalAmount,
        admin_note: adminNote,
      },
      created_at: now,
    });

    t.update(originalEntryRef, {
      reversed_at: now,
      reversed_by_uid: adminUid,
      reversal_entry_id: reversalEntryRef.id,
    });

    t.update(walletRef, {
      available_balance: newBalance,
      last_entry_at: now,
      updated_at: now,
    });

    reversalNotification = {
      venueId,
      eventKeyPrefix: `wallet_reversal_${entryId}`,
      title: "تم عكس حركة رصيد",
      body: `تمت إعادة ${formatCurrencyAmount(
        originalAmount,
        typeof originalEntry.currency === "string" ? originalEntry.currency : "ILS",
      )} إلى رصيدك بسبب ${reason}.`,
      type: "wallet_entry_reversed",
      data: {
        venue_id: venueId,
        entry_id: entryId,
        reversal_entry_id: reversalEntryRef.id,
        amount: originalAmount,
        feature_key: originalFeatureKey,
        reason,
      },
    };
  });

  const reversalEntryId = `reversal_${entryId}`;
  await Promise.all([
    upsertWalletAuditEvent(`wallet_reversal_${entryId}`, {
      category: "wallet_reversal",
      event_type: "wallet_entry_reversed",
      venue_id: venueId,
      entry_id: entryId,
      reversal_entry_id: reversalEntryId,
      original_feature_key: originalFeatureKey,
      original_amount: originalAmount,
      reference_type: referenceType,
      reference_id: referenceId,
      reversal_reason: reason,
      reviewed_by_uid: adminUid,
      auth_source: authSource,
      created_at: now,
      updated_at: now,
    }),
    upsertWalletAuditEvent(`entry_${entryId}`, {
      reversal_entry_id: reversalEntryId,
      reversed_at: now,
      reversed_by_uid: adminUid,
      updated_at: now,
    }),
    upsertWalletAuditEvent(`entry_reversal_${entryId}`, {
      category: "wallet_entry",
      event_type: "wallet_entry",
      venue_id: venueId,
      entry_id: reversalEntryId,
      type: "credit",
      amount: originalAmount,
      feature_key: originalFeatureKey || "manual_reversal",
      reference_type: referenceType,
      reference_id: referenceId,
      reversal_of_entry_id: entryId,
      reversal_reason: reason,
      created_by_uid: adminUid,
      created_at: now,
      updated_at: now,
    }),
    rebuildWalletReportForVenue(venueId),
  ]);

  logSecurityAudit("wallet_entry_reversed", {
    adminUid,
    venueId,
    entryId,
    reversalEntryId,
    reason,
    balanceAfter: newBalance,
    timestamp: now.toMillis(),
  });
  if (reversalNotification) {
    await sendWalletMerchantNotification(db, reversalNotification);
  }

  return {
    venueId,
    entryId,
    reversalEntryId,
    balanceAfter: newBalance,
    originalAmount,
    originalFeatureKey,
    referenceType,
    referenceId,
  };
}

export const reverseWalletEntry = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const adminAccess = await requireAdminAccess(context);
  const { uid: adminUid, source: authSource } = adminAccess;
  const requesterRole = resolveAdminExecutionRole(context, adminAccess);

  const entryId = typeof data?.entryId === "string" ? data.entryId.trim() : "";
  const venueId = typeof data?.venueId === "string" ? data.venueId.trim() : "";
  const reason = typeof data?.reason === "string" ? data.reason.trim() : "";
  const adminNote = normalizeAdminNote(data?.adminNote);
  const commandId = typeof data?.commandId === "string" && data.commandId.trim().length > 0
    ? data.commandId.trim()
    : `reverse_wallet_entry_${entryId}`;
  const correlationId = typeof data?.correlationId === "string" && data.correlationId.trim().length > 0
    ? data.correlationId.trim()
    : null;
  const idempotencyKey = typeof data?.idempotencyKey === "string" && data.idempotencyKey.trim().length > 0
    ? data.idempotencyKey.trim()
    : commandId;
  const expectedState = data?.expectedState && typeof data.expectedState === "object"
    ? data.expectedState as Record<string, unknown>
    : null;

  if (!entryId || !venueId || !reason) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_reversal_arguments");
  }

  if (expectedState) {
    const expectedEntryType = typeof expectedState.entry_type === "string"
      ? expectedState.entry_type
      : null;
    const expectedEntryStatus = typeof expectedState.entry_status === "string"
      ? expectedState.entry_status
      : null;
    const expectedReversalState = typeof expectedState.reversal_state === "string"
      ? expectedState.reversal_state
      : null;
    if (
      expectedEntryType !== "debit" ||
      expectedEntryStatus !== "posted" ||
      expectedReversalState !== "not_reversed"
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "reverse_wallet_entry_expected_state_conflict",
      );
    }
  }

  const now = Timestamp.now();
  const walletRef = db.collection("merchant_wallets").doc(venueId);
  const originalEntryRef = walletRef.collection("entries").doc(entryId);
  const reversalEntryRef = walletRef.collection("entries").doc(`reversal_${entryId}`);
  const approvalRequestRef = db.collection("wallet_reversal_requests").doc(`reversal_request_${entryId}`);

  const [walletDoc, originalEntryDoc, reversalEntryDoc] = await Promise.all([
    walletRef.get(),
    originalEntryRef.get(),
    reversalEntryRef.get(),
  ]);

  if (!walletDoc.exists) {
    throw new functions.https.HttpsError("failed-precondition", "wallet_not_found");
  }
  if ((walletDoc.data() ?? {}).status !== "active") {
    throw new functions.https.HttpsError("failed-precondition", "wallet_inactive");
  }
  if (!originalEntryDoc.exists) {
    throw new functions.https.HttpsError("not-found", "entry_not_found");
  }
  const originalEntry = originalEntryDoc.data() ?? {};
  if (originalEntry.venue_id !== venueId) {
    throw new functions.https.HttpsError("failed-precondition", "entry_venue_mismatch");
  }
  if (originalEntry.type !== "debit") {
    throw new functions.https.HttpsError("failed-precondition", "reversal_only_for_debit");
  }
  const featureKey = typeof originalEntry.feature_key === "string"
    ? originalEntry.feature_key
    : "";
  if (!REVERSIBLE_FEATURE_KEYS.has(featureKey)) {
    throw new functions.https.HttpsError("failed-precondition", "unsupported_reversal_feature");
  }
  if (typeof originalEntry.reversal_entry_id === "string" &&
      originalEntry.reversal_entry_id.trim().length > 0) {
    throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
  }
  if (reversalEntryDoc.exists) {
    throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
  }

  const originalAmount = roundMoney(normalizeNumber(originalEntry.amount));
  if (originalAmount <= 0) {
    throw new functions.https.HttpsError("failed-precondition", "invalid_original_amount");
  }

  if (originalAmount > REVERSAL_SINGLE_APPROVAL_LIMIT_ILS) {
    const requiredSecondApproverRole = resolveRequiredSecondApproverRole(
      originalAmount,
      requesterRole,
      {
        singleApprovalLimitIls: REVERSAL_SINGLE_APPROVAL_LIMIT_ILS,
        superAdminThresholdIls: REVERSAL_SUPER_ADMIN_THRESHOLD_ILS,
      },
    );
    const approvalExpiresAt = Timestamp.fromMillis(
      now.toMillis() + REVERSAL_APPROVAL_REQUEST_EXPIRY_MS,
    );

    const pendingRequest = await db.runTransaction(async (t) => {
      const [walletTxnDoc, originalEntryTxnDoc, reversalEntryTxnDoc, approvalRequestDoc] = await Promise.all([
        t.get(walletRef),
        t.get(originalEntryRef),
        t.get(reversalEntryRef),
        t.get(approvalRequestRef),
      ]);

      if (!walletTxnDoc.exists || (walletTxnDoc.data() ?? {}).status !== "active") {
        throw new functions.https.HttpsError("failed-precondition", "wallet_inactive");
      }
      if (!originalEntryTxnDoc.exists) {
        throw new functions.https.HttpsError("not-found", "entry_not_found");
      }
      const originalEntryTxn = originalEntryTxnDoc.data() ?? {};
      if (originalEntryTxn.venue_id !== venueId) {
        throw new functions.https.HttpsError("failed-precondition", "entry_venue_mismatch");
      }
      if (originalEntryTxn.type !== "debit") {
        throw new functions.https.HttpsError("failed-precondition", "reversal_only_for_debit");
      }
      if (typeof originalEntryTxn.reversal_entry_id === "string" &&
          originalEntryTxn.reversal_entry_id.trim().length > 0) {
        throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
      }
      if (reversalEntryTxnDoc.exists) {
        throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
      }

      if (approvalRequestDoc.exists) {
        const existing = approvalRequestDoc.data() ?? {};
        const existingStatus = typeof existing.status === "string" ? existing.status : "";
        if (existingStatus === "pending_second_approval") {
          const existingCommandId = typeof existing.command_id === "string"
            ? existing.command_id
            : "";
          if (existingCommandId === commandId) {
            const existingExpiresAt = existing.expires_at instanceof Timestamp
              ? existing.expires_at
              : approvalExpiresAt;
            return {
              replay: true,
              reversalRequestId: approvalRequestRef.id,
              approvalExpiresAt: existingExpiresAt,
            };
          }

          throw new functions.https.HttpsError(
            "failed-precondition",
            "reversal_approval_already_pending",
          );
        }
        if (existingStatus === "approved_and_executed") {
          throw new functions.https.HttpsError("failed-precondition", "entry_already_reversed");
        }
      }

      t.set(approvalRequestRef, {
        request_id: approvalRequestRef.id,
        venue_id: venueId,
        entry_id: entryId,
        status: "pending_second_approval",
        requested_by_uid: adminUid,
        requested_by_role: requesterRole,
        auth_source: authSource,
        required_second_approver_role: requiredSecondApproverRole,
        requires_super_admin_second_approval: requiredSecondApproverRole === "super_admin",
        original_amount: originalAmount,
        currency: typeof originalEntryTxn.currency === "string" &&
            originalEntryTxn.currency.trim().length > 0
          ? originalEntryTxn.currency.trim()
          : "ILS",
        original_feature_key:
          typeof originalEntryTxn.feature_key === "string"
            ? originalEntryTxn.feature_key
            : null,
        reference_type:
          typeof originalEntryTxn.reference_type === "string"
            ? originalEntryTxn.reference_type
            : null,
        reference_id:
          typeof originalEntryTxn.reference_id === "string"
            ? originalEntryTxn.reference_id
            : null,
        reason,
        admin_note: adminNote,
        command_id: commandId,
        idempotency_key: idempotencyKey,
        correlation_id: correlationId,
        expected_state: expectedState,
        created_at: now,
        updated_at: now,
        submitted_at: now,
        expires_at: approvalExpiresAt,
      });

      return {
        replay: false,
        reversalRequestId: approvalRequestRef.id,
        approvalExpiresAt,
      };
    });

    if (!pendingRequest.replay) {
      await upsertWalletAuditEvent(`reversal_request_${pendingRequest.reversalRequestId}`, {
        category: "wallet_reversal",
        event_type: "wallet_reversal_pending_second_approval",
        venue_id: venueId,
        entry_id: entryId,
        request_id: pendingRequest.reversalRequestId,
        requested_by_uid: adminUid,
        requested_by_role: requesterRole,
        required_second_approver_role: requiredSecondApproverRole,
        original_amount: originalAmount,
        reason,
        command_id: commandId,
        correlation_id: correlationId,
        expires_at: pendingRequest.approvalExpiresAt,
        created_at: now,
        updated_at: now,
      });
    }

    logSecurityAudit("wallet_reversal_pending_second_approval", {
      adminUid,
      venueId,
      entryId,
      requestId: pendingRequest.reversalRequestId,
      originalAmount,
      requiredSecondApproverRole,
      replay: pendingRequest.replay,
      timestamp: now.toMillis(),
    });

    return {
      success: true,
      status: "pending_second_approval",
      venueId,
      entryId,
      reversalRequestId: pendingRequest.reversalRequestId,
      approvalExpiresAt: pendingRequest.approvalExpiresAt.toMillis(),
      requiredSecondApproverRole,
    };
  }

  const execution = await executeWalletReversal({
    entryId,
    venueId,
    reason,
    adminNote,
    adminUid,
    authSource,
    now,
  });

  return {
    success: true,
    status: "reversed",
    venueId: execution.venueId,
    entryId: execution.entryId,
    reversalEntryId: execution.reversalEntryId,
    balanceAfter: execution.balanceAfter,
  };
});

export const approveWalletReversalRequest = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const adminAccess = await requireAdminAccess(context);
  const { uid: approverUid, source: authSource } = adminAccess;
  const approverRole = resolveAdminExecutionRole(context, adminAccess);

  const reversalRequestId = typeof data?.reversalRequestId === "string"
    ? data.reversalRequestId.trim()
    : "";
  const commandId = typeof data?.commandId === "string"
    ? data.commandId.trim()
    : "";
  const reason = typeof data?.reason === "string" && data.reason.trim().length > 0
    ? data.reason.trim()
    : "Approved reversal request";
  const adminNote = normalizeAdminNote(data?.adminNote);
  const expectedState = data?.expectedState && typeof data.expectedState === "object"
    ? data.expectedState as Record<string, unknown>
    : null;

  if (!reversalRequestId || !commandId) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_reversal_approval_arguments");
  }

  if (
    !expectedState ||
    expectedState.approval_state !== "pending_second_approval" ||
    expectedState.request_not_expired !== true
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "reversal_approval_expected_state_conflict",
    );
  }

  const now = Timestamp.now();
  const approvalRequestRef = db.collection("wallet_reversal_requests").doc(reversalRequestId);
  const approvalRequestDoc = await approvalRequestRef.get();
  if (!approvalRequestDoc.exists) {
    throw new functions.https.HttpsError("not-found", "reversal_request_not_found");
  }

  const requestData = approvalRequestDoc.data() ?? {};
  const requestStatus = typeof requestData.status === "string" ? requestData.status : "";

  if (requestStatus === "approved_and_executed") {
    const existingApprovalCommandId = typeof requestData.approval_command_id === "string"
      ? requestData.approval_command_id
      : "";
    const existingExecutedReversalEntryId =
      typeof requestData.executed_reversal_entry_id === "string"
        ? requestData.executed_reversal_entry_id
        : "";
    if (
      existingApprovalCommandId === commandId &&
      existingExecutedReversalEntryId.length > 0
    ) {
      return {
        success: true,
        status: "approved_and_executed",
        reversalRequestId,
        executedReversalEntryId: existingExecutedReversalEntryId,
        approvedAt: requestData.approved_at instanceof Timestamp
          ? requestData.approved_at.toMillis()
          : now.toMillis(),
        venueId: typeof requestData.venue_id === "string" ? requestData.venue_id : null,
      };
    }

    throw new functions.https.HttpsError("failed-precondition", "reversal_request_already_executed");
  }

  if (requestStatus !== "pending_second_approval") {
    throw new functions.https.HttpsError("failed-precondition", "reversal_request_not_pending");
  }

  const expiresAt = requestData.expires_at instanceof Timestamp
    ? requestData.expires_at
    : null;
  if (expiresAt && expiresAt.toMillis() <= now.toMillis()) {
    await approvalRequestRef.set({
      status: "expired",
      expired_at: now,
      updated_at: now,
    }, { merge: true });
    throw new functions.https.HttpsError("failed-precondition", "reversal_request_expired");
  }

  const requesterUid = typeof requestData.requested_by_uid === "string"
    ? requestData.requested_by_uid
    : "";
  if (!requesterUid || requesterUid === approverUid) {
    throw new functions.https.HttpsError("failed-precondition", "second_approver_must_differ");
  }

  const requiredSecondApproverRole =
    typeof requestData.required_second_approver_role === "string"
      ? requestData.required_second_approver_role
      : "finance_admin";
  if (
    requiredSecondApproverRole === "super_admin" &&
    approverRole !== "super_admin"
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "super_admin_approval_required",
    );
  }

  const entryId = typeof requestData.entry_id === "string" ? requestData.entry_id : "";
  const venueId = typeof requestData.venue_id === "string" ? requestData.venue_id : "";
  if (!entryId || !venueId) {
    throw new functions.https.HttpsError("failed-precondition", "invalid_reversal_request_state");
  }

  const execution = await executeWalletReversal({
    entryId,
    venueId,
    reason,
    adminNote,
    adminUid: approverUid,
    authSource,
    now,
  });

  await Promise.all([
    approvalRequestRef.set({
      status: "approved_and_executed",
      approval_state: "approved_and_executed",
      approved_by_uid: approverUid,
      approved_by_role: approverRole,
      approved_auth_source: authSource,
      approved_at: now,
      approval_command_id: commandId,
      executed_reversal_entry_id: execution.reversalEntryId,
      approval_reason: reason,
      approval_admin_note: adminNote,
      updated_at: now,
    }, { merge: true }),
    upsertWalletAuditEvent(`reversal_approval_${reversalRequestId}`, {
      category: "wallet_reversal",
      event_type: "wallet_reversal_approved_and_executed",
      request_id: reversalRequestId,
      venue_id: venueId,
      entry_id: entryId,
      executed_reversal_entry_id: execution.reversalEntryId,
      approved_by_uid: approverUid,
      approved_by_role: approverRole,
      approved_auth_source: authSource,
      approval_command_id: commandId,
      approved_at: now,
      created_at: now,
      updated_at: now,
    }),
  ]);

  logSecurityAudit("wallet_reversal_approved", {
    approverUid,
    approverRole,
    requestId: reversalRequestId,
    venueId,
    entryId,
    reversalEntryId: execution.reversalEntryId,
    timestamp: now.toMillis(),
  });

  return {
    success: true,
    status: "approved_and_executed",
    reversalRequestId,
    executedReversalEntryId: execution.reversalEntryId,
    approvedAt: now.toMillis(),
    venueId,
  };
});

// ============= MERCHANT PROMOTION FEATURES (promoteStory, pinOffer) =============
const STORY_PROMOTION_PRICING_FIELDS: Record<number, string> = {
  1: "story_promote_1d",
  3: "story_promote_3d",
  7: "story_promote_7d",
};
const OFFER_PIN_PRICING_FIELDS: Record<number, string> = {
  1: "offer_pin_1d",
  3: "offer_pin_3d",
  7: "offer_pin_7d",
};
function normalizePromotionRequestId(value: unknown): string {
  if (typeof value !== "string") return "";
  const normalized = value.trim();
  if (!normalized || normalized.length > 80 || normalized.includes("/")) {
    return "";
  }
  if (!/^[A-Za-z0-9_-]+$/.test(normalized)) {
    return "";
  }
  return normalized;
}

function resolveStoryPromotionPrice(
  pricingData: FirebaseFirestore.DocumentData | undefined,
  durationDays: number,
): { amount: number; currency: string } {
  const fieldName = STORY_PROMOTION_PRICING_FIELDS[durationDays];
  if (!fieldName || !pricingData) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "pricing_unavailable",
    );
  }

  const amount = (pricingData[fieldName] as number | undefined);
  const currency = typeof pricingData.currency === "string" &&
      pricingData.currency.trim().length > 0
    ? pricingData.currency.trim()
    : "ILS";

  if (typeof amount !== "number" || !Number.isFinite(amount) || amount <= 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "pricing_unavailable",
    );
  }

  return {
    amount: roundMoney(amount),
    currency,
  };
}

function resolveOfferPinPrice(
  pricingData: FirebaseFirestore.DocumentData | undefined,
  durationDays: number,
): { amount: number; currency: string } {
  const fieldName = OFFER_PIN_PRICING_FIELDS[durationDays];
  if (!fieldName || !pricingData) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "pricing_unavailable",
    );
  }

  const amount = (pricingData[fieldName] as number | undefined);
  const currency = typeof pricingData.currency === "string" &&
      pricingData.currency.trim().length > 0
    ? pricingData.currency.trim()
    : "ILS";

  if (typeof amount !== "number" || !Number.isFinite(amount) || amount <= 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "pricing_unavailable",
    );
  }

  return {
    amount: roundMoney(amount),
    currency,
  };
}
// 9. Promote Story (Paid Feature Simulation)
// Input: storyId, durationDays (int)
// Security: App Check + Auth + Ownership
export const promoteStory = functions.https.onCall(async (data, context) => {
    // 1. Security Checks
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    requireAppCheck(context);

    const { storyId, durationDays } = data;
    const requestId = normalizePromotionRequestId(data?.requestId);

    if (!storyId || typeof storyId !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "Invalid story ID");
    }
    if (!durationDays || typeof durationDays !== 'number' ||
        !Number.isInteger(durationDays) ||
        !(durationDays in STORY_PROMOTION_PRICING_FIELDS)) {
        throw new functions.https.HttpsError("invalid-argument", "unsupported_promotion_duration");
    }
    if (!requestId) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid request ID");
    }

    const uid = context.auth.uid;

    // 2. Fetch Merchant Profile & Story
    // We need to find the story. Since we don't know the venueId from input (securely),
    // we should first get the merchant's venueId.

    const merchantDoc = await db.collection("merchants").doc(uid).get();
    if (!merchantDoc.exists) {
        throw new functions.https.HttpsError("permission-denied", "Not a merchant");
    }

    const venueId = merchantDoc.data()!.venue_id;
    if (!venueId) {
        throw new functions.https.HttpsError("failed-precondition", "Merchant has no venue");
    }
    // Stories are stored in top-level "stories" collection.
    const storyRef = db.collection("stories").doc(storyId);
    const venueRef = db.collection("venues").doc(venueId);
    const walletRef = db.collection("merchant_wallets").doc(venueId);
    const pricingRef = db.collection("wallet_feature_pricing").doc("default");
    const entryRef = walletRef.collection("entries").doc(`story_promotion_${requestId}`);
    let auditPayload: Record<string, unknown> | null = null;
    let auditEvent = "promoteStory";
    let lowBalanceNotification: { balanceAfter: number; threshold: number } | null = null;

    const result = await db.runTransaction(async (t) => {
        const storyDoc = await t.get(storyRef);

        if (!storyDoc.exists) {
             throw new functions.https.HttpsError("not-found", "Story not found or access denied");
        }

        const story = storyDoc.data()!;
        const storyVenueId = story.venue_id;
        if (!storyVenueId || storyVenueId !== venueId) {
            throw new functions.https.HttpsError("permission-denied", "Cannot promote story outside your venue");
        }
        const [venueDoc, walletDoc, pricingDoc, existingEntryDoc] = await Promise.all([
          t.get(venueRef),
          t.get(walletRef),
          t.get(pricingRef),
          t.get(entryRef),
        ]);
        if (venueDoc.data()?.is_active === false) {
            throw new functions.https.HttpsError("failed-precondition", "venue_inactive");
        }
        const now = Timestamp.now();
        const expiresAt = story.expires_at; // Timestamp
        if (!(expiresAt instanceof Timestamp) || now.toMillis() > expiresAt.toMillis()) {
             throw new functions.https.HttpsError("failed-precondition", "story_expired");
        }

        if (existingEntryDoc.exists) {
            const existingEntry = existingEntryDoc.data() ?? {};
            const metadata = existingEntry.metadata as Record<string, unknown> | undefined;
            const existingStoryId = typeof metadata?.story_id === "string" ? metadata.story_id : "";
            const existingDuration = typeof metadata?.duration_days === "number" ? metadata.duration_days : null;
            if (existingStoryId !== storyId || existingDuration !== durationDays) {
                throw new functions.https.HttpsError("already-exists", "promotion_request_conflict");
            }

            const existingPromotedUntil = metadata?.promoted_until instanceof Timestamp
              ? metadata.promoted_until
              : (story.promoted_until instanceof Timestamp ? story.promoted_until : expiresAt);

            auditEvent = "promoteStory_idempotent";
            auditPayload = {
              uid,
              storyId,
              venueId,
              durationDays,
              requestId,
              chargedAmount: existingEntry.amount ?? null,
              balanceAfter: existingEntry.balance_after ?? null,
              timestamp: now.toMillis(),
              result: "idempotent",
            };

            return {
              success: true,
              promoted_until: existingPromotedUntil.toDate().toISOString(),
              clamped: existingPromotedUntil.toMillis() !== expiresAt.toMillis(),
              charged_amount: existingEntry.amount ?? null,
              balance_after: existingEntry.balance_after ?? null,
              idempotent: true,
            };
        }

        if (!walletDoc.exists) {
            throw new functions.https.HttpsError("failed-precondition", "wallet_not_found");
        }
        const walletData = walletDoc.data() ?? {};
        if (walletData.status !== "active") {
            throw new functions.https.HttpsError("failed-precondition", "wallet_inactive");
        }

        const pricing = resolveStoryPromotionPrice(pricingDoc.data(), durationDays);
        const currentBalance = typeof walletData.available_balance === "number"
          ? walletData.available_balance
          : 0;
        if (currentBalance < pricing.amount) {
            logSecurityAudit("insufficient_wallet_balance", {
              uid,
              venueId,
              storyId,
              requestId,
              requiredAmount: pricing.amount,
              availableBalance: currentBalance,
              timestamp: Timestamp.now().toMillis(),
            });
            throw new functions.https.HttpsError("failed-precondition", "insufficient_wallet_balance");
        }

        // 3. Calculate Promotion Period
        // Start from NOW (or extend if already promoted?) -> Business rule: From NOW.
        let promoteUntilDate = new Date();
        promoteUntilDate.setDate(promoteUntilDate.getDate() + durationDays);
        let promoteUntilTs = Timestamp.fromDate(promoteUntilDate);

        // 4. Clamp to Expiry
        // Cannot promote a story beyond its life
        if (promoteUntilTs.toMillis() > expiresAt.toMillis()) {
            promoteUntilTs = expiresAt;
        }

        const newBalance = roundMoney(currentBalance - pricing.amount);
        const lowBalanceThreshold = typeof walletData.low_balance_threshold === "number"
          ? roundMoney(walletData.low_balance_threshold)
          : 10;
        if (currentBalance > lowBalanceThreshold && newBalance <= lowBalanceThreshold) {
          lowBalanceNotification = {
            balanceAfter: newBalance,
            threshold: lowBalanceThreshold,
          };
        }
        t.set(entryRef, {
            venue_id: venueId,
            type: "debit",
            amount: pricing.amount,
            currency: pricing.currency,
            balance_after: newBalance,
            feature_key: "story_promotion",
            reference_type: "story",
            reference_id: storyId,
            idempotency_key: requestId,
            created_by_type: "merchant",
            created_by_uid: uid,
            note: `Story promotion (${durationDays}d)`,
            metadata: {
              request_id: requestId,
              story_id: storyId,
              duration_days: durationDays,
              promoted_until: promoteUntilTs,
            },
            created_at: now,
        });

        t.update(walletRef, {
            available_balance: newBalance,
            last_entry_at: now,
            updated_at: now,
        });

        // 5. Update Story
        t.update(storyRef, {
            promoted_until: promoteUntilTs,
            is_promoted: true, // Helper flag
            updated_at: now
        });

        auditPayload = {
          uid,
          storyId,
          venueId,
          durationDays,
          requestId,
          chargedAmount: pricing.amount,
          balanceAfter: newBalance,
          promotedUntil: promoteUntilTs.toMillis(),
          timestamp: now.toMillis(),
          result: "success",
        };

        return {
            success: true,
            promoted_until: promoteUntilTs.toDate().toISOString(),
            clamped: promoteUntilTs.toMillis() !== Timestamp.fromDate(new Date(Date.now() + durationDays * 86400000)).toMillis(), // Rough check
            charged_amount: pricing.amount,
            balance_after: newBalance,
            idempotent: false,
        };
    });

    if (auditPayload != null) {
      logSecurityAudit(auditEvent, auditPayload);
      if (auditEvent === "promoteStory") {
        logSecurityAudit("story_promotion_debited", auditPayload);
        const chargedAmount = normalizeNumber(
          (auditPayload as Record<string, unknown>)["chargedAmount"],
        );
        const balanceAfter = normalizeNumber(
          (auditPayload as Record<string, unknown>)["balanceAfter"],
        );
        await upsertWalletAuditEvent(
          `story_promotion_${requestId}`,
          {
            category: "wallet_debit",
            event_type: "story_promotion",
            venue_id: venueId,
            request_id: requestId,
            entry_id: `story_promotion_${requestId}`,
            story_id: storyId,
            duration_days: durationDays,
            amount: chargedAmount,
            balance_after: balanceAfter,
            created_at: Timestamp.now(),
            updated_at: Timestamp.now(),
          },
        );
        await rebuildWalletReportForVenue(venueId);
        const lowBalanceState = lowBalanceNotification as {
          balanceAfter: number;
          threshold: number;
        } | null;
        if (lowBalanceState) {
          await sendWalletMerchantNotification(db, {
            venueId,
            eventKeyPrefix: `wallet_low_balance_story_${requestId}`,
            title: "رصيد وين منخفض",
            body: `رصيدك الحالي ${formatCurrencyAmount(
              lowBalanceState.balanceAfter,
              "ILS",
            )}. يرجى شحن المحفظة قبل انتهاء الحملات.`,
            type: "wallet_low_balance",
            data: {
              venue_id: venueId,
              request_id: requestId,
              feature_key: "story_promotion",
              balance_after: lowBalanceState.balanceAfter,
              threshold: lowBalanceState.threshold,
            },
          });
        }
      }
    }

    return result;
});

export const pinOffer = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    requireAppCheck(context);

    const offerId = typeof data?.offerId === "string" ? data.offerId.trim() : "";
    const durationDays = data?.durationDays;
    const requestId = normalizePromotionRequestId(data?.requestId);
    if (!offerId) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid offer ID");
    }
    if (!durationDays || typeof durationDays !== "number" ||
        !Number.isInteger(durationDays) ||
        !(durationDays in OFFER_PIN_PRICING_FIELDS)) {
        throw new functions.https.HttpsError("invalid-argument", "unsupported_pin_duration");
    }
    if (!requestId) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid request ID");
    }

    const uid = context.auth.uid;
    const merchantDoc = await db.collection("merchants").doc(uid).get();
    if (!merchantDoc.exists) {
        throw new functions.https.HttpsError("permission-denied", "Not a merchant");
    }
    const venueId = merchantDoc.data()!.venue_id;
    if (!venueId) {
        throw new functions.https.HttpsError("failed-precondition", "Merchant has no venue");
    }

    const offerRef = db.collection("offers").doc(offerId);
    const walletRef = db.collection("merchant_wallets").doc(venueId);
    const pricingRef = db.collection("wallet_feature_pricing").doc("default");
    const entryRef = walletRef.collection("entries").doc(`offer_pin_${requestId}`);
    let auditPayload: Record<string, unknown> | null = null;
    let auditEvent = "pinOffer";
    let lowBalanceNotification: { balanceAfter: number; threshold: number } | null = null;

    const result = await db.runTransaction(async (t) => {
        const [offerDoc, walletDoc, pricingDoc, existingEntryDoc] = await Promise.all([
          t.get(offerRef),
          t.get(walletRef),
          t.get(pricingRef),
          t.get(entryRef),
        ]);
        if (!offerDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Offer not found");
        }
        const offerData = offerDoc.data() ?? {};
        if (offerData.venue_id !== venueId) {
            throw new functions.https.HttpsError("permission-denied", "Cannot feature another venue offer");
        }
        const now = Timestamp.now();
        if (offerData.is_active === false) {
            throw new functions.https.HttpsError("failed-precondition", "offer_inactive");
        }
        const offerEndAt = offerData.end_at;
        if (!(offerEndAt instanceof Timestamp) || offerEndAt.toMillis() <= now.toMillis()) {
            throw new functions.https.HttpsError("failed-precondition", "offer_expired");
        }

        if (existingEntryDoc.exists) {
            const existingEntry = existingEntryDoc.data() ?? {};
            const metadata = existingEntry.metadata as Record<string, unknown> | undefined;
            const existingOfferId = typeof metadata?.offer_id === "string" ? metadata.offer_id : "";
            const existingDuration = typeof metadata?.duration_days === "number" ? metadata.duration_days : null;
            if (existingOfferId !== offerId || existingDuration !== durationDays) {
                throw new functions.https.HttpsError("already-exists", "pin_request_conflict");
            }
            const existingFeaturedUntil = metadata?.featured_until instanceof Timestamp
              ? metadata.featured_until
              : offerEndAt;
            auditEvent = "pinOffer_idempotent";
            auditPayload = {
              uid,
              offerId,
              venueId,
              durationDays,
              requestId,
              chargedAmount: existingEntry.amount ?? null,
              balanceAfter: existingEntry.balance_after ?? null,
              timestamp: now.toMillis(),
              result: "idempotent",
            };
            return {
              success: true,
              featured_until: existingFeaturedUntil.toDate().toISOString(),
              clamped: metadata?.clamped == true,
              charged_amount: existingEntry.amount ?? null,
              balance_after: existingEntry.balance_after ?? null,
              idempotent: true,
            };
        }

        if (!walletDoc.exists) {
            throw new functions.https.HttpsError("failed-precondition", "wallet_not_found");
        }
        const walletData = walletDoc.data() ?? {};
        if (walletData.status !== "active") {
            throw new functions.https.HttpsError("failed-precondition", "wallet_inactive");
        }
        const pricing = resolveOfferPinPrice(pricingDoc.data(), durationDays);
        const currentBalance = typeof walletData.available_balance === "number"
          ? walletData.available_balance
          : 0;
        if (currentBalance < pricing.amount) {
            throw new functions.https.HttpsError("failed-precondition", "insufficient_wallet_balance");
        }

        let featuredUntilTs = Timestamp.fromDate(
          new Date(now.toMillis() + durationDays * 24 * 60 * 60 * 1000),
        );
        let clamped = false;
        if (featuredUntilTs.toMillis() > offerEndAt.toMillis()) {
            featuredUntilTs = offerEndAt;
            clamped = true;
        }
        const newBalance = roundMoney(currentBalance - pricing.amount);
        const lowBalanceThreshold = typeof walletData.low_balance_threshold === "number"
          ? roundMoney(walletData.low_balance_threshold)
          : 10;
        if (currentBalance > lowBalanceThreshold && newBalance <= lowBalanceThreshold) {
          lowBalanceNotification = {
            balanceAfter: newBalance,
            threshold: lowBalanceThreshold,
          };
        }
        t.set(entryRef, {
            venue_id: venueId,
            type: "debit",
            amount: pricing.amount,
            currency: pricing.currency,
            balance_after: newBalance,
            feature_key: "offer_pin",
            reference_type: "offer",
            reference_id: offerId,
            idempotency_key: requestId,
            created_by_type: "merchant",
            created_by_uid: uid,
            note: `Offer pin (${durationDays}d)`,
            metadata: {
              request_id: requestId,
              offer_id: offerId,
              duration_days: durationDays,
              featured_until: featuredUntilTs,
              clamped,
            },
            created_at: now,
        });
        t.update(walletRef, {
            available_balance: newBalance,
            last_entry_at: now,
            updated_at: now,
        });
        t.update(offerRef, {
            featured_until: featuredUntilTs,
            is_featured: true,
            updated_at: now,
        });
        auditPayload = {
          uid,
          offerId,
          venueId,
          durationDays,
          requestId,
          chargedAmount: pricing.amount,
          balanceAfter: newBalance,
          featuredUntil: featuredUntilTs.toMillis(),
          clamped,
          timestamp: now.toMillis(),
          result: "success",
        };
        return {
            success: true,
            featured_until: featuredUntilTs.toDate().toISOString(),
            clamped,
            charged_amount: pricing.amount,
            balance_after: newBalance,
            idempotent: false,
        };
    });

    if (auditPayload != null) {
      logSecurityAudit(auditEvent, auditPayload);
      if (auditEvent === "pinOffer") {
        logSecurityAudit("offer_pin_debited", auditPayload);
        const chargedAmount = normalizeNumber(
          (auditPayload as Record<string, unknown>)["chargedAmount"],
        );
        const balanceAfter = normalizeNumber(
          (auditPayload as Record<string, unknown>)["balanceAfter"],
        );
        await upsertWalletAuditEvent(
          `offer_pin_${requestId}`,
          {
            category: "wallet_debit",
            event_type: "offer_pin",
            venue_id: venueId,
            request_id: requestId,
            entry_id: `offer_pin_${requestId}`,
            offer_id: offerId,
            duration_days: durationDays,
            amount: chargedAmount,
            balance_after: balanceAfter,
            created_at: Timestamp.now(),
            updated_at: Timestamp.now(),
          },
        );
        await rebuildWalletReportForVenue(venueId);
        const lowBalanceState = lowBalanceNotification as {
          balanceAfter: number;
          threshold: number;
        } | null;
        if (lowBalanceState) {
          await sendWalletMerchantNotification(db, {
            venueId,
            eventKeyPrefix: `wallet_low_balance_offer_${requestId}`,
            title: "رصيد وين منخفض",
            body: `رصيدك الحالي ${formatCurrencyAmount(
              lowBalanceState.balanceAfter,
              "ILS",
            )}. يرجى شحن المحفظة قبل تثبيت عروض جديدة.`,
            type: "wallet_low_balance",
            data: {
              venue_id: venueId,
              request_id: requestId,
              feature_key: "offer_pin",
              balance_after: lowBalanceState.balanceAfter,
              threshold: lowBalanceState.threshold,
            },
          });
        }
      }
    }
    return result;
});
