import {
  createFinanceReadEmpty,
  createFinanceReadSuccess,
  resolveReadFreshness,
  toReadSuccessState,
  type FinanceReadTransport,
} from "./finance-read-transport";
import {
  FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
  resolveFixtureFallbackPolicy,
} from "@/lib/admin/fixture-fallback-policy";
import type {
  FinanceReadFailure,
  FinanceReadSource,
  TopUpQueueReadQuery,
  TopUpQueueReadResult,
  TopUpRequest,
  WalletAuditReadQuery,
  WalletAuditReadResult,
  WalletLedgerEntry,
  WalletReadinessReadQuery,
  WalletReadinessReadResult,
  WalletReadinessReport,
} from "./read-models";
import {
  MOCK_READINESS_REPORT,
  MOCK_TOPUP_REQUESTS,
  MOCK_WALLET_LEDGER_ENTRIES,
} from "./read-models";

const FIXTURE_CHANNEL = "development_fixture";
const DEFAULT_SHARED_SNAPSHOT_CACHE_TTL_MS = 30_000;
const DEFAULT_LEDGER_READ_LIMIT = 60;
const DEFAULT_LEDGER_UNORDERED_OVERSCAN_FACTOR = 4;
const DEFAULT_LEDGER_ORDERED_QUERY_RETRY_COOLDOWN_MS = 60_000;
const DEFAULT_VENUE_NAME_CACHE_TTL_MS = 30_000;

type SnapshotTransportOptions = {
  env: Record<string, string | undefined>;
  now: () => Date;
  fetchImpl: typeof fetch;
};

type UnifiedSnapshot = {
  asOf: string;
  topups: TopUpRequest[];
  ledger: WalletLedgerEntry[];
  readiness: WalletReadinessReport;
};

type TopupsSnapshot = {
  asOf: string;
  topups: TopUpRequest[];
};

type ReadinessSnapshot = {
  asOf: string;
  readiness: WalletReadinessReport;
};

type LedgerSnapshot = {
  asOf: string;
  ledger: WalletLedgerEntry[];
};

type SnapshotLoadResult =
  | { ok: true; snapshot: UnifiedSnapshot; channel: string }
  | { ok: false; message: string; channel: string };

type TopupsLoadResult =
  | { ok: true; snapshot: TopupsSnapshot; channel: string }
  | { ok: false; message: string; channel: string };

type ReadinessLoadResult =
  | { ok: true; snapshot: ReadinessSnapshot; channel: string }
  | { ok: false; message: string; channel: string };

type LedgerLoadResult =
  | { ok: true; snapshot: LedgerSnapshot; channel: string }
  | { ok: false; message: string; channel: string };

type LedgerFallbackOptions = {
  env: Record<string, string | undefined>;
  getHintVenueIds?: () => Promise<string[]>;
};

type SharedSnapshotCacheEntry<TResult> = {
  key: string;
  expiresAt: number;
  promise: Promise<TResult>;
};

type VenueNameCacheEntry = {
  name: string;
  expiresAt: number;
};

const g = globalThis as any;
g.sharedVenueNameCache ??= new Map<string, VenueNameCacheEntry>();
const sharedVenueNameCache: Map<string, VenueNameCacheEntry> = g.sharedVenueNameCache;

function getSharedUnifiedOverrideSnapshotCache(): SharedSnapshotCacheEntry<SnapshotLoadResult | null> | null { return g.sharedUnifiedOverrideSnapshotCache ?? null; }
function setSharedUnifiedOverrideSnapshotCache(val: SharedSnapshotCacheEntry<SnapshotLoadResult | null> | null) { g.sharedUnifiedOverrideSnapshotCache = val; }

function getSharedTopupsSnapshotCache(): SharedSnapshotCacheEntry<TopupsLoadResult> | null { return g.sharedTopupsSnapshotCache ?? null; }
function setSharedTopupsSnapshotCache(val: SharedSnapshotCacheEntry<TopupsLoadResult> | null) { g.sharedTopupsSnapshotCache = val; }

function getSharedReadinessSnapshotCache(): SharedSnapshotCacheEntry<ReadinessLoadResult> | null { return g.sharedReadinessSnapshotCache ?? null; }
function setSharedReadinessSnapshotCache(val: SharedSnapshotCacheEntry<ReadinessLoadResult> | null) { g.sharedReadinessSnapshotCache = val; }

function getSharedLedgerSnapshotCache(): SharedSnapshotCacheEntry<LedgerLoadResult> | null { return g.sharedLedgerSnapshotCache ?? null; }
function setSharedLedgerSnapshotCache(val: SharedSnapshotCacheEntry<LedgerLoadResult> | null) { g.sharedLedgerSnapshotCache = val; }

function getOrderedLedgerQueryRetryAfterMs(): number { return g.orderedLedgerQueryRetryAfterMs ?? 0; }
function setOrderedLedgerQueryRetryAfterMs(val: number) { g.orderedLedgerQueryRetryAfterMs = val; }

export function createFinanceReadSnapshotTransport(
  options: SnapshotTransportOptions,
): FinanceReadTransport {
  let topupsCache: Promise<TopupsLoadResult> | null = null;
  let readinessCache: Promise<ReadinessLoadResult> | null = null;
  let ledgerCache: Promise<LedgerLoadResult> | null = null;

  const loadTopups = () => {
    topupsCache ??= loadTopupsWithSharedCache(options);
    return topupsCache;
  };

  const loadReadiness = () => {
    readinessCache ??= loadReadinessWithSharedCache(options);
    return readinessCache;
  };

  const loadLedger = () => {
    ledgerCache ??= loadLedgerSnapshotWithSharedCache(options);
    return ledgerCache;
  };

  return {
    async readTopUpQueue(query?: TopUpQueueReadQuery): Promise<TopUpQueueReadResult> {
      const loaded = await loadTopups();
      if (!loaded.ok) {
        return snapshotLoadFailure("topup_queue", loaded);
      }

      const staleAfterMs = query?.maxAgeMs;
      const freshness = resolveReadFreshness({
        source: "topup_queue",
        checkedAt: loaded.snapshot.asOf,
        fetchedAt: options.now(),
        staleAfterMs,
        channel: loaded.channel,
      });

      if (loaded.snapshot.topups.length === 0) {
        return createFinanceReadEmpty({ freshness });
      }

      return createFinanceReadSuccess({
        data: loaded.snapshot.topups,
        freshness,
      });
    },

    async readWalletAudit(query?: WalletAuditReadQuery): Promise<WalletAuditReadResult> {
      const loaded = await loadLedger();
      if (!loaded.ok) {
        return snapshotLoadFailure("wallet_audit", loaded);
      }

      const staleAfterMs = query?.maxAgeMs;
      const freshness = resolveReadFreshness({
        source: "wallet_audit",
        checkedAt: loaded.snapshot.asOf,
        fetchedAt: options.now(),
        staleAfterMs,
        channel: loaded.channel,
      });

      if (loaded.snapshot.ledger.length === 0) {
        return createFinanceReadEmpty({ freshness });
      }

      return createFinanceReadSuccess({
        data: loaded.snapshot.ledger,
        freshness,
      });
    },

    async readWalletReadiness(
      query?: WalletReadinessReadQuery,
    ): Promise<WalletReadinessReadResult> {
      const loaded = await loadReadiness();
      if (!loaded.ok) {
        return snapshotLoadFailure("wallet_readiness", loaded);
      }

      const staleAfterMs = query?.maxAgeMs;
      const freshness = resolveReadFreshness({
        source: "wallet_readiness",
        checkedAt: loaded.snapshot.readiness.generatedAt,
        fetchedAt: options.now(),
        staleAfterMs,
        channel: loaded.channel,
      });

      const report = loaded.snapshot.readiness;
      const successState = toReadSuccessState(freshness);
      return {
        ok: true,
        state: successState,
        data: report,
        freshness,
      };
    },
  };
}

