import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  authorizeOfferModerationCommand,
  authorizeStoryModerationCommand,
} from "./content-command-policy";
import type { ContentModerationAction } from "./content-command-contracts";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "test-user",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

const ALL_ACTIONS: ContentModerationAction[] = ["approve", "reject", "flag", "pause"];

describe("authorizeOfferModerationCommand", () => {
  it("denies access when session is null", () => {
    for (const action of ALL_ACTIONS) {
      const result = authorizeOfferModerationCommand(null, action);
      expect(result.allowed).toBe(false);
      if (!result.allowed) {
        expect(result.error.code).toBe("unauthorized");
      }
    }
  });

  it("denies access to finance_admin for all offer actions", () => {
    const session = createSession("finance_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeOfferModerationCommand(session, action);
      expect(result.allowed).toBe(false);
      if (!result.allowed) {
        expect(result.error.code).toBe("forbidden");
      }
    }
  });

  it("denies access to ops_viewer for all offer actions", () => {
    const session = createSession("ops_viewer");
    for (const action of ALL_ACTIONS) {
      const result = authorizeOfferModerationCommand(session, action);
      expect(result.allowed).toBe(false);
    }
  });

  it("denies access to support_admin for all offer actions", () => {
    const session = createSession("support_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeOfferModerationCommand(session, action);
      expect(result.allowed).toBe(false);
    }
  });

  it("grants access to super_admin for all offer actions", () => {
    const session = createSession("super_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeOfferModerationCommand(session, action);
      expect(result.allowed).toBe(true);
    }
  });

  it("grants access to content_admin for all offer actions", () => {
    const session = createSession("content_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeOfferModerationCommand(session, action);
      expect(result.allowed).toBe(true);
    }
  });
});

describe("authorizeStoryModerationCommand", () => {
  it("denies access when session is null", () => {
    for (const action of ALL_ACTIONS) {
      const result = authorizeStoryModerationCommand(null, action);
      expect(result.allowed).toBe(false);
      if (!result.allowed) {
        expect(result.error.code).toBe("unauthorized");
      }
    }
  });

  it("denies access to finance_admin for all story actions", () => {
    const session = createSession("finance_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeStoryModerationCommand(session, action);
      expect(result.allowed).toBe(false);
      if (!result.allowed) {
        expect(result.error.code).toBe("forbidden");
      }
    }
  });

  it("denies access to ops_viewer for all story actions", () => {
    const session = createSession("ops_viewer");
    for (const action of ALL_ACTIONS) {
      const result = authorizeStoryModerationCommand(session, action);
      expect(result.allowed).toBe(false);
    }
  });

  it("grants access to super_admin for all story actions", () => {
    const session = createSession("super_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeStoryModerationCommand(session, action);
      expect(result.allowed).toBe(true);
    }
  });

  it("grants access to content_admin for all story actions", () => {
    const session = createSession("content_admin");
    for (const action of ALL_ACTIONS) {
      const result = authorizeStoryModerationCommand(session, action);
      expect(result.allowed).toBe(true);
    }
  });
});
