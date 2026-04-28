import { formatCurrency, formatStatus } from "@/lib/finance/read-model-formatters";
import {
  createFinanceCallableInvokerFromEnv,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";
import {
  FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
  resolveFixtureFallbackPolicy,
} from "@/lib/admin/fixture-fallback-policy";

import type {
  VenueDirectoryFilterInput,
  VenueDirectoryFilterOptions,
  VenueDirectoryItem,
  VenueDirectoryReadBudget,
  VenueDirectoryReadData,
  VenueDirectorySummary,
} from "./venue-directory-models";
import type {
  VenueDirectoryReadResult,
  VenueDirectoryReadSuccess,
} from "./venue-directory-read-types";

const DEFAULT_STALE_AFTER_MS = 5 * 60 * 1000;
const DEFAULT_SHARED_CACHE_TTL_MS = 30_000;
const FIXTURE_CHANNEL = "development_fixture";

const DEFAULT_VENUE_IDS = [
  "venue_wain_default",
  "venue_ramallah_core",
  "venue_nablus_hub",
];

type VenueDirectorySnapshot = {
  asOf: string;
  items: VenueDirectoryItem[];
};

type SnapshotLoadResult =
  | {
      ok: true;
      snapshot: VenueDirectorySnapshot;
      channel: string;
      readBudget: VenueDirectoryReadBudget;
    }
  | {
      ok: false;
      message: string;
      channel: string;
    };

type VenueDirectoryReadLoaderOptions = {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
  fetchImpl?: typeof fetch;
};

type VenueDirectoryReadCacheEntry = {
  value: VenueDirectoryReadResult<VenueDirectoryReadData>;
  expiresAt: number;
};

const g = globalThis as any;
g.venueDirectoryReadCache ??= new Map<string, VenueDirectoryReadCacheEntry>();
const venueDirectoryReadCache: Map<string, VenueDirectoryReadCacheEntry> = g.venueDirectoryReadCache;

export function __resetVenueDirectoryReadCacheForTests(): void {
  venueDirectoryReadCache.clear();
}

export async function loadVenueDirectoryRead(
  options?: VenueDirectoryReadLoaderOptions,
): Promise<VenueDirectoryReadResult<VenueDirectoryReadData>> {
  const _t0 = performance.now();
  const env = options?.env ?? process.env;
  const now = options?.now ?? (() => new Date());
  const fetchImpl = options?.fetchImpl ?? fetch;

  const sharedCacheConfig = resolveSharedCacheConfig(env, options);
  if (sharedCacheConfig.enabled) {
    const cached = readSharedCache(sharedCacheConfig.key);
    if (cached) {
      console.log(
        `[PERF] loadVenueDirectoryRead: ${(performance.now() - _t0).toFixed(0)}ms (channel: cache_hit)`,
      );
      return cached;
    }
  }

  if (env.WAIN_VENUE_DIRECTORY_FORCE_UNAVAILABLE === "1") {
    const unavailableResult: VenueDirectoryReadResult<VenueDirectoryReadData> = {
      kind: "unavailable",
      message:
        "Venue directory read is unavailable (WAIN_VENUE_DIRECTORY_FORCE_UNAVAILABLE).",
      attemptedSource: "venue_directory_forced_unavailable",
    };
    writeSharedCache(sharedCacheConfig, unavailableResult);
    return unavailableResult;
  }

  const staleAfterMs =
    parsePositiveInt(env.WAIN_VENUE_DIRECTORY_STALE_AFTER_MS) ?? DEFAULT_STALE_AFTER_MS;
  const fixtureFallbackPolicy = resolveFixtureFallbackPolicy(env);

  const invokerResolution = resolveCallableInvoker(options, env);
  const callableResult = invokerResolution
    ? await loadSnapshotFromCallable({
        invokeCallable: invokerResolution,
        env,
        now,
      })
    : null;

  if (callableResult && callableResult.ok) {
    const readResult = toReadSuccess(callableResult.snapshot, {
      source: callableResult.channel,
      fetchedAt: now().toISOString(),
      staleAfterMs,
      readBudget: callableResult.readBudget,
    });
    writeSharedCache(sharedCacheConfig, readResult);
    console.log(`[PERF] loadVenueDirectoryRead: ${(performance.now() - _t0).toFixed(0)}ms (channel: ${callableResult.channel})`);
    return readResult;
  }

  const firestoreResult =
    env.WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE === "1"
      ? null
      : await loadSnapshotFromFirestoreAdmin({
          env,
          now,
        });

  if (firestoreResult?.ok) {
    const readResult = toReadSuccess(firestoreResult.snapshot, {
      source:
        callableResult && !callableResult.ok
          ? `${callableResult.channel} -> ${firestoreResult.channel}`
          : firestoreResult.channel,
      fetchedAt: now().toISOString(),
      staleAfterMs,
      readBudget: firestoreResult.readBudget,
    });
    writeSharedCache(sharedCacheConfig, readResult);
    console.log(`[PERF] loadVenueDirectoryRead: ${(performance.now() - _t0).toFixed(0)}ms (channel: ${firestoreResult.channel})`);
    return readResult;
  }

  const snapshotResult = await loadSnapshotFromConfig({
    env,
    now,
    fetchImpl,
    allowFixtureFallback: fixtureFallbackPolicy.allowed,
  });

  if (!snapshotResult.ok) {
    const unavailableResult: VenueDirectoryReadResult<VenueDirectoryReadData> = {
      kind: "unavailable",
      message: snapshotResult.message,
      attemptedSource: callableResult
        ? `${callableResult.channel} -> ${snapshotResult.channel}`
        : snapshotResult.channel,
    };
    writeSharedCache(sharedCacheConfig, unavailableResult);
    return unavailableResult;
  }

  const readResult = toReadSuccess(snapshotResult.snapshot, {
    source:
      callableResult && !callableResult.ok
        ? `${callableResult.channel} -> ${snapshotResult.channel}`
        : snapshotResult.channel,
    fetchedAt: now().toISOString(),
    staleAfterMs,
    readBudget: snapshotResult.readBudget,
  });
  writeSharedCache(sharedCacheConfig, readResult);
  console.log(`[PERF] loadVenueDirectoryRead: ${(performance.now() - _t0).toFixed(0)}ms (channel: ${snapshotResult.channel})`);
  return readResult;
}

function resolveSharedCacheConfig(
  env: Record<string, string | undefined>,
  options: VenueDirectoryReadLoaderOptions | undefined,
): {
  enabled: boolean;
  key: string;
  ttlMs: number;
} {
  const isTestRuntime =
    process.env.NODE_ENV === "test" ||
    process.env.VITEST === "true" ||
    process.env.WAIN_TEST_MODE === "1";

  const explicitMode = env.WAIN_VENUE_DIRECTORY_SHARED_CACHE;
  const enabledByEnv = explicitMode === "1" || explicitMode === undefined;
  const enabledInRuntime = explicitMode === "1" || !isTestRuntime;
  const enabledByOptions =
    explicitMode === "1" ||
    (!options?.invokeCallable && !options?.now && !options?.fetchImpl);

  const ttlMs =
    parsePositiveInt(env.WAIN_VENUE_DIRECTORY_SHARED_CACHE_TTL_MS) ??
    DEFAULT_SHARED_CACHE_TTL_MS;

  return {
    enabled: enabledByEnv && enabledInRuntime && enabledByOptions && ttlMs > 0,
    key: buildSharedCacheKey(env),
    ttlMs,
  };
}

function buildSharedCacheKey(env: Record<string, string | undefined>): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  const entries = [
    ["fixtureFallback", fallbackPolicy.cacheKey],
    ["forceUnavailable", env.WAIN_VENUE_DIRECTORY_FORCE_UNAVAILABLE],
    ["staleAfterMs", env.WAIN_VENUE_DIRECTORY_STALE_AFTER_MS],
    ["skipFirestore", env.WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE],
    ["adminLimit", env.WAIN_VENUE_DIRECTORY_ADMIN_LIMIT],
    ["ids", env.WAIN_VENUE_DIRECTORY_IDS],
    ["fixtureAsOf", env.WAIN_VENUE_DIRECTORY_FIXTURE_AS_OF],
    ["inlineJson", env.WAIN_VENUE_DIRECTORY_INLINE_JSON],
    ["httpUrl", env.WAIN_VENUE_DIRECTORY_HTTP_URL],
    ["venueBaseUrl", env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL],
    ["financeBaseUrl", env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL],
  ];

  return entries
    .map(([key, value]) => `${key}=${value ?? ""}`)
    .join("|");
}

