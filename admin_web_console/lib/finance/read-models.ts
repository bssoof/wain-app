// Finance read models for Admin Web Console - Phase 2
import type { Firestore, Timestamp } from "firebase-admin/firestore";

export type TopUpRequestStatus = "pending" | "credited" | "rejected";

export interface TopUpRequest {
  id: string;
  venueId?: string;
  userId: string;
  userName: string;
  amount: number;
  currency: "ILS" | "USD";
  providerReference: string;
  createdAt: string;
  status: TopUpRequestStatus;
  proofImageUrl?: string;
  proofRetentionUntil?: string;
  proofStorageDeleted?: boolean;
  reviewedBy?: string;
  reviewedAt?: string;
}

export type WalletLedgerEntryType = "credit" | "debit" | "reversal";

export interface WalletLedgerEntry {
  id: string;
  venueId?: string;
  userId: string;
  userName: string;
  type: WalletLedgerEntryType;
  amount: number;
  currency: "ILS" | "USD";
  description: string;
  reference: string;
  createdAt: string;
}

export type ReadinessOverallStatus = "ready" | "warning" | "blocked";
export type ReadinessCheckStatus = "pass" | "warn" | "fail";

export interface ReadinessCheck {
  id: string;
  label: string;
  status: ReadinessCheckStatus;
  details: string;
}

export interface WalletReadinessReport {
  generatedAt: string;
  overallStatus: ReadinessOverallStatus;
  summary: string;
  checks: ReadinessCheck[];
}

export type MerchantReversalRequestStatus =
  | "pending_review"
  | "pending_second_approval"
  | "approved_and_executed"
  | "rejected"
  | "expired";

export type MerchantReversalAdminDecision = "approved" | "rejected";

export interface MerchantReversalRequest {
  requestId: string;
  source: "merchant";
  status: MerchantReversalRequestStatus;
  venueId: string;
  entryId: string;
  originalAmount: number;
  currency: string;
  originalFeatureKey: string;
  requestedByUid: string;
  reason: string;
  merchantNote: string | null;
  reviewedByUid: string | null;
  reviewedByRole: string | null;
  reviewedAt: Timestamp | null;
  adminDecision: MerchantReversalAdminDecision | null;
  adminNote: string | null;
  rejectionReason: string | null;
  requiredSecondApproverRole: string | null;
  reversalEntryId: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  expiresAt: Timestamp | null;
}

export const FINANCE_READ_SOURCES = [
  "topup_queue",
  "wallet_audit",
  "wallet_readiness",
] as const;

export type FinanceReadSource = (typeof FINANCE_READ_SOURCES)[number];

export type FinanceReadState =
  | "success"
  | "empty"
  | "stale"
  | "unavailable"
  | "unauthorized"
  | "forbidden";

export type FinanceReadFailureState = Extract<
  FinanceReadState,
  "unavailable" | "unauthorized" | "forbidden"
>;

export type FinanceReadQueryBase = {
  correlationId?: string;
  maxAgeMs?: number;
};

export type TopUpQueueReadQuery = FinanceReadQueryBase & {
  venueId?: string;
  limit?: number;
  statuses?: TopUpRequestStatus[];
  /** Inclusive ISO 8601 lower bound on `created_at` (server contract). */
  createdAfter?: string;
  /** Inclusive ISO 8601 upper bound on `created_at` (server contract). */
  createdBefore?: string;
};

export type WalletAuditReadQuery = FinanceReadQueryBase & {
  venueId?: string;
  limit?: number;
  entryTypes?: WalletLedgerEntryType[];
  /** Inclusive ISO 8601 lower bound on `created_at` (server contract). */
  createdAfter?: string;
  /** Inclusive ISO 8601 upper bound on `created_at` (server contract). */
  createdBefore?: string;
};

export type WalletReadinessReadQuery = FinanceReadQueryBase & {
  reason?: string;
};

export type FinanceReadFreshness = {
  source: FinanceReadSource;
  checkedAt: string;
  fetchedAt: string;
  ageMs: number;
  staleAfterMs: number;
  /** Operator-visible transport channel (HTTP URL, inline JSON, fixture, …) */
  channel?: string;
};

export type FinanceReadSuccessState = Extract<FinanceReadState, "success" | "stale">;

