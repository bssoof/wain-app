import { createConfigCallableInvokerFromEnv } from "./config-callable-env";
import {
  FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
  resolveFixtureFallbackPolicy,
} from "@/lib/admin/fixture-fallback-policy";
import {
  DEFAULT_CONFIG_PRICING,
  type ConfigDraftStatus,
  type ConfigGovernanceSnapshot,
  type ConfigPricing,
  type ConfigValidationIssue,
} from "./config-governance-models";

const DEFAULT_STALE_AFTER_MS = 5 * 60 * 1000;
const CALLABLE_CHANNEL = "callable:getAdminConfigGovernanceBundle";
const FIXTURE_CHANNEL = "development_fixture";
const FIXTURE_BLOCKED_CHANNEL = "fixture_fallback_disabled";
const DEFAULT_CONFIG_SHARED_CACHE_TTL_MS = 30_000;
const MAX_CONFIG_SHARED_CACHE_SIZE = 16;

type ConfigSnapshotCacheEntry = {
  value: ConfigGovernanceSnapshot;
  expiresAt: number;
};

const g = globalThis as any;
g.configGovernanceSnapshotCache ??= new Map<string, ConfigSnapshotCacheEntry>();
const configGovernanceSnapshotCache: Map<string, ConfigSnapshotCacheEntry> =
  g.configGovernanceSnapshotCache;

export function __resetConfigGovernanceSnapshotCacheForTests(): void {
  configGovernanceSnapshotCache.clear();
}

export async function loadConfigGovernanceSnapshot(options?: {
  env?: Record<string, string | undefined>;
  now?: () => Date;
}) {
  const _t0 = performance.now();
  const env = options?.env ?? process.env;
  const nowFn = options?.now ?? (() => new Date());
  const sharedCacheConfig = resolveConfigSharedCacheConfig(env, options);
  const cachedSnapshot = readConfigSnapshotFromCache(sharedCacheConfig.key);
  if (sharedCacheConfig.enabled && cachedSnapshot) {
    console.log(
      `[PERF] loadConfigGovernance: ${(performance.now() - _t0).toFixed(0)}ms (channel: cache_hit)`,
    );
    return cachedSnapshot;
  }

  const finalize = (snapshot: ConfigGovernanceSnapshot, channel?: string) => {
    writeConfigSnapshotToCache(sharedCacheConfig, snapshot);
    console.log(
      `[PERF] loadConfigGovernance: ${(performance.now() - _t0).toFixed(0)}ms (channel: ${channel ?? snapshot.source})`,
    );
    return snapshot;
  };

  const staleAfterMs = parsePositiveInt(env.WAIN_CONFIG_STALE_AFTER_MS) ?? DEFAULT_STALE_AFTER_MS;
  const fetchedAt = nowFn();
  const fixtureFallbackPolicy = resolveFixtureFallbackPolicy(env);

  const resolution = createConfigCallableInvokerFromEnv(env);
  if (resolution.ok) {
    try {
      const raw = asRecord(
        await resolution.invokeCallable("getAdminConfigGovernanceBundle", {
          historyLimit: 12,
        }),
      );
      return finalize(
        normalizeCallableSnapshot(raw, fetchedAt, staleAfterMs),
        CALLABLE_CHANNEL,
      );
    } catch (error) {
      const firestoreSnapshot = await loadConfigSnapshotFromFirestore(
        fetchedAt,
        staleAfterMs,
      );
      if (firestoreSnapshot) {
        return finalize(firestoreSnapshot, "firestore_fallback");
      }

      if (!fixtureFallbackPolicy.allowed) {
        return finalize(
          buildUnavailableSnapshot({
            source: `${CALLABLE_CHANNEL} -> ${FIXTURE_BLOCKED_CHANNEL}`,
            generatedAt: fetchedAt,
            message: FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
          }),
          FIXTURE_BLOCKED_CHANNEL,
        );
      }

      return finalize(
        buildFixtureSnapshot({
          source: `${CALLABLE_CHANNEL} -> ${FIXTURE_CHANNEL}`,
          state: "stale",
          generatedAt: fetchedAt,
          message: `Config governance callable read failed: ${normalizeError(error)}`,
        }),
        "fixture_fallback",
      );
    }
  }

  const firestoreSnapshot = await loadConfigSnapshotFromFirestore(
    fetchedAt,
    staleAfterMs,
  );
  if (firestoreSnapshot) {
    return finalize(firestoreSnapshot, "firestore");
  }

  if (!fixtureFallbackPolicy.allowed) {
    return finalize(
      buildUnavailableSnapshot({
        source: FIXTURE_BLOCKED_CHANNEL,
        generatedAt: fetchedAt,
        message: FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
      }),
      FIXTURE_BLOCKED_CHANNEL,
    );
  }

  return finalize(
    buildFixtureSnapshot({
      source: FIXTURE_CHANNEL,
      state: "stale",
      generatedAt: fetchedAt,
      message: "Config governance surface is using fixture data until callable transport is configured.",
    }),
    "fixture",
  );
}

