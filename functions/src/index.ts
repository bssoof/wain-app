import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import * as crypto from "crypto";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import {
  requireAdminAccessWithDb,
} from "./shared/admin-auth";
import {
  financeTimestampToIso,
  financeTimestampToIsoWithFallback,
  financeTimestampToMillis,
  financeTimestampToOptionalIso,
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
  workspaceString,
} from "./shared/finance-media-normalizers";
import {
  normalizeNumber,
  resolveWalletLedgerUiType,
} from "./shared/admin-surface-helpers";
import {
} from "./shared/wallet-notification-preferences";
import {
  formatCurrencyAmount,
  sendWalletMerchantNotification,
} from "./shared/wallet-notifications";
import {
  getDefaultStorageBucket,
} from "./shared/storage";
export {
  createMenuImportJob,
  processMenuImport,
  enqueueMenuImport,
  runMenuOcr,
  extractMenuCandidates,
  mapExtractedMenu,
  onMenuImportTaskCreate,
} from "./menu_import";
export { aggregateVenueBusyTimes, backfillVenueBusyTimes } from "./busy_times/job";
export { createTransportHandoff, getTransportQuotes } from "./transport";
export {
  trackVenueEvent,
  searchVenuesInBounds,
  createClaimToken,
  validateToken,
  redeemToken,
  onReviewWrite,
} from "./public_engagement";
export {
  aggregateVenueAnalytics,
  backfillMerchantAnalytics,
} from "./analytics_runtime";
export {
  updateVenueHasOffers,
  checkExpiringOffers,
} from "./analytics_offer_health";
export {
  isCurrentUserAdmin,
  verifyWalletOperationalReadiness,
} from "./wallet_runtime_readiness";
export {
  listMerchantTopUpRequestsForAdmin,
  listMerchantWalletLedgerEntriesForAdmin,
} from "./wallet_admin_reads";
export {
  createMerchantTopUpRequest,
  reviewMerchantTopUpRequest,
  reverseWalletEntry,
  approveWalletReversalRequest,
} from "./wallet_runtime_mutations";
export {
  runWalletLifecycleMaintenance,
  runWalletExpiryReminderMaintenance,
  walletLifecycleMaintenance,
  walletExpiryReminderMaintenance,
} from "./wallet_runtime_maintenance";
export { requireAppCheck, logSecurityAudit };
export {
  workspaceString,
  financeTimestampToIsoWithFallback,
  financeTimestampToOptionalIso,
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
};

if (admin.apps.length === 0) {
  admin.initializeApp();
}
export const db = admin.firestore();
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
const MEDIA_COMMAND_COLLECTION = "media_governance_commands";
const MEDIA_AUDIT_COLLECTION = "media_audit_events";
const MEDIA_ASSET_COLLECTION = "media_governance_assets";
const REVIEW_MODERATION_COMMAND_COLLECTION = "review_moderation_commands";
const REVIEW_MODERATION_AUDIT_COLLECTION = "review_moderation_events";
const DEFAULT_MEDIA_QUARANTINE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
const MEDIA_ACTION_ALLOWED_SOURCE_COLLECTIONS = new Set<string>([
  "merchant_topup_requests",
  "venues",
  "offers",
  "stories",
]);
const MEDIA_ACTION_ALLOWED_TARGET_TYPES = new Set<string>([
  "media_asset",
  "topup_proof",
  "venue_photo",
  "offer_image",
  "story_image",
]);
const REVIEW_MODERATION_ALLOWED_REASONS = new Set<string>([
  "spam",
  "abusive_language",
  "off_topic",
  "privacy_request",
  "legal_request",
  "duplicate",
  "manual_review",
  "appeal_approved",
  "other",
]);

export async function requireAdminAccess(
  context: functions.https.CallableContext,
): Promise<{ uid: string; source: "claim" | "document" }> {
  return requireAdminAccessWithDb(context, db);
}

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

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

