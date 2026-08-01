import { describe, expect, it } from "vitest";

import { buildAdminSession } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";
import {
  ADMIN_ROUTE_MAP,
  getVisibleNavigationRouteGroups,
  getVisibleNavigationRoutes,
} from "@/lib/navigation/admin-route-map";

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

describe("admin sidebar route groups", () => {
  it("maps super admin routes into localized groups with stable ordering", () => {
    const session = mustBuildSession("super_admin");
    const groups = getVisibleNavigationRouteGroups(session);

    expect(groups.map((group) => group.key)).toEqual([
      "finance",
      "content",
      "system",
    ]);
    expect(groups.map((group) => group.title)).toEqual([
      "المالية",
      "المحتوى",
      "النظام",
    ]);
    expect(groups.map((group) => group.routes.map((route) => route.key))).toEqual([
      ["dashboard", "topups", "wallet_audit", "reversals", "readiness"],
      ["venues", "media", "content_offers", "content_stories", "reviews_moderation"],
      ["config"],
    ]);
    expect(groups.flatMap((group) => group.routes.map((route) => route.title))).toEqual([
      "نظرة عامة",
      "طلبات الشحن",
      "سجل المحفظة",
      "طلبات عكس العمليات",
      "حالة النظام",
      "الجهات",
      "الصور والملفات",
      "العروض",
      "القصص",
      "المراجعات",
      "إعدادات التطبيق",
    ]);
  });

  it("preserves visible-route order when flattening grouped output", () => {
    const session = mustBuildSession("support_admin");
    const flatVisibleRouteKeys = getVisibleNavigationRoutes(session).map(
      (route) => route.key,
    );
    const groupedVisibleRouteKeys = getVisibleNavigationRouteGroups(session)
      .flatMap((group) => group.routes)
      .map((route) => route.key);

    expect(groupedVisibleRouteKeys.slice().sort()).toEqual(
      flatVisibleRouteKeys.slice().sort(),
    );
    expect(new Set(groupedVisibleRouteKeys).size).toBe(groupedVisibleRouteKeys.length);
    expect(
      getVisibleNavigationRouteGroups(session).every(
        (group) => group.routes.length > 0,
      ),
    ).toBe(true);
  });

  it("assigns a renderable icon to every admin route", () => {
    expect(ADMIN_ROUTE_MAP.every((route) => route.icon)).toBe(true);
    expect(ADMIN_ROUTE_MAP.map((route) => route.key)).toHaveLength(
      ADMIN_ROUTE_MAP.map((route) => route.icon).length,
    );
  });
});