function readSharedCache(
  key: string,
): VenueDirectoryReadResult<VenueDirectoryReadData> | null {
  const entry = venueDirectoryReadCache.get(key);
  if (!entry) {
    return null;
  }

  if (entry.expiresAt <= Date.now()) {
    venueDirectoryReadCache.delete(key);
    return null;
  }

  return entry.value;
}

function writeSharedCache(
  config: { enabled: boolean; key: string; ttlMs: number },
  value: VenueDirectoryReadResult<VenueDirectoryReadData>,
): void {
  if (!config.enabled) {
    return;
  }

  venueDirectoryReadCache.set(config.key, {
    value,
    expiresAt: Date.now() + config.ttlMs,
  });
}

export function filterVenueDirectoryItems(
  items: VenueDirectoryItem[],
  input: VenueDirectoryFilterInput,
): VenueDirectoryItem[] {
  const search = normalizeSearch(input.searchTerm);
  const city = normalizeSearch(input.city);
  const category = normalizeSearch(input.category);

  return items.filter((item) => {
    if (city && normalizeSearch(item.city) !== city) {
      return false;
    }

    if (
      category &&
      !item.categories.some((entry) => normalizeSearch(entry) === category)
    ) {
      return false;
    }

    if (!search) {
      return true;
    }

    const searchTargets = [
      item.venueId,
      item.venueName,
      item.venueNameEn ?? "",
      item.city ?? "",
      item.phone ?? "",
      item.categories.join(" "),
      item.readinessSummary,
      item.walletSummary,
      item.merchantLinkSummary,
      item.subscriptionStatus,
      item.visibilityStatus,
      item.operationalStatus,
    ];

    return searchTargets.some((target) => normalizeSearch(target).includes(search));
  });
}

