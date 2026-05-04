export const REVIEW_MODERATION_REASONS = [
  "spam",
  "abusive_language",
  "off_topic",
  "privacy_request",
  "legal_request",
  "duplicate",
  "manual_review",
  "appeal_approved",
  "other",
] as const;

export type ReviewModerationReason = (typeof REVIEW_MODERATION_REASONS)[number];

export type ReviewModerationStatus = "published" | "flagged" | "hidden";

export type ReviewModerationReadState =
  | "success"
  | "empty"
  | "stale"
  | "unavailable";

export type ReviewModerationAction = "review_publish" | "review_hide" | "review_escalate";

export type ReviewModerationItem = {
  id: string;
  venueId: string;
  venueName: string;
  authorName: string;
  rating: number;
  status: ReviewModerationStatus;
  snippet: string;
  createdAt: string;
  moderationReason: string | null;
  moderationNote: string | null;
  moderatedAt: string | null;
  moderatedByUid: string | null;
};

export type ReviewModerationSnapshot = {
  generatedAt: string;
  source: string;
  freshnessNote: string;
  state: ReviewModerationReadState;
  message?: string;
  filtersApplied: {
    venueId: string | null;
    statuses: ReviewModerationStatus[];
    limit: number;
  };
  items: ReviewModerationItem[];
};
