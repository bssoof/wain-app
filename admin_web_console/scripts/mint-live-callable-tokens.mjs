#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

const DEFAULT_PROJECT_ID = "wain-d2e28";
const DEFAULT_APP_ID = "1:620614484841:web:ac86320829e764bc41b3f8";
const DEFAULT_API_KEY = "AIzaSyC9YKkNcRIbFkVeiO-sBbA2zgJxEzm6rlM";

function resolveServiceAccountPath() {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const candidates = [
    process.env.WAIN_FIREBASE_SERVICE_ACCOUNT_PATH,
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.resolve(scriptDir, "..", "..", "service-account-key.json"),
    path.resolve(scriptDir, "..", "..", "serviceAccountKey.json"),
    path.resolve(scriptDir, "..", "service-account-key.json"),
    path.resolve(scriptDir, "..", "serviceAccountKey.json"),
  ].filter((value) => typeof value === "string" && value.trim().length > 0);

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return null;
}

function decodeJwtExpiration(token) {
  if (typeof token !== "string" || token.length === 0) {
    return null;
  }

  const parts = token.split(".");
  if (parts.length < 2) {
    return null;
  }

  try {
    const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
    if (typeof payload.exp !== "number") {
      return null;
    }
    return {
      epochSeconds: payload.exp,
      iso: new Date(payload.exp * 1000).toISOString(),
    };
  } catch {
    return null;
  }
}

function initializeAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const serviceAccountPath = resolveServiceAccountPath();
  const projectId =
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    DEFAULT_PROJECT_ID;

  if (serviceAccountPath) {
    const raw = fs.readFileSync(serviceAccountPath, "utf8");
    const serviceAccount = JSON.parse(raw);
    return admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
    });
  }

  return admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });
}

async function signInWithCustomToken(apiKey, customToken) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        token: customToken,
        returnSecureToken: true,
      }),
    },
  );

  const body = await response.json();
  if (!response.ok || typeof body.idToken !== "string") {
    throw new Error(`Identity Toolkit sign-in failed: ${JSON.stringify(body)}`);
  }

  return body.idToken;
}

async function main() {
  const app = initializeAdmin();
  const projectId = app.options.projectId || DEFAULT_PROJECT_ID;
  const appId = process.env.NEXT_PUBLIC_FIREBASE_APP_ID || DEFAULT_APP_ID;
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY || DEFAULT_API_KEY;
  const adminUid = process.env.WAIN_LIVE_ADMIN_UID || "local-dev-admin-cli";

  const appCheckResponse = await app.appCheck().createToken(appId);

  const customToken = await app.auth().createCustomToken(adminUid, {
    admin: true,
    isAdmin: true,
    role: "super_admin",
    roles: ["super_admin"],
    super_admin: true,
    finance_admin: true,
    content_admin: true,
  });

  const idToken = await signInWithCustomToken(apiKey, customToken);

  const result = {
    projectId,
    appId,
    apiKey,
    functionsBaseUrl: `https://us-central1-${projectId}.cloudfunctions.net`,
    admin: {
      uid: adminUid,
      role: "super_admin",
    },
    tokens: {
      authToken: idToken,
      appCheckToken: appCheckResponse.token,
    },
    tokenExpirations: {
      authToken: decodeJwtExpiration(idToken),
      appCheckToken: decodeJwtExpiration(appCheckResponse.token),
    },
  };

  console.log(JSON.stringify(result, null, 2));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
