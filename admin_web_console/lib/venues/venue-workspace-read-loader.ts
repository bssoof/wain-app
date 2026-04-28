import {
  createFinanceCallableInvokerFromEnv,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";
import {
  FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
  resolveFixtureFallbackPolicy,
} from "@/lib/admin/fixture-fallback-policy";

import type {
  VenueOfferItem,
  VenueReviewItem,
  VenueStoryItem,
  VenueWalletEntry,
  VenueWorkspaceContext,
  VenueWorkspaceSnapshot,
  VenueWorkspaceTabKey,
} from "./venue-workspace-models";
import type { VenueWorkspaceReadResult } from "./venue-workspace-read-types";

export type VenueWalletReadData = { entries: VenueWalletEntry[] };
export type VenueOffersReadData = { items: VenueOfferItem[] };
export type VenueStoriesReadData = { items: VenueStoryItem[] };
export type VenueReviewsReadData = { items: VenueReviewItem[] };

export type VenueWorkspaceReadBundle = {
  context: VenueWorkspaceContext;
  wallet: VenueWorkspaceReadResult<VenueWalletReadData>;
  offers: VenueWorkspaceReadResult<VenueOffersReadData>;
  stories: VenueWorkspaceReadResult<VenueStoriesReadData>;
  reviews: VenueWorkspaceReadResult<VenueReviewsReadData>;
};

export type VenueWorkspaceReadLoaderOptions = {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
};

const DEFAULT_STALE_AFTER_MS = 5 * 60 * 1000;
const FIXTURE_CHANNEL = "development_fixture";
const CALLABLE_CHANNEL = "callable:getAdminVenueWorkspaceReadBundle";
const UNAVAILABLE_CHANNEL = "venue_workspace_unavailable";
const FIXTURE_BLOCKED_CHANNEL = "fixture_fallback_disabled";

type SnapshotLoadResult =
  | {
      ok: true;
      snapshot: VenueWorkspaceSnapshot;
      channel: string;
    }
  | {
      ok: false;
      message: string;
      channel: string;
    };

export async function loadVenueWorkspaceReadBundle(
  venueId: string,
  options?: VenueWorkspaceReadLoaderOptions,
): Promise<VenueWorkspaceReadBundle> {
  const env = options?.env ?? process.env;
  const nowFn = options?.now ?? (() => new Date());

  if (env.WAIN_VENUE_WORKSPACE_FORCE_UNAVAILABLE === "1") {
    return buildUnavailableBundle(
      venueId,
      "Venue workspace read is unavailable (WAIN_VENUE_WORKSPACE_FORCE_UNAVAILABLE).",
      UNAVAILABLE_CHANNEL,
    );
  }

  const staleAfterMs =
    parsePositiveInt(env.WAIN_VENUE_WORKSPACE_STALE_AFTER_MS) ??
    DEFAULT_STALE_AFTER_MS;
  const fixtureFallbackPolicy = resolveFixtureFallbackPolicy(env);
  const fetchedAt = nowFn().toISOString();
  const invoker = resolveCallableInvoker(options, env);
  const callableResult = invoker
    ? await loadSnapshotFromCallable({
        venueId,
        invokeCallable: invoker,
        now: nowFn,
      })
    : null;

  if (callableResult?.ok) {
    return toReadBundle(callableResult.snapshot, {
      source: callableResult.channel,
      fetchedAt,
      staleAfterMs,
    });
  }

  if (!fixtureFallbackPolicy.allowed) {
    return buildUnavailableBundle(
      venueId,
      FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
      callableResult && !callableResult.ok
        ? `${callableResult.channel} -> ${FIXTURE_BLOCKED_CHANNEL}`
        : FIXTURE_BLOCKED_CHANNEL,
    );
  }

  const asOf = normalizeIsoDate(env.WAIN_VENUE_WORKSPACE_FIXTURE_AS_OF, nowFn);
  const emptyTabs = parseEmptyTabs(env.WAIN_VENUE_WORKSPACE_FORCE_EMPTY_TABS);
  const snapshot = buildFixtureSnapshot(venueId, asOf, emptyTabs);

  return toReadBundle(snapshot, {
    source:
      callableResult && !callableResult.ok
        ? `${callableResult.channel} -> ${FIXTURE_CHANNEL}`
        : FIXTURE_CHANNEL,
    fetchedAt,
    staleAfterMs,
  });
}

function resolveCallableInvoker(
  options: VenueWorkspaceReadLoaderOptions | undefined,
  env: Record<string, string | undefined>,
): FinanceCallableInvoker | null {
  if (options?.invokeCallable) {
    return options.invokeCallable;
  }

  const resolution = createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
  });

  return resolution.ok ? resolution.invokeCallable : null;
}

