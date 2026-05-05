"use client";

import {
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { AdminRole } from "@/lib/navigation/admin-contract";
import type { ContentCommandTransport } from "@/lib/content/content-command-transport";
import type {
  OfferModerationSnapshot,
  StoryModerationSnapshot,
} from "@/lib/content/content-models";

import { ContentCommandProvider } from "./content-command-provider";
import { OffersManagementShell } from "./offers-management-shell";
import { StoriesManagementShell } from "./stories-management-shell";

function createSession(role: AdminRole) {
  return {
    uid: `${role}-uid`,
    primaryRole: role,
    roles: [role],
    roleSource: "claims" as const,
  };
}

function createOfferSnapshot(): OfferModerationSnapshot {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    source: "callable:listOffersForAdmin",
    freshnessNote: "Offer moderation feed is fresh.",
    state: "success",
    filtersApplied: {
      venueId: null,
      statuses: ["pending"],
      limit: 50,
    },
    items: [
      {
        id: "offer-1",
        venueId: "venue-1",
        venueName: "Venue One",
        title: "Pending Offer",
        description: "Needs review",
        adminState: "pending",
        isActive: true,
        isFeatured: false,
        createdAt: "2026-04-10T12:00:00.000Z",
        updatedAt: "2026-04-10T12:00:00.000Z",
      },
      {
        id: "offer-2",
        venueId: "venue-2",
        venueName: "Venue Two",
        title: "Approved Offer",
        description: "Already approved",
        adminState: "approved",
        isActive: true,
        isFeatured: true,
        featuredUntil: "2026-04-14T12:00:00.000Z",
        createdAt: "2026-04-09T12:00:00.000Z",
        updatedAt: "2026-04-09T12:00:00.000Z",
      },
    ],
  };
}

function createStorySnapshot(): StoryModerationSnapshot {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    source: "callable:listStoriesForAdmin",
    freshnessNote: "Story moderation feed is stale.",
    state: "stale",
    message: "Story moderation feed is stale.",
    filtersApplied: {
      venueId: null,
      statuses: ["pending"],
      limit: 50,
    },
    items: [
      {
        id: "story-1",
        venueId: "venue-1",
        venueName: "Venue One",
        caption: "Pending Story Caption",
        adminState: "pending",
        isActive: true,
        isPromoted: false,
        createdAt: "2026-04-10T12:00:00.000Z",
        updatedAt: "2026-04-10T12:00:00.000Z",
      },
      {
        id: "story-2",
        venueId: "venue-2",
        venueName: "Venue Two",
        caption: "Flagged Story Caption",
        adminState: "flagged",
        isActive: false,
        isPromoted: false,
        createdAt: "2026-04-09T12:00:00.000Z",
        updatedAt: "2026-04-09T12:00:00.000Z",
      },
    ],
  };
}

function renderOffersShell(options?: {
  role?: AdminRole;
  transport?: ContentCommandTransport;
  snapshot?: OfferModerationSnapshot;
  canModerate?: boolean;
}) {
  const snapshot = options?.snapshot ?? createOfferSnapshot();
  const canModerate = options?.canModerate ?? Boolean(options?.role);
  const ui = (
    <OffersManagementShell snapshot={snapshot} canModerate={canModerate} />
  );

  if (!options?.role) {
    return render(ui);
  }

  return render(
    <ContentCommandProvider
      session={createSession(options.role)}
      transport={options.transport}
    >
      {ui}
    </ContentCommandProvider>,
  );
}

function renderStoriesShell(options?: {
  role?: AdminRole;
  transport?: ContentCommandTransport;
  snapshot?: StoryModerationSnapshot;
  canModerate?: boolean;
}) {
  const snapshot = options?.snapshot ?? createStorySnapshot();
  const canModerate = options?.canModerate ?? Boolean(options?.role);
  const ui = (
    <StoriesManagementShell snapshot={snapshot} canModerate={canModerate} />
  );

  if (!options?.role) {
    return render(ui);
  }

  return render(
    <ContentCommandProvider
      session={createSession(options.role)}
      transport={options.transport}
    >
      {ui}
    </ContentCommandProvider>,
  );
}