function loadTopupsWithSharedCache(
  options: SnapshotTransportOptions,
): Promise<TopupsLoadResult> {
  return loadSnapshotWithSharedCache({
    env: options.env,
    getKey: () => buildTopupsSharedSnapshotCacheKey(options.env),
    getSharedCache: () => getSharedTopupsSnapshotCache(),
    setSharedCache: (entry) => {
      setSharedTopupsSnapshotCache(entry);
    },
    load: () => loadTopupsSnapshot(options),
  });
}

function loadReadinessWithSharedCache(
  options: SnapshotTransportOptions,
): Promise<ReadinessLoadResult> {
  return loadSnapshotWithSharedCache({
    env: options.env,
    getKey: () => buildReadinessSharedSnapshotCacheKey(options.env),
    getSharedCache: () => getSharedReadinessSnapshotCache(),
    setSharedCache: (entry) => {
      setSharedReadinessSnapshotCache(entry);
    },
    load: () => loadReadinessSnapshot(options),
  });
}

function loadLedgerSnapshotWithSharedCache(
  options: SnapshotTransportOptions,
): Promise<LedgerLoadResult> {
  return loadSnapshotWithSharedCache({
    env: options.env,
    getKey: () => buildLedgerSharedSnapshotCacheKey(options.env),
    getSharedCache: () => getSharedLedgerSnapshotCache(),
    setSharedCache: (entry) => {
      setSharedLedgerSnapshotCache(entry);
    },
    load: () => loadLedgerSnapshot(options),
  });
}

function loadSnapshotWithSharedCache<TResult>(args: {
  env: Record<string, string | undefined>;
  getKey: () => string;
  getSharedCache: () => SharedSnapshotCacheEntry<TResult> | null;
  setSharedCache: (entry: SharedSnapshotCacheEntry<TResult> | null) => void;
  load: () => Promise<TResult>;
}): Promise<TResult> {
  if (!shouldUseSharedSnapshotCache(args.env)) {
    return args.load();
  }

  const ttlMs = resolveSharedSnapshotCacheTtlMs(args.env);
  if (ttlMs <= 0) {
    return args.load();
  }

  const nowMs = Date.now();
  const key = args.getKey();
  const sharedCache = args.getSharedCache();
  if (sharedCache && sharedCache.key === key && sharedCache.expiresAt > nowMs) {
    return sharedCache.promise;
  }

  const promise = args
    .load()
    .then((result) => {
      if (isLoadFailureResult(result)) {
        args.setSharedCache(null);
      }
      return result;
    })
    .catch((error) => {
      args.setSharedCache(null);
      throw error;
    });

  args.setSharedCache({
    key,
    expiresAt: nowMs + ttlMs,
    promise,
  });

  return promise;
}

function isLoadFailureResult(value: unknown): value is { ok: false } {
  return (
    Boolean(value) &&
    typeof value === "object" &&
    "ok" in (value as Record<string, unknown>) &&
    (value as { ok?: unknown }).ok === false
  );
}

function shouldUseSharedSnapshotCache(
  env: Record<string, string | undefined>,
): boolean {
  if (env.WAIN_FINANCE_SHARED_SNAPSHOT_CACHE === "0") {
    return false;
  }

  const runtimeEnv = (env.NODE_ENV ?? process.env.NODE_ENV ?? "").trim().toLowerCase();
  if (runtimeEnv === "test") {
    return false;
  }

  const vitestFlag = (env.VITEST ?? process.env.VITEST ?? "").trim().toLowerCase();
  return vitestFlag !== "true";
}

function resolveSharedSnapshotCacheTtlMs(
  env: Record<string, string | undefined>,
): number {
  const explicit = parsePositiveInt(env.WAIN_FINANCE_SHARED_SNAPSHOT_CACHE_TTL_MS);
  return explicit ?? DEFAULT_SHARED_SNAPSHOT_CACHE_TTL_MS;
}

function shouldUseVenueNameCache(
  env: Record<string, string | undefined>,
): boolean {
  if (env.WAIN_FINANCE_VENUE_NAME_CACHE === "0") {
    return false;
  }

  const runtimeEnv = (env.NODE_ENV ?? process.env.NODE_ENV ?? "").trim().toLowerCase();
  if (runtimeEnv === "test") {
    return false;
  }

  const vitestFlag = (env.VITEST ?? process.env.VITEST ?? "").trim().toLowerCase();
  return vitestFlag !== "true";
}

function resolveVenueNameCacheTtlMs(
  env: Record<string, string | undefined>,
): number {
  const explicit = parsePositiveInt(env.WAIN_FINANCE_VENUE_NAME_CACHE_TTL_MS);
  return explicit ?? DEFAULT_VENUE_NAME_CACHE_TTL_MS;
}

function clearExpiredVenueNameCacheEntries(nowMs: number): void {
  for (const [venueId, entry] of sharedVenueNameCache.entries()) {
    if (entry.expiresAt <= nowMs) {
      sharedVenueNameCache.delete(venueId);
    }
  }
}