async function loadSnapshotFromCallable(args: {
  venueId: string;
  invokeCallable: FinanceCallableInvoker;
  now: () => Date;
}): Promise<SnapshotLoadResult> {
  try {
    const raw = asRecord(
      await args.invokeCallable("getAdminVenueWorkspaceReadBundle", {
        venueId: args.venueId,
      }),
    );
    if (!raw) {
      return {
        ok: false,
        message: "Venue workspace callable returned a non-object response.",
        channel: CALLABLE_CHANNEL,
      };
    }

    return {
      ok: true,
      snapshot: normalizeCallableWorkspaceSnapshot(args.venueId, raw, args.now),
      channel: CALLABLE_CHANNEL,
    };
  } catch (error) {
    return {
      ok: false,
      message: `Venue workspace callable read failed: ${normalizeError(error)}`,
      channel: CALLABLE_CHANNEL,
    };
  }
}

function normalizeCallableWorkspaceSnapshot(
  venueId: string,
  raw: Record<string, unknown>,
  now: () => Date,
): VenueWorkspaceSnapshot {
  const asOf = normalizeIsoDate(raw.checkedAt ?? raw.asOf, now);
  const context = normalizeWorkspaceContext(
    venueId,
    asRecord(raw.context),
  );

  return {
    asOf,
    context,
    walletEntries: normalizeWalletEntries(raw.walletEntries, asOf),
    offers: normalizeOfferItems(raw.offers, asOf),
    stories: normalizeStoryItems(raw.stories, asOf),
    reviews: normalizeReviewItems(raw.reviews, asOf),
  };
}

function normalizeWorkspaceContext(
  venueId: string,
  context: Record<string, unknown> | undefined,
): VenueWorkspaceContext {
  const walletBalance = toFiniteNumber(
    context?.walletBalance ?? context?.wallet_balance,
  );

  return {
    venueId,
    venueName:
      toNonEmptyString(context?.venueName) ??
      toNonEmptyString(context?.venue_name) ??
      venueId,
    walletBalance: walletBalance ?? 0,
    walletCurrency: normalizeCurrency(
      context?.walletCurrency ?? context?.wallet_currency,
    ),
    readinessStatus: normalizeReadinessStatus(
      context?.readinessStatus ?? context?.readiness_status,
    ),
    readinessSummary:
      toNonEmptyString(context?.readinessSummary) ??
      toNonEmptyString(context?.readiness_summary) ??
      "Workspace context is available from the admin read surface.",
  };
}

function normalizeWalletEntries(
  value: unknown,
  fallbackIso: string,
): VenueWalletEntry[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => asRecord(entry))
    .filter((entry): entry is Record<string, unknown> => Boolean(entry))
    .map((entry, index) => ({
      id: toNonEmptyString(entry.id) ?? `wallet_entry_${index}`,
      type: normalizeWalletEntryType(entry.type),
      amount: Math.abs(toFiniteNumber(entry.amount) ?? 0),
      currency: normalizeCurrency(entry.currency),
      description:
        toNonEmptyString(entry.description) ??
        toNonEmptyString(entry.note) ??
        "Wallet entry",
      createdAt: normalizeIsoDate(entry.createdAt ?? entry.created_at, () => new Date(fallbackIso)),
    }))
    .sort((left, right) => Date.parse(right.createdAt) - Date.parse(left.createdAt));
}

function normalizeOfferItems(
  value: unknown,
  fallbackIso: string,
): VenueOfferItem[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => asRecord(entry))
    .filter((entry): entry is Record<string, unknown> => Boolean(entry))
    .map((entry, index) => ({
      id: toNonEmptyString(entry.id) ?? `offer_${index}`,
      title:
        toNonEmptyString(entry.title) ??
        toNonEmptyString(entry.title_ar) ??
        `Offer ${index + 1}`,
      status: normalizeOfferStatus(entry.status),
      startsAt: normalizeIsoDate(
        entry.startsAt ?? entry.starts_at ?? entry.start_at,
        () => new Date(fallbackIso),
      ),
      endsAt: normalizeIsoDate(
        entry.endsAt ?? entry.ends_at ?? entry.end_at,
        () => new Date(fallbackIso),
      ),
    }))
    .sort((left, right) => Date.parse(right.endsAt) - Date.parse(left.endsAt));
}

