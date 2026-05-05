import {
  fireEvent,
  render,
  screen,
  waitFor,
} from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { AdminRole } from "@/lib/navigation/admin-contract";
import type { ReviewModerationSnapshot, ReviewModerationTransport } from "@/lib/reviews";

import { ReviewCommandProvider } from "./review-command-provider";
import { ReviewModerationShell } from "./review-moderation-shell";

function createSnapshot(): ReviewModerationSnapshot {
  return {
    generatedAt: "2026-04-10T12:00:00.000Z",
    source: "callable:listVenueReviewsForAdmin",
    freshnessNote: "Moderation feed is older than expected.",
    state: "stale",
    message: "Moderation feed is older than expected.",
    filtersApplied: {
      venueId: null,
      statuses: ["flagged", "hidden"],
      limit: 25,
    },
    items: [
      {
        id: "review-1",
        venueId: "venue-1",
        venueName: "Venue One",
        authorName: "Guest Alpha",
        rating: 2,
        status: "flagged",
        snippet: "Needs moderation follow-up urgently.",
        createdAt: "2026-04-09T12:00:00.000Z",
        moderationReason: "manual_review",
        moderationNote: null,
        moderatedAt: null,
        moderatedByUid: null,
      },
      {
        id: "review-2",
        venueId: "venue-2",
        venueName: "Venue Two",
        authorName: "Guest Beta",
        rating: 5,
        status: "published",
        snippet: "Happy customer testimonial.",
        createdAt: "2026-04-08T12:00:00.000Z",
        moderationReason: null,
        moderationNote: null,
        moderatedAt: null,
        moderatedByUid: null,
      },
    ],
  };
}

function createSession(role: AdminRole) {
  return {
    uid: `${role}-uid`,
    primaryRole: role,
    roles: [role],
    roleSource: "claims" as const,
  };
}

function renderShell(options?: {
  role?: AdminRole;
  transport?: ReviewModerationTransport;
  snapshot?: ReviewModerationSnapshot;
}) {
  const snapshot = options?.snapshot ?? createSnapshot();
  const ui = <ReviewModerationShell snapshot={snapshot} canModerate={Boolean(options?.role)} />;

  if (!options?.role) {
    return render(ui);
  }

  return render(
    <ReviewCommandProvider
      session={createSession(options.role)}
      transport={options.transport}
    >
      {ui}
    </ReviewCommandProvider>,
  );
}

describe("review moderation shell", () => {
  it("renders source honesty and stale-state messaging", () => {
    renderShell();

    expect(screen.getByTestId("reviews-summary-grid")).toBeTruthy();
    expect(screen.getByText("عدد المراجعات")).toBeTruthy();
    expect(screen.getByTestId("reviews-source-note").textContent).toMatch(
      /الخدمة المتصلة/i,
    );
    expect(screen.getByTestId("reviews-source-note").textContent).toMatch(
      /البيانات قديمة مقارنة بالوقت المتوقع/i,
    );
    expect(screen.getByTestId("reviews-source-note").textContent).toMatch(
      /الخيارات الحالية/i,
    );
    expect(screen.queryByText("عدد الصفوف")).toBeNull();
  });

  it("filters rows by search, status, and venue", () => {
    renderShell();

    fireEvent.change(screen.getByTestId("reviews-search-input"), {
      target: { value: "alpha" },
    });
    expect(screen.getByTestId("review-row-review-1")).toBeTruthy();
    expect(screen.queryByTestId("review-row-review-2")).toBeNull();

    fireEvent.change(screen.getByTestId("reviews-search-input"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("reviews-status-filter"), {
      target: { value: "published" },
    });
    expect(screen.queryByTestId("review-row-review-1")).toBeNull();
    expect(screen.getByTestId("review-row-review-2")).toBeTruthy();

    fireEvent.change(screen.getByTestId("reviews-status-filter"), {
      target: { value: "" },
    });
    fireEvent.change(screen.getByTestId("reviews-venue-filter"), {
      target: { value: "Venue One" },
    });
    expect(screen.getByTestId("review-row-review-1")).toBeTruthy();
    expect(screen.queryByTestId("review-row-review-2")).toBeNull();
  });

  it("shows read-only rendering when moderation provider is absent", () => {
    renderShell();

    expect(screen.queryByRole("button", { name: /نشر/i })).toBeNull();
  });

  it("shows governed actions for content admin and surfaces unavailable transport", async () => {
    const transport: ReviewModerationTransport = {
      execute: async () => ({
        ok: false,
        error: {
          status: 503,
          message: "Reviews callable transport is unavailable.",
        },
      }),
    };

    renderShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("review-action-select-review-1"), {
      target: { value: "review_hide" },
    });
    fireEvent.click(screen.getByTestId("review-action-run-review-1"));

    // Dialog should open
    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
    });

    // Click confirm button in dialog (إخفاء for hide action) - last button is the confirm button
    const hideButtons = screen.getAllByRole("button", { name: /إخفاء/i });
    fireEvent.click(hideButtons[hideButtons.length - 1]!);

    await waitFor(() => {
      expect(screen.getByText(/الاتصال بالخدمة غير متاح/i)).toBeTruthy();
    });
  });

  it("surfaces App Check failures without labeling them as conflicts", async () => {
    const transport: ReviewModerationTransport = {
      execute: async () => ({
        ok: false,
        error: {
          status: 403,
          message: "App Check verification failed",
        },
      }),
    };

    renderShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("review-action-select-review-1"), {
      target: { value: "review_hide" },
    });
    fireEvent.click(screen.getByTestId("review-action-run-review-1"));

    // Dialog should open
    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
    });

    // Click confirm button in dialog (إخفاء for hide action) - last button is the confirm button
    const hideButtons = screen.getAllByRole("button", { name: /إخفاء/i });
    fireEvent.click(hideButtons[hideButtons.length - 1]!);

    await waitFor(() => {
      expect(screen.getByText(/تعذر التحقق من أمان الطلب الحالي/i)).toBeTruthy();
    });
  });

  it("surfaces successful moderation completion state", async () => {
    const transport: ReviewModerationTransport = {
      execute: async (_action, request) => ({
        ok: true,
        correlationId: request.correlationId,
        data: {
          reviewId: request.target.reviewId,
          venueId: request.target.venueId,
          status: "hidden",
          moderationState: "hidden",
          auditEventId: "audit-1",
          moderatedAt: Date.now(),
        },
      }),
    };

    renderShell({ role: "content_admin", transport });

    fireEvent.change(screen.getByTestId("review-action-select-review-1"), {
      target: { value: "review_hide" },
    });
    fireEvent.click(screen.getByTestId("review-action-run-review-1"));

    // Dialog should open
    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
    });

    // Click confirm button in dialog (إخفاء for hide action) - last button is the confirm button
    const hideButtons = screen.getAllByRole("button", { name: /إخفاء/i });
    fireEvent.click(hideButtons[hideButtons.length - 1]!);

    await waitFor(() => {
      expect(screen.getByText(/تم تنفيذ إخفاء بنجاح/i)).toBeTruthy();
    });
  });

  it("renders explicit unavailable state when the moderation feed is unavailable", () => {
    renderShell({
      snapshot: {
        ...createSnapshot(),
        state: "unavailable",
        message: "Review moderation source unavailable.",
        items: [],
      },
    });

    expect(screen.getByTestId("reviews-unavailable").textContent).toMatch(
      /مصدر البيانات غير متاح/i,
    );
  });
});