// 7. Redeem Invite Code (Merchant Onboarding)
// Input: code
// Security: App Check + Auth Required + Rate Limit
export const redeemInviteCode = functions.https.onCall(async (data, context) => {
    // 1. Security Checks
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    requireAppCheck(context);

    const { code } = data;
    if (!code || typeof code !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "Invalid invite code");
    }
    const normalizedCode = code.trim().toUpperCase();
    if (!normalizedCode) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid invite code");
    }

    const uid = context.auth.uid;
    const now = Timestamp.now();

    // 2. Rate Limiting (5 attempts per hour per user)
    const rateLimitKey = `redeem_invite_${uid}_${Math.floor(Date.now() / 3600000)}`; // Hourly bucket
    const rateRef = db.collection("rate_limits").doc(rateLimitKey);

    await db.runTransaction(async (t) => {
        const doc = await t.get(rateRef);
        const count = doc.exists ? doc.data()?.count || 0 : 0;
        if (count >= 5) {
            throw new functions.https.HttpsError("resource-exhausted", "Too many attempts. Try again later.");
        }
        t.set(rateRef, { count: count + 1 }, { merge: true });
    });

    // 3. Redeem Transaction
    const userRef = db.collection("users").doc(uid);
    const merchantRef = db.collection("merchants").doc(uid);

    // We need to query for the invite code first (since DocID is random)
    // Query is not supported inside transaction directly for dynamic keys unless we read it first.
    // But we need the doc reference for the transaction.
    const inviteQuery = await db.collection("merchant_invites")
        .where("code", "==", normalizedCode)
        .limit(2) // Fetch 2 to detect duplicates
        .get();

    if (inviteQuery.empty) {
        throw new functions.https.HttpsError("not-found", "Invalid invite code");
    }

    // Safety Check: Ambiguous Code
    if (inviteQuery.size > 1) {
        throw new functions.https.HttpsError("aborted", "Ambiguous invite code. Please contact support.");
    }

    // Get the reference to standardise the transaction lock
    const inviteRef = inviteQuery.docs[0].ref;
    const result = await db.runTransaction(async (t) => {
        // A. Lock & Validate Invite
        const inviteDoc = await t.get(inviteRef);
        if (!inviteDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Invalid invite code (intermittent)");
        }

        const invite = inviteDoc.data()!;

        if (invite.status !== 'active') {
            throw new functions.https.HttpsError("failed-precondition", "Invite code already used or inactive");
        }
        if (invite.used_by) {
             throw new functions.https.HttpsError("failed-precondition", "Invite code already used");
        }
        if (invite.expires_at && invite.expires_at < now) {
            throw new functions.https.HttpsError("failed-precondition", "Invite code expired");
        }

        // B. Check User Status (Anti-Relinking)
        const userDoc = await t.get(userRef);
        const userData = userDoc.data();

        if (userData?.merchant_venue_id) {
            // User is already a merchant.
            // Only allow if they are re-claiming the SAME venue (e.g. fix broken link)
            // Otherwise, reject to prevent hijacking or accidental overwrite.
            if (userData.merchant_venue_id !== invite.venue_id) {
                throw new functions.https.HttpsError("failed-precondition", "User is already linked to another venue.");
            }
        }

        // C. Read merchant profile before writes (Firestore requires all reads before writes)
        const merchantDoc = await t.get(merchantRef);

        // D. Update Invite
        t.update(inviteRef, {
            status: 'used',
            used_by: uid,
            used_at: now,
            updated_at: now
        });

        // E. Upsert User (Grant Merchant Role)
        // Use set+merge to avoid failing when users/{uid} does not exist yet.
        t.set(userRef, {
            merchant_venue_id: invite.venue_id,
            is_merchant: true,
            updated_at: now
        }, { merge: true });

        // F. Create/Update Merchant Profile
        if (!merchantDoc.exists) {
             t.set(merchantRef, {
                uid: uid,
                venue_id: invite.venue_id,
                created_at: now,
                updated_at: now
            });
        } else {
             t.update(merchantRef, {
                venue_id: invite.venue_id,
                updated_at: now
             });
        }

        // ًں”” Create welcome notification (inside transaction for the new merchant)
        const notifRef = db.collection('users').doc(uid).collection('notifications').doc();
        t.set(notifRef, {
          title: 'ًںژ‰ ظ…ط±ط­ط¨ط§ظ‹ ط¨ظƒ ظƒطھط§ط¬ط±!',
          body: 'طھظ… ط±ط¨ط· ظ…ط­ظ„ظƒ ط¨ظ†ط¬ط§ط­. ظٹظ…ظƒظ†ظƒ ط§ظ„ط¢ظ† ط¥ط¯ط§ط±ط© ط§ظ„ط¹ط±ظˆط¶ ظˆط§ظ„طھظ‚ظٹظٹظ…ط§طھ ظ…ظ† ظ„ظˆط­ط© ط§ظ„طھط­ظƒظ….',
          type: 'welcome',
          data: { venue_id: invite.venue_id },
          is_read: false,
          created_at: now,
        });

        return { success: true, venueId: invite.venue_id };
    });

    logSecurityAudit("redeemInviteCode", {
      uid,
      inviteId: inviteRef.id,
      venueId: result.venueId ?? null,
      timestamp: now.toMillis(),
      result: "success",
    });

    return result;
});

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

export function clampFinanceReadLimit(
  value: unknown,
  fallback: number,
  min: number,
  max: number,
): number {
  const n =
    typeof value === "number" && Number.isFinite(value)
      ? Math.floor(value)
      : fallback;
  return Math.min(max, Math.max(min, n));
}

