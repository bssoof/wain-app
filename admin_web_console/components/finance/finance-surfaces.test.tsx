import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import { createFinanceCommandAdaptersTransport } from "@/lib/finance/finance-command-adapters";
import type { FinanceCommandTransport } from "@/lib/finance/finance-command-transport";
import type {
  LedgerReadData,
  ReadinessReadData,
  TopUpReadData,
} from "@/lib/finance/finance-read-loader";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";
import type { TopUpRequest, WalletLedgerEntry } from "@/lib/finance/read-models";
import { MOCK_READINESS_REPORT } from "@/lib/finance/read-models";
import {
  createTypeSafeMockInvoker,
  readCallableMockCall,
} from "@/lib/testing/type-safe-mock-invoker";

import { FinanceCommandProvider } from "./finance-command-provider";
import {
  ReadinessCommandPanel,
  ReadinessReportCard,
} from "./readiness-panel";
import { ReversalApprovalPanel } from "./reversal-approval-panel";
import { TopUpQueueTable } from "./topup-queue-table";
import { WalletAuditTable } from "./wallet-audit-table";

const routerRefreshMock = vi.hoisted(() => vi.fn());

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    refresh: routerRefreshMock,
  }),
}));

beforeEach(() => {
  routerRefreshMock.mockClear();
});

