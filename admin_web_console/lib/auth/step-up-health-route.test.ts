import { beforeEach, describe, expect, it, vi } from "vitest";

const { runStepUpHealthChecksMock } = vi.hoisted(() => ({
  runStepUpHealthChecksMock: vi.fn(),
}));

vi.mock("@/lib/auth/step-up-health", () => ({
  runStepUpHealthChecks: (...args: unknown[]) =>
    runStepUpHealthChecksMock(...args),
}));

vi.mock("server-only", () => ({}));

import { GET } from "@/app/api/admin/step-up/health/route";
import { clearStepUpHealthRateLimitForTests } from "./step-up-health-rate-limit";

beforeEach(() => {
  vi.clearAllMocks();
  vi.useRealTimers();
  clearStepUpHealthRateLimitForTests();
  runStepUpHealthChecksMock.mockResolvedValue({
    status: "healthy",
    timestamp: "2026-04-30T10:00:00.000Z",
    checks: {
      secret_manager: { ok: true },
      token_signing: { ok: true },
      firestore_config: { ok: true, mode: "enabled" },
    },
  });
});

function makeRequest(ip = "192.0.2.1"): Request {
  return new Request("https://wain-admin.web.app/api/admin/step-up/health", {
    headers: {
      "x-forwarded-for": ip,
    },
  });
}

describe("step-up health route", () => {
  it("returns 200 for a healthy report without auth", async () => {
    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      status: "healthy",
      timestamp: "2026-04-30T10:00:00.000Z",
      checks: {
        secret_manager: { ok: true },
        token_signing: { ok: true },
        firestore_config: { ok: true, mode: "enabled" },
      },
    });
    expect(JSON.stringify(payload)).not.toMatch(/password|token-value|raw-key/i);
  });

  it("returns 503 for a degraded report", async () => {
    runStepUpHealthChecksMock.mockResolvedValue({
      status: "degraded",
      timestamp: "2026-04-30T10:00:00.000Z",
      checks: {
        secret_manager: { ok: false, error: "secret_unavailable" },
        token_signing: { ok: false, error: "token_roundtrip_failed" },
        firestore_config: { ok: true, mode: "enabled" },
      },
    });

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(503);
    expect(payload.status).toBe("degraded");
    expect(payload.checks.secret_manager).toEqual({
      ok: false,
      error: "secret_unavailable",
    });
  });

  it("rate limits after 60 requests per minute per IP", async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-04-30T10:00:00.000Z"));

    for (let i = 0; i < 60; i += 1) {
      const response = await GET(makeRequest("203.0.113.10"));
      expect(response.status).toBe(200);
    }

    const rateLimited = await GET(makeRequest("203.0.113.10"));
    const payload = await rateLimited.json();

    expect(rateLimited.status).toBe(429);
    expect(payload).toEqual({
      status: "rate_limited",
      timestamp: "2026-04-30T10:00:00.000Z",
      retryAt: "2026-04-30T10:01:00.000Z",
    });
  });
});
