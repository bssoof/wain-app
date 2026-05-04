export const ADMIN_ROLES = [
  "super_admin",
  "finance_admin",
  "content_admin",
  "support_admin",
  "ops_viewer",
] as const;

export type AdminRole = (typeof ADMIN_ROLES)[number];

export const ADMIN_ROUTE_KEYS = [
  "dashboard",
  "topups",
  "wallet_audit",
  "reversals",
  "venues",
  "media",
  "content_offers",
  "content_stories",
  "reviews_moderation",
  "config",
  "readiness",
] as const;

export type AdminRouteKey = (typeof ADMIN_ROUTE_KEYS)[number];

export function isAdminRouteKey(value: unknown): value is AdminRouteKey {
  return (
    typeof value === "string" &&
    ADMIN_ROUTE_KEYS.includes(value as AdminRouteKey)
  );
}

export const ADMIN_ROUTE_PREFETCH_MODES = [
  "auto",
  "hover-intent",
  "disabled",
] as const;

export type AdminRoutePrefetchMode =
  (typeof ADMIN_ROUTE_PREFETCH_MODES)[number];

export const PHASE1_BUSINESS_CAPABILITY_KEYS = [
  "view_dashboard",
  "view_topups",
  "approve_topup",
  "reject_topup",
  "view_wallet_audit",
  "create_reversal",
  "approve_reversal",
  "view_venues",
  "view_readiness",
] as const;

export type Phase1BusinessCapabilityKey =
  (typeof PHASE1_BUSINESS_CAPABILITY_KEYS)[number];

export const PHASE4_MEDIA_CAPABILITY_KEYS = [
  "view_media",
  "media_soft_delete",
  "media_quarantine",
  "media_reference_check",
  "media_purge",
] as const;

export type Phase4MediaCapabilityKey =
  (typeof PHASE4_MEDIA_CAPABILITY_KEYS)[number];

export const PHASE5_CONTENT_CAPABILITY_KEYS = [
  "view_reviews_moderation",
  "review_publish",
  "review_hide",
  "review_escalate",
] as const;

export type Phase5ContentCapabilityKey =
  (typeof PHASE5_CONTENT_CAPABILITY_KEYS)[number];

export const PHASE5_OFFER_STORY_CAPABILITY_KEYS = [
  "offer_approve",
  "offer_reject",
  "offer_flag",
  "offer_pause",
  "story_approve",
  "story_reject",
  "story_flag",
  "story_pause",
] as const;

export type Phase5OfferStoryCapabilityKey =
  (typeof PHASE5_OFFER_STORY_CAPABILITY_KEYS)[number];

export const PHASE6_CONFIG_CAPABILITY_KEYS = [
  "view_config_governance",
  "config_draft_write",
  "config_review",
  "publish_config",
  "rollback_config",
] as const;

export type Phase6ConfigCapabilityKey =
  (typeof PHASE6_CONFIG_CAPABILITY_KEYS)[number];

export const VENUE_MANAGEMENT_CAPABILITY_KEYS = [
  "create_venue",
  "edit_venue_profile",
  "change_venue_visibility",
  "change_venue_operational_status",
  "change_venue_subscription_status",
] as const;

export type VenueManagementCapabilityKey =
  (typeof VENUE_MANAGEMENT_CAPABILITY_KEYS)[number];

export const ADMIN_CAPABILITY_KEYS = [
  ...PHASE1_BUSINESS_CAPABILITY_KEYS,
  ...PHASE4_MEDIA_CAPABILITY_KEYS,
  ...PHASE5_CONTENT_CAPABILITY_KEYS,
  ...PHASE5_OFFER_STORY_CAPABILITY_KEYS,
  ...PHASE6_CONFIG_CAPABILITY_KEYS,
  ...VENUE_MANAGEMENT_CAPABILITY_KEYS,
  "shell.sign_out",
] as const;

export type AdminCapabilityKey = (typeof ADMIN_CAPABILITY_KEYS)[number];

export function isAdminRole(value: unknown): value is AdminRole {
  return typeof value === "string" && ADMIN_ROLES.includes(value as AdminRole);
}
