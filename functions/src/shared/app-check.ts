import * as functions from "firebase-functions/v1";

export function requireAppCheck(
  context: functions.https.CallableContext,
  message: string = "App Check verification failed",
): void {
  if (!context.app) {
    throw new functions.https.HttpsError("failed-precondition", message);
  }
}
