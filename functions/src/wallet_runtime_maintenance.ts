import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import { logSecurityAudit } from "./shared/audit";
import { db } from "./shared/firestore-db";
import {
  getDefaultStorageBucket,
  isInternalProofStoragePath,
} from "./shared/storage";
import { WALLET_EXPIRY_REMINDER_PREF_FIELD } from "./shared/wallet-notification-preferences";
import { sendWalletMerchantNotification } from "./shared/wallet-notifications";

const MAINTENANCE_CLEANUP_LIMIT = 100;
const EXPIRY_REMINDER_WINDOW_HOURS = 24;
const EXPIRY_REMINDER_WINDOW_MS = EXPIRY_REMINDER_WINDOW_HOURS * 60 * 60 * 1000;

type WalletLifecycleMaintenanceOptions = {
  now?: Timestamp;
  limitPerType?: number;
};

type WalletLifecycleMaintenanceResult = {
  offersExpired: number;
  storiesExpired: number;
  proofsDeleted: number;
  proofStorageDeleted: number;
  proofLegacyCleared: number;
  scans: {
    offers: number;
    stories: number;
    topups: number;
  };
  hasMore: {
    offers: boolean;
    stories: boolean;
    topups: boolean;
  };
};

type WalletExpiryReminderMaintenanceOptions = {
  now?: Timestamp;
  limitPerType?: number;
  reminderWindowMs?: number;
};

type WalletExpiryReminderMaintenanceResult = {
  storyRemindersSent: number;
  offerRemindersSent: number;
  scans: {
    stories: number;
    offers: number;
  };
  hasMore: {
    stories: boolean;
    offers: boolean;
  };
  reminderDeadline: Timestamp;
};

async function upsertWalletAuditEvent(
  id: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await db.collection("wallet_audit_events").doc(id).set(payload, { merge: true });
}

export async function runWalletLifecycleMaintenance(
  options: WalletLifecycleMaintenanceOptions = {},
): Promise<WalletLifecycleMaintenanceResult> {
  const now = options.now ?? Timestamp.now();
  const limitPerType = options.limitPerType && options.limitPerType > 0
    ? Math.min(Math.trunc(options.limitPerType), 400)
    : MAINTENANCE_CLEANUP_LIMIT;

  let offersExpired = 0;
  let storiesExpired = 0;
  let proofsDeleted = 0;
  let proofStorageDeleted = 0;
  let proofLegacyCleared = 0;

  const expiredOffersSnap = await db.collection("offers")
    .where("featured_until", "<=", now)
    .limit(limitPerType)
    .get();
  {
    const batch = db.batch();
    for (const doc of expiredOffersSnap.docs) {
      const data = doc.data();
      if (data.is_featured !== true) {
        continue;
      }
      batch.update(doc.ref, {
        is_featured: false,
        updated_at: now,
      });
      offersExpired += 1;
    }
    if (offersExpired > 0) {
      await batch.commit();
    }
  }

  const expiredStoriesSnap = await db.collection("stories")
    .where("promoted_until", "<=", now)
    .limit(limitPerType)
    .get();
  {
    const batch = db.batch();
    for (const doc of expiredStoriesSnap.docs) {
      const data = doc.data();
      if (data.is_promoted !== true) {
        continue;
      }
      batch.update(doc.ref, {
        is_promoted: false,
        updated_at: now,
      });
      storiesExpired += 1;
    }
    if (storiesExpired > 0) {
      await batch.commit();
    }
  }

  const expiredProofsSnap = await db.collection("merchant_topup_requests")
    .where("proof_retention_until", "<=", now)
    .limit(limitPerType)
    .get();
  {
    const batch = db.batch();
    const auditWrites: Promise<void>[] = [];
    for (const doc of expiredProofsSnap.docs) {
      const data = doc.data();
      const rawProofUrl = typeof data.proof_image_url === "string"
        ? data.proof_image_url.trim()
        : "";
      if (!rawProofUrl) {
        continue;
      }

      let storageDeleted = false;
      if (isInternalProofStoragePath(rawProofUrl)) {
        await getDefaultStorageBucket().file(rawProofUrl).delete({
          ignoreNotFound: true,
        });
        storageDeleted = true;
      } else {
        proofLegacyCleared += 1;
      }

      batch.update(doc.ref, {
        proof_image_url: null,
        proof_deleted_at: now,
        proof_storage_deleted: storageDeleted,
        updated_at: now,
      });
      auditWrites.push(upsertWalletAuditEvent(
        `topup_proof_deleted_${doc.id}`,
        {
          category: "topup_proof_lifecycle",
          event_type: "topup_proof_deleted",
          venue_id: typeof data.venue_id === "string" ? data.venue_id : null,
          request_id: doc.id,
          proof_storage_deleted: storageDeleted,
          proof_deleted_at: now,
          created_at: now,
          updated_at: now,
        },
      ));
      proofsDeleted += 1;
      if (storageDeleted) {
        proofStorageDeleted += 1;
      }
    }
    if (proofsDeleted > 0) {
      await batch.commit();
      await Promise.all(auditWrites);
    }
  }

  const nowMillis = now.toMillis();
  if (offersExpired > 0) {
    logSecurityAudit("offer_pin_expired", {
      count: offersExpired,
      timestamp: nowMillis,
    });
  }
  if (storiesExpired > 0) {
    logSecurityAudit("story_promotion_expired", {
      count: storiesExpired,
      timestamp: nowMillis,
    });
  }
  if (proofsDeleted > 0) {
    logSecurityAudit("topup_proof_deleted", {
      count: proofsDeleted,
      storageDeleted: proofStorageDeleted,
      legacyCleared: proofLegacyCleared,
      timestamp: nowMillis,
    });
  }

  return {
    offersExpired,
    storiesExpired,
    proofsDeleted,
    proofStorageDeleted,
    proofLegacyCleared,
    scans: {
      offers: expiredOffersSnap.size,
      stories: expiredStoriesSnap.size,
      topups: expiredProofsSnap.size,
    },
    hasMore: {
      offers: expiredOffersSnap.size === limitPerType,
      stories: expiredStoriesSnap.size === limitPerType,
      topups: expiredProofsSnap.size === limitPerType,
    },
  };
}

