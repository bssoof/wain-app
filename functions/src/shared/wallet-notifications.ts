import { Timestamp } from "firebase-admin/firestore";

import { roundMoney } from "./admin-surface-helpers";
import {
  ADMIN_WALLET_NOTIFICATION_PREF_FIELD,
  filterUserUidsByWalletNotificationPreference,
  WALLET_NOTIFICATION_PREF_FIELD,
  WalletNotificationPreferenceKey,
} from "./wallet-notification-preferences";

type DedupedNotificationParams = {
  eventKey: string;
  userUid: string;
  title: string;
  body: string;
  type: string;
  venueId?: string | null;
  recipientRole: "merchant" | "admin";
  data?: Record<string, unknown>;
};

type WalletUserNotificationParams = {
  userUids: string[];
  eventKeyPrefix: string;
  title: string;
  body: string;
  type: string;
  venueId?: string | null;
  recipientRole: "merchant" | "admin";
  preferenceKey: WalletNotificationPreferenceKey;
  data?: Record<string, unknown>;
};

export type WalletMerchantNotificationParams = {
  venueId: string;
  eventKeyPrefix: string;
  title: string;
  body: string;
  type: string;
  preferenceKey?: WalletNotificationPreferenceKey;
  data?: Record<string, unknown>;
};

export type WalletAdminNotificationParams = {
  venueId: string;
  eventKeyPrefix: string;
  title: string;
  body: string;
  type: string;
  preferenceKey?: WalletNotificationPreferenceKey;
  data?: Record<string, unknown>;
};

export async function writeDedupedUserNotification(
  db: FirebaseFirestore.Firestore,
  params: DedupedNotificationParams,
): Promise<boolean> {
  const normalizedUserUid = params.userUid.trim();
  const normalizedEventKey = params.eventKey.trim();
  if (!normalizedUserUid || !normalizedEventKey) {
    return false;
  }

  const eventRef = db.collection("wallet_notification_events").doc(normalizedEventKey);
  const notificationRef = db.collection("users").doc(normalizedUserUid)
    .collection("notifications")
    .doc();
  const now = Timestamp.now();
  let created = false;

  await db.runTransaction(async (t) => {
    const eventDoc = await t.get(eventRef);
    if (eventDoc.exists) {
      return;
    }

    t.set(notificationRef, {
      title: params.title,
      body: params.body,
      type: params.type,
      data: params.data ?? {},
      is_read: false,
      created_at: now,
    });

    t.set(eventRef, {
      event_key: normalizedEventKey,
      user_uid: normalizedUserUid,
      recipient_role: params.recipientRole,
      type: params.type,
      venue_id: params.venueId ?? null,
      notification_path: notificationRef.path,
      created_at: now,
      updated_at: now,
      data: params.data ?? {},
    });

    created = true;
  });

  return created;
}

export async function sendWalletNotificationToUsers(
  db: FirebaseFirestore.Firestore,
  params: WalletUserNotificationParams,
): Promise<number> {
  const uniqueUserUids = Array.from(new Set(
    params.userUids
      .map((uid) => uid.trim())
      .filter((uid) => uid.length > 0),
  ));
  if (uniqueUserUids.length === 0) {
    return 0;
  }

  const eligibleUserUids = await filterUserUidsByWalletNotificationPreference(
    db,
    uniqueUserUids,
    params.preferenceKey,
  );
  if (eligibleUserUids.length === 0) {
    return 0;
  }

  const writes = await Promise.all(eligibleUserUids.map((userUid) => {
    const eventKey = `${params.eventKeyPrefix}_${userUid}`;
    return writeDedupedUserNotification(db, {
      eventKey,
      userUid,
      title: params.title,
      body: params.body,
      type: params.type,
      venueId: params.venueId,
      recipientRole: params.recipientRole,
      data: params.data,
    });
  }));

  return writes.filter(Boolean).length;
}

async function getMerchantUserUidsForVenue(
  db: FirebaseFirestore.Firestore,
  venueId: string,
): Promise<string[]> {
  const merchantQuery = await db.collection("merchants")
    .where("venue_id", "==", venueId)
    .limit(10)
    .get();
  return merchantQuery.docs
    .map((doc) => {
      const uid = doc.data().uid;
      if (typeof uid === "string" && uid.trim().length > 0) {
        return uid.trim();
      }
      return doc.id.trim();
    })
    .filter((uid) => uid.length > 0);
}

async function getActiveAdminUids(
  db: FirebaseFirestore.Firestore,
): Promise<string[]> {
  const adminSnap = await db.collection("admins").limit(20).get();
  return adminSnap.docs
    .filter((doc) => doc.data()?.active !== false)
    .map((doc) => doc.id.trim())
    .filter((uid) => uid.length > 0);
}

export function formatCurrencyAmount(amount: number, currency: string = "ILS"): string {
  return `${roundMoney(amount).toFixed(2)} ${currency}`;
}

export async function sendWalletMerchantNotification(
  db: FirebaseFirestore.Firestore,
  params: WalletMerchantNotificationParams,
): Promise<number> {
  const merchantUids = await getMerchantUserUidsForVenue(db, params.venueId);
  return sendWalletNotificationToUsers(db, {
    userUids: merchantUids,
    eventKeyPrefix: params.eventKeyPrefix,
    title: params.title,
    body: params.body,
    type: params.type,
    venueId: params.venueId,
    recipientRole: "merchant",
    preferenceKey: params.preferenceKey ?? WALLET_NOTIFICATION_PREF_FIELD,
    data: params.data,
  });
}

export async function sendWalletAdminNotification(
  db: FirebaseFirestore.Firestore,
  params: WalletAdminNotificationParams,
): Promise<number> {
  const adminUids = await getActiveAdminUids(db);
  return sendWalletNotificationToUsers(db, {
    userUids: adminUids,
    eventKeyPrefix: params.eventKeyPrefix,
    title: params.title,
    body: params.body,
    type: params.type,
    venueId: params.venueId,
    recipientRole: "admin",
    preferenceKey: params.preferenceKey ?? ADMIN_WALLET_NOTIFICATION_PREF_FIELD,
    data: params.data,
  });
}
