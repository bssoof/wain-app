import { act, fireEvent, render, screen } from "@testing-library/react";
import type { AnchorHTMLAttributes, ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { prefetchMock, usePathnameMock } = vi.hoisted(() => ({
  prefetchMock: vi.fn(),
  usePathnameMock: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  usePathname: () => usePathnameMock(),
  useRouter: () => ({
    prefetch: prefetchMock,
  }),
}));

vi.mock("next/link", () => ({
  default: ({
    href,
    children,
    prefetch: _prefetch,
    ...props
  }: AnchorHTMLAttributes<HTMLAnchorElement> & {
    href: string;
    children: ReactNode;
    prefetch?: boolean;
  }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}));

import { AdminSidebar } from "@/components/admin/admin-sidebar";
import { buildAdminSession, type AdminSession } from "@/lib/auth/guard-api";
import {
  getVisibleNavigationRoutes,
} from "@/lib/navigation/admin-route-map";

function session(): AdminSession {
  const built = buildAdminSession({
    uid: "admin-1",
    email: "admin@wain.app",
    displayName: "Admin",
    claims: { role: "super_admin" },
  });

  if (!built) {
    throw new Error("Expected a super admin session");
  }

  return built;
}

function visibleRoutes() {
  return getVisibleNavigationRoutes(session());
}

beforeEach(() => {
  vi.clearAllMocks();
  usePathnameMock.mockReturnValue("/admin/dashboard");
  Object.defineProperty(window, "matchMedia", {
    configurable: true,
    value: vi.fn().mockReturnValue({
      matches: false,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }),
  });
});

afterEach(() => {
  vi.useRealTimers();
});

describe("AdminSidebar", () => {
  it("renders all routes visible to the current admin session", () => {
    render(<AdminSidebar session={session()} />);

    const links = screen.getAllByRole("link");

    expect(links).toHaveLength(visibleRoutes().length);
    for (const route of visibleRoutes()) {
      expect(screen.getByRole("link", { name: route.title })).not.toBeNull();
    }
  });

  it("renders one route icon for every visible route", () => {
    const { container } = render(<AdminSidebar session={session()} />);

    const icons = container.querySelectorAll("[data-testid^='admin-sidebar-icon-']");

    expect(icons).toHaveLength(visibleRoutes().length);
  });

  it("marks the active route with aria-current and the active class", () => {
    usePathnameMock.mockReturnValue("/admin/topups");

    render(<AdminSidebar session={session()} />);

    const activeLink = screen.getByRole("link", { name: "طلبات الشحن" });

    expect(activeLink.getAttribute("aria-current")).toBe("page");
    expect(activeLink.className).toContain("admin-sidebar__item--active");
  });

  it("hides route label text from assistive tech in compact mode while keeping link names", () => {
    const { container } = render(<AdminSidebar mode="compact" session={session()} />);

    const sidebar = container.querySelector(".admin-sidebar");
    const firstLabel = container.querySelector(".admin-sidebar__item-label");

    expect(sidebar?.className).toContain("admin-sidebar--compact");
    expect(firstLabel?.getAttribute("aria-hidden")).toBe("true");
    expect(screen.getByRole("link", { name: "نظرة عامة" })).not.toBeNull();
  });

  it("shows compact-mode route tooltips after hover delay", () => {
    vi.useFakeTimers();
    render(<AdminSidebar mode="compact" session={session()} />);

    const tooltip = screen.getAllByRole("tooltip")[0];

    expect(tooltip.getAttribute("data-visible")).toBe("false");
    fireEvent.mouseEnter(tooltip.parentElement!);
    act(() => {
      vi.advanceTimersByTime(400);
    });

    expect(tooltip.getAttribute("data-visible")).toBe("true");
  });

  it("asks to compact the sidebar from expanded mode", () => {
    const onModeChange = vi.fn();
    render(<AdminSidebar onModeChange={onModeChange} session={session()} />);

    fireEvent.click(screen.getByRole("button", { name: "طي القائمة الجانبية" }));

    expect(onModeChange).toHaveBeenCalledWith("compact");
  });

  it("asks to expand the sidebar from compact mode", () => {
    const onModeChange = vi.fn();
    render(
      <AdminSidebar mode="compact" onModeChange={onModeChange} session={session()} />,
    );

    fireEvent.click(screen.getByRole("button", { name: "توسيع القائمة الجانبية" }));

    expect(onModeChange).toHaveBeenCalledWith("expanded");
  });

  it("renders drawer mode as a modal dialog with a dismissable backdrop", () => {
    const onOpenChange = vi.fn();
    const { container } = render(
      <AdminSidebar mode="drawer" onOpenChange={onOpenChange} open session={session()} />,
    );

    const dialog = screen.getByRole("dialog", { name: "القائمة الجانبية" });
    const backdrop = container.querySelector(".admin-sidebar-drawer-backdrop");

    expect(dialog.getAttribute("aria-modal")).toBe("true");
    expect(backdrop).not.toBeNull();
    fireEvent.click(backdrop!);
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it("dismisses drawer mode on Escape", () => {
    const onOpenChange = vi.fn();
    render(
      <AdminSidebar mode="drawer" onOpenChange={onOpenChange} open session={session()} />,
    );

    fireEvent.keyDown(window, { key: "Escape" });

    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it("renders nothing for a closed drawer", () => {
    render(<AdminSidebar mode="drawer" open={false} session={session()} />);

    expect(screen.queryByRole("navigation", { name: "تنقل الإدارة" })).toBeNull();
    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("does not expose aria-modal outside drawer mode", () => {
    const { container } = render(<AdminSidebar session={session()} />);

    const sidebar = container.querySelector("aside");

    expect(screen.queryByRole("dialog")).toBeNull();
    expect(sidebar?.getAttribute("aria-modal")).toBeNull();
  });

  it("keeps hover-intent prefetch behavior for eligible routes", () => {
    vi.useFakeTimers();
    render(<AdminSidebar session={session()} />);

    fireEvent.pointerEnter(screen.getByRole("link", { name: "الصور والملفات" }));
    act(() => {
      vi.advanceTimersByTime(120);
    });

    expect(prefetchMock).toHaveBeenCalledWith("/admin/media");
  });
});
