import { beforeEach, describe, expect, it, vi } from "vitest";

const { getStepUpEnforcementModeMock } = vi.hoisted(() => ({
  getStepUpEnforcementModeMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("./step-up-config", () => ({
  getStepUpEnforcementMode: (...args: unknown[]) =>
    getStepUpEnforcementModeMock(...args),
}));

import { runStepUpHealthChecks } from "./step-up-health";

const NOW = new Date("2026-04-30T10:00:00.000Z");
const STRONG_KEY = Buffer.from("x".repeat(64), "utf8");

beforeEach(() => {
  vi.clearAllMocks();
  getStepUpEnforcementModeMock.mockResolvedValue("enabled");
});

describe("step-up health checks", () => {
  it("returns healthy when secret, token roundtrip, and Firestore config pass", async () => {
    const report = await runStepUpHealthChecks({
      now: () => NOW,
      resolveSigningKey: async () => STRONG_KEY,
    });

    expect(report).toEqual({
      status: "healthy",
      timestamp: "2026-04-30T10:00:00.000Z",
      checks: {
        secret_manager: { ok: true },
        token_signing: { ok: true },
        firestore_config: { ok: true, mode: "enabled" },
      },
    });
    expect(JSON.stringify(report)).not.toContain("xxxxxxxx");
  });

  it("returns degraded when the signing key cannot be read", async () => {
    const report = await runStepUpHealthChecks({
      now: () => NOW,
      resolveSigningKey: async () => {
        throw new Error("secret unavailable");
      },
    });

    expect(report.status).toBe("degraded");
    expect(report.checks.secret_manager).toEqual({
      ok: false,
      error: "secret_unavailable",
    });
    expect(report.checks.token_signing).toEqual({
      ok: false,
      error: "token_roundtrip_failed",
    });
  });

  it("returns degraded when the signing key is too short", async () => {
    const report = await runStepUpHealthChecks({
      now: () => NOW,
      resolveSigningKey: async () => Buffer.from("short", "utf8"),
    });

    expect(report.status).toBe("degraded");
    expect(report.checks.secret_manager).toEqual({
      ok: false,
      error: "signing_key_too_short",
    });
  });

  it("returns degraded when Firestore config read fails", async () => {
    getStepUpEnforcementModeMock.mockImplementation(async (options: any) => {
      options?.onReadError?.(new Error("firestore unavailable"));
      return "enabled";
    });

    const report = await runStepUpHealthChecks({
      now: () => NOW,
      resolveSigningKey: async () => STRONG_KEY,
    });

    expect(report.status).toBe("degraded");
    expect(report.checks.firestore_config).toEqual({
      ok: false,
      error: "firestore_config_unavailable",
    });
  });

  it("times out slow checks", async () => {
    const report = await runStepUpHealthChecks({
      now: () => NOW,
      timeoutMs: 5,
      resolveSigningKey: () =>
        new Promise((resolve) => {
          setTimeout(() => resolve(STRONG_KEY), 50);
        }),
    });

    expect(report.status).toBe("degraded");
    expect(report.checks.secret_manager).toEqual({
      ok: false,
      error: "secret_manager_timeout",
    });
    expect(report.checks.token_signing).toEqual({
      ok: false,
      error: "token_signing_timeout",
    });
  });
});