export type FinanceReadSuccess<TData> = {
  ok: true;
  state: FinanceReadSuccessState;
  data: TData;
  freshness: FinanceReadFreshness;
};

export type FinanceReadEmpty = {
  ok: true;
  state: "empty";
  data: null;
  freshness: FinanceReadFreshness;
};

export type FinanceReadFailure = {
  ok: false;
  state: FinanceReadFailureState;
  source: FinanceReadSource;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

export type FinanceReadResult<TData> =
  | FinanceReadSuccess<TData>
  | FinanceReadEmpty
  | FinanceReadFailure;

export type TopUpQueueReadResult = FinanceReadResult<TopUpRequest[]>;
export type WalletAuditReadResult = FinanceReadResult<WalletLedgerEntry[]>;
export type WalletReadinessReadResult = FinanceReadResult<WalletReadinessReport>;

export async function listPendingMerchantReversalRequests(
  db: Firestore,
): Promise<MerchantReversalRequest[]> {
  const snap = await db
    .collection("wallet_reversal_requests")
    .where("source", "==", "merchant")
    .where("status", "==", "pending_review")
    .orderBy("created_at", "desc")
    .get();

  return snap.docs.map(toMerchantReversalRequest);
}

export function toMerchantReversalRequest(doc: {
  id: string;
  data(): Record<string, unknown>;
}): MerchantReversalRequest {
  const data = doc.data();

  return {
    requestId: stringField(data, "request_id") ?? doc.id,
    source: "merchant",
    status: merchantReversalStatusField(data, "status"),
    venueId: requiredStringField(data, "venue_id", doc.id),
    entryId: requiredStringField(data, "entry_id", doc.id),
    originalAmount: numberField(data, "original_amount") ?? 0,
    currency: stringField(data, "currency") ?? "ILS",
    originalFeatureKey: stringField(data, "original_feature_key") ?? "",
    requestedByUid: requiredStringField(data, "requested_by_uid", doc.id),
    reason: stringField(data, "reason") ?? "",
    merchantNote: stringField(data, "merchant_note"),
    reviewedByUid: stringField(data, "reviewed_by_uid"),
    reviewedByRole: stringField(data, "reviewed_by_role"),
    reviewedAt: timestampField(data, "reviewed_at"),
    adminDecision: adminDecisionField(data, "admin_decision"),
    adminNote: stringField(data, "admin_note"),
    rejectionReason: stringField(data, "rejection_reason"),
    requiredSecondApproverRole: stringField(data, "required_second_approver_role"),
    reversalEntryId: stringField(data, "reversal_entry_id"),
    createdAt: requiredTimestampField(data, "created_at", doc.id),
    updatedAt:
      timestampField(data, "updated_at") ??
      requiredTimestampField(data, "created_at", doc.id),
    expiresAt: timestampField(data, "expires_at"),
  };
}

function stringField(
  data: Record<string, unknown>,
  field: string,
): string | null {
  const value = data[field];
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function requiredStringField(
  data: Record<string, unknown>,
  field: string,
  docId: string,
): string {
  const value = stringField(data, field);
  if (!value) {
    throw new Error(`wallet_reversal_requests/${docId} is missing ${field}.`);
  }
  return value;
}

function numberField(
  data: Record<string, unknown>,
  field: string,
): number | null {
  const value = data[field];
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function timestampField(
  data: Record<string, unknown>,
  field: string,
): Timestamp | null {
  const value = data[field];
  if (!isTimestampLike(value)) {
    return null;
  }
  return value as Timestamp;
}

function requiredTimestampField(
  data: Record<string, unknown>,
  field: string,
  docId: string,
): Timestamp {
  const value = timestampField(data, field);
  if (!value) {
    throw new Error(`wallet_reversal_requests/${docId} is missing ${field}.`);
  }
  return value;
}

function isTimestampLike(value: unknown): boolean {
  if (!value || typeof value !== "object") {
    return false;
  }
  const candidate = value as { toDate?: unknown; toMillis?: unknown };
  return (
    typeof candidate.toDate === "function" &&
    typeof candidate.toMillis === "function"
  );
}

function merchantReversalStatusField(
  data: Record<string, unknown>,
  field: string,
): MerchantReversalRequestStatus {
  const value = stringField(data, field);
  if (
    value === "pending_review" ||
    value === "pending_second_approval" ||
    value === "approved_and_executed" ||
    value === "rejected" ||
    value === "expired"
  ) {
    return value;
  }

  return "pending_review";
}

function adminDecisionField(
  data: Record<string, unknown>,
  field: string,
): MerchantReversalAdminDecision | null {
  const value = stringField(data, field);
  if (value === "approved" || value === "rejected") {
    return value;
  }

  return null;
}

export const MOCK_TOPUP_REQUESTS: TopUpRequest[] = [
  {
    id: "topup_001",
    venueId: "venue_001",
    userId: "user_1001",
    userName: "Nour Abu Saleh",
    amount: 250,
    currency: "ILS",
    providerReference: "PSP-TRX-88102",
    createdAt: "2026-04-01T10:00:00.000Z",
    status: "pending",
  },
  {
    id: "topup_002",
    venueId: "venue_002",
    userId: "user_1002",
    userName: "Sami Darwish",
    amount: 500,
    currency: "ILS",
    providerReference: "PSP-TRX-88103",
    createdAt: "2026-04-01T10:30:00.000Z",
    status: "pending",
  },
  {
    id: "topup_003",
    venueId: "venue_003",
    userId: "user_1003",
    userName: "Lina Odeh",
    amount: 75,
    currency: "USD",
    providerReference: "PSP-TRX-88104",
    createdAt: "2026-04-01T09:10:00.000Z",
    status: "credited",
    reviewedBy: "finance-admin-1",
    reviewedAt: "2026-04-01T09:25:00.000Z",
  },
  {
    id: "topup_004",
    venueId: "venue_004",
    userId: "user_1004",
    userName: "Rania Khateeb",
    amount: 180,
    currency: "ILS",
    providerReference: "PSP-TRX-88105",
    createdAt: "2026-04-01T11:20:00.000Z",
    status: "pending",
  },
];

export const MOCK_WALLET_LEDGER_ENTRIES: WalletLedgerEntry[] = [
  {
    id: "ledger_001",
    venueId: "venue_001",
    userId: "user_1001",
    userName: "Nour Abu Saleh",
    type: "credit",
    amount: 250,
    currency: "ILS",
    description: "Top-up credit posted",
    reference: "topup_001",
    createdAt: "2026-04-01T10:02:00.000Z",
  },
  {
    id: "ledger_002",
    venueId: "venue_002",
    userId: "user_1002",
    userName: "Sami Darwish",
    type: "debit",
    amount: 120,
    currency: "ILS",
    description: "Order settlement",
    reference: "order_9011",
    createdAt: "2026-04-01T10:40:00.000Z",
  },
  {
    id: "ledger_003",
    venueId: "venue_004",
    userId: "user_1004",
    userName: "Rania Khateeb",
    type: "debit",
    amount: 60,
    currency: "ILS",
    description: "Wallet adjustment",
    reference: "adj_117",
    createdAt: "2026-04-01T11:30:00.000Z",
  },
  {
    id: "ledger_004",
    venueId: "venue_003",
    userId: "user_1003",
    userName: "Lina Odeh",
    type: "reversal",
    amount: 60,
    currency: "ILS",
    description: "Approved reversal entry",
    reference: "reversal_213",
    createdAt: "2026-04-01T11:45:00.000Z",
  },
  {
    id: "ledger_005",
    venueId: "venue_005",
    userId: "user_1005",
    userName: "Ameer Taha",
    type: "debit",
    amount: 330,
    currency: "ILS",
    description: "Large payout",
    reference: "payout_581",
    createdAt: "2026-04-01T12:05:00.000Z",
  },
];

export const MOCK_READINESS_REPORT: WalletReadinessReport = {
  generatedAt: "2026-04-01T12:30:00.000Z",
  overallStatus: "warning",
  summary: "Core wallet services are available, but one integration queue is delayed.",
  checks: [
    {
      id: "readiness_ledger_stream",
      label: "Ledger stream health",
      status: "pass",
      details: "Event ingestion is within target latency.",
    },
    {
      id: "readiness_reversal_workers",
      label: "Reversal workers",
      status: "warn",
      details: "Worker backlog is above warning threshold.",
    },
    {
      id: "readiness_settlement_export",
      label: "Settlement export",
      status: "pass",
      details: "Nightly settlement export completed successfully.",
    },
  ],
};
