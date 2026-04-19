import { redirect } from "next/navigation";
import * as React from "react";

import {
  canAccessRoute,
  type AdminSession,
} from "@/lib/auth/guard-api";
import type { AdminRouteKey } from "@/lib/navigation/admin-contract";
import {
  resolveAdminNextPath,
  resolveAdminNextPathFromCandidates,
} from "./redirect-path";
import { emitAdminSecurityAudit } from "./admin-security-audit";

function withOptionalReactCache<T extends (...args: any[]) => any>(fn: T): T {
  const maybeCache = (React as { cache?: <U extends (...args: any[]) => any>(wrapped: U) => U }).cache;
  return maybeCache ? maybeCache(fn) : fn;
}

const loadCurrentAdminSession = withOptionalReactCache(async (): Promise<AdminSession | null> => {
  const { getCurrentAdminSession } = await import("@/lib/auth/session-server");
  return getCurrentAdminSession();
});

export function getSignInRedirectPath(nextPath: string): string {
  return `/admin/sign-in?next=${encodeURIComponent(nextPath)}`;
}

export async function resolveRequestAdminNextPath(
  fallbackPath = "/admin",
): Promise<string> {
  try {
    const { headers } = await import("next/headers");
    const requestHeaders = headers();

    return resolveAdminNextPathFromCandidates(
      [
        requestHeaders.get("x-invoke-path"),
        requestHeaders.get("x-matched-path"),
        requestHeaders.get("next-url"),
        requestHeaders.get("x-next-url"),
        requestHeaders.get("referer"),
      ],
      fallbackPath,
    );
  } catch {
    return fallbackPath;
  }
}

export function getAccessDeniedRedirectPath(routeKey: AdminRouteKey): string {
  return `/admin/access-denied?route=${encodeURIComponent(routeKey)}`;
}

export type RouteAccessOutcome =
  | { kind: "allow"; session: AdminSession }
  | {
      kind: "redirect";
      reason: "unauthenticated" | "forbidden";
      destination: string;
    };

export function evaluateRouteAccess(
  session: AdminSession | null,
  routeKey: AdminRouteKey,
  path: string,
): RouteAccessOutcome {
  if (!session) {
    emitAdminSecurityAudit({
      source: "route-guards",
      eventType: "admin_route_access_denied",
      reason: "unauthenticated",
      status: 401,
      routeKey,
      path,
    });
    return {
      kind: "redirect",
      reason: "unauthenticated",
      destination: getSignInRedirectPath(path),
    };
  }

  if (!canAccessRoute(session, routeKey)) {
    emitAdminSecurityAudit({
      source: "route-guards",
      eventType: "admin_route_access_denied",
      reason: "forbidden",
      status: 403,
      routeKey,
      path,
      sessionUid: session.uid,
      sessionRole: session.primaryRole,
    });
    return {
      kind: "redirect",
      reason: "forbidden",
      destination: getAccessDeniedRedirectPath(routeKey),
    };
  }

  return { kind: "allow", session };
}

export async function requireAdminSession(
  nextPath?: string,
): Promise<AdminSession> {
  const _t0 = performance.now();
  const session = await loadCurrentAdminSession();
  console.log(`[PERF] requireAdminSession: ${(performance.now() - _t0).toFixed(0)}ms`);
  if (!session) {
    const fallbackPath = resolveAdminNextPath(nextPath, "/admin");
    const redirectPath = nextPath
      ? fallbackPath
      : await resolveRequestAdminNextPath(fallbackPath);
    emitAdminSecurityAudit({
      source: "route-guards",
      eventType: "admin_session_required_missing",
      reason: "unauthenticated",
      status: 401,
      path: redirectPath,
    });
    redirect(getSignInRedirectPath(redirectPath));
  }
  return session;
}

export async function requireRouteAccess(
  routeKey: AdminRouteKey,
  path: string,
): Promise<AdminSession> {
  const session = await loadCurrentAdminSession();
  const outcome = evaluateRouteAccess(session, routeKey, path);
  if (outcome.kind === "redirect") {
    redirect(outcome.destination);
  }
  return outcome.session;
}
