export type VenueDirectoryReadinessStatus = "ready" | "warning" | "fail" | "unknown";

export type VenueDirectoryWalletStatus =
  | "active"
  | "low_balance"
  | "inactive"
  | "unknown";

export type VenueDirectoryMerchantLinkStatus = "linked" | "unlinked" | "unknown";
export type VenueDirectorySubscriptionStatus = "active" | "expired" | "paused";
export type VenueDirectoryVisibilityStatus = "visible" | "hidden";
export type VenueDirectoryOperationalStatus = "active" | "suspended" | "archived";

export type VenueDirectoryItem = {
  venueId: string;
  venueName: string;
  venueNameEn: string | null;
  city: string | null;
  lat?: number | null;
  lng?: number | null;
  categories: string[];
  phone: string | null;
  readinessStatus: VenueDirectoryReadinessStatus;
  readinessSummary: string;
  walletStatus: VenueDirectoryWalletStatus;
  walletSummary: string;
  walletBalance: number | null;
  walletCurrency: "ILS" | "USD";
  merchantLinkStatus: VenueDirectoryMerchantLinkStatus;
  merchantLinkSummary: string;
  merchantLinkedCount: number | null;
  subscriptionStatus: VenueDirectorySubscriptionStatus;
  visibilityStatus: VenueDirectoryVisibilityStatus;
  operationalStatus: VenueDirectoryOperationalStatus;
  workspacePath: string;
};

export type VenueDirectorySummary = {
  totalVenues: number;
  readiness: Record<VenueDirectoryReadinessStatus, number>;
  wallet: Record<VenueDirectoryWalletStatus, number>;
  merchantLinks: Record<VenueDirectoryMerchantLinkStatus, number>;
  subscriptions: Record<VenueDirectorySubscriptionStatus, number>;
  visibility: Record<VenueDirectoryVisibilityStatus, number>;
  operational: Record<VenueDirectoryOperationalStatus, number>;
};

export type VenueDirectoryFilterOptions = {
  cities: string[];
  categories: string[];
};

export type VenueDirectoryReadBudget = {
  sourceMode: "admin_list_callable" | "bounded_callable" | "snapshot";
  boundsScanned: number;
  perBoundLimit: number | null;
  maxPagesPerBound: number | null;
  maxResultsBudget: number | null;
  truncatedBounds: string[];
  partialResults: boolean;
};

export type VenueDirectoryReadData = {
  items: VenueDirectoryItem[];
  summary: VenueDirectorySummary;
  filters: VenueDirectoryFilterOptions;
  readBudget: VenueDirectoryReadBudget;
};

export type VenueDirectoryFilterInput = {
  searchTerm?: string;
  city?: string;
  category?: string;
};
