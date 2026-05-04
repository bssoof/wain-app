// Finance read models for Admin Web Console - Phase 2

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