function buildTopupsSharedSnapshotCacheKey(
  env: Record<string, string | undefined>,
): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  return [
    fallbackPolicy.cacheKey,
    env.WAIN_FINANCE_READ_FORCE_UNAVAILABLE ?? "",
    env.WAIN_FINANCE_READ_INLINE_JSON ?? "",
    env.WAIN_FINANCE_READ_HTTP_URL ?? "",
    env.WAIN_FINANCE_READ_FIXTURE_AS_OF ?? "",
    env.WAIN_FINANCE_TOPUP_READ_LIMIT ?? "",
    env.WAIN_FINANCE_READ_STALE_AFTER_MS ?? "",
    env.WAIN_FINANCE_TOPUP_READ_STALE_AFTER_MS ?? "",
  ].join("|");
}

function buildReadinessSharedSnapshotCacheKey(
  env: Record<string, string | undefined>,
): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  return [
    fallbackPolicy.cacheKey,
    env.WAIN_FINANCE_READ_FORCE_UNAVAILABLE ?? "",
    env.WAIN_FINANCE_READ_INLINE_JSON ?? "",
    env.WAIN_FINANCE_READ_HTTP_URL ?? "",
    env.WAIN_FINANCE_READ_FIXTURE_AS_OF ?? "",
    env.WAIN_FINANCE_READINESS_REPORTS_LIMIT ?? "",
    env.WAIN_FINANCE_READ_STALE_AFTER_MS ?? "",
    env.WAIN_FINANCE_READINESS_READ_STALE_AFTER_MS ?? "",
  ].join("|");
}

function buildLedgerSharedSnapshotCacheKey(
  env: Record<string, string | undefined>,
): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  return [
    fallbackPolicy.cacheKey,
    env.WAIN_FINANCE_READ_FORCE_UNAVAILABLE ?? "",
    env.WAIN_FINANCE_READ_INLINE_JSON ?? "",
    env.WAIN_FINANCE_READ_HTTP_URL ?? "",
    env.WAIN_FINANCE_READ_FIXTURE_AS_OF ?? "",
    env.WAIN_FINANCE_TOPUP_READ_LIMIT ?? "",
    env.WAIN_FINANCE_LEDGER_READ_LIMIT ?? "",
    env.WAIN_FINANCE_LEDGER_UNORDERED_OVERSCAN_FACTOR ?? "",
    env.WAIN_FINANCE_LEDGER_ORDERED_QUERY_RETRY_COOLDOWN_MS ?? "",
    env.WAIN_FINANCE_LEDGER_FALLBACK_WALLETS_SCAN_LIMIT ?? "",
    env.WAIN_FINANCE_LEDGER_FALLBACK_PRIORITY_WALLETS_LIMIT ?? "",
    env.WAIN_FINANCE_LEDGER_FALLBACK_BROAD_WALLETS_LIMIT ?? "",
    env.WAIN_FINANCE_READ_STALE_AFTER_MS ?? "",
    env.WAIN_FINANCE_LEDGER_READ_STALE_AFTER_MS ?? "",
  ].join("|");
}

function buildUnifiedOverrideSnapshotCacheKey(
  env: Record<string, string | undefined>,
): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  return [
    fallbackPolicy.cacheKey,
    env.WAIN_FINANCE_READ_FORCE_UNAVAILABLE ?? "",
    env.WAIN_FINANCE_READ_INLINE_JSON ?? "",
    env.WAIN_FINANCE_READ_HTTP_URL ?? "",
    env.WAIN_FINANCE_READ_FIXTURE_AS_OF ?? "",
  ].join("|");
}

async function loadTopupsSnapshot(
  options: SnapshotTransportOptions,
): Promise<TopupsLoadResult> {
  const overrideResult = await loadUnifiedOverrideSnapshotWithSharedCache(options);
  if (overrideResult) {
    return toTopupsLoadResultFromUnified(overrideResult);
  }

  const firestoreResult = await loadTopupsSnapshotFromFirestore(options);
  if (firestoreResult) {
    return firestoreResult;
  }

  const fixtureAsOf =
    options.env.WAIN_FINANCE_READ_FIXTURE_AS_OF?.trim() ||
    options.now().toISOString();

  const fallbackPolicy = resolveFixtureFallbackPolicy(options.env);
  if (!fallbackPolicy.allowed) {
    return {
      ok: false,
      message: FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
      channel: "fixture_fallback_disabled",
    };
  }

  return {
    ok: true,
    snapshot: {
      asOf: fixtureAsOf,
      topups: MOCK_TOPUP_REQUESTS,
    },
    channel: FIXTURE_CHANNEL,
  };
}

async function loadReadinessSnapshot(
  options: SnapshotTransportOptions,
): Promise<ReadinessLoadResult> {
  const overrideResult = await loadUnifiedOverrideSnapshotWithSharedCache(options);
  if (overrideResult) {
    return toReadinessLoadResultFromUnified(overrideResult);
  }

  const firestoreResult = await loadReadinessSnapshotFromFirestore(options);
  if (firestoreResult) {
    return firestoreResult;
  }

  const fixtureAsOf =
    options.env.WAIN_FINANCE_READ_FIXTURE_AS_OF?.trim() ||
    options.now().toISOString();

  const fallbackPolicy = resolveFixtureFallbackPolicy(options.env);
  if (!fallbackPolicy.allowed) {
    return {
      ok: false,
      message: FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
      channel: "fixture_fallback_disabled",
    };
  }

  return {
    ok: true,
    snapshot: {
      asOf: fixtureAsOf,
      readiness: MOCK_READINESS_REPORT,
    },
    channel: FIXTURE_CHANNEL,
  };
}

async function loadLedgerSnapshot(
  options: SnapshotTransportOptions,
): Promise<LedgerLoadResult> {
  const overrideResult = await loadUnifiedOverrideSnapshotWithSharedCache(options);
  if (overrideResult) {
    return toLedgerLoadResultFromUnified(overrideResult);
  }

  const firestoreResult = await loadLedgerSnapshotFromFirestore(options);
  if (firestoreResult) {
    return firestoreResult;
  }

  const fixtureAsOf =
    options.env.WAIN_FINANCE_READ_FIXTURE_AS_OF?.trim() ||
    options.now().toISOString();

  const fallbackPolicy = resolveFixtureFallbackPolicy(options.env);
  if (!fallbackPolicy.allowed) {
    return {
      ok: false,
      message: FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
      channel: "fixture_fallback_disabled",
    };
  }

  return {
    ok: true,
    snapshot: {
      asOf: fixtureAsOf,
      ledger: MOCK_WALLET_LEDGER_ENTRIES,
    },
    channel: FIXTURE_CHANNEL,
  };
}

