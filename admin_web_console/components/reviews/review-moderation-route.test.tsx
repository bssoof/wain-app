import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { ReviewModerationSnapshot } from "@/lib/reviews";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadReviewModerationSnapshotMock = vi.fn();

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/reviews/review-moderation-loader", () => ({
  loadReviewModerationSnapshot: (...args: unknown[]) =>
    loadReviewModerationSnapshotMock(...args),
}));

function session(): AdminSession {
  return {
    uid: "content-admin-1",
    primaryRole: "content_admin",
    roles: ["content_admin"],
    roleSource: "claims",
  };
}

function snapshot(): ReviewModerationSnapshot {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    source: "callable:listVenueReviewsForAdmin",
    freshnessNote: "Feed is fresh.",
    state: "success",
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 25,
    },
    items: [
      {
        id: "review-route-1",
        venueId: "venue-1",
        venueName: "Venue One",
        authorName: "Guest",
        rating: 3,
        status: "flagged",
        snippet: "Route review row",
        createdAt: "2026-04-10T12:00:00.000Z",
        moderationReason: "manual_review",
        moderationNote: null,
        moderatedAt: null,
        moderatedByUid: null,
      },
    ],
  };
}

describe("reviews moderation route", () => {
  it("requires route access and renders the moderation shell", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "reviews_moderation",
      path: "/admin/content/reviews",
      title: "المراجعات",
      scopeNote: "مراجعة تعليقات المستخدمين وإظهارها أو إخفاؤها أو إرسالها للمراجعة مع سبب واضح.",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    loadReviewModerationSnapshotMock.mockResolvedValue(snapshot());

    const module = await import("@/app/(protected)/admin/content/reviews/page");
    const AdminReviewsPage = module.default;

    const ui = await AdminReviewsPage();
    render(ui);

    expect(requireRouteAccessMock).toHaveBeenCalledWith(
      "reviews_moderation",
      "/admin/content/reviews",
    );
    expect(loadReviewModerationSnapshotMock).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("heading", { name: "المراجعات" })).toBeTruthy();
    expect(screen.getByTestId("reviews-table")).toBeTruthy();
  });
});
