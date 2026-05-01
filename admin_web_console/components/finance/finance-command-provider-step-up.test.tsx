import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { useState } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { StepUpEnsureResult } from "@/lib/auth/use-step-up";
import type { FinanceCommandTransport } from "@/lib/finance/finance-command-transport";
import type { ApproveTopUpCommandRequest } from "@/lib/finance/command-contracts";

import {
  FinanceCommandProvider,
  useFinanceCommands,
} from "./finance-command-provider";

const { ensureStepUpMock, modalState } = vi.hoisted(() => ({
  ensureStepUpMock: vi.fn(),
  modalState: {
    open: false,
    pending: false,
    onSubmit: vi.fn(),
    onClose: vi.fn(),
  },
}));

vi.mock("@/lib/auth/use-step-up", () => ({
  useStepUp: () => ({
    ensureStepUp: ensureStepUpMock,
    modal: modalState,
  }),
}));

vi.mock("@/components/auth/step-up-modal", () => ({
  StepUpModal: (props: { open: boolean }) => (
    <div data-testid="step-up-modal" data-open={String(props.open)} />
  ),
}));

describe("FinanceCommandProvider step-up integration", () => {
  beforeEach(() => {
    ensureStepUpMock.mockReset();
    modalState.open = false;
    modalState.pending = false;
    modalState.onSubmit = vi.fn();
    modalState.onClose = vi.fn();
  });

  it("does not execute finance command when step-up is cancelled", async () => {
    const transport: FinanceCommandTransport = {
      execute: vi.fn(),
    };
    ensureStepUpMock.mockResolvedValue({
      ok: false,
      code: "step_up_required",
      message: "STEP_UP_REQUIRED",
      reason: "cancelled",
    } satisfies StepUpEnsureResult);

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <ApproveTopUpProbe />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByRole("button", { name: "run approve" }));

    await waitFor(() => {
      expect(screen.getByTestId("command-result").textContent).toBe(
        "step_up_required",
      );
    });
    expect(ensureStepUpMock).toHaveBeenCalledWith("approve_topup");
    expect(transport.execute).not.toHaveBeenCalled();
  });

  it("reopens step-up and retries once when backend returns STEP_UP_REQUIRED", async () => {
    const execute = vi
      .fn<FinanceCommandTransport["execute"]>()
      .mockResolvedValueOnce({
        ok: false,
        error: {
          status: 403,
          code: "step_up_required",
          message: "STEP_UP_REQUIRED",
          details: { scope: "finance", command: "approve_topup" },
        },
      } as any)
      .mockResolvedValueOnce({
        ok: true,
        data: {
          action: "approve_topup",
          requestId: "topup_1",
          venueId: "venue_1",
          status: "credited",
          linkedEntryId: "entry_1",
          reviewedAt: "2026-04-30T10:00:00.000Z",
        },
      } as any);
    const transport: FinanceCommandTransport = { execute: execute as FinanceCommandTransport["execute"] };
    ensureStepUpMock
      .mockResolvedValueOnce({ ok: true } satisfies StepUpEnsureResult)
      .mockResolvedValueOnce({ ok: true } satisfies StepUpEnsureResult);

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <ApproveTopUpProbe />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByRole("button", { name: "run approve" }));

    await waitFor(() => {
      expect(screen.getByTestId("command-result").textContent).toBe("credited");
    });
    expect(ensureStepUpMock).toHaveBeenNthCalledWith(1, "approve_topup");
    expect(ensureStepUpMock).toHaveBeenNthCalledWith(2, "approve_topup", {
      force: true,
    });
    expect(execute).toHaveBeenCalledTimes(2);
    expect(execute.mock.calls[0]?.[1]).toBe(execute.mock.calls[1]?.[1]);
    expect(execute.mock.calls[0]?.[1].commandId).toBe("cmd_1");
    expect(execute.mock.calls[1]?.[1].commandId).toBe("cmd_1");
  });

  it("does not reopen step-up for network failures", async () => {
    const execute = vi.fn<FinanceCommandTransport["execute"]>(async () => {
      throw new Error("network timeout");
    });
    const transport: FinanceCommandTransport = { execute: execute as FinanceCommandTransport["execute"] };
    ensureStepUpMock.mockResolvedValue({ ok: true } satisfies StepUpEnsureResult);

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <ApproveTopUpProbe />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByRole("button", { name: "run approve" }));

    await waitFor(() => {
      expect(screen.getByTestId("command-result").textContent).toBe("unavailable");
    });
    expect(ensureStepUpMock).toHaveBeenCalledTimes(1);
    expect(ensureStepUpMock).toHaveBeenCalledWith("approve_topup");
    expect(execute).toHaveBeenCalledTimes(1);
  });

  it("does not reopen step-up for generic 403 failures", async () => {
    const execute = vi.fn<FinanceCommandTransport["execute"]>().mockResolvedValue({
      ok: false,
      error: {
        status: 403,
        message: "Forbidden",
      },
    } as any);
    const transport: FinanceCommandTransport = { execute: execute as FinanceCommandTransport["execute"] };
    ensureStepUpMock.mockResolvedValue({ ok: true } satisfies StepUpEnsureResult);

    render(
      <FinanceCommandProvider session={financeSession()} transport={transport}>
        <ApproveTopUpProbe />
      </FinanceCommandProvider>,
    );

    fireEvent.click(screen.getByRole("button", { name: "run approve" }));

    await waitFor(() => {
      expect(screen.getByTestId("command-result").textContent).toBe("forbidden");
    });
    expect(ensureStepUpMock).toHaveBeenCalledTimes(1);
    expect(ensureStepUpMock).toHaveBeenCalledWith("approve_topup");
    expect(execute).toHaveBeenCalledTimes(1);
  });
});

function ApproveTopUpProbe() {
  const { getLastErrorMessage, getRuntimeState, runCommand } = useFinanceCommands();
  const [resultLabel, setResultLabel] = useState("");

  return (
    <>
      <button
        type="button"
        onClick={() => {
          void runCommand("approve-topup-1", "approve_topup", approveTopUpRequest()).then(
            (result) => {
              setResultLabel(result.ok ? result.data.status : result.error.code);
            },
          );
        }}
      >
        run approve
      </button>
      <div data-testid="command-runtime">{getRuntimeState("approve-topup-1")}</div>
      <div data-testid="command-error">
        {getLastErrorMessage("approve-topup-1") ?? ""}
      </div>
      <div data-testid="command-result">{resultLabel}</div>
    </>
  );
}

function financeSession(): AdminSession {
  return {
    uid: "admin-1",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function approveTopUpRequest(): ApproveTopUpCommandRequest {
  return {
    action: "approve_topup",
    requestId: "topup_1",
    venueId: "venue_1",
    commandId: "cmd_1",
    correlationId: "corr_1",
    reason: "approval",
    submittedAt: "2026-04-30T10:00:00.000Z",
    expectedState: {
      status: "pending",
      decision_state: "unreviewed",
    },
  };
}
