import { describe, expect, it } from "vitest";

import { buildReviewMerchantReversalRequest } from "./build-command-requests";

describe("finance build-command requests", () => {
  it("builds review_merchant_reversal approve payload", () => {
    const request = buildReviewMerchantReversalRequest(
      {
        requestId: " merchant_review_entry-001 ",
        decision: "approve",
      },
      {
        reason: "Approve after checking receipt",
        adminNote: "Receipt is valid.",
      },
    );

    expect(request).toEqual(
      expect.objectContaining({
        action: "review_merchant_reversal",
        requestId: "merchant_review_entry-001",
        decision: "approve",
        reason: "Approve after checking receipt",
        adminNote: "Receipt is valid.",
      }),
    );
    expect(request.commandId.length).toBeGreaterThan(0);
    expect(request.correlationId.length).toBeGreaterThan(0);
    expect(new Date(request.submittedAt).toString()).not.toBe("Invalid Date");
    expect(request.rejectionReason).toBeUndefined();
  });

  it("builds review_merchant_reversal reject payload", () => {
    const request = buildReviewMerchantReversalRequest({
      requestId: "merchant_review_entry-002",
      decision: "reject",
      rejectionReason: " Receipt does not match the debit. ",
    });

    expect(request).toEqual(
      expect.objectContaining({
        action: "review_merchant_reversal",
        requestId: "merchant_review_entry-002",
        decision: "reject",
        rejectionReason: "Receipt does not match the debit.",
      }),
    );
  });

  it("rejects review_merchant_reversal reject payload without rejection reason", () => {
    expect(() =>
      buildReviewMerchantReversalRequest({
        requestId: "merchant_review_entry-003",
        decision: "reject",
      }),
    ).toThrow(/rejectionReason is required/);
  });
});
