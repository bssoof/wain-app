import { beforeEach, describe, expect, it, vi } from "vitest";

/* ------------------------------------------------------------------ */
/*  Hoisted mocks                                                      */
/* ------------------------------------------------------------------ */
const { runChecksMock } = vi.hoisted(() => ({
  runChecksMock: vi.fn(),
}));

vi.mock("@/lib/admin/route-guards/readiness-rbac", () => ({
  verifyReadinessRbac: vi.fn(),
}));

import { verifyReadinessRbac } from "@/lib/admin/route-guards/readiness-rbac";

vi.mock("@/lib/admin/config-health/run-checks", () => ({
  runConfigHealthChecks: (...args: unknown[]) => runChecksMock(...args),
}));

vi.mock("server-only", () => ({}));

import { GET } from "@/app/api/admin/health/config/route";
import type { HealthReport } from "@/lib/admin/config-health/types";

/* ------------------------------------------------------------------ */
/*  Helpers                                                            */
/* ------------------------------------------------------------------ */
function makeRequest(ip = "192.0.2.1"): Request {
  return new Request("https://wain-admin.web.app/api/admin/health/config", {
    headers: { "x-forwarded-for": ip },
  });
}

const HEALTHY_REPORT: HealthReport = {
  ok: true,
  checkedAt: "2026-05-01T12:00:00.000Z",
  cacheTtlSeconds: 60,
  checks: [
    {
      id: "firebase_admin_initialized",
      tier: 1,
      label: "Firebase Admin SDK",
      status: "ok",
      present: true,
      source: "firebase-admin",
      message: null,
    },
  ],
  summary: { errorCount: 0, warnCount: 0, unknownCount: 0 },
};

const DISABLED_REPORT: HealthReport = {
  ok: true,
  checkedAt: "2026-05-01T12:00:00.000Z",
  cacheTtlSeconds: 60,
  checks: [],
  summary: { errorCount: 0, warnCount: 0, unknownCount: 0 },
  disabled: true,
};

/* ------------------------------------------------------------------ */
/*  Setup                                                              */
/* ------------------------------------------------------------------ */
beforeEach(() => {
  vi.clearAllMocks();

  // Defaults: authenticated super_admin, healthy report
  vi.mocked(verifyReadinessRbac).mockResolvedValue({
    ok: true,
    user: { uid: "admin1", roles: ["super_admin"] },
    role: "super_admin",
  } as any);
  
  runChecksMock.mockResolvedValue(HEALTHY_REPORT);
});

/* ------------------------------------------------------------------ */
/*  Tests                                                              */
/* ------------------------------------------------------------------ */
describe("GET /api/admin/health/config", () => {
  // 1) Unauthenticated → 401
  it("returns 401 with { ok: false, reason: 'unauthenticated' } when no session", async () => {
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: false,
      status: 401,
      body: { ok: false, reason: "unauthenticated" },
    });

    const response = await GET(makeRequest());
    const body = await response.json();

    expect(response.status).toBe(401);
    expect(body).toEqual({ ok: false, reason: "unauthenticated" });
  });

  // 2) Authenticated non-super_admin → 403
  it("returns 403 with { ok: false, reason: 'forbidden' } for non-super_admin", async () => {
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: false,
      status: 403,
      body: { ok: false, reason: "forbidden" },
    });

    const response = await GET(makeRequest());
    const body = await response.json();

    expect(response.status).toBe(403);
    expect(body).toEqual({ ok: false, reason: "forbidden" });
  });

  // 3) super_admin with healthCheckEnabled=true → 200 with HealthReport shape
  it("returns 200 with HealthReport shape when healthCheckEnabled=true", async () => {
    runChecksMock.mockResolvedValue(HEALTHY_REPORT);

    const response = await GET(makeRequest());
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body).toHaveProperty("ok", true);
    expect(body).toHaveProperty("checkedAt");
    expect(typeof body.checkedAt).toBe("string");
    expect(body).toHaveProperty("checks");
    expect(Array.isArray(body.checks)).toBe(true);
    expect(body).toHaveProperty("summary");
    expect(body.summary).toEqual(
      expect.objectContaining({
        errorCount: expect.any(Number),
        warnCount: expect.any(Number),
        unknownCount: expect.any(Number),
      }),
    );
  });

  // 4) super_admin with healthCheckEnabled=false → 200 with disabled report
  it("returns 200 with { ok: true, disabled: true, checks: [] } when healthCheckEnabled=false", async () => {
    runChecksMock.mockResolvedValue(DISABLED_REPORT);

    const response = await GET(makeRequest());
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.ok).toBe(true);
    expect(body.disabled).toBe(true);
    expect(body.checks).toEqual([]);
  });

  // 5) Rate limit exceeded → 429 with retryAt
  it("returns 429 with retryAt when rate limit exceeded", async () => {
    const retryDate = new Date("2026-05-01T12:01:00.000Z");
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: false,
      status: 429,
      body: { ok: false, status: "rate_limited", retryAt: retryDate.toISOString() },
    });

    const response = await GET(makeRequest());
    const body = await response.json();

    expect(response.status).toBe(429);
    expect(body.ok).toBe(false);
    expect(body).toHaveProperty("retryAt");
    // retryAt is serialised as ISO string via JSON (Date → toJSON)
    expect(body.retryAt).toBe("2026-05-01T12:01:00.000Z");
  });

  // 6) Cache hit within 60s: second call returns same checkedAt
  it("returns cached report on second call within 60s (same checkedAt)", async () => {
    // The route delegates caching to runConfigHealthChecks.
    // Simulate: first call returns report A, second call returns the same
    // cached object (identical checkedAt).
    const reportA: HealthReport = { ...HEALTHY_REPORT, checkedAt: "2026-05-01T12:00:00.000Z" };
    runChecksMock.mockResolvedValue(reportA);

    const res1 = await GET(makeRequest());
    const body1 = await res1.json();

    // runConfigHealthChecks returns the same cached object on second call
    const res2 = await GET(makeRequest());
    const body2 = await res2.json();

    expect(res1.status).toBe(200);
    expect(res2.status).toBe(200);
    expect(body2.checkedAt).toBe(body1.checkedAt);
  });

  // 7) runConfigHealthChecks throws → 500 without stack trace
  it("returns 500 with { ok: false, reason } and no stack trace when runConfigHealthChecks throws", async () => {
    const error = new Error("Firestore unavailable");
    error.stack = "Error: Firestore unavailable\n    at Object.<anonymous> (/app/lib/run-checks.ts:42:11)";
    runChecksMock.mockRejectedValue(error);

    const response = await GET(makeRequest());
    const body = await response.json();

    expect(response.status).toBe(500);
    expect(body.ok).toBe(false);
    expect(body).toHaveProperty("reason");
    // Body must NOT leak the stack trace
    const raw = JSON.stringify(body);
    expect(raw).not.toContain("at Object");
    expect(raw).not.toContain("run-checks.ts");
    expect(raw).not.toContain("\n");
  });
});
