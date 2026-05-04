export type OpsWidgetState = "success" | "stale" | "empty" | "unavailable";

export type OpsWidgetData<T> = {
  state: OpsWidgetState;
  asOf: string;
  source: string;
  message?: string;
  data: T | null;
};

// -- Specific Widget Data Types --

export type TopUpQueueSummary = {
  pendingCount: number;
  recentPending: Array<{ id: string; userName: string; amount: number; currency: string; createdAt: string }>;
};

export type WalletReadinessSummary = {
  overallStatus: "ready" | "warning" | "blocked" | "unknown";
  failingChecksCount: number;
  warningChecksCount: number;
  failingChecksPreview: Array<{ id: string; name: string; message: string }>;
};

export type VenueDirectorySummary = {
  totalVenues: number;
  readyVenues: number;
  lowBalanceVenues: number;
  inactiveWallets: number;
  lowBalancePreview: Array<{ id: string; name: string }>;
};

export type ContentModerationBacklogSummary = {
  pendingOffers: number;
  pendingStories: number;
  recentOffersPreview: Array<{ id: string; title: string; venueId: string; createdAt: string }>;
};

// -- Aggregated Dashboard Model --

export type OpsDashboardSummary = {
  generatedAt: string;
  topUpQueue: OpsWidgetData<TopUpQueueSummary>;
  walletReadiness: OpsWidgetData<WalletReadinessSummary>;
  venueDirectory: OpsWidgetData<VenueDirectorySummary>;
  contentModeration: OpsWidgetData<ContentModerationBacklogSummary>;
};
