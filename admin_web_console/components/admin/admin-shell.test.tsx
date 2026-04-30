import { render, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { fetchMock, prefetchMock, usePathnameMock } = vi.hoisted(() => ({
  fetchMock: vi.fn(),
  prefetchMock: vi.fn(),
  usePathnameMock: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  usePathname: () => usePathnameMock(),
  useRouter: () => ({
    prefetch: prefetchMock,
  }),
}));

vi.mock("@/components/admin/admin-header", () => ({
  AdminHeader: () => <header data-testid="admin-header" />,
}));

vi.mock("@/components/admin/admin-sidebar", () => ({
  AdminSidebar: () => <aside data-testid="admin-sidebar" />,
}));

vi.mock("@/components/admin/admin-banner", () => ({
  AdminBanner: () => <div data-testid="admin-banner" />,
}));

import { AdminShell } from "@/components/admin/admin-shell";
import { buildAdminSession } from "@/lib/auth/guard-api";

function mustBuildSuperAdminSession() {
  const session = buildAdminSession({
    uid: "admin-1",
    email: "admin@wain.app",
    claims: { role: "super_admin" },
  });

  if (!session) {
    throw new Error("Expected super admin session");
  }

  return session;
}

beforeEach(() => {
  vi.clearAllMocks();
  window.sessionStorage.clear();
  usePathnameMock.mockReturnValue("/admin/dashboard");
  fetchMock.mockResolvedValue({ ok: true });
  vi.stubGlobal("fetch", fetchMock);
  window.requestIdleCallback = ((callback: IdleRequestCallback) => {
    callback({ didTimeout: false, timeRemaining: () => 50 });
    return 1;
  }) as typeof window.requestIdleCallback;
  window.cancelIdleCallback = vi.fn() as typeof window.cancelIdleCallback;
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("AdminShell warmup guardrails", () => {
  it("runs a bounded warmup once per browser session", async () => {
    const session = mustBuildSuperAdminSession();

    render(
      <AdminShell session={session}>
        <div>children</div>
      </AdminShell>,
    );

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));

    expect(prefetchMock.mock.calls.map(([path]) => path)).toEqual([
      "/admin/topups",
      "/admin/wallet-audit",
      "/admin/readiness",
      "/admin/venues",
    ]);
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/admin/warmup",
      expect.objectContaining({
        method: "POST",
        credentials: "same-origin",
        body: JSON.stringify({
          routeKeys: ["topups", "wallet_audit", "readiness", "venues"],
        }),
      }),
    );

    render(
      <AdminShell session={session}>
        <div>children again</div>
      </AdminShell>,
    );

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(prefetchMock).toHaveBeenCalledTimes(4);
  });
});
