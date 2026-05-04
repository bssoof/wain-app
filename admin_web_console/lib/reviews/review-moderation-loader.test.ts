import { beforeEach, describe, expect, it, vi } from "vitest";

import { createFinanceCallableInvokerFromEnv } from "@/lib/finance/finance-command-transport";
import { FIXTURE_FALLBACK_DISABLED_MESSAGE_AR } from "@/lib/admin/fixture-fallback-policy";

import {
  __resetReviewModerationSnapshotCacheForTests,
  loadReviewModerationSnapshot,
} from "./review-moderation-loader";

vi.mock("@/lib/finance/finance-command-transport", () => ({
  createFinanceCallableInvokerFromEnv: vi.fn(),
}));

const FIXED_NOW = new Date("2026-04-16T09:00:00.000Z");
const createFinanceCallableInvokerFromEnvMock = vi.mocked(
  createFinanceCallableInvokerFromEnv,
);

function buildCallablePayload() {
  return {
    checkedAt: FIXED_NOW.toISOString(),
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 25,
    },
    items: [
      {
        id: "review-1",
        venueId: "venue-1",
        venueName: "Venue One",
        authorName: "Reviewer One",
        rating: 4,
        status: "published",
        snippet: "Review content sample",
        createdAt: FIXED_NOW.toISOString(),
      },
    ],
  };
}

describe("review-moderation-loader", () => {
  beforeEach(() => {
    __resetReviewModerationSnapshotCacheForTests();
    createFinanceCallableInvokerFromEnvMock.mockReset();
  });

  it("reuses shared review snapshot when cache is explicitly enabled", async () => {
    const invokeCallable = vi.fn().mockResolvedValue(buildCallablePayload());
    createFinanceCallableInvokerFromEnvMock.mockReturnValue({
      ok: true,
      invokeCallable,
    } as any);

    const env = {
      WAIN_REVIEWS_SHARED_CACHE: "1",
      WAIN_REVIEWS_SHARED_CACHE_TTL_MS: "60000",
    };

    const first = await loadReviewModerationSnapshot({
      env,
      now: () => new Date("2026-04-16T09:00:00.000Z"),
    });
    const second = await loadReviewModerationSnapshot({
      env,
      now: () => new Date("2026-04-16T09:10:00.000Z"),
    });

    expect(first.source).toBe("callable:listVenueReviewsForAdmin");
    expect(second.source).toBe("callable:listVenueReviewsForAdmin");
    expect(first.state).toBe("success");
    expect(second.state).toBe("success");
    expect(invokeCallable).toHaveBeenCalledTimes(1);
  });

  it("does not reuse shared review snapshot when cache is disabled", async () => {
    const invokeCallable = vi.fn().mockResolvedValue(buildCallablePayload());
    createFinanceCallableInvokerFromEnvMock.mockReturnValue({
      ok: true,
      invokeCallable,
    } as any);

    const env = {
      WAIN_REVIEWS_SHARED_CACHE: "0",
    };

    await loadReviewModerationSnapshot({
      env,
      now: () => new Date("2026-04-16T09:00:00.000Z"),
    });
    await loadReviewModerationSnapshot({
      env,
      now: () => new Date("2026-04-16T09:10:00.000Z"),
    });

    expect(invokeCallable).toHaveBeenCalledTimes(2);
  });

  it("returns unavailable state when fixture fallback is blocked in production", async () => {
    createFinanceCallableInvokerFromEnvMock.mockReturnValue({
      ok: false,
    } as any);

    vi.stubGlobal("window", {});
    const snapshot = await loadReviewModerationSnapshot({
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      },
      now: () => FIXED_NOW,
    });
    vi.unstubAllGlobals();

    expect(snapshot.state).toBe("unavailable");
    expect(snapshot.source).toContain("fixture_fallback_disabled");
    expect(snapshot.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
    expect(snapshot.items).toEqual([]);
  });
});