function resolveCallableInvoker(
  options: VenueDirectoryReadLoaderOptions | undefined,
  env: Record<string, string | undefined>,
): FinanceCallableInvoker | null {
  if (options?.invokeCallable) {
    return options.invokeCallable;
  }

  const resolved = createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      env.NEXT_PUBLIC_WAIN_VENUE_AUTH_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      env.NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
  });

  return resolved.ok ? resolved.invokeCallable : null;
}

async function loadSnapshotFromCallable(args: {
  invokeCallable: FinanceCallableInvoker;
  env: Record<string, string | undefined>;
  now: () => Date;
}): Promise<SnapshotLoadResult> {
  const limit =
    parsePositiveInt(args.env.WAIN_VENUE_DIRECTORY_ADMIN_LIMIT) ?? 150;

  try {
    const rawResponse = asRecord(
      await args.invokeCallable("listVenuesForAdmin", {
        limit,
        correlationId: "admin_web_console_venue_directory",
      }),
    );
    const itemsSource = Array.isArray(rawResponse?.items)
      ? rawResponse.items
      : Array.isArray(rawResponse?.venues)
        ? rawResponse.venues
        : [];
    const items = sortVenueItems(
      itemsSource
        .map((rawVenue) => {
          const venueRecord = asRecord(rawVenue);
          return venueRecord ? normalizeVenueRecord(venueRecord) : null;
        })
        .filter((entry): entry is VenueDirectoryItem => Boolean(entry)),
    );

    return {
      ok: true,
      snapshot: {
        asOf: args.now().toISOString(),
        items,
      },
      channel: "callable:listVenuesForAdmin",
      readBudget: {
        sourceMode: "admin_list_callable",
        boundsScanned: 0,
        perBoundLimit: null,
        maxPagesPerBound: null,
        maxResultsBudget: limit,
        truncatedBounds: [],
        partialResults: false,
      },
    };
  } catch (error) {
    return {
      ok: false,
      message: `Venue directory callable read failed: ${normalizeError(error)}`,
      channel: "callable:listVenuesForAdmin",
    };
  }
}