export async function loadVenueDisplayLabels(
  venueIds: string[],
): Promise<Map<string, string>> {
  const unique = [...new Set(venueIds.filter((id) => id.trim().length > 0))].slice(
    0,
    200,
  );
  const map = new Map<string, string>();
  await Promise.all(
    unique.map(async (id) => {
      const snap = await db.collection("venues").doc(id).get();
      if (!snap.exists) {
        map.set(id, id);
        return;
      }
      const d = snap.data() ?? {};
      const ar = typeof d.name_ar === "string" ? d.name_ar.trim() : "";
      const en = typeof d.name === "string" ? d.name.trim() : "";
      map.set(id, ar || en || id);
    }),
  );
  return map;
}

function workspaceStoryStatus(
  data: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "published" | "expired" | "draft" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "published" || explicit === "expired" || explicit === "draft") {
    return explicit;
  }

  const expiresAt = financeTimestampToMillis(data.expires_at ?? data.expiresAt);
  if (expiresAt > 0 && expiresAt <= now.toMillis()) {
    return "expired";
  }

  if (data.is_active === false || data.is_published === false) {
    return "draft";
  }

  return "published";
}

function workspaceOfferStatus(
  data: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "active" | "paused" | "expired" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "active" || explicit === "paused" || explicit === "expired") {
    return explicit;
  }

  const endAt = financeTimestampToMillis(data.end_at ?? data.ends_at ?? data.endAt);
  if (endAt > 0 && endAt <= now.toMillis()) {
    return "expired";
  }

  if (data.is_active === false || data.is_featured === false) {
    return "paused";
  }

  return "active";
}

function workspaceReviewStatus(
  data: FirebaseFirestore.DocumentData,
): "published" | "flagged" | "hidden" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "published" || explicit === "flagged" || explicit === "hidden") {
    return explicit;
  }

  if (data.hidden === true || data.is_hidden === true) {
    return "hidden";
  }

  if (data.flagged === true || data.is_flagged === true) {
    return "flagged";
  }

  return "published";
}

type ReviewModerationAction =
  | "review_publish"
  | "review_hide"
  | "review_escalate";

type ReviewModerationRole = "content_admin" | "super_admin";

type ReviewModerationStatus = "published" | "flagged" | "hidden";

type ReviewModerationTarget = {
  venueId: string;
  reviewId: string;
  sourcePath: string;
};

type ReviewModerationCommandEnvelope = {
  action: ReviewModerationAction;
  commandId: string;
  correlationId: string | null;
  idempotencyKey: string;
  reason: string;
  note: string | null;
  submittedAt: string;
  expectedState: Record<string, unknown> | null;
};

function resolveReviewModerationRole(
  context: functions.https.CallableContext,
): ReviewModerationRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  if (token.content_admin === true || token.role === "content_admin") {
    return "content_admin";
  }
  return null;
}

async function requireReviewModerationAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: ReviewModerationRole;
}> {
  const baseAccess = await requireAdminAccess(context);
  const role = resolveReviewModerationRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "review_moderation_role_not_authorized",
    );
  }

  return {
    ...baseAccess,
    role,
  };
}

function normalizeReviewModerationAction(value: unknown): ReviewModerationAction {
  const normalized = workspaceString(value).toLowerCase();
  if (
    normalized === "review_publish" ||
    normalized === "review_hide" ||
    normalized === "review_escalate"
  ) {
    return normalized;
  }

  throw new functions.https.HttpsError(
    "invalid-argument",
    "unsupported_review_moderation_action",
  );
}

function normalizeReviewModerationTarget(data: unknown): ReviewModerationTarget {
  const payload = mediaRecordOrNull(data) ?? {};
  const venueId = workspaceString(payload.venueId);
  const reviewId = workspaceString(payload.reviewId);

  if (!venueId || !reviewId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "review_target_requires_venue_and_review_id",
    );
  }

  return {
    venueId,
    reviewId,
    sourcePath: `venues/${venueId}/reviews/${reviewId}`,
  };
}

function normalizeReviewModerationReason(value: unknown): string {
  const normalized = workspaceString(value).toLowerCase();
  if (!normalized || !REVIEW_MODERATION_ALLOWED_REASONS.has(normalized)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "review_moderation_reason_invalid",
    );
  }
  return normalized;
}

function normalizeReviewModerationEnvelope(
  action: ReviewModerationAction,
  payload: unknown,
  target: ReviewModerationTarget,
  now: Timestamp,
): ReviewModerationCommandEnvelope {
  const data = mediaRecordOrNull(payload) ?? {};
  const commandId =
    workspaceString(data.commandId) || `${action}_${target.reviewId}`;
  const correlationId = workspaceString(data.correlationId) || null;
  const idempotencyKey = workspaceString(data.idempotencyKey) || commandId;
  const submittedAt = normalizeMediaIsoTimestamp(data.submittedAt, now);
  const expectedState = mediaRecordOrNull(data.expectedState);
  const reason = normalizeReviewModerationReason(data.reason);
  const note = workspaceString(data.note) || null;

  return {
    action,
    commandId,
    correlationId,
    idempotencyKey,
    reason,
    note,
    submittedAt,
    expectedState,
  };
}

