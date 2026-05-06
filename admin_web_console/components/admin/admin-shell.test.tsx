import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import type { ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const {
  adminHeaderMock,
  adminSidebarMock,
  fetchMock,
  prefetchMock,
  routerPushMock,
  usePathnameMock,
} = vi.hoisted(() => ({
  adminHeaderMock: vi.fn(),
  adminSidebarMock: vi.fn(),
  fetchMock: vi.fn(),
  prefetchMock: vi.fn(),
  routerPushMock: vi.fn(),
  usePathnameMock: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  usePathname: () => usePathnameMock(),
  useRouter: () => ({
    prefetch: prefetchMock,
    push: routerPushMock,
  }),
}));

vi.mock("@/components/admin/admin-header", () => ({
  AdminHeader: (props: {
    breadcrumb?: Array<{ label: string; href?: string }>;
    environment?: string;
    onMenuClick?: () => void;
    onQuickNavigate?: (path: string) => void;
    session: unknown;
  }) => {
    adminHeaderMock(props);
    return (
      <header data-testid="admin-header">
        <button
          type="button"
          onClick={props.onMenuClick}
          disabled={!props.onMenuClick}
        >
          menu
        </button>
        <button type="button" onClick={() => props.onQuickNavigate?.("/admin/topups")}>
          quick navigate
        </button>
        <span data-testid="environment">{props.environment}</span>
        <span data-testid="breadcrumb">
          {(props.breadcrumb ?? [])
            .map((item) => `${item.label}:${item.href ?? "current"}`)
            .join("|")}
        </span>
      </header>
    );
  },
}));

vi.mock("@/components/admin/admin-sidebar", () => ({
  AdminSidebar: (props: {
    mode?: string;
    onModeChange?: (mode: "expanded" | "compact") => void;
    onOpenChange?: (open: boolean) => void;
    open?: boolean;
    session: unknown;
  }) => {
    adminSidebarMock(props);
    return (
      <aside data-mode={props.mode} data-open={String(props.open)} data-testid="admin-sidebar">
        <button type="button" onClick={() => props.onModeChange?.("compact")}>
          compact
        </button>
        <button type="button" onClick={() => props.onOpenChange?.(true)}>
          open drawer
        </button>
      </aside>
    );
  },
}));

vi.mock("@/components/admin/admin-banner", () => ({
  AdminBanner: () => <div data-testid="admin-banner" />,
}));

vi.mock("@/components/shared/ui/toast", () => ({
  ToastViewport: () => <div data-testid="toast-viewport" />,
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

function renderShell(children: ReactNode = <div>children</div>) {
  return render(<AdminShell session={mustBuildSuperAdminSession()}>{children}</AdminShell>);
}

function latestSidebarProps() {
  return adminSidebarMock.mock.calls.at(-1)?.[0] as
    | { mode: string; open: boolean }
    | undefined;
}

function latestHeaderProps() {
  return adminHeaderMock.mock.calls.at(-1)?.[0] as
    | {
        breadcrumb: Array<{ label: string; href?: string }>;
        environment: string;
        onMenuClick?: () => void;
      }
    | undefined;
}

function mockMatchMedia(matches: boolean) {
  Object.defineProperty(window, "matchMedia", {
    configurable: true,
    value: vi.fn().mockReturnValue({
      matches,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }),
  });
}

function setHostname(hostname: string) {
  Object.defineProperty(window, "location", {
    configurable: true,
    value: {
      ...window.location,
      hostname,
    },
  });
}

beforeEach(() => {
  vi.clearAllMocks();
  window.localStorage.clear();
  window.sessionStorage.clear();
  mockMatchMedia(false);
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
    renderShell();

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

    renderShell(<div>children again</div>);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(prefetchMock).toHaveBeenCalledTimes(4);
  });
});

describe("AdminShell Phase 2 wiring", () => {
  it("renders with default expanded sidebar mode", () => {
    renderShell();

    expect(latestSidebarProps()?.mode).toBe("expanded");
    expect(screen.getByTestId("toast-viewport")).not.toBeNull();
  });

  it("persists sidebar mode changes to localStorage", async () => {
    renderShell();

    fireEvent.click(screen.getByRole("button", { name: "compact" }));

    await waitFor(() => {
      expect(window.localStorage.getItem("wain.admin.sidebarMode")).toBe("compact");
    });
    expect(latestSidebarProps()?.mode).toBe("compact");
  });

  it("reads sidebar mode from localStorage on mount", () => {
    window.localStorage.setItem("wain.admin.sidebarMode", "compact");

    renderShell();

    expect(latestSidebarProps()?.mode).toBe("compact");
  });

  it("computes breadcrumb for nested routes", () => {
    usePathnameMock.mockReturnValue("/admin/venues/venue-123");

    renderShell();

    expect(screen.getByTestId("breadcrumb").textContent).toBe(
      "الإدارة:/admin|الجهات:/admin/venues|venue-123:current",
    );
  });

  it("detects production environment from hostname", async () => {
    setHostname("wain-admin.web.app");

    renderShell();

    await waitFor(() => {
      expect(latestHeaderProps()?.environment).toBe("production");
    });
  });

  it("detects preview environment from hostname", async () => {
    setHostname("wain-admin--preview.web.app");

    renderShell();

    await waitFor(() => {
      expect(latestHeaderProps()?.environment).toBe("preview");
    });
  });

  it("detects local environment from hostname", async () => {
    setHostname("localhost");

    renderShell();

    await waitFor(() => {
      expect(latestHeaderProps()?.environment).toBe("local");
    });
  });

  it("forces drawer mode on mobile viewport", async () => {
    mockMatchMedia(true);

    renderShell();

    await waitFor(() => {
      expect(latestSidebarProps()?.mode).toBe("drawer");
    });
    expect(latestHeaderProps()?.onMenuClick).toEqual(expect.any(Function));
  });

  it("closes drawer on pathname change", async () => {
    mockMatchMedia(true);
    const { rerender } = render(
      <AdminShell session={mustBuildSuperAdminSession()}>
        <div>children</div>
      </AdminShell>,
    );

    await waitFor(() => expect(latestSidebarProps()?.mode).toBe("drawer"));
    fireEvent.click(screen.getByRole("button", { name: "menu" }));
    await waitFor(() => expect(latestSidebarProps()?.open).toBe(true));

    usePathnameMock.mockReturnValue("/admin/topups");
    rerender(
      <AdminShell session={mustBuildSuperAdminSession()}>
        <div>children</div>
      </AdminShell>,
    );

    await waitFor(() => expect(latestSidebarProps()?.open).toBe(false));
  });
});
