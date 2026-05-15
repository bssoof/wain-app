import type {
  ApproveReversalCommandRequest,
  ApproveTopUpCommandRequest,
  FinanceCommandRequestMap,
  FinanceCommandType,
  RejectTopUpCommandRequest,
  ReviewMerchantReversalCommandRequest,
  ReverseWalletEntryCommandRequest,
  VerifyWalletReadinessCommandRequest,
} from "./command-contracts";
import {
  mapBackendErrorToTransportError,
  type FinanceCallableInvoker,
  type FinanceCommandTransport,
  type FinanceCommandTransportResult,
} from "./finance-command-transport";

type FinanceCallableName =
  | "reviewMerchantTopUpRequest"
  | "approveWalletReversalRequest"
  | "reviewMerchantWalletReversalRequest"
  | "reverseWalletEntry"
  | "verifyWalletOperationalReadiness";

export const FINANCE_COMMAND_CALLABLE_SURFACES: Record<
  FinanceCommandType,
  FinanceCallableName | null
> = {
  approve_topup: "reviewMerchantTopUpRequest",
  reject_topup: "reviewMerchantTopUpRequest",
  reverse_wallet_entry: "reverseWalletEntry",
  approve_reversal: "approveWalletReversalRequest",
  review_merchant_reversal: "reviewMerchantWalletReversalRequest",
  verify_wallet_readiness: "verifyWalletOperationalReadiness",
};

export type FinanceCommandAdaptersOptions = {
  invokeCallable: FinanceCallableInvoker;
  now?: () => Date;
};

export function createFinanceCommandAdaptersTransport(
  options: FinanceCommandAdaptersOptions,
): FinanceCommandTransport {
  const now = options.now ?? (() => new Date());

  return {
    async execute<T extends FinanceCommandType>(
      command: T,
      request: FinanceCommandRequestMap[T],
    ): Promise<FinanceCommandTransportResult<T>> {
      switch (command) {
        case "approve_topup":
          return (await executeApproveTopUp(
            options.invokeCallable,
            request as ApproveTopUpCommandRequest,
          )) as FinanceCommandTransportResult<T>;
        case "reject_topup":
          return (await executeRejectTopUp(
            options.invokeCallable,
            request as RejectTopUpCommandRequest,
          )) as FinanceCommandTransportResult<T>;
        case "reverse_wallet_entry":
          return (await executeReverseWalletEntry(
            options.invokeCallable,
            request as ReverseWalletEntryCommandRequest,
          )) as FinanceCommandTransportResult<T>;
        case "verify_wallet_readiness":
          return (await executeVerifyWalletReadiness(
            options.invokeCallable,
            request as VerifyWalletReadinessCommandRequest,
            now,
          )) as FinanceCommandTransportResult<T>;
        case "approve_reversal":
          return (await executeApproveReversal(
            options.invokeCallable,
            request as ApproveReversalCommandRequest,
          )) as FinanceCommandTransportResult<T>;
        case "review_merchant_reversal":
          return (await executeReviewMerchantReversal(
            options.invokeCallable,
            request as ReviewMerchantReversalCommandRequest,
          )) as FinanceCommandTransportResult<T>;
        default:
          return missingSurfaceResult(command, request.correlationId, request);
      }
    },
  };
}