function normalizeStoryItems(
  value: unknown,
  fallbackIso: string,
): VenueStoryItem[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => asRecord(entry))
    .filter((entry): entry is Record<string, unknown> => Boolean(entry))
    .map((entry, index) => ({
      id: toNonEmptyString(entry.id) ?? `story_${index}`,
      caption:
        toNonEmptyString(entry.caption) ??
        toNonEmptyString(entry.caption_ar) ??
        `Story ${index + 1}`,
      status: normalizeStoryStatus(entry.status),
      expiresAt: normalizeIsoDate(
        entry.expiresAt ?? entry.expires_at ?? entry.expire_at,
        () => new Date(fallbackIso),
      ),
    }))
    .sort((left, right) => Date.parse(right.expiresAt) - Date.parse(left.expiresAt));
}

function normalizeReviewItems(
  value: unknown,
  fallbackIso: string,
): VenueReviewItem[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => asRecord(entry))
    .filter((entry): entry is Record<string, unknown> => Boolean(entry))
    .map((entry, index) => ({
      id: toNonEmptyString(entry.id) ?? `review_${index}`,
      authorName:
        toNonEmptyString(entry.authorName) ??
        toNonEmptyString(entry.author_name) ??
        "زائر",
      rating: clampRating(toFiniteNumber(entry.rating)),
      status: normalizeReviewStatus(entry.status),
      snippet:
        toNonEmptyString(entry.snippet) ??
        toNonEmptyString(entry.comment) ??
        toNonEmptyString(entry.review_text) ??
        "لا يوجد نص مختصر لهذه المراجعة.",
      createdAt: normalizeIsoDate(
        entry.createdAt ?? entry.created_at,
        () => new Date(fallbackIso),
      ),
    }))
    .sort((left, right) => Date.parse(right.createdAt) - Date.parse(left.createdAt));
}

function toReadBundle(
  snapshot: VenueWorkspaceSnapshot,
  meta: {
    source: string;
    fetchedAt: string;
    staleAfterMs: number;
  },
): VenueWorkspaceReadBundle {
  const ageMs = Math.max(
    0,
    new Date(meta.fetchedAt).getTime() - new Date(snapshot.asOf).getTime(),
  );
  const stale = ageMs > meta.staleAfterMs;

  return {
    context: snapshot.context,
    wallet: {
      kind: "success",
      data: { entries: snapshot.walletEntries },
      asOf: snapshot.asOf,
      fetchedAt: meta.fetchedAt,
      source: meta.source,
      stale,
    },
    offers: {
      kind: "success",
      data: { items: snapshot.offers },
      asOf: snapshot.asOf,
      fetchedAt: meta.fetchedAt,
      source: meta.source,
      stale,
    },
    stories: {
      kind: "success",
      data: { items: snapshot.stories },
      asOf: snapshot.asOf,
      fetchedAt: meta.fetchedAt,
      source: meta.source,
      stale,
    },
    reviews: {
      kind: "success",
      data: { items: snapshot.reviews },
      asOf: snapshot.asOf,
      fetchedAt: meta.fetchedAt,
      source: meta.source,
      stale,
    },
  };
}

