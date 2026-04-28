import { beforeEach, describe, expect, it, vi } from "vitest";

const {
  getCurrentAdminSessionMock,
  loadConfigGovernanceSnapshotMock,
  loadMediaCenterBaselineMock,
  loadOfferModerationSnapshotMock,
  loadReadinessReadMock,
  loadReviewModerationSnapshotMock,
  loadStoryModerationSnapshotMock,
  loadTopUpQueueReadMock,
  loadVenueDirectoryReadMock,
  loadWalletLedgerReadMock,
} = vi.hoisted(() => ({
  getCurrentAdminSessionMock: vi.fn(),
  loadConfigGovernanceSnapshotMock: vi.fn(),
  loadMediaCenterBaselineMock: vi.fn(),
  loadOfferModerationSnapshotMock: vi.fn(),
  loadReadinessReadMock: vi.fn(),
  loadReviewModerationSnapshotMock: vi.fn(),
  loadStoryModerationSnapshotMock: vi.fn(),
  loadTopUpQueueReadMock: vi.fn(),
  loadVenueDirectoryReadMock: vi.fn(),
  loadWalletLedgerReadMock: vi.fn(),
}));

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: () => getCurrentAdminSessionMock(),
}));

vi.mock("@/lib/config/config-read-loader", () => ({
  loadConfigGovernanceSnapshot: () => loadConfigGovernanceSnapshotMock(),
}));

vi.mock("@/lib/content/content-read-loader", () => ({
  loadOfferModerationSnapshot: () => loadOfferModerationSnapshotMock(),
  loadStoryModerationSnapshot: () => loadStoryModerationSnapshotMock(),
}));

vi.mock("@/lib/finance/finance-read-loader", () => ({
  loadReadinessRead: () => loadReadinessReadMock(),
  loadTopUpQueueRead: () => loadTopUpQueueReadMock(),
  loadWalletLedgerRead: () => loadWalletLedgerReadMock(),
}));

vi.mock("@/lib/media/media-center-baseline", () => ({
  loadMediaCenterBaseline: () => loadMediaCenterBaselineMock(),
}));

vi.mock("@/lib/reviews/review-moderation-loader", () => ({
  loadReviewModerationSnapshot: () => loadReviewModerationSnapshotMock(),
}));

vi.mock("@/lib/venues/venue-directory-read-loader", () => ({
  loadVenueDirectoryRead: () => loadVenueDirectoryReadMock(),
}));

import { POST } from "@/app/api/admin/warmup/route";
import { __resetAdminWarmupDedupeForTests } from "@/lib/admin/admin-warmup-dedupe";
import type { AdminSession } from "@/lib/auth/guard-api";

const superAdminSession: AdminSession = {
  uid: "super-admin-1",
  email: "admin@wain.app",
  primaryRole: "super_admin",
  roles: ["super_admin"],
  roleSource: "claims",
};

function makeRequest(routeKeys?: unknown[]) {
  return {
    json: async () => ({ routeKeys }),
  } as Request;
}

beforeEach(() => {
  vi.clearAllMocks();
  __resetAdminWarmupDedupeForTests();
  delete process.env.WAIN_ADMIN_WARMUP_MAX_TASKS;
  delete process.env.WAIN_ADMIN_WARMUP_DEDUPE_TTL_MS;

  getCurrentAdminSessionMock.mockResolvedValue(superAdminSession);
  loadConfigGovernanceSnapshotMock.mockResolvedValue({});
  loadMediaCenterBaselineMock.mockResolvedValue({});
  loadOfferModerationSnapshotMock.mockResolvedValue({});
  loadReadinessReadMock.mockResolvedValue({});
  loadReviewModerationSnapshotMock.mockResolvedValue({});
  loadStoryModerationSnapshotMock.mockResolvedValue({});
  loadTopUpQueueReadMock.mockResolvedValue({});
  loadVenueDirectoryReadMock.mockResolvedValue({});
  loadWalletLedgerReadMock.mockResolvedValue({});
});

describe("admin warmup route", () => {
  it("rejects unauthenticated warmup requests", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(null);

    const response = await POST(makeRequest(["topups"]));
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload).toEqual({
      ok: false,
      message: "unauthenticated",
    });
  });

  it("runs only bounded auto warmup tasks from requested route keys", async () => {
    const response = await POST(
      makeRequest([
        "topups",
        "wallet_audit",
        "readiness",
        "venues",
        "config",
        "media",
      ]),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(response.headers.get("Cache-Control")).toBe("no-store, max-age=0");
    expect(payload).toMatchObject({
      ok: true,
      skipped: false,
      warmed: 4,
      failed: 0,
      maxTasks: 4,
    });
    expect(loadTopUpQueueReadMock).toHaveBeenCalledTimes(1);
    expect(loadWalletLedgerReadMock).toHaveBeenCalledTimes(1);
    expect(loadReadinessReadMock).toHaveBeenCalledTimes(1);
    expect(loadVenueDirectoryReadMock).toHaveBeenCalledTimes(1);
    expect(loadConfigGovernanceSnapshotMock).not.toHaveBeenCalled();
    expect(loadMediaCenterBaselineMock).not.toHaveBeenCalled();
  });

  it("deduplicates repeated warmup requests for the same admin session", async () => {
    await POST(makeRequest(["topups", "wallet_audit"]));

    const response = await POST(makeRequest(["readiness", "venues"]));
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toMatchObject({
      ok: true,
      skipped: true,
      reason: "recent_duplicate",
      warmed: 0,
      failed: 0,
    });
    expect(loadTopUpQueueReadMock).toHaveBeenCalledTimes(1);
    expect(loadWalletLedgerReadMock).toHaveBeenCalledTimes(1);
    expect(loadReadinessReadMock).not.toHaveBeenCalled();
    expect(loadVenueDirectoryReadMock).not.toHaveBeenCalled();
  });
});
