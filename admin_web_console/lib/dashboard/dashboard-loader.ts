import { loadTopUpQueueRead, loadReadinessRead, type FinanceReadLoaderOptions } from "@/lib/finance/finance-read-loader";
import { loadVenueDirectoryRead } from "@/lib/venues/venue-directory-read-loader";
import { loadOfferModerationSnapshot, loadStoryModerationSnapshot } from "@/lib/content/content-read-loader";
import type { FinanceCallableInvoker } from "@/lib/finance/finance-command-transport";

import type {
  OpsDashboardSummary,
  OpsWidgetData,
  OpsWidgetState,
  TopUpQueueSummary,
  WalletReadinessSummary,
  VenueDirectorySummary,
  ContentModerationBacklogSummary,
} from "./dashboard-models";

const DEFAULT_DASHBOARD_SHARED_CACHE_TTL_MS = 30_000;
const DEFAULT_DASHBOARD_WIDGET_TIMEOUT_MS = 12_000;

type DashboardSummaryCacheEntry = {
  value: OpsDashboardSummary;
  expiresAt: number;
};

const g = globalThis as any;
g.dashboardSummaryCache ??= new Map<string, DashboardSummaryCacheEntry>();
const dashboardSummaryCache: Map<string, DashboardSummaryCacheEntry> = g.dashboardSummaryCache;

export type DashboardLoaderOptions = {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
  fetchImpl?: typeof fetch;
};

export function __resetDashboardSummaryCacheForTests(): void {
  dashboardSummaryCache.clear();
}

export async function loadDashboardSummary(
  options?: DashboardLoaderOptions,
): Promise<OpsDashboardSummary> {
  const _t0 = performance.now();
  const env = options?.env ?? process.env;
  const now = options?.now ?? (() => new Date());
  const sharedCacheConfig = resolveDashboardSharedCacheConfig(env, options);
  const widgetTimeoutMs = resolveDashboardWidgetTimeoutMs(env);

  if (sharedCacheConfig.enabled) {
    const cached = readDashboardSummaryFromCache(sharedCacheConfig.key);
    if (cached) {
      console.log(
        `[PERF] loadDashboardSummary:total_ms: ${(performance.now() - _t0).toFixed(0)}ms (cache_hit)`,
      );
      return cached;
    }
  }

  const financeOptions: FinanceReadLoaderOptions = {
    env,
    now: options?.now,
    invokeCallable: options?.invokeCallable,
    fetchImpl: options?.fetchImpl,
  };

  const results = await Promise.all([
    settleWithTimeout(
      (async () => {
        const _s = performance.now();
        const r = await loadTopUpQueueRead(financeOptions);
        console.log(`[PERF] loadTopUpQueueRead: ${(performance.now() - _s).toFixed(0)}ms`);
        return r;
      })(),
      widgetTimeoutMs,
      "topup_queue",
    ),
    settleWithTimeout(
      (async () => {
        const _s = performance.now();
        const r = await loadReadinessRead(financeOptions);
        console.log(`[PERF] loadReadinessRead: ${(performance.now() - _s).toFixed(0)}ms`);
        return r;
      })(),
      widgetTimeoutMs,
      "wallet_readiness",
    ),
    settleWithTimeout(
      (async () => {
        const _s = performance.now();
        const r = await loadVenueDirectoryRead(financeOptions);
        console.log(`[PERF] loadVenueDirectoryRead: ${(performance.now() - _s).toFixed(0)}ms`);
        return r;
      })(),
      widgetTimeoutMs,
      "venue_directory",
    ),
    settleWithTimeout(
      (async () => {
        const _s = performance.now();
        const r = await loadOfferModerationSnapshot(financeOptions);
        console.log(`[PERF] loadOfferModerationSnapshot: ${(performance.now() - _s).toFixed(0)}ms`);
        return r;
      })(),
      widgetTimeoutMs,
      "content_offers",
    ),
    settleWithTimeout(
      (async () => {
        const _s = performance.now();
        const r = await loadStoryModerationSnapshot(financeOptions);
        console.log(`[PERF] loadStoryModerationSnapshot: ${(performance.now() - _s).toFixed(0)}ms`);
        return r;
      })(),
      widgetTimeoutMs,
      "content_stories",
    ),
  ]);

  const [
    topUpResult,
    readinessResult,
    venueResult,
    offersResult,
    storiesResult,
  ] = results;

  const summary = {
    generatedAt: now().toISOString(),
    topUpQueue: mapTopUpQueue(topUpResult, now),
    walletReadiness: mapWalletReadiness(readinessResult, now),
    venueDirectory: mapVenueDirectory(venueResult, now),
    contentModeration: mapContentModeration(offersResult, storiesResult, now),
  };

  writeDashboardSummaryToCache(sharedCacheConfig, summary);
  console.log(`[PERF] loadDashboardSummary:total_ms: ${(performance.now() - _t0).toFixed(0)}ms`);
  return summary;
}

