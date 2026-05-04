export type ContentAdminState = "pending" | "approved" | "rejected" | "flagged" | "paused";

export type ContentModerationReason =
  | "policy_violation"
  | "inappropriate_content"
  | "merchant_request"
  | "quality_standard"
  | "other";

export const CONTENT_MODERATION_REASONS: Record<ContentModerationReason, string> = {
  policy_violation: "انتهاك السياسة",
  inappropriate_content: "محتوى غير لائق",
  merchant_request: "طلب التاجر",
  quality_standard: "معايير الجودة",
  other: "أخرى",
};

export const CONTENT_MODERATION_REASON_KEYS = Object.keys(
  CONTENT_MODERATION_REASONS,
) as ContentModerationReason[];

export function isContentModerationReason(
  value: unknown,
): value is ContentModerationReason {
  return (
    typeof value === "string" &&
    CONTENT_MODERATION_REASON_KEYS.includes(value as ContentModerationReason)
  );
}

export const CONTENT_ADMIN_STATES: Record<ContentAdminState, string> = {
  pending: "قيد المراجعة",
  approved: "معتمد",
  rejected: "مرفوض",
  flagged: "مبلّغ عنه",
  paused: "موقوف",
};

export const CONTENT_ADMIN_STATE_CLASS_MAP: Record<ContentAdminState, string> = {
  pending: "status-warning",
  approved: "status-success",
  rejected: "status-danger",
  flagged: "status-danger",
  paused: "status-neutral",
};

export interface ModeratedContentBase {
  id: string;
  venueId: string;
  adminState: ContentAdminState;
  isActive: boolean;
  moderationReason?: ContentModerationReason | string;
  moderationNote?: string;
  moderatedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface OfferAdminSummary extends ModeratedContentBase {
  title: string;
  description?: string;
  isFeatured: boolean;
  featuredUntil?: string;
  startAt?: string;
  endAt?: string;
}

export interface StoryAdminSummary extends ModeratedContentBase {
  caption: string;
  isPromoted: boolean;
  promotedUntil?: string;
  expiresAt?: string;
  mediaUrl?: string;
}

// -- Per-item types for governed moderation surfaces --

export type ContentModerationReadState =
  | "success"
  | "empty"
  | "stale"
  | "unavailable";

export type OfferAdminItem = OfferAdminSummary & {
  venueName?: string;
};

export type StoryAdminItem = StoryAdminSummary & {
  venueName?: string;
};

export type OfferModerationSnapshot = {
  generatedAt: string;
  source: string;
  freshnessNote: string;
  state: ContentModerationReadState;
  message?: string;
  filtersApplied: {
    venueId: string | null;
    statuses: ContentAdminState[];
    limit: number;
  };
  items: OfferAdminItem[];
};

export type StoryModerationSnapshot = {
  generatedAt: string;
  source: string;
  freshnessNote: string;
  state: ContentModerationReadState;
  message?: string;
  filtersApplied: {
    venueId: string | null;
    statuses: ContentAdminState[];
    limit: number;
  };
  items: StoryAdminItem[];
};

// -- Protected derived fields --
// These are server-authorized ONLY and must NEVER be written from browser commands.
// Offer: isFeatured, featuredUntil    → controlled by wallet debit callable
// Story: isPromoted, promotedUntil    → controlled by wallet debit callable

export const OFFER_PROTECTED_DERIVED_FIELDS = [
  "isFeatured",
  "featuredUntil",
  "is_featured",
  "featured_until",
] as const;

export const STORY_PROTECTED_DERIVED_FIELDS = [
  "isPromoted",
  "promotedUntil",
  "is_promoted",
  "promoted_until",
] as const;

export const ALL_PROTECTED_DERIVED_FIELDS = [
  ...OFFER_PROTECTED_DERIVED_FIELDS,
  ...STORY_PROTECTED_DERIVED_FIELDS,
] as const;
