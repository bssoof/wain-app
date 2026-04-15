import { mapBackendErrorToTransportError } from "@/lib/finance/finance-command-transport";
import type {
  FinanceCallableInvoker,
  FinanceTransportErrorStatus,
} from "@/lib/finance/finance-command-transport";

import {
  type ContentModerationReadState,
  type ContentAdminState,
  type OfferAdminItem,
  type OfferModerationSnapshot,
  type StoryAdminItem,
  type StoryModerationSnapshot,
} from "./content-models";
import { createContentCallableInvokerFromEnv } from "./content-callable-env";

const DEFAULT_STALE_AFTER_MS = 5 * 60 * 1000;
const OFFERS_CHANNEL = "callable:listOffersForAdmin";
const STORIES_CHANNEL = "callable:listStoriesForAdmin";
const FIXTURE_CHANNEL = "development_fixture";
const DEFAULT_CONTENT_SHARED_CACHE_TTL_MS = 10_000;
const MAX_CONTENT_SHARED_CACHE_SIZE = 32;

type ContentModerationSnapshotLike<TItem extends OfferAdminItem | StoryAdminItem> = {
  generatedAt: string;
  source: string;
  freshnessNote: string;
  state: ContentModerationReadState;
  message?: string;
  filtersApplied: {
    venueId: string | null;
    statuses: ContentAdminState[];
    limit: number;
  };
  items: TItem[];
};

type ContentSnapshotCacheEntry = {
  value: ContentModerationSnapshotLike<OfferAdminItem | StoryAdminItem>;
  expiresAt: number;
};

const g = globalThis as any;
g.contentModerationSnapshotCache ??= new Map<string, ContentSnapshotCacheEntry>();
const contentModerationSnapshotCache: Map<string, ContentSnapshotCacheEntry> =
  g.contentModerationSnapshotCache;

export function __resetContentModerationSnapshotCacheForTests(): void {
  contentModerationSnapshotCache.clear();
}

export async function loadOfferModerationSnapshot(options?: {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
}): Promise<OfferModerationSnapshot> {
  const _t0 = performance.now();
  const result = await loadContentSnapshot({
    channel: OFFERS_CHANNEL,
    callableName: "listOffersForAdmin",
    normalizeItem: normalizeOfferItem,
    buildFixtureItems: buildOfferFixtureItems,
    loadFirestoreFallback: loadOfferSnapshotFromFirestore,
    options,
  });
  console.log(`[PERF] loadOfferModerationSnapshot: ${(performance.now() - _t0).toFixed(0)}ms (source: ${result.source})`);
  return result;
}

export async function loadStoryModerationSnapshot(options?: {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
}): Promise<StoryModerationSnapshot> {
  const _t0 = performance.now();
  const result = await loadContentSnapshot({
    channel: STORIES_CHANNEL,
    callableName: "listStoriesForAdmin",
    normalizeItem: normalizeStoryItem,
    buildFixtureItems: buildStoryFixtureItems,
    loadFirestoreFallback: loadStorySnapshotFromFirestore,
    options,
  });
  console.log(`[PERF] loadStoryModerationSnapshot: ${(performance.now() - _t0).toFixed(0)}ms (source: ${result.source})`);
  return result;
}

