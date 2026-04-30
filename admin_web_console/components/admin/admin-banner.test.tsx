import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

type MockBannerResponse = {
  success: boolean;
  bannerMessage?: string | null;
  bannerSeverity?: "info" | "warning" | "critical";
};

const fetchMock = vi.fn();

beforeEach(() => {
  vi.clearAllMocks();
  window.sessionStorage.clear();
  vi.stubGlobal("fetch", fetchMock);
  mockBannerResponse({
    success: true,
    bannerMessage: "تنبيه اختبار",
    bannerSeverity: "info",
  });
});

import { AdminBanner } from "@/components/admin/admin-banner";

describe("AdminBanner", () => {
  it("renders when bannerMessage is present", async () => {
    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner).toBeTruthy();
    expect(banner.textContent).toContain("تنبيه اختبار");
    expect(fetchMock).toHaveBeenCalledWith("/api/admin/step-up/banner", {
      cache: "no-store",
      credentials: "include",
    });
  });

  it("hides when bannerMessage is null", async () => {
    mockBannerResponse({
      success: true,
      bannerMessage: null,
      bannerSeverity: "warning",
    });

    render(<AdminBanner />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });
    expect(screen.queryByTestId("admin-step-up-banner")).toBeNull();
  });

  it("dismisses and stores state in sessionStorage", async () => {
    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner).toBeTruthy();

    fireEvent.click(screen.getByRole("button", { name: "إخفاء" }));

    await waitFor(() => {
      expect(screen.queryByTestId("admin-step-up-banner")).toBeNull();
    });

    const storedDismissKey = findDismissStorageKey();
    expect(storedDismissKey).toBeTruthy();
    expect(window.sessionStorage.getItem(storedDismissKey as string)).toBe("1");
  });

  it("stays hidden after remount for the same dismissed message", async () => {
    const { unmount } = render(<AdminBanner />);
    await screen.findByTestId("admin-step-up-banner");

    fireEvent.click(screen.getByRole("button", { name: "إخفاء" }));
    await waitFor(() => {
      expect(screen.queryByTestId("admin-step-up-banner")).toBeNull();
    });

    unmount();
    render(<AdminBanner />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledTimes(2);
    });
    expect(screen.queryByTestId("admin-step-up-banner")).toBeNull();
  });

  it("shows again when message hash changes", async () => {
    const { unmount } = render(<AdminBanner />);
    await screen.findByTestId("admin-step-up-banner");

    fireEvent.click(screen.getByRole("button", { name: "إخفاء" }));
    await waitFor(() => {
      expect(screen.queryByTestId("admin-step-up-banner")).toBeNull();
    });

    mockBannerResponse({
      success: true,
      bannerMessage: "رسالة جديدة",
      bannerSeverity: "warning",
    });

    unmount();
    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner).toBeTruthy();
    expect(banner.textContent).toContain("رسالة جديدة");
  });

  it("applies severity class mapping", async () => {
    mockBannerResponse({
      success: true,
      bannerMessage: "حرج",
      bannerSeverity: "critical",
    });

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner.classList.contains("admin-step-up-banner--critical")).toBe(true);
  });
});

function mockBannerResponse(payload: MockBannerResponse): void {
  fetchMock.mockResolvedValue({
    ok: payload.success,
    json: async () => payload,
  });
}

function findDismissStorageKey(): string | null {
  for (let i = 0; i < window.sessionStorage.length; i += 1) {
    const key = window.sessionStorage.key(i);
    if (key?.startsWith("wain_admin_step_up_banner_dismissed:")) {
      return key;
    }
  }

  return null;
}
