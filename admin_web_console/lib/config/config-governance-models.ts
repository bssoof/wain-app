export type ConfigReadState = "success" | "stale" | "empty" | "unavailable";

export type ConfigDraftStatus = "none" | "drafted" | "reviewed" | "published";

export type ConfigPricing = {
  story_promote_1d: number;
  story_promote_3d: number;
  story_promote_7d: number;
  offer_pin_1d: number;
  offer_pin_3d: number;
  offer_pin_7d: number;
  currency: string;
};

export type ConfigValidationIssue = {
  code: string;
  field: string;
  message: string;
};

export type ConfigGovernanceLiveSnapshot = {
  exists: boolean;
  version: number;
  pricing: ConfigPricing | null;
  updatedAt: string | null;
  updatedByUid: string | null;
  updatedByRole: string | null;
};

export type ConfigGovernanceDraftSnapshot = {
  exists: boolean;
  status: ConfigDraftStatus;
  draftVersion: number;
  pricing: ConfigPricing | null;
  validationIssues: ConfigValidationIssue[];
  reviewedByUid: string | null;
  reviewedAt: string | null;
  updatedAt: string | null;
};

export type ConfigPublishHistoryItem = {
  id: string;
  eventType: string;
  liveVersion: number;
  previousLiveVersion: number;
  rollbackToVersion: number | null;
  sourceHistoryId: string | null;
  commandId: string | null;
  correlationId: string | null;
  reason: string | null;
  note: string | null;
  publishedByUid: string | null;
  publishedByRole: string | null;
  reviewedByUid: string | null;
  publishedAt: string;
};

export type ConfigGovernanceSnapshot = {
  generatedAt: string;
  source: string;
  scope: string;
  state: ConfigReadState;
  freshnessNote: string;
  message?: string;
  live: ConfigGovernanceLiveSnapshot;
  draft: ConfigGovernanceDraftSnapshot;
  history: ConfigPublishHistoryItem[];
};

export const DEFAULT_CONFIG_PRICING: ConfigPricing = {
  story_promote_1d: 3,
  story_promote_3d: 7,
  story_promote_7d: 14,
  offer_pin_1d: 4,
  offer_pin_3d: 9,
  offer_pin_7d: 16,
  currency: "ILS",
};
