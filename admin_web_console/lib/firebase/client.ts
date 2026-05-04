import { initializeApp, getApps } from "firebase/app";
import {
  browserLocalPersistence,
  browserSessionPersistence,
  getAuth,
  indexedDBLocalPersistence,
  initializeAuth,
} from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyC9YKkNcRIbFkVeiO-sBbA2zgJxEzm6rlM",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:620614484841:web:ac86320829e764bc41b3f8",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "620614484841",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "wain-d2e28",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "wain-d2e28.firebaseapp.com",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "wain-d2e28.firebasestorage.app",
};

export const app =
  getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

let authInstance;

try {
  // Admin console uses email/password only; disable popup/redirect resolver
  // to avoid OAuth iframe/domain warnings for features we do not use.
  authInstance = initializeAuth(app, {
    persistence: [
      indexedDBLocalPersistence,
      browserLocalPersistence,
      browserSessionPersistence,
    ],
    popupRedirectResolver: undefined,
  });
} catch {
  authInstance = getAuth(app);
}

export const auth = authInstance;

// Use emulators only when explicitly enabled.
const useFirebaseEmulators =
  process.env.NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS === "1";

if (process.env.NODE_ENV === "development" && useFirebaseEmulators) {
  const emulatorHost = process.env.NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST;
  if (emulatorHost) {
    const { connectAuthEmulator } = require("firebase/auth");
    connectAuthEmulator(auth, `http://${emulatorHost}`, { disableWarnings: true });
  }
}
