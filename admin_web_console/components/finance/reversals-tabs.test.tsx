import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { useEffect } from "react";
import { describe, expect, it, vi } from "vitest";

import { ReversalsTabs } from "./reversals-tabs";

vi.mock("@/components/finance/merchant-reversal-review-container", () => ({
  MerchantReversalReviewContainer: ({
    onPendingCountChange,
  }: {
    onPendingCountChange?: (count: number) => void;
  }) => {
    useEffect(() => {
      onPendingCountChange?.(3);
    }, [onPendingCountChange]);
    return <div>merchant panel</div>;
  },
}));

vi.mock("@/components/finance/reversal-approval-panel", () => ({
  ReversalApprovalPanel: () => <div>admin panel</div>,
}));

describe("ReversalsTabs", () => {
  it("shows the merchant pending count badge", async () => {
    render(<ReversalsTabs />);

    await waitFor(() => {
      expect(screen.getByText("3")).toBeTruthy();
    });
    expect(
      screen.getByRole("tab", { name: /طلبات التجار/ }).getAttribute("aria-selected"),
    ).toBe("true");
  });

  it("switches between merchant and admin tabs", () => {
    render(<ReversalsTabs />);

    fireEvent.click(screen.getByRole("tab", { name: "طلبات إدارية" }));

    expect(
      screen.getByRole("tab", { name: "طلبات إدارية" }).getAttribute("aria-selected"),
    ).toBe("true");
    expect(screen.getByText("admin panel")).toBeTruthy();
  });
});
