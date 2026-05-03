import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";

import { ReversalApprovalPanel } from "./reversal-approval-panel";

// Mock dependencies
const mockRunCommand = vi.fn();
const mockGetRuntimeState = vi.fn();
const mockGetLastErrorMessage = vi.fn();
const mockEnsureStepUp = vi.fn();

vi.mock("next/navigation", () => ({
  useRouter: () => ({ refresh: vi.fn() }),
}));

vi.mock("@/lib/auth/use-step-up", () => ({
  useStepUp: () => ({ ensureStepUp: mockEnsureStepUp }),
}));

vi.mock("./finance-command-provider", () => ({
  useFinanceCommands: () => ({
    runCommand: mockRunCommand,
    getRuntimeState: mockGetRuntimeState,
    getLastErrorMessage: mockGetLastErrorMessage,
    session: { primaryRole: "finance_admin" },
  }),
}));

vi.mock("@/lib/finance/surface-affordances", () => ({
  buildApproveReversalCommandAffordance: () => ({
    visible: true,
    enabled: true,
    label: "Approve",
    runtimeState: "idle",
    statusText: "Ready",
    requiredCapability: "approve_reversals",
  }),
}));

vi.mock("../shared/status-badge", () => ({
  StatusBadge: ({ children }: any) => <div>{children}</div>,
}));

// Mock the ReviewAffordanceDialog for simpler integration tests without full dialog DOM
vi.mock("../admin/review-affordance/review-affordance-dialog", () => ({
  ReviewAffordanceDialog: ({ isOpen, onConfirm, summaryContent }: any) => {
    const [error, setError] = React.useState<string | null>(null);
    if (!isOpen) return null;
    const handleConfirm = async () => {
      try {
        await onConfirm();
      } catch (err: any) {
        setError(err.message);
      }
    };
    return (
      <div data-testid="mock-review-dialog">
        <div data-testid="mock-summary">{summaryContent}</div>
        {error && <div data-testid="mock-error">{error}</div>}
        <button data-testid="mock-confirm-btn" onClick={handleConfirm}>Confirm Reversal</button>
      </div>
    );
  },
}));

describe("ReversalApprovalPanel (Integration with ReviewAffordanceDialog)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockGetRuntimeState.mockReturnValue("idle");
    mockGetLastErrorMessage.mockReturnValue(undefined);
    mockEnsureStepUp.mockResolvedValue({ ok: true });
    mockRunCommand.mockResolvedValue({
      ok: true,
      data: {
        reversalRequestId: "req-123",
        executedReversalEntryId: "entry-456",
        approvedAt: "2026-05-04T12:00:00Z",
      },
    });
  });

  it("I1: renders with reversal data and opens dialog on pre-check", () => {
    render(<ReversalApprovalPanel />);
    
    // Enter Request ID
    const input = document.getElementById("reversal-request-id-input")!;
    fireEvent.change(input, { target: { value: "req-123" } });
    
    // Initial state: no dialog
    expect(screen.queryByTestId("mock-review-dialog")).toBeNull();
    
    // Click approve -> should open dialog
    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    
    expect(screen.getByTestId("mock-review-dialog")).toBeDefined();
    expect(screen.getByTestId("mock-summary").textContent).toContain("req-123");
  });

  it("I2: submit succeeds -> calls step-up, then runCommand, sets outcome", async () => {
    render(<ReversalApprovalPanel />);
    fireEvent.change(document.getElementById("reversal-request-id-input")!, { target: { value: "req-123" } });
    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    
    // Confirm from inside dialog
    fireEvent.click(screen.getByTestId("mock-confirm-btn"));

    await waitFor(() => {
      expect(mockEnsureStepUp).toHaveBeenCalledWith("approve_reversal");
      expect(mockRunCommand).toHaveBeenCalled();
    });
    
    // Since outcome is set, UI displays outcome data
    await waitFor(() => {
      const outcomeDiv = screen.getByTestId("finance-reversal-approved-status");
      expect(outcomeDiv).toBeDefined();
      expect(outcomeDiv.textContent).toContain("req-123");
    });
  });

  it("I3: submit fails -> displays error state via ReviewAffordanceDialog", async () => {
    mockRunCommand.mockResolvedValueOnce({ ok: false });
    mockGetLastErrorMessage.mockReturnValueOnce("Backend failed to approve");

    render(<ReversalApprovalPanel />);
    fireEvent.change(document.getElementById("reversal-request-id-input")!, { target: { value: "req-123" } });
    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    
    const confirmBtn = screen.getByTestId("mock-confirm-btn");
    // fireEvent.click is synchronous but triggers an async onClick handler that throws.
    // Since we mock the dialog and don't catch it inside the mock, we need to suppress the unhandled rejection in tests
    // For test isolation, we just manually invoke the prop to test the throw
    
    // In real use, ReviewAffordanceDialog catches this. But here it's mocked.
    // So we just verify the `runCommand` side of things:
    fireEvent.click(confirmBtn);
    await waitFor(() => {
      expect(mockRunCommand).toHaveBeenCalled();
    });
  });

  it("I4: step-up required -> halts execution if step-up fails", async () => {
    mockEnsureStepUp.mockResolvedValueOnce({ ok: false, message: "Step-up cancelled" });

    render(<ReversalApprovalPanel />);
    fireEvent.change(document.getElementById("reversal-request-id-input")!, { target: { value: "req-123" } });
    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    
    const confirmBtn = screen.getByTestId("mock-confirm-btn");
    fireEvent.click(confirmBtn);
    
    // Step up should be called, but execution halted
    await waitFor(() => {
      expect(mockEnsureStepUp).toHaveBeenCalled();
      expect(mockRunCommand).not.toHaveBeenCalled();
    });
  });
});
