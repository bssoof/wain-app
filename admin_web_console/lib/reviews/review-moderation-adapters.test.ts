import { describe, expect, it, vi } from "vitest";

import { createReviewModerationAdaptersTransport } from "./review-moderation-adapters";

function createRequest() {
  return {
    action: "review_hide" as const,
    commandId: "cmd-1",
    correlationId: "corr-1",
    reason: "spam" as const,
    note: "Spam link detected",
    submittedAt: "2026-04-10T12:00:00.000Z",
    target: {
      venueId: "venue-1",
      reviewId: "review-1",
    },
    expectedState: {
      moderation_state: "published" as const,
    },
  };
}

describe("review moderation adapters", () => {
  it("maps the moderation callable response into normalized transport data", async () => {
    const invokeCallable = vi.fn(
      async (_name: string, payload: Record<string, unknown>) => ({
        reviewId: payload.reviewId,
        venueId: payload.venueId,
        status: "hidden",
        moderationState: "hidden",
        auditEventId: "audit-1",
        moderatedAt: 1712750400000,
      }),
    );

    const transport = createReviewModerationAdaptersTransport({
      invokeCallable: invokeCallable as any,
    });
    const result = await transport.execute("review_hide", createRequest());

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("hidden");
      expect(result.data.auditEventId).toBe("audit-1");
    }
    expect(invokeCallable).toHaveBeenCalledWith(
      "moderateVenueReviewForAdmin",
      expect.objectContaining({
        action: "review_hide",
        venueId: "venue-1",
        reviewId: "review-1",
        reason: "spam",
        idempotencyKey: "cmd-1",
      }),
    );
  });

  it("normalizes backend callable failures into transport failures", async () => {
    const invokeCallable = vi.fn(async () => {
      throw {
        code: "failed-precondition",
        message: "review_expected_state_conflict",
      };
    });

    const transport = createReviewModerationAdaptersTransport({
      invokeCallable: invokeCallable as any,
    });
    const result = await transport.execute("review_hide", createRequest());

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toMatchObject({
        status: 409,
        message: "review_expected_state_conflict",
      });
    }
  });
});
