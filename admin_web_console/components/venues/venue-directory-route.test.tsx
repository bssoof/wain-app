import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { VenueDirectoryReadResult } from "@/lib/venues/venue-directory-read-types";
import type { VenueDirectoryReadData } from "@/lib/venues/venue-directory-models";

const requireRouteAccessMock = vi.fn();
const getRouteDefinitionMock = vi.fn();
const loadVenueDirectoryReadMock = vi.fn();

vi.mock("@/lib/auth/route-guards", () => ({
  requireRouteAccess: (...args: unknown[]) => requireRouteAccessMock(...args),
}));

vi.mock("@/lib/navigation/admin-route-map", () => ({
  getRouteDefinition: (...args: unknown[]) => getRouteDefinitionMock(...args),
}));

vi.mock("@/lib/venues", () => ({
  loadVenueDirectoryRead: (...args: unknown[]) => loadVenueDirectoryReadMock(...args),
}));

function session(): AdminSession {
  return {
    uid: "admin_venues_1",
    primaryRole: "super_admin",
    roles: ["super_admin"],
    roleSource: "claims",
  };
}

function readResult(): VenueDirectoryReadResult<VenueDirectoryReadData> {
  return {
    kind: "success",
    data: {
      items: [
        {
          venueId: "venue_route_1",
          venueName: "Venue route_1",
          venueNameEn: "Venue route_1",
          city: "Ramallah",
          categories: ["cafe"],
          phone: "0599000002",
          readinessStatus: "ready",
          readinessSummary: "Ready",
          walletStatus: "active",
          walletSummary: "Balance",
          walletBalance: 120,
          walletCurrency: "ILS",
          merchantLinkStatus: "linked",
          merchantLinkSummary: "Linked",
          merchantLinkedCount: 1,
          subscriptionStatus: "active",
          visibilityStatus: "visible",
          operationalStatus: "active",
          workspacePath: "/admin/venues/venue_route_1",
        },
      ],
      summary: {
        totalVenues: 1,
        readiness: { ready: 1, warning: 0, fail: 0, unknown: 0 },
        wallet: { active: 1, low_balance: 0, inactive: 0, unknown: 0 },
        merchantLinks: { linked: 1, unlinked: 0, unknown: 0 },
        subscriptions: { active: 1, expired: 0, paused: 0 },
        visibility: { visible: 1, hidden: 0 },
        operational: { active: 1, suspended: 0, archived: 0 },
      },
      filters: {
        cities: ["Ramallah"],
        categories: ["cafe"],
      },
      readBudget: {
        sourceMode: "snapshot",
        boundsScanned: 0,
        perBoundLimit: null,
        maxPagesPerBound: null,
        maxResultsBudget: null,
        truncatedBounds: [],
        partialResults: false,
      },
    },
    asOf: "2026-04-10T10:00:00.000Z",
    fetchedAt: "2026-04-10T10:00:10.000Z",
    source: "development_fixture",
    stale: false,
  };
}

describe("venue directory route", () => {
  it("requires route access and renders the operational venue directory", async () => {
    getRouteDefinitionMock.mockReturnValue({
      key: "venues",
      path: "/admin/venues",
      title: "Venue Directory",
      scopeNote: "Operational read-only directory",
    });
    requireRouteAccessMock.mockResolvedValue(session());
    loadVenueDirectoryReadMock.mockResolvedValue(readResult());

    const module = await import("@/app/(protected)/admin/venues/page");
    const AdminVenuesPage = module.default;

    const ui = await AdminVenuesPage();
    render(ui);

    expect(requireRouteAccessMock).toHaveBeenCalledWith("venues", "/admin/venues");
    expect(loadVenueDirectoryReadMock).toHaveBeenCalledTimes(1);
    expect(screen.getByTestId("venue-directory-shell")).toBeTruthy();
    expect(screen.getByTestId("venue-directory-read-banner")).toBeTruthy();
    expect(screen.getByRole("button", { name: "إضافة جهة" })).toBeTruthy();
    expect(
      screen.getByRole("link", {
        name: /فتح التفاصيل/i,
      }).getAttribute("href"),
    ).toBe("/admin/venues/venue_route_1");
  });
});