function toTopupsLoadResultFromUnified(
  unifiedResult: SnapshotLoadResult,
): TopupsLoadResult {
  if (!unifiedResult.ok) {
    return unifiedResult;
  }

  return {
    ok: true,
    channel: unifiedResult.channel,
    snapshot: {
      asOf: unifiedResult.snapshot.asOf,
      topups: unifiedResult.snapshot.topups,
    },
  };
}

function toReadinessLoadResultFromUnified(
  unifiedResult: SnapshotLoadResult,
): ReadinessLoadResult {
  if (!unifiedResult.ok) {
    return unifiedResult;
  }

  return {
    ok: true,
    channel: unifiedResult.channel,
    snapshot: {
      asOf: unifiedResult.snapshot.asOf,
      readiness: unifiedResult.snapshot.readiness,
    },
  };
}

function toLedgerLoadResultFromUnified(
  unifiedResult: SnapshotLoadResult,
): LedgerLoadResult {
  if (!unifiedResult.ok) {
    return unifiedResult;
  }

  return {
    ok: true,
    channel: unifiedResult.channel,
    snapshot: {
      asOf: unifiedResult.snapshot.asOf,
      ledger: unifiedResult.snapshot.ledger,
    },
  };
}

function loadUnifiedOverrideSnapshotWithSharedCache(
  options: SnapshotTransportOptions,
): Promise<SnapshotLoadResult | null> {
  return loadSnapshotWithSharedCache({
    env: options.env,
    getKey: () => buildUnifiedOverrideSnapshotCacheKey(options.env),
    getSharedCache: () => getSharedUnifiedOverrideSnapshotCache(),
    setSharedCache: (entry) => {
      setSharedUnifiedOverrideSnapshotCache(entry);
    },
    load: () => loadUnifiedOverrideSnapshot(options),
  });
}

async function loadUnifiedOverrideSnapshot(
  options: SnapshotTransportOptions,
): Promise<SnapshotLoadResult | null> {
  const { env, fetchImpl } = options;

  if (env.WAIN_FINANCE_READ_FORCE_UNAVAILABLE === "1") {
    return {
      ok: false,
      message: "Finance read was forced unavailable (WAIN_FINANCE_READ_FORCE_UNAVAILABLE).",
      channel: "force_unavailable",
    };
  }

  const inline = env.WAIN_FINANCE_READ_INLINE_JSON?.trim();
  if (inline) {
    const parsed = parseSnapshotJson(inline);
    if (!parsed) {
      return {
        ok: false,
        message: "WAIN_FINANCE_READ_INLINE_JSON is not valid JSON object.",
        channel: "inline_json",
      };
    }
    const built = buildSnapshotFromRecord(parsed);
    if (!built.ok) {
      return { ok: false, message: built.message, channel: "inline_json" };
    }
    return { ok: true, snapshot: built.snapshot, channel: "inline_json" };
  }

  const url = env.WAIN_FINANCE_READ_HTTP_URL?.trim();
  if (url) {
    try {
      const response = await fetchImpl(url, { cache: "no-store" });
      if (!response.ok) {
        return {
          ok: false,
          message: `Finance read HTTP ${response.status} ${response.statusText}`,
          channel: `http:${url}`,
        };
      }
      const text = await response.text();
      const parsed = parseSnapshotJson(text);
      if (!parsed) {
        return {
          ok: false,
          message: "Finance read HTTP response was not a JSON object.",
          channel: `http:${url}`,
        };
      }
      const built = buildSnapshotFromRecord(parsed);
      if (!built.ok) {
        return { ok: false, message: built.message, channel: `http:${url}` };
      }
      return { ok: true, snapshot: built.snapshot, channel: `http:${url}` };
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      return {
        ok: false,
        message: `Finance read fetch failed: ${detail}`,
        channel: `http:${url}`,
      };
    }
  }

  return null;
}

export function createLayeredFinanceReadTransport(options: {
  snapshot: FinanceReadTransport;
  callable: FinanceReadTransport;
}): FinanceReadTransport {
  return {
    readTopUpQueue: async (query) => {
      const primary = await options.callable.readTopUpQueue(query);
      if (primary.ok) {
        return primary;
      }
      if (primary.state === "unauthorized" || primary.state === "forbidden") {
        return primary;
      }
      return options.snapshot.readTopUpQueue(query);
    },
    readWalletAudit: async (query) => {
      const primary = await options.callable.readWalletAudit(query);
      if (primary.ok) {
        return primary;
      }
      if (primary.state === "unauthorized" || primary.state === "forbidden") {
        return primary;
      }
      return options.snapshot.readWalletAudit(query);
    },
    readWalletReadiness: async (query) => {
      const primary = await options.callable.readWalletReadiness(query);
      if (primary.ok) {
        return primary;
      }
      if (primary.state === "unauthorized" || primary.state === "forbidden") {
        return primary;
      }
      return options.snapshot.readWalletReadiness(query);
    },
  };
}

function snapshotLoadFailure(
  source: FinanceReadSource,
  loaded: { ok: false; message: string; channel: string },
): FinanceReadFailure {
  return {
    ok: false,
    source,
    state: "unavailable",
    message: loaded.message,
    retryable: true,
    details: { channel: loaded.channel },
  };
}

