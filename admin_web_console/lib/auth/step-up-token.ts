import "server-only";

import { createHmac, randomUUID, timingSafeEqual } from "node:crypto";

import {
  STEP_UP_ISSUE_MAX_AUTH_AGE_SECONDS,
  STEP_UP_TTL_MS,
  isStepUpScope,
  type StepUpScope,
} from "./step-up-required";
import { verifyIdTokenForAdminSession } from "./session-cookie";

const JWT_ALGORITHM = "HS256";
const JWT_TYPE = "JWT";
const MAX_AUTH_TIME_CLOCK_SKEW_SECONDS = 30;
const DEFAULT_SECRET_ID = "wain-admin-step-up-signing-key";
const SECRET_MANAGER_API_ROOT = "https://secretmanager.googleapis.com/v1";

export type StepUpTokenPayload = {
  sub: string;
  scope: StepUpScope;
  iat: number;
  exp: number;
  authTime: number;
  jti: string;
};

export type StepUpTokenIssueResult = {
  token: string;
  payload: StepUpTokenPayload;
  expiresAtEpochMs: number;
};

export type StepUpTokenErrorCode =
  | "missing_id_token"
  | "invalid_scope"
  | "missing_signing_key"
  | "secret_unavailable"
  | "invalid_token"
  | "expired_token"
  | "scope_mismatch"
  | "subject_mismatch"
  | "stale_auth_time";

export class StepUpTokenError extends Error {
  readonly code: StepUpTokenErrorCode;

  constructor(code: StepUpTokenErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = "StepUpTokenError";
  }
}

type StepUpTokenOptions = {
  nowMs?: number;
  jti?: string;
  signingKey?: string | Buffer;
  env?: Record<string, string | undefined>;
  fetchImpl?: typeof fetch;
};

export async function issueStepUpTokenForIdToken(
  idToken: string,
  scope: StepUpScope,
  options: StepUpTokenOptions = {},
): Promise<StepUpTokenIssueResult> {
  const normalizedToken = idToken.trim();
  if (!normalizedToken) {
    throw new StepUpTokenError("missing_id_token", "Missing idToken");
  }

  if (!isStepUpScope(scope)) {
    throw new StepUpTokenError("invalid_scope", "Invalid step-up scope");
  }

  const { decodedIdToken } = await verifyIdTokenForAdminSession(normalizedToken);
  const authTime = normalizeEpochSeconds(decodedIdToken.auth_time);

  return issueStepUpToken(
    {
      sub: decodedIdToken.uid,
      scope,
      authTime,
    },
    options,
  );
}

export async function issueStepUpToken(
  input: {
    sub: string;
    scope: StepUpScope;
    authTime: number;
  },
  options: StepUpTokenOptions = {},
): Promise<StepUpTokenIssueResult> {
  const nowMs = options.nowMs ?? Date.now();
  const nowSeconds = Math.floor(nowMs / 1000);
  assertFreshAuthTime(input.authTime, nowSeconds);

  const payload: StepUpTokenPayload = {
    sub: input.sub,
    scope: input.scope,
    iat: nowSeconds,
    exp: nowSeconds + Math.floor(STEP_UP_TTL_MS / 1000),
    authTime: input.authTime,
    jti: options.jti ?? randomUUID(),
  };

  const signingKey = await resolveStepUpSigningKey(options);
  const token = signJwt(payload, signingKey);

  return {
    token,
    payload,
    expiresAtEpochMs: payload.exp * 1000,
  };
}

