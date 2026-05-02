import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { AdminBanner } from "./admin-banner";
import type { HealthReport } from "@/lib/admin/config-health/types";

/* ------------------------------------------------------------------ */
/*  Helpers                                                           */
/* ------------------------------------------------------------------ */

function makeBannerPayload(
  overrides: {
    bannerMessage?: string;
    bannerSeverity?: string;
    configHealth?: Partial<HealthReport>;
  } = {},
) {
  return {
    success: true,
    bannerMessage: overrides.bannerMessage ?? "Test banner message",
    bannerSeverity: overrides.bannerSeverity ?? "info",
    ...(overrides.configHealth !== undefined
      ? { configHealth: overrides.configHealth }
      : {}),
  };
}

function healthReport(opts: {
  ok?: boolean;
  errorCount?: number;
  warnCount?: number;
  unknownCount?: number;
  checks?: HealthReport["checks"];
}): HealthReport {
  return {
    ok: opts.ok ?? true,
    checkedAt: new Date().toISOString(),
    cacheTtlSeconds: 60,
    checks: opts.checks ?? [],
    summary: {
      errorCount: opts.errorCount ?? 0,
      warnCount: opts.warnCount ?? 0,
      unknownCount: opts.unknownCount ?? 0,
    },
  };
}

/* ------------------------------------------------------------------ */
/*  Setup / Teardown                                                  */
/* ------------------------------------------------------------------ */

let fetchMock: ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.useFakeTimers({ shouldAdvanceTime: true });
  fetchMock = vi.fn();
  vi.stubGlobal("fetch", fetchMock);

  // sessionStorage stub (jsdom provides it, but reset between tests)
  sessionStorage.clear();
});

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

function mockFetchResponse(payload: unknown, ok = true) {
  fetchMock.mockResolvedValue({
    ok,
    json: async () => payload,
  });
}

/* ------------------------------------------------------------------ */
/*  Tests                                                             */
/* ------------------------------------------------------------------ */

describe("AdminBanner – configHealth integration", () => {
  it("1) configHealth.ok=true with all checks status=ok keeps original banner severity unchanged", async () => {
    const payload = makeBannerPayload({
      bannerMessage: "Step-up log_only active",
      bannerSeverity: "info",
      configHealth: healthReport({
        ok: true,
        errorCount: 0,
        warnCount: 0,
        unknownCount: 0,
        checks: [
          {
            id: "finance_functions_base_url",
            tier: 1,
            label: "Finance Functions Base URL",
            status: "ok",
            present: true,
            source: "env",
            message: null,
          },
        ],
      }),
    });
    mockFetchResponse(payload);

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner).toBeDefined();
    // Severity class should remain "info" (the original)
    expect(banner.className).toContain("admin-step-up-banner--info");
    expect(banner.textContent).toContain("Step-up log_only active");
  });

  it("2) configHealth.summary.errorCount > 0 escalates banner severity to 'critical' even if original was 'info'", async () => {
    const payload = makeBannerPayload({
      bannerMessage: "Informational notice",
      bannerSeverity: "info",
      configHealth: healthReport({
        ok: false,
        errorCount: 1,
        warnCount: 0,
        unknownCount: 0,
        checks: [
          {
            id: "finance_functions_base_url",
            tier: 1,
            label: "Finance Functions Base URL",
            status: "error",
            present: false,
            source: "env",
            message: "عنوان خدمة المالية غير مُعرّف",
          },
        ],
      }),
    });
    mockFetchResponse(payload);

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner.className).toContain("admin-step-up-banner--critical");
  });

  it("3) configHealth.summary.warnCount > 0 with original 'info' severity escalates to 'warning'", async () => {
    const payload = makeBannerPayload({
      bannerMessage: "Some info",
      bannerSeverity: "info",
      configHealth: healthReport({
        ok: true,
        errorCount: 0,
        warnCount: 1,
        unknownCount: 0,
        checks: [
          {
            id: "step_up_signing_key_present",
            tier: 2,
            label: "Step-Up Signing Key",
            status: "warn",
            present: false,
            source: "secret_manager",
            message: "مفتاح التوقيع غير موجود",
          },
        ],
      }),
    });
    mockFetchResponse(payload);

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner.className).toContain("admin-step-up-banner--warning");
  });

  it("4) configHealth.summary.warnCount > 0 with original 'critical' severity stays 'critical'", async () => {
    const payload = makeBannerPayload({
      bannerMessage: "Critical system alert",
      bannerSeverity: "critical",
      configHealth: healthReport({
        ok: true,
        errorCount: 0,
        warnCount: 2,
        unknownCount: 0,
        checks: [
          {
            id: "step_up_signing_key_present",
            tier: 2,
            label: "Step-Up Signing Key",
            status: "warn",
            present: false,
            source: "secret_manager",
            message: "مفتاح التوقيع غير موجود",
          },
          {
            id: "step_up_previous_key_present",
            tier: 2,
            label: "Step-Up Previous Key",
            status: "warn",
            present: false,
            source: "secret_manager",
            message: "المفتاح السابق غير موجود",
          },
        ],
      }),
    });
    mockFetchResponse(payload);

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    expect(banner.className).toContain("admin-step-up-banner--critical");
    // Must NOT have downgraded to warning
    expect(banner.className).not.toContain("admin-step-up-banner--warning");
  });

  it("5a) Bad-check messages prefix the existing bannerMessage joined by ' | '", async () => {
    const payload = makeBannerPayload({
      bannerMessage: "Original notice",
      bannerSeverity: "info",
      configHealth: healthReport({
        ok: false,
        errorCount: 2,
        warnCount: 0,
        unknownCount: 0,
        checks: [
          {
            id: "finance_functions_base_url",
            tier: 1,
            label: "Finance Functions Base URL",
            status: "error",
            present: false,
            source: "env",
            message: "خطأ أول",
          },
          {
            id: "venue_functions_base_url",
            tier: 1,
            label: "Venue Functions Base URL",
            status: "error",
            present: false,
            source: "env",
            message: "خطأ ثاني",
          },
        ],
      }),
    });
    mockFetchResponse(payload);

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    const text = banner.textContent ?? "";
    // Bad-check messages joined by " | " come first
    expect(text).toContain("خطأ أول | خطأ ثاني");
    // Original message is also present (appended after newline)
    expect(text).toContain("Original notice");
  });

  it("5b) If no original bannerMessage, only the joined check messages appear", async () => {
    const payload = makeBannerPayload({
      bannerMessage: "",
      bannerSeverity: "info",
      configHealth: healthReport({
        ok: false,
        errorCount: 1,
        warnCount: 0,
        unknownCount: 0,
        checks: [
          {
            id: "finance_functions_base_url",
            tier: 1,
            label: "Finance Functions Base URL",
            status: "error",
            present: false,
            source: "env",
            message: "عنوان خدمة المالية غير مُعرّف",
          },
          {
            id: "venue_functions_base_url",
            tier: 1,
            label: "Venue Functions Base URL",
            status: "ok",
            present: true,
            source: "env",
            message: null,
          },
        ],
      }),
    });
    mockFetchResponse(payload);

    render(<AdminBanner />);

    const banner = await screen.findByTestId("admin-step-up-banner");
    const text = banner.textContent ?? "";
    expect(text).toContain("عنوان خدمة المالية غير مُعرّف");
    // No " | " since only one bad check has a message
    expect(text).not.toContain(" | ");
  });
});
