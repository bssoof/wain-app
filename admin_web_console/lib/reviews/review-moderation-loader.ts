import { createFinanceCallableInvokerFromEnv } from "@/lib/finance/finance-command-transport";
import {
  FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
  resolveFixtureFallbackPolicy,
} from "@/lib/admin/fixture-fallback-policy";

import type {
  ReviewModerationItem,
  ReviewModerationSnapshot,
  ReviewModerationStatus,
} from "./review-moderation-models";

const DEFAULT_STALE_AFTER_MS = 5 * 60 * 1000;
const CALLABLE_CHANNEL = "callable:listVenueReviewsForAdmin";
const FIXTURE_CHANNEL = "development_fixture";
const FIXTURE_BLOCKED_CHANNEL = "fixture_fallback_disabled";
const DEFAULT_REVIEWS_SHARED_CACHE_TTL_MS = 30_000;
const MAX_REVIEWS_SHARED_CACHE_SIZE = 16;

type ReviewSnapshotCacheEntry = {
  value: ReviewModerationSnapshot;
  expiresAt: number;
};

const g = globalThis as any;
g.reviewModerationSnapshotCache ??= new Map<string, ReviewSnapshotCacheEntry>();
const reviewModerationSnapshotCache: Map<string, ReviewSnapshotCacheEntry> =
  g.reviewModerationSnapshotCache;

export function __resetReviewModerationSnapshotCacheForTests(): void {
  reviewModerationSnapshotCache.clear();
}

export async function loadReviewModerationSnapshot(options?: {
  env?: Record<string, string | undefined>;
  now?: () => Date;
}) {
  const _t0 = performance.now();
  const env = options?.env ?? process.env;
  const nowFn = options?.now ?? (() => new Date());
  const sharedCacheConfig = resolveReviewsSharedCacheConfig(env, options);
  const cachedSnapshot = readReviewSnapshotFromCache(sharedCacheConfig.key);
  if (sharedCacheConfig.enabled && cachedSnapshot) {
    console.log(
      `[PERF] loadReviewModerationSnapshot: ${(performance.now() - _t0).toFixed(0)}ms (channel: cache_hit)`,
    );
    return cachedSnapshot;
  }

  const finalize = (snapshot: ReviewModerationSnapshot, channel?: string) => {
    writeReviewSnapshotToCache(sharedCacheConfig, snapshot);
    console.log(
      `[PERF] loadReviewModerationSnapshot: ${(performance.now() - _t0).toFixed(0)}ms (channel: ${channel ?? snapshot.source})`,
    );
    return snapshot;
  };

  const staleAfterMs =
    parsePositiveInt(env.WAIN_REVIEWS_STALE_AFTER_MS) ?? DEFAULT_STALE_AFTER_MS;
  const fetchedAt = nowFn();
  const fixtureFallbackPolicy = resolveFixtureFallbackPolicy(env);

  const resolution = createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      env.NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      env.NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
  });

  if (resolution.ok) {
    try {
      const raw = asRecord(
        await resolution.invokeCallable("listVenueReviewsForAdmin", {
          limit: 25,
        }),
      );
      return finalize(
        normalizeCallableSnapshot(raw, fetchedAt, staleAfterMs),
        CALLABLE_CHANNEL,
      );
    } catch (error) {
      const firestoreSnapshot = await loadReviewSnapshotFromFirestore(fetchedAt);
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
          message: `Reviews callable read failed: ${normalizeError(error)}`,
          generatedAt: fetchedAt,
        }),
        "fixture_fallback",
      );
    }
  }

  const firestoreSnapshot = await loadReviewSnapshotFromFirestore(fetchedAt);
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
      message: "Reviews moderation surface is using fixture data until callable transport is configured.",
    }),
    "fixture",
  );
}

function resolveReviewsSharedCacheConfig(
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

  const explicitMode = env.WAIN_REVIEWS_SHARED_CACHE;
  const enabledByEnv = explicitMode === "1" || explicitMode === undefined;
  const enabledInRuntime = explicitMode === "1" || !isTestRuntime;
  const enabledByOptions = explicitMode === "1" || !options?.now;
  const ttlMs =
    parsePositiveInt(env.WAIN_REVIEWS_SHARED_CACHE_TTL_MS) ??
    DEFAULT_REVIEWS_SHARED_CACHE_TTL_MS;

  return {
    enabled: enabledByEnv && enabledInRuntime && enabledByOptions && ttlMs > 0,
    key: buildReviewsSharedCacheKey(env),
    ttlMs,
  };
}