async function loadSnapshotFromFirestoreAdmin(args: {
  env: Record<string, string | undefined>;
  now: () => Date;
}): Promise<SnapshotLoadResult> {
  try {
    const _t0 = performance.now();
    const { adminDb } = await import("@/lib/firebase/server");
    const limit =
      parsePositiveInt(args.env.WAIN_VENUE_DIRECTORY_ADMIN_LIMIT) ?? 150;

    const venuesSnap = await adminDb.collection("venues").limit(limit).get();
    const venueIds = venuesSnap.docs.map((doc) => doc.id);
    console.log(`[PERF] venue:firestoreAdmin:venueRead: ${(performance.now() - _t0).toFixed(0)}ms (${venueIds.length} venues)`);

    const _tW = performance.now();
    const [walletDocs, walletReportDocs] = venueIds.length > 0
      ? await Promise.all([
          adminDb.getAll(
            ...venueIds.map((venueId) =>
              adminDb.collection("merchant_wallets").doc(venueId)
            ),
          ),
          adminDb.getAll(
            ...venueIds.map((venueId) =>
              adminDb.collection("merchant_wallet_reports").doc(venueId)
            ),
          ),
        ])
      : [[], []];
    console.log(`[PERF] venue:firestoreAdmin:walletReads: ${(performance.now() - _tW).toFixed(0)}ms (${venueIds.length} wallets + ${venueIds.length} reports = ${venueIds.length * 2} docs)`);

    const walletByVenueId = new Map<string, Record<string, unknown>>();
    for (const walletDoc of walletDocs) {
      walletByVenueId.set(
        walletDoc.id,
        (walletDoc.data() ?? {}) as Record<string, unknown>,
      );
    }

    const walletReportByVenueId = new Map<string, Record<string, unknown>>();
    for (const walletReportDoc of walletReportDocs) {
      walletReportByVenueId.set(
        walletReportDoc.id,
        (walletReportDoc.data() ?? {}) as Record<string, unknown>,
      );
    }

    const items = sortVenueItems(
      venuesSnap.docs
        .map((venueDoc) => {
          const venueData =
            (venueDoc.data() ?? {}) as Record<string, unknown>;
          const walletData = walletByVenueId.get(venueDoc.id) ?? {};
          const walletReport = walletReportByVenueId.get(venueDoc.id) ?? {};

          const mergedRecord: Record<string, unknown> = {
            id: venueDoc.id,
            ...venueData,
            wallet_available_balance:
              walletReport.available_balance ?? walletData.available_balance,
            wallet_low_balance_threshold:
              walletReport.low_balance_threshold ??
              walletData.low_balance_threshold,
            wallet_currency: walletReport.currency ?? walletData.currency,
          };

          return normalizeVenueRecord(mergedRecord);
        })
        .filter((entry): entry is VenueDirectoryItem => Boolean(entry)),
    );

    return {
      ok: true,
      snapshot: {
        asOf: args.now().toISOString(),
        items,
      },
      channel: "firestore:venues",
      readBudget: buildSnapshotReadBudget(),
    };
  } catch (error) {
    return {
      ok: false,
      message: `Venue directory firestore read failed: ${normalizeError(error)}`,
      channel: "firestore:venues",
    };
  }
}

async function loadSnapshotFromConfig(args: {
  env: Record<string, string | undefined>;
  now: () => Date;
  fetchImpl: typeof fetch;
  allowFixtureFallback: boolean;
}): Promise<SnapshotLoadResult> {
  const inline = args.env.WAIN_VENUE_DIRECTORY_INLINE_JSON?.trim();
  if (inline) {
    const parsed = parseJsonObject(inline);
    if (!parsed) {
      return {
        ok: false,
        message: "WAIN_VENUE_DIRECTORY_INLINE_JSON is not a valid JSON object.",
        channel: "inline_json",
      };
    }

    const built = buildSnapshotFromRecord(parsed, args.now);
    if (!built.ok) {
      return {
        ok: false,
        message: built.message,
        channel: "inline_json",
      };
    }

    return {
      ok: true,
      snapshot: built.snapshot,
      channel: "inline_json",
      readBudget: buildSnapshotReadBudget(),
    };
  }

  const url = args.env.WAIN_VENUE_DIRECTORY_HTTP_URL?.trim();
  if (url) {
    try {
      const response = await args.fetchImpl(url, { cache: "no-store" });
      if (!response.ok) {
        return {
          ok: false,
          message: `Venue directory HTTP ${response.status} ${response.statusText}`,
          channel: `http:${url}`,
        };
      }

      const text = await response.text();
      const parsed = parseJsonObject(text);
      if (!parsed) {
        return {
          ok: false,
          message: "Venue directory HTTP response was not a JSON object.",
          channel: `http:${url}`,
        };
      }

      const built = buildSnapshotFromRecord(parsed, args.now);
      if (!built.ok) {
        return {
          ok: false,
          message: built.message,
          channel: `http:${url}`,
        };
      }

      return {
        ok: true,
        snapshot: built.snapshot,
        channel: `http:${url}`,
        readBudget: buildSnapshotReadBudget(),
      };
    } catch (error) {
      return {
        ok: false,
        message: `Venue directory fetch failed: ${normalizeError(error)}`,
        channel: `http:${url}`,
      };
    }
  }

  if (!args.allowFixtureFallback) {
    return {
      ok: false,
      message: FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
      channel: "fixture_fallback_disabled",
    };
  }

  return {
    ok: true,
    snapshot: buildFixtureSnapshot(args.env, args.now),
    channel: FIXTURE_CHANNEL,
    readBudget: buildSnapshotReadBudget(),
  };
}