async function loadContentSnapshot<TItem extends OfferAdminItem | StoryAdminItem>(args: {
  channel: string;
  callableName: string;
  normalizeItem: (value: Record<string, unknown> | undefined, fallbackIso: string) => TItem | null;
  buildFixtureItems: (generatedAtIso: string) => TItem[];
  loadFirestoreFallback?: (
    fetchedAt: Date,
    staleAfterMs: number,
  ) => Promise<ContentModerationSnapshotLike<TItem> | null>;
  options?: {
    env?: Record<string, string | undefined>;
    now?: () => Date;
    invokeCallable?: FinanceCallableInvoker;
  };
  }): Promise<ContentModerationSnapshotLike<TItem>> {
  const env = args.options?.env ?? process.env;
  const nowFn = args.options?.now ?? (() => new Date());
  const sharedCacheConfig = resolveContentSharedCacheConfig(
    env,
    args.options,
    args.channel,
  );
  const cachedSnapshot = readContentSnapshotFromCache<TItem>(sharedCacheConfig.key);
  if (sharedCacheConfig.enabled && cachedSnapshot) {
    return cachedSnapshot;
  }

  const finalize = (snapshot: ContentModerationSnapshotLike<TItem>) => {
    writeContentSnapshotToCache(sharedCacheConfig, snapshot);
    return snapshot;
  };

  const hasExplicitInvokeCallable = typeof args.options?.invokeCallable === "function";
  const staleAfterMs =
    parsePositiveInt(env.WAIN_CONTENT_STALE_AFTER_MS) ?? DEFAULT_STALE_AFTER_MS;
  const fetchedAt = nowFn();
  const invokeCallable =
    args.options?.invokeCallable ?? resolveCallableFromEnv(env);

  if (invokeCallable) {
    try {
      const raw = asRecord(
        await invokeCallable(args.callableName, {
          limit: 50,
        }),
      );
      return finalize(
        normalizeCallableSnapshot(
          raw,
          fetchedAt,
          staleAfterMs,
          args.channel,
          args.normalizeItem,
        ),
      );
    } catch (error) {
      if (!hasExplicitInvokeCallable) {
        const firestoreSnapshot = await args.loadFirestoreFallback?.(
          fetchedAt,
          staleAfterMs,
        );
        if (firestoreSnapshot) {
          return finalize(firestoreSnapshot);
        }
      }

      const transportError = mapBackendErrorToTransportError(error);
      if (!shouldFallbackToFixture(transportError.status)) {
        return finalize(
          buildUnavailableSnapshot({
            source: args.channel,
            generatedAt: fetchedAt,
            message: `${args.callableName} failed: ${transportError.message}`,
          }),
        );
      }

      return finalize(
        buildFixtureSnapshot({
          source: `${args.channel} -> ${FIXTURE_CHANNEL}`,
          state: "stale",
          generatedAt: fetchedAt,
          message: `${args.callableName} failed: ${transportError.message}`,
          items: args.buildFixtureItems(fetchedAt.toISOString()),
        }),
      );
    }
  }

  const firestoreSnapshot = await args.loadFirestoreFallback?.(
    fetchedAt,
    staleAfterMs,
  );
  if (firestoreSnapshot) {
    return finalize(firestoreSnapshot);
  }

  return finalize(
    buildFixtureSnapshot({
      source: FIXTURE_CHANNEL,
      state: "stale",
      generatedAt: fetchedAt,
      message: `${args.callableName} is using explicitly labeled fixture data until content callable transport is configured.`,
      items: args.buildFixtureItems(fetchedAt.toISOString()),
    }),
  );
}

function resolveContentSharedCacheConfig(
  env: Record<string, string | undefined>,
  options:
    | {
        now?: () => Date;
        invokeCallable?: FinanceCallableInvoker;
      }
    | undefined,
  channel: string,
): {
  enabled: boolean;
  key: string;
  ttlMs: number;
} {
  const isTestRuntime =
    process.env.NODE_ENV === "test" ||
    process.env.VITEST === "true" ||
    process.env.WAIN_TEST_MODE === "1";

  const explicitMode = env.WAIN_CONTENT_MODERATION_SHARED_CACHE;
  const enabledByEnv = explicitMode === "1" || explicitMode === undefined;
  const enabledInRuntime = explicitMode === "1" || !isTestRuntime;
  const enabledByOptions =
    explicitMode === "1" || (!options?.now && !options?.invokeCallable);
  const ttlMs =
    parsePositiveInt(env.WAIN_CONTENT_MODERATION_SHARED_CACHE_TTL_MS) ??
    DEFAULT_CONTENT_SHARED_CACHE_TTL_MS;

  return {
    enabled: enabledByEnv && enabledInRuntime && enabledByOptions && ttlMs > 0,
    key: buildContentSharedCacheKey(channel, env),
    ttlMs,
  };
}

function buildContentSharedCacheKey(
  channel: string,
  env: Record<string, string | undefined>,
): string {
  const relevantEntries = Object.entries(env)
    .filter(
      ([key]) =>
        key.startsWith("WAIN_CONTENT_") ||
        key.startsWith("NEXT_PUBLIC_WAIN_CONTENT_") ||
        key.startsWith("NEXT_PUBLIC_WAIN_FINANCE_"),
    )
    .sort(([left], [right]) => left.localeCompare(right));

  return [
    channel,
    ...relevantEntries.map(([key, value]) => `${key}=${value ?? ""}`),
  ].join("|");
}

