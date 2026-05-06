import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { MediaCenterBaseline } from "@/lib/media";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadMediaCenterBaselineMock = vi.fn();

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/media/media-center-baseline", () => ({
  loadMediaCenterBaseline: (...args: unknown[]) =>
    loadMediaCenterBaselineMock(...args),
}));

function session(): AdminSession {
  return {
    uid: "admin_media_1",
    primaryRole: "support_admin",
    roles: ["support_admin"],
    roleSource: "claims",
  };
}

function baseline(): MediaCenterBaseline {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    sections: [
      {
        key: "proofs",
        title: "Proof Images",
        scopeNote: "Proof inventory",
        state: "stale",
        source: "development_fixture",
        freshnessNote: "Fixture is stale.",
        referenceSafetyNote: "Reference safety unknown.",
        referenceIndexHealth: "stale",
        purgeBlocked: true,
        items: [
          {
            id: "proof_route_1",
            title: "Proof route asset",
            venueName: "Route Venue",
            uploadedAt: "2026-04-09T12:00:00.000Z",
            sourceDocument: "merchant_topup_requests/topup_route_1",
            referenceType: "topup_request",
            referenceId: "topup_route_1",
            sourceLabel: "merchant_topup_requests",
            referenceSafety: "unknown",
            referenceIndexHealth: "stale",
            purgeBlocked: true,
            mediaUrl: "https://cdn.wain.test/media/topup_route_1.jpg",
            previewNote: "Route proof preview",
          },
        ],
      },
      {
        key: "venue_photos",
        title: "Venue Photos",
        scopeNote: "Venue inventory",
        state: "success",
        source: "development_fixture",
        freshnessNote: "Fixture is current enough.",
        referenceSafetyNote: "Safe reference",
        referenceIndexHealth: "healthy",
        purgeBlocked: false,
        items: [],
      },
      {
        key: "offer_images",
        title: "Offer Images",
        scopeNote: "Offer inventory",
        state: "empty",
        source: "development_fixture",
        freshnessNote: "No rows",
        referenceSafetyNote: "No rows",
        referenceIndexHealth: "healthy",
        purgeBlocked: false,
        items: [],
        message: "No offer images.",
      },
      {
        key: "story_images",
        title: "Story Images",
        scopeNote: "Story inventory",
        state: "unavailable",
        source: "unavailable",
        freshnessNote: "Unavailable",
        referenceSafetyNote: "Unavailable",
        referenceIndexHealth: "unavailable",
        purgeBlocked: true,
        items: [],
        message: "Story source unavailable.",
      },
    ],
  };
}

describe("media center route", () => {
  it("requires route access and renders the media center baseline", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "media",
      path: "/admin/media",
      title: "Media Center",
      scopeNote: "Read-only media inventory baseline",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    loadMediaCenterBaselineMock.mockResolvedValue(baseline());

    const module = await import("@/app/(protected)/admin/media/page");
    const AdminMediaPage = module.default;

    const ui = await AdminMediaPage();
    render(ui);

    expect(requireRouteAccessMock).toHaveBeenCalledWith("media", "/admin/media");
    expect(loadMediaCenterBaselineMock).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("heading", { name: "Media Center" })).toBeTruthy();
    expect(screen.getByTestId("media-center-shell")).toBeTruthy();
    expect(screen.getByTestId("media-center-tab-proofs")).toBeTruthy();
  });
});
