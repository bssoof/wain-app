#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");

function resolveServiceAccountPath() {
  const candidates = [
    process.env.WAIN_FIREBASE_SERVICE_ACCOUNT_PATH,
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.resolve(__dirname, "../service-account-key.json"),
    path.resolve(__dirname, "../serviceAccountKey.json"),
    path.resolve(process.cwd(), "service-account-key.json"),
    path.resolve(process.cwd(), "serviceAccountKey.json"),
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error("Service account key file was not found.");
}

function initAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const serviceAccountPath = resolveServiceAccountPath();
  const raw = fs.readFileSync(serviceAccountPath, "utf8");
  const serviceAccount = JSON.parse(raw);

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id || "wain-d2e28",
  });
}

async function ensureTestAdminUser({ auth, db, email, password }) {
  let user;
  try {
    user = await auth.getUserByEmail(email);
    await auth.updateUser(user.uid, { password, emailVerified: true, disabled: false });
  } catch (error) {
    if (error && error.code === "auth/user-not-found") {
      user = await auth.createUser({
        email,
        password,
        emailVerified: true,
        disabled: false,
        displayName: "Media Smoke Admin",
      });
    } else {
      throw error;
    }
  }

  await db.collection("admins").doc(user.uid).set(
    {
      active: true,
      role: "super_admin",
      roles: ["super_admin"],
      name: "Media Smoke Admin",
      email,
      updated_at: new Date().toISOString(),
    },
    { merge: true },
  );

  // Media governance callables require role claims in the auth token.
  await auth.setCustomUserClaims(user.uid, {
    role: "super_admin",
    super_admin: true,
    content_admin: true,
  });

  return user;
}

async function signInWithPassword({ apiKey, email, password }) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );

  const body = await response.json();
  if (!response.ok || !body.idToken) {
    throw new Error(`Firebase sign-in failed: ${JSON.stringify(body)}`);
  }

  return body.idToken;
}

function callableList() {
  return [
    "listVenuesForAdmin",
    "getAdminMediaInventoryReadBundle",
    "mediaReferenceCheckAsset",
    "mediaSoftDeleteAsset",
    "mediaQuarantineAsset",
    "mediaPurgeAsset",
  ];
}

async function probeCallable({ baseUrl, idToken, appCheckToken, name }) {
  const payload = arguments[0].payload ?? { probe: true };
  const res = await fetch(`${baseUrl}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${idToken}`,
      "X-Firebase-AppCheck": appCheckToken,
    },
    body: JSON.stringify({ data: payload }),
  });

  const text = await res.text();
  const appCheckFailed = text.includes("App Check verification failed");

  return {
    name,
    httpStatus: res.status,
    result:
      res.status === 200
        ? "ok"
        : appCheckFailed
          ? "app_check_failed"
          : res.status === 404
            ? "missing_endpoint"
            : "non_200",
    bodySnippet: text.slice(0, 240),
  };
}

function buildProbePayloads(runId) {
  const targetId = `media_probe_${runId}`;

  return {
    listVenuesForAdmin: { limit: 1 },
    getAdminMediaInventoryReadBundle: { topupProofLimit: 1, venuePhotoLimit: 1, offerImageLimit: 1, storyImageLimit: 1 },
    mediaReferenceCheckAsset: {
      targetType: "media_asset",
      targetId,
      commandId: `${runId}_reference_check`,
      correlationId: `${runId}:reference_check`,
      idempotencyKey: `${runId}_reference_check`,
      reason: "media_reference_check",
      expectedState: { media_state: "active" },
    },
    mediaSoftDeleteAsset: {
      targetType: "media_asset",
      targetId,
      commandId: `${runId}_soft_delete`,
      correlationId: `${runId}:soft_delete`,
      idempotencyKey: `${runId}_soft_delete`,
      reason: "media_probe_soft_delete",
      expectedState: { media_state: "active" },
    },
    mediaQuarantineAsset: {
      targetType: "media_asset",
      targetId,
      commandId: `${runId}_quarantine`,
      correlationId: `${runId}:quarantine`,
      idempotencyKey: `${runId}_quarantine`,
      reason: "media_probe_quarantine",
      quarantineDays: 1,
      expectedState: { media_state: "soft_deleted" },
    },
    mediaPurgeAsset: {
      targetType: "media_asset",
      targetId,
      commandId: `${runId}_purge`,
      correlationId: `${runId}:purge`,
      idempotencyKey: `${runId}_purge`,
      reason: "media_probe_purge",
      expectedState: {
        media_state: "quarantined",
        reference_index_health: "healthy",
        reference_count: 0,
      },
    },
  };
}

async function cleanupTestAdminUser({ auth, db, uid }) {
  await db.collection("admins").doc(uid).delete().catch(() => {});
  await auth.deleteUser(uid).catch(() => {});
}

async function main() {
  const baseUrl =
    process.env.WAIN_STAGING_FUNCTIONS_BASE_URL ||
    process.env.NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL ||
    process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL ||
    "https://us-central1-wain-d2e28.cloudfunctions.net";

  const appCheckToken =
    process.env.WAIN_STAGING_APP_CHECK_TOKEN ||
    process.env.NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN ||
    process.env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN ||
    process.env.NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN ||
    process.env.NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN ||
    "local-dev-app-check";

  const apiKey =
    process.env.NEXT_PUBLIC_FIREBASE_API_KEY ||
    "AIzaSyC9YKkNcRIbFkVeiO-sBbA2zgJxEzm6rlM";

  const testEmail = process.env.ADMIN_SMOKE_EMAIL || "media.smoke.admin@wain.local";
  const testPassword = process.env.ADMIN_SMOKE_PASSWORD || "WainAdmin!2026";

  const app = initAdmin();
  const auth = app.auth();
  const db = app.firestore();

  const user = await ensureTestAdminUser({ auth, db, email: testEmail, password: testPassword });

  let result;
  try {
    const idToken = await signInWithPassword({ apiKey, email: testEmail, password: testPassword });
    const runId = `${Date.now()}_${Math.floor(Math.random() * 1_000_000)}`;
    const payloads = buildProbePayloads(runId);

    const endpoints = [];
    for (const name of callableList()) {
      endpoints.push(
        await probeCallable({
          baseUrl,
          idToken,
          appCheckToken,
          name,
          payload: payloads[name],
        }),
      );
    }

    const summary = {
      probesTotal: endpoints.length,
      probesHttp200: endpoints.filter((item) => item.httpStatus === 200).length,
      probesHttp404: endpoints.filter((item) => item.httpStatus === 404).length,
      probesAppCheckFailed: endpoints.filter((item) => item.result === "app_check_failed").length,
    };

    result = {
      round: "AWC-UI-030",
      timestamp: new Date().toISOString(),
      project: "wain-d2e28",
      mode: "media_transport_authenticated_probe",
      auth: {
        adminToken: "present",
        appCheckToken:
          appCheckToken && appCheckToken !== "local-dev-app-check" ? "present_non_placeholder" : "present_placeholder",
      },
      summary,
      routes: ["/admin/media"],
      endpoints,
      decisionHint: summary.probesHttp200 === endpoints.length ? "FOLLOW_UP_CLOSED" : "FOLLOW_UP_REQUIRED",
    };
  } finally {
    if (process.env.ADMIN_SMOKE_CLEANUP === "1") {
      await cleanupTestAdminUser({ auth, db, uid: user.uid });
    }
  }

  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);

  if (result.summary.probesHttp200 !== result.summary.probesTotal) {
    process.exitCode = 2;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