function buildSnapshotFromRecord(
  record: Record<string, unknown>,
  now: () => Date,
):
  | {
      ok: true;
      snapshot: VenueDirectorySnapshot;
    }
  | {
      ok: false;
      message: string;
    } {
  const asOf = normalizeIsoDate(record.asOf, now);
  const sourceRows = Array.isArray(record.items)
    ? record.items
    : Array.isArray(record.venues)
      ? record.venues
      : null;

  if (!sourceRows) {
    return {
      ok: false,
      message: "Venue directory snapshot is missing an items or venues array.",
    };
  }

  const items: VenueDirectoryItem[] = [];
  for (const row of sourceRows) {
    const rowRecord = asRecord(row);
    if (!rowRecord) {
      return {
        ok: false,
        message: "Venue directory snapshot rows must be objects.",
      };
    }

    const normalized = normalizeVenueRecord(rowRecord);
    if (!normalized) {
      return {
        ok: false,
        message: "Venue directory snapshot contained an item without venue id.",
      };
    }
    items.push(normalized);
  }

  return {
    ok: true,
    snapshot: {
      asOf,
      items: sortVenueItems(items),
    },
  };
}

function buildFixtureSnapshot(
  env: Record<string, string | undefined>,
  now: () => Date,
): VenueDirectorySnapshot {
  const asOf = normalizeIsoDate(env.WAIN_VENUE_DIRECTORY_FIXTURE_AS_OF, now);
  const venueIds = resolveFixtureVenueIds(env);
  const items = sortVenueItems(
    venueIds.map((venueId, index) => buildFixtureVenueItem(venueId, index)),
  );

  return {
    asOf,
    items,
  };
}

function toReadSuccess(
  snapshot: VenueDirectorySnapshot,
  meta: {
    source: string;
    fetchedAt: string;
    staleAfterMs: number;
    readBudget: VenueDirectoryReadBudget;
  },
): VenueDirectoryReadSuccess<VenueDirectoryReadData> {
  const asOfMs = Date.parse(snapshot.asOf);
  const fetchedAtMs = Date.parse(meta.fetchedAt);
  const ageMs = Number.isFinite(asOfMs) && Number.isFinite(fetchedAtMs)
    ? Math.max(0, fetchedAtMs - asOfMs)
    : meta.staleAfterMs + 1;

  const data: VenueDirectoryReadData = {
    items: snapshot.items,
    summary: buildDirectorySummary(snapshot.items),
    filters: buildFilterOptions(snapshot.items),
    readBudget: meta.readBudget,
  };

  return {
    kind: "success",
    data,
    asOf: snapshot.asOf,
    fetchedAt: meta.fetchedAt,
    source: meta.source,
    stale: ageMs > meta.staleAfterMs,
  };
}

function buildSnapshotReadBudget(): VenueDirectoryReadBudget {
  return {
    sourceMode: "snapshot",
    boundsScanned: 0,
    perBoundLimit: null,
    maxPagesPerBound: null,
    maxResultsBudget: null,
    truncatedBounds: [],
    partialResults: false,
  };
}

function normalizeVenueRecord(record: Record<string, unknown>): VenueDirectoryItem | null {
  const venueId =
    toNonEmptyString(record.id) ??
    toNonEmptyString(record.venue_id) ??
    toNonEmptyString(record.venueId);

  if (!venueId) {
    return null;
  }

  const venueName =
    toNonEmptyString(record.name_ar) ??
    toNonEmptyString(record.name) ??
    toNonEmptyString(record.name_en) ??
    toNonEmptyString(record.venue_name) ??
    toNonEmptyString(record.venueName) ??
    venueId;

  const city =
    toNonEmptyString(record.city) ??
    toNonEmptyString(record.city_en) ??
    toNonEmptyString(record.city_ar) ??
    null;
  const venueNameEn =
    toNonEmptyString(record.name_en) ??
    toNonEmptyString(record.venue_name_en) ??
    null;
  const phone =
    toNonEmptyString(record.phone) ??
    toNonEmptyString(record.contact_phone) ??
    null;
  const lat = firstFiniteNumber([record.lat, record.latitude]);
  const lng = firstFiniteNumber([record.lng, record.longitude, record.lon]);

  const categories = parseStringList(record.categories);

  const readiness = deriveReadiness(record, city, categories);
  const wallet = deriveWallet(record);
  const merchantLink = deriveMerchantLink(record);
  const subscriptionStatus = normalizeVenueSubscriptionStatus(
    toNonEmptyString(record.subscription_status) ??
      toNonEmptyString(record.subscriptionStatus),
  ) ?? "active";
  const visibilityStatus = normalizeVenueVisibilityStatus(
    toNonEmptyString(record.visibility_status) ??
      toNonEmptyString(record.visibilityStatus),
  ) ?? "visible";
  const operationalStatus = normalizeVenueOperationalStatus(
    toNonEmptyString(record.operational_status) ??
      toNonEmptyString(record.operationalStatus),
  ) ?? "active";

  return {
    venueId,
    venueName,
    venueNameEn,
    city,
    lat,
    lng,
    categories,
    phone,
    readinessStatus: readiness.status,
    readinessSummary: readiness.summary,
    walletStatus: wallet.status,
    walletSummary: wallet.summary,
    walletBalance: wallet.balance,
    walletCurrency: wallet.currency,
    merchantLinkStatus: merchantLink.status,
    merchantLinkSummary: merchantLink.summary,
    merchantLinkedCount: merchantLink.linkedCount,
    subscriptionStatus,
    visibilityStatus,
    operationalStatus,
    workspacePath: `/admin/venues/${encodeURIComponent(venueId)}`,
  };
}