async function executeApproveTopUp(
  invokeCallable: FinanceCallableInvoker,
  request: ApproveTopUpCommandRequest,
): Promise<FinanceCommandTransportResult<"approve_topup">> {
  try {
    const response = asRecord(
      await invokeCallable(
        FINANCE_COMMAND_CALLABLE_SURFACES.approve_topup!,
        buildTopUpReviewPayload(request, "credit"),
      ),
    );

    const linkedEntryId =
      toNonEmptyString(response?.linkedEntryId) ??
      toNonEmptyString(response?.linked_entry_id);
    const reviewedAt =
      toIsoString(response?.reviewedAt) ??
      toIsoString(response?.reviewed_at) ??
      undefined;

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "approve_topup",
        requestId: request.requestId,
        venueId: request.venueId,
        status: "credited",
        ...(linkedEntryId ? { linkedEntryId } : {}),
        ...(reviewedAt ? { reviewedAt } : {}),
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeRejectTopUp(
  invokeCallable: FinanceCallableInvoker,
  request: RejectTopUpCommandRequest,
): Promise<FinanceCommandTransportResult<"reject_topup">> {
  try {
    const response = asRecord(
      await invokeCallable(
        FINANCE_COMMAND_CALLABLE_SURFACES.reject_topup!,
        buildTopUpReviewPayload(request, "reject"),
      ),
    );

    const reviewedAt =
      toIsoString(response?.reviewedAt) ??
      toIsoString(response?.reviewed_at) ??
      undefined;

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "reject_topup",
        requestId: request.requestId,
        venueId: request.venueId,
        status: "rejected",
        ...(reviewedAt ? { reviewedAt } : {}),
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeReverseWalletEntry(
  invokeCallable: FinanceCallableInvoker,
  request: ReverseWalletEntryCommandRequest,
): Promise<FinanceCommandTransportResult<"reverse_wallet_entry">> {
  try {
    const response = asRecord(
      await invokeCallable(
        FINANCE_COMMAND_CALLABLE_SURFACES.reverse_wallet_entry!,
        {
          entryId: request.entryId,
          venueId: request.venueId,
          reason: request.reason,
          ...(request.adminNote
            ? {
                adminNote: request.adminNote,
              }
            : {}),
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          submittedAt: request.submittedAt,
        },
      ),
    );

    const reversalStatus = normalizeReversalStatus(response?.status);
    const reversalRequestId =
      toNonEmptyString(response?.reversalRequestId) ??
      toNonEmptyString(response?.reversal_request_id);

    if (reversalStatus === "pending_second_approval") {
      if (!reversalRequestId) {
        return {
          ok: false,
          correlationId: request.correlationId,
          error: {
            status: 503,
            message:
              "reverseWalletEntry callable returned pending_second_approval without reversalRequestId.",
            details: {
              command: request.action,
              entryId: request.entryId,
            },
          },
        };
      }

      return {
        ok: true,
        correlationId: request.correlationId,
        data: {
          action: "reverse_wallet_entry",
          originalEntryId: request.entryId,
          venueId: toNonEmptyString(response?.venueId) ?? request.venueId,
          status: "pending_second_approval",
          reversalRequestId,
          ...(toNonEmptyString(response?.requiredSecondApproverRole)
            ? {
                requiredSecondApproverRole: toNonEmptyString(
                  response?.requiredSecondApproverRole,
                ) as "finance_admin" | "super_admin",
              }
            : {}),
          ...(toIsoString(response?.approvalExpiresAt) ??
          toIsoString(response?.approval_expires_at)
            ? {
                approvalExpiresAt:
                  toIsoString(response?.approvalExpiresAt) ??
                  toIsoString(response?.approval_expires_at),
              }
            : {}),
        },
      };
    }

    const reversalEntryId =
      toNonEmptyString(response?.reversalEntryId) ??
      toNonEmptyString(response?.reversal_entry_id);

    if (!reversalEntryId) {
      return {
        ok: false,
        correlationId: request.correlationId,
        error: {
          status: 503,
          message:
            "reverseWalletEntry callable returned success without reversalEntryId.",
          details: {
            command: request.action,
            entryId: request.entryId,
          },
        },
      };
    }

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "reverse_wallet_entry",
        originalEntryId: request.entryId,
        reversalEntryId,
        venueId: toNonEmptyString(response?.venueId) ?? request.venueId,
        status: "reversed",
        ...(reversalRequestId
          ? {
              reversalRequestId,
            }
          : {}),
        ...(toIsoString(response?.reversedAt)
          ? { reversedAt: toIsoString(response?.reversedAt) }
          : {}),
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeApproveReversal(
  invokeCallable: FinanceCallableInvoker,
  request: ApproveReversalCommandRequest,
): Promise<FinanceCommandTransportResult<"approve_reversal">> {
  try {
    const response = asRecord(
      await invokeCallable(
        FINANCE_COMMAND_CALLABLE_SURFACES.approve_reversal!,
        {
          reversalRequestId: request.reversalRequestId,
          reason: request.reason,
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          submittedAt: request.submittedAt,
        },
      ),
    );

    const executedReversalEntryId =
      toNonEmptyString(response?.executedReversalEntryId) ??
      toNonEmptyString(response?.executed_reversal_entry_id) ??
      toNonEmptyString(response?.reversalEntryId) ??
      toNonEmptyString(response?.reversal_entry_id);

    if (!executedReversalEntryId) {
      return {
        ok: false,
        correlationId: request.correlationId,
        error: {
          status: 503,
          message:
            "approveWalletReversalRequest callable returned success without executed reversal entry id.",
          details: {
            command: request.action,
            reversalRequestId: request.reversalRequestId,
          },
        },
      };
    }

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "approve_reversal",
        reversalRequestId:
          toNonEmptyString(response?.reversalRequestId) ??
          toNonEmptyString(response?.reversal_request_id) ??
          request.reversalRequestId,
        status: "approved_and_executed",
        executedReversalEntryId,
        approvedAt:
          toIsoString(response?.approvedAt) ??
          toIsoString(response?.approved_at) ??
          new Date().toISOString(),
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeReviewMerchantReversal(
  invokeCallable: FinanceCallableInvoker,
  request: ReviewMerchantReversalCommandRequest,
): Promise<FinanceCommandTransportResult<"review_merchant_reversal">> {
  try {
    const response = asRecord(
      await invokeCallable(
        FINANCE_COMMAND_CALLABLE_SURFACES.review_merchant_reversal!,
        {
          requestId: request.requestId,
          decision: request.decision,
          ...(request.adminNote ? { adminNote: request.adminNote } : {}),
          ...(request.rejectionReason
            ? { rejectionReason: request.rejectionReason }
            : {}),
          reason: request.reason,
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          submittedAt: request.submittedAt,
        },
      ),
    );

    const status = normalizeMerchantReversalReviewStatus(response?.status);
    if (!status) {
      return {
        ok: false,
        correlationId: request.correlationId,
        error: {
          status: 503,
          message:
            "reviewMerchantWalletReversalRequest callable returned an unknown status.",
          details: {
            command: request.action,
            requestId: request.requestId,
            status: response?.status,
          },
        },
      };
    }

    const reversalEntryId =
      toNonEmptyString(response?.reversalEntryId) ??
      toNonEmptyString(response?.reversal_entry_id);
    if (status === "approved_and_executed" && !reversalEntryId) {
      return {
        ok: false,
        correlationId: request.correlationId,
        error: {
          status: 503,
          message:
            "reviewMerchantWalletReversalRequest callable executed without reversalEntryId.",
          details: {
            command: request.action,
            requestId: request.requestId,
          },
        },
      };
    }

    const requiredSecondApproverRole =
      toNonEmptyString(response?.requiredSecondApproverRole) ??
      toNonEmptyString(response?.required_second_approver_role);
    if (status === "pending_second_approval" && !requiredSecondApproverRole) {
      return {
        ok: false,
        correlationId: request.correlationId,
        error: {
          status: 503,
          message:
            "reviewMerchantWalletReversalRequest callable returned pending_second_approval without requiredSecondApproverRole.",
          details: {
            command: request.action,
            requestId: request.requestId,
          },
        },
      };
    }

    const approvalExpiresAt =
      toIsoString(response?.approvalExpiresAt) ??
      toIsoString(response?.approval_expires_at);

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "review_merchant_reversal",
        requestId:
          toNonEmptyString(response?.requestId) ??
          toNonEmptyString(response?.request_id) ??
          request.requestId,
        status,
        ...(reversalEntryId ? { reversalEntryId } : {}),
        ...(requiredSecondApproverRole
          ? {
              requiredSecondApproverRole:
                requiredSecondApproverRole as "finance_admin" | "super_admin",
            }
          : {}),
        ...(approvalExpiresAt ? { approvalExpiresAt } : {}),
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeVerifyWalletReadiness(
  invokeCallable: FinanceCallableInvoker,
  request: VerifyWalletReadinessCommandRequest,
  now: () => Date,
): Promise<FinanceCommandTransportResult<"verify_wallet_readiness">> {
  try {
    const response = asRecord(
      await invokeCallable(
        FINANCE_COMMAND_CALLABLE_SURFACES.verify_wallet_readiness!,
        {
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          reason: request.reason,
          submittedAt: request.submittedAt,
        },
      ),
    );

    const warningChecks = toStringArray(
      response?.warningChecks ?? response?.warning_checks,
    );
    const failureChecks = toStringArray(
      response?.failureChecks ?? response?.failure_checks,
    );
    const status =
      normalizeReadinessStatus(response?.overallStatus ?? response?.status) ??
      (failureChecks.length > 0
        ? "FAIL"
        : warningChecks.length > 0
          ? "WARN"
          : "PASS");

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "verify_wallet_readiness",
        status,
        warningChecks,
        failureChecks,
        checkedAt:
          toIsoString(response?.checkedAt) ??
          toIsoString(response?.checked_at) ??
          now().toISOString(),
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

function buildTopUpReviewPayload(
  request: ApproveTopUpCommandRequest | RejectTopUpCommandRequest,
  decision: "credit" | "reject",
) {
  return {
    requestId: request.requestId,
    venueId: request.venueId,
    decision,
    adminNote:
      decision === "reject"
        ? (request.adminNote ?? request.reason)
        : request.adminNote,
    commandId: request.commandId,
    correlationId: request.correlationId,
    idempotencyKey: request.commandId,
    expectedState: request.expectedState,
    reason: request.reason,
    submittedAt: request.submittedAt,
  };
}

function missingSurfaceResult<T extends FinanceCommandType>(
  command: T,
  correlationId: string,
  request: { commandId: string },
): FinanceCommandTransportResult<T> {
  return {
    ok: false,
    correlationId,
    error: {
      status: 503,
      message: `No backend callable surface exists for command ${command}.`,
      details: {
        command,
        commandId: request.commandId,
        requiredSurface: FINANCE_COMMAND_CALLABLE_SURFACES[command],
      },
    },
  };
}

function toBackendFailureResult<T extends FinanceCommandType>(
  correlationId: string,
  error: unknown,
): FinanceCommandTransportResult<T> {
  return {
    ok: false,
    correlationId,
    error: mapBackendErrorToTransportError(error),
  };
}

function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, any>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function toIsoString(value: unknown): string | undefined {
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
    return undefined;
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value).toISOString();
  }

  return undefined;
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => (typeof entry === "string" ? entry.trim() : ""))
    .filter((entry) => entry.length > 0);
}

function normalizeReadinessStatus(value: unknown): "PASS" | "WARN" | "FAIL" | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalized = value.trim().toUpperCase();
  if (normalized === "PASS" || normalized === "WARN" || normalized === "FAIL") {
    return normalized;
  }

  return undefined;
}

function normalizeReversalStatus(
  value: unknown,
): "reversed" | "pending_second_approval" | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "reversed" || normalized === "pending_second_approval") {
    return normalized;
  }

  return undefined;
}

function normalizeMerchantReversalReviewStatus(
  value: unknown,
):
  | "approved_and_executed"
  | "pending_second_approval"
  | "rejected"
  | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalized = value.trim().toLowerCase();
  if (
    normalized === "approved_and_executed" ||
    normalized === "pending_second_approval" ||
    normalized === "rejected"
  ) {
    return normalized;
  }

  return undefined;
}