function resolveConfigSharedCacheConfig(
  env: Record<string, string | undefined>,
  options:
    | {
        now?: () => Date;
      }
    | undefined,
): {
  enabled: boolean;
  key: string;
  ttlMs: number;
} {
  const isTestRuntime =
    process.env.NODE_ENV === "test" ||
    process.env.VITEST === "true" ||
    process.env.WAIN_TEST_MODE === "1";

  const explicitMode = env.WAIN_CONFIG_SHARED_CACHE;
  const enabledByEnv = explicitMode === "1" || explicitMode === undefined;
  const enabledInRuntime = explicitMode === "1" || !isTestRuntime;
  const enabledByOptions = explicitMode === "1" || !options?.now;
  const ttlMs =
    parsePositiveInt(env.WAIN_CONFIG_SHARED_CACHE_TTL_MS) ??
    DEFAULT_CONFIG_SHARED_CACHE_TTL_MS;

  return {
    enabled: enabledByEnv && enabledInRuntime && enabledByOptions && ttlMs > 0,
    key: buildConfigSharedCacheKey(env),
    ttlMs,
  };
}

function buildConfigSharedCacheKey(
  env: Record<string, string | undefined>,
): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  const relevantEntries = Object.entries(env)
    .filter(
      ([key]) =>
        key.startsWith("WAIN_CONFIG_") ||
        key.startsWith("NEXT_PUBLIC_WAIN_CONFIG_") ||
        key.startsWith("NEXT_PUBLIC_WAIN_FINANCE_"),
    )
    .sort(([left], [right]) => left.localeCompare(right));

  return JSON.stringify([
    ...relevantEntries,
    ["fixture_fallback_policy", fallbackPolicy.cacheKey],
  ]);
}

function readConfigSnapshotFromCache(
  key: string,
): ConfigGovernanceSnapshot | null {
  const cached = configGovernanceSnapshotCache.get(key);
  if (!cached) {
    return null;
  }

  if (cached.expiresAt <= Date.now()) {
    configGovernanceSnapshotCache.delete(key);
    return null;
  }

  return cached.value;
}

function writeConfigSnapshotToCache(
  config: {
    enabled: boolean;
    key: string;
    ttlMs: number;
  },
  snapshot: ConfigGovernanceSnapshot,
): void {
  if (!config.enabled || config.ttlMs <= 0) {
    return;
  }

  if (
    !configGovernanceSnapshotCache.has(config.key) &&
    configGovernanceSnapshotCache.size >= MAX_CONFIG_SHARED_CACHE_SIZE
  ) {
    const oldestKey = configGovernanceSnapshotCache.keys().next().value;
    if (oldestKey) {
      configGovernanceSnapshotCache.delete(oldestKey);
    }
  }

  configGovernanceSnapshotCache.set(config.key, {
    value: snapshot,
    expiresAt: Date.now() + config.ttlMs,
  });
}

function normalizeCallableSnapshot(
  raw: Record<string, any> | undefined,
  fetchedAt: Date,
  staleAfterMs: number,
): ConfigGovernanceSnapshot {
  const generatedAt = toIsoDate(raw?.generatedAt, fetchedAt);
  const generatedAtMs = Date.parse(generatedAt);

  const live = normalizeLiveSnapshot(asRecord(raw?.live));
  const draft = normalizeDraftSnapshot(asRecord(raw?.draft));
  const history = normalizeHistory(raw?.history);

  const empty = !live.exists && !draft.exists && history.length === 0;
  const stale = fetchedAt.getTime() - generatedAtMs > staleAfterMs;
  const state = empty ? "empty" : stale ? "stale" : "success";

  return {
    generatedAt,
    source: CALLABLE_CHANNEL,
    scope: toNonEmptyString(raw?.scope) ?? "wallet_feature_pricing/default",
    state,
    freshnessNote:
      state === "stale"
        ? "Config governance snapshot is older than the configured freshness window."
        : state === "empty"
          ? "No live/draft/history config rows were returned."
          : "Config governance snapshot is within the expected freshness window.",
    message: empty ? "No config governance records are available yet." : undefined,
    live,
    draft,
    history,
  };
}

