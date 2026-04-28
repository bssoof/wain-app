import type { AdminCapabilityKey, AdminRole } from "@/lib/navigation/admin-contract";

export const FINANCE_COMMANDS = [
  "approve_topup",
  "reject_topup",
  "reverse_wallet_entry",
  "approve_reversal",
  "verify_wallet_readiness",
] as const;

export type FinanceCommandType = (typeof FINANCE_COMMANDS)[number];

export type FinanceCommandErrorCode =
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_error"
  | "unavailable";

export type FinanceCommandErrorStatus = 401 | 403 | 409 | 422 | 503;

export type FinanceCommandError = {
  code: FinanceCommandErrorCode;
  status: FinanceCommandErrorStatus;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

const ERROR_STATUS_BY_CODE: Record<FinanceCommandErrorCode, FinanceCommandErrorStatus> = {
  unauthorized: 401,
  forbidden: 403,
  conflict: 409,
  validation_error: 422,
  unavailable: 503,
};

const ERROR_RETRYABLE_BY_CODE: Record<FinanceCommandErrorCode, boolean> = {
  unauthorized: false,
  forbidden: false,
  conflict: true,
  validation_error: false,
  unavailable: true,
};

export function isFinanceCommandErrorCode(value: unknown): value is FinanceCommandErrorCode {
  return (
    value === "unauthorized" ||
    value === "forbidden" ||
    value === "conflict" ||
    value === "validation_error" ||
    value === "unavailable"
  );
}

export function createFinanceCommandError(
  code: FinanceCommandErrorCode,
  message: string,
  details?: Record<string, unknown>,
): FinanceCommandError {
  return {
    code,
    status: ERROR_STATUS_BY_CODE[code],
    message,
    retryable: ERROR_RETRYABLE_BY_CODE[code],
    details,
  };
}

export type FinanceCommandRequestBase = {
  commandId: string;
  correlationId: string;
  reason: string;
  submittedAt: string;
};

export type ApproveTopUpExpectedState = {
  status: "pending";
  decision_state: "unreviewed";
};

export type RejectTopUpExpectedState = {
  status: "pending";
  decision_state: "unreviewed";
};

export type ReverseWalletEntryExpectedState = {
  entry_status: "posted";
  reversal_state: "not_reversed";
  entry_type: "debit";
};

export type ApproveReversalExpectedState = {
  approval_state: "pending_second_approval";
  request_not_expired: true;
};

export type VerifyWalletReadinessExpectedState = {
  readiness_scope?: "global" | "finance_ops";
};

export type ApproveTopUpCommandRequest = FinanceCommandRequestBase & {
  action: "approve_topup";
  requestId: string;
  venueId: string;
  adminNote?: string;
  expectedState: ApproveTopUpExpectedState;
};

export type RejectTopUpCommandRequest = FinanceCommandRequestBase & {
  action: "reject_topup";
  requestId: string;
  venueId: string;
  adminNote?: string;
  expectedState: RejectTopUpExpectedState;
};

export type ReverseWalletEntryCommandRequest = FinanceCommandRequestBase & {
  action: "reverse_wallet_entry";
  entryId: string;
  venueId: string;
  adminNote?: string;
  expectedState: ReverseWalletEntryExpectedState;
};

export type ApproveReversalCommandRequest = FinanceCommandRequestBase & {
  action: "approve_reversal";
  reversalRequestId: string;
  expectedState: ApproveReversalExpectedState;
};

export type VerifyWalletReadinessCommandRequest = FinanceCommandRequestBase & {
  action: "verify_wallet_readiness";
  expectedState?: VerifyWalletReadinessExpectedState;
};

export type ApproveTopUpCommandResponse = {
  action: "approve_topup";
  requestId: string;
  venueId: string;
  status: "credited";
  linkedEntryId?: string;
  reviewedAt?: string;
};

export type RejectTopUpCommandResponse = {
  action: "reject_topup";
  requestId: string;
  venueId: string;
  status: "rejected";
  reviewedAt?: string;
};

export type ReverseWalletEntryCommandResponse = {
  action: "reverse_wallet_entry";
  originalEntryId: string;
  venueId: string;
  status: "reversed" | "pending_second_approval";
  reversalEntryId?: string;
  reversalRequestId?: string;
  requiredSecondApproverRole?: "finance_admin" | "super_admin";
  approvalExpiresAt?: string;
  reversedAt?: string;
};

export type ApproveReversalCommandResponse = {
  action: "approve_reversal";
  reversalRequestId: string;
  status: "approved_and_executed";
  executedReversalEntryId: string;
  approvedAt: string;
};

export type VerifyWalletReadinessCommandResponse = {
  action: "verify_wallet_readiness";
  status: "PASS" | "WARN" | "FAIL";
  warningChecks: string[];
  failureChecks: string[];
  checkedAt: string;
};

export type FinanceCommandRequestMap = {
  approve_topup: ApproveTopUpCommandRequest;
  reject_topup: RejectTopUpCommandRequest;
  reverse_wallet_entry: ReverseWalletEntryCommandRequest;
  approve_reversal: ApproveReversalCommandRequest;
  verify_wallet_readiness: VerifyWalletReadinessCommandRequest;
};

export type FinanceCommandResponseMap = {
  approve_topup: ApproveTopUpCommandResponse;
  reject_topup: RejectTopUpCommandResponse;
  reverse_wallet_entry: ReverseWalletEntryCommandResponse;
  approve_reversal: ApproveReversalCommandResponse;
  verify_wallet_readiness: VerifyWalletReadinessCommandResponse;
};

export type FinanceCommandRequest = FinanceCommandRequestMap[FinanceCommandType];
export type FinanceCommandResponse = FinanceCommandResponseMap[FinanceCommandType];

export type FinanceCommandSuccess<T extends FinanceCommandType> = {
  ok: true;
  command: T;
  commandId: string;
  correlationId: string;
  data: FinanceCommandResponseMap[T];
};

export type FinanceCommandFailure<T extends FinanceCommandType> = {
  ok: false;
  command: T;
  commandId: string;
  correlationId: string;
  error: FinanceCommandError;
};

export type FinanceCommandResult<T extends FinanceCommandType> =
  | FinanceCommandSuccess<T>
  | FinanceCommandFailure<T>;

export type CommandIdempotencyExpectation = {
  required: true;
  keyField: "commandId";
  replayRule:
    | "same_command_same_payload_returns_original"
    | "same_command_different_payload_rejected";
};

export type CommandExpectedStateExpectation = {
  required: boolean;
  requiredFields: readonly string[];
};

export type FinanceCommandMetadata = {
  requiredCapability: AdminCapabilityKey;
  allowedRoles: readonly AdminRole[];
  idempotency: CommandIdempotencyExpectation;
  expectedState: CommandExpectedStateExpectation;
};

const FINANCE_MUTATION_ROLES: readonly AdminRole[] = ["super_admin", "finance_admin"];

const READINESS_VIEW_ROLES: readonly AdminRole[] = [
  "super_admin",
  "finance_admin",
  "content_admin",
  "support_admin",
  "ops_viewer",
];

const SHARED_IDEMPOTENCY: CommandIdempotencyExpectation = {
  required: true,
  keyField: "commandId",
  replayRule: "same_command_same_payload_returns_original",
};

export const FINANCE_COMMAND_METADATA: Record<
  FinanceCommandType,
  FinanceCommandMetadata
> = {
  approve_topup: {
    requiredCapability: "approve_topup",
    allowedRoles: FINANCE_MUTATION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["status", "decision_state"],
    },
  },
  reject_topup: {
    requiredCapability: "reject_topup",
    allowedRoles: FINANCE_MUTATION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["status", "decision_state"],
    },
  },
  reverse_wallet_entry: {
    requiredCapability: "create_reversal",
    allowedRoles: FINANCE_MUTATION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["entry_status", "reversal_state", "entry_type"],
    },
  },
  approve_reversal: {
    requiredCapability: "approve_reversal",
    allowedRoles: FINANCE_MUTATION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["approval_state", "request_not_expired"],
    },
  },
  verify_wallet_readiness: {
    requiredCapability: "view_readiness",
    allowedRoles: READINESS_VIEW_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: false,
      requiredFields: [],
    },
  },
};
