import type {
  ApproveReversalCommandRequest,
  ApproveTopUpCommandRequest,
  FinanceCommandType,
  RejectTopUpCommandRequest,
  ReverseWalletEntryCommandRequest,
  VerifyWalletReadinessCommandRequest,
} from "./command-contracts";
import type { TopUpRequest, WalletLedgerEntry } from "./read-models";

export const DEFAULT_FINANCE_VENUE_ID = "venue_wain_default";

function newIds() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return { commandId: crypto.randomUUID(), correlationId: crypto.randomUUID() };
  }
  const fallback = `cmd_${Date.now()}_${Math.random().toString(16).slice(2)}`;
  return { commandId: fallback, correlationId: `${fallback}_corr` };
}

export function buildApproveTopUpRequest(
  request: TopUpRequest,
  overrides?: Partial<Pick<ApproveTopUpCommandRequest, "reason" | "adminNote">>,
): ApproveTopUpCommandRequest {
  const { commandId, correlationId } = newIds();
  const submittedAt = new Date().toISOString();
  return {
    action: "approve_topup",
    commandId,
    correlationId,
    reason: overrides?.reason ?? "Top-up approval from admin queue",
    submittedAt,
    requestId: request.id,
    venueId: resolveVenueId(request.venueId),
    adminNote: overrides?.adminNote,
    expectedState: {
      status: "pending",
      decision_state: "unreviewed",
    },
  };
}

export function buildRejectTopUpRequest(
  request: TopUpRequest,
  overrides?: Partial<Pick<RejectTopUpCommandRequest, "reason" | "adminNote">>,
): RejectTopUpCommandRequest {
  const { commandId, correlationId } = newIds();
  const submittedAt = new Date().toISOString();
  return {
    action: "reject_topup",
    commandId,
    correlationId,
    reason: overrides?.reason ?? "Top-up rejection from admin queue",
    submittedAt,
    requestId: request.id,
    venueId: resolveVenueId(request.venueId),
    adminNote: overrides?.adminNote,
    expectedState: {
      status: "pending",
      decision_state: "unreviewed",
    },
  };
}

export function buildReverseWalletEntryRequest(
  entry: WalletLedgerEntry,
  overrides?: Partial<Pick<ReverseWalletEntryCommandRequest, "reason" | "adminNote">>,
): ReverseWalletEntryCommandRequest {
  const { commandId, correlationId } = newIds();
  const submittedAt = new Date().toISOString();
  return {
    action: "reverse_wallet_entry",
    commandId,
    correlationId,
    reason: overrides?.reason ?? "Wallet debit reversal from audit",
    submittedAt,
    entryId: entry.id,
    venueId: resolveVenueId(entry.venueId),
    adminNote: overrides?.adminNote,
    expectedState: {
      entry_status: "posted",
      reversal_state: "not_reversed",
      entry_type: "debit",
    },
  };
}

export function buildVerifyWalletReadinessRequest(
  overrides?: Partial<
    Pick<VerifyWalletReadinessCommandRequest, "reason" | "expectedState">
  >,
): VerifyWalletReadinessCommandRequest {
  const { commandId, correlationId } = newIds();
  const submittedAt = new Date().toISOString();
  return {
    action: "verify_wallet_readiness",
    commandId,
    correlationId,
    reason: overrides?.reason ?? "Manual readiness verification from admin console",
    submittedAt,
    expectedState: overrides?.expectedState ?? { readiness_scope: "finance_ops" },
  };
}

export function buildApproveReversalRequest(
  reversalRequestId: string,
  overrides?: Partial<Pick<ApproveReversalCommandRequest, "reason" | "expectedState">>,
): ApproveReversalCommandRequest {
  const { commandId, correlationId } = newIds();
  const submittedAt = new Date().toISOString();

  return {
    action: "approve_reversal",
    commandId,
    correlationId,
    reason: overrides?.reason ?? "Second approval for wallet reversal request",
    submittedAt,
    reversalRequestId,
    expectedState:
      overrides?.expectedState ??
      ({
        approval_state: "pending_second_approval",
        request_not_expired: true,
      } as const),
  };
}

export function commandKey(
  command: FinanceCommandType,
  resourceId: string,
): string {
  return `${resourceId}:${command}`;
}

function resolveVenueId(value: string | undefined): string {
  const venueId = value?.trim();
  return venueId && venueId.length > 0 ? venueId : DEFAULT_FINANCE_VENUE_ID;
}