function targetStatusForReviewAction(
  action: ReviewModerationAction,
): ReviewModerationStatus {
  switch (action) {
    case "review_publish":
      return "published";
    case "review_hide":
      return "hidden";
    case "review_escalate":
      return "flagged";
  }
}

function reviewModerationCommandDocId(
  action: ReviewModerationAction,
  target: ReviewModerationTarget,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${action}|${target.sourcePath}|${commandId}`)
    .digest("hex");
}

function sortObjectForReviewHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForReviewHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForReviewHash(record[key]);
    }
    return sorted;
  }

  return value;
}

function hashReviewModerationPayload(payload: Record<string, unknown>): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(sortObjectForReviewHash(payload)))
    .digest("hex");
}

function buildReviewModerationPayloadShape(
  target: ReviewModerationTarget,
  envelope: ReviewModerationCommandEnvelope,
): Record<string, unknown> {
  return {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    note: envelope.note,
    expectedState: envelope.expectedState,
    target,
  };
}

export {
  REVIEW_MODERATION_AUDIT_COLLECTION,
  REVIEW_MODERATION_COMMAND_COLLECTION,
  buildReviewModerationPayloadShape,
  financeTimestampToIso,
  hashReviewModerationPayload,
  normalizeNumber,
  normalizeReviewModerationAction,
  normalizeReviewModerationEnvelope,
  normalizeReviewModerationTarget,
  requireReviewModerationAccess,
  reviewModerationCommandDocId,
  targetStatusForReviewAction,
  workspaceReviewStatus,
};

type MediaReferenceIndexHealthStatus =
  | "healthy"
  | "stale"
  | "failed"
  | "unavailable";

function normalizeMediaReferenceIndexHealth(
  value: unknown,
): MediaReferenceIndexHealthStatus {
  const normalized = workspaceString(value).toLowerCase();
  if (normalized === "healthy" || normalized === "stale" || normalized === "failed") {
    return normalized;
  }
  return "unavailable";
}

function workspaceStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => workspaceString(entry))
    .filter((entry) => entry.length > 0);
}

function workspaceMediaUrl(
  data: FirebaseFirestore.DocumentData,
  candidates: string[],
): string {
  for (const candidate of candidates) {
    const value = workspaceString(data[candidate]);
    if (value.length > 0) {
      return value;
    }
  }
  return "";
}

function mediaStoragePathFromUrl(value: string): string | null {
  if (!value || /^https?:\/\//i.test(value) || value.startsWith("gs://")) {
    return null;
  }
  return value;
}

async function loadMediaReferenceIndexHealth(now: Timestamp): Promise<{
  status: MediaReferenceIndexHealthStatus;
  asOf: string | null;
  detail: string;
}> {
  const healthDocId = "health";
  const healthDocPath = `media_reference_index/${healthDocId}`;

  try {
    const healthDoc = await db.collection("media_reference_index").doc(healthDocId).get();
    if (!healthDoc.exists) {
      return {
        status: "unavailable",
        asOf: null,
        detail: `${healthDocPath} missing`,
      };
    }

    const row = healthDoc.data() ?? {};
    const status = normalizeMediaReferenceIndexHealth(
      row.current_health_status ?? row.health_status ?? row.status,
    );
    const asOfMs = financeTimestampToMillis(
      row.last_successful_build_at ?? row.as_of ?? row.updated_at,
    );

    return {
      status,
      asOf: asOfMs > 0 ? new Date(asOfMs).toISOString() : null,
      detail:
        status === "unavailable"
          ? `${healthDocPath} status invalid`
          : "ok",
    };
  } catch (error) {
    return {
      status: "unavailable",
      asOf: null,
      detail: `${healthDocPath} read error: ${
        error instanceof Error ? error.message : String(error)
      }`,
    };
  }
}

function buildMediaSafetyMetadata(args: {
  referenceType: "topup_request" | "venue" | "offer" | "story";
  referenceId: string;
  sourceCollection: string;
  sourceDocumentId: string;
  indexHealth: {
    status: MediaReferenceIndexHealthStatus;
    asOf: string | null;
  };
}): Record<string, unknown> {
  const blockedByIndex = args.indexHealth.status !== "healthy";
  return {
    referenceType: args.referenceType,
    referenceId: args.referenceId,
    sourceCollection: args.sourceCollection,
    sourceDocumentId: args.sourceDocumentId,
    sourcePath: `${args.sourceCollection}/${args.sourceDocumentId}`,
    referenceCount: 1,
    referenceIndexStatus: args.indexHealth.status,
    referenceIndexAsOf: args.indexHealth.asOf,
    purgeBlocked: true,
    purgeBlockReason: blockedByIndex
      ? "reference_index_unavailable_or_unhealthy"
      : "reference_count_unverified_read_only_baseline",
  };
}

type MediaGovernanceAction =
  | "media_soft_delete"
  | "media_quarantine"
  | "media_reference_check"
  | "media_purge";

type MediaGovernanceRole = "content_admin" | "super_admin";

type MediaGovernanceTarget = {
  targetType: string;
  targetId: string;
  assetKey: string;
  venueId: string | null;
  sourceCollection: string | null;
  sourceDocumentId: string | null;
  sourcePath: string | null;
  mediaUrl: string | null;
  storagePath: string | null;
  referenceType: string | null;
  referenceId: string | null;
};

type MediaGovernanceCommandEnvelope = {
  action: MediaGovernanceAction;
  commandId: string;
  correlationId: string | null;
  idempotencyKey: string;
  reason: string;
  submittedAt: string;
  expectedState: Record<string, unknown> | null;
};

type MediaReferenceCheckSummary = {
  checkedAt: string;
  referenceCount: number;
  indexStatus: MediaReferenceIndexHealthStatus;
  indexAsOf: string | null;
  indexDetail: string;
  purgeEligible: boolean;
  blockedReason: "reference_index_unhealthy" | "references_present" | null;
  matchedSourcePaths: string[];
};

function resolveMediaGovernanceRole(
  context: functions.https.CallableContext,
): MediaGovernanceRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  if (token.content_admin === true || token.role === "content_admin") {
    return "content_admin";
  }
  return null;
}

async function requireMediaGovernanceAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: MediaGovernanceRole;
}> {
  const baseAccess = await requireAdminAccess(context);
  const role = resolveMediaGovernanceRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "media_role_not_authorized",
    );
  }

  return {
    ...baseAccess,
    role,
  };
}

function normalizeMediaGovernanceTarget(data: unknown): MediaGovernanceTarget {
  const payload = mediaRecordOrNull(data) ?? {};

  const targetType = workspaceString(payload.targetType) || "media_asset";
  if (!MEDIA_ACTION_ALLOWED_TARGET_TYPES.has(targetType)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "unsupported_media_target_type",
    );
  }

  const targetId = workspaceString(payload.targetId) || workspaceString(payload.assetId);
  if (!targetId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "media_target_id_required",
    );
  }

  const mediaUrlRaw = workspaceString(payload.mediaUrl);
  const storagePathRaw = workspaceString(payload.storagePath);
  const derivedStoragePath = mediaStoragePathFromUrl(mediaUrlRaw);
  const storagePath = storagePathRaw || derivedStoragePath || null;
  const mediaUrl = mediaUrlRaw || (storagePath ? storagePath : null);

  const sourceCollectionRaw = workspaceString(payload.sourceCollection);
  const sourceCollection = sourceCollectionRaw || null;
  const sourceDocumentId = workspaceString(payload.sourceDocumentId) || null;
  if (sourceCollection && !MEDIA_ACTION_ALLOWED_SOURCE_COLLECTIONS.has(sourceCollection)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "unsupported_media_source_collection",
    );
  }
  if (Boolean(sourceCollection) !== Boolean(sourceDocumentId)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "media_source_collection_and_document_id_must_pair",
    );
  }

  const sourcePath =
    sourceCollection && sourceDocumentId
      ? `${sourceCollection}/${sourceDocumentId}`
      : null;
  const assetKey =
    storagePath ||
    mediaUrl ||
    sourcePath ||
    targetId;

  return {
    targetType,
    targetId,
    assetKey,
    venueId: workspaceString(payload.venueId) || null,
    sourceCollection,
    sourceDocumentId,
    sourcePath,
    mediaUrl,
    storagePath,
    referenceType: workspaceString(payload.referenceType) || null,
    referenceId: workspaceString(payload.referenceId) || null,
  };
}

function normalizeMediaExpectedState(value: unknown): Record<string, unknown> | null {
  const state = mediaRecordOrNull(value);
  return state ?? null;
}

function normalizeMediaCommandEnvelope(
  action: MediaGovernanceAction,
  payload: unknown,
  target: MediaGovernanceTarget,
  now: Timestamp,
): MediaGovernanceCommandEnvelope {
  const data = mediaRecordOrNull(payload) ?? {};
  const commandId =
    workspaceString(data.commandId) ||
    `${action}_${target.targetId}`;
  const correlationId = workspaceString(data.correlationId) || null;
  const idempotencyKey = workspaceString(data.idempotencyKey) || commandId;
  const submittedAt = normalizeMediaIsoTimestamp(data.submittedAt, now);
  const expectedState = normalizeMediaExpectedState(data.expectedState);
  const reasonRaw = workspaceString(data.reason);
  const reason =
    reasonRaw ||
    (action === "media_reference_check" ? "media_reference_check" : "");

  if (!reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "media_action_reason_required",
    );
  }

  return {
    action,
    commandId,
    correlationId,
    idempotencyKey,
    reason,
    submittedAt,
    expectedState,
  };
}

function normalizeMediaQuarantineUntil(payload: unknown, now: Timestamp): Timestamp {
  const data = mediaRecordOrNull(payload) ?? {};

  const explicitIso = workspaceString(data.quarantineUntil);
  if (explicitIso) {
    const parsed = Date.parse(explicitIso);
    if (Number.isFinite(parsed) && parsed > now.toMillis()) {
      return Timestamp.fromMillis(parsed);
    }
  }

  const quarantineDays =
    typeof data.quarantineDays === "number" && Number.isFinite(data.quarantineDays)
      ? Math.max(1, Math.min(90, Math.trunc(data.quarantineDays)))
      : null;
  if (quarantineDays !== null) {
    return Timestamp.fromMillis(
      now.toMillis() + quarantineDays * 24 * 60 * 60 * 1000,
    );
  }

  return Timestamp.fromMillis(now.toMillis() + DEFAULT_MEDIA_QUARANTINE_WINDOW_MS);
}

function mediaAssetDocIdFromKey(assetKey: string): string {
  return crypto.createHash("sha1").update(assetKey).digest("hex");
}

function mediaCommandDocId(
  action: MediaGovernanceAction,
  target: MediaGovernanceTarget,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${action}|${target.assetKey}|${commandId}`)
    .digest("hex");
}

function sortObjectForMediaHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForMediaHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForMediaHash(record[key]);
    }
    return sorted;
  }

  return value;
}

function hashMediaPayload(payload: Record<string, unknown>): string {
  const normalized = sortObjectForMediaHash(payload);
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(normalized))
    .digest("hex");
}

function buildMediaPayloadShape(
  target: MediaGovernanceTarget,
  envelope: MediaGovernanceCommandEnvelope,
): Record<string, unknown> {
  return {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    submittedAt: envelope.submittedAt,
    expectedState: envelope.expectedState,
    target: {
      targetType: target.targetType,
      targetId: target.targetId,
      assetKey: target.assetKey,
      venueId: target.venueId,
      sourceCollection: target.sourceCollection,
      sourceDocumentId: target.sourceDocumentId,
      mediaUrl: target.mediaUrl,
      storagePath: target.storagePath,
      referenceType: target.referenceType,
      referenceId: target.referenceId,
    },
  };
}

function buildMediaTargetCandidates(target: MediaGovernanceTarget): Set<string> {
  const candidates = new Set<string>();
  if (target.mediaUrl) {
    candidates.add(target.mediaUrl);
    const derivedPath = mediaStoragePathFromUrl(target.mediaUrl);
    if (derivedPath) {
      candidates.add(derivedPath);
    }
  }
  if (target.storagePath) {
    candidates.add(target.storagePath);
  }
  return candidates;
}