function readContentSnapshotFromCache<
  TItem extends OfferAdminItem | StoryAdminItem,
>(key: string): ContentModerationSnapshotLike<TItem> | null {
  const entry = contentModerationSnapshotCache.get(key);
  if (!entry) {
    return null;
  }

  if (entry.expiresAt <= Date.now()) {
    contentModerationSnapshotCache.delete(key);
    return null;
  }

  return entry.value as ContentModerationSnapshotLike<TItem>;
}

function writeContentSnapshotToCache<
  TItem extends OfferAdminItem | StoryAdminItem,
>(
  config: { enabled: boolean; key: string; ttlMs: number },
  snapshot: ContentModerationSnapshotLike<TItem>,
): void {
  if (!config.enabled) {
    return;
  }

  contentModerationSnapshotCache.set(config.key, {
    value: snapshot,
    expiresAt: Date.now() + config.ttlMs,
  });

  if (contentModerationSnapshotCache.size > MAX_CONTENT_SHARED_CACHE_SIZE) {
    const oldestKey = contentModerationSnapshotCache.keys().next().value as
      | string
      | undefined;
    if (oldestKey) {
      contentModerationSnapshotCache.delete(oldestKey);
    }
  }
}

function normalizeCallableSnapshot<TItem extends OfferAdminItem | StoryAdminItem>(
  raw: Record<string, any> | undefined,
  fetchedAt: Date,
  staleAfterMs: number,
  channel: string,
  normalizeItem: (value: Record<string, unknown> | undefined, fallbackIso: string) => TItem | null,
): ContentModerationSnapshotLike<TItem> {
  const generatedAt = toIsoDate(raw?.checkedAt, fetchedAt);
  const rawItems = Array.isArray(raw?.items) ? raw.items : [];
  const items = rawItems
    .map((item) => normalizeItem(asRecord(item), generatedAt))
    .filter((item): item is TItem => Boolean(item));

  const hasMalformedRows = rawItems.length > 0 && items.length === 0;
  const state = hasMalformedRows
    ? "unavailable"
    : items.length === 0
      ? "empty"
      : fetchedAt.getTime() - Date.parse(generatedAt) > staleAfterMs
        ? "stale"
        : "success";

  return {
    generatedAt,
    source: channel,
    freshnessNote:
      state === "stale"
        ? "Content moderation data is older than the configured freshness window."
        : "Content moderation data is within the expected freshness window.",
    state,
    message: hasMalformedRows
      ? "Content moderation payload was malformed and could not be normalized."
      : items.length === 0
        ? "No content items matched the current moderation surface."
        : undefined,
    filtersApplied: {
      venueId: toNullableString(raw?.filtersApplied?.venueId),
      statuses: normalizeStatuses(raw?.filtersApplied?.statuses),
      limit:
        typeof raw?.filtersApplied?.limit === "number"
          ? raw.filtersApplied.limit
          : 50,
    },
    items,
  };
}

function buildFixtureSnapshot<TItem extends OfferAdminItem | StoryAdminItem>(args: {
  source: string;
  state: ContentModerationReadState;
  generatedAt: Date;
  message?: string;
  items: TItem[];
}): ContentModerationSnapshotLike<TItem> {
  return {
    generatedAt: args.generatedAt.toISOString(),
    source: args.source,
    freshnessNote:
      args.state === "stale"
        ? "Fixture data is stale and should not be treated as a live moderation feed."
        : "Fixture data is being used for the content moderation baseline.",
    state: args.state,
    message: args.message,
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 50,
    },
    items: args.items,
  };
}

function buildUnavailableSnapshot<TItem extends OfferAdminItem | StoryAdminItem>(args: {
  source: string;
  generatedAt: Date;
  message: string;
}): ContentModerationSnapshotLike<TItem> {
  return {
    generatedAt: args.generatedAt.toISOString(),
    source: args.source,
    freshnessNote:
      "Callable transport rejected the moderation read, so no fixture fallback was used.",
    state: "unavailable",
    message: args.message,
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 50,
    },
    items: [],
  };
}

function buildOfferFixtureItems(generatedAtIso: string): OfferAdminItem[] {
  return [
    {
      id: "offer_fixture_1",
      venueId: "venue_fixture_1",
      venueName: "Fixture Venue",
      title: "Fixture Offer",
      description: "Fallback content moderation row.",
      adminState: "pending",
      isActive: true,
      isFeatured: false,
      moderationReason: "other",
      moderationNote: "Fixture fallback row.",
      moderatedAt: undefined,
      createdAt: generatedAtIso,
      updatedAt: generatedAtIso,
    },
  ];
}