export async function runWalletExpiryReminderMaintenance(
  options: WalletExpiryReminderMaintenanceOptions = {},
): Promise<WalletExpiryReminderMaintenanceResult> {
  const now = options.now ?? Timestamp.now();
  const limitPerType = options.limitPerType && options.limitPerType > 0
    ? Math.min(Math.trunc(options.limitPerType), 400)
    : MAINTENANCE_CLEANUP_LIMIT;
  const reminderWindowMs =
    options.reminderWindowMs && options.reminderWindowMs > 0
      ? options.reminderWindowMs
      : EXPIRY_REMINDER_WINDOW_MS;
  const reminderDeadline = Timestamp.fromMillis(now.toMillis() + reminderWindowMs);

  let storyRemindersSent = 0;
  let offerRemindersSent = 0;

  const expiringStoriesSnap = await db.collection("stories")
    .where("is_promoted", "==", true)
    .where("promoted_until", ">", now)
    .where("promoted_until", "<=", reminderDeadline)
    .limit(limitPerType)
    .get();
  for (const doc of expiringStoriesSnap.docs) {
    const data = doc.data();
    const venueId = typeof data.venue_id === "string" ? data.venue_id.trim() : "";
    const promotedUntil = data.promoted_until instanceof Timestamp
      ? data.promoted_until
      : null;
    if (!venueId || promotedUntil == null) {
      continue;
    }

    storyRemindersSent += await sendWalletMerchantNotification(db, {
      venueId,
      eventKeyPrefix: `wallet_story_expiring_${doc.id}_${promotedUntil.toMillis()}`,
      title: "سينتهي ترويج الستوري قريبًا",
      body: `ينتهي ترويج الستوري خلال ${EXPIRY_REMINDER_WINDOW_HOURS} ساعة.`,
      type: "wallet_story_promotion_expiring",
      preferenceKey: WALLET_EXPIRY_REMINDER_PREF_FIELD,
      data: {
        venue_id: venueId,
        story_id: doc.id,
        promoted_until: promotedUntil,
      },
    });
  }

  const expiringOffersSnap = await db.collection("offers")
    .where("is_featured", "==", true)
    .where("featured_until", ">", now)
    .where("featured_until", "<=", reminderDeadline)
    .limit(limitPerType)
    .get();
  for (const doc of expiringOffersSnap.docs) {
    const data = doc.data();
    const venueId = typeof data.venue_id === "string" ? data.venue_id.trim() : "";
    const featuredUntil = data.featured_until instanceof Timestamp
      ? data.featured_until
      : null;
    if (!venueId || featuredUntil == null) {
      continue;
    }

    offerRemindersSent += await sendWalletMerchantNotification(db, {
      venueId,
      eventKeyPrefix: `wallet_offer_expiring_${doc.id}_${featuredUntil.toMillis()}`,
      title: "سينتهي تمييز العرض قريبًا",
      body: `ينتهي تمييز العرض خلال ${EXPIRY_REMINDER_WINDOW_HOURS} ساعة.`,
      type: "wallet_offer_pin_expiring",
      preferenceKey: WALLET_EXPIRY_REMINDER_PREF_FIELD,
      data: {
        venue_id: venueId,
        offer_id: doc.id,
        featured_until: featuredUntil,
      },
    });
  }

  const nowMillis = now.toMillis();
  if (storyRemindersSent > 0) {
    logSecurityAudit("story_promotion_expiring_soon", {
      count: storyRemindersSent,
      reminderWindowHours: EXPIRY_REMINDER_WINDOW_HOURS,
      timestamp: nowMillis,
    });
  }
  if (offerRemindersSent > 0) {
    logSecurityAudit("offer_pin_expiring_soon", {
      count: offerRemindersSent,
      reminderWindowHours: EXPIRY_REMINDER_WINDOW_HOURS,
      timestamp: nowMillis,
    });
  }

  return {
    storyRemindersSent,
    offerRemindersSent,
    scans: {
      stories: expiringStoriesSnap.size,
      offers: expiringOffersSnap.size,
    },
    hasMore: {
      stories: expiringStoriesSnap.size >= limitPerType,
      offers: expiringOffersSnap.size >= limitPerType,
    },
    reminderDeadline,
  };
}

export const walletLifecycleMaintenance = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    await runWalletLifecycleMaintenance();
    return null;
  });

export const walletExpiryReminderMaintenance = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    await runWalletExpiryReminderMaintenance();
    return null;
  });
