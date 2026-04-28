import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

export function getDefaultStorageBucket() {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }

  const configuredBucket = admin.app().options.storageBucket;
  if (configuredBucket) {
    return admin.storage().bucket(configuredBucket);
  }

  const envBucket = process.env.FIREBASE_STORAGE_BUCKET || process.env.STORAGE_BUCKET;
  if (envBucket) {
    return admin.storage().bucket(envBucket);
  }

  const projectId = process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    admin.app().options.projectId;
  if (!projectId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "storage_bucket_unavailable",
    );
  }

  if (process.env.FIREBASE_STORAGE_EMULATOR_HOST || process.env.FUNCTIONS_EMULATOR === "true") {
    return admin.storage().bucket(`${projectId}.appspot.com`);
  }

  return admin.storage().bucket(`${projectId}.firebasestorage.app`);
}

export function isInternalProofStoragePath(value: string): boolean {
  return /^venues\/[^/]+\/wallet_topups\/.+/.test(value);
}