function buildStoryFixtureItems(generatedAtIso: string): StoryAdminItem[] {
  return [
    {
      id: "story_fixture_1",
      venueId: "venue_fixture_1",
      venueName: "Fixture Venue",
      caption: "Fixture story moderation row.",
      adminState: "flagged",
      isActive: false,
      isPromoted: false,
      moderationReason: "other",
      moderationNote: "Fixture fallback row.",
      moderatedAt: generatedAtIso,
      createdAt: generatedAtIso,
      updatedAt: generatedAtIso,
    },
  ];
}

async function loadOfferSnapshotFromFirestore(
  fetchedAt: Date,
  staleAfterMs: number,
): Promise<ContentModerationSnapshotLike<OfferAdminItem> | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const { adminDb } = await import("@/lib/firebase/server");
    const limit = 50;
    const scanLimit = 200;
    const offersSnap = await adminDb.collection("offers").limit(scanLimit).get();

    const venueNames = await loadVenueNames(
      adminDb,
      offersSnap.docs
        .map((doc) => toNullableString(asRecord(doc.data())?.venue_id))
        .filter((value): value is string => Boolean(value)),
    );

    const fallbackIso = fetchedAt.toISOString();
    const items: OfferAdminItem[] = offersSnap.docs
      .map<OfferAdminItem | null>((doc) => {
        const row = asRecord(doc.data());
        if (!row) {
          return null;
        }
        const venueId = toNullableString(row.venue_id);
        if (!venueId) {
          return null;
        }

        const title =
          toNullableString(row.title_ar ?? row.title ?? row.name) ?? doc.id;
        const createdAt = toIsoDateFromFirestore(row.created_at, fallbackIso);
        const updatedAt = toIsoDateFromFirestore(
          row.updated_at ?? row.created_at,
          fallbackIso,
        );

        return {
          id: doc.id,
          venueId,
          venueName: venueNames.get(venueId) ?? venueId,
          title,
          description:
            toNullableString(row.description_ar ?? row.description) ?? undefined,
          adminState: normalizeAdminState(row.admin_state),
          isActive: row.is_active !== false,
          isFeatured: row.is_featured === true || row.isFeatured === true,
          featuredUntil: toOptionalIsoDateFromFirestore(
            row.featured_until ?? row.featuredUntil,
          ),
          startAt: toOptionalIsoDateFromFirestore(row.start_at ?? row.starts_at),
          endAt: toOptionalIsoDateFromFirestore(row.end_at ?? row.ends_at),
          moderationReason: toNullableString(row.moderation_reason) ?? undefined,
          moderationNote: toNullableString(row.moderation_note) ?? undefined,
          moderatedAt: toOptionalIsoDateFromFirestore(row.moderated_at),
          createdAt,
          updatedAt,
        };
      })
      .filter((item): item is OfferAdminItem => item !== null)
      .sort((left, right) => Date.parse(right.updatedAt) - Date.parse(left.updatedAt))
      .slice(0, limit);

    const generatedAt = fetchedAt.toISOString();
    const state: ContentModerationReadState =
      items.length === 0
        ? "empty"
        : fetchedAt.getTime() - Date.parse(generatedAt) > staleAfterMs
          ? "stale"
          : "success";

    return {
      generatedAt,
      source: "firestore:offers",
      freshnessNote:
        state === "stale"
          ? "Content moderation data is older than the configured freshness window."
          : "Content moderation data is within the expected freshness window.",
      state,
      message:
        items.length === 0
          ? "No content items matched the current moderation surface."
          : undefined,
      filtersApplied: {
        venueId: null,
        statuses: [],
        limit,
      },
      items,
    };
  } catch {
    return null;
  }
}

