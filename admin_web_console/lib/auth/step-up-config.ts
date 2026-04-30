import "server-only";

export type StepUpEnforcementMode = "enabled" | "log_only" | "disabled";

const CONFIG_COLLECTION = "app_config";
const CONFIG_DOCUMENT_ID = "admin_step_up";
const DEFAULT_ENFORCEMENT_MODE: StepUpEnforcementMode = "enabled";
const DEFAULT_CACHE_TTL_MS = 60_000;

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

type StepUpConfigOptions = {
  db?: FirestoreDbLike;
  nowMs?: number;
  cacheTtlMs?: number;
  useCache?: boolean;
  onReadError?: (error: unknown) => void;
};

type CachedMode = {
  mode: StepUpEnforcementMode;
  expiresAtMs: number;
};

let cachedMode: CachedMode | null = null;

export async function getStepUpEnforcementMode(
  options: StepUpConfigOptions = {},
): Promise<StepUpEnforcementMode> {
  const nowMs = options.nowMs ?? Date.now();
  const cacheTtlMs = options.cacheTtlMs ?? DEFAULT_CACHE_TTL_MS;
  const useCache = options.useCache !== false;

  if (useCache && cachedMode && cachedMode.expiresAtMs > nowMs) {
    return cachedMode.mode;
  }

  try {
    const db = options.db ?? (await getDefaultAdminDb());
    const snapshot = await db
      .collection(CONFIG_COLLECTION)
      .doc(CONFIG_DOCUMENT_ID)
      .get();
    const mode = normalizeStepUpEnforcementMode(
      snapshot.exists === false ? undefined : asRecord(snapshot.data())?.enforcementMode,
    );

    return cacheAndReturn(mode, nowMs, cacheTtlMs, useCache);
  } catch (error) {
    options.onReadError?.(error);
    console.error(
      "[STEP_UP_CONFIG] Failed to read enforcement mode; defaulting to enabled.",
      error,
    );
    return cacheAndReturn(DEFAULT_ENFORCEMENT_MODE, nowMs, cacheTtlMs, useCache);
  }
}

export function normalizeStepUpEnforcementMode(
  value: unknown,
): StepUpEnforcementMode {
  return value === "disabled" || value === "log_only" || value === "enabled"
    ? value
    : DEFAULT_ENFORCEMENT_MODE;
}

export function clearStepUpEnforcementModeCacheForTests(): void {
  cachedMode = null;
}

function cacheAndReturn(
  mode: StepUpEnforcementMode,
  nowMs: number,
  cacheTtlMs: number,
  useCache: boolean,
): StepUpEnforcementMode {
  if (useCache) {
    cachedMode = {
      mode,
      expiresAtMs: nowMs + cacheTtlMs,
    };
  }
  return mode;
}

async function getDefaultAdminDb(): Promise<FirestoreDbLike> {
  const { adminDb } = await import("@/lib/firebase/server");
  return adminDb as FirestoreDbLike;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object"
    ? (value as Record<string, unknown>)
    : undefined;
}
