import { describe, expect, it, vi } from "vitest";

import type {
  ApproveReversalCommandRequest,
  ApproveTopUpCommandRequest,
  RejectTopUpCommandRequest,
  ReviewMerchantReversalCommandRequest,
  ReverseWalletEntryCommandRequest,
  VerifyWalletReadinessCommandRequest,
} from "./command-contracts";
import {
  FINANCE_COMMAND_CALLABLE_SURFACES,
  createFinanceCommandAdaptersTransport,
} from "./finance-command-adapters";
import {
  createTypeSafeMockInvoker,
  readCallableMockCall,
} from "../testing/type-safe-mock-invoker";

function makeApproveTopUpRequest(): ApproveTopUpCommandRequest {
  return {
    action: "approve_topup",
    commandId: "cmd-approve-topup-001",
    correlationId: "corr-approve-topup-001",
    reason: "Top-up approval from admin queue",
    submittedAt: "2026-04-09T23:00:00.000Z",
    requestId: "topup-request-001",
    venueId: "venue-001",
    expectedState: {
      status: "pending",
      decision_state: "unreviewed",
    },
  };
}

function makeRejectTopUpRequest(): RejectTopUpCommandRequest {
  return {
    action: "reject_topup",
    commandId: "cmd-reject-topup-001",
    correlationId: "corr-reject-topup-001",
    reason: "Top-up rejected after manual review",
    submittedAt: "2026-04-09T23:01:00.000Z",
    requestId: "topup-request-002",
    venueId: "venue-001",
    expectedState: {
      status: "pending",
      decision_state: "unreviewed",
    },
  };
}

function makeReverseWalletEntryRequest(): ReverseWalletEntryCommandRequest {
  return {
    action: "reverse_wallet_entry",
    commandId: "cmd-reverse-wallet-entry-001",
    correlationId: "corr-reverse-wallet-entry-001",
    reason: "Reversal approved by finance",
    submittedAt: "2026-04-09T23:02:00.000Z",
    entryId: "entry-001",
    venueId: "venue-001",
    expectedState: {
      entry_status: "posted",
      reversal_state: "not_reversed",
      entry_type: "debit",
    },
  };
}

function makeVerifyWalletReadinessRequest(): VerifyWalletReadinessCommandRequest {
  return {
    action: "verify_wallet_readiness",
    commandId: "cmd-readiness-001",
    correlationId: "corr-readiness-001",
    reason: "Manual readiness verification",
    submittedAt: "2026-04-09T23:03:00.000Z",
    expectedState: {
      readiness_scope: "finance_ops",
    },
  };
}

function makeApproveReversalRequest(): ApproveReversalCommandRequest {
  return {
    action: "approve_reversal",
    commandId: "cmd-approve-reversal-001",
    correlationId: "corr-approve-reversal-001",
    reason: "Second-actor approval",
    submittedAt: "2026-04-09T23:04:00.000Z",
    reversalRequestId: "reversal-request-001",
    expectedState: {
      approval_state: "pending_second_approval",
      request_not_expired: true,
    },
  };
}

function makeReviewMerchantReversalRequest(
  overrides: Partial<ReviewMerchantReversalCommandRequest> = {},
): ReviewMerchantReversalCommandRequest {
  return {
    action: "review_merchant_reversal",
    commandId: "cmd-review-merchant-reversal-001",
    correlationId: "corr-review-merchant-reversal-001",
    reason: "Review merchant reversal request",
    submittedAt: "2026-04-09T23:05:00.000Z",
    requestId: "merchant_review_entry-001",
    decision: "approve",
    ...overrides,
  };
}