function mediaCandidateMatchesTarget(
  candidateRaw: unknown,
  targetCandidates: Set<string>,
): boolean {
  const candidate = workspaceString(candidateRaw);
  if (!candidate) {
    return false;
  }

  if (targetCandidates.has(candidate)) {
    return true;
  }

  const candidatePath = mediaStoragePathFromUrl(candidate);
  return candidatePath ? targetCandidates.has(candidatePath) : false;
}

async function loadMediaReferenceMatchCount(target: MediaGovernanceTarget): Promise<{
  referenceCount: number;
  matchedSourcePaths: string[];
}> {
  if (!target.sourceCollection || !target.sourceDocumentId) {
    return {
      referenceCount: 0,
      matchedSourcePaths: [],
    };
  }

  const sourcePath = `${target.sourceCollection}/${target.sourceDocumentId}`;
  const sourceDoc = await db
    .collection(target.sourceCollection)
    .doc(target.sourceDocumentId)
    .get();
  if (!sourceDoc.exists) {
    return {
      referenceCount: 0,
      matchedSourcePaths: [],
    };
  }

  const sourceData = sourceDoc.data() ?? {};
  const targetCandidates = buildMediaTargetCandidates(target);
  if (targetCandidates.size === 0) {
    return {
      referenceCount: 1,
      matchedSourcePaths: [sourcePath],
    };
  }

  if (target.sourceCollection === "merchant_topup_requests") {
    const proofDeleted =
      sourceData.proof_storage_deleted === true ||
      financeTimestampToMillis(sourceData.proof_deleted_at) > 0;
    if (!proofDeleted && mediaCandidateMatchesTarget(sourceData.proof_image_url, targetCandidates)) {
      return {
        referenceCount: 1,
        matchedSourcePaths: [sourcePath],
      };
    }
    return {
      referenceCount: 0,
      matchedSourcePaths: [],
    };
  }

  if (target.sourceCollection === "venues") {
    const photos = workspaceStringArray(sourceData.photos);
    const matchedCount = photos.filter((photo) =>
      mediaCandidateMatchesTarget(photo, targetCandidates),
    ).length;
    return {
      referenceCount: matchedCount,
      matchedSourcePaths: matchedCount > 0 ? [sourcePath] : [],
    };
  }

  if (target.sourceCollection === "offers") {
    const offerMediaUrl = workspaceMediaUrl(sourceData, [
      "image_url",
      "imageUrl",
      "media_url",
      "mediaUrl",
      "photo_url",
      "photoUrl",
      "cover_image_url",
      "coverImageUrl",
      "banner_image_url",
      "bannerImageUrl",
    ]);
    return {
      referenceCount: mediaCandidateMatchesTarget(offerMediaUrl, targetCandidates)
        ? 1
        : 0,
      matchedSourcePaths: mediaCandidateMatchesTarget(offerMediaUrl, targetCandidates)
        ? [sourcePath]
        : [],
    };
  }

  if (target.sourceCollection === "stories") {
    const storyMediaUrl = workspaceMediaUrl(sourceData, [
      "image_url",
      "imageUrl",
      "media_url",
      "mediaUrl",
      "photo_url",
      "photoUrl",
      "thumbnail_url",
      "thumbnailUrl",
    ]);
    return {
      referenceCount: mediaCandidateMatchesTarget(storyMediaUrl, targetCandidates)
        ? 1
        : 0,
      matchedSourcePaths: mediaCandidateMatchesTarget(storyMediaUrl, targetCandidates)
        ? [sourcePath]
        : [],
    };
  }

  return {
    referenceCount: 1,
    matchedSourcePaths: [sourcePath],
  };
}

