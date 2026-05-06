import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";

import { AdminHeader } from "./admin-header";

const mocks = vi.hoisted(() => ({
  routerPush: vi.fn(),
  signOut: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: mocks.routerPush,
  }),
}));

vi.mock("firebase/auth", () => ({
  signOut: mocks.signOut,
}));

vi.mock("@/lib/firebase/client", () => ({
  auth: {
    currentUser: null,
  },
}));

beforeEach(() => {
  vi.clearAllMocks();
  vi.unstubAllGlobals();
});

function session(overrides: Partial<AdminSession> = {}): AdminSession {
  return {
    uid: "admin-1",
    displayName: "Local Admin",
    primaryRole: "super_admin",
    roles: ["super_admin"],
    roleSource: "claims",
    ...overrides,
  };
}

describe("AdminHeader", () => {
  it("localizes the local development admin display name", () => {
    render(<AdminHeader session={session()} />);

    expect(screen.getByText(/مسؤول محلي/i)).toBeTruthy();
    expect(screen.queryByText(/Local Admin/i)).toBeNull();
  });

  it("keeps email visible when no display name is available", () => {
    render(
      <AdminHeader
        session={session({
          displayName: undefined,
          email: "admin@wain.app",
        })}
      />,
    );

    expect(screen.getByText(/admin@wain.app/i)).toBeTruthy();
  });

  it("renders breadcrumb from additive prop", () => {
    render(
      <AdminHeader
        session={session()}
        breadcrumb={[
          { label: "الرئيسية", href: "/admin" },
          { label: "طلبات الشحن" },
        ]}
      />,
    );

    expect(screen.getByRole("navigation", { name: "مسار الصفحات" })).toBeTruthy();
    expect(screen.getByRole("link", { name: "الرئيسية" }).getAttribute("href")).toBe(
      "/admin",
    );
    expect(screen.getByText("طلبات الشحن").getAttribute("aria-current")).toBe("page");
  });

  it("renders the unknown environment by default", () => {
    render(<AdminHeader session={session()} />);

    expect(screen.getByText("غير محدد").className).toContain(
      "header-env-badge--unknown",
    );
  });

  it("renders explicit environment", () => {
    render(<AdminHeader session={session()} environment="production" />);

    expect(screen.getByText("إنتاج").className).toContain(
      "header-env-badge--production",
    );
  });

  it("renders a mobile menu trigger only when onMenuClick is provided", () => {
    const onMenuClick = vi.fn();
    const { rerender } = render(<AdminHeader session={session()} />);

    expect(
      screen.queryByRole("button", { name: "فتح القائمة الجانبية" }),
    ).toBeNull();

    rerender(
      <AdminHeader
        session={session()}
        menuControls="admin-sidebar-drawer"
        menuExpanded={false}
        onMenuClick={onMenuClick}
      />,
    );
    const trigger = screen.getByRole("button", { name: "فتح القائمة الجانبية" });

    expect(trigger.getAttribute("aria-controls")).toBe("admin-sidebar-drawer");
    expect(trigger.getAttribute("aria-expanded")).toBe("false");

    fireEvent.click(trigger);

    expect(onMenuClick).toHaveBeenCalledTimes(1);
  });

  it("uses onQuickNavigate when selecting a quick search result", () => {
    const onQuickNavigate = vi.fn();
    render(<AdminHeader session={session()} onQuickNavigate={onQuickNavigate} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.change(screen.getByRole("searchbox"), {
      target: { value: "topups" },
    });
    fireEvent.keyDown(screen.getByRole("searchbox"), { key: "Enter" });

    expect(onQuickNavigate).toHaveBeenCalledWith("/admin/topups");
    expect(mocks.routerPush).not.toHaveBeenCalled();
  });

  it("defaults quick search navigation to router.push", () => {
    render(<AdminHeader session={session()} />);

    fireEvent.click(screen.getByRole("button", { name: "بحث" }));
    fireEvent.change(screen.getByRole("searchbox"), {
      target: { value: "venues" },
    });
    fireEvent.keyDown(screen.getByRole("searchbox"), { key: "Enter" });

    expect(mocks.routerPush).toHaveBeenCalledWith("/admin/venues");
  });

  it("preserves sign-out behavior from the user menu", async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal("fetch", fetchMock);

    render(<AdminHeader session={session()} />);

    fireEvent.click(screen.getByRole("button", { name: /مسؤول محلي/i }));
    fireEvent.click(screen.getByRole("menuitem", { name: "تسجيل الخروج" }));

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith("/api/admin/session", {
        method: "DELETE",
      });
      expect(mocks.routerPush).toHaveBeenCalledWith("/admin/sign-in");
    });
  });
});
