import { applicationDefault, cert, getApps, initializeApp } from "firebase-admin/app";
import type { App, ServiceAccount } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import type { Auth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";
import fs from "node:fs";
import path from "node:path";

function isProduction(): boolean {
  return process.env.NODE_ENV === "production";
}

function resolveServiceAccountPath(): string | null {
  const candidates = [
    process.env.WAIN_FIREBASE_SERVICE_ACCOUNT_PATH,
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.resolve(process.cwd(), "../service-account-key.json"),
    path.resolve(process.cwd(), "../serviceAccountKey.json"),
    path.resolve(process.cwd(), "service-account-key.json"),
    path.resolve(process.cwd(), "serviceAccountKey.json"),
  ].filter((value): value is string => Boolean(value));

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return null;
}

function readServiceAccountCredential(): ReturnType<typeof cert> | null {
  const serviceAccountPath = resolveServiceAccountPath();
  if (!serviceAccountPath) {
    return null;
  }

  try {
    const raw = fs.readFileSync(serviceAccountPath, "utf8");
    const serviceAccount = JSON.parse(raw) as ServiceAccount;
    return cert(serviceAccount);
  } catch (error) {
    console.warn("Could not load Firebase service account file.", error);
    return null;
  }
}

function resolveCredential(): ReturnType<typeof applicationDefault> | ReturnType<typeof cert> {
  if (isProduction()) {
    // Production must use ADC. JSON key paths are intentionally skipped so a
    // stray key file cannot be selected from a Cloud Run image.
    console.log("[firebase/server] credential=adc");
    return applicationDefault();
  }

  const serviceAccountCredential = readServiceAccountCredential();
  if (serviceAccountCredential) {
    console.log("[firebase/server] credential=cert");
    return serviceAccountCredential;
  }

  console.log("[firebase/server] credential=adc");
  return applicationDefault();
}

function initializeFirebaseAdmin() {
  const apps = getApps();
  if (apps.length > 0) {
    return apps[0];
  }

  const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "wain-d2e28";

  const useFirebaseEmulators =
    process.env.WAIN_USE_FIREBASE_EMULATORS === "1" ||
    process.env.NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS === "1";

  // Prevent accidental emulator routing from stale env values.
  if (!useFirebaseEmulators) {
    delete process.env.FIREBASE_AUTH_EMULATOR_HOST;
    delete process.env.FIRESTORE_EMULATOR_HOST;
  }

  // If we're not in production and emulators are explicitly enabled, use emulator mode.
  if (process.env.NODE_ENV !== "production" && useFirebaseEmulators) {
    // Emulator mode requires minimally a project Id
    return initializeApp({ projectId });
  }

  // In production (like Firebase Hosting/Cloud Functions), ADC usually works.
  try {
    return initializeApp({
      credential: resolveCredential(),
      projectId,
    });
  } catch (e) {
    if (isProduction()) {
      console.warn("Could not initialize Admin SDK with ADC. Check Cloud Run service account.", e);
      throw e;
    }

    // Fallback if environment hasn't auto-discovered credentials but we are building
    console.warn("Could not auto-initialize Admin SDK. Check credentials.");
    return initializeApp({ projectId });
  }
}

let _adminApp: App | null = null;

export function getAdminApp(): App {
  if (_adminApp) {
    return _adminApp;
  }
  _adminApp = initializeFirebaseAdmin();
  return _adminApp;
}

export function getAdminAuth(): Auth {
  return getAuth(getAdminApp());
}

export function getAdminDb(): Firestore {
  return getFirestore(getAdminApp());
}

// Legacy named exports for backward compatibility — lazily resolved.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const adminApp = new Proxy({} as App, {
  get(_target, prop) {
    return (getAdminApp() as unknown as Record<string | symbol, unknown>)[prop];
  },
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const adminAuth = new Proxy({} as Auth, {
  get(_target, prop) {
    return (getAdminAuth() as unknown as Record<string | symbol, unknown>)[prop];
  },
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const adminDb = new Proxy({} as Firestore, {
  get(_target, prop) {
    return (getAdminDb() as unknown as Record<string | symbol, unknown>)[prop];
  },
});
