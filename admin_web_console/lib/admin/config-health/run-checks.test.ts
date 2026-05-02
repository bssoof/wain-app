import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { runConfigHealthChecks, clearHealthCache } from "./run-checks";
import { adminDb } from "@/lib/firebase/server";

vi.mock("@/lib/firebase/server", () => {
  return {
    adminDb: {
      collection: vi.fn().mockReturnThis(),
      doc: vi.fn().mockReturnThis(),
      get: vi.fn().mockResolvedValue({
        exists: true,
        data: () => ({ healthCheckEnabled: true }),
      }),
    },
    getAdminApp: vi.fn().mockReturnValue({}),
  };
});

vi.mock("@/lib/auth/step-up-token", () => ({
  resolveStepUpSigningKey: vi.fn().mockResolvedValue(Buffer.from("mock-key")),
}));

vi.mock("@/lib/auth/step-up-config", () => ({
  getStepUpEnforcementMode: vi.fn().mockResolvedValue("enabled"),
}));

describe("Config Health runChecks", () => {
  beforeEach(() => {
    clearHealthCache();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("returns disabled payload if flag is off", async () => {
    vi.mocked(adminDb.doc("admin_console").get).mockResolvedValueOnce({
      exists: true,
      data: () => ({ healthCheckEnabled: false }),
    } as any);

    const report = await runConfigHealthChecks();
    expect(report.disabled).toBe(true);
    expect(report.ok).toBe(true);
    expect(report.checks.length).toBe(0);
  });

  it("returns full ok payload if all checks pass", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL", "https://finance.example.com");
    vi.stubEnv("NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL", "https://venue.example.com");
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL", "https://content.example.com");
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL", "https://config.example.com");
    vi.stubEnv("WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION", "v1");

    const report = await runConfigHealthChecks();
    expect(report.disabled).toBeUndefined();
    expect(report.ok).toBe(true);
    expect(report.summary.errorCount).toBe(0);
    // BuildID missing would be unknown, DeployChannel unknown, these don't fail `ok`.
  });

  it("sets ok=false if a Tier 1 check fails", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL", ""); // Empty causes error
    vi.stubEnv("NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL", "https://venue.example.com");
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL", "https://content.example.com");
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL", "https://config.example.com");

    const report = await runConfigHealthChecks();
    expect(report.ok).toBe(false);
    expect(report.summary.errorCount).toBeGreaterThan(0);
    
    const financeCheck = report.checks.find(c => c.id === "finance_functions_base_url");
    expect(financeCheck?.status).toBe("error");
  });
});