async function evaluateMediaReferenceCheck(
  target: MediaGovernanceTarget,
  now: Timestamp,
): Promise<MediaReferenceCheckSummary> {
  const [indexHealth, referenceMatches] = await Promise.all([
    loadMediaReferenceIndexHealth(now),
    loadMediaReferenceMatchCount(target),
  ]);

  let blockedReason: "reference_index_unhealthy" | "references_present" | null = null;
  if (indexHealth.status !== "healthy") {
    blockedReason = "reference_index_unhealthy";
  } else if (referenceMatches.referenceCount > 0) {
    blockedReason = "references_present";
  }

  return {
    checkedAt: now.toDate().toISOString(),
    referenceCount: referenceMatches.referenceCount,
    indexStatus: indexHealth.status,
    indexAsOf: indexHealth.asOf,
    indexDetail: indexHealth.detail,
    purgeEligible: blockedReason === null,
    blockedReason,
    matchedSourcePaths: referenceMatches.matchedSourcePaths,
  };
}

function mediaReferenceCheckToFirestore(
  summary: MediaReferenceCheckSummary,
): Record<string, unknown> {
  return {
    checked_at: summary.checkedAt,
    reference_count: summary.referenceCount,
    index_status: summary.indexStatus,
    index_as_of: summary.indexAsOf,
    index_detail: summary.indexDetail,
    purge_eligible: summary.purgeEligible,
    blocked_reason: summary.blockedReason,
    matched_source_paths: summary.matchedSourcePaths,
  };
}

function readMediaCommandReplayResult(
  existingCommandDoc: FirebaseFirestore.DocumentSnapshot,
  payloadHash: string,
  fallbackCorrelationId: string | null,
): Record<string, unknown> | null {
  if (!existingCommandDoc.exists) {
    return null;
  }

  const existing = existingCommandDoc.data() ?? {};
  const existingPayloadHash = workspaceString(existing.payload_hash);
  if (existingPayloadHash && existingPayloadHash !== payloadHash) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "media_command_payload_mismatch",
    );
  }

  const existingResult = mediaRecordOrNull(existing.result);
  if (!existingResult) {
    return null;
  }

  const existingCorrelationId =
    workspaceString(existingResult.correlationId) ||
    workspaceString(existing.correlation_id) ||
    fallbackCorrelationId;

  return {
    ...existingResult,
    idempotent: true,
    correlationId: existingCorrelationId || null,
  };
}

async function upsertMediaAuditEvent(
  id: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await db.collection(MEDIA_AUDIT_COLLECTION).doc(id).set(payload, { merge: true });
}

