import { describe, expect, it, vi } from "vitest";

import { createContentModerationAdaptersTransport } from "./content-command-adapters";
import type { ModerateOfferCommand, ModerateStoryCommand } from "./content-command-contracts";

function createOfferCommand(): ModerateOfferCommand {
  return {
    action: "reject",
    commandId: "cmd-offer-1",
    correlationId: "corr-offer-1",
    offerId: "offer-1",
    venueId: "venue-1",
    reason: "policy_violation",
    note: "Misleading claim",
    submittedAt: "2026-04-10T12:00:00.000Z",
    expectedState: {
      admin_state: "pending",
    },
  };
}

function createStoryCommand(): ModerateStoryCommand {
  return {
    action: "approve",
    commandId: "cmd-story-1",
    correlationId: "corr-story-1",
    storyId: "story-1",
    venueId: "venue-1",
    reason: "quality_standard",
    submittedAt: "2026-04-10T12:00:00.000Z",
    expectedState: {
      admin_state: "flagged",
    },
  };
}

describe("content moderation adapters", () => {
  it("maps offer callable response into normalized transport data", async () => {
    const invokeCallable = vi.fn(
      async (_name: string, _payload: Record<string, unknown>) => ({
        newAdminState: "rejected",
        isActive: false,
        auditEventId: "audit-offer-1",
      }),
    );

    const transport = createContentModerationAdaptersTransport({
      invokeCallable: invokeCallable as any,
    });
    const result = await transport.executeOffer("reject", createOfferCommand());

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.newAdminState).toBe("rejected");
      expect(result.data.auditEventId).toBe("audit-offer-1");
      expect(result.data.isActive).toBe(false);
    }
    expect(invokeCallable).toHaveBeenCalledWith(
      "contentModerateOffer",
      expect.objectContaining({
        action: "reject",
        offerId: "offer-1",
        venueId: "venue-1",
        reason: "policy_violation",
        idempotencyKey: "cmd-offer-1",
      }),
    );
  });

  it("maps story callable response into normalized transport data", async () => {
    const invokeCallable = vi.fn(
      async (_name: string, _payload: Record<string, unknown>) => ({
        newAdminState: "approved",
        isActive: true,
        auditEventId: "audit-story-1",
      }),
    );

    const transport = createContentModerationAdaptersTransport({
      invokeCallable: invokeCallable as any,
    });
    const result = await transport.executeStory("approve", createStoryCommand());

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.newAdminState).toBe("approved");
      expect(result.data.auditEventId).toBe("audit-story-1");
    }
    expect(invokeCallable).toHaveBeenCalledWith(
      "contentModerateStory",
      expect.objectContaining({
        action: "approve",
        storyId: "story-1",
        venueId: "venue-1",
        reason: "quality_standard",
        idempotencyKey: "cmd-story-1",
      }),
    );
  });

  it("normalizes backend callable failures into transport failures", async () => {
    const invokeCallable = vi.fn(async () => {
      throw {
        code: "failed-precondition",
        message: "content_expected_state_conflict",
      };
    });

    const transport = createContentModerationAdaptersTransport({
      invokeCallable: invokeCallable as any,
    });
    const result = await transport.executeOffer("reject", createOfferCommand());

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBeDefined();
    }
  });
});
