import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  buildReviewItemActionAffordances,
  computeReviewAffordances,
  getReviewActionStateClass,
} from "./review-surface-affordances";
import type { ReviewModerationItem } from "./review-moderation-models";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "test-user",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

describe("computeReviewAffordances RBAC", () => {
  it("denies access to non-session", () => {
    const affordances = computeReviewAffordances(null);
    expect(affordances.canReviewPublish).toBe(false);
    expect(affordances.canReviewHide).toBe(false);
    expect(affordances.canReviewEscalate).toBe(false);
  });

  it("denies access to finance_admin", () => {
    const session = createSession("finance_admin");
    const affordances = computeReviewAffordances(session);
    expect(affordances.canReviewPublish).toBe(false);
    expect(affordances.canReviewHide).toBe(false);
    expect(affordances.canReviewEscalate).toBe(false);
  });

  it("grants access to super_admin", () => {
    const session = createSession("super_admin");
    const affordances = computeReviewAffordances(session);
    expect(affordances.canReviewPublish).toBe(true);
    expect(affordances.canReviewHide).toBe(true);
    expect(affordances.canReviewEscalate).toBe(true);
  });

  it("grants access to content_admin", () => {
    const session = createSession("content_admin");
    const affordances = computeReviewAffordances(session);
    expect(affordances.canReviewPublish).toBe(true);
    expect(affordances.canReviewHide).toBe(true);
    expect(affordances.canReviewEscalate).toBe(true);
  });
});

describe("review item action affordances", () => {
  const item: ReviewModerationItem = {
    id: "review-1",
    venueId: "venue-1",
    venueName: "Venue One",
    authorName: "Guest",
    rating: 2,
    status: "flagged",
    snippet: "Needs moderation follow-up.",
    createdAt: "2026-04-10T12:00:00.000Z",
    moderationReason: "manual_review",
    moderationNote: null,
    moderatedAt: null,
    moderatedByUid: null,
  };

  it("exposes content-admin actions with target-state disabling", () => {
    const affordances = buildReviewItemActionAffordances(
      createSession("content_admin"),
      item,
      {
        review_hide: "pending",
      },
    );

    expect(affordances.find((entry) => entry.action === "review_publish")?.visible).toBe(true);
    expect(affordances.find((entry) => entry.action === "review_hide")?.enabled).toBe(false);
    expect(affordances.find((entry) => entry.action === "review_escalate")?.label).toBe(
      "إرسال للمراجعة",
    );
    expect(affordances.find((entry) => entry.action === "review_escalate")?.message).toMatch(
      /هذه المراجعة مرسلة للمراجعة بالفعل/i,
    );
  });

  it("hides mutation actions for non-content roles", () => {
    const affordances = buildReviewItemActionAffordances(
      createSession("ops_viewer"),
      item,
    );

    expect(affordances.every((entry) => entry.visible === false)).toBe(true);
  });

  it("maps runtime states to badge classes", () => {
    expect(getReviewActionStateClass("idle")).toBe("status-neutral");
    expect(getReviewActionStateClass("success")).toBe("status-success");
    expect(getReviewActionStateClass("conflict")).toBe("status-danger");
    expect(getReviewActionStateClass("unavailable")).toBe("status-warning");
  });
});
