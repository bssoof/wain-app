import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type {
  OfferModerationSnapshot,
  StoryModerationSnapshot,
} from "@/lib/content/content-models";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadOfferModerationSnapshotMock = vi.fn();
const loadStoryModerationSnapshotMock = vi.fn();

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/content/content-read-loader", async (importOriginal) => {
  const actual =
    await importOriginal<typeof import("@/lib/content/content-read-loader")>();
  return {
    ...actual,
    loadOfferModerationSnapshot: (...args: unknown[]) =>
      loadOfferModerationSnapshotMock(...args),
    loadStoryModerationSnapshot: (...args: unknown[]) =>
      loadStoryModerationSnapshotMock(...args),
  };
});

function session(): AdminSession {
  return {
    uid: "content-admin-1",
    primaryRole: "content_admin",
    roles: ["content_admin"],
    roleSource: "claims",
  };
}

function offerSnapshot(): OfferModerationSnapshot {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    source: "callable:listOffersForAdmin",
    freshnessNote: "Offer feed is fresh.",
    state: "success",
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 50,
    },
    items: [
      {
        id: "offer-route-1",
        venueId: "venue-1",
        venueName: "Venue One",
        title: "Route Offer",
        adminState: "pending",
        isActive: true,
        isFeatured: false,
        createdAt: "2026-04-10T12:00:00.000Z",
        updatedAt: "2026-04-10T12:00:00.000Z",
      },
    ],
  };
}

function storySnapshot(): StoryModerationSnapshot {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    source: "callable:listStoriesForAdmin",
    freshnessNote: "Story feed is fresh.",
    state: "success",
    filtersApplied: {
      venueId: null,
      statuses: [],
      limit: 50,
    },
    items: [
      {
        id: "story-route-1",
        venueId: "venue-1",
        venueName: "Venue One",
        caption: "Route Story",
        adminState: "pending",
        isActive: true,
        isPromoted: false,
        createdAt: "2026-04-10T12:00:00.000Z",
        updatedAt: "2026-04-10T12:00:00.000Z",
      },
    ],
  };
}

describe("content management routes", () => {
  it("requires route access and renders the offers moderation shell", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "content_offers",
      path: "/admin/content/offers",
      title: "العروض",
      scopeNote: "مراجعة عروض الجهات واتخاذ قرار واضح: قبول أو رفض أو إيقاف.",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    loadOfferModerationSnapshotMock.mockResolvedValue(offerSnapshot());

    const module = await import("@/app/(protected)/admin/content/offers/page");
    const AdminOffersPage = module.default;

    render(await AdminOffersPage());

    expect(requireRouteAccessMock).toHaveBeenCalledWith(
      "content_offers",
      "/admin/content/offers",
    );
    expect(loadOfferModerationSnapshotMock).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("heading", { name: "العروض" })).toBeTruthy();
    expect(screen.getByTestId("offers-table")).toBeTruthy();
  });

  it("requires route access and renders the stories moderation shell", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "content_stories",
      path: "/admin/content/stories",
      title: "القصص",
      scopeNote: "مراجعة قصص الجهات واتخاذ قرار واضح: قبول أو رفض أو إيقاف.",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    loadStoryModerationSnapshotMock.mockResolvedValue(storySnapshot());

    const module = await import("@/app/(protected)/admin/content/stories/page");
    const AdminStoriesPage = module.default;

    render(await AdminStoriesPage());

    expect(requireRouteAccessMock).toHaveBeenCalledWith(
      "content_stories",
      "/admin/content/stories",
    );
    expect(loadStoryModerationSnapshotMock).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("heading", { name: "القصص" })).toBeTruthy();
    expect(screen.getByTestId("stories-table")).toBeTruthy();
  });
});
