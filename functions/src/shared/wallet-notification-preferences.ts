export const WALLET_NOTIFICATION_PREF_FIELD = "wallet_notifications_enabled";
export const WALLET_EXPIRY_REMINDER_PREF_FIELD = "wallet_expiry_reminders_enabled";
export const ADMIN_WALLET_NOTIFICATION_PREF_FIELD = "admin_wallet_notifications_enabled";

export type WalletNotificationPreferenceKey =
  | typeof WALLET_NOTIFICATION_PREF_FIELD
  | typeof WALLET_EXPIRY_REMINDER_PREF_FIELD
  | typeof ADMIN_WALLET_NOTIFICATION_PREF_FIELD;

export function isWalletNotificationPreferenceEnabled(
  data: FirebaseFirestore.DocumentData | undefined,
  preferenceKey: WalletNotificationPreferenceKey,
): boolean {
  return data?.[preferenceKey] !== false;
}

export async function filterUserUidsByWalletNotificationPreference(
  db: FirebaseFirestore.Firestore,
  userUids: string[],
  preferenceKey: WalletNotificationPreferenceKey,
): Promise<string[]> {
  if (userUids.length === 0) {
    return [];
  }

  const userRefs = userUids.map((uid) => db.collection("users").doc(uid));
  const userDocs = await db.getAll(...userRefs);
  return userDocs
    .filter((doc) =>
      isWalletNotificationPreferenceEnabled(doc.data(), preferenceKey),
    )
    .map((doc) => doc.id.trim())
    .filter((uid) => uid.length > 0);
}