function buildReviewsSharedCacheKey(
  env: Record<string, string | undefined>,
): string {
  const fallbackPolicy = resolveFixtureFallbackPolicy(env);
  const relevantEntries = Object.entries(env)
    .filter(
      ([key]) =>
        key.startsWith("WAIN_REVIEWS_") ||
        key.startsWith("NEXT_PUBLIC_WAIN_CONTENT_") ||
        key.startsWith("NEXT_PUBLIC_WAIN_FINANCE_"),
    )
    .sort(([left], [right]) => left.localeCompare(right));

  return JSON.stringify([
    ...relevantEntries,
    ["fixture_fallback_policy", fallbackPolicy.cacheKey],
  ]);
}

function readReviewSnapshotFromCache(
  key: string,
): ReviewModerationSnapshot | null {
  const cached = reviewModerationSnapshotCache.get(key);
  if (!cached) {
    return null;
  }

  if (cached.expiresAt <= Date.now()) {
    reviewModerationSnapshotCache.delete(key);
    return null;
  }

  return cached.value;
}

function writeReviewSnapshotToCache(
  config: {
    enabled: boolean;
    key: string;
    ttlMs: number;
  },
  snapshot: ReviewModerationSnapshot,
): void {
  if (!config.enabled || config.ttlMs <= 0) {
    return;
  }

  if (
    !reviewModerationSnapshotCache.has(config.key) &&
    reviewModerationSnapshotCache.size >= MAX_REVIEWS_SHARED_CACHE_SIZE
  ) {
    const oldestKey = reviewModerationSnapshotCache.keys().next().value;
    if (oldestKey) {
      reviewModerationSnapshotCache.delete(oldestKey);
    }
  }

  reviewModerationSnapshotCache.set(config.key, {
    value: snapshot,
    expiresAt: Date.now() + config.ttlMs,
  });
}

async function loadReviewSnapshotFromFirestore(
  fetchedAt: Date,
): Promise<ReviewModerationSnapshot | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const { adminDb } = await import("@/lib/firebase/server");
    const checkedAt = fetchedAt.toISOString();
    const reviewsSnap = await adminDb.collectionGroup("reviews").limit(25).get();

    const venueIds = Array.from(
      new Set(
        reviewsSnap.docs
          .map((doc) => doc.ref.parent.parent?.id)
          .filter(
            (venueId): venueId is string =>
              typeof venueId === "string" && venueId.trim().length > 0,
          ),
      ),
    );

    const venueNameMap = new Map<string, string>();
    if (venueIds.length > 0) {
      const venueDocs = await adminDb.getAll(
        ...venueIds.map((venueId) => adminDb.collection("venues").doc(venueId)),
      );
      for (const venueDoc of venueDocs) {
        const row = venueDoc.data() ?? {};
        const venueName =
          toNullableString(row.name_ar) ??
          toNullableString(row.name) ??
          toNullableString(row.name_en) ??
          venueDoc.id;
        venueNameMap.set(venueDoc.id, venueName);
      }
    }

    const items = reviewsSnap.docs
      .map((doc) => {
        const row = (doc.data() ?? {}) as Record<string, unknown>;
        const parentVenueId = doc.ref.parent.parent?.id;
        const venueId =
          (typeof parentVenueId === "string" && parentVenueId.trim().length > 0
            ? parentVenueId
            : toNullableString(row.venue_id)) ??
          "";

        const normalizedInput: Record<string, unknown> = {
          id: doc.id,
          ...row,
          venueId,
          venueName: venueId ? venueNameMap.get(venueId) ?? venueId : null,
        };

        return normalizeItem(normalizedInput, checkedAt);
      })
      .filter((item): item is ReviewModerationItem => Boolean(item));

    return {
      generatedAt: checkedAt,
      source: "firestore:reviews",
      freshnessNote: "Reviews snapshot was loaded directly from Firestore.",
      state: items.length === 0 ? "empty" : "success",
      message: items.length === 0 ? "No reviews matched the current moderation surface." : undefined,
      filtersApplied: {
        venueId: null,
        statuses: [],
        limit: 25,
      },
      items,
    };
  } catch {
    return null;
  }
}

