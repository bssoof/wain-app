import { describe, expect, it } from "vitest";

import {
  buildOfferModerationCommandRequest,
  buildStoryModerationCommandRequest,
} from "./build-content-command-requests";
import type { OfferAdminItem, StoryAdminItem } from "./content-models";

const OFFER_ITEM: OfferAdminItem = {
  id: "offer-1",
  venueId: "venue-1",
  venueName: "Venue One",
  title: "Test Offer",
  adminState: "pending",
  isActive: true,
  isFeatured: false,
  createdAt: "2026-04-10T12:00:00.000Z",
  updatedAt: "2026-04-10T12:00:00.000Z",
};

const STORY_ITEM: StoryAdminItem = {
  id: "story-1",
  venueId: "venue-1",
  venueName: "Venue One",
  caption: "Test Story Caption",
  adminState: "flagged",
  isActive: true,
  isPromoted: false,
  createdAt: "2026-04-10T12:00:00.000Z",
  updatedAt: "2026-04-10T12:00:00.000Z",
};

describe("buildOfferModerationCommandRequest", () => {
  it("builds explicit envelopes with expected state", () => {
    const request = buildOfferModerationCommandRequest({
      action: "reject",
      item: OFFER_ITEM,
      reason: "policy_violation",
      note: "Misleading discount claim.",
    });

    expect(request.action).toBe("reject");
    expect(request.offerId).toBe("offer-1");
    expect(request.venueId).toBe("venue-1");
    expect(request.expectedState).toEqual({
      admin_state: "pending",
    });
    expect(request.reason).toBe("policy_violation");
    expect(request.note).toBe("Misleading discount claim.");
    expect(request.commandId.length).toBeGreaterThan(0);
    expect(request.correlationId.length).toBeGreaterThan(0);
  });

  it("generates unique ids for repeated actions on the same offer", () => {
    const first = buildOfferModerationCommandRequest({
      action: "approve",
      item: OFFER_ITEM,
      reason: "quality_standard",
    });
    const second = buildOfferModerationCommandRequest({
      action: "approve",
      item: OFFER_ITEM,
      reason: "quality_standard",
    });

    expect(first.commandId).not.toBe(second.commandId);
    expect(first.correlationId).not.toBe(second.correlationId);
  });

  it("does not include protected derived fields in the command", () => {
    const request = buildOfferModerationCommandRequest({
      action: "approve",
      item: OFFER_ITEM,
      reason: "quality_standard",
    });

    const keys = Object.keys(request);
    expect(keys).not.toContain("isFeatured");
    expect(keys).not.toContain("featuredUntil");
    expect(keys).not.toContain("is_featured");
    expect(keys).not.toContain("featured_until");
  });
});

describe("buildStoryModerationCommandRequest", () => {
  it("builds explicit envelopes with expected state", () => {
    const request = buildStoryModerationCommandRequest({
      action: "approve",
      item: STORY_ITEM,
      reason: "merchant_request",
    });

    expect(request.action).toBe("approve");
    expect(request.storyId).toBe("story-1");
    expect(request.venueId).toBe("venue-1");
    expect(request.expectedState).toEqual({
      admin_state: "flagged",
    });
    expect(request.reason).toBe("merchant_request");
    expect(request.commandId.length).toBeGreaterThan(0);
  });

  it("generates unique ids for repeated actions on the same story", () => {
    const first = buildStoryModerationCommandRequest({
      action: "flag",
      item: STORY_ITEM,
      reason: "inappropriate_content",
    });
    const second = buildStoryModerationCommandRequest({
      action: "flag",
      item: STORY_ITEM,
      reason: "inappropriate_content",
    });

    expect(first.commandId).not.toBe(second.commandId);
    expect(first.correlationId).not.toBe(second.correlationId);
  });

  it("does not include protected derived fields in the command", () => {
    const request = buildStoryModerationCommandRequest({
      action: "approve",
      item: STORY_ITEM,
      reason: "quality_standard",
    });

    const keys = Object.keys(request);
    expect(keys).not.toContain("isPromoted");
    expect(keys).not.toContain("promotedUntil");
    expect(keys).not.toContain("is_promoted");
    expect(keys).not.toContain("promoted_until");
  });
});
