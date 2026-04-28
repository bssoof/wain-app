import { describe, expect, it } from "vitest";

import { buildAdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";
import {
  ADMIN_ROUTE_PREFETCH_MODES,
  type AdminRoutePrefetchMode,
} from "@/lib/navigation/admin-contract";
import { ADMIN_ROUTE_MAP } from "@/lib/navigation/admin-route-map";
import {
  ADMIN_WARMUP_MAX_AUTO_PREFETCH_ROUTES,
  ADMIN_WARMUP_MAX_SERVER_TASKS,
  buildAdminWarmupStorageKey,
  getAdminServerWarmupRouteKeys,
  getAdminWarmupPolicy,
} from "@/lib/navigation/admin-warmup-policy";

function mustBuildSession(primaryRole: AdminRole) {
  const session = buildAdminSession({
    uid: `${primaryRole}-uid`,
    claims: { role: primaryRole },
  });

  if (!session) {
    throw new Error(`Expected a valid admin session for role: ${primaryRole}`);
  }

  return session;
}

describe("admin warmup policy", () => {
  it("declares a prefetch mode for every admin route", () => {
    const allowedModes = new Set<AdminRoutePrefetchMode>(
      ADMIN_ROUTE_PREFETCH_MODES,
    );

    expect(ADMIN_ROUTE_MAP.every((route) => allowedModes.has(route.prefetchMode))).toBe(
      true,
    );
  });

  it("bounds one-time auto prefetches and excludes the active route", () => {
    const session = mustBuildSession("super_admin");
    const policy = getAdminWarmupPolicy(session, {
      pathname: "/admin/dashboard",
    });

    expect(policy.prefetchPaths).toEqual([
      "/admin/topups",
      "/admin/wallet-audit",
      "/admin/readiness",
      "/admin/venues",
    ]);
    expect(policy.prefetchPaths.length).toBeLessThanOrEqual(
      ADMIN_WARMUP_MAX_AUTO_PREFETCH_ROUTES,
    );
    expect(policy.prefetchPaths).not.toContain("/admin/dashboard");
    expect(policy.prefetchPaths).not.toContain("/admin/config");
    expect(policy.prefetchPaths).not.toContain("/admin/content/reviews");
  });

  it("keeps server warmup tasks bounded and aligned to requested auto routes", () => {
    const session = mustBuildSession("super_admin");
    const routeKeys = getAdminServerWarmupRouteKeys(session, {
      pathname: "/admin/topups",
      requestedRouteKeys: ["topups", "wallet_audit", "readiness", "venues", "config"],
    });

    expect(routeKeys).toEqual(["wallet_audit", "readiness", "venues"]);
    expect(routeKeys.length).toBeLessThanOrEqual(ADMIN_WARMUP_MAX_SERVER_TASKS);
  });

  it("filters warmup tasks through RBAC visibility", () => {
    const session = mustBuildSession("content_admin");
    const routeKeys = getAdminServerWarmupRouteKeys(session, {
      requestedRouteKeys: ["topups", "wallet_audit", "readiness", "venues"],
    });

    expect(routeKeys).toEqual(["readiness", "venues"]);
  });

  it("versions the client session guard storage key", () => {
    expect(buildAdminWarmupStorageKey("uid-1")).toBe(
      "wain_admin_warmup_v4:uid-1",
    );
  });
});
