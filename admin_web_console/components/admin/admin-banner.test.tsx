import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

type MockBannerConfig = {
  bannerMessage: string | null;
  bannerSeverity?: "info" | "warning" | "critical";
};

const { firestoreDocMock, getDocMock, setBannerConfig } = vi.hoisted(() => {
  let currentBannerConfig: MockBannerConfig | null = null;

  return {
    firestoreDocMock: vi.fn(() => ({ id: "admin_step_up" })),
    getDocMock: vi.fn(async () => ({
      exists: () => currentBannerConfig !== null,
      data: () => currentBannerConfig,
    })),
    setBannerConfig: (nextConfig: MockBannerConfig | null) => {
      currentBannerConfig = nextConfig;
    },
  };
});

vi.mock("@/lib/firebase/client", () => ({
  app: {},
}));

vi.mock("firebase/firestore", () => ({
  getFirestore: vi.fn(() => ({ mock: "db" })),
  doc: firestoreDocMock,
  getDoc: getDocMock,
}));

import { AdminBanner } from "@/components/admin/admin-banner";

beforeEach(() => {
  vi.clearAllMocks();
  window.sessionStorage.clear();
  setBannerConfig({
    bannerMessage: "تنبيه اختبار",
    bannerSeverity: "info",
  });
});

describe("AdminBanner", () => {
  it("renders when bannerMessage is present", async () => {
    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner).toBeTruthy();
    expect(banner.textContent).toContain("تنبيه اختبار");
  });

  it("hides when bannerMessage is null", async () => {
    setBannerConfig({ bannerMessage: null, bannerSeverity: "warning" });

    render(<AdminBanner />);

    await waitFor(() => {
      expect(getDocMock).toHaveBeenCalledTimes(1);
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
      expect(getDocMock).toHaveBeenCalledTimes(2);
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

    setBannerConfig({
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
    setBannerConfig({
      bannerMessage: "حرج",
      bannerSeverity: "critical",
    });

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner.classList.contains("admin-step-up-banner--critical")).toBe(true);
  });
});

function findDismissStorageKey(): string | null {
  for (let i = 0; i < window.sessionStorage.length; i += 1) {
    const key = window.sessionStorage.key(i);
    if (key?.startsWith("wain_admin_step_up_banner_dismissed:")) {
      return key;
    }
  }

  return null;
}