function financeSession(): AdminSession {
  return {
    uid: "admin-1",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function opsViewerSession(): AdminSession {
  return {
    uid: "admin-2",
    primaryRole: "ops_viewer",
    roles: ["ops_viewer"],
    roleSource: "claims",
  };
}

const samplePending: TopUpRequest = {
  id: "topup_test_1",
  venueId: "venue_test_1",
  userId: "user_1",
  userName: "Test User",
  amount: 100,
  currency: "ILS",
  providerReference: "PSP-TEST",
  createdAt: "2026-04-01T10:00:00.000Z",
  status: "pending",
};

const sampleDebitEntry: WalletLedgerEntry = {
  id: "entry_test_debit_1",
  venueId: "venue_test_1",
  userId: "user_2",
  userName: "Debit User",
  type: "debit",
  amount: 120,
  currency: "ILS",
  description: "Story promotion",
  reference: "story_21",
  createdAt: "2026-04-01T10:05:00.000Z",
};

const SAMPLE_AS_OF = "2026-04-01T10:00:00.000Z";
const SAMPLE_FETCHED_AT = "2026-04-01T10:00:05.000Z";
const SAMPLE_SOURCE = "test-source";

function topUpReadResult(
  pending: TopUpRequest[] = [samplePending],
): FinanceReadResult<TopUpReadData> {
  return {
    kind: "success",
    data: { pending },
    asOf: SAMPLE_AS_OF,
    fetchedAt: SAMPLE_FETCHED_AT,
    source: SAMPLE_SOURCE,
    stale: false,
  };
}

function ledgerReadResult(
  entries: WalletLedgerEntry[] = [sampleDebitEntry],
): FinanceReadResult<LedgerReadData> {
  return {
    kind: "success",
    data: { entries },
    asOf: SAMPLE_AS_OF,
    fetchedAt: SAMPLE_FETCHED_AT,
    source: SAMPLE_SOURCE,
    stale: false,
  };
}

function readinessReadResult(): FinanceReadResult<ReadinessReadData> {
  return {
    kind: "success",
    data: { report: MOCK_READINESS_REPORT },
    asOf: SAMPLE_AS_OF,
    fetchedAt: SAMPLE_FETCHED_AT,
    source: SAMPLE_SOURCE,
    stale: false,
  };
}

describe("finance command surfaces", () => {
  it("executes top-up approve through real adapters with idempotency + expected_state propagation", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      linked_entry_id: "entry_credited_001",
      reviewed_at: "2026-04-01T10:01:00.000Z",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByTestId("finance-topup-topup_test_1-approve"));

    // Dialog now intercepts — select reason and confirm
    fireEvent.change(screen.getByLabelText(/السبب/i), { target: { value: "payment_verified" } });
    fireEvent.click(screen.getByRole("button", { name: "تأكيد الإجراء" }));

    await waitFor(() => {
      expect(invokeCallable).toHaveBeenCalledTimes(1);
    });

    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reviewMerchantTopUpRequest");
    expect(payload.requestId).toBe(samplePending.id);
    expect(payload.venueId).toBe(samplePending.venueId);
    expect(payload.expectedState).toEqual({
      status: "pending",
      decision_state: "unreviewed",
    });
    expect(payload.idempotencyKey).toBe(payload.commandId);
  });

  it("requires a note when selecting 'other' reason", () => {
    const transport = createFinanceCommandAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => ({}) as any),
    });

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByTestId("finance-topup-topup_test_1-approve"));
    
    // Select "other"
    fireEvent.change(screen.getByLabelText(/السبب/i), { target: { value: "other" } });
    
    // Confirm should be disabled because note is empty
    const confirmBtn = screen.getByRole("button", { name: "تأكيد الإجراء" });
    expect((confirmBtn as HTMLButtonElement).disabled).toBe(true);
    
    // Add note
    fireEvent.change(screen.getByLabelText(/ملاحظة إدارية/i), { target: { value: "All good" } });
    expect((confirmBtn as HTMLButtonElement).disabled).toBe(false);
  });

  it("retains idempotency key (commandId) if submission fails and is retried", async () => {
    let capturedCommandId1 = "";
    let capturedCommandId2 = "";
    
    const executeMock = vi.fn()
      .mockImplementationOnce(async (command, payload) => {
        capturedCommandId1 = payload.commandId;
        return {
          ok: false,
          error: { status: 500, message: "Server Error" },
        };
      })
      .mockImplementationOnce(async (command, payload) => {
        capturedCommandId2 = payload.commandId;
        return {
          ok: true,
          data: { status: "credited" },
        };
      });

    const transport: FinanceCommandTransport = {
      execute: executeMock
    } as any;

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByTestId("finance-topup-topup_test_1-approve"));
    fireEvent.change(screen.getByLabelText(/السبب/i), { target: { value: "payment_verified" } });
    
    fireEvent.click(screen.getByRole("button", { name: "تأكيد الإجراء" }));

    await waitFor(() => {
      expect(executeMock).toHaveBeenCalledTimes(1);
    });

    // Wait for retry state, then click the dialog's retry button (first match)
        await waitFor(() => {
          expect(screen.getAllByRole("button", { name: /إعادة المحاولة/i }).length).toBeGreaterThan(0);
        });
        const retryBtns = screen.getAllByRole("button", { name: /إعادة المحاولة/i });
        // Try to find the button inside the review dialog, or fallback to the first
        const dialogRetryBtn = retryBtns.find((btn) => btn.className.includes("review-dialog__btn")) ?? retryBtns[0];
        fireEvent.click(dialogRetryBtn);
    
    await waitFor(() => {
      expect(executeMock).toHaveBeenCalledTimes(2);
    });
    
    // Command ID must be strictly retained
    expect(capturedCommandId1).toBeTruthy();
    expect(capturedCommandId1).toBe(capturedCommandId2);
  });

  it("shows pending status while a command is in flight", async () => {
    let release: (() => void) | undefined;
    const barrier = new Promise<void>((resolve) => {
      release = resolve;
    });

    const transport: FinanceCommandTransport = {
      async execute() {
        await barrier;
        return {
          ok: false,
          error: { status: 503, message: "stopped" },
        };
      },
    };

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByTestId("finance-topup-topup_test_1-approve"));
    fireEvent.change(screen.getByLabelText(/السبب/i), { target: { value: "payment_verified" } });
    fireEvent.click(screen.getByRole("button", { name: "تأكيد الإجراء" }));

    await waitFor(() => {
      expect(screen.getByText(/اعتماد: قيد التنفيذ/i)).toBeTruthy();
    });

    release?.();
  });

  it("allows finance roles to trigger reversal command through the real adapter", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      reversalEntryId: "reversal_entry_001",
      venueId: sampleDebitEntry.venueId,
      reversedAt: "2026-04-01T10:06:00.000Z",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <WalletAuditTable readResult={ledgerReadResult()} />
      </FinanceCommandProvider>,
    );

    expect(screen.queryByText(/Debit User/i)).toBeNull();
    expect(screen.queryByText(/Story promotion/i)).toBeNull();
    expect(screen.getByText(/صاحب حساب/i)).toBeTruthy();
    expect(screen.getByText(/ترويج قصة/i)).toBeTruthy();

    fireEvent.click(screen.getByRole("button", { name: /طلب تصحيح/i }));

    await waitFor(() => {
      expect(invokeCallable).toHaveBeenCalledTimes(1);
    });

    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reverseWalletEntry");
    expect(payload.entryId).toBe(sampleDebitEntry.id);
    expect(payload.venueId).toBe(sampleDebitEntry.venueId);
    expect(payload.expectedState).toEqual({
      entry_status: "posted",
      reversal_state: "not_reversed",
      entry_type: "debit",
    });
    expect(payload.idempotencyKey).toBe(payload.commandId);
  });

  it("shows pending second approval runtime outcome for reversal requests above threshold", async () => {
    const transport: FinanceCommandTransport = {
      async execute(command) {
        if (command !== "reverse_wallet_entry") {
          throw new Error(`Unexpected command: ${command}`);
        }

        return {
          ok: true,
          data: {
            action: "reverse_wallet_entry",
            originalEntryId: sampleDebitEntry.id,
            venueId: sampleDebitEntry.venueId ?? "venue_test_1",
            status: "pending_second_approval",
            reversalRequestId: "reversal-request-9001",
            requiredSecondApproverRole: "finance_admin",
            approvalExpiresAt: "2026-04-11T00:00:00.000Z",
          },
        } as any;
      },
    };

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <WalletAuditTable readResult={ledgerReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByRole("button", { name: /طلب تصحيح/i }));

    await waitFor(() => {
      expect(
        screen.getByTestId(`finance-reversal-outcome-${sampleDebitEntry.id}`).textContent,
      ).toMatch(/ينتظر موافقة ثانية/i);
    });
  });

  it("surfaces conflict and unavailable messaging without silent failure", async () => {
    const conflictTransport = createFinanceCommandAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw {
          code: "failed-precondition",
          message: "expected_state mismatch",
        };
      }),
    });

    const { unmount } = render(
      <FinanceCommandProvider session={financeSession()} transport={conflictTransport}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByTestId("finance-topup-topup_test_1-approve"));
    fireEvent.change(screen.getByLabelText(/السبب/i), { target: { value: "payment_verified" } });
    fireEvent.click(screen.getByRole("button", { name: "تأكيد الإجراء" }));

    await waitFor(() => {
      const alert = screen.getByTestId("finance-command-runtime-callout");
      expect(alert.getAttribute("data-runtime-state")).toBe("conflict");
      expect(screen.getByText(/تعذر إكمال الطلب حاليًا/)).toBeTruthy();
    });

    unmount();

    const unavailableTransport = createFinanceCommandAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw {
          code: "unavailable",
          message: "upstream unavailable",
        };
      }),
    });

    render(
      <FinanceCommandProvider session={financeSession()} transport={unavailableTransport}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByTestId("finance-topup-topup_test_1-approve"));
    fireEvent.change(screen.getByLabelText(/السبب/i), { target: { value: "payment_verified" } });
    fireEvent.click(screen.getByRole("button", { name: "تأكيد الإجراء" }));

    await waitFor(() => {
      const alert = screen.getByTestId("finance-command-runtime-callout");
      expect(alert.getAttribute("data-runtime-state")).toBe("unavailable");
      expect(screen.getByText(/الخدمة غير متاحة حاليًا/)).toBeTruthy();
    });
  });

  it("shows approved and executed runtime outcome for approve_reversal", async () => {
    const transport: FinanceCommandTransport = {
      async execute(command) {
        if (command !== "approve_reversal") {
          throw new Error(`Unexpected command: ${command}`);
        }

        return {
          ok: true,
          data: {
            action: "approve_reversal",
            reversalRequestId: "reversal-request-001",
            status: "approved_and_executed",
            executedReversalEntryId: "reversal_entry_001",
            approvedAt: "2026-04-10T00:15:00.000Z",
          },
        } as any;
      },
    };

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <ReversalApprovalPanel />
      </FinanceCommandProvider>,
    );

    fireEvent.change(screen.getByLabelText(/رقم طلب التصحيح/i), {
      target: { value: "reversal-request-001" },
    });
    fireEvent.click(screen.getByRole("button", { name: /اعتماد التصحيح/i }));
    fireEvent.click(screen.getByRole("button", { name: /تأكيد الموافقة/i }));

    await waitFor(() => {
      expect(screen.getByTestId("finance-reversal-approved-status").textContent).toMatch(
        /تم الاعتماد والتنفيذ/i,
      );
    });
  });

  it("surfaces conflict and unavailable runtime states for approve_reversal", async () => {
    const conflictTransport: FinanceCommandTransport = {
      async execute(command) {
        if (command !== "approve_reversal") {
          throw new Error(`Unexpected command: ${command}`);
        }

        return {
          ok: false,
          error: {
            status: 409,
            message: "reversal_request_expired",
          },
        } as any;
      },
    };

    const { unmount } = render(
      <FinanceCommandProvider session={financeSession()} transport={conflictTransport}>
        <ReversalApprovalPanel />
      </FinanceCommandProvider>,
    );

    fireEvent.change(screen.getByLabelText(/رقم طلب التصحيح/i), {
      target: { value: "reversal-request-002" },
    });
    fireEvent.click(screen.getByRole("button", { name: /اعتماد التصحيح/i }));
    fireEvent.click(screen.getByRole("button", { name: /تأكيد الموافقة/i }));

    await waitFor(() => {
      const alert = screen.getByTestId("finance-command-runtime-callout");
      expect(alert.getAttribute("data-runtime-state")).toBe("conflict");
      expect(screen.getByText(/تعذر إكمال الطلب حاليًا/i)).toBeTruthy();
    });

    unmount();

    const unavailableTransport: FinanceCommandTransport = {
      async execute(command) {
        if (command !== "approve_reversal") {
          throw new Error(`Unexpected command: ${command}`);
        }

        return {
          ok: false,
          error: {
            status: 503,
            message: "approval backend unavailable",
          },
        } as any;
      },
    };

    render(
      <FinanceCommandProvider session={financeSession()} transport={unavailableTransport}>
        <ReversalApprovalPanel />
      </FinanceCommandProvider>,
    );

    fireEvent.change(screen.getByLabelText(/رقم طلب التصحيح/i), {
      target: { value: "reversal-request-003" },
    });
    fireEvent.click(screen.getByRole("button", { name: /اعتماد التصحيح/i }));
    fireEvent.click(screen.getByRole("button", { name: /تأكيد الموافقة/i }));

    await waitFor(() => {
      const alert = screen.getByTestId("finance-command-runtime-callout");
      expect(alert.getAttribute("data-runtime-state")).toBe("unavailable");
      expect(screen.getByText(/الخدمة غير متاحة حاليًا/i)).toBeTruthy();
    });
  });

  it("refreshes the page instead of re-running approve_reversal from the runtime callout", async () => {
    const execute = vi
      .fn<FinanceCommandTransport["execute"]>()
      .mockImplementationOnce(async (command) => {
        if (command !== "approve_reversal") {
          throw new Error(`Unexpected command: ${command}`);
        }

        return {
          ok: false,
          error: {
            status: 409,
            message: "reversal_request_expired",
          },
        } as any;
      })
      .mockImplementationOnce(async (command) => {
        if (command !== "approve_reversal") {
          throw new Error(`Unexpected command: ${command}`);
        }

        return {
          ok: true,
          data: {
            action: "approve_reversal",
            reversalRequestId: "reversal-request-refresh",
            status: "approved_and_executed",
            executedReversalEntryId: "reversal_entry_refresh",
            approvedAt: "2026-04-10T00:15:00.000Z",
          },
        } as any;
      });
    const transport: FinanceCommandTransport = { execute: execute as FinanceCommandTransport["execute"] };

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <ReversalApprovalPanel />
      </FinanceCommandProvider>,
    );

    fireEvent.change(screen.getByLabelText(/رقم طلب التصحيح/i), {
      target: { value: "reversal-request-refresh" },
    });
    fireEvent.click(screen.getByRole("button", { name: /اعتماد التصحيح/i }));
    fireEvent.click(screen.getByRole("button", { name: /تأكيد الموافقة/i }));

    await waitFor(() => {
      const alert = screen.getByTestId("finance-command-runtime-callout");
      expect(alert.getAttribute("data-runtime-state")).toBe("conflict");
    });
    expect(execute).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByRole("button", { name: "تحديث" }));

    expect(routerRefreshMock).toHaveBeenCalledTimes(1);
    expect(execute).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByRole("button", { name: "إعادة المحاولة" }));

    await waitFor(() => {
      expect(execute).toHaveBeenCalledTimes(2);
    });
  });

  it("hides finance mutation controls for non-finance roles", () => {
    render(
      <FinanceCommandProvider session={opsViewerSession()}>
        <TopUpQueueTable readResult={topUpReadResult()} />
      </FinanceCommandProvider>,
    );

    expect(screen.queryByTestId("finance-topup-topup_test_1-approve")).toBeNull();
    expect(screen.queryByTestId("finance-topup-topup_test_1-reject")).toBeNull();
    expect(screen.getByText(/هذا الدور يستطيع القراءة فقط/i)).toBeTruthy();
  });

  it("keeps readiness command executable for ops_viewer per contract", () => {
    render(
      <FinanceCommandProvider session={opsViewerSession()}>
        <ReadinessReportCard readResult={readinessReadResult()} />
        <ReadinessCommandPanel />
      </FinanceCommandProvider>,
    );

    expect(screen.getByRole("button", { name: /تحديث حالة النظام/i })).toBeTruthy();
  });
});
