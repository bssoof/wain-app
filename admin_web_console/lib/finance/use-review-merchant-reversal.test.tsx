import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";

import {
  mapReviewMerchantReversalError,
  useReviewMerchantReversal,
} from "./use-review-merchant-reversal";

const { runCommandMock } = vi.hoisted(() => ({
  runCommandMock: vi.fn(),
}));

vi.mock("@/components/finance/finance-command-provider", () => ({
  useFinanceCommands: () => ({
    runCommand: runCommandMock,
  }),
}));

function ReviewProbe() {
  const { execute } = useReviewMerchantReversal();
  return (
    <button
      onClick={async () => {
        const result = await execute({
          requestId: "merchant_review_entry_001",
          decision: "approve",
          adminNote: "ok",
        });
        document.body.dataset.resultStatus = result.status;
      }}
      type="button"
    >
      approve
    </button>
  );
}

describe("useReviewMerchantReversal", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("calls the finance command provider with the review payload", async () => {
    runCommandMock.mockResolvedValue({
      ok: true,
      data: {
        action: "review_merchant_reversal",
        requestId: "merchant_review_entry_001",
        status: "approved_and_executed",
      },
    });

    render(<ReviewProbe />);
    fireEvent.click(screen.getByRole("button", { name: "approve" }));

    await waitFor(() => {
      expect(document.body.dataset.resultStatus).toBe("approved_and_executed");
    });
    expect(runCommandMock).toHaveBeenCalledWith(
      "merchant_review_entry_001:review_merchant_reversal",
      "review_merchant_reversal",
      expect.objectContaining({
        action: "review_merchant_reversal",
        requestId: "merchant_review_entry_001",
        decision: "approve",
        adminNote: "ok",
      }),
    );
  });

  it("maps backend review errors to Arabic operator messages", () => {
    expect(mapReviewMerchantReversalError("entry_already_reversed")).toBe(
      "تم تصحيح هذه العملية من قِبل أدمن آخر",
    );
    expect(mapReviewMerchantReversalError("request_not_pending_review")).toBe(
      "تمت مراجعة الطلب مسبقًا",
    );
  });
});