export async function verifyStepUpToken(
  token: string,
  expected: {
    scope: StepUpScope;
    subject: string;
  },
  options: StepUpTokenOptions = {},
): Promise<StepUpTokenPayload> {
  const signingKey = await resolveStepUpSigningKey(options);
  const payload = verifyJwt(token, signingKey);
  const nowSeconds = Math.floor((options.nowMs ?? Date.now()) / 1000);

  if (payload.exp <= nowSeconds) {
    throw new StepUpTokenError("expired_token", "Step-up token has expired");
  }

  if (payload.scope !== expected.scope) {
    throw new StepUpTokenError(
      "scope_mismatch",
      "Step-up token scope does not match this command",
    );
  }

  if (payload.sub !== expected.subject) {
    throw new StepUpTokenError(
      "subject_mismatch",
      "Step-up token belongs to a different admin session",
    );
  }

  return payload;
}

export async function resolveStepUpSigningKey(
  options: Pick<StepUpTokenOptions, "signingKey" | "env" | "fetchImpl"> = {},
): Promise<Buffer> {
  if (options.signingKey) {
    return toSigningKeyBuffer(options.signingKey);
  }

  const env = options.env ?? process.env;
  const directKey = toNonEmptyString(env.WAIN_ADMIN_STEP_UP_SIGNING_KEY);
  if (directKey) {
    if (env.NODE_ENV === "production") {
      throw new StepUpTokenError(
        "missing_signing_key",
        "Direct step-up signing key env values are forbidden in production. Configure Secret Manager.",
      );
    }

    return Buffer.from(directKey, "utf8");
  }

  const secretVersion = resolveSecretVersionResource(env);
  if (!secretVersion) {
    throw new StepUpTokenError(
      "missing_signing_key",
      "Step-up signing key is not configured.",
    );
  }

  const secret = await accessSecretManagerVersion(
    secretVersion,
    env,
    options.fetchImpl ?? fetch,
  );
  return Buffer.from(secret, "utf8");
}

function signJwt(payload: StepUpTokenPayload, signingKey: Buffer): string {
  const header = {
    alg: JWT_ALGORITHM,
    typ: JWT_TYPE,
  };
  const encodedHeader = base64UrlEncodeJson(header);
  const encodedPayload = base64UrlEncodeJson(payload);
  const signature = sign(`${encodedHeader}.${encodedPayload}`, signingKey);
  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

function verifyJwt(token: string, signingKey: Buffer): StepUpTokenPayload {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new StepUpTokenError("invalid_token", "Malformed step-up token");
  }

  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const header = parseBase64UrlJson(encodedHeader);
  if (header.alg !== JWT_ALGORITHM || header.typ !== JWT_TYPE) {
    throw new StepUpTokenError("invalid_token", "Invalid step-up token header");
  }

  const expectedSignature = sign(`${encodedHeader}.${encodedPayload}`, signingKey);
  if (!safeEqual(encodedSignature, expectedSignature)) {
    throw new StepUpTokenError("invalid_token", "Invalid step-up token signature");
  }

  const payload = parseBase64UrlJson(encodedPayload);
  if (!isStepUpTokenPayload(payload)) {
    throw new StepUpTokenError("invalid_token", "Invalid step-up token payload");
  }

  return payload;
}

function assertFreshAuthTime(authTime: number, nowSeconds: number): void {
  if (!Number.isFinite(authTime)) {
    throw new StepUpTokenError("stale_auth_time", "Fresh re-authentication is required");
  }

  if (authTime > nowSeconds + MAX_AUTH_TIME_CLOCK_SKEW_SECONDS) {
    throw new StepUpTokenError("stale_auth_time", "Invalid future auth_time");
  }

  if (nowSeconds - authTime > STEP_UP_ISSUE_MAX_AUTH_AGE_SECONDS) {
    throw new StepUpTokenError("stale_auth_time", "Fresh re-authentication is required");
  }
}

function sign(value: string, signingKey: Buffer): string {
  return createHmac("sha256", signingKey).update(value).digest("base64url");
}

function safeEqual(left: string, right: string): boolean {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }

  return timingSafeEqual(leftBuffer, rightBuffer);
}

function base64UrlEncodeJson(value: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
}

