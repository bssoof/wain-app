export type VenueWorkspaceTabKey = "wallet" | "offers" | "stories" | "reviews";

export type VenueWorkspaceContext = {
  venueId: string;
  venueName: string;
  walletBalance: number;
  walletCurrency: "ILS" | "USD";
  readinessStatus: "ready" | "warning" | "fail";
  readinessSummary: string;
};

export type VenueWalletEntry = {
  id: string;
  type: "credit" | "debit" | "reversal";
  amount: number;
  currency: "ILS" | "USD";
  description: string;
  createdAt: string;
};

export type VenueOfferItem = {
  id: string;
  title: string;
  status: "active" | "paused" | "expired";
  startsAt: string;
  endsAt: string;
};

export type VenueStoryItem = {
  id: string;
  caption: string;
  status: "published" | "expired" | "draft";
  expiresAt: string;
};

export type VenueReviewItem = {
  id: string;
  authorName: string;
  rating: number;
  status: "published" | "flagged" | "hidden";
  snippet: string;
  createdAt: string;
};

export type VenueWorkspaceSnapshot = {
  asOf: string;
  context: VenueWorkspaceContext;
  walletEntries: VenueWalletEntry[];
  offers: VenueOfferItem[];
  stories: VenueStoryItem[];
  reviews: VenueReviewItem[];
};