function normalizeCallableSnapshot(
  raw: Record<string, any> | undefined,
  fetchedAt: Date,
  staleAfterMs: number,
): ReviewModerationSnapshot {
  const checkedAt = toIsoDate(raw?.checkedAt, fetchedAt);
  const items = Array.isArray(raw?.items)
    ? raw.items
        .map((item) => normalizeItem(asRecord(item), checkedAt))
        .filter((item): item is ReviewModerationItem => Boolean(item))
    : [];
  const state =
    items.length === 0
      ? "empty"
      : fetchedAt.getTime() - Date.parse(checkedAt) > staleAfterMs
        ? "stale"
        : "success";

  return {
    generatedAt: checkedAt,
    source: CALLABLE_CHANNEL,
    freshnessNote:
      state === "stale"
        ? "Reviews callable data is older than the configured freshness window."
        : "Reviews callable data is within the expected freshness window.",
    state,
    message: items.length === 0 ? "No reviews matched the current moderation surface." : undefined,
    filtersApplied: {
      venueId: toNullableString(raw?.filtersApplied?.venueId),
      statuses: normalizeStatuses(raw?.filtersApplied?.statuses),
      limit:
        typeof raw?.filtersApplied?.limit === "number"
          ? raw.filtersApplied.limit
          : 25,
    },
    items,
  };
}

function buildFixtureSnapshot(args: {
  source: string;
  state: ReviewModerationSnapshot["state"];
  generatedAt: Date;
  message?: string;
}): ReviewModerationSnapshot {
  return {
    generatedAt: args.generatedAt.toISOString(),
    source: args.source,
    freshnessNote:
      args.state === "stale"
        ? "Fixture data is stale and should not be treated as a live moderation feed."
        : "Fixture data is being used for the reviews moderation baseline.",
    state: args.state,
    message: args.message,
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 25,
    },
    items: [
      {
        id: "review_fixture_1",
        venueId: "venue-a",
        venueName: "Venue A",
        authorName: "مراجع تجريبي",
        rating: 2,
        status: "flagged",
        snippet: "مراجعة تجريبية تتطلب متابعة من فريق الإشراف.",
        createdAt: args.generatedAt.toISOString(),
        moderationReason: "manual_review",
        moderationNote: "سجل تجريبي أساسي.",
        moderatedAt: args.generatedAt.toISOString(),
        moderatedByUid: "fixture",
      },
    ],
  };
}

function buildUnavailableSnapshot(args: {
  source: string;
  generatedAt: Date;
  message: string;
}): ReviewModerationSnapshot {
  return {
    generatedAt: args.generatedAt.toISOString(),
    source: args.source,
    freshnessNote: "Reviews moderation source is unavailable and fixture fallback is disabled.",
    state: "unavailable",
    message: args.message,
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 25,
    },
    items: [],
  };
}

function normalizeItem(
  item: Record<string, any> | undefined,
  fallbackIso: string,
): ReviewModerationItem | null {
  if (!item) {
    return null;
  }

  const id = toNullableString(item.id);
  const venueId = toNullableString(item.venueId ?? item.venue_id);
  if (!id || !venueId) {
    return null;
  }

  return {
    id,
    venueId,
    venueName:
      toNullableString(item.venueName ?? item.venue_name) ?? venueId,
    authorName:
      toNullableString(item.authorName ?? item.author_name) ?? "زائر",
    rating:
      typeof item.rating === "number" && Number.isFinite(item.rating)
        ? item.rating
        : 0,
    status: normalizeStatus(item.status),
    snippet:
      toNullableString(item.snippet) ?? "لا يوجد نص مختصر لهذه المراجعة.",
    createdAt: toIsoDate(item.createdAt ?? item.created_at, new Date(fallbackIso)),
    moderationReason:
      toNullableString(item.moderationReason ?? item.moderation_reason),
    moderationNote:
      toNullableString(item.moderationNote ?? item.moderation_note),
    moderatedAt: toNullableString(item.moderatedAt ?? item.moderated_at),
    moderatedByUid:
      toNullableString(item.moderatedByUid ?? item.moderated_by_uid),
  };
}

function normalizeStatuses(value: unknown): ReviewModerationStatus[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter(
    (entry): entry is ReviewModerationStatus =>
      entry === "published" || entry === "flagged" || entry === "hidden",
  );
}

function normalizeStatus(value: unknown): ReviewModerationStatus {
  return value === "hidden" || value === "flagged" ? value : "published";
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

function toNullableString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}
