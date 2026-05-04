import * as functions from "firebase-functions/v1";

export type AdminAccessResult = {
  uid: string;
  source: "claim" | "document";
};

export type AdminExecutionRole = "finance_admin" | "super_admin";

export function isEmulatorOwnerToken(context: functions.https.CallableContext): boolean {
  if (process.env.FUNCTIONS_EMULATOR !== "true") {
    return false;
  }

  const authorizationHeader = context.rawRequest?.headers?.authorization;
  if (typeof authorizationHeader !== "string") {
    return false;
  }

  return authorizationHeader.trim().toLowerCase() === "bearer owner";
}

export async function requireAdminAccessWithDb(
  context: functions.https.CallableContext,
  db: FirebaseFirestore.Firestore,
): Promise<AdminAccessResult> {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required",
    );
  }

  const token = context.auth.token as Record<string, unknown>;
  const uidCandidates = [
    context.auth.uid,
    typeof token.uid === "string" ? token.uid : undefined,
    typeof token.user_id === "string" ? token.user_id : undefined,
    typeof token.sub === "string" ? token.sub : undefined,
  ];
  const uid = uidCandidates.find(
    (candidate): candidate is string =>
      typeof candidate === "string" && candidate.trim().length > 0,
  );

  if (!uid && isEmulatorOwnerToken(context)) {
    return { uid: "owner", source: "claim" };
  }

  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required",
    );
  }

  if (token.admin === true || token.role === "admin") {
    return { uid, source: "claim" };
  }

  const adminDoc = await db.collection("admins").doc(uid).get();
  if (adminDoc.exists && adminDoc.data()?.active !== false) {
    return { uid, source: "document" };
  }

  throw new functions.https.HttpsError(
    "permission-denied",
    "Requires admin privileges",
  );
}

export function resolveAdminExecutionRole(
  context: functions.https.CallableContext,
): AdminExecutionRole {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }

  return "finance_admin";
}

export function resolveRequiredSecondApproverRole(
  amountIls: number,
  requesterRole: AdminExecutionRole,
  thresholds: {
    singleApprovalLimitIls: number;
    superAdminThresholdIls: number;
  },
): AdminExecutionRole {
  if (amountIls <= thresholds.singleApprovalLimitIls) {
    return requesterRole;
  }

  if (amountIls > thresholds.superAdminThresholdIls) {
    return "super_admin";
  }

  return "finance_admin";
}