async function loadTopupsSnapshotFromFirestore(
  options: SnapshotTransportOptions,
): Promise<TopupsLoadResult | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const _t0 = performance.now();
    const { adminDb } = await import("@/lib/firebase/server");
    console.log(
      `[PERF] finance:importAdminDb (topups): ${(performance.now() - _t0).toFixed(0)}ms`,
    );
    const asOf = options.now().toISOString();

    const topupsLimit = parsePositiveInt(options.env.WAIN_FINANCE_TOPUP_READ_LIMIT) ?? 80;

    const _tQ = performance.now();
    const topupsSnap = await loadTopupRequestsSnapshot(adminDb, topupsLimit);
    console.log(
      `[PERF] finance:firestoreQueries (topups): ${(performance.now() - _tQ).toFixed(0)}ms`,
    );

    const topupDocs = [...topupsSnap.docs]
      .sort((left, right) => {
        const leftIso = toFirestoreIso(left.data()?.created_at);
        const rightIso = toFirestoreIso(right.data()?.created_at);
        const leftMs = leftIso ? Date.parse(leftIso) : 0;
        const rightMs = rightIso ? Date.parse(rightIso) : 0;
        return rightMs - leftMs;
      })
      .slice(0, topupsLimit);

    const venueIds = new Set<string>();
    for (const doc of topupDocs) {
      const venueId = toNonEmptyString(doc.data()?.venue_id);
      if (venueId) {
        venueIds.add(venueId);
      }
    }
    const venueNameMap = await loadVenueNameMap(adminDb, venueIds, options.env);

    const topups: TopUpRequest[] = topupDocs.map((doc) => {
      const row = doc.data() ?? {};
      const venueId = toNonEmptyString(row.venue_id) ?? undefined;
      const userId = toNonEmptyString(row.requested_by_uid) ?? venueId ?? "unknown";
      const amount = typeof row.amount === "number" && Number.isFinite(row.amount)
        ? row.amount
        : 0;
      const currency = row.currency === "USD" ? "USD" : "ILS";
      const status =
        row.status === "credited" || row.status === "rejected"
          ? row.status
          : "pending";

      const reviewedBy = toNonEmptyString(row.reviewed_by_uid) ?? undefined;
      const reviewedAt = toFirestoreIso(row.reviewed_at) ?? undefined;
      const proofImageUrl =
        toNonEmptyString(row.proof_image_url ?? row.proofImageUrl) ?? undefined;
      const proofRetentionUntil =
        toFirestoreIso(row.proof_retention_until ?? row.proofRetentionUntil) ??
        undefined;
      const proofStorageDeleted =
        row.proof_storage_deleted === true || row.proofStorageDeleted === true;

      return {
        id: doc.id,
        ...(venueId ? { venueId } : {}),
        userId,
        userName: venueId ? venueNameMap.get(venueId) ?? userId : userId,
        amount,
        currency,
        providerReference: toNonEmptyString(row.transfer_reference) ?? "",
        createdAt: toFirestoreIso(row.created_at) ?? asOf,
        status,
        ...(proofImageUrl ? { proofImageUrl } : {}),
        ...(proofRetentionUntil ? { proofRetentionUntil } : {}),
        ...(proofStorageDeleted ? { proofStorageDeleted } : {}),
        ...(reviewedBy ? { reviewedBy } : {}),
        ...(reviewedAt ? { reviewedAt } : {}),
      };
    });

    return {
      ok: true,
      snapshot: {
        asOf,
        topups,
      },
      channel: "firestore:admin_finance",
    };
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    return {
      ok: false,
      message: `Finance firestore fallback failed: ${detail}`,
      channel: "firestore:admin_finance",
    };
  }
}

async function loadReadinessSnapshotFromFirestore(
  options: SnapshotTransportOptions,
): Promise<ReadinessLoadResult | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const _t0 = performance.now();
    const { adminDb } = await import("@/lib/firebase/server");
    console.log(
      `[PERF] finance:importAdminDb (readiness): ${(performance.now() - _t0).toFixed(0)}ms`,
    );
    const asOf = options.now().toISOString();

    const reportsLimit =
      parsePositiveInt(options.env.WAIN_FINANCE_READINESS_REPORTS_LIMIT) ?? 150;

    const _tQ = performance.now();
    const reportsSnap = await adminDb
      .collection("merchant_wallet_reports")
      .limit(reportsLimit)
      .get();
    console.log(
      `[PERF] finance:firestoreQueries (readiness reports): ${(performance.now() - _tQ).toFixed(0)}ms`,
    );

    let lowBalanceCount = 0;
    for (const reportDoc of reportsSnap.docs) {
      const report = reportDoc.data() ?? {};
      const available =
        typeof report.available_balance === "number" &&
          Number.isFinite(report.available_balance)
          ? report.available_balance
          : undefined;
      const threshold =
        typeof report.low_balance_threshold === "number" &&
          Number.isFinite(report.low_balance_threshold)
          ? report.low_balance_threshold
          : 10;
      if (available !== undefined && available <= threshold) {
        lowBalanceCount += 1;
      }
    }

    const readiness: WalletReadinessReport = {
      generatedAt: asOf,
      overallStatus:
        reportsSnap.size === 0
          ? "warning"
          : lowBalanceCount > 0
            ? "warning"
            : "ready",
      summary:
        reportsSnap.size === 0
          ? "لا توجد تقارير محافظ في قاعدة البيانات حتى الآن."
          : lowBalanceCount > 0
            ? `${lowBalanceCount} من محافظ الجهات أقل من الحدود المحددة.`
            : "أرصدة المحافظ ضمن الحدود المحددة.",
      checks: [
        {
          id: "wallet_reports_coverage",
          label: "تغطية تقارير المحافظ",
          status: reportsSnap.size === 0 ? "warn" : "pass",
          details: `عدد التقارير: ${reportsSnap.size}`,
        },
        {
          id: "wallet_low_balance_scan",
          label: "فحص الرصيد المنخفض",
          status: lowBalanceCount > 0 ? "warn" : "pass",
          details: `عدد الجهات منخفضة الرصيد: ${lowBalanceCount}`,
        },
      ],
    };

    return {
      ok: true,
      snapshot: {
        asOf,
        readiness,
      },
      channel: "firestore:admin_finance",
    };
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    return {
      ok: false,
      message: `Finance firestore fallback failed: ${detail}`,
      channel: "firestore:admin_finance",
    };
  }
}

