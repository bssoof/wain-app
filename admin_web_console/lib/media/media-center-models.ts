export const MEDIA_SECTION_KEYS = [
  "proofs",
  "venue_photos",
  "offer_images",
  "story_images",
] as const;

export type MediaSectionKey = (typeof MEDIA_SECTION_KEYS)[number];

export type MediaReadState = "success" | "empty" | "stale" | "unavailable";
export type MediaReferenceSafety = "safe" | "unsafe" | "unknown";
export type MediaReferenceIndexHealth =
  | "healthy"
  | "stale"
  | "failed"
  | "unavailable";

export type MediaCenterItem = {
  id: string;
  title: string;
  venueName?: string;
  uploadedAt: string;
  sourceDocument: string;
  referenceType: string;
  referenceId: string;
  sourceLabel: string;
  referenceSafety: MediaReferenceSafety;
  referenceIndexHealth: MediaReferenceIndexHealth;
  purgeBlocked: boolean;
  mediaUrl?: string;
  previewNote: string;
};

export type MediaCenterSection = {
  key: MediaSectionKey;
  title: string;
  scopeNote: string;
  state: MediaReadState;
  source: string;
  freshnessNote: string;
  referenceSafetyNote: string;
  referenceIndexHealth: MediaReferenceIndexHealth;
  purgeBlocked: boolean;
  items: MediaCenterItem[];
  message?: string;
};

export type MediaCenterBaseline = {
  generatedAt: string;
  sections: MediaCenterSection[];
};