function resolveDashboardSharedCacheConfig(
  env: Record<string, string | undefined>,
  options: DashboardLoaderOptions | undefined,
): {
  enabled: boolean;
  key: string;
  ttlMs: number;
} {
  const isTestRuntime =
    process.env.NODE_ENV === "test" ||
    process.env.VITEST === "true" ||
    process.env.WAIN_TEST_MODE === "1";

  const explicitMode = env.WAIN_DASHBOARD_SHARED_CACHE;
  const enabledByEnv = explicitMode === "1" || explicitMode === undefined;
  const enabledInRuntime = explicitMode === "1" || !isTestRuntime;
  const enabledByOptions =
    explicitMode === "1" ||
    (!options?.now && !options?.invokeCallable && !options?.fetchImpl);

  const ttlMs =
    parsePositiveInt(env.WAIN_DASHBOARD_SHARED_CACHE_TTL_MS) ??
    DEFAULT_DASHBOARD_SHARED_CACHE_TTL_MS;

  return {
    enabled: enabledByEnv && enabledInRuntime && enabledByOptions && ttlMs > 0,
    key: buildDashboardSharedCacheKey(env),
    ttlMs,
  };
}

function buildDashboardSharedCacheKey(
  env: Record<string, string | undefined>,
): string {
  const relevantEntries = Object.entries(env)
    .filter(([key]) => key.startsWith("WAIN_") || key.startsWith("NEXT_PUBLIC_WAIN_"))
    .sort(([left], [right]) => left.localeCompare(right));

  return relevantEntries
    .map(([key, value]) => `${key}=${value ?? ""}`)
    .join("|");
}

function readDashboardSummaryFromCache(key: string): OpsDashboardSummary | null {
  const entry = dashboardSummaryCache.get(key);
  if (!entry) {
    return null;
  }

  if (entry.expiresAt <= Date.now()) {
    dashboardSummaryCache.delete(key);
    return null;
  }

  return entry.value;
}

function writeDashboardSummaryToCache(
  config: { enabled: boolean; key: string; ttlMs: number },
  value: OpsDashboardSummary,
): void {
  if (!config.enabled) {
    return;
  }

  dashboardSummaryCache.set(config.key, {
    value,
    expiresAt: Date.now() + config.ttlMs,
  });
}

function parsePositiveInt(raw: unknown): number | undefined {
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return undefined;
  }
  const parsed = Number.parseInt(raw.trim(), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

function resolveDashboardWidgetTimeoutMs(
  env: Record<string, string | undefined>,
): number {
  return (
    parsePositiveInt(env.WAIN_DASHBOARD_WIDGET_TIMEOUT_MS) ??
    DEFAULT_DASHBOARD_WIDGET_TIMEOUT_MS
  );
}

async function settleWithTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number,
  widgetKey: string,
): Promise<PromiseSettledResult<T>> {
  if (timeoutMs <= 0) {
    try {
      const value = await promise;
      return { status: "fulfilled", value };
    } catch (reason) {
      return { status: "rejected", reason };
    }
  }

  try {
    const value = await Promise.race([
      promise,
      new Promise<T>((_, reject) => {
        setTimeout(() => {
          reject(
            new Error(
              `dashboard_widget_timeout:${widgetKey}:${timeoutMs}ms`,
            ),
          );
        }, timeoutMs);
      }),
    ]);

    return { status: "fulfilled", value };
  } catch (reason) {
    return { status: "rejected", reason };
  }
}

function mapTopUpQueue(
  result: PromiseSettledResult<Awaited<ReturnType<typeof loadTopUpQueueRead>>>,
  now: () => Date,
): OpsWidgetData<TopUpQueueSummary> {
  if (result.status === "rejected") {
    return buildUnavailableWidget(resolveLoaderFailureMessage(result.reason), now);
  }

  const payload = result.value;
  if (payload.kind === "unavailable") {
    return {
      state: "unavailable",
      asOf: now().toISOString(),
      source: payload.attemptedSource ?? "unknown_source",
      message: payload.message,
      data: null,
    };
  }

  const { data, fetchedAt, source, stale } = payload;
  const pendingCount = data.pending.length;

  return {
    state: pendingCount === 0 && !stale ? "empty" : stale ? "stale" : "success",
    asOf: fetchedAt,
    source,
    message: stale ? "Queue data is stale" : undefined,
    data: {
      pendingCount,
      recentPending: data.pending.slice(0, 5).map(req => ({
        id: req.id,
        userName: req.userName || "غير معروف",
        amount: req.amount,
        currency: req.currency,
        createdAt: req.createdAt,
      })),
    },
  };
}