async function loadLedgerSnapshotFromFirestore(
  options: SnapshotTransportOptions,
): Promise<LedgerLoadResult | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const _t0 = performance.now();
    const { adminDb } = await import("@/lib/firebase/server");
    console.log(
      `[PERF] finance:importAdminDb (ledger): ${(performance.now() - _t0).toFixed(0)}ms`,
    );
    const asOf = options.now().toISOString();

    const ledgerLimit =
      parsePositiveInt(options.env.WAIN_FINANCE_LEDGER_READ_LIMIT) ??
      DEFAULT_LEDGER_READ_LIMIT;
    const hintTopupsLimit =
      parsePositiveInt(options.env.WAIN_FINANCE_TOPUP_READ_LIMIT) ?? 80;
    const hintReportsLimit =
      parsePositiveInt(options.env.WAIN_FINANCE_READINESS_REPORTS_LIMIT) ?? 150;

    const _tQ = performance.now();
    const ledgerDocs = await loadLedgerEntriesWithFallback(adminDb, ledgerLimit, {
      env: options.env,
      getHintVenueIds: async () => {
        const [hintTopupsSnap, hintReportsSnap] = await Promise.all([
          loadTopupRequestsSnapshot(adminDb, hintTopupsLimit),
          adminDb.collection("merchant_wallet_reports").limit(hintReportsLimit).get(),
        ]);
        return collectHintVenueIds(hintTopupsSnap.docs, hintReportsSnap.docs);
      },
    });
    console.log(
      `[PERF] finance:firestoreQueries (ledger): ${(performance.now() - _tQ).toFixed(0)}ms`,
    );

    const venueIds = new Set<string>();
    for (const doc of ledgerDocs) {
      const venueId = doc.ref.parent.parent?.id;
      if (venueId) {
        venueIds.add(venueId);
      }
    }

    const venueNameMap = await loadVenueNameMap(adminDb, venueIds, options.env);

    const ledger: WalletLedgerEntry[] = ledgerDocs.map((doc) => {
      const row = doc.data() ?? {};
      const venueId = doc.ref.parent.parent?.id;
      const rawAmount =
        typeof row.amount === "number" && Number.isFinite(row.amount)
          ? row.amount
          : 0;
      const amount = Math.abs(rawAmount);
      const currency = row.currency === "USD" ? "USD" : "ILS";
      const entryTypeRaw = (
        toNonEmptyString(row.type) ?? toNonEmptyString(row.entry_type)
      )?.toLowerCase();
      const type =
        entryTypeRaw === "credit" ||
        entryTypeRaw === "debit" ||
        entryTypeRaw === "reversal"
          ? entryTypeRaw
          : rawAmount >= 0
            ? "credit"
            : "debit";
      const userId = toNonEmptyString(row.created_by_uid) ?? venueId ?? "system";

      return {
        id: doc.id,
        ...(venueId ? { venueId } : {}),
        userId,
        userName: venueId ? venueNameMap.get(venueId) ?? userId : userId,
        type,
        amount,
        currency,
        description:
          toNonEmptyString(row.description) ??
          toNonEmptyString(row.note) ??
          "Wallet entry",
        reference:
          toNonEmptyString(row.reference_id) ??
          toNonEmptyString(row.idempotency_key) ??
          "",
        createdAt: toFirestoreIso(row.created_at) ?? asOf,
      };
    });

    return {
      ok: true,
      snapshot: {
        asOf,
        ledger,
      },
      channel: "firestore:admin_finance",
    };
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    return {
      ok: false,
      message: `Finance firestore fallback failed: ${detail}`,
      channel: "firestore:admin_finance",
    };
  }
}

async function loadVenueNameMap(
  adminDb: any,
  venueIds: Set<string>,
  env: Record<string, string | undefined>,
): Promise<Map<string, string>> {
  const venueNameMap = new Map<string, string>();
  if (venueIds.size === 0) {
    return venueNameMap;
  }

  const useVenueNameCache = shouldUseVenueNameCache(env);
  const venueNameCacheTtlMs = useVenueNameCache ? resolveVenueNameCacheTtlMs(env) : 0;
  const nowMs = Date.now();
  if (useVenueNameCache && venueNameCacheTtlMs > 0) {
    clearExpiredVenueNameCacheEntries(nowMs);
  }

  const venueIdsToFetch: string[] = [];
  for (const venueId of venueIds) {
    if (useVenueNameCache && venueNameCacheTtlMs > 0) {
      const cached = sharedVenueNameCache.get(venueId);
      if (cached && cached.expiresAt > nowMs) {
        venueNameMap.set(venueId, cached.name);
        continue;
      }
      if (cached) {
        sharedVenueNameCache.delete(venueId);
      }
    }

    venueIdsToFetch.push(venueId);
  }

  if (venueIdsToFetch.length === 0) {
    return venueNameMap;
  }

  const _tV = performance.now();
  const venueDocs = await adminDb.getAll(
    ...venueIdsToFetch.map((venueId) => adminDb.collection("venues").doc(venueId)),
  );
  console.log(
    `[PERF] finance:venueNameLookup (${venueIdsToFetch.length} fetched / ${venueIds.size} requested): ${(performance.now() - _tV).toFixed(0)}ms`,
  );

  const cacheExpiresAtMs = nowMs + venueNameCacheTtlMs;

  for (const venueDoc of venueDocs) {
    const row = venueDoc.data() ?? {};
    const venueName =
      toNonEmptyString(row.name_ar) ??
      toNonEmptyString(row.name) ??
      toNonEmptyString(row.name_en) ??
      venueDoc.id;
    venueNameMap.set(venueDoc.id, venueName);
    if (useVenueNameCache && venueNameCacheTtlMs > 0) {
      sharedVenueNameCache.set(venueDoc.id, {
        name: venueName,
        expiresAt: cacheExpiresAtMs,
      });
    }
  }

  return venueNameMap;
}

async function loadTopupRequestsSnapshot(
  adminDb: any,
  limit: number,
) {
  try {
    return await adminDb
      .collection("merchant_topup_requests")
      .orderBy("created_at", "desc")
      .limit(limit)
      .get();
  } catch (error) {
    if (!isFirestoreFailedPrecondition(error)) {
      throw error;
    }

    return adminDb.collection("merchant_topup_requests").limit(limit).get();
  }
}

