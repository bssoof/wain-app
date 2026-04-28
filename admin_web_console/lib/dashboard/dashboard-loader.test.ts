import { beforeEach, describe, it, expect, vi } from "vitest";
import {
  __resetDashboardSummaryCacheForTests,
  loadDashboardSummary,
} from "./dashboard-loader";
import * as financeDocs from "@/lib/finance/finance-read-loader";
import * as venueDocs from "@/lib/venues/venue-directory-read-loader";
import * as contentDocs from "@/lib/content/content-read-loader";

vi.mock("@/lib/finance/finance-read-loader", () => ({
  loadTopUpQueueRead: vi.fn(),
  loadReadinessRead: vi.fn(),
}));

vi.mock("@/lib/venues/venue-directory-read-loader", () => ({
  loadVenueDirectoryRead: vi.fn(),
}));

vi.mock("@/lib/content/content-read-loader", () => ({
  loadOfferModerationSnapshot: vi.fn(),
  loadStoryModerationSnapshot: vi.fn(),
}));

describe("dashboard-loader", () => {
  const mockNow = () => new Date("2026-04-11T00:00:00.000Z");

  beforeEach(() => {
    vi.clearAllMocks();
    __resetDashboardSummaryCacheForTests();
  });

  it("should aggregate all success results correctly", async () => {
    vi.mocked(financeDocs.loadTopUpQueueRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        pending: [{ id: "request1" } as any],
      },
    });

    vi.mocked(financeDocs.loadReadinessRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        report: {
          generatedAt: "2026-04-11T00:00:00.000Z",
          overallStatus: "ready",
          summary: "All good",
          checks: [],
        },
      },
    });

    vi.mocked(venueDocs.loadVenueDirectoryRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        items: [{ venueId: "v1" } as any],
        summary: {
          totalVenues: 1,
          readiness: { ready: 1, warning: 0, fail: 0, unknown: 0 },
          wallet: { active: 1, low_balance: 0, inactive: 0, unknown: 0 },
          merchantLinks: { linked: 1, unlinked: 0, unknown: 0 },
          subscriptions: { active: 1, expired: 0, paused: 0 },
          visibility: { visible: 1, hidden: 0 },
          operational: { active: 1, suspended: 0, archived: 0 }
        },
        filters: {} as any,
        readBudget: {} as any,
      },
    });

    vi.mocked(contentDocs.loadOfferModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "success",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [{ adminState: "pending" } as any],
    });

    vi.mocked(contentDocs.loadStoryModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "success",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [{ adminState: "flagged" } as any],
    });

    const result = await loadDashboardSummary({ now: mockNow });

    expect(result.topUpQueue.state).toBe("success");
    expect(result.topUpQueue.data?.pendingCount).toBe(1);

    expect(result.walletReadiness.state).toBe("success");
    expect(result.walletReadiness.data?.overallStatus).toBe("ready");

    expect(result.venueDirectory.state).toBe("success");
    expect(result.venueDirectory.data?.totalVenues).toBe(1);

    expect(result.contentModeration.state).toBe("success");
    expect(result.contentModeration.data?.pendingOffers).toBe(1);
    expect(result.contentModeration.data?.pendingStories).toBe(0);
  });

  it("should handle mixed unreachable and empty results gracefully without crashing", async () => {
    vi.mocked(financeDocs.loadTopUpQueueRead).mockRejectedValue(new Error("Network crash"));

    vi.mocked(financeDocs.loadReadinessRead).mockResolvedValue({
      kind: "unavailable",
      message: "Forbidden",
      attemptedSource: "callable:health",
    });

    vi.mocked(venueDocs.loadVenueDirectoryRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: true,
      data: {
        items: [],
        summary: {
          totalVenues: 0,
          readiness: { ready: 0, warning: 0, fail: 0, unknown: 0 },
          wallet: { active: 0, low_balance: 0, inactive: 0, unknown: 0 },
          merchantLinks: { linked: 0, unlinked: 0, unknown: 0 },
          subscriptions: { active: 0, expired: 0, paused: 0 },
          visibility: { visible: 0, hidden: 0 },
          operational: { active: 0, suspended: 0, archived: 0 }
        },
        filters: {} as any,
        readBudget: {} as any,
      },
    });

    vi.mocked(contentDocs.loadOfferModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "empty",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [],
    });

    vi.mocked(contentDocs.loadStoryModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "empty",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [],
    });

    const result = await loadDashboardSummary({ now: mockNow });

    expect(result.topUpQueue.state).toBe("unavailable");
    expect(result.topUpQueue.message).toContain("Network crash");

    expect(result.walletReadiness.state).toBe("unavailable");
    expect(result.walletReadiness.message).toBe("Forbidden");

    expect(result.venueDirectory.state).toBe("stale");
    expect(result.venueDirectory.message).toContain("stale");
    expect(result.venueDirectory.data?.totalVenues).toBe(0);

    expect(result.contentModeration.state).toBe("empty");
    expect(result.contentModeration.data?.pendingOffers).toBe(0);
    expect(result.contentModeration.data?.pendingStories).toBe(0);
  });

  it("reuses dashboard summary when shared cache is explicitly enabled", async () => {
    const env = {
      WAIN_DASHBOARD_SHARED_CACHE: "1",
      WAIN_DASHBOARD_SHARED_CACHE_TTL_MS: "60000",
    };

    vi.mocked(financeDocs.loadTopUpQueueRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: { pending: [{ id: "request1" } as any] },
    });
    vi.mocked(financeDocs.loadReadinessRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        report: {
          generatedAt: "2026-04-11T00:00:00.000Z",
          overallStatus: "ready",
          summary: "All good",
          checks: [],
        },
      },
    });
    vi.mocked(venueDocs.loadVenueDirectoryRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        items: [{ venueId: "v1" } as any],
        summary: {
          totalVenues: 1,
          readiness: { ready: 1, warning: 0, fail: 0, unknown: 0 },
          wallet: { active: 1, low_balance: 0, inactive: 0, unknown: 0 },
          merchantLinks: { linked: 1, unlinked: 0, unknown: 0 },
          subscriptions: { active: 1, expired: 0, paused: 0 },
          visibility: { visible: 1, hidden: 0 },
          operational: { active: 1, suspended: 0, archived: 0 },
        },
        filters: {} as any,
        readBudget: {} as any,
      },
    });
    vi.mocked(contentDocs.loadOfferModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "success",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [{ adminState: "pending" } as any],
    });
    vi.mocked(contentDocs.loadStoryModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "success",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [{ adminState: "flagged" } as any],
    });

    const first = await loadDashboardSummary({
      env,
      now: () => new Date("2026-04-11T00:00:00.000Z"),
    });
    const second = await loadDashboardSummary({
      env,
      now: () => new Date("2026-04-11T00:10:00.000Z"),
    });

    expect(second.generatedAt).toBe(first.generatedAt);
    expect(financeDocs.loadTopUpQueueRead).toHaveBeenCalledTimes(1);
    expect(financeDocs.loadReadinessRead).toHaveBeenCalledTimes(1);
    expect(venueDocs.loadVenueDirectoryRead).toHaveBeenCalledTimes(1);
    expect(contentDocs.loadOfferModerationSnapshot).toHaveBeenCalledTimes(1);
    expect(contentDocs.loadStoryModerationSnapshot).toHaveBeenCalledTimes(1);
  });

  it("does not reuse dashboard summary when shared cache is disabled", async () => {
    const env = {
      WAIN_DASHBOARD_SHARED_CACHE: "0",
    };

    vi.mocked(financeDocs.loadTopUpQueueRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: { pending: [{ id: "request1" } as any] },
    });
    vi.mocked(financeDocs.loadReadinessRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        report: {
          generatedAt: "2026-04-11T00:00:00.000Z",
          overallStatus: "ready",
          summary: "All good",
          checks: [],
        },
      },
    });
    vi.mocked(venueDocs.loadVenueDirectoryRead).mockResolvedValue({
      kind: "success",
      asOf: "2026-04-11T00:00:00.000Z",
      fetchedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      stale: false,
      data: {
        items: [{ venueId: "v1" } as any],
        summary: {
          totalVenues: 1,
          readiness: { ready: 1, warning: 0, fail: 0, unknown: 0 },
          wallet: { active: 1, low_balance: 0, inactive: 0, unknown: 0 },
          merchantLinks: { linked: 1, unlinked: 0, unknown: 0 },
          subscriptions: { active: 1, expired: 0, paused: 0 },
          visibility: { visible: 1, hidden: 0 },
          operational: { active: 1, suspended: 0, archived: 0 },
        },
        filters: {} as any,
        readBudget: {} as any,
      },
    });
    vi.mocked(contentDocs.loadOfferModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "success",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [{ adminState: "pending" } as any],
    });
    vi.mocked(contentDocs.loadStoryModerationSnapshot).mockResolvedValue({
      generatedAt: "2026-04-11T00:00:00.000Z",
      source: "mock",
      freshnessNote: "",
      state: "success",
      filtersApplied: { venueId: null, statuses: [], limit: 50 },
      items: [{ adminState: "flagged" } as any],
    });

    const first = await loadDashboardSummary({
      env,
      now: () => new Date("2026-04-11T00:00:00.000Z"),
    });
    const second = await loadDashboardSummary({
      env,
      now: () => new Date("2026-04-11T00:10:00.000Z"),
    });

    expect(second.generatedAt).not.toBe(first.generatedAt);
    expect(financeDocs.loadTopUpQueueRead).toHaveBeenCalledTimes(2);
    expect(financeDocs.loadReadinessRead).toHaveBeenCalledTimes(2);
    expect(venueDocs.loadVenueDirectoryRead).toHaveBeenCalledTimes(2);
    expect(contentDocs.loadOfferModerationSnapshot).toHaveBeenCalledTimes(2);
    expect(contentDocs.loadStoryModerationSnapshot).toHaveBeenCalledTimes(2);
  });
});