function mapWalletReadiness(
  result: PromiseSettledResult<Awaited<ReturnType<typeof loadReadinessRead>>>,
  now: () => Date,
): OpsWidgetData<WalletReadinessSummary> {
  if (result.status === "rejected") {
    return buildUnavailableWidget(resolveLoaderFailureMessage(result.reason), now);
  }

  const payload = result.value;
  if (payload.kind === "unavailable") {
    return {
      state: "unavailable",
      asOf: now().toISOString(),
      source: payload.attemptedSource ?? "unknown_source",
      message: payload.message,
      data: null,
    };
  }

  const { data, fetchedAt, source, stale } = payload;
  const failingChecksCount = data.report.checks.filter(c => c.status === "fail").length;
  const warningChecksCount = data.report.checks.filter(c => c.status === "warn").length;

  return {
    state: stale ? "stale" : "success",
    asOf: fetchedAt,
    source,
    message: stale ? "Readiness report is stale." : undefined,
    data: {
      overallStatus: data.report.overallStatus,
      failingChecksCount,
      warningChecksCount,
      failingChecksPreview: data.report.checks.filter(c => c.status === "fail").slice(0, 3).map(c => ({
        id: c.id,
        name: c.label,
        message: c.details || "فشل الفحص بدون تفاصيل",
      })),
    },
  };
}

function mapVenueDirectory(
  result: PromiseSettledResult<Awaited<ReturnType<typeof loadVenueDirectoryRead>>>,
  now: () => Date,
): OpsWidgetData<VenueDirectorySummary> {
  if (result.status === "rejected") {
    return buildUnavailableWidget(resolveLoaderFailureMessage(result.reason), now);
  }

  const payload = result.value;
  if (payload.kind === "unavailable") {
    return {
      state: "unavailable",
      asOf: now().toISOString(),
      source: payload.attemptedSource ?? "unknown_source",
      message: payload.message,
      data: null,
    };
  }

  const { data, fetchedAt, source, stale } = payload;

  return {
    state: data.items.length === 0 && !stale ? "empty" : stale ? "stale" : "success",
    asOf: fetchedAt,
    source,
    message: stale ? "Venue directory read is stale." : undefined,
    data: {
      totalVenues: data.summary.totalVenues,
      readyVenues: data.summary.readiness["ready"] ?? 0,
      lowBalanceVenues: data.summary.wallet["low_balance"] ?? 0,
      inactiveWallets: data.summary.wallet["inactive"] ?? 0,
      lowBalancePreview: data.items
        .filter(v => {
          const vd = v as any;
          return typeof vd.wallet === "object" && vd.wallet !== null && vd.wallet.status === "low_balance";
        })
        .slice(0, 3)
        .map(v => {
          const vd = v as Record<string, any>;
          return { id: String(vd.id), name: String(vd.name_ar || vd.name_en || "جهة مجهولة") };
        }),
    },
  };
}

function mapContentModeration(
  offersResult: PromiseSettledResult<Awaited<ReturnType<typeof loadOfferModerationSnapshot>>>,
  storiesResult: PromiseSettledResult<Awaited<ReturnType<typeof loadStoryModerationSnapshot>>>,
  now: () => Date,
): OpsWidgetData<ContentModerationBacklogSummary> {
  if (offersResult.status !== "fulfilled" || storiesResult.status !== "fulfilled") {
    const rejectedReason =
      offersResult.status === "rejected"
        ? resolveLoaderFailureMessage(offersResult.reason)
        : storiesResult.status === "rejected"
          ? resolveLoaderFailureMessage(storiesResult.reason)
          : "Content read loader failed.";

    return buildUnavailableWidget(rejectedReason, now);
  }

  const offers = offersResult.value;
  const stories = storiesResult.value;

  const isUnavailable = offers.state === "unavailable" || stories.state === "unavailable";
  if (isUnavailable) {
    return {
      state: "unavailable",
      asOf: now().toISOString(),
      source: `${offers.source} / ${stories.source}`,
      message: offers.message ?? stories.message ?? "Content moderation read is unavailable.",
      data: null,
    };
  }

  const isStale = offers.state === "stale" || stories.state === "stale";
  const pendingOffers = offers.items.filter((o) => o.adminState === "pending").length;
  const pendingStories = stories.items.filter((s) => s.adminState === "pending").length;
  const isEmpty =
    (offers.state === "empty" && stories.state === "empty") ||
    (pendingOffers === 0 && pendingStories === 0);

  return {
    state: isEmpty && !isStale ? "empty" : isStale ? "stale" : "success",
    asOf: offers.generatedAt,
    source: `${offers.source} / ${stories.source}`,
    message: isStale ? "Content moderation backlog is stale." : undefined,
    data: {
      pendingOffers,
      pendingStories,
      recentOffersPreview: offers.items.filter(o => o.adminState === "pending").slice(0, 3).map(o => ({
        id: o.id,
        title: o.title,
        venueId: o.venueId,
        createdAt: o.createdAt,
      })),
    },
  };
}

function buildUnavailableWidget<T>(message: string, now: () => Date): OpsWidgetData<T> {
  return {
    state: "unavailable",
    asOf: now().toISOString(),
    source: "dashboard_loader",
    message,
    data: null,
  };
}

function resolveLoaderFailureMessage(reason: unknown): string {
  const rawMessage =
    reason instanceof Error
      ? reason.message
      : typeof reason === "string"
        ? reason
        : "Promise rejected or crashed.";

  if (rawMessage.startsWith("dashboard_widget_timeout:")) {
    return "هذا القسم يستغرق وقتًا أطول من المتوقع. أعد المحاولة بعد لحظات.";
  }

  return rawMessage;
}