async function loadConfigSnapshotFromFirestore(
  fetchedAt: Date,
  staleAfterMs: number,
): Promise<ConfigGovernanceSnapshot | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const { adminDb } = await import("@/lib/firebase/server");

    const liveRef = adminDb.collection("wallet_feature_pricing").doc("default");
    const draftRef = adminDb
      .collection("config_governance_drafts")
      .doc("wallet_feature_pricing_default");

    const [liveDoc, draftDoc] = await Promise.all([liveRef.get(), draftRef.get()]);

    let historySnap;
    try {
      historySnap = await adminDb
        .collection("config_publish_history")
        .orderBy("published_at", "desc")
        .limit(12)
        .get();
    } catch {
      historySnap = await adminDb.collection("config_publish_history").limit(12).get();
    }

    const liveData = (liveDoc.data() ?? {}) as Record<string, unknown>;
    const draftData = (draftDoc.data() ?? {}) as Record<string, unknown>;

    const rawSnapshot = {
      generatedAt: fetchedAt.toISOString(),
      scope: "wallet_feature_pricing/default",
      live: {
        exists: liveDoc.exists,
        version: liveData.version ?? liveData.live_version,
        pricing: liveData,
        updatedAt: liveData.updated_at ?? liveData.updatedAt,
        updatedByUid:
          liveData.updated_by_uid ?? liveData.updatedByUid ?? liveData.actor_uid,
        updatedByRole:
          liveData.updated_by_role ??
          liveData.updatedByRole ??
          liveData.actor_role,
      },
      draft: {
        exists: draftDoc.exists,
        status:
          draftData.status ??
          draftData.draft_status ??
          (draftDoc.exists ? "drafted" : "none"),
        draftVersion: draftData.draft_version ?? draftData.draftVersion,
        pricing: asRecord(draftData.pricing) ?? draftData,
        validationIssues:
          draftData.validation_issues ?? draftData.validationIssues,
        reviewedByUid: draftData.reviewed_by_uid ?? draftData.reviewedByUid,
        reviewedAt: draftData.reviewed_at ?? draftData.reviewedAt,
        updatedAt: draftData.updated_at ?? draftData.updatedAt,
      },
      history: historySnap.docs.map((doc) => {
        const row = (doc.data() ?? {}) as Record<string, unknown>;
        return {
          id: doc.id,
          eventType: row.event_type ?? row.eventType,
          liveVersion: row.live_version ?? row.liveVersion,
          previousLiveVersion:
            row.previous_live_version ?? row.previousLiveVersion,
          rollbackToVersion:
            row.rollback_to_version ?? row.rollbackToVersion,
          sourceHistoryId: row.source_history_id ?? row.sourceHistoryId,
          commandId: row.command_id ?? row.commandId,
          correlationId: row.correlation_id ?? row.correlationId,
          reason: row.reason,
          note: row.note,
          publishedByUid: row.actor_uid ?? row.publishedByUid,
          publishedByRole: row.actor_role ?? row.publishedByRole,
          reviewedByUid: row.reviewed_by_uid ?? row.reviewedByUid,
          publishedAt: row.published_at ?? row.publishedAt,
        };
      }),
    };

    const normalized = normalizeCallableSnapshot(
      rawSnapshot,
      fetchedAt,
      staleAfterMs,
    );

    return {
      ...normalized,
      source: "firestore:config_governance",
    };
  } catch {
    return null;
  }
}

function buildFixtureSnapshot(args: {
  source: string;
  state: ConfigGovernanceSnapshot["state"];
  generatedAt: Date;
  message?: string;
}): ConfigGovernanceSnapshot {
  return {
    generatedAt: args.generatedAt.toISOString(),
    source: args.source,
    scope: "wallet_feature_pricing/default",
    state: args.state,
    freshnessNote:
      args.state === "stale"
        ? "Fixture data is stale and should not be treated as a live governance signal."
        : "Fixture data is being used for config governance baseline.",
    message: args.message,
    live: {
      exists: true,
      version: 0,
      pricing: DEFAULT_CONFIG_PRICING,
      updatedAt: args.generatedAt.toISOString(),
      updatedByUid: "fixture",
      updatedByRole: "system",
    },
    draft: {
      exists: false,
      status: "none",
      draftVersion: 0,
      pricing: null,
      validationIssues: [],
      reviewedByUid: null,
      reviewedAt: null,
      updatedAt: null,
    },
    history: [],
  };
}

function buildUnavailableSnapshot(args: {
  source: string;
  generatedAt: Date;
  message: string;
}): ConfigGovernanceSnapshot {
  return {
    generatedAt: args.generatedAt.toISOString(),
    source: args.source,
    scope: "wallet_feature_pricing/default",
    state: "unavailable",
    freshnessNote: "Config governance source is unavailable and fixture fallback is disabled.",
    message: args.message,
    live: {
      exists: false,
      version: 0,
      pricing: null,
      updatedAt: null,
      updatedByUid: null,
      updatedByRole: null,
    },
    draft: {
      exists: false,
      status: "none",
      draftVersion: 0,
      pricing: null,
      validationIssues: [],
      reviewedByUid: null,
      reviewedAt: null,
      updatedAt: null,
    },
    history: [],
  };
}

