import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach, afterEach } from "vitest";
import { ReviewAffordanceDialog } from "./review-affordance-dialog";


describe("ReviewAffordanceDialog", () => {
  const mockOnOpenChange = vi.fn();
  const mockOnConfirm = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders the title and summary content correctly", () => {
    render(
      <ReviewAffordanceDialog 
        isOpen={true} 
        onOpenChange={mockOnOpenChange}
        title="Approve Top-Up"
        summaryContent={<div data-testid="summary-mock">100 WAIN</div>}
        onConfirm={mockOnConfirm}
      />
    );

    expect(screen.getByText("Approve Top-Up")).toBeDefined();
    expect(screen.getByTestId("summary-mock")).toBeDefined();
    expect(screen.getByText("100 WAIN")).toBeDefined();
  });

  it("shows loading state and prevents double submission during inflight action", async () => {
    // Disable fake timers specifically for this test so waitFor works smoothly
    vi.useRealTimers();

    // Create a delayed promise to simulate an inflight request
    let resolveConfirm: () => void;
    mockOnConfirm.mockImplementation(() => new Promise<void>((resolve) => {
      resolveConfirm = resolve;
    }));

    render(
      <ReviewAffordanceDialog 
        isOpen={true} 
        onOpenChange={mockOnOpenChange}
        title="Approve Action"
        summaryContent={<div>Action details</div>}
        onConfirm={mockOnConfirm}
      />
    );

    const confirmButton = screen.getByTestId("review-confirm-button");
    
    // Initial state
    expect(confirmButton.textContent).toBe("Confirm");
    expect((confirmButton as HTMLButtonElement).disabled).toBe(false);

    // Click to start submission
    fireEvent.click(confirmButton);

    // Button should immediately show processing and be disabled
    expect(confirmButton.textContent).toContain("Processing...");
    expect((confirmButton as HTMLButtonElement).disabled).toBe(true);
    expect(mockOnConfirm).toHaveBeenCalledTimes(1);

    // Additional clicks should not trigger onConfirm again since button is disabled
    fireEvent.click(confirmButton);
    expect(mockOnConfirm).toHaveBeenCalledTimes(1);

    // Resolve the promise
    resolveConfirm!();
    
    // Wait for success state to appear
    await waitFor(() => {
      expect(screen.getByTestId("review-success")).toBeDefined();
    });
  });

  it("displays error message and allows retry when action fails", async () => {
    vi.useRealTimers();
    mockOnConfirm.mockRejectedValueOnce(new Error("Insufficient funds"));

    render(
      <ReviewAffordanceDialog 
        isOpen={true} 
        onOpenChange={mockOnOpenChange}
        title="Approve Action"
        summaryContent={<div>Action details</div>}
        onConfirm={mockOnConfirm}
      />
    );

    const confirmButton = screen.getByTestId("review-confirm-button");
    fireEvent.click(confirmButton);

    // Fast-forward promises so state updates
    await Promise.resolve();
    
    // Wait for the error to be caught and displayed
    await waitFor(() => {
      expect(screen.getByTestId("review-error").textContent).toContain("Insufficient funds");
    });

    // Button should be re-enabled for retry
    expect((confirmButton as HTMLButtonElement).disabled).toBe(false);
    expect(confirmButton.textContent).toBe("Confirm");
  });

  it("auto-closes after a successful confirmation delay", async () => {
    vi.useRealTimers();
    mockOnConfirm.mockResolvedValueOnce(undefined);

    render(
      <ReviewAffordanceDialog 
        isOpen={true} 
        onOpenChange={mockOnOpenChange}
        title="Approve Action"
        summaryContent={<div>Action details</div>}
        onConfirm={mockOnConfirm}
      />
    );

    fireEvent.click(screen.getByTestId("review-confirm-button"));

    await waitFor(() => {
      expect(screen.getByTestId("review-success")).toBeDefined();
    });

    // Wait for the 1500ms setTimeout inside the component to fire
    await waitFor(() => {
      expect(mockOnOpenChange).toHaveBeenCalledWith(false);
    }, { timeout: 2000 });
  });
});
