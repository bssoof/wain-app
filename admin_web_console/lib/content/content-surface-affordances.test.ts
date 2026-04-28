import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  buildOfferItemActionAffordances,
  buildStoryItemActionAffordances,
  computeContentAffordances,
  getContentActionStateClass,
} from "./content-surface-affordances";
import type { OfferAdminItem, StoryAdminItem } from "./content-models";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "test-user",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

const OFFER_ITEM: OfferAdminItem = {
  id: "offer-1",
  venueId: "venue-1",
  venueName: "Test Venue",
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
  venueName: "Test Venue",
  caption: "Test Story",
  adminState: "approved",
  isActive: true,
  isPromoted: true,
  promotedUntil: "2026-04-15T12:00:00.000Z",
  createdAt: "2026-04-10T12:00:00.000Z",
  updatedAt: "2026-04-10T12:00:00.000Z",
};

describe("computeContentAffordances RBAC", () => {
  it("denies access to non-session", () => {
    const affordances = computeContentAffordances(null);
    expect(affordances.canModerateOffers).toBe(false);
    expect(affordances.canModerateStories).toBe(false);
  });

  it("denies access to finance_admin", () => {
    const session = createSession("finance_admin");
    const affordances = computeContentAffordances(session);
    expect(affordances.canModerateOffers).toBe(false);
    expect(affordances.canModerateStories).toBe(false);
  });

  it("grants access to super_admin", () => {
    const session = createSession("super_admin");
    const affordances = computeContentAffordances(session);
    expect(affordances.canModerateOffers).toBe(true);
    expect(affordances.canModerateStories).toBe(true);
  });

  it("grants access to content_admin", () => {
    const session = createSession("content_admin");
    const affordances = computeContentAffordances(session);
    expect(affordances.canModerateOffers).toBe(true);
    expect(affordances.canModerateStories).toBe(true);
  });
});

describe("offer item action affordances", () => {
  it("exposes content-admin actions with target-state disabling", () => {
    const affordances = buildOfferItemActionAffordances(
      createSession("content_admin"),
      OFFER_ITEM,
      { reject: "pending" },
    );

    expect(affordances.find((e) => e.action === "approve")?.visible).toBe(true);
    expect(affordances.find((e) => e.action === "reject")?.enabled).toBe(false);
    expect(affordances.find((e) => e.action === "flag")?.visible).toBe(true);
    expect(affordances.find((e) => e.action === "pause")?.visible).toBe(true);
  });

  it("hides mutation actions for non-content roles", () => {
    const affordances = buildOfferItemActionAffordances(
      createSession("ops_viewer"),
      OFFER_ITEM,
    );
    expect(affordances.every((e) => e.visible === false)).toBe(true);
  });

  it("disables approve for already-approved items", () => {
    const approvedItem = { ...OFFER_ITEM, adminState: "approved" as const };
    const affordances = buildOfferItemActionAffordances(
      createSession("content_admin"),
      approvedItem,
    );
    const approveAffordance = affordances.find((e) => e.action === "approve");
    expect(approveAffordance?.enabled).toBe(false);
    expect(approveAffordance?.message).toMatch(/بالحالة معتمد بالفعل/i);
  });
});

describe("story item action affordances", () => {
  it("disables approve for already-approved stories", () => {
    const affordances = buildStoryItemActionAffordances(
      createSession("content_admin"),
      STORY_ITEM,
    );
    const approveAffordance = affordances.find((e) => e.action === "approve");
    expect(approveAffordance?.enabled).toBe(false);
    expect(approveAffordance?.message).toMatch(/بالحالة معتمد بالفعل/i);
  });

  it("hides actions for ops_viewer", () => {
    const affordances = buildStoryItemActionAffordances(
      createSession("ops_viewer"),
      STORY_ITEM,
    );
    expect(affordances.every((e) => e.visible === false)).toBe(true);
  });
});

describe("content runtime state mapping", () => {
  it("maps runtime states to badge classes", () => {
    expect(getContentActionStateClass("idle")).toBe("status-neutral");
    expect(getContentActionStateClass("success")).toBe("status-success");
    expect(getContentActionStateClass("conflict")).toBe("status-danger");
    expect(getContentActionStateClass("unavailable")).toBe("status-warning");
  });
});
