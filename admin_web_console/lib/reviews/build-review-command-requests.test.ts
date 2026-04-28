import { describe, expect, it } from "vitest";

import { buildReviewModerationCommandRequest } from "./build-review-command-requests";
import type { ReviewModerationItem } from "./review-moderation-models";

const ITEM: ReviewModerationItem = {
  id: "review-1",
  venueId: "venue-1",
  venueName: "Venue One",
  authorName: "Guest",
  rating: 1,
  status: "flagged",
  snippet: "Low quality review",
  createdAt: "2026-04-10T12:00:00.000Z",
  moderationReason: "manual_review",
  moderationNote: null,
  moderatedAt: null,
  moderatedByUid: null,
};

describe("buildReviewModerationCommandRequest", () => {
  it("builds explicit envelopes with expected state", () => {
    const request = buildReviewModerationCommandRequest({
      action: "review_hide",
      item: ITEM,
      reason: "spam",
      note: "Clear spam pattern.",
    });

    expect(request.action).toBe("review_hide");
    expect(request.target).toEqual({
      venueId: "venue-1",
      reviewId: "review-1",
    });
    expect(request.expectedState).toEqual({
      moderation_state: "flagged",
    });
    expect(request.reason).toBe("spam");
    expect(request.note).toBe("Clear spam pattern.");
    expect(request.commandId.length).toBeGreaterThan(0);
    expect(request.correlationId.length).toBeGreaterThan(0);
  });

  it("generates unique ids for repeated actions on the same review", () => {
    const first = buildReviewModerationCommandRequest({
      action: "review_publish",
      item: ITEM,
      reason: "appeal_approved",
    });
    const second = buildReviewModerationCommandRequest({
      action: "review_publish",
      item: ITEM,
      reason: "appeal_approved",
    });

    expect(first.commandId).not.toBe(second.commandId);
    expect(first.correlationId).not.toBe(second.correlationId);
  });
});