function assertMediaPurgeExpectedState(
  expectedState: Record<string, unknown> | null,
): void {
  const expectedMediaState = workspaceString(expectedState?.media_state).toLowerCase();
  const expectedReferenceHealth = workspaceString(
    expectedState?.reference_index_health,
  ).toLowerCase();
  const expectedReferenceCount =
    typeof expectedState?.reference_count === "number"
      ? expectedState.reference_count
      : Number.NaN;

  if (
    expectedMediaState !== "quarantined" ||
    expectedReferenceHealth !== "healthy" ||
    expectedReferenceCount !== 0
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "media_purge_expected_state_conflict",
    );
  }
}

function normalizeStorageDeleteError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === "string" && error.trim().length > 0) {
    return error.trim();
  }
  return "unknown_storage_delete_error";
}

export {
  MEDIA_ASSET_COLLECTION,
  MEDIA_COMMAND_COLLECTION,
  assertMediaPurgeExpectedState,
  buildMediaPayloadShape,
  buildMediaSafetyMetadata,
  evaluateMediaReferenceCheck,
  getDefaultStorageBucket,
  hashMediaPayload,
  loadMediaReferenceIndexHealth,
  mediaAssetDocIdFromKey,
  mediaCommandDocId,
  mediaReferenceCheckToFirestore,
  mediaStoragePathFromUrl,
  normalizeMediaCommandEnvelope,
  normalizeMediaGovernanceTarget,
  normalizeMediaQuarantineUntil,
  normalizeStorageDeleteError,
  readMediaCommandReplayResult,
  resolveWalletLedgerUiType,
  requireMediaGovernanceAccess,
  roundMoney,
  upsertMediaAuditEvent,
  workspaceMediaUrl,
  workspaceOfferStatus,
  workspaceStoryStatus,
  workspaceStringArray,
};

export {
  listVenueReviewsForAdmin,
  moderateVenueReviewForAdmin,
} from "./admin_reviews";

export {
  getAdminMediaInventoryReadBundle,
  mediaSoftDeleteAsset,
  mediaQuarantineAsset,
  mediaReferenceCheckAsset,
  mediaPurgeAsset,
} from "./admin_media";

export {
  getAdminVenueWorkspaceReadBundle,
  listVenuesForAdmin,
  adminCreateVenue,
  adminUpdateVenueProfile,
  adminUpdateVenueVisibility,
  adminUpdateVenueOperationalStatus,
  adminUpdateVenueSubscriptionStatus
} from "./admin_venues";

export const onWalletEntryWrite = functions.firestore
  .document("merchant_wallets/{venueId}/entries/{entryId}")
  .onWrite(async (change, context) => {
    const venueId = context.params.venueId as string;
    const entryId = context.params.entryId as string;
    const now = Timestamp.now();
    if (change.after.exists) {
      const entry = change.after.data() ?? {};
      await upsertWalletAuditEvent(`entry_${entryId}`, {
        category: "wallet_entry",
        event_type: "wallet_entry",
        venue_id: venueId,
        entry_id: entryId,
        type: typeof entry.type === "string" ? entry.type : null,
        amount: normalizeNumber(entry.amount),
        currency: typeof entry.currency === "string" ? entry.currency : null,
        balance_after: normalizeNumber(entry.balance_after),
        feature_key: typeof entry.feature_key === "string" ? entry.feature_key : null,
        reference_type: typeof entry.reference_type === "string" ? entry.reference_type : null,
        reference_id: typeof entry.reference_id === "string" ? entry.reference_id : null,
        reversed_at: entry.reversed_at ?? null,
        reversed_by_uid: typeof entry.reversed_by_uid === "string" ? entry.reversed_by_uid : null,
        reversal_entry_id: typeof entry.reversal_entry_id === "string" ? entry.reversal_entry_id : null,
        created_at: entry.created_at instanceof Timestamp ? entry.created_at : now,
        updated_at: now,
      });
    }
    await rebuildWalletReportForVenue(venueId);
    return null;
  });

export const rebuildWalletReportsDaily = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const now = Timestamp.now();
    const walletsSnap = await db.collection("merchant_wallets").limit(400).get();
    let rebuilt = 0;
    for (const walletDoc of walletsSnap.docs) {
      await rebuildWalletReportForVenue(walletDoc.id, now);
      rebuilt += 1;
    }
    logSecurityAudit("wallet_reports_rebuilt_daily", {
      rebuilt,
      timestamp: now.toMillis(),
    });
    return null;
  });

// CONFIG GOVERNANCE

export {
  getAdminConfigGovernanceBundle,
  configUpsertDraft,
  configReviewDraft,
  configPublishDraft,
  configRollbackVersion,
} from "./admin_config";

// CONTENT GOVERNANCE




export {
  listOffersForAdmin,
  listStoriesForAdmin,
  contentModerateOffer,
  contentModerateStory
} from "./admin_content";
