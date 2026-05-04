import "server-only";

import { Timestamp } from "firebase-admin/firestore";

import { adminDb } from "@/lib/firebase/server";

const STEP_UP_RATE_LIMIT_COLLECTION = "step_up_attempts";
const STEP_UP_RATE_LIMIT_MAX_ATTEMPTS = 3;
const STEP_UP_RATE_LIMIT_WINDOW_MS = 5 * 60 * 1000;

type StepUpIssueRateLimitDoc = {
  failureCount?: unknown;
  windowStartedAtMs?: unknown;
  lockoutUntilMs?: unknown;
};

export class StepUpIssueRateLimitError extends Error {
  readonly retryAtMs: number;

  constructor(retryAtMs: number) {
    super("Too many step-up attempts. Try again later.");
    this.name = "StepUpIssueRateLimitError";
    this.retryAtMs = retryAtMs;
  }
}

export async function assertStepUpIssueNotRateLimited(
  uid: string,
  nowMs: number = Date.now(),
): Promise<void> {
  const attemptsRef = adminDb.collection(STEP_UP_RATE_LIMIT_COLLECTION).doc(uid);
  const snapshot = await attemptsRef.get();
  if (!snapshot.exists) {
    return;
  }

  const data = (snapshot.data() ?? {}) as StepUpIssueRateLimitDoc;
  const lockoutUntilMs = toMillis(data.lockoutUntilMs);
  if (typeof lockoutUntilMs === "number" && lockoutUntilMs > nowMs) {
    throw new StepUpIssueRateLimitError(lockoutUntilMs);
  }

  const windowStartedAtMs = toMillis(data.windowStartedAtMs);
  if (
    typeof windowStartedAtMs === "number" &&
    nowMs - windowStartedAtMs > STEP_UP_RATE_LIMIT_WINDOW_MS
  ) {
    await attemptsRef.delete();
  }
}

export async function recordStepUpIssueFailure(
  uid: string,
  nowMs: number = Date.now(),
): Promise<{ locked: boolean; retryAtMs?: number }> {
  const attemptsRef = adminDb.collection(STEP_UP_RATE_LIMIT_COLLECTION).doc(uid);

  return adminDb.runTransaction(async (tx) => {
    const snapshot = await tx.get(attemptsRef);
    const data = (snapshot.data() ?? {}) as StepUpIssueRateLimitDoc;

    const activeLockoutUntilMs = toMillis(data.lockoutUntilMs);
    if (typeof activeLockoutUntilMs === "number" && activeLockoutUntilMs > nowMs) {
      tx.set(
        attemptsRef,
        {
          ...data,
          expiresAt: Timestamp.fromMillis(activeLockoutUntilMs),
        },
        { merge: true },
      );
      return { locked: true, retryAtMs: activeLockoutUntilMs };
    }

    const existingWindowStartedAtMs = toMillis(data.windowStartedAtMs);
    const existingFailureCount = toNonNegativeInteger(data.failureCount) ?? 0;

    const withinActiveWindow =
      typeof existingWindowStartedAtMs === "number" &&
      nowMs - existingWindowStartedAtMs <= STEP_UP_RATE_LIMIT_WINDOW_MS;

    const windowStartedAtMs = withinActiveWindow ? existingWindowStartedAtMs : nowMs;
    const failureCount = withinActiveWindow ? existingFailureCount + 1 : 1;
    const lockoutUntilMs =
      failureCount >= STEP_UP_RATE_LIMIT_MAX_ATTEMPTS
        ? nowMs + STEP_UP_RATE_LIMIT_WINDOW_MS
        : undefined;
    const expiresAtMs = lockoutUntilMs ?? windowStartedAtMs + STEP_UP_RATE_LIMIT_WINDOW_MS;

    tx.set(
      attemptsRef,
      {
        failureCount,
        windowStartedAtMs,
        lastFailedAtMs: nowMs,
        ...(lockoutUntilMs ? { lockoutUntilMs } : {}),
        expiresAt: Timestamp.fromMillis(expiresAtMs),
      },
      { merge: false },
    );

    return lockoutUntilMs
      ? { locked: true, retryAtMs: lockoutUntilMs }
      : { locked: false };
  });
}

export async function clearStepUpIssueFailures(uid: string): Promise<void> {
  const attemptsRef = adminDb.collection(STEP_UP_RATE_LIMIT_COLLECTION).doc(uid);
  await attemptsRef.delete();
}

function toNonNegativeInteger(value: unknown): number | undefined {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return undefined;
  }
  return Math.floor(parsed);
}

function toMillis(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.floor(value);
  }

  if (
    value &&
    typeof value === "object" &&
    "toMillis" in value &&
    typeof (value as { toMillis: unknown }).toMillis === "function"
  ) {
    return (value as { toMillis: () => number }).toMillis();
  }

  return undefined;
}