function deriveReadiness(
  record: Record<string, unknown>,
  city: string | null,
  categories: string[],
): { status: VenueDirectoryItem["readinessStatus"]; summary: string } {
  const explicitStatus = normalizeReadinessStatus(
    toNonEmptyString(record.readiness_status) ??
      toNonEmptyString(record.readinessStatus) ??
      toNonEmptyString(record.operational_readiness),
  );
  const explicitSummary =
    toNonEmptyString(record.readiness_summary) ??
    toNonEmptyString(record.readinessSummary) ??
    null;

  if (explicitStatus) {
    return {
      status: explicitStatus,
      summary: explicitSummary ?? `جاهزية الجهة: ${formatStatus(explicitStatus)}.`,
    };
  }

  const operationalStatus = normalizeVenueOperationalStatus(
    toNonEmptyString(record.operational_status) ??
      toNonEmptyString(record.operationalStatus),
  );
  if (operationalStatus === "suspended" || operationalStatus === "archived") {
    return {
      status: "fail",
      summary: `الحالة التشغيلية: ${formatStatus(operationalStatus)}.`,
    };
  }

  if (record.is_active === false) {
    return {
      status: "fail",
      summary: "الجهة غير نشطة حاليًا.",
    };
  }

  if (city && categories.length > 0) {
    return {
      status: "ready",
      summary: "البيانات الأساسية للجهة مكتملة.",
    };
  }

  if (city || categories.length > 0) {
    return {
      status: "warning",
      summary: "بيانات الجهة مكتملة جزئيًا.",
    };
  }

  return {
    status: "unknown",
    summary: "ملخص الجاهزية غير متاح في القراءة الحالية.",
  };
}

function deriveWallet(record: Record<string, unknown>): {
  status: VenueDirectoryItem["walletStatus"];
  summary: string;
  balance: number | null;
  currency: "ILS" | "USD";
} {
  const balance = firstFiniteNumber([
    record.wallet_available_balance,
    record.available_balance,
    record.walletBalance,
    record.wallet_balance,
  ]);
  const threshold = firstFiniteNumber([
    record.wallet_low_balance_threshold,
    record.low_balance_threshold,
  ]) ?? 10;

  const explicitStatus = normalizeWalletStatus(
    toNonEmptyString(record.wallet_status) ??
      toNonEmptyString(record.walletStatus) ??
      toNonEmptyString(record.wallet_state),
  );

  const currency = normalizeCurrency(
    toNonEmptyString(record.wallet_currency) ??
      toNonEmptyString(record.currency),
  );

  if (balance !== null) {
    if (explicitStatus === "inactive") {
      return {
        status: "inactive",
        summary: "المحفظة موقوفة.",
        balance,
        currency,
      };
    }

    const status: VenueDirectoryItem["walletStatus"] =
      balance <= threshold ? "low_balance" : "active";

    return {
      status,
      summary:
        status === "low_balance"
          ? `الرصيد منخفض: ${formatCurrency(balance, currency)} (الحد ${formatCurrency(
              threshold,
              currency,
            )}).`
          : `الرصيد الحالي: ${formatCurrency(balance, currency)}.`,
      balance,
      currency,
    };
  }

  if (explicitStatus) {
    return {
      status: explicitStatus,
      summary: `حالة المحفظة: ${formatStatus(explicitStatus)}.`,
      balance: null,
      currency,
    };
  }

  return {
    status: "unknown",
    summary: "ملخص المحفظة غير متاح في القراءة الحالية.",
    balance: null,
    currency,
  };
}

