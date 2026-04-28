import { describe, expect, it } from "vitest";

import {
  ADMIN_ROUTE_MAP,
  getVisibleNavigationRoutes,
} from "@/lib/navigation/admin-route-map";
import type { AdminRole } from "../navigation/admin-contract";
import {
  buildAdminSession,
  canAccessRoute,
  canRenderAction,
  type AdminSession,
} from "./guard-api";
import {
  evaluateRouteAccess,
  getAccessDeniedRedirectPath,
  getSignInRedirectPath,
} from "./route-guards";

function mustBuildSession(primaryRole: AdminRole): AdminSession {
  const session = buildAdminSession({
    uid: `${primaryRole}-uid`,
    claims: { role: primaryRole },
  });

  if (!session) {
    throw new Error(`Expected valid session for role: ${primaryRole}`);
  }

  return session;
}

describe("Phase 1 shell and RBAC integration", () => {
  it("allowed role sees allowed routes", () => {
    const financeSession = mustBuildSession("finance_admin");
    const visibleRouteKeys = getVisibleNavigationRoutes(financeSession).map(
      (route) => route.key,
    );

    expect(visibleRouteKeys).toEqual(
      ADMIN_ROUTE_MAP.filter((route) => canAccessRoute(financeSession, route.key)).map(
        (route) => route.key,
      ),
    );

    expect(visibleRouteKeys).toContain("reversals");
    expect(canRenderAction(financeSession, "approve_topup")).toBe(true);
    expect(canRenderAction(financeSession, "create_reversal")).toBe(true);
  });

  it("denied role does not see restricted routes", () => {
    const supportSession = mustBuildSession("support_admin");
    const visibleRouteKeys = getVisibleNavigationRoutes(supportSession).map(
      (route) => route.key,
    );

    expect(visibleRouteKeys).not.toContain("topups");
    expect(visibleRouteKeys).not.toContain("reversals");
    expect(visibleRouteKeys).not.toContain("reviews_moderation");
    expect(visibleRouteKeys).not.toContain("config");
    expect(visibleRouteKeys).toContain("wallet_audit");
    expect(visibleRouteKeys).toContain("venues");
    expect(visibleRouteKeys).toContain("media");

    expect(canAccessRoute(supportSession, "topups")).toBe(false);
    expect(canAccessRoute(supportSession, "reversals")).toBe(false);
  });

  it("direct route denial is enforced", () => {
    const opsSession = mustBuildSession("ops_viewer");
    const deniedOutcome = evaluateRouteAccess(
      opsSession,
      "reversals",
      "/admin/reversals",
    );

    expect(deniedOutcome.kind).toBe("redirect");
    if (deniedOutcome.kind === "redirect") {
      expect(deniedOutcome.reason).toBe("forbidden");
      expect(deniedOutcome.destination).toBe(
        getAccessDeniedRedirectPath("reversals"),
      );
    }

    const noSessionOutcome = evaluateRouteAccess(null, "dashboard", "/admin/dashboard");
    expect(noSessionOutcome.kind).toBe("redirect");
    if (noSessionOutcome.kind === "redirect") {
      expect(noSessionOutcome.reason).toBe("unauthenticated");
      expect(noSessionOutcome.destination).toBe(
        getSignInRedirectPath("/admin/dashboard"),
      );
    }
  });

  it("shell route model stays aligned with guard and capability contract", () => {
    const opsSession = mustBuildSession("ops_viewer");
    const visibleRouteKeys = new Set(
      getVisibleNavigationRoutes(opsSession).map((route) => route.key),
    );

    for (const route of ADMIN_ROUTE_MAP) {
      const canAccess = canAccessRoute(opsSession, route.key);
      expect(visibleRouteKeys.has(route.key)).toBe(canAccess);

      if (route.routeCapability && canAccess) {
        expect(canRenderAction(opsSession, route.routeCapability)).toBe(true);
      }

      for (const capability of route.mutationCapabilities) {
        const capabilityAllowed = canRenderAction(opsSession, capability);
        if (
          route.key === "topups" ||
          route.key === "reversals" ||
          route.key === "venues" ||
          route.key === "media" ||
          route.key === "reviews_moderation" ||
          route.key === "config"
        ) {
          expect(capabilityAllowed).toBe(false);
        }
      }
    }
  });
});