async function loadStorySnapshotFromFirestore(
  fetchedAt: Date,
  staleAfterMs: number,
): Promise<ContentModerationSnapshotLike<StoryAdminItem> | null> {
  if (typeof window !== "undefined") {
    return null;
  }

  try {
    const { adminDb } = await import("@/lib/firebase/server");
    const limit = 50;
    const scanLimit = 200;
    const storiesSnap = await adminDb.collection("stories").limit(scanLimit).get();

    const venueNames = await loadVenueNames(
      adminDb,
      storiesSnap.docs
        .map((doc) => toNullableString(asRecord(doc.data())?.venue_id))
        .filter((value): value is string => Boolean(value)),
    );

    const fallbackIso = fetchedAt.toISOString();
    const items: StoryAdminItem[] = storiesSnap.docs
      .map<StoryAdminItem | null>((doc) => {
        const row = asRecord(doc.data());
        if (!row) {
          return null;
        }
        const venueId = toNullableString(row.venue_id);
        if (!venueId) {
          return null;
        }

        const caption =
          toNullableString(row.caption ?? row.text ?? row.caption_ar) ?? doc.id;
        const createdAt = toIsoDateFromFirestore(row.created_at, fallbackIso);
        const updatedAt = toIsoDateFromFirestore(
          row.updated_at ?? row.created_at,
          fallbackIso,
        );

        return {
          id: doc.id,
          venueId,
          venueName: venueNames.get(venueId) ?? venueId,
          caption,
          adminState: normalizeAdminState(row.admin_state),
          isActive: row.is_active !== false,
          isPromoted: row.is_promoted === true || row.isPromoted === true,
          promotedUntil: toOptionalIsoDateFromFirestore(
            row.promoted_until ?? row.promotedUntil,
          ),
          expiresAt: toOptionalIsoDateFromFirestore(
            row.expires_at ?? row.expire_at,
          ),
          mediaUrl:
            toNullableString(row.image_url ?? row.imageUrl ?? row.media_url) ??
            undefined,
          moderationReason: toNullableString(row.moderation_reason) ?? undefined,
          moderationNote: toNullableString(row.moderation_note) ?? undefined,
          moderatedAt: toOptionalIsoDateFromFirestore(row.moderated_at),
          createdAt,
          updatedAt,
        };
      })
      .filter((item): item is StoryAdminItem => item !== null)
      .sort((left, right) => Date.parse(right.updatedAt) - Date.parse(left.updatedAt))
      .slice(0, limit);

    const generatedAt = fetchedAt.toISOString();
    const state: ContentModerationReadState =
      items.length === 0
        ? "empty"
        : fetchedAt.getTime() - Date.parse(generatedAt) > staleAfterMs
          ? "stale"
          : "success";

    return {
      generatedAt,
      source: "firestore:stories",
      freshnessNote:
        state === "stale"
          ? "Content moderation data is older than the configured freshness window."
          : "Content moderation data is within the expected freshness window.",
      state,
      message:
        items.length === 0
          ? "No content items matched the current moderation surface."
          : undefined,
      filtersApplied: {
        venueId: null,
        statuses: [],
        limit,
      },
      items,
    };
  } catch {
    return null;
  }
}

async function loadVenueNames(
  adminDb: any,
  venueIds: string[],
): Promise<Map<string, string>> {
  const uniqueVenueIds = Array.from(new Set(venueIds));
  if (uniqueVenueIds.length === 0) {
    return new Map();
  }

  const refs = uniqueVenueIds.map((venueId) =>
    adminDb.collection("venues").doc(venueId),
  );
  const snaps = await adminDb.getAll(...refs);
  const names = new Map<string, string>();

  for (const snap of snaps) {
    if (!snap.exists) {
      continue;
    }
    const row = asRecord(snap.data());
    const name = toNullableString(row?.name_ar ?? row?.name ?? row?.title);
    names.set(snap.id, name ?? snap.id);
  }

  return names;
}

function normalizeOfferItem(
  item: Record<string, unknown> | undefined,
  fallbackIso: string,
): OfferAdminItem | null {
  if (!item) {
    return null;
  }

  const id = toNullableString(item.id);
  const venueId = toNullableString(item.venueId ?? item.venue_id);
  const title = toNullableString(item.title);
  if (!id || !venueId || !title) {
    return null;
  }

  return {
    id,
    venueId,
    venueName:
      toNullableString(item.venueName ?? item.venue_name) ?? venueId,
    title,
    description: toNullableString(item.description) ?? undefined,
    adminState: normalizeAdminState(item.adminState ?? item.admin_state),
    isActive: Boolean(item.isActive ?? item.is_active ?? false),
    isFeatured: Boolean(item.isFeatured ?? item.is_featured ?? false),
    featuredUntil:
      toNullableString(item.featuredUntil ?? item.featured_until) ?? undefined,
    startAt: toNullableString(item.startAt ?? item.start_at) ?? undefined,
    endAt: toNullableString(item.endAt ?? item.end_at) ?? undefined,
    moderationReason:
      toNullableString(item.moderationReason ?? item.moderation_reason) ??
      undefined,
    moderationNote:
      toNullableString(item.moderationNote ?? item.moderation_note) ?? undefined,
    moderatedAt:
      toNullableString(item.moderatedAt ?? item.moderated_at) ?? undefined,
    createdAt: toIsoDate(item.createdAt ?? item.created_at, new Date(fallbackIso)),
    updatedAt: toIsoDate(item.updatedAt ?? item.updated_at, new Date(fallbackIso)),
  };
}

