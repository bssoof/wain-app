import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  __resetContentModerationSnapshotCacheForTests,
  loadOfferModerationSnapshot,
  loadStoryModerationSnapshot,
} from "./content-read-loader";

const FIXED_NOW = new Date("2026-04-10T12:00:00.000Z");

describe("content-read-loader", () => {
  beforeEach(() => {
    __resetContentModerationSnapshotCacheForTests();
  });

  it("loads callable-backed offers when content transport is available", async () => {
    const invokeCallable = vi.fn().mockResolvedValue({
      checkedAt: FIXED_NOW.toISOString(),
      filtersApplied: {
        venueId: "venue-1",
        statuses: ["pending"],
        limit: 50,
      },
      items: [
        {
          id: "offer-1",
          venueId: "venue-1",
          venueName: "Venue One",
          title: "Offer One",
          adminState: "pending",
          isActive: true,
          isFeatured: false,
          createdAt: FIXED_NOW.toISOString(),
          updatedAt: FIXED_NOW.toISOString(),
        },
      ],
    });

    const snapshot = await loadOfferModerationSnapshot({
      now: () => FIXED_NOW,
      invokeCallable,
    });

    expect(invokeCallable).toHaveBeenCalledWith("listOffersForAdmin", { limit: 50 });
    expect(snapshot.source).toBe("callable:listOffersForAdmin");
    expect(snapshot.state).toBe("success");
    expect(snapshot.items).toHaveLength(1);
    expect(snapshot.items[0]?.title).toBe("Offer One");
  });

  it("marks callable-backed stories as empty when no rows are returned", async () => {
    const snapshot = await loadStoryModerationSnapshot({
      now: () => FIXED_NOW,
      invokeCallable: vi.fn().mockResolvedValue({
        checkedAt: FIXED_NOW.toISOString(),
        filtersApplied: {
          venueId: null,
          statuses: [],
          limit: 50,
        },
        items: [],
      }),
    });

    expect(snapshot.source).toBe("callable:listStoriesForAdmin");
    expect(snapshot.state).toBe("empty");
    expect(snapshot.items).toHaveLength(0);
  });

  it("does not fall back to fixtures when the callable is unauthorized", async () => {
    const snapshot = await loadOfferModerationSnapshot({
      now: () => FIXED_NOW,
      invokeCallable: vi.fn().mockRejectedValue({
        status: 403,
        message: "permission denied",
      }),
    });

    expect(snapshot.source).toBe("callable:listOffersForAdmin");
    expect(snapshot.state).toBe("unavailable");
    expect(snapshot.items).toHaveLength(0);
    expect(snapshot.message).toMatch(/permission denied/i);
  });

  it("falls back to explicitly labeled fixtures only on retryable transport failures", async () => {
    const snapshot = await loadStoryModerationSnapshot({
      now: () => FIXED_NOW,
      invokeCallable: vi.fn().mockRejectedValue({
        status: 503,
        message: "transport unavailable",
      }),
    });

    expect(snapshot.source).toBe(
      "callable:listStoriesForAdmin -> development_fixture",
    );
    expect(snapshot.state).toBe("stale");
    expect(snapshot.items).toHaveLength(1);
    expect(snapshot.message).toMatch(/transport unavailable/i);
  });

  it("marks malformed callable rows as unavailable", async () => {
    const snapshot = await loadOfferModerationSnapshot({
      now: () => FIXED_NOW,
      invokeCallable: vi.fn().mockResolvedValue({
        checkedAt: FIXED_NOW.toISOString(),
        filtersApplied: {
          venueId: null,
          statuses: [],
          limit: 50,
        },
        items: [{}],
      }),
    });

    expect(snapshot.source).toBe("callable:listOffersForAdmin");
    expect(snapshot.state).toBe("unavailable");
    expect(snapshot.items).toHaveLength(0);
    expect(snapshot.message).toMatch(/malformed/i);
  });

  it("reuses shared content snapshot when cache is explicitly enabled", async () => {
    const invokeCallable = vi.fn().mockResolvedValue({
      checkedAt: FIXED_NOW.toISOString(),
      filtersApplied: {
        venueId: null,
        statuses: [],
        limit: 50,
      },
      items: [
        {
          id: "story-cache-1",
          venueId: "venue-cache-1",
          venueName: "Cache Venue",
          caption: "Story cache row",
          adminState: "pending",
          isActive: true,
          isPromoted: false,
          createdAt: FIXED_NOW.toISOString(),
          updatedAt: FIXED_NOW.toISOString(),
        },
      ],
    });

    const env = {
      WAIN_CONTENT_MODERATION_SHARED_CACHE: "1",
      WAIN_CONTENT_MODERATION_SHARED_CACHE_TTL_MS: "60000",
    };

    const first = await loadStoryModerationSnapshot({
      env,
      now: () => new Date("2026-04-10T12:00:00.000Z"),
      invokeCallable,
    });
    const second = await loadStoryModerationSnapshot({
      env,
      now: () => new Date("2026-04-10T12:10:00.000Z"),
      invokeCallable,
    });

    expect(first.source).toBe("callable:listStoriesForAdmin");
    expect(second.source).toBe("callable:listStoriesForAdmin");
    expect(invokeCallable).toHaveBeenCalledTimes(1);
  });

  it("does not reuse shared content snapshot when cache is disabled", async () => {
    const invokeCallable = vi.fn().mockResolvedValue({
      checkedAt: FIXED_NOW.toISOString(),
      filtersApplied: {
        venueId: null,
        statuses: [],
        limit: 50,
      },
      items: [
        {
          id: "offer-cache-1",
          venueId: "venue-cache-1",
          venueName: "Cache Venue",
          title: "Offer cache row",
          adminState: "pending",
          isActive: true,
          isFeatured: false,
          createdAt: FIXED_NOW.toISOString(),
          updatedAt: FIXED_NOW.toISOString(),
        },
      ],
    });

    const env = {
      WAIN_CONTENT_MODERATION_SHARED_CACHE: "0",
    };

    await loadOfferModerationSnapshot({
      env,
      now: () => new Date("2026-04-10T12:00:00.000Z"),
      invokeCallable,
    });
    await loadOfferModerationSnapshot({
      env,
      now: () => new Date("2026-04-10T12:10:00.000Z"),
      invokeCallable,
    });

    expect(invokeCallable).toHaveBeenCalledTimes(2);
  });
});