export function buildFixtureSnapshot(
  venueId: string,
  asOf: string,
  emptyTabs: ReadonlySet<VenueWorkspaceTabKey> = new Set(),
): VenueWorkspaceSnapshot {
  const shortId = venueId.slice(-6) || venueId;

  const context: VenueWorkspaceContext = {
    venueId,
    venueName: `Venue ${shortId}`,
    walletBalance: 148.25,
    walletCurrency: "ILS",
    readinessStatus: "ready",
    readinessSummary: "Core checks are healthy for read-only workspace operations.",
  };

  const walletEntries: VenueWalletEntry[] = emptyTabs.has("wallet")
    ? []
    : [
        {
          id: `entry_${shortId}_1`,
          type: "credit",
          amount: 200,
          currency: "ILS",
          description: "Top-up credited",
          createdAt: asOf,
        },
        {
          id: `entry_${shortId}_2`,
          type: "debit",
          amount: 51.75,
          currency: "ILS",
          description: "Story promotion debit",
          createdAt: asOf,
        },
      ];

  const offers: VenueOfferItem[] = emptyTabs.has("offers")
    ? []
    : [
        {
          id: `offer_${shortId}_a`,
          title: "Morning Coffee Bundle",
          status: "active",
          startsAt: asOf,
          endsAt: new Date(new Date(asOf).getTime() + 3 * 24 * 60 * 60 * 1000).toISOString(),
        },
        {
          id: `offer_${shortId}_b`,
          title: "Weekend Family Menu",
          status: "paused",
          startsAt: asOf,
          endsAt: new Date(new Date(asOf).getTime() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        },
      ];

  const stories: VenueStoryItem[] = emptyTabs.has("stories")
    ? []
    : [
        {
          id: `story_${shortId}_a`,
          caption: "Today specials highlight",
          status: "published",
          expiresAt: new Date(new Date(asOf).getTime() + 24 * 60 * 60 * 1000).toISOString(),
        },
      ];

  const reviews: VenueReviewItem[] = emptyTabs.has("reviews")
    ? []
    : [
        {
          id: `review_${shortId}_a`,
          authorName: "زائر 1",
          rating: 4,
          status: "published",
          snippet: "خدمة سريعة وطعام دافئ.",
          createdAt: asOf,
        },
        {
          id: `review_${shortId}_b`,
          authorName: "زائر 2",
          rating: 2,
          status: "flagged",
          snippet: "وصل الطلب متأخرًا عن المتوقع.",
          createdAt: asOf,
        },
      ];

  return {
    asOf,
    context,
    walletEntries,
    offers,
    stories,
    reviews,
  };
}

function buildUnavailableBundle(
  venueId: string,
  message: string,
  attemptedSource: string,
): VenueWorkspaceReadBundle {
  const fallbackContext: VenueWorkspaceContext = {
    venueId,
    venueName: venueId,
    walletBalance: 0,
    walletCurrency: "ILS",
    readinessStatus: "warning",
    readinessSummary: "Workspace context is in fallback mode until upstream reads recover.",
  };

  const unavailable = {
    kind: "unavailable" as const,
    message,
    attemptedSource,
  };

  return {
    context: fallbackContext,
    wallet: unavailable,
    offers: unavailable,
    stories: unavailable,
    reviews: unavailable,
  };
}

function parsePositiveInt(raw: string | undefined): number | undefined {
  if (!raw || raw.trim().length === 0) {
    return undefined;
  }

  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

function normalizeIsoDate(
  raw: unknown,
  nowFn: () => Date,
): string {
  if (typeof raw === "number" && Number.isFinite(raw)) {
    return new Date(raw).toISOString();
  }

  if (typeof raw === "string" && raw.trim().length > 0) {
    const parsed = new Date(raw);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
  }

  if (raw && typeof raw === "object" && "toMillis" in raw) {
    const candidate = raw as { toMillis?: () => number };
    if (typeof candidate.toMillis === "function") {
      return new Date(candidate.toMillis()).toISOString();
    }
  }

  return nowFn().toISOString();
}

function parseEmptyTabs(raw: string | undefined): ReadonlySet<VenueWorkspaceTabKey> {
  if (!raw || raw.trim().length === 0) {
    return new Set();
  }

  const parsed = raw
    .split(",")
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);

  const tabs = new Set<VenueWorkspaceTabKey>();
  for (const key of parsed) {
    if (key === "wallet" || key === "offers" || key === "stories" || key === "reviews") {
      tabs.add(key);
    }
  }
  return tabs;
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

function normalizeCurrency(value: unknown): "ILS" | "USD" {
  return toNonEmptyString(value)?.toUpperCase() === "USD" ? "USD" : "ILS";
}

function normalizeReadinessStatus(value: unknown): "ready" | "warning" | "fail" {
  const normalized = toNonEmptyString(value)?.toLowerCase();
  if (normalized === "ready" || normalized === "pass") {
    return "ready";
  }
  if (normalized === "fail" || normalized === "blocked") {
    return "fail";
  }
  return "warning";
}

function normalizeWalletEntryType(value: unknown): "credit" | "debit" | "reversal" {
  const normalized = toNonEmptyString(value)?.toLowerCase();
  if (normalized === "debit" || normalized === "reversal") {
    return normalized;
  }
  return "credit";
}

function normalizeOfferStatus(value: unknown): "active" | "paused" | "expired" {
  const normalized = toNonEmptyString(value)?.toLowerCase();
  if (normalized === "paused" || normalized === "expired") {
    return normalized;
  }
  return "active";
}

function normalizeStoryStatus(value: unknown): "published" | "expired" | "draft" {
  const normalized = toNonEmptyString(value)?.toLowerCase();
  if (normalized === "expired" || normalized === "draft") {
    return normalized;
  }
  return "published";
}

function normalizeReviewStatus(value: unknown): "published" | "flagged" | "hidden" {
  const normalized = toNonEmptyString(value)?.toLowerCase();
  if (normalized === "flagged" || normalized === "hidden") {
    return normalized;
  }
  return "published";
}

function clampRating(value: number | null): number {
  if (value === null) {
    return 0;
  }
  return Math.max(0, Math.min(5, Math.round(value)));
}

function normalizeError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}