function normalizeLiveSnapshot(
  raw: Record<string, any> | undefined,
): ConfigGovernanceSnapshot["live"] {
  return {
    exists: raw?.exists === true,
    version: toNumber(raw?.version) ?? 0,
    pricing: normalizePricing(raw?.pricing),
    updatedAt: toNullableIso(raw?.updatedAt),
    updatedByUid: toNullableString(raw?.updatedByUid),
    updatedByRole: toNullableString(raw?.updatedByRole),
  };
}

function normalizeDraftSnapshot(
  raw: Record<string, any> | undefined,
): ConfigGovernanceSnapshot["draft"] {
  return {
    exists: raw?.exists === true,
    status: normalizeDraftStatus(raw?.status),
    draftVersion: toNumber(raw?.draftVersion) ?? 0,
    pricing: normalizePricing(raw?.pricing),
    validationIssues: normalizeIssues(raw?.validationIssues),
    reviewedByUid: toNullableString(raw?.reviewedByUid),
    reviewedAt: toNullableIso(raw?.reviewedAt),
    updatedAt: toNullableIso(raw?.updatedAt),
  };
}

function normalizeHistory(value: unknown): ConfigGovernanceSnapshot["history"] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => asRecord(entry))
    .filter((entry): entry is Record<string, any> => Boolean(entry))
    .map((entry) => ({
      id: toNonEmptyString(entry.id) ?? "unknown-history",
      eventType: toNonEmptyString(entry.eventType) ?? "config_published",
      liveVersion: toNumber(entry.liveVersion) ?? 0,
      previousLiveVersion: toNumber(entry.previousLiveVersion) ?? 0,
      rollbackToVersion: toNumber(entry.rollbackToVersion),
      sourceHistoryId: toNullableString(entry.sourceHistoryId),
      commandId: toNullableString(entry.commandId),
      correlationId: toNullableString(entry.correlationId),
      reason: toNullableString(entry.reason),
      note: toNullableString(entry.note),
      publishedByUid: toNullableString(entry.publishedByUid),
      publishedByRole: toNullableString(entry.publishedByRole),
      reviewedByUid: toNullableString(entry.reviewedByUid),
      publishedAt: toIsoDate(entry.publishedAt, new Date()),
    }));
}

function normalizeIssues(value: unknown): ConfigValidationIssue[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => asRecord(entry))
    .filter((entry): entry is Record<string, any> => Boolean(entry))
    .map((entry) => ({
      code: toNonEmptyString(entry.code) ?? "validation_issue",
      field: toNonEmptyString(entry.field) ?? "pricing",
      message: toNonEmptyString(entry.message) ?? "Validation issue detected.",
    }));
}

function normalizePricing(value: unknown): ConfigPricing | null {
  const raw = asRecord(value);
  if (!raw) {
    return null;
  }

  const story1d = toNumber(raw.story_promote_1d);
  const story3d = toNumber(raw.story_promote_3d);
  const story7d = toNumber(raw.story_promote_7d);
  const offer1d = toNumber(raw.offer_pin_1d);
  const offer3d = toNumber(raw.offer_pin_3d);
  const offer7d = toNumber(raw.offer_pin_7d);
  const currency = toNonEmptyString(raw.currency);

  if (
    story1d === null ||
    story3d === null ||
    story7d === null ||
    offer1d === null ||
    offer3d === null ||
    offer7d === null ||
    !currency
  ) {
    return null;
  }

  return {
    story_promote_1d: story1d,
    story_promote_3d: story3d,
    story_promote_7d: story7d,
    offer_pin_1d: offer1d,
    offer_pin_3d: offer3d,
    offer_pin_7d: offer7d,
    currency: currency.toUpperCase(),
  };
}

function parsePositiveInt(value: string | undefined): number | null {
  if (!value) {
    return null;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, any>;
}

function toNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value.trim());
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return null;
}

function toIsoDate(value: unknown, fallback: Date): string {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return new Date(value).toISOString();
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return new Date(parsed).toISOString();
    }
  }
  return fallback.toISOString();
}

function toNullableIso(value: unknown): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  return toIsoDate(value, new Date());
}

function toNullableString(value: unknown): string | null {
  const normalized = toNonEmptyString(value);
  return normalized ?? null;
}

function toNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeError(value: unknown): string {
  if (value instanceof Error) {
    return value.message;
  }
  if (value && typeof value === "object" && "message" in value) {
    const message = (value as Record<string, unknown>).message;
    if (typeof message === "string" && message.trim().length > 0) {
      return message;
    }
  }
  return "unknown_error";
}

function normalizeDraftStatus(value: unknown): ConfigDraftStatus {
  return value === "drafted" || value === "reviewed" || value === "published"
    ? value
    : "none";
}
