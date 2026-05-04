import { describe, expect, it } from "vitest";

import type { AdminRole } from "../navigation/admin-contract";
import {
  ADMIN_CAPABILITY_KEYS,
  ADMIN_ROUTE_KEYS,
  PHASE4_MEDIA_CAPABILITY_KEYS,
  PHASE6_CONFIG_CAPABILITY_KEYS,
  PHASE5_CONTENT_CAPABILITY_KEYS,
  PHASE5_OFFER_STORY_CAPABILITY_KEYS,
  PHASE1_BUSINESS_CAPABILITY_KEYS,
} from "../navigation/admin-contract";
import {
  buildAdminSession,
  canAccessRoute,
  canRenderAction,
  resolveAdminRole,
  type AdminSession,
} from "./guard-api";

function createSession(primaryRole: AdminRole, roles: AdminRole[] = [primaryRole]): AdminSession {
  return {
    uid: "admin-uid",
    primaryRole,
    roles,
    roleSource: "claims",
  };
}

describe("guard-api RBAC foundation", () => {
  it("exports the agreed Phase 1 capability contract", () => {
    expect(PHASE1_BUSINESS_CAPABILITY_KEYS).toEqual([
      "view_dashboard",
      "view_topups",
      "approve_topup",
      "reject_topup",
      "view_wallet_audit",
      "create_reversal",
      "approve_reversal",
      "view_venues",
      "view_readiness",
    ]);
  });

  it("exports the Phase 4 media capability contract", () => {
    expect(PHASE4_MEDIA_CAPABILITY_KEYS).toEqual([
      "view_media",
      "media_soft_delete",
      "media_quarantine",
      "media_reference_check",
      "media_purge",
    ]);
  });

  it("exports the Phase 5 reviews moderation capability contract", () => {
    expect(PHASE5_CONTENT_CAPABILITY_KEYS).toEqual([
      "view_reviews_moderation",
      "review_publish",
      "review_hide",
      "review_escalate",
    ]);
  });

  it("exports the Phase 5 offers/stories moderation capability contract", () => {
    expect(PHASE5_OFFER_STORY_CAPABILITY_KEYS).toEqual([
      "offer_approve",
      "offer_reject",
      "offer_flag",
      "offer_pause",
      "story_approve",
      "story_reject",
      "story_flag",
      "story_pause",
    ]);
  });

  it("exports the Phase 6 config governance capability contract", () => {
    expect(PHASE6_CONFIG_CAPABILITY_KEYS).toEqual([
      "view_config_governance",
      "config_draft_write",
      "config_review",
      "publish_config",
      "rollback_config",
    ]);
  });

  it("denies non-admin sessions everywhere", () => {
    const nonAdminSession = {
      uid: "not-admin",
      primaryRole: "not_admin",
      roles: [],
      roleSource: "claims",
    } as unknown as AdminSession;

    for (const routeKey of ADMIN_ROUTE_KEYS) {
      expect(canAccessRoute(nonAdminSession, routeKey)).toBe(false);
    }

    for (const capabilityKey of ADMIN_CAPABILITY_KEYS) {
      expect(canRenderAction(nonAdminSession, capabilityKey)).toBe(false);
    }

    expect(
      buildAdminSession({
        uid: "explicit-deny-user",
        claims: { admin: false },
        fallback: { role: "finance_admin" },
      }),
    ).toBeNull();
  });

  it("grants finance_admin Phase 1 access", () => {
    const session = createSession("finance_admin");

    expect(canAccessRoute(session, "dashboard")).toBe(true);
    expect(canAccessRoute(session, "topups")).toBe(true);
    expect(canAccessRoute(session, "wallet_audit")).toBe(true);
    expect(canAccessRoute(session, "reversals")).toBe(true);
    expect(canAccessRoute(session, "venues")).toBe(true);
    expect(canAccessRoute(session, "media")).toBe(true);
    expect(canAccessRoute(session, "config")).toBe(true);
    expect(canAccessRoute(session, "reviews_moderation")).toBe(false);

    expect(canRenderAction(session, "view_dashboard")).toBe(true);
    expect(canRenderAction(session, "view_topups")).toBe(true);
    expect(canRenderAction(session, "approve_topup")).toBe(true);
    expect(canRenderAction(session, "reject_topup")).toBe(true);
    expect(canRenderAction(session, "view_wallet_audit")).toBe(true);
    expect(canRenderAction(session, "create_reversal")).toBe(true);
    expect(canRenderAction(session, "approve_reversal")).toBe(true);
    expect(canRenderAction(session, "view_venues")).toBe(true);
    expect(canRenderAction(session, "create_venue")).toBe(false);
    expect(canRenderAction(session, "edit_venue_profile")).toBe(false);
    expect(canRenderAction(session, "change_venue_visibility")).toBe(false);
    expect(canRenderAction(session, "change_venue_operational_status")).toBe(false);
    expect(canRenderAction(session, "change_venue_subscription_status")).toBe(false);
    expect(canRenderAction(session, "view_config_governance")).toBe(true);
    expect(canRenderAction(session, "config_draft_write")).toBe(true);
    expect(canRenderAction(session, "config_review")).toBe(true);
    expect(canRenderAction(session, "publish_config")).toBe(true);
    expect(canRenderAction(session, "rollback_config")).toBe(true);
    expect(canRenderAction(session, "view_readiness")).toBe(true);
  });

  it("keeps ops_viewer read-only", () => {
    const session = createSession("ops_viewer");

    expect(canAccessRoute(session, "dashboard")).toBe(true);
    expect(canAccessRoute(session, "topups")).toBe(true);
    expect(canAccessRoute(session, "wallet_audit")).toBe(true);
    expect(canAccessRoute(session, "venues")).toBe(true);
    expect(canAccessRoute(session, "reversals")).toBe(false);
    expect(canAccessRoute(session, "media")).toBe(true);
    expect(canAccessRoute(session, "config")).toBe(false);
    expect(canAccessRoute(session, "reviews_moderation")).toBe(false);

    expect(canRenderAction(session, "view_dashboard")).toBe(true);
    expect(canRenderAction(session, "view_topups")).toBe(true);
    expect(canRenderAction(session, "view_wallet_audit")).toBe(true);
    expect(canRenderAction(session, "view_venues")).toBe(true);
    expect(canRenderAction(session, "view_readiness")).toBe(true);
    expect(canRenderAction(session, "approve_topup")).toBe(false);
    expect(canRenderAction(session, "reject_topup")).toBe(false);
    expect(canRenderAction(session, "create_reversal")).toBe(false);
    expect(canRenderAction(session, "approve_reversal")).toBe(false);
    expect(canRenderAction(session, "create_venue")).toBe(false);
    expect(canRenderAction(session, "edit_venue_profile")).toBe(false);
    expect(canRenderAction(session, "change_venue_visibility")).toBe(false);
    expect(canRenderAction(session, "change_venue_operational_status")).toBe(false);
    expect(canRenderAction(session, "change_venue_subscription_status")).toBe(false);
    expect(canRenderAction(session, "view_media")).toBe(true);
    expect(canRenderAction(session, "media_soft_delete")).toBe(false);
    expect(canRenderAction(session, "media_quarantine")).toBe(false);
    expect(canRenderAction(session, "media_reference_check")).toBe(false);
    expect(canRenderAction(session, "media_purge")).toBe(false);
    expect(canRenderAction(session, "view_config_governance")).toBe(false);
    expect(canRenderAction(session, "config_draft_write")).toBe(false);
    expect(canRenderAction(session, "config_review")).toBe(false);
    expect(canRenderAction(session, "publish_config")).toBe(false);
    expect(canRenderAction(session, "rollback_config")).toBe(false);
    expect(canRenderAction(session, "view_reviews_moderation")).toBe(false);
    expect(canRenderAction(session, "review_publish")).toBe(false);
    expect(canRenderAction(session, "review_hide")).toBe(false);
    expect(canRenderAction(session, "review_escalate")).toBe(false);
    expect(canRenderAction(session, "shell.sign_out")).toBe(true);
  });

  it("prevents support_admin from finance mutation capabilities", () => {
    const session = createSession("support_admin");

    expect(canAccessRoute(session, "wallet_audit")).toBe(true);
    expect(canAccessRoute(session, "venues")).toBe(true);
    expect(canAccessRoute(session, "reversals")).toBe(false);
    expect(canAccessRoute(session, "media")).toBe(true);
    expect(canAccessRoute(session, "config")).toBe(false);
    expect(canAccessRoute(session, "reviews_moderation")).toBe(false);

    expect(canRenderAction(session, "view_dashboard")).toBe(true);
    expect(canRenderAction(session, "view_wallet_audit")).toBe(true);
    expect(canRenderAction(session, "view_venues")).toBe(true);
    expect(canRenderAction(session, "view_readiness")).toBe(true);
    expect(canRenderAction(session, "approve_topup")).toBe(false);
    expect(canRenderAction(session, "reject_topup")).toBe(false);
    expect(canRenderAction(session, "create_reversal")).toBe(false);
    expect(canRenderAction(session, "approve_reversal")).toBe(false);
    expect(canRenderAction(session, "create_venue")).toBe(false);
    expect(canRenderAction(session, "edit_venue_profile")).toBe(false);
    expect(canRenderAction(session, "change_venue_visibility")).toBe(false);
    expect(canRenderAction(session, "change_venue_operational_status")).toBe(false);
    expect(canRenderAction(session, "change_venue_subscription_status")).toBe(false);
    expect(canRenderAction(session, "view_media")).toBe(true);
    expect(canRenderAction(session, "media_soft_delete")).toBe(false);
    expect(canRenderAction(session, "media_quarantine")).toBe(false);
    expect(canRenderAction(session, "media_reference_check")).toBe(false);
    expect(canRenderAction(session, "media_purge")).toBe(false);
    expect(canRenderAction(session, "view_config_governance")).toBe(false);
    expect(canRenderAction(session, "config_draft_write")).toBe(false);
    expect(canRenderAction(session, "config_review")).toBe(false);
    expect(canRenderAction(session, "publish_config")).toBe(false);
    expect(canRenderAction(session, "rollback_config")).toBe(false);
    expect(canRenderAction(session, "view_reviews_moderation")).toBe(false);
    expect(canRenderAction(session, "review_publish")).toBe(false);
    expect(canRenderAction(session, "review_hide")).toBe(false);
    expect(canRenderAction(session, "review_escalate")).toBe(false);
  });

  it("grants content_admin the governed media action capabilities", () => {
    const session = createSession("content_admin");

    expect(canAccessRoute(session, "media")).toBe(true);
    expect(canAccessRoute(session, "venues")).toBe(true);
    expect(canAccessRoute(session, "content_offers")).toBe(true);
    expect(canAccessRoute(session, "content_stories")).toBe(true);
    expect(canAccessRoute(session, "config")).toBe(false);
    expect(canRenderAction(session, "view_venues")).toBe(true);
    expect(canRenderAction(session, "create_venue")).toBe(false);
    expect(canRenderAction(session, "edit_venue_profile")).toBe(true);
    expect(canRenderAction(session, "change_venue_visibility")).toBe(true);
    expect(canRenderAction(session, "change_venue_operational_status")).toBe(false);
    expect(canRenderAction(session, "change_venue_subscription_status")).toBe(false);
    expect(canRenderAction(session, "view_media")).toBe(true);
    expect(canRenderAction(session, "media_soft_delete")).toBe(true);
    expect(canRenderAction(session, "media_quarantine")).toBe(true);
    expect(canRenderAction(session, "media_reference_check")).toBe(true);
    expect(canRenderAction(session, "media_purge")).toBe(true);
    expect(canAccessRoute(session, "reviews_moderation")).toBe(true);
    expect(canRenderAction(session, "view_reviews_moderation")).toBe(true);
    expect(canRenderAction(session, "review_publish")).toBe(true);
    expect(canRenderAction(session, "review_hide")).toBe(true);
    expect(canRenderAction(session, "review_escalate")).toBe(true);
    expect(canRenderAction(session, "offer_approve")).toBe(true);
    expect(canRenderAction(session, "offer_reject")).toBe(true);
    expect(canRenderAction(session, "offer_flag")).toBe(true);
    expect(canRenderAction(session, "offer_pause")).toBe(true);
    expect(canRenderAction(session, "story_approve")).toBe(true);
    expect(canRenderAction(session, "story_reject")).toBe(true);
    expect(canRenderAction(session, "story_flag")).toBe(true);
    expect(canRenderAction(session, "story_pause")).toBe(true);
    expect(canRenderAction(session, "view_config_governance")).toBe(false);
    expect(canRenderAction(session, "config_draft_write")).toBe(false);
    expect(canRenderAction(session, "config_review")).toBe(false);
    expect(canRenderAction(session, "publish_config")).toBe(false);
    expect(canRenderAction(session, "rollback_config")).toBe(false);

    expect(canAccessRoute(session, "reversals")).toBe(false);
    expect(canRenderAction(session, "approve_topup")).toBe(false);
  });

  it("grants super_admin the full venue management capability set", () => {
    const session = createSession("super_admin");

    expect(canAccessRoute(session, "venues")).toBe(true);
    expect(canRenderAction(session, "view_venues")).toBe(true);
    expect(canRenderAction(session, "create_venue")).toBe(true);
    expect(canRenderAction(session, "edit_venue_profile")).toBe(true);
    expect(canRenderAction(session, "change_venue_visibility")).toBe(true);
    expect(canRenderAction(session, "change_venue_operational_status")).toBe(true);
    expect(canRenderAction(session, "change_venue_subscription_status")).toBe(true);
  });

  it("denies fallback-only contexts when claims are missing", () => {
    const resolvedRole = resolveAdminRole({
      claims: {},
      fallback: { role: "finance_admin" },
    });

    expect(resolvedRole).toBeNull();

    const session = buildAdminSession({
      uid: "fallback-finance",
      fallback: { role: "finance_admin" },
    });

    expect(session).toBeNull();
  });

  it("denies on claims and fallback role conflict", () => {
    const resolvedRole = resolveAdminRole({
      claims: { role: "finance_admin" },
      fallback: { role: "ops_viewer" },
    });

    expect(resolvedRole).toBeNull();

    expect(
      buildAdminSession({
        uid: "conflict-user",
        claims: { role: "finance_admin" },
        fallback: { role: "ops_viewer" },
      }),
    ).toBeNull();
  });
});
