import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  authorizeFinanceCommand,
  canExecuteFinanceCommand,
  isRoleAllowedForCommand,
} from "./command-policy";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "admin-uid",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

describe("finance command authorization policy", () => {
  it("enforces default deny for missing session", () => {
    const result = authorizeFinanceCommand(null, "approve_topup");

    expect(result.allowed).toBe(false);
    if (!result.allowed) {
      expect(result.reason).toBe("unauthorized");
      expect(result.error.code).toBe("unauthorized");
    }

    expect(canExecuteFinanceCommand(null, "approve_topup")).toBe(false);
  });

  it("supports capability-based command gating", () => {
    const financeSession = createSession("finance_admin");
    const opsSession = createSession("ops_viewer");

    expect(canExecuteFinanceCommand(financeSession, "approve_topup")).toBe(true);
    expect(canExecuteFinanceCommand(opsSession, "approve_topup")).toBe(false);
  });

  it("keeps role-command compatibility explicit", () => {
    expect(isRoleAllowedForCommand("finance_admin", "reverse_wallet_entry")).toBe(true);
    expect(isRoleAllowedForCommand("super_admin", "approve_reversal")).toBe(true);
    expect(isRoleAllowedForCommand("ops_viewer", "approve_reversal")).toBe(false);
    expect(isRoleAllowedForCommand("support_admin", "reject_topup")).toBe(false);

    expect(isRoleAllowedForCommand("ops_viewer", "verify_wallet_readiness")).toBe(true);
    expect(isRoleAllowedForCommand("content_admin", "verify_wallet_readiness")).toBe(true);
  });

  it("returns forbidden when capability is missing", () => {
    const supportSession = createSession("support_admin");
    const result = authorizeFinanceCommand(supportSession, "reverse_wallet_entry");

    expect(result.allowed).toBe(false);
    if (!result.allowed) {
      expect(result.reason).toBe("forbidden");
      expect(result.error.code).toBe("forbidden");
    }
  });
});