async function loadLedgerEntriesWithFallback(
  adminDb: any,
  limit: number,
  options: LedgerFallbackOptions,
): Promise<any[]> {
  const _t0 = performance.now();
  const orderedRetryCooldownMs =
    parsePositiveInt(options.env.WAIN_FINANCE_LEDGER_ORDERED_QUERY_RETRY_COOLDOWN_MS) ??
    DEFAULT_LEDGER_ORDERED_QUERY_RETRY_COOLDOWN_MS;
  const nowMs = Date.now();
  const shouldSkipOrderedQuery = getOrderedLedgerQueryRetryAfterMs() > nowMs;

  if (!shouldSkipOrderedQuery) {
    try {
      const grouped = await adminDb
        .collectionGroup("entries")
        .orderBy("created_at", "desc")
        .limit(limit)
        .get();
      setOrderedLedgerQueryRetryAfterMs(0);
      console.log(`[PERF] loadLedgerEntries: ${(performance.now() - _t0).toFixed(0)}ms (collectionGroup OK, ${grouped.docs.length} docs)`);
      return grouped.docs;
    } catch (error) {
      if (!isFirestoreFailedPrecondition(error)) {
        throw error;
      }

      setOrderedLedgerQueryRetryAfterMs(nowMs + orderedRetryCooldownMs);
      console.warn(
        `[PERF] ⚠️ loadLedgerEntries: collectionGroup(orderBy=created_at) FAILED_PRECONDITION after ${(performance.now() - _t0).toFixed(0)}ms ` +
          `→ trying unordered collectionGroup fallback (cooldown=${orderedRetryCooldownMs}ms)`,
      );
    }
  } else {
    const cooldownRemainingMs = Math.max(getOrderedLedgerQueryRetryAfterMs() - nowMs, 0);
    console.log(
      `[PERF] loadLedgerEntries: skipping ordered collectionGroup due to FAILED_PRECONDITION cooldown ` +
        `(remaining=${cooldownRemainingMs}ms)`,
    );
  }

  try {
    const overscanFactor = Math.max(
      1,
      parsePositiveInt(options.env.WAIN_FINANCE_LEDGER_UNORDERED_OVERSCAN_FACTOR) ??
        DEFAULT_LEDGER_UNORDERED_OVERSCAN_FACTOR,
    );
    const unorderedLimit = Math.max(limit, limit * overscanFactor);
    const unorderedGrouped = await adminDb
      .collectionGroup("entries")
      .limit(unorderedLimit)
      .get();

    const sortedUnordered = sortLedgerDocsByCreatedAtDesc(unorderedGrouped.docs);
    console.log(
      `[PERF] ✅ loadLedgerEntries: unordered collectionGroup fallback recovered in ${(performance.now() - _t0).toFixed(0)}ms ` +
        `(overscan=${unorderedLimit}, docs=${sortedUnordered.length})`,
    );
    return sortedUnordered.slice(0, limit);
  } catch (unorderedError) {
    const detail = unorderedError instanceof Error ? unorderedError.message : String(unorderedError);
    console.warn(
      `[PERF] ⚠️ loadLedgerEntries: unordered collectionGroup fallback failed (${detail}) ` +
        `→ initiating wallet fan-out fallback`,
    );
  }

  const _tF = performance.now();
  const walletsScanLimit =
    parsePositiveInt(options.env.WAIN_FINANCE_LEDGER_FALLBACK_WALLETS_SCAN_LIMIT) ??
    160;
  const walletsSnap = await adminDb.collection("merchant_wallets").limit(walletsScanLimit).get();
  if (walletsSnap.empty) {
    console.log(`[PERF] loadLedgerEntries: fan-out aborted (0 wallets) ${(performance.now() - _t0).toFixed(0)}ms total`);
    return [];
  }

  const hintVenueIds =
    (await options.getHintVenueIds?.().catch(() => [])) ?? [];

  const stagePlan = buildLedgerFallbackStagePlan(
    walletsSnap.docs,
    hintVenueIds,
    limit,
    options.env,
  );

  const stage1Docs = await readWalletEntriesForFallbackStage(
    stagePlan.stage1WalletDocs,
    stagePlan.stage1PerWalletLimit,
  );

  let docs = stage1Docs;
  if (docs.length < limit && stagePlan.stage2WalletDocs.length > 0) {
    const stage2Docs = await readWalletEntriesForFallbackStage(
      stagePlan.stage2WalletDocs,
      stagePlan.stage2PerWalletLimit,
    );
    docs = docs.concat(stage2Docs);
  }

  docs = sortLedgerDocsByCreatedAtDesc(docs);

  console.log(
    `[PERF] ⚠️ loadLedgerEntries: fan-out completed in ${(performance.now() - _tF).toFixed(0)}ms ` +
      `(wallets=${walletsSnap.size}, stage1=${stagePlan.stage1WalletDocs.length}x${stagePlan.stage1PerWalletLimit}, ` +
      `stage2=${stagePlan.stage2WalletDocs.length}x${stagePlan.stage2PerWalletLimit}, hints=${hintVenueIds.length}, ` +
      `entries=${docs.length}, total=${(performance.now() - _t0).toFixed(0)}ms)`,
  );
  return docs.slice(0, limit);
}

function sortLedgerDocsByCreatedAtDesc(docs: any[]): any[] {
  return [...docs].sort((left, right) => {
    const leftIso = toFirestoreIso(left.data()?.created_at);
    const rightIso = toFirestoreIso(right.data()?.created_at);
    const leftMs = leftIso ? Date.parse(leftIso) : 0;
    const rightMs = rightIso ? Date.parse(rightIso) : 0;
    return rightMs - leftMs;
  });
}

function collectHintVenueIds(
  topupDocs: any[],
  reportDocs: any[],
): string[] {
  const output = new Set<string>();

  for (const doc of topupDocs) {
    const venueId = toNonEmptyString(doc?.data?.()?.venue_id);
    if (venueId) {
      output.add(venueId);
    }
  }

  for (const doc of reportDocs) {
    const row = doc?.data?.() ?? {};
    const venueId =
      toNonEmptyString(row.venue_id) ??
      toNonEmptyString(row.venueId) ??
      toNonEmptyString(doc?.id);
    if (venueId) {
      output.add(venueId);
    }
  }

  return Array.from(output);
}

function buildLedgerFallbackStagePlan(
  walletDocs: any[],
  hintVenueIds: string[],
  limit: number,
  env: Record<string, string | undefined>,
): {
  stage1WalletDocs: any[];
  stage2WalletDocs: any[];
  stage1PerWalletLimit: number;
  stage2PerWalletLimit: number;
} {
  const walletById = new Map<string, any>();
  for (const walletDoc of walletDocs) {
    walletById.set(String(walletDoc.id), walletDoc);
  }

  const priorityWalletLimit =
    parsePositiveInt(env.WAIN_FINANCE_LEDGER_FALLBACK_PRIORITY_WALLETS_LIMIT) ?? 24;
  const hintWalletDocs = hintVenueIds
    .map((venueId) => walletById.get(venueId))
    .filter((doc): doc is any => Boolean(doc));

  const seenWalletIds = new Set<string>();
  const stage1WalletDocs: any[] = [];
  for (const walletDoc of hintWalletDocs) {
    if (seenWalletIds.has(walletDoc.id)) {
      continue;
    }
    stage1WalletDocs.push(walletDoc);
    seenWalletIds.add(walletDoc.id);
    if (stage1WalletDocs.length >= priorityWalletLimit) {
      break;
    }
  }

  const fallbackWalletScanLimit =
    parsePositiveInt(env.WAIN_FINANCE_LEDGER_FALLBACK_BROAD_WALLETS_LIMIT) ??
    walletDocs.length;

  const stage2WalletDocs = walletDocs
    .filter((walletDoc) => !seenWalletIds.has(walletDoc.id))
    .slice(0, Math.max(0, fallbackWalletScanLimit));

  const stage1PerWalletLimit =
    stage1WalletDocs.length > 0
      ? Math.max(1, Math.ceil(limit / stage1WalletDocs.length))
      : 0;

  const remainingAfterStage1 = Math.max(
    limit - stage1WalletDocs.length * Math.max(stage1PerWalletLimit, 1),
    1,
  );

  const stage2PerWalletLimit =
    stage2WalletDocs.length > 0
      ? Math.max(1, Math.ceil(remainingAfterStage1 / stage2WalletDocs.length))
      : 0;

  return {
    stage1WalletDocs,
    stage2WalletDocs,
    stage1PerWalletLimit,
    stage2PerWalletLimit,
  };
}

