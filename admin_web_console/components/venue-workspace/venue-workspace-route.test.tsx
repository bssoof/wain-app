import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { VenueWorkspaceReadBundle } from "@/lib/venues/venue-workspace-read-loader";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadVenueWorkspaceReadBundleMock = vi.fn();

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/venues", () => ({
  loadVenueWorkspaceReadBundle: (...args: unknown[]) =>
    loadVenueWorkspaceReadBundleMock(...args),
}));

function session(): AdminSession {
  return {
    uid: "admin_1",
    primaryRole: "ops_viewer",
    roles: ["ops_viewer"],
    roleSource: "claims",
  };
}

function readBundle(): VenueWorkspaceReadBundle {
  return {
    context: {
      venueId: "venue_route_1",
      venueName: "Venue route_1",
      walletBalance: 120,
      walletCurrency: "ILS",
      readinessStatus: "ready",
      readinessSummary: "Ready",
    },
    wallet: {
      kind: "success",
      data: { entries: [] },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:10.000Z",
      source: "development_fixture",
      stale: false,
    },
    offers: {
      kind: "success",
      data: { items: [] },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:10.000Z",
      source: "development_fixture",
      stale: false,
    },
    stories: {
      kind: "success",
      data: { items: [] },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:10.000Z",
      source: "development_fixture",
      stale: false,
    },
    reviews: {
      kind: "success",
      data: { items: [] },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:10.000Z",
      source: "development_fixture",
      stale: false,
    },
  };
}

describe("venue workspace route", () => {
  it("loads the dynamic venue workspace route and renders shell content", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "venues",
      path: "/admin/venues",
      title: "Venue Directory",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    loadVenueWorkspaceReadBundleMock.mockResolvedValue(readBundle());

    const module = await import("@/app/(protected)/admin/venues/[venueId]/page");
    const AdminVenueWorkspacePage = module.default;

    const ui = await AdminVenueWorkspacePage({
      params: { venueId: "venue_route_1" },
    });

    render(ui);

    expect(requireRouteAccessMock).toHaveBeenCalledWith(
      "venues",
      "/admin/venues/venue_route_1",
    );
    expect(loadVenueWorkspaceReadBundleMock).toHaveBeenCalledWith("venue_route_1");
    expect(screen.getByTestId("venue-workspace-shell")).toBeTruthy();
    expect(screen.getByText(/تعرض هذه الصفحة بيانات الجهة/i)).toBeTruthy();
  });
});