describe("finance command adapters", () => {
  it("maps approve_topup to review callable payload and propagates expected_state + idempotency", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      linked_entry_id: "entry-credited-001",
      reviewed_at: "2026-04-09T23:00:30.000Z",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeApproveTopUpRequest();
    const result = await transport.execute("approve_topup", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reviewMerchantTopUpRequest");
    expect(payload.requestId).toBe(request.requestId);
    expect(payload.decision).toBe("credit");
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);
    expect(payload.expectedState).toEqual(request.expectedState);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("credited");
      expect(result.data.linkedEntryId).toBe("entry-credited-001");
      expect(result.data.reviewedAt).toBe("2026-04-09T23:00:30.000Z");
    }
  });

  it("maps reject_topup to review callable payload and carries reject note from reason when note is absent", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      reviewed_at: "2026-04-09T23:01:30.000Z",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeRejectTopUpRequest();
    const result = await transport.execute("reject_topup", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reviewMerchantTopUpRequest");
    expect(payload.decision).toBe("reject");
    expect(payload.adminNote).toBe(request.reason);
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);
    expect(payload.expectedState).toEqual(request.expectedState);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("rejected");
      expect(result.data.reviewedAt).toBe("2026-04-09T23:01:30.000Z");
    }
  });

  it("maps reverse_wallet_entry to reversal callable payload and propagates expected_state + idempotency", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      reversalEntryId: "reversal_entry_001",
      venueId: "venue-001",
      reversedAt: "2026-04-09T23:02:30.000Z",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeReverseWalletEntryRequest();
    const result = await transport.execute("reverse_wallet_entry", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reverseWalletEntry");
    expect(payload.entryId).toBe(request.entryId);
    expect(payload.venueId).toBe(request.venueId);
    expect(payload.reason).toBe(request.reason);
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);
    expect(payload.expectedState).toEqual(request.expectedState);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("reversed");
      expect(result.data.reversalEntryId).toBe("reversal_entry_001");
      expect(result.data.reversedAt).toBe("2026-04-09T23:02:30.000Z");
    }
  });

  it("maps reverse_wallet_entry pending_second_approval response when reversal requires dual approval", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      status: "pending_second_approval",
      reversalRequestId: "reversal-request-9001",
      venueId: "venue-001",
      approvalExpiresAt: "2026-04-11T00:00:00.000Z",
      requiredSecondApproverRole: "finance_admin",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeReverseWalletEntryRequest();
    const result = await transport.execute("reverse_wallet_entry", request);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("pending_second_approval");
      expect(result.data.reversalRequestId).toBe("reversal-request-9001");
      expect(result.data.requiredSecondApproverRole).toBe("finance_admin");
      expect(result.data.approvalExpiresAt).toBe("2026-04-11T00:00:00.000Z");
    }
  });

  it("maps approve_reversal to approval callable payload and keeps idempotency + expected_state envelope", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      reversalRequestId: "reversal-request-001",
      executedReversalEntryId: "reversal_entry_001",
      approvedAt: "2026-04-10T00:05:00.000Z",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeApproveReversalRequest();
    const result = await transport.execute("approve_reversal", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("approveWalletReversalRequest");
    expect(payload.reversalRequestId).toBe(request.reversalRequestId);
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);
    expect(payload.expectedState).toEqual(request.expectedState);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("approved_and_executed");
      expect(result.data.executedReversalEntryId).toBe("reversal_entry_001");
      expect(result.data.approvedAt).toBe("2026-04-10T00:05:00.000Z");
    }
  });

  it("maps review_merchant_reversal approve decision to merchant review callable", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      requestId: "merchant_review_entry-001",
      status: "approved_and_executed",
      reversalEntryId: "reversal_entry_merchant_001",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeReviewMerchantReversalRequest({
      adminNote: "Payment verified manually.",
    });
    const result = await transport.execute("review_merchant_reversal", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reviewMerchantWalletReversalRequest");
    expect(payload.requestId).toBe(request.requestId);
    expect(payload.decision).toBe("approve");
    expect(payload.adminNote).toBe("Payment verified manually.");
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("approved_and_executed");
      expect(result.data.reversalEntryId).toBe("reversal_entry_merchant_001");
    }
  });

  it("maps review_merchant_reversal reject decision with rejection reason", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      requestId: "merchant_review_entry-001",
      status: "rejected",
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeReviewMerchantReversalRequest({
      decision: "reject",
      rejectionReason: "Receipt does not match wallet debit.",
    });
    const result = await transport.execute("review_merchant_reversal", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("reviewMerchantWalletReversalRequest");
    expect(payload.decision).toBe("reject");
    expect(payload.rejectionReason).toBe("Receipt does not match wallet debit.");

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("rejected");
      expect(result.data.requestId).toBe("merchant_review_entry-001");
    }
  });

  it("maps review_merchant_reversal pending second approval response", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      success: true,
      requestId: "merchant_review_entry-001",
      status: "pending_second_approval",
      requiredSecondApproverRole: "finance_admin",
      approvalExpiresAt: 1775865600000,
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeReviewMerchantReversalRequest();
    const result = await transport.execute("review_merchant_reversal", request);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("pending_second_approval");
      expect(result.data.requiredSecondApproverRole).toBe("finance_admin");
      expect(result.data.approvalExpiresAt).toBe("2026-04-11T00:00:00.000Z");
    }
  });

  it("maps readiness callable response and propagates command envelope fields", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      overallStatus: "WARN",
      warningChecks: ["read_models"],
      failureChecks: [],
      checkedAt: 1775775810000,
    }));

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeVerifyWalletReadinessRequest();
    const result = await transport.execute("verify_wallet_readiness", request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);

    expect(callableName).toBe("verifyWalletOperationalReadiness");
    expect(payload.commandId).toBe(request.commandId);
    expect(payload.idempotencyKey).toBe(request.commandId);
    expect(payload.expectedState).toEqual(request.expectedState);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.status).toBe("WARN");
      expect(result.data.warningChecks).toEqual(["read_models"]);
      expect(result.data.failureChecks).toEqual([]);
      expect(result.data.checkedAt).toBe(new Date(1775775810000).toISOString());
    }
  });

  it("normalizes backend callable errors into transport status codes", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => {
      throw {
        code: "permission-denied",
        message: "Requires admin privileges",
      };
    });

    const transport = createFinanceCommandAdaptersTransport({ invokeCallable });
    const request = makeReverseWalletEntryRequest();
    const result = await transport.execute("reverse_wallet_entry", request);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toEqual(
        expect.objectContaining({
          status: 403,
          message: "Requires admin privileges",
        }),
      );
    }
  });

  it("normalizes approval callable conflict and authorization errors", async () => {
    const conflictCallable = createTypeSafeMockInvoker(async () => {
      throw {
        code: "failed-precondition",
        message: "reversal_request_expired",
      };
    });

    const conflictTransport = createFinanceCommandAdaptersTransport({
      invokeCallable: conflictCallable,
    });
    const request = makeApproveReversalRequest();
    const conflict = await conflictTransport.execute("approve_reversal", request);

    expect(conflict.ok).toBe(false);
    if (!conflict.ok) {
      expect(conflict.error).toEqual(
        expect.objectContaining({
          status: 409,
          message: "reversal_request_expired",
        }),
      );
    }

    const forbiddenCallable = createTypeSafeMockInvoker(async () => {
      throw {
        code: "permission-denied",
        message: "Requires admin privileges",
      };
    });
    const forbiddenTransport = createFinanceCommandAdaptersTransport({
      invokeCallable: forbiddenCallable,
    });
    const forbidden = await forbiddenTransport.execute("approve_reversal", request);

    expect(forbidden.ok).toBe(false);
    if (!forbidden.ok) {
      expect(forbidden.error).toEqual(
        expect.objectContaining({
          status: 403,
          message: "Requires admin privileges",
        }),
      );
    }
  });
});