async function readWalletEntriesForFallbackStage(
  walletDocs: any[],
  perWalletLimit: number,
): Promise<any[]> {
  if (walletDocs.length === 0 || perWalletLimit <= 0) {
    return [];
  }

  const entriesByWallet = await Promise.all(
    walletDocs.map(async (walletDoc: any) => {
      try {
        return await walletDoc.ref.collection("entries").limit(perWalletLimit).get();
      } catch {
        return null;
      }
    }),
  );

  const docs: any[] = [];
  for (const entrySnap of entriesByWallet) {
    if (!entrySnap) {
      continue;
    }
    docs.push(...entrySnap.docs);
  }

  return docs;
}

function isFirestoreFailedPrecondition(error: unknown): boolean {
  if (!error || typeof error !== "object") {
    return false;
  }

  const row = error as { code?: unknown; message?: unknown };
  if (row.code === 9 || row.code === "9") {
    return true;
  }

  if (typeof row.code === "string") {
    const normalized = row.code.trim().toLowerCase();
    if (normalized.includes("failed-precondition") || normalized.includes("failed_precondition")) {
      return true;
    }
  }

  if (typeof row.message === "string") {
    return row.message.toUpperCase().includes("FAILED_PRECONDITION");
  }

  return false;
}

function toFirestoreIso(value: unknown): string | null {
  if (value && typeof value === "object" && "toDate" in (value as Record<string, unknown>)) {
    try {
      const dateValue = (value as { toDate: () => Date }).toDate();
      return dateValue.toISOString();
    } catch {
      return null;
    }
  }

  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return new Date(value).toISOString();
  }

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return new Date(parsed).toISOString();
    }
  }

  return null;
}

function toNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function parsePositiveInt(value: string | undefined): number | undefined {
  if (!value || value.trim().length === 0) {
    return undefined;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

export const __financeReadSnapshotTransportForTests = {
  loadLedgerEntriesWithFallback,
  isFirestoreFailedPrecondition,
  resetOrderedLedgerQueryRetryCooldown: () => {
    setOrderedLedgerQueryRetryAfterMs(0);
  },
  resetSharedSnapshotCaches: () => {
    setSharedUnifiedOverrideSnapshotCache(null);
    setSharedTopupsSnapshotCache(null);
    setSharedReadinessSnapshotCache(null);
    setSharedLedgerSnapshotCache(null);
    sharedVenueNameCache.clear();
  },
};

type SnapshotRecord = Record<string, unknown>;

function parseSnapshotJson(raw: string): SnapshotRecord | null {
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return null;
    }
    return parsed as SnapshotRecord;
  } catch {
    return null;
  }
}

function buildSnapshotFromRecord(
  record: SnapshotRecord,
):
  | { ok: true; snapshot: UnifiedSnapshot }
  | { ok: false; message: string } {
  const asOfRaw = record.asOf;
  const asOf =
    typeof asOfRaw === "string" && asOfRaw.trim().length > 0
      ? new Date(asOfRaw).toISOString()
      : new Date().toISOString();

  if (!Array.isArray(record.topups)) {
    return { ok: false, message: "Snapshot is missing a topups array." };
  }
  const topups = record.topups.filter(isTopUpRequest);
  if (topups.length !== record.topups.length) {
    return { ok: false, message: "Snapshot topups array contained invalid entries." };
  }

  if (!Array.isArray(record.ledger)) {
    return { ok: false, message: "Snapshot is missing a ledger array." };
  }
  const ledger = record.ledger.filter(isLedgerEntry);
  if (ledger.length !== record.ledger.length) {
    return { ok: false, message: "Snapshot ledger array contained invalid entries." };
  }

  if (!isReadinessReport(record.readiness)) {
    return { ok: false, message: "Snapshot is missing a valid readiness object." };
  }

  return {
    ok: true,
    snapshot: {
      asOf,
      topups,
      ledger,
      readiness: record.readiness,
    },
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value && typeof value === "object" && !Array.isArray(value));
}

function isTopUpRequest(value: unknown): value is TopUpRequest {
  if (!isRecord(value)) {
    return false;
  }
  return (
    typeof value.id === "string" &&
    typeof value.userId === "string" &&
    typeof value.userName === "string" &&
    typeof value.amount === "number" &&
    (value.currency === "ILS" || value.currency === "USD") &&
    typeof value.providerReference === "string" &&
    typeof value.createdAt === "string" &&
    (value.status === "pending" ||
      value.status === "credited" ||
      value.status === "rejected")
  );
}

function isLedgerEntry(value: unknown): value is WalletLedgerEntry {
  if (!isRecord(value)) {
    return false;
  }
  return (
    typeof value.id === "string" &&
    typeof value.userId === "string" &&
    typeof value.userName === "string" &&
    (value.type === "credit" || value.type === "debit" || value.type === "reversal") &&
    typeof value.amount === "number" &&
    (value.currency === "ILS" || value.currency === "USD") &&
    typeof value.description === "string" &&
    typeof value.reference === "string" &&
    typeof value.createdAt === "string"
  );
}

function isReadinessReport(value: unknown): value is WalletReadinessReport {
  if (!isRecord(value)) {
    return false;
  }
  if (
    typeof value.generatedAt !== "string" ||
    typeof value.summary !== "string" ||
    (value.overallStatus !== "ready" &&
      value.overallStatus !== "warning" &&
      value.overallStatus !== "blocked") ||
    !Array.isArray(value.checks)
  ) {
    return false;
  }
  return value.checks.every((check) => {
    if (!isRecord(check)) {
      return false;
    }
    return (
      typeof check.id === "string" &&
      typeof check.label === "string" &&
      typeof check.details === "string" &&
      (check.status === "pass" || check.status === "warn" || check.status === "fail")
    );
  });
}
