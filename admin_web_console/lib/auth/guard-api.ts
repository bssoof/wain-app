import type {
  AdminCapabilityKey,
  AdminRole,
  AdminRouteKey,
} from "../navigation/admin-contract";
import { isAdminRole } from "../navigation/admin-contract";

export type AdminClaimsInput = {
  admin?: unknown;
  isAdmin?: unknown;
  role?: unknown;
  roles?: unknown;
};

export type AdminFallbackInput = {
  role?: unknown;
  roles?: unknown;
};

export type ResolveAdminRoleInput = {
  claims?: AdminClaimsInput | null;
  fallback?: AdminFallbackInput | null;
};

export type ResolvedAdminRole = {
  primaryRole: AdminRole;
  roles: AdminRole[];
  source: "claims";
};

export type AdminSessionContext = ResolveAdminRoleInput & {
  uid?: unknown;
  email?: unknown;
  displayName?: unknown;
};

export type AdminSession = {
  uid: string;
  email?: string;
  displayName?: string;
  primaryRole: AdminRole;
  roles: AdminRole[];
  roleSource: "claims";
};

const ALL_ADMIN_ROLES: readonly AdminRole[] = [
  "super_admin",
  "finance_admin",
  "content_admin",
  "support_admin",
  "ops_viewer",
];

const FINANCE_ACTION_ROLES: readonly AdminRole[] = [
  "super_admin",
  "finance_admin",
];

const MEDIA_ACTION_ROLES: readonly AdminRole[] = [
  "super_admin",
  "content_admin",
];

const CONTENT_ACTION_ROLES: readonly AdminRole[] = [
  "super_admin",
  "content_admin",
];

export const ROUTE_ROLE_PERMISSIONS: Record<AdminRouteKey, readonly AdminRole[]> = {
  dashboard: ALL_ADMIN_ROLES,
  topups: ["super_admin", "finance_admin", "ops_viewer"],
  wallet_audit: ["super_admin", "finance_admin", "support_admin", "ops_viewer"],
  reversals: ["super_admin", "finance_admin"],
  venues: ALL_ADMIN_ROLES,
  media: ALL_ADMIN_ROLES,
  content_offers: CONTENT_ACTION_ROLES,
  content_stories: CONTENT_ACTION_ROLES,
  reviews_moderation: CONTENT_ACTION_ROLES,
  config: FINANCE_ACTION_ROLES,
  readiness: ALL_ADMIN_ROLES,
};

export const CAPABILITY_ROLE_PERMISSIONS: Record<
  AdminCapabilityKey,
  readonly AdminRole[]
> = {
  view_dashboard: ROUTE_ROLE_PERMISSIONS.dashboard,
  view_topups: ROUTE_ROLE_PERMISSIONS.topups,
  approve_topup: FINANCE_ACTION_ROLES,
  reject_topup: FINANCE_ACTION_ROLES,
  view_wallet_audit: ROUTE_ROLE_PERMISSIONS.wallet_audit,
  create_reversal: FINANCE_ACTION_ROLES,
  approve_reversal: FINANCE_ACTION_ROLES,
  view_venues: ROUTE_ROLE_PERMISSIONS.venues,
  create_venue: ["super_admin"],
  edit_venue_profile: CONTENT_ACTION_ROLES,
  change_venue_visibility: CONTENT_ACTION_ROLES,
  change_venue_operational_status: ["super_admin"],
  change_venue_subscription_status: ["super_admin"],
  view_media: ROUTE_ROLE_PERMISSIONS.media,
  media_soft_delete: MEDIA_ACTION_ROLES,
  media_quarantine: MEDIA_ACTION_ROLES,
  media_reference_check: MEDIA_ACTION_ROLES,
  media_purge: MEDIA_ACTION_ROLES,
  view_reviews_moderation: ROUTE_ROLE_PERMISSIONS.reviews_moderation,
  review_publish: CONTENT_ACTION_ROLES,
  review_hide: CONTENT_ACTION_ROLES,
  review_escalate: CONTENT_ACTION_ROLES,
  offer_approve: CONTENT_ACTION_ROLES,
  offer_reject: CONTENT_ACTION_ROLES,
  offer_flag: CONTENT_ACTION_ROLES,
  offer_pause: CONTENT_ACTION_ROLES,
  story_approve: CONTENT_ACTION_ROLES,
  story_reject: CONTENT_ACTION_ROLES,
  story_flag: CONTENT_ACTION_ROLES,
  story_pause: CONTENT_ACTION_ROLES,
  view_config_governance: ROUTE_ROLE_PERMISSIONS.config,
  config_draft_write: FINANCE_ACTION_ROLES,
  config_review: FINANCE_ACTION_ROLES,
  publish_config: FINANCE_ACTION_ROLES,
  rollback_config: FINANCE_ACTION_ROLES,
  view_readiness: ROUTE_ROLE_PERMISSIONS.readiness,
  "shell.sign_out": ALL_ADMIN_ROLES,
};

