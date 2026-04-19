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
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("redirects unauthenticated users to sign-in", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(null);

    await expect(requireRouteAccess("dashboard", "/admin/dashboard")).rejects.toThrow(
      "redirect:/admin/sign-in?next=%2Fadmin%2Fdashboard",
    );
  });

  it("redirects unauthorized roles to access-denied", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(makeSession("ops_viewer"));

    await expect(requireRouteAccess("config", "/admin/config")).rejects.toThrow(
      "redirect:/admin/access-denied?route=config",
    );
  });

  it("allows authorized role through protected route", async () => {
    const financeSession = makeSession("finance_admin");
    getCurrentAdminSessionMock.mockResolvedValue(financeSession);

    await expect(requireRouteAccess("config", "/admin/config")).resolves.toEqual(
      financeSession,
    );
    expect(redirectMock).not.toHaveBeenCalled();
  });
});
