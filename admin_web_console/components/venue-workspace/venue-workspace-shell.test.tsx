import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { VenueWorkspaceReadBundle } from "@/lib/venues/venue-workspace-read-loader";

import { VenueWorkspaceShell } from "./venue-workspace-shell";

function buildReadBundle(): VenueWorkspaceReadBundle {
  return {
    context: {
      venueId: "venue_test_1",
      venueName: "Venue test_1",
      walletBalance: 148.25,
      walletCurrency: "ILS",
      readinessStatus: "warning",
      readinessSummary: "One upstream warning is active.",
    },
    wallet: {
      kind: "success",
      data: {
        entries: [
          {
            id: "entry_1",
            type: "credit",
            amount: 200,
            currency: "ILS",
            description: "Top-up",
            createdAt: "2026-04-10T10:00:00.000Z",
          },
        ],
      },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:05.000Z",
      source: "callable:workspace_wallet",
      stale: true,
    },
    offers: {
      kind: "success",
      data: {
        items: [
          {
            id: "offer_1",
            title: "Offer title",
            status: "active",
            startsAt: "2026-04-10T10:00:00.000Z",
            endsAt: "2026-04-11T10:00:00.000Z",
          },
        ],
      },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:05.000Z",
      source: "callable:workspace_offers",
      stale: false,
    },
    stories: {
      kind: "unavailable",
      message: "Stories source timed out",
      attemptedSource: "callable:workspace_stories",
    },
    reviews: {
      kind: "success",
      data: { items: [] },
      asOf: "2026-04-10T10:00:00.000Z",
      fetchedAt: "2026-04-10T10:00:05.000Z",
      source: "development_fixture",
      stale: false,
    },
  };
}

describe("venue workspace shell", () => {
  it("renders venue context header with readiness and wallet summary", () => {
    render(
      <VenueWorkspaceShell
        venueId="venue_test_1"
        readBundle={buildReadBundle()}
      />,
    );

    expect(screen.getByTestId("venue-workspace-venue-name").textContent).toMatch(
      /venue test_1/i,
    );
    expect(
      screen.getByTestId("venue-workspace-readiness-badge").textContent,
    ).toMatch(/حالة النظام:/);
    expect(screen.getByTestId("venue-workspace-wallet-summary").textContent).toMatch(
      /المحفظة:/,
    );
    expect(screen.getByTestId("venue-workspace-back-link").getAttribute("href")).toBe(
      "/admin/venues",
    );
  });

  it("switches tabs and renders the correct read-only content", () => {
    render(
      <VenueWorkspaceShell
        venueId="venue_test_1"
        readBundle={buildReadBundle()}
      />,
    );

    expect(screen.getByTestId("venue-workspace-panel-wallet")).toBeTruthy();
    expect(screen.getByText(/top-up/i)).toBeTruthy();

    fireEvent.click(screen.getByTestId("venue-workspace-tab-offers"));
    expect(screen.getByTestId("venue-workspace-panel-offers")).toBeTruthy();
    expect(screen.getByText(/offer title/i)).toBeTruthy();

    fireEvent.click(screen.getByTestId("venue-workspace-tab-reviews"));
    expect(screen.getByTestId("venue-workspace-panel-reviews")).toBeTruthy();
    expect(screen.getByTestId("venue-tab-empty-reviews")).toBeTruthy();
  });

  it("shows unavailable and stale state indicators for tabs", () => {
    render(
      <VenueWorkspaceShell
        venueId="venue_test_1"
        readBundle={buildReadBundle()}
      />,
    );

    expect(screen.getByTestId("venue-read-stale-wallet")).toBeTruthy();

    fireEvent.click(screen.getByTestId("venue-workspace-tab-stories"));
    expect(screen.getByTestId("venue-tab-unavailable-stories").textContent).toMatch(
      /انتهت مهلة المصدر/i,
    );
  });

  it("keeps the workspace strictly read-only with no mutation controls", () => {
    render(
      <VenueWorkspaceShell
        venueId="venue_test_1"
        readBundle={buildReadBundle()}
      />,
    );

    expect(screen.getByTestId("venue-workspace-read-only-note").textContent).toMatch(/للعرض فقط|العرض فقط/);
    expect(
      screen.queryByRole("button", {
        name: /approve|reject|reverse|delete|edit|create/i,
      }),
    ).toBeNull();
  });
});
