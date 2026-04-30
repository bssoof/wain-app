import "server-only";

import type { StepUpEnforcementMode } from "./step-up-config";
import type { StepUpScope } from "./step-up-required";

export type StepUpAuditEventType =
  | "step_up_required"
  | "step_up_verified"
  | "step_up_rejected"
  | "step_up_previous_key_verified"
  | "step_up_log_only_would_reject"
  | "step_up_rate_limited";

export type StepUpAuditEvent = {
  eventType: StepUpAuditEventType;
  userId?: string;
  sessionRole?: string;
  command?: string;
  correlationId?: string;
  scope?: StepUpScope;
  reason?: string;
  enforcementMode?: StepUpEnforcementMode;
  status?: number;
  tokenJti?: string;
  tokenIssuedAt?: string;
  tokenAge_ms?: number;
  expiresAt?: string;
  retryAt?: string;
  currentKeyVersion?: string;
  previousKeyVersion?: string;
};

export type StepUpAuditRecord = StepUpAuditEvent & {
  timestamp: string;
  source: "step-up-auth";
  event: StepUpAuditEventType;
};

type FirestoreDbLike = {
  collection: (collectionId: string) => {
    add: (data: StepUpAuditRecord) => Promise<unknown>;
  };
};

type StepUpAuditOptions = {
  db?: FirestoreDbLike;
  now?: () => Date;
  logger?: (message: string) => void;
  errorLogger?: (message: string, error?: unknown) => void;
  writeToFirestore?: boolean;
};

const STEP_UP_AUDIT_COLLECTION = "admin_step_up_audit_events";

export async function emitStepUpAuditEvent(
  event: StepUpAuditEvent,
  options: StepUpAuditOptions = {},
): Promise<StepUpAuditRecord> {
  const now = options.now ?? (() => new Date());
  const logger = options.logger ?? ((message: string) => console.info(message));
  const errorLogger =
    options.errorLogger ??
    ((message: string, error?: unknown) => console.warn(message, error));

  const record = normalizeAuditRecord(event, now());
  logger(`[SECURITY_AUDIT] ${JSON.stringify(record)}`);

  if (options.writeToFirestore === false) {
    return record;
  }

  try {
    const db = options.db ?? (await getDefaultAdminDb());
    await db.collection(STEP_UP_AUDIT_COLLECTION).add(record);
  } catch (error) {
    errorLogger("[STEP_UP_AUDIT] Failed to write audit event.", error);
  }

  return record;
}

export function resolveStepUpKeyVersionLabels(
  env: Record<string, string | undefined> = process.env,
): {
  currentKeyVersion: string;
  previousKeyVersion: string;
} {
  return {
    currentKeyVersion:
      extractSecretVersionLabel(
        env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION ??
          env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_RESOURCE,
      ) ?? "latest",
    previousKeyVersion:
      extractSecretVersionLabel(
        env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION ??
          env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE,
      ) ?? "previous",
  };
}

function normalizeAuditRecord(
  event: StepUpAuditEvent,
  now: Date,
): StepUpAuditRecord {
  const timestamp = now.toISOString();
  const userId = toNonEmptyString(event.userId);
  const sessionRole = toNonEmptyString(event.sessionRole);
  const command = toNonEmptyString(event.command);
  const correlationId = toNonEmptyString(event.correlationId);
  const reason = toNonEmptyString(event.reason);
  const tokenJti = toNonEmptyString(event.tokenJti);
  const tokenIssuedAt = toNonEmptyString(event.tokenIssuedAt);
  const expiresAt = toNonEmptyString(event.expiresAt);
  const retryAt = toNonEmptyString(event.retryAt);
  const currentKeyVersion = toNonEmptyString(event.currentKeyVersion);
  const previousKeyVersion = toNonEmptyString(event.previousKeyVersion);

  return {
    timestamp,
    source: "step-up-auth",
    event: event.eventType,
    eventType: event.eventType,
    ...(userId ? { userId } : {}),
    ...(sessionRole ? { sessionRole } : {}),
    ...(command ? { command } : {}),
    ...(correlationId ? { correlationId } : {}),
    ...(event.scope ? { scope: event.scope } : {}),
    ...(reason ? { reason } : {}),
    ...(event.enforcementMode ? { enforcementMode: event.enforcementMode } : {}),
    ...(isFiniteNumber(event.status) ? { status: event.status } : {}),
    ...(tokenJti ? { tokenJti } : {}),
    ...(tokenIssuedAt ? { tokenIssuedAt } : {}),
    ...(isFiniteNumber(event.tokenAge_ms)
      ? { tokenAge_ms: Math.max(0, Math.floor(event.tokenAge_ms)) }
      : {}),
    ...(expiresAt ? { expiresAt } : {}),
    ...(retryAt ? { retryAt } : {}),
    ...(currentKeyVersion ? { currentKeyVersion } : {}),
    ...(previousKeyVersion ? { previousKeyVersion } : {}),
  };
}

async function getDefaultAdminDb(): Promise<FirestoreDbLike> {
  const { adminDb } = await import("@/lib/firebase/server");
  return adminDb as FirestoreDbLike;
}

function extractSecretVersionLabel(value: unknown): string | undefined {
  const raw = toNonEmptyString(value);
  if (!raw) {
    return undefined;
  }

  const match = raw.match(/\/versions\/([^/]+)$/);
  return match?.[1] ?? raw;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}
