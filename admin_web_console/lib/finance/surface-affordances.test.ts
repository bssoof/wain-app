import { describe, expect, it } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import { MOCK_WALLET_LEDGER_ENTRIES } from "./read-models";
import {
  buildFinanceCommandAffordance,
  buildReadinessCommandAffordance,
  buildTopUpActionAffordances,
  buildWalletEntryReversalAffordance,
  mapErrorCodeToRuntimeState,
} from "./surface-affordances";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "admin-uid",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

describe("finance surface affordances", () => {
  it("shows finance mutation affordances for authorized finance roles", () => {
    const financeSession = createSession("finance_admin");

    const topupActions = buildTopUpActionAffordances(financeSession);

    expect(topupActions.approve.visible).toBe(true);
    expect(topupActions.approve.enabled).toBe(true);
    expect(topupActions.reject.visible).toBe(true);
    expect(topupActions.reject.enabled).toBe(true);

    const debitEntry = MOCK_WALLET_LEDGER_ENTRIES.find((entry) => entry.type === "debit");
    expect(debitEntry).toBeDefined();

    const reversal = buildWalletEntryReversalAffordance(financeSession, debitEntry!);
    expect(reversal).not.toBeNull();
    expect(reversal?.visible).toBe(true);
    expect(reversal?.enabled).toBe(true);
  });

  it("hides finance mutation affordances for non-finance roles", () => {
    const opsSession = createSession("ops_viewer");

    const topupActions = buildTopUpActionAffordances(opsSession);
    expect(topupActions.approve.visible).toBe(false);
    expect(topupActions.reject.visible).toBe(false);

    const debitEntry = MOCK_WALLET_LEDGER_ENTRIES.find((entry) => entry.type === "debit");
    expect(debitEntry).toBeDefined();

    const reversal = buildWalletEntryReversalAffordance(opsSession, debitEntry!);
    expect(reversal).not.toBeNull();
    expect(reversal?.visible).toBe(false);
    expect(reversal?.enabled).toBe(false);

    const readiness = buildReadinessCommandAffordance(opsSession);
    expect(readiness.visible).toBe(true);
    expect(readiness.enabled).toBe(true);
  });

  it("renders pending, unavailable, and conflict command states consistently", () => {
    const financeSession = createSession("finance_admin");

    const pending = buildFinanceCommandAffordance(financeSession, "approve_topup", "pending");
    const unavailable = buildFinanceCommandAffordance(
      financeSession,
      "approve_topup",
      "unavailable",
    );
    const conflict = buildFinanceCommandAffordance(financeSession, "approve_topup", "conflict");

    expect(pending.visible).toBe(true);
    expect(pending.enabled).toBe(false);
    expect(pending.statusText).toBe("قيد التنفيذ...");

    expect(unavailable.visible).toBe(true);
    expect(unavailable.enabled).toBe(false);
    expect(unavailable.statusText).toBe("الإجراء غير متاح حاليًا. أعد المحاولة لاحقًا.");

    expect(conflict.visible).toBe(true);
    expect(conflict.enabled).toBe(false);
    expect(conflict.statusText).toBe("تم اكتشاف تعارض. حدّث البيانات قبل إعادة المحاولة.");
  });

  it("maps command errors to runtime states for UI consistency", () => {
    expect(mapErrorCodeToRuntimeState("conflict")).toBe("conflict");
    expect(mapErrorCodeToRuntimeState("unavailable")).toBe("unavailable");
    expect(mapErrorCodeToRuntimeState("validation_error")).toBe("unavailable");
    expect(mapErrorCodeToRuntimeState("forbidden")).toBe("unavailable");
  });

  it("keeps readiness command executable for ops_viewer while blocking finance mutations", () => {
    const opsSession = createSession("ops_viewer");

    const topupActions = buildTopUpActionAffordances(opsSession);
    expect(topupActions.approve.visible).toBe(false);

    const readiness = buildReadinessCommandAffordance(opsSession);
    expect(readiness.visible).toBe(true);
    expect(readiness.enabled).toBe(true);
  });
});