// Server session generation has been moved to session-server.ts to prevent 
// client-side bundling of firebase-admin and node APIs.

export function resolveAdminRole(
  input: ResolveAdminRoleInput,
): ResolvedAdminRole | null {
  const claimRoles = extractRoles(input.claims);
  const fallbackRoles = extractRoles(input.fallback);

  // SEC-2: fallback roles can never elevate or grant access.
  if (claimRoles.length === 0 && fallbackRoles.length > 0) {
    return null;
  }

  if (claimRoles.length > 0) {
    if (fallbackRoles.length > 0 && !sameRoleSet(claimRoles, fallbackRoles)) {
      return null;
    }

    return {
      primaryRole: claimRoles[0],
      roles: claimRoles,
      source: "claims",
    };
  }

  return null;
}

export function buildAdminSession(
  context: AdminSessionContext | null | undefined,
): AdminSession | null {
  if (!context || hasExplicitClaimDeny(context.claims)) {
    return null;
  }

  const uid = toNonEmptyString(context.uid);
  if (!uid) {
    return null;
  }

  const resolved = resolveAdminRole(context);
  if (!resolved) {
    return null;
  }

  return {
    uid,
    email: toNonEmptyString(context.email),
    displayName: toNonEmptyString(context.displayName),
    primaryRole: resolved.primaryRole,
    roles: resolved.roles,
    roleSource: resolved.source,
  };
}

export function canAccessRoute(
  session: AdminSession,
  routeKey: AdminRouteKey,
): boolean {
  const allowedRoles = ROUTE_ROLE_PERMISSIONS[routeKey];
  return hasAtLeastOneRole(session, allowedRoles);
}

export function canRenderAction(
  session: AdminSession,
  capabilityKey: AdminCapabilityKey,
): boolean {
  const allowedRoles = CAPABILITY_ROLE_PERMISSIONS[capabilityKey];
  return hasAtLeastOneRole(session, allowedRoles);
}

function hasAtLeastOneRole(
  session: AdminSession,
  allowedRoles: readonly AdminRole[] | undefined,
): boolean {
  if (!allowedRoles || allowedRoles.length === 0) {
    return false;
  }

  const sessionRoles = dedupeRoles([session.primaryRole, ...session.roles]);
  if (sessionRoles.length === 0) {
    return false;
  }

  return sessionRoles.some((role) => allowedRoles.includes(role));
}

export function hasExplicitClaimDeny(claims: AdminClaimsInput | null | undefined): boolean {
  if (!claims) {
    return false;
  }

  return claims.admin === false || claims.isAdmin === false;
}

function sameRoleSet(left: AdminRole[], right: AdminRole[]): boolean {
  if (left.length !== right.length) {
    return false;
  }

  return left.every((role) => right.includes(role));
}

export function extractRoles(
  source: { role?: unknown; roles?: unknown } | null | undefined,
): AdminRole[] {
  if (!source) {
    return [];
  }

  const roleCandidates: unknown[] = [];
  roleCandidates.push(source.role);

  if (Array.isArray(source.roles)) {
    roleCandidates.push(...source.roles);
  } else if (typeof source.roles === "string") {
    roleCandidates.push(
      ...source.roles
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean),
    );
  }

  const normalizedRoles = roleCandidates
    .map((candidate) => (typeof candidate === "string" ? candidate.trim() : candidate))
    .filter(isAdminRole);

  return dedupeRoles(normalizedRoles);
}

function dedupeRoles(roles: AdminRole[]): AdminRole[] {
  const output: AdminRole[] = [];
  for (const role of roles) {
    if (isAdminRole(role) && !output.includes(role)) {
      output.push(role);
    }
  }
  return output;
}

export function parseJsonRecord(
  rawValue: string | null | undefined,
): Record<string, unknown> | null {
  if (!rawValue) {
    return null;
  }

  try {
    const parsed = JSON.parse(rawValue) as unknown;
    if (!parsed || typeof parsed !== "object") {
      return null;
    }
    return parsed as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function parseBoolean(value: string | null | undefined): boolean | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }

  const normalized = value.trim().toLowerCase();
  if (normalized === "true") {
    return true;
  }
  if (normalized === "false") {
    return false;
  }
  return undefined;
}

export function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

