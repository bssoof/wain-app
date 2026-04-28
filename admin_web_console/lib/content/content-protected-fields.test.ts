import { describe, expect, it } from "vitest";

import {
  buildOfferModerationCommandRequest,
  buildStoryModerationCommandRequest,
} from "./build-content-command-requests";
import {
  ALL_PROTECTED_DERIVED_FIELDS,
  OFFER_PROTECTED_DERIVED_FIELDS,
  STORY_PROTECTED_DERIVED_FIELDS,
} from "./content-models";
import type {
  ModerateOfferCommand,
  ModerateStoryCommand,
} from "./content-command-contracts";
import type { OfferAdminItem, StoryAdminItem } from "./content-models";

const OFFER_ITEM: OfferAdminItem = {
  id: "offer-1",
  venueId: "venue-1",
  venueName: "Venue One",
  title: "Test Offer",
  description: "A great deal",
  adminState: "pending",
  isActive: true,
  isFeatured: true,
  featuredUntil: "2026-04-20T00:00:00.000Z",
  createdAt: "2026-04-10T12:00:00.000Z",
  updatedAt: "2026-04-10T12:00:00.000Z",
};

const STORY_ITEM: StoryAdminItem = {
  id: "story-1",
  venueId: "venue-1",
  venueName: "Venue One",
  caption: "Test Story",
  adminState: "approved",
  isActive: true,
  isPromoted: true,
  promotedUntil: "2026-04-20T00:00:00.000Z",
  createdAt: "2026-04-10T12:00:00.000Z",
  updatedAt: "2026-04-10T12:00:00.000Z",
};

describe("protected derived field safety — offers", () => {
  it("offer command payload never contains protected derived fields", () => {
    const command: ModerateOfferCommand = buildOfferModerationCommandRequest({
      action: "approve",
      item: OFFER_ITEM,
      reason: "quality_standard",
      note: "Approved after review",
    });

    const commandKeys = Object.keys(command);
    for (const protectedField of OFFER_PROTECTED_DERIVED_FIELDS) {
      expect(commandKeys).not.toContain(protectedField);
    }
  });

  it("offer command does not leak source item promotion state", () => {
    const command = buildOfferModerationCommandRequest({
      action: "reject",
      item: OFFER_ITEM,
      reason: "policy_violation",
    });

    const serialized = JSON.stringify(command);
    // isFeatured and featuredUntil should not appear in the serialized command
    expect(serialized).not.toContain('"isFeatured"');
    expect(serialized).not.toContain('"featuredUntil"');
    expect(serialized).not.toContain('"is_featured"');
    expect(serialized).not.toContain('"featured_until"');
  });

  it("ModerateOfferCommand type shape does not include promotion fields", () => {
    // Structural test: the command shape should only contain these keys
    const command = buildOfferModerationCommandRequest({
      action: "flag",
      item: OFFER_ITEM,
      reason: "inappropriate_content",
    });

    const allowedKeys = new Set([
      "commandId",
      "action",
      "offerId",
      "venueId",
      "reason",
      "note",
      "correlationId",
      "submittedAt",
      "expectedState",
    ]);

    for (const key of Object.keys(command)) {
      expect(allowedKeys.has(key)).toBe(true);
    }
  });
});

describe("protected derived field safety — stories", () => {
  it("story command payload never contains protected derived fields", () => {
    const command: ModerateStoryCommand = buildStoryModerationCommandRequest({
      action: "approve",
      item: STORY_ITEM,
      reason: "quality_standard",
    });

    const commandKeys = Object.keys(command);
    for (const protectedField of STORY_PROTECTED_DERIVED_FIELDS) {
      expect(commandKeys).not.toContain(protectedField);
    }
  });

  it("story command does not leak source item promotion state", () => {
    const command = buildStoryModerationCommandRequest({
      action: "reject",
      item: STORY_ITEM,
      reason: "policy_violation",
    });

    const serialized = JSON.stringify(command);
    expect(serialized).not.toContain('"isPromoted"');
    expect(serialized).not.toContain('"promotedUntil"');
    expect(serialized).not.toContain('"is_promoted"');
    expect(serialized).not.toContain('"promoted_until"');
  });

  it("ModerateStoryCommand type shape does not include promotion fields", () => {
    const command = buildStoryModerationCommandRequest({
      action: "pause",
      item: STORY_ITEM,
      reason: "merchant_request",
    });

    const allowedKeys = new Set([
      "commandId",
      "action",
      "storyId",
      "venueId",
      "reason",
      "note",
      "correlationId",
      "submittedAt",
      "expectedState",
    ]);

    for (const key of Object.keys(command)) {
      expect(allowedKeys.has(key)).toBe(true);
    }
  });
});

describe("protected field constants are complete", () => {
  it("ALL_PROTECTED_DERIVED_FIELDS includes both offer and story fields", () => {
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("isFeatured");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("featuredUntil");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("isPromoted");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("promotedUntil");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("is_featured");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("featured_until");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("is_promoted");
    expect(ALL_PROTECTED_DERIVED_FIELDS).toContain("promoted_until");
    expect(ALL_PROTECTED_DERIVED_FIELDS.length).toBe(8);
  });
});