function normalizeStoryItem(
  item: Record<string, unknown> | undefined,
  fallbackIso: string,
): StoryAdminItem | null {
  if (!item) {
    return null;
  }

  const id = toNullableString(item.id);
  const venueId = toNullableString(item.venueId ?? item.venue_id);
  const caption = toNullableString(item.caption);
  if (!id || !venueId || !caption) {
    return null;
  }

  return {
    id,
    venueId,
    venueName:
      toNullableString(item.venueName ?? item.venue_name) ?? venueId,
    caption,
    adminState: normalizeAdminState(item.adminState ?? item.admin_state),
    isActive: Boolean(item.isActive ?? item.is_active ?? false),
    isPromoted: Boolean(item.isPromoted ?? item.is_promoted ?? false),
    promotedUntil:
      toNullableString(item.promotedUntil ?? item.promoted_until) ?? undefined,
    expiresAt: toNullableString(item.expiresAt ?? item.expires_at) ?? undefined,
    mediaUrl: toNullableString(item.mediaUrl ?? item.media_url) ?? undefined,
    moderationReason:
      toNullableString(item.moderationReason ?? item.moderation_reason) ??
      undefined,
    moderationNote:
      toNullableString(item.moderationNote ?? item.moderation_note) ?? undefined,
    moderatedAt:
      toNullableString(item.moderatedAt ?? item.moderated_at) ?? undefined,
    createdAt: toIsoDate(item.createdAt ?? item.created_at, new Date(fallbackIso)),
    updatedAt: toIsoDate(item.updatedAt ?? item.updated_at, new Date(fallbackIso)),
  };
}

function resolveCallableFromEnv(
  env: Record<string, string | undefined>,
): FinanceCallableInvoker | null {
  const resolution = createContentCallableInvokerFromEnv(env);
  return resolution.ok ? resolution.invokeCallable : null;
}

function normalizeStatuses(value: unknown): ContentAdminState[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter(
    (entry): entry is ContentAdminState =>
      entry === "pending" ||
      entry === "approved" ||
      entry === "rejected" ||
      entry === "flagged" ||
      entry === "paused",
  );
}

function normalizeAdminState(value: unknown): ContentAdminState {
  return value === "approved" ||
    value === "rejected" ||
    value === "flagged" ||
    value === "paused"
    ? value
    : "pending";
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

function toIsoDateFromFirestore(value: unknown, fallbackIso: string): string {
  const parsed = parseFirestoreDate(value);
  if (parsed) {
    return parsed.toISOString();
  }
  return fallbackIso;
}

function toOptionalIsoDateFromFirestore(value: unknown): string | undefined {
  const parsed = parseFirestoreDate(value);
  return parsed ? parsed.toISOString() : undefined;
}

function parseFirestoreDate(value: unknown): Date | null {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return new Date(parsed);
    }
    return null;
  }

  if (!value || typeof value !== "object") {
    return null;
  }

  const row = value as {
    toDate?: () => Date;
    seconds?: unknown;
    _seconds?: unknown;
  };

  if (typeof row.toDate === "function") {
    const date = row.toDate();
    if (date instanceof Date && !Number.isNaN(date.getTime())) {
      return date;
    }
  }

  const seconds =
    typeof row.seconds === "number"
      ? row.seconds
      : typeof row._seconds === "number"
        ? row._seconds
        : null;
  if (seconds !== null && Number.isFinite(seconds)) {
    const date = new Date(seconds * 1000);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  return null;
}

function shouldFallbackToFixture(status: FinanceTransportErrorStatus): boolean {
  return status === 503;
}

function toNullableString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}