function parseBase64UrlJson(value: string): Record<string, any> {
  try {
    return JSON.parse(Buffer.from(value, "base64url").toString("utf8")) as Record<
      string,
      any
    >;
  } catch {
    throw new StepUpTokenError("invalid_token", "Malformed step-up token JSON");
  }
}

function isStepUpTokenPayload(value: unknown): value is StepUpTokenPayload {
  if (!value || typeof value !== "object") {
    return false;
  }

  const record = value as Partial<StepUpTokenPayload>;
  return (
    typeof record.sub === "string" &&
    isStepUpScope(record.scope) &&
    typeof record.iat === "number" &&
    typeof record.exp === "number" &&
    typeof record.authTime === "number" &&
    typeof record.jti === "string"
  );
}

function normalizeEpochSeconds(value: unknown): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed)) {
    throw new StepUpTokenError("stale_auth_time", "Fresh re-authentication is required");
  }

  return Math.floor(parsed);
}

function toSigningKeyBuffer(value: string | Buffer): Buffer {
  return Buffer.isBuffer(value) ? value : Buffer.from(value, "utf8");
}

function resolveSecretVersionResource(
  env: Record<string, string | undefined>,
): string | undefined {
  const explicit =
    toNonEmptyString(env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION) ??
    toNonEmptyString(env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_RESOURCE);
  if (explicit) {
    return explicit;
  }

  const projectId =
    toNonEmptyString(env.GOOGLE_CLOUD_PROJECT) ??
    toNonEmptyString(env.GCLOUD_PROJECT) ??
    toNonEmptyString(env.NEXT_PUBLIC_FIREBASE_PROJECT_ID);

  if (!projectId || env.NODE_ENV !== "production") {
    return undefined;
  }

  return `projects/${projectId}/secrets/${DEFAULT_SECRET_ID}/versions/latest`;
}

async function accessSecretManagerVersion(
  secretVersion: string,
  env: Record<string, string | undefined>,
  fetchImpl: typeof fetch,
): Promise<string> {
  const accessToken = await resolveGoogleAccessToken(env, fetchImpl);
  if (!accessToken) {
    throw new StepUpTokenError(
      "secret_unavailable",
      "Could not authenticate to Secret Manager.",
    );
  }

  const response = await fetchImpl(
    `${SECRET_MANAGER_API_ROOT}/${encodeSecretVersionPath(secretVersion)}:access`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      cache: "no-store",
    },
  );

  if (!response.ok) {
    throw new StepUpTokenError(
      "secret_unavailable",
      "Could not read step-up signing key from Secret Manager.",
    );
  }

  const body = (await response.json()) as {
    payload?: {
      data?: unknown;
    };
  };
  const encodedSecret = toNonEmptyString(body.payload?.data);
  if (!encodedSecret) {
    throw new StepUpTokenError(
      "secret_unavailable",
      "Secret Manager returned an empty step-up signing key.",
    );
  }

  return Buffer.from(encodedSecret, "base64").toString("utf8");
}

async function resolveGoogleAccessToken(
  env: Record<string, string | undefined>,
  fetchImpl: typeof fetch,
): Promise<string | undefined> {
  const explicitToken =
    toNonEmptyString(env.WAIN_GOOGLE_OAUTH_ACCESS_TOKEN) ??
    toNonEmptyString(env.GOOGLE_OAUTH_ACCESS_TOKEN);
  if (explicitToken) {
    return explicitToken;
  }

  try {
    const response = await fetchImpl(
      "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
      {
        headers: {
          "Metadata-Flavor": "Google",
        },
        cache: "no-store",
      },
    );

    if (!response.ok) {
      return undefined;
    }

    const body = (await response.json()) as { access_token?: unknown };
    return toNonEmptyString(body.access_token);
  } catch {
    return undefined;
  }
}

function encodeSecretVersionPath(secretVersion: string): string {
  return secretVersion
    .split("/")
    .map((segment) => encodeURIComponent(segment))
    .join("/");
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}
