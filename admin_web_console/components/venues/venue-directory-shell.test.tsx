import { fireEvent, render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type {
  VenueDirectoryReadData,
  VenueDirectorySummary,
} from "@/lib/venues/venue-directory-models";
import type { VenueManagementTransport } from "@/lib/venues/venue-command-adapters";
import type { VenueDirectoryReadResult } from "@/lib/venues/venue-directory-read-types";

import { VenueCommandProvider } from "./venue-command-provider";
import { VenueDirectoryReadBanner } from "./venue-directory-read-banner";
import { VenueDirectoryShell } from "./venue-directory-shell";

function buildSummary(total: number): VenueDirectorySummary {
  return {
    totalVenues: total,
    readiness: { ready: total, warning: 0, fail: 0, unknown: 0 },
    wallet: { active: total, low_balance: 0, inactive: 0, unknown: 0 },
    merchantLinks: { linked: total, unlinked: 0, unknown: 0 },
    subscriptions: { active: total, expired: 0, paused: 0 },
    visibility: { visible: total, hidden: 0 },
    operational: { active: total, suspended: 0, archived: 0 },
  };
}

function createSession(primaryRole: AdminSession["primaryRole"]): AdminSession {
  return {
    uid: `${primaryRole}-uid`,
    primaryRole,
    roles: [primaryRole],
    roleSource: "claims",
  };
}

function createTransportStub(): VenueManagementTransport {
  return {
    async execute(command) {
      switch (command.action) {
        case "create_venue":
          return {
            ok: true,
            data: {
              action: "create_venue",
              venueId: "venue_created",
              status: "created",
              auditEventId: "audit_created",
            },
          };
        case "update_venue_visibility":
          return {
            ok: true,
            data: {
              action: "update_venue_visibility",
              venueId: command.venueId,
              newVisibility: command.newVisibility,
              status: "updated",
              auditEventId: "audit_visibility",
            },
          };
        case "update_venue_operational_status":
          return {
            ok: true,
            data: {
              action: "update_venue_operational_status",
              venueId: command.venueId,
              newStatus: command.newStatus,
              status: "updated",
              auditEventId: "audit_operational",
            },
          };
        case "update_venue_subscription_status":
          return {
            ok: true,
            data: {
              action: "update_venue_subscription_status",
              venueId: command.venueId,
              newStatus: command.newStatus,
              status: "updated",
              auditEventId: "audit_subscription",
            },
          };
        case "update_venue_profile":
          return {
            ok: true,
            data: {
              action: "update_venue_profile",
              venueId: command.venueId,
              status: "updated",
              auditEventId: "audit_profile",
            },
          };
      }
    },
  };
}

function renderWithVenueCommands(session: AdminSession) {
  return render(
    <VenueCommandProvider session={session} transport={createTransportStub()}>
      <VenueDirectoryShell readResult={successRead()} />
    </VenueCommandProvider>,
  );
}

function successRead(): VenueDirectoryReadResult<VenueDirectoryReadData> {
  const items: VenueDirectoryReadData["items"] = [
    {
      venueId: "venue_alpha",
      venueName: "Alpha Cafe",
      venueNameEn: "Alpha Cafe",
      city: "Ramallah",
      categories: ["cafe"],
      phone: "0599000001",
      readinessStatus: "ready",
      readinessSummary: "Ready",
      walletStatus: "active",
      walletSummary: "Balance: ILS 100",
      walletBalance: 100,
      walletCurrency: "ILS",
      merchantLinkStatus: "linked",
      merchantLinkSummary: "Linked",
      merchantLinkedCount: 1,
      subscriptionStatus: "active",
      visibilityStatus: "visible",
      operationalStatus: "active",
      workspacePath: "/admin/venues/venue_alpha",
    },
    {
      venueId: "venue_beta",
      venueName: "Beta Grill",
      venueNameEn: null,
      city: "Nablus",
      categories: ["restaurant"],
      phone: null,
      readinessStatus: "warning",
      readinessSummary: "Warning",
      walletStatus: "low_balance",
      walletSummary: "Low balance",
      walletBalance: 5,
      walletCurrency: "ILS",
      merchantLinkStatus: "unlinked",
      merchantLinkSummary: "Unlinked",
      merchantLinkedCount: 0,
      subscriptionStatus: "expired",
      visibilityStatus: "hidden",
      operationalStatus: "suspended",
      workspacePath: "/admin/venues/venue_beta",
    },
  ];

  return {
    kind: "success",
    data: {
      items,
      filters: {
        cities: ["Nablus", "Ramallah"],
        categories: ["cafe", "restaurant"],
      },
      summary: buildSummary(items.length),
      readBudget: {
        sourceMode: "admin_list_callable",
        boundsScanned: 0,
        perBoundLimit: null,
        maxPagesPerBound: null,
        maxResultsBudget: 150,
        truncatedBounds: [],
        partialResults: false,
      },
    },
    asOf: "2026-04-10T10:00:00.000Z",
    fetchedAt: "2026-04-10T10:00:10.000Z",
    source: "callable:listVenuesForAdmin",
    stale: false,
  };
}

describe("venue directory shell", () => {
  it("filters rows by search text, city, and category", () => {
    render(<VenueDirectoryShell readResult={successRead()} />);

    expect(screen.getByTestId("venue-directory-row-venue_alpha")).toBeTruthy();
    expect(screen.getByTestId("venue-directory-row-venue_beta")).toBeTruthy();

    fireEvent.change(screen.getByTestId("venue-directory-search-input"), {
      target: { value: "alpha" },
    });

    expect(screen.getByTestId("venue-directory-row-venue_alpha")).toBeTruthy();
    expect(screen.queryByTestId("venue-directory-row-venue_beta")).toBeNull();

    fireEvent.change(screen.getByTestId("venue-directory-search-input"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("venue-directory-city-filter"), {
      target: { value: "Nablus" },
    });

    expect(screen.queryByTestId("venue-directory-row-venue_alpha")).toBeNull();
    expect(screen.getByTestId("venue-directory-row-venue_beta")).toBeTruthy();

    fireEvent.change(screen.getByTestId("venue-directory-city-filter"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("venue-directory-category-filter"), {
      target: { value: "cafe" },
    });

    expect(screen.getByTestId("venue-directory-row-venue_alpha")).toBeTruthy();
    expect(screen.queryByTestId("venue-directory-row-venue_beta")).toBeNull();
  });

  it("filters rows by subscription, visibility, and operational statuses", () => {
    render(<VenueDirectoryShell readResult={successRead()} />);

    fireEvent.change(screen.getByTestId("venue-directory-subscription-filter"), {
      target: { value: "expired" },
    });
    expect(screen.queryByTestId("venue-directory-row-venue_alpha")).toBeNull();
    expect(screen.getByTestId("venue-directory-row-venue_beta")).toBeTruthy();

    fireEvent.change(screen.getByTestId("venue-directory-subscription-filter"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("venue-directory-visibility-filter"), {
      target: { value: "hidden" },
    });
    expect(screen.queryByTestId("venue-directory-row-venue_alpha")).toBeNull();
    expect(screen.getByTestId("venue-directory-row-venue_beta")).toBeTruthy();

    fireEvent.change(screen.getByTestId("venue-directory-visibility-filter"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("venue-directory-operational-filter"), {
      target: { value: "active" },
    });
    expect(screen.getByTestId("venue-directory-row-venue_alpha")).toBeTruthy();
    expect(screen.queryByTestId("venue-directory-row-venue_beta")).toBeNull();
  });

  it("maps directory rows to workspace routes", () => {
    render(<VenueDirectoryShell readResult={successRead()} />);

    const alphaRow = screen.getByTestId("venue-directory-row-venue_alpha");
    const betaRow = screen.getByTestId("venue-directory-row-venue_beta");

    const alphaLink = within(alphaRow).getByRole("link", { name: /فتح التفاصيل/i });
    const betaLink = within(betaRow).getByRole("link", { name: /فتح التفاصيل/i });

    expect(alphaLink.getAttribute("href")).toBe("/admin/venues/venue_alpha");
    expect(betaLink.getAttribute("href")).toBe("/admin/venues/venue_beta");
  });

  it("renders explicit no-match state when filters exclude all rows", () => {
    render(<VenueDirectoryShell readResult={successRead()} />);

    fireEvent.change(screen.getByTestId("venue-directory-search-input"), {
      target: { value: "does-not-exist" },
    });

    expect(screen.getByTestId("venue-directory-filter-empty-state")).toBeTruthy();
  });

  it("shows result count and clears active filters", () => {
    render(<VenueDirectoryShell readResult={successRead()} />);

    expect(screen.getByTestId("venue-directory-result-count").textContent).toMatch(
      /يعرض 2 من أصل 2 جهة/i,
    );

    fireEvent.change(screen.getByTestId("venue-directory-search-input"), {
      target: { value: "alpha" },
    });

    expect(screen.getByTestId("venue-directory-result-count").textContent).toMatch(
      /يعرض 1 من أصل 2 جهة/i,
    );

    const clearButton = screen.getByTestId("venue-directory-clear-filters");
    expect(clearButton.textContent).toMatch(/مسح الفلاتر \(1\)/i);

    fireEvent.click(clearButton);

    const searchInput = screen.getByTestId("venue-directory-search-input") as HTMLInputElement;
    const cityFilter = screen.getByTestId("venue-directory-city-filter") as HTMLSelectElement;

    expect(searchInput.value).toBe("");
    expect(cityFilter.value).toBe("");
    expect(screen.getByTestId("venue-directory-row-venue_alpha")).toBeTruthy();
    expect(screen.getByTestId("venue-directory-row-venue_beta")).toBeTruthy();
    expect(screen.queryByTestId("venue-directory-clear-filters")).toBeNull();
  });

  it("renders explicit unavailable state", () => {
    render(
      <VenueDirectoryShell
        readResult={{
          kind: "unavailable",
          message: "Source unavailable",
          attemptedSource: "callable:searchVenuesInBounds",
        }}
      />,
    );

    expect(screen.getByTestId("venue-directory-unavailable").textContent).toMatch(
      /المصدر غير متاح/i,
    );
  });

  it("stays read-only with no mutation action controls", () => {
    render(<VenueDirectoryShell readResult={successRead()} />);

    expect(screen.getByTestId("venue-directory-read-only-note").textContent).toMatch(/للعرض فقط/);
    expect(screen.queryByRole("button", { name: /إضافة جهة/i })).toBeNull();
  });

  it("shows create action for super_admin", () => {
    renderWithVenueCommands(createSession("super_admin"));

    expect(screen.getByRole("button", { name: "إضافة جهة" })).toBeTruthy();

    const alphaSelect = screen.getByTestId("venue-action-select-venue_alpha");
    expect(within(alphaSelect).getByRole("option", { name: "تعديل الملف" })).toBeTruthy();
    expect(within(alphaSelect).getByRole("option", { name: "إخفاء" })).toBeTruthy();
    expect(screen.getByTestId("venue-action-run-venue_alpha")).toBeTruthy();
  });

  it("limits content_admin to profile and visibility actions", () => {
    renderWithVenueCommands(createSession("content_admin"));

    expect(screen.queryByRole("button", { name: "إضافة جهة" })).toBeNull();

    const alphaSelect = screen.getByTestId("venue-action-select-venue_alpha");
    expect(within(alphaSelect).getByRole("option", { name: "تعديل الملف" })).toBeTruthy();
    expect(within(alphaSelect).getByRole("option", { name: "إخفاء" })).toBeTruthy();
    expect(within(alphaSelect).queryByRole("option", { name: /حالة العمل:/ })).toBeNull();
    expect(within(alphaSelect).queryByRole("option", { name: /الاشتراك:/ })).toBeNull();
  });

  it("renders stale banner state for successful stale reads", () => {
    const staleRead = successRead();
    if (staleRead.kind === "success") {
      staleRead.stale = true;
    }

    render(<VenueDirectoryReadBanner result={staleRead} label="قراءة قائمة الجهات" />);

    expect(screen.getByTestId("venue-directory-read-stale")).toBeTruthy();
    expect(screen.getByTestId("venue-directory-read-banner").getAttribute("data-read-stale")).toBe(
      "true",
    );
  });

  it("renders scan budget and truncation honesty when callable budget is partial", () => {
    const partialRead = successRead();
    if (partialRead.kind === "success") {
      partialRead.data.readBudget.partialResults = true;
      partialRead.data.readBudget.truncatedBounds = ["ramallah", "nablus"];
    }

    render(<VenueDirectoryShell readResult={partialRead} />);

    expect(screen.getByTestId("venue-directory-budget-note").textContent).toMatch(/البيانات الحالية جزئية/);
    expect(screen.getByTestId("venue-directory-budget-truncated").textContent).toMatch(
      /ramallah, nablus/i,
    );
  });
});