function deriveMerchantLink(record: Record<string, unknown>): {
  status: VenueDirectoryItem["merchantLinkStatus"];
  summary: string;
  linkedCount: number | null;
} {
  const linkedIds = new Set<string>();

  const singleId =
    toNonEmptyString(record.merchant_uid) ??
    toNonEmptyString(record.merchant_user_uid) ??
    toNonEmptyString(record.owner_uid) ??
    toNonEmptyString(record.merchantId);
  if (singleId) {
    linkedIds.add(singleId);
  }

  for (const id of parseStringList(record.merchant_uids)) {
    linkedIds.add(id);
  }
  for (const id of parseStringList(record.merchant_ids)) {
    linkedIds.add(id);
  }
  for (const id of parseStringList(record.linked_merchant_uids)) {
    linkedIds.add(id);
  }

  const linkedCountCandidate = firstFiniteNumber([
    record.merchant_count,
    record.linked_merchants_count,
    record.merchantLinkedCount,
  ]);
  const linkedCount = linkedIds.size > 0
    ? linkedIds.size
    : linkedCountCandidate !== null
      ? Math.max(0, Math.floor(linkedCountCandidate))
      : null;

  if (linkedCount !== null && linkedCount > 0) {
    return {
      status: "linked",
      summary:
        linkedCount === 1
          ? "عدد حسابات التاجر المرتبطة: 1."
          : `عدد حسابات التاجر المرتبطة: ${linkedCount}.`,
      linkedCount,
    };
  }

  if (record.merchant_linked === false || linkedCount === 0) {
    return {
      status: "unlinked",
      summary: "لا يوجد حساب تاجر مرتبط.",
      linkedCount: 0,
    };
  }

  return {
    status: "unknown",
    summary: "ملخص ربط التاجر غير متاح في القراءة الحالية.",
    linkedCount: null,
  };
}

function buildFilterOptions(items: VenueDirectoryItem[]): VenueDirectoryFilterOptions {
  const cities = new Set<string>();
  const categories = new Set<string>();

  for (const item of items) {
    if (item.city) {
      cities.add(item.city);
    }
    for (const category of item.categories) {
      if (category.trim().length > 0) {
        categories.add(category.trim());
      }
    }
  }

  return {
    cities: Array.from(cities).sort((a, b) => a.localeCompare(b)),
    categories: Array.from(categories).sort((a, b) => a.localeCompare(b)),
  };
}

function buildDirectorySummary(items: VenueDirectoryItem[]): VenueDirectorySummary {
  const summary: VenueDirectorySummary = {
    totalVenues: items.length,
    readiness: {
      ready: 0,
      warning: 0,
      fail: 0,
      unknown: 0,
    },
    wallet: {
      active: 0,
      low_balance: 0,
      inactive: 0,
      unknown: 0,
    },
    merchantLinks: {
      linked: 0,
      unlinked: 0,
      unknown: 0,
    },
    subscriptions: {
      active: 0,
      expired: 0,
      paused: 0,
    },
    visibility: {
      visible: 0,
      hidden: 0,
    },
    operational: {
      active: 0,
      suspended: 0,
      archived: 0,
    },
  };

  for (const item of items) {
    summary.readiness[item.readinessStatus] += 1;
    summary.wallet[item.walletStatus] += 1;
    summary.merchantLinks[item.merchantLinkStatus] += 1;
    summary.subscriptions[item.subscriptionStatus] += 1;
    summary.visibility[item.visibilityStatus] += 1;
    summary.operational[item.operationalStatus] += 1;
  }

  return summary;
}

function buildFixtureVenueItem(venueId: string, index: number): VenueDirectoryItem {
  const normalized = venueId.toLowerCase();
  const city = normalized.includes("nablus")
    ? "Nablus"
    : normalized.includes("jerusalem")
      ? "Jerusalem"
      : normalized.includes("bethlehem")
        ? "Bethlehem"
        : normalized.includes("amman")
          ? "Amman"
          : "Ramallah";

  const categories = normalized.includes("cafe")
    ? ["cafe", "coffee"]
    : normalized.includes("pizza")
      ? ["restaurant", "pizza"]
      : normalized.includes("bakery")
        ? ["bakery"]
        : ["restaurant", "general"];

  const readinessStatus: VenueDirectoryItem["readinessStatus"] =
    index % 5 === 0 ? "warning" : "ready";

  const walletStatus: VenueDirectoryItem["walletStatus"] =
    index % 4 === 0 ? "low_balance" : "active";

  const merchantLinkStatus: VenueDirectoryItem["merchantLinkStatus"] =
    index % 6 === 0 ? "unlinked" : "linked";

  const balance = walletStatus === "low_balance" ? 6 : 150 + index * 12;

  return {
    venueId,
    venueName: `Venue ${venueId.slice(-8)}`,
    venueNameEn: "",
    city,
    lat: null,
    lng: null,
    categories,
    phone: index % 3 === 0 ? null : `0599000${String(index).padStart(3, "0")}`,
    readinessStatus,
    readinessSummary:
      readinessStatus === "ready"
        ? "Core venue profile fields are available."
        : "Venue profile is partially populated.",
    walletStatus,
    walletSummary:
      walletStatus === "low_balance"
        ? `Low balance: ${formatCurrency(balance, "ILS")} (threshold ${formatCurrency(10, "ILS")}).`
        : `Balance: ${formatCurrency(balance, "ILS")}.`,
    walletBalance: balance,
    walletCurrency: "ILS",
    merchantLinkStatus,
    merchantLinkSummary:
      merchantLinkStatus === "linked"
        ? "Linked merchant account: 1."
        : "No merchant account is linked.",
    merchantLinkedCount: merchantLinkStatus === "linked" ? 1 : 0,
    subscriptionStatus:
      index % 9 === 0 ? "expired" : index % 7 === 0 ? "paused" : "active",
    visibilityStatus: index % 5 === 0 ? "hidden" : "visible",
    operationalStatus: index % 11 === 0 ? "suspended" : "active",
    workspacePath: `/admin/venues/${encodeURIComponent(venueId)}`,
  };
}

