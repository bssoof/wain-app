import "server-only";

import { getStepUpEnforcementMode } from "./step-up-config";
import {
  issueStepUpToken,
  resolveStepUpSigningKey,
  verifyStepUpToken,
} from "./step-up-token";

export type StepUpHealthCheckName =
  | "secret_manager"
  | "token_signing"
  | "firestore_config";

export type StepUpHealthCheckResult = {
  ok: boolean;
  error?: string;
  mode?: string;
};

export type StepUpHealthReport = {
  status: "healthy" | "degraded";
  timestamp: string;
  checks: Record<StepUpHealthCheckName, StepUpHealthCheckResult>;
};

type FirestoreDocSnapshotLike = {
  exists?: boolean;
  data: () => unknown;
};

type FirestoreDbLike = {
  collection: (collectionId: string) => {
    doc: (documentId: string) => {
      get: () => Promise<FirestoreDocSnapshotLike>;
    };
  };
};

type StepUpHealthOptions = {
  now?: () => Date;
  timeoutMs?: number;
  resolveSigningKey?: () => Promise<Buffer>;
  db?: FirestoreDbLike;
};

const DEFAULT_CHECK_TIMEOUT_MS = 2_000;
const MIN_SIGNING_KEY_BYTES = 32;

export async function runStepUpHealthChecks(
  options: StepUpHealthOptions = {},
): Promise<StepUpHealthReport> {
  const now = options.now ?? (() => new Date());
  const timeoutMs = options.timeoutMs ?? DEFAULT_CHECK_TIMEOUT_MS;
  const resolveSigningKey =
    options.resolveSigningKey ?? (() => resolveStepUpSigningKey());

  const secretManager = await withTimeout(
    checkSecretManager(resolveSigningKey),
    timeoutMs,
    "secret_manager_timeout",
  );
  const tokenSigning = await withTimeout(
    checkTokenSigning(resolveSigningKey, now),
    timeoutMs,
    "token_signing_timeout",
  );
  const firestoreConfig = await withTimeout(
    checkFirestoreConfig(options.db),
    timeoutMs,
    "firestore_config_timeout",
  );

  const checks = {
    secret_manager: secretManager,
    token_signing: tokenSigning,
    firestore_config: firestoreConfig,
  };
  const healthy = Object.values(checks).every((check) => check.ok);

  return {
    status: healthy ? "healthy" : "degraded",
    timestamp: now().toISOString(),
    checks,
  };
}

async function checkSecretManager(
  resolveSigningKey: () => Promise<Buffer>,
): Promise<StepUpHealthCheckResult> {
  try {
    const signingKey = await resolveSigningKey();
    if (signingKey.length < MIN_SIGNING_KEY_BYTES) {
      return { ok: false, error: "signing_key_too_short" };
    }
    return { ok: true };
  } catch {
    return { ok: false, error: "secret_unavailable" };
  }
}

async function checkTokenSigning(
  resolveSigningKey: () => Promise<Buffer>,
  now: () => Date,
): Promise<StepUpHealthCheckResult> {
  try {
    const signingKey = await resolveSigningKey();
    const nowMs = now().getTime();
    const nowSeconds = Math.floor(nowMs / 1000);
    const issued = await issueStepUpToken(
      {
        sub: "health-check",
        scope: "finance",
        authTime: nowSeconds,
      },
      {
        signingKey,
        nowMs,
        jti: "health-check",
      },
    );
    const verified = await verifyStepUpToken(
      issued.token,
      {
        scope: "finance",
        subject: "health-check",
      },
      {
        signingKey,
        nowMs,
      },
    );

    return verified.jti === "health-check"
      ? { ok: true }
      : { ok: false, error: "token_roundtrip_mismatch" };
  } catch {
    return { ok: false, error: "token_roundtrip_failed" };
  }
}

async function checkFirestoreConfig(
  db?: FirestoreDbLike,
): Promise<StepUpHealthCheckResult> {
  let readError: unknown;
  const mode = await getStepUpEnforcementMode({
    ...(db ? { db } : {}),
    useCache: false,
    onReadError: (error) => {
      readError = error;
    },
  });

  return readError
    ? { ok: false, error: "firestore_config_unavailable" }
    : { ok: true, mode };
}

async function withTimeout(
  check: Promise<StepUpHealthCheckResult>,
  timeoutMs: number,
  timeoutError: string,
): Promise<StepUpHealthCheckResult> {
  let timeout: NodeJS.Timeout | undefined;
  try {
    return await Promise.race([
      check,
      new Promise<StepUpHealthCheckResult>((resolve) => {
        timeout = setTimeout(() => {
          resolve({ ok: false, error: timeoutError });
        }, timeoutMs);
      }),
    ]);
  } finally {
    if (timeout) {
      clearTimeout(timeout);
    }
  }
}
