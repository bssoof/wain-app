import type { AdminSession } from "@/lib/auth/guard-api";
import type { AdminRouteKey } from "@/lib/navigation/admin-contract";
import {
  getVisibleNavigationRoutes,
  type AdminRouteDefinition,
} from "@/lib/navigation/admin-route-map";

export const ADMIN_WARMUP_STORAGE_VERSION = "v4";
export const ADMIN_WARMUP_MAX_AUTO_PREFETCH_ROUTES = 4;
export const ADMIN_WARMUP_MAX_SERVER_TASKS = 4;

const AUTO_PREFETCH_ROUTE_PRIORITY: readonly AdminRouteKey[] = [
  "dashboard",
  "topups",
  "wallet_audit",
  "readiness",
  "venues",
];

const SERVER_WARMUP_ROUTE_PRIORITY: readonly AdminRouteKey[] = [
  "topups",
  "wallet_audit",
  "readiness",
  "venues",
];

type WarmupPolicyOptions = {
  pathname?: string | null;
  maxPrefetchRoutes?: number;
  maxServerTasks?: number;
  requestedRouteKeys?: readonly AdminRouteKey[];
};

export type AdminWarmupPolicy = {
  prefetchPaths: string[];
  warmupRouteKeys: AdminRouteKey[];
};

export function buildAdminWarmupStorageKey(uid: string): string {
  return `wain_admin_warmup_${ADMIN_WARMUP_STORAGE_VERSION}:${uid}`;
}

export function getAdminWarmupPolicy(
  session: AdminSession,
  options: WarmupPolicyOptions = {},
): AdminWarmupPolicy {
  return {
    prefetchPaths: getAdminAutoPrefetchPaths(session, options),
    warmupRouteKeys: getAdminServerWarmupRouteKeys(session, options),
  };
}

export function getAdminAutoPrefetchPaths(
  session: AdminSession,
  options: WarmupPolicyOptions = {},
): string[] {
  const maxRoutes = normalizeLimit(
    options.maxPrefetchRoutes,
    ADMIN_WARMUP_MAX_AUTO_PREFETCH_ROUTES,
  );
  const pathname = options.pathname ?? "";
  const visibleRouteByKey = buildVisibleRouteMap(session);

  return AUTO_PREFETCH_ROUTE_PRIORITY
    .map((routeKey) => visibleRouteByKey.get(routeKey))
    .filter(
      (route): route is AdminRouteDefinition =>
        route !== undefined && route.prefetchMode === "auto",
    )
    .filter((route) => !isActiveRoutePath(pathname, route.path))
    .map((route) => route.path)
    .slice(0, maxRoutes);
}

export function getAdminServerWarmupRouteKeys(
  session: AdminSession,
  options: WarmupPolicyOptions = {},
): AdminRouteKey[] {
  const maxTasks = normalizeLimit(
    options.maxServerTasks,
    ADMIN_WARMUP_MAX_SERVER_TASKS,
  );
  const visibleRouteByKey = buildVisibleRouteMap(session);
  const pathname = options.pathname ?? "";
  const requestedRouteKeySet = options.requestedRouteKeys
    ? new Set(options.requestedRouteKeys)
    : null;

  return SERVER_WARMUP_ROUTE_PRIORITY
    .filter((routeKey) => !requestedRouteKeySet || requestedRouteKeySet.has(routeKey))
    .filter((routeKey) => {
      const route = visibleRouteByKey.get(routeKey);
      return (
        route?.prefetchMode === "auto" &&
        !isActiveRoutePath(pathname, route.path)
      );
    })
    .slice(0, maxTasks);
}

function buildVisibleRouteMap(session: AdminSession) {
  return new Map(
    getVisibleNavigationRoutes(session).map((route) => [route.key, route]),
  );
}

function isActiveRoutePath(pathname: string, routePath: string): boolean {
  return pathname === routePath || pathname.startsWith(`${routePath}/`);
}

function normalizeLimit(value: number | undefined, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return fallback;
  }

  return Math.max(0, Math.floor(value));
}
