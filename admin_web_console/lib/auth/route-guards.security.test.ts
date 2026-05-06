import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";

const { getCurrentAdminSessionMock, redirectMock } = vi.hoisted(() => ({
  getCurrentAdminSessionMock: vi.fn(),
  redirectMock: vi.fn((destination: string) => {
    throw new Error(`redirect:${destination}`);
  }),
}));

vi.mock("next/navigation", () => ({
  redirect: (destination: string) => redirectMock(destination),
}));

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: (...args: unknown[]) => getCurrentAdminSessionMock(...args),
}));

import { requireRouteAccess } from "@/lib/auth/route-guards";

function makeSession(primaryRole: AdminSession["primaryRole"]): AdminSession {
  return {
    uid: "admin-security-test",
    primaryRole,
    roles: [primaryRole],
    roleSource: "claims",
  };
}

describe("security: protected route access", () => {
  const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => undefined);

  beforeEach(() => {
    vi.clearAllMocks();
  });

  function parseLastSecurityAuditEvent(): Record<string, unknown> {
    const lastCall = warnSpy.mock.calls.at(-1)?.[0];
    const prefix = "[SECURITY_AUDIT] ";
    expect(typeof lastCall).toBe("string");
    expect((lastCall as string).startsWith(prefix)).toBe(true);
    return JSON.parse((lastCall as string).slice(prefix.length)) as Record<string, unknown>;
  }

  it("redirects unauthenticated users to sign-in", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(null);

    await expect(requireRouteAccess("dashboard", "/admin/dashboard")).rejects.toThrow(
      "redirect:/admin/sign-in?next=%2Fadmin%2Fdashboard",
    );

    const event = parseLastSecurityAuditEvent();
    expect(event.eventType).toBe("admin_route_access_denied");
    expect(event.reason).toBe("unauthenticated");
    expect(event.status).toBe(401);
    expect(event.routeKey).toBe("dashboard");
    expect(event.path).toBe("/admin/dashboard");
  });

  it("redirects unauthorized roles to access-denied", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(makeSession("ops_viewer"));

    await expect(requireRouteAccess("config", "/admin/config")).rejects.toThrow(
      "redirect:/admin/access-denied?route=config",
    );

    const event = parseLastSecurityAuditEvent();
    expect(event.eventType).toBe("admin_route_access_denied");
    expect(event.reason).toBe("forbidden");
    expect(event.status).toBe(403);
    expect(event.routeKey).toBe("config");
    expect(event.path).toBe("/admin/config");
    expect(event.sessionRole).toBe("ops_viewer");
  });

  it("denies finance_admin access to config route", async () => {
    // RBAC tightened per docs/design/admin-config-validation.md
    const financeSession = makeSession("finance_admin");
    getCurrentAdminSessionMock.mockResolvedValue(financeSession);

    await expect(requireRouteAccess("config", "/admin/config")).rejects.toThrow(
      "redirect:/admin/access-denied?route=config",
    );

    const event = parseLastSecurityAuditEvent();
    expect(event.eventType).toBe("admin_route_access_denied");
    expect(event.reason).toBe("forbidden");
    expect(event.status).toBe(403);
    expect(event.routeKey).toBe("config");
    expect(event.path).toBe("/admin/config");
    expect(event.sessionRole).toBe("finance_admin");
  });

  it("allows super_admin through protected route", async () => {
    const superAdminSession = makeSession("super_admin");
    getCurrentAdminSessionMock.mockResolvedValue(superAdminSession);

    await expect(requireRouteAccess("config", "/admin/config")).resolves.toEqual(
      superAdminSession,
    );
    expect(redirectMock).not.toHaveBeenCalled();
    expect(warnSpy).not.toHaveBeenCalled();
  });
});
