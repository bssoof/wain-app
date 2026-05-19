import "server-only";

import {
  type AdminSession,
  type AdminSessionContext,
  buildAdminSession,
  extractRoles,
  hasExplicitClaimDeny,
  parseBoolean,
  parseJsonRecord,
  toNonEmptyString,
} from "./guard-api";
import {
  ADMIN_HOSTING_SESSION_COOKIE_NAME,
  ADMIN_SESSION_COOKIE_NAME,
  verifyAdminSessionCookieWithProfile,
} from "./session-cookie";

function isTruthyFlag(value: string | undefined): boolean {
  if (!value) {
    return false;
  }

  const normalized = value.trim().toLowerCase();
  return normalized === "1" || normalized === "true" || normalized === "on";
}

export function isUnsafeHeaderSessionEnabled(
  env: Record<string, string | undefined> = process.env,
): boolean {
  const runtime = env.NODE_ENV?.trim().toLowerCase();
  if (runtime === "production") {
    return false;
  }

  return isTruthyFlag(env.WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION);
}

export function isUnsafeEnvJsonSessionEnabled(
  env: Record<string, string | undefined> = process.env,
): boolean {
  const runtime = env.NODE_ENV?.trim().toLowerCase();
  return runtime !== "production";
}

export async function getCurrentAdminSession(): Promise<AdminSession | null> {
  const context = await readRuntimeAdminSessionContext();
  return buildAdminSession(context);
}

export async function readRuntimeAdminSessionContext(): Promise<AdminSessionContext | null> {
  const cookieContext = await readCookieBasedSessionContext();
  if (cookieContext) return cookieContext;

  if (isUnsafeHeaderSessionEnabled()) {
    const headerContext = await readHeaderBasedSessionContext();
    if (headerContext) {
      return headerContext;
    }
  }

  if (isUnsafeEnvJsonSessionEnabled()) {
    const envJsonContext = parseSessionContext(process.env.WAIN_ADMIN_SESSION_JSON);
    if (envJsonContext) {
      return envJsonContext;
    }
  }

  if (process.env.NODE_ENV === "development" && !process.env.WAIN_STRICT_AUTH) {
     const envContext = readEnvSessionContext();
     return envContext;
  }

  return null;
}

export async function readCookieBasedSessionContext(): Promise<AdminSessionContext | null> {
  try {
    const { cookies } = await import("next/headers");
    const cookieStore = await cookies();
    const sessionCookie =
      cookieStore.get(ADMIN_SESSION_COOKIE_NAME)?.value ??
      cookieStore.get(ADMIN_HOSTING_SESSION_COOKIE_NAME)?.value;
    if (!sessionCookie) return null;

    const { decodedToken, adminProfile } =
      await verifyAdminSessionCookieWithProfile(sessionCookie);
    
    return {
      uid: decodedToken.uid,
      email: decodedToken.email ?? adminProfile.email,
      displayName: decodedToken.name || adminProfile.name,
      claims: {
        role: adminProfile.role ?? decodedToken.role,
        roles: adminProfile.roles ?? decodedToken.roles,
        admin: true,
        isAdmin: true,
      },
    };
  } catch {
    return null;
  }
}

export async function readHeaderBasedSessionContext(): Promise<AdminSessionContext | null> {
  if (!isUnsafeHeaderSessionEnabled()) {
    return null;
  }

  try {
    const { headers } = await import("next/headers");
    const requestHeaders = await headers();

    const serializedSession = requestHeaders.get("x-wain-admin-session");
    const parsedSerialized = parseSessionContext(serializedSession);
    if (parsedSerialized) {
      return parsedSerialized;
    }

    const claimsObject = parseJsonRecord(requestHeaders.get("x-wain-admin-claims"));
    const fallbackObject = parseJsonRecord(
      requestHeaders.get("x-wain-admin-fallback"),
    );

    const headerContext: AdminSessionContext = {
      uid: requestHeaders.get("x-wain-admin-uid") ?? undefined,
      email: requestHeaders.get("x-wain-admin-email") ?? undefined,
      displayName: requestHeaders.get("x-wain-admin-display-name") ?? undefined,
      claims: {
        role: requestHeaders.get("x-wain-admin-role") ?? claimsObject?.role,
        roles: requestHeaders.get("x-wain-admin-roles") ?? claimsObject?.roles,
        admin:
          parseBoolean(requestHeaders.get("x-wain-admin-admin")) ?? claimsObject?.admin,
        isAdmin:
          parseBoolean(requestHeaders.get("x-wain-admin-is-admin")) ??
          claimsObject?.isAdmin,
      },
      fallback: {
        role:
          requestHeaders.get("x-wain-admin-fallback-role") ?? fallbackObject?.role,
        roles:
          requestHeaders.get("x-wain-admin-fallback-roles") ??
          fallbackObject?.roles,
      },
    };

    if (!hasAnySessionSignal(headerContext)) {
      return null;
    }

    return headerContext;
  } catch {
    return null;
  }
}

export function readEnvSessionContext(): AdminSessionContext | null {
  const envContext: AdminSessionContext = {
    uid: process.env.WAIN_ADMIN_UID,
    email: process.env.WAIN_ADMIN_EMAIL,
    displayName: process.env.WAIN_ADMIN_DISPLAY_NAME,
    claims: {
      role: process.env.WAIN_ADMIN_ROLE,
      roles: process.env.WAIN_ADMIN_ROLES,
      admin: parseBoolean(process.env.WAIN_ADMIN_ADMIN),
      isAdmin: parseBoolean(process.env.WAIN_ADMIN_IS_ADMIN),
    },
    fallback: {
      role: process.env.WAIN_ADMIN_FALLBACK_ROLE,
      roles: process.env.WAIN_ADMIN_FALLBACK_ROLES,
    },
  };

  if (!hasAnySessionSignal(envContext)) {
    return null;
  }

  return envContext;
}

export function hasAnySessionSignal(context: AdminSessionContext): boolean {
  return Boolean(
    toNonEmptyString(context.uid) ||
      toNonEmptyString(context.email) ||
      toNonEmptyString(context.displayName) ||
      extractRoles(context.claims).length > 0 ||
      hasExplicitClaimDeny(context.claims),
  );
}

export function parseSessionContext(
  rawValue: string | null | undefined,
): AdminSessionContext | null {
  const parsed = parseJsonRecord(rawValue);
  return parsed ? (parsed as AdminSessionContext) : null;
}
