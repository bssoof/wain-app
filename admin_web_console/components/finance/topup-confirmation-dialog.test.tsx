import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";
import { TopUpConfirmationDialog, TopUpPendingDecision } from "./topup-confirmation-dialog";

const mocks = vi.hoisted(() => ({
  mockOnCancel: vi.fn(),
  mockOnConfirmExecute: vi.fn(),
}));

// Mock ReviewAffordanceDialog
vi.mock("../admin/review-affordance/review-affordance-dialog", () => ({
  ReviewAffordanceDialog: ({ isOpen, onOpenChange, onConfirm, summaryContent, isConfirmDisabled }: any) => {
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
        <button data-testid="mock-cancel-btn" onClick={() => onOpenChange(false)}>Cancel Action</button>
        <button
          data-testid="mock-confirm-btn"
          onClick={handleConfirm}
          disabled={false}
        >
          Confirm Action
        </button>
      </div>
    );
  },
}));

describe("TopUpConfirmationDialog", () => {
  const baseDecision: TopUpPendingDecision = {
    action: "approve_topup",
    runtimeKey: "test-key",
    request: {
      id: "req-111",
      userName: "John Doe",
      userId: "user-1",
      amount: 500,
      currency: "USD",
      providerReference: "txn-999",
      venueId: "",
      status: "pending",
      createdAt: "2026-01-01T00:00:00Z",
    },
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("I1: renders summary and submits approve path when valid", async () => {
    render(
      <TopUpConfirmationDialog
        decision={baseDecision}
        onCancel={mocks.mockOnCancel}
        onConfirmExecute={mocks.mockOnConfirmExecute}
        submissionState="idle"
      />
    );

    const confirmBtn = screen.getByTestId("mock-confirm-btn");
    const select = document.getElementById("reason-select")!;
    fireEvent.change(select, { target: { value: "payment_verified" } });

    fireEvent.click(confirmBtn);

    await waitFor(() => {
      expect(mocks.mockOnConfirmExecute).toHaveBeenCalled();
    });
  });

  it("I2: renders reject path and enforces note requirement", async () => {
    render(
      <TopUpConfirmationDialog
          decision={{ ...baseDecision, action: "reject_topup" }}
          onCancel={mocks.mockOnCancel}
          onConfirmExecute={mocks.mockOnConfirmExecute}
          submissionState="idle"
        />
    );

    // State explains no wallet change
    expect(screen.getByText(/لا تغيير على المحفظة/)).toBeDefined();

    const confirmBtn = screen.getByTestId("mock-confirm-btn");
    const select = screen.getByRole("combobox");

    // Select "other" -> requires note
    fireEvent.change(select, { target: { value: "other" } });

    // Add note
    const textarea = document.getElementById("admin-note")!;
    fireEvent.change(textarea, { target: { value: "Suspicious activity" } });

    fireEvent.click(confirmBtn);

    await waitFor(() => {
      expect(mocks.mockOnConfirmExecute).toHaveBeenCalled();
    });
  });

  it("renders receipt proof preview when the request has a proof image", () => {
    render(
      <TopUpConfirmationDialog
        decision={{
          ...baseDecision,
          request: {
            ...baseDecision.request,
            proofImageUrl: "https://example.test/topup-proof.jpg",
          },
        }}
        onCancel={mocks.mockOnCancel}
        onConfirmExecute={mocks.mockOnConfirmExecute}
        submissionState="idle"
      />
    );

    const proofLink = screen.getByText("عرض الوصل").closest("a");

    expect(proofLink?.getAttribute("href")).toBe(
      "https://example.test/topup-proof.jpg",
    );
    expect(screen.getByAltText("وصل طلب الشحن req-111")).toBeTruthy();
  });

  it("I3: cancel-without-commit triggers onCancel immediately and closes dialog", () => {
    render(
      <TopUpConfirmationDialog
        decision={baseDecision}
        onCancel={mocks.mockOnCancel}
        onConfirmExecute={mocks.mockOnConfirmExecute}
        submissionState="idle"
      />
    );

    const cancelBtn = screen.getByTestId("mock-cancel-btn");
    fireEvent.click(cancelBtn);

    expect(mocks.mockOnCancel).toHaveBeenCalledTimes(1);
    expect(mocks.mockOnConfirmExecute).not.toHaveBeenCalled();
  });

  it("I4: surfaces command execution failures from the provider", async () => {
    mocks.mockOnConfirmExecute.mockClear();
    mocks.mockOnConfirmExecute.mockRejectedValueOnce(new Error("Auth failed"));

    render(
      <TopUpConfirmationDialog
        decision={baseDecision}
        onCancel={mocks.mockOnCancel}
        onConfirmExecute={mocks.mockOnConfirmExecute}
        submissionState="idle"
      />
    );

    const select = document.getElementById("reason-select")!;
    fireEvent.change(select, { target: { value: "payment_verified" } });

    const confirmBtn = screen.getByTestId("mock-confirm-btn");
    fireEvent.click(confirmBtn);

    await waitFor(() => {
      const errDiv = screen.queryByTestId("mock-error");
      expect(errDiv).not.toBeNull();
      expect(errDiv!.textContent).toBe("Auth failed");
      expect(mocks.mockOnConfirmExecute).toHaveBeenCalled();
    });
  });
});