function resolveFixtureVenueIds(env: Record<string, string | undefined>): string[] {
  const configured = env.WAIN_VENUE_DIRECTORY_IDS?.trim();
  if (!configured) {
    return DEFAULT_VENUE_IDS;
  }

  const ids = configured
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  return ids.length > 0 ? ids : DEFAULT_VENUE_IDS;
}

function sortVenueItems(items: VenueDirectoryItem[]): VenueDirectoryItem[] {
  return [...items].sort((a, b) => a.venueName.localeCompare(b.venueName));
}

function parseStringList(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .map((entry) => String(entry).trim())
      .filter((entry) => entry.length > 0);
  }

  if (typeof value === "string") {
    return value
      .split(",")
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0);
  }

  return [];
}

function normalizeReadinessStatus(
  value: string | undefined,
): VenueDirectoryItem["readinessStatus"] | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "ready" || normalized === "pass") {
    return "ready";
  }
  if (normalized === "warning" || normalized === "warn") {
    return "warning";
  }
  if (normalized === "fail" || normalized === "blocked" || normalized === "inactive") {
    return "fail";
  }
  if (normalized === "unknown") {
    return "unknown";
  }

  return null;
}

function normalizeWalletStatus(
  value: string | undefined,
): VenueDirectoryItem["walletStatus"] | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "active" || normalized === "ready") {
    return "active";
  }
  if (normalized === "low_balance" || normalized === "warning" || normalized === "warn") {
    return "low_balance";
  }
  if (normalized === "inactive" || normalized === "disabled" || normalized === "blocked") {
    return "inactive";
  }
  if (normalized === "unknown") {
    return "unknown";
  }

  return null;
}

function normalizeVenueSubscriptionStatus(
  value: string | undefined,
): VenueDirectoryItem["subscriptionStatus"] | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "active" || normalized === "expired" || normalized === "paused") {
    return normalized;
  }

  return null;
}

function normalizeVenueVisibilityStatus(
  value: string | undefined,
): VenueDirectoryItem["visibilityStatus"] | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "visible" || normalized === "hidden") {
    return normalized;
  }

  return null;
}

function normalizeVenueOperationalStatus(
  value: string | undefined,
): VenueDirectoryItem["operationalStatus"] | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (
    normalized === "active" ||
    normalized === "suspended" ||
    normalized === "archived"
  ) {
    return normalized;
  }

  return null;
}

function normalizeCurrency(value: string | undefined): "ILS" | "USD" {
  return value?.toUpperCase() === "USD" ? "USD" : "ILS";
}

function parseJsonObject(raw: string): Record<string, unknown> | null {
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return null;
    }
    return parsed as Record<string, unknown>;
  } catch {
    return null;
  }
}

function normalizeIsoDate(raw: unknown, now: () => Date): string {
  if (typeof raw === "string" && raw.trim().length > 0) {
    const date = new Date(raw.trim());
    if (!Number.isNaN(date.getTime())) {
      return date.toISOString();
    }
  }
  return now().toISOString();
}

function parsePositiveInt(raw: unknown): number | undefined {
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return undefined;
  }
  const parsed = Number.parseInt(raw.trim(), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

function firstFiniteNumber(values: unknown[]): number | null {
  for (const value of values) {
    const n = toFiniteNumber(value);
    if (n !== null) {
      return n;
    }
  }
  return null;
}

function toFiniteNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  return value as Record<string, unknown>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function normalizeSearch(value: string | null | undefined): string {
  if (!value) {
    return "";
  }
  return value.trim().toLowerCase();
}

function normalizeError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}