describe("content management shells", () => {
  it("renders offers source honesty and filters rows by search and state", () => {
    renderOffersShell();

    expect(screen.getByTestId("offers-summary-grid")).toBeTruthy();
    expect(screen.getByTestId("offers-source-note").textContent).toMatch(
      /الخدمة المتصلة/i,
    );

    fireEvent.change(screen.getByTestId("offers-search-input"), {
      target: { value: "Venue Two" },
    });
    expect(screen.queryByTestId("offer-row-offer-1")).toBeNull();
    expect(screen.getByTestId("offer-row-offer-2")).toBeTruthy();

    fireEvent.change(screen.getByTestId("offers-search-input"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("offers-state-filter"), {
      target: { value: "approved" },
    });
    expect(screen.queryByTestId("offer-row-offer-1")).toBeNull();
    expect(screen.getByTestId("offer-row-offer-2")).toBeTruthy();
  });

  it("keeps offers read-only when moderation provider is absent", () => {
    renderOffersShell({ canModerate: false });

    expect(screen.queryByRole("button", { name: /اعتماد/i })).toBeNull();
  });

  it("shows unavailable offer moderation transport explicitly", async () => {
    const transport: ContentCommandTransport = {
      moderateOffer: async () => {
        throw new Error("Offer moderation transport is unavailable.");
      },
      moderateStory: async () => {
        throw new Error("Story moderation transport is unavailable.");
      },
    };

    renderOffersShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("content-action-select-offer-offer-1"), {
      target: { value: "approve" },
    });
    fireEvent.click(screen.getByTestId("content-action-run-offer-offer-1"));

    // Dialog should open
    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
    });

    // Click confirm button in dialog (قبول for approve action) - last button is the confirm button
    const approveButtons = screen.getAllByRole("button", { name: /قبول/i });
    fireEvent.click(approveButtons[approveButtons.length - 1]!);

    await waitFor(() => {
      expect(screen.getByText(/الاتصال بالخدمة غير متاح/i)).toBeTruthy();
    });
  });

  it("shows successful offer moderation completion", async () => {
    const transport: ContentCommandTransport = {
      moderateOffer: async (command) => ({
        success: true,
        action: command.action,
        commandId: command.commandId,
        newAdminState: "approved",
        isActive: true,
        auditEventId: "offer-audit-1",
      }),
      moderateStory: async () => {
        throw new Error("Story moderation transport is unavailable.");
      },
    };

    renderOffersShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("content-action-select-offer-offer-1"), {
      target: { value: "approve" },
    });
    fireEvent.click(screen.getByTestId("content-action-run-offer-offer-1"));

    // Dialog should open
    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
    });

    // Click confirm button in dialog (قبول for approve action) - last button is the confirm button
    const approveButtons = screen.getAllByRole("button", { name: /قبول/i });
    fireEvent.click(approveButtons[approveButtons.length - 1]!);

    await waitFor(() => {
      expect(screen.getByText(/تم تنفيذ اعتماد بنجاح/i)).toBeTruthy();
    });
  });

  it("renders stories source honesty and filters rows by search and state", () => {
    renderStoriesShell();

    expect(screen.getByTestId("stories-summary-grid")).toBeTruthy();
    expect(screen.getByTestId("stories-source-note").textContent).toMatch(
      /الخدمة المتصلة/i,
    );

    fireEvent.change(screen.getByTestId("stories-search-input"), {
      target: { value: "Venue Two" },
    });
    expect(screen.queryByTestId("story-row-story-1")).toBeNull();
    expect(screen.getByTestId("story-row-story-2")).toBeTruthy();

    fireEvent.change(screen.getByTestId("stories-search-input"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("stories-state-filter"), {
      target: { value: "flagged" },
    });
    expect(screen.queryByTestId("story-row-story-1")).toBeNull();
    expect(screen.getByTestId("story-row-story-2")).toBeTruthy();
  });

  it("keeps stories read-only when moderation provider is absent", () => {
    renderStoriesShell({ canModerate: false });

    expect(screen.queryByRole("button", { name: /اعتماد/i })).toBeNull();
  });

  it("shows successful story moderation completion", async () => {
    const transport: ContentCommandTransport = {
      moderateOffer: async () => {
        throw new Error("Offer moderation transport is unavailable.");
      },
      moderateStory: async (command) => ({
        success: true,
        action: command.action,
        commandId: command.commandId,
        newAdminState: "paused",
        isActive: false,
        auditEventId: "story-audit-1",
      }),
    };

    renderStoriesShell({ role: "content_admin", transport });

    // Click pause button (opens dialog)
    const pauseButtons = screen.getAllByRole("button", { name: /إيقاف/i });
    fireEvent.click(pauseButtons[0]!);

    // Dialog should open
    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
    });

    // Click confirm button in dialog (إيقاف for pause action) - last button is the confirm button
    const confirmButtons = screen.getAllByRole("button", { name: /إيقاف/i });
    fireEvent.click(confirmButtons[confirmButtons.length - 1]!);

    await waitFor(() => {
      expect(screen.getByText(/تم تنفيذ إيقاف بنجاح/i)).toBeTruthy();
    });
  });

  it("renders explicit unavailable state for stories when the feed is unavailable", () => {
    renderStoriesShell({
      snapshot: {
        ...createStorySnapshot(),
        state: "unavailable",
        message: "Stories moderation source unavailable.",
        items: [],
      },
    });

    expect(screen.getByTestId("stories-unavailable").textContent).toMatch(
      /مصدر البيانات غير متاح/i,
    );
  });
});
