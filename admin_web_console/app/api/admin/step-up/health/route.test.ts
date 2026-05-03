import { describe, it, expect, vi, beforeEach } from "vitest";
import { GET } from "./route";
import { runStepUpHealthChecks } from "@/lib/auth/step-up-health";
import { verifyReadinessRbac } from "@/lib/admin/route-guards/readiness-rbac";

vi.mock("@/lib/auth/step-up-health", () => ({
  runStepUpHealthChecks: vi.fn(),
}));

vi.mock("@/lib/admin/route-guards/readiness-rbac", () => ({
  verifyReadinessRbac: vi.fn(),
}));

describe("GET /api/admin/step-up/health", () => {
  const mockRequest = new Request("http://localhost/api/admin/step-up/health", {
    method: "GET",
    headers: new Headers({
      "x-forwarded-for": "127.0.0.1",
    }),
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // I1: super_admin → 200 + payload
  it("returns 200 and health payload when user is super_admin", async () => {
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: true,
      user: { uid: "user-1" },
      role: "super_admin",
    });

    vi.mocked(runStepUpHealthChecks).mockResolvedValueOnce({
      status: "healthy",
      details: "test",
    } as any);

    const response = await GET(mockRequest);
    const json = await response.json();

    expect(response.status).toBe(200);
    expect(json).toEqual({
      status: "healthy",
      details: "test",
    });
    expect(verifyReadinessRbac).toHaveBeenCalledWith(
      mockRequest,
      expect.objectContaining({
        endpoint: "/api/admin/step-up/health",
        allowedRoles: ["super_admin"],
      })
    );
  });

  // I2: non-super_admin → 403 + {ok: false, reason: "forbidden"}
  it("returns 403 and forbidden reason when user is not super_admin", async () => {
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: false,
      status: 403,
      body: { ok: false, reason: "forbidden" },
    });

    const response = await GET(mockRequest);
    const json = await response.json();

    expect(response.status).toBe(403);
    expect(json).toEqual({ ok: false, reason: "forbidden" });
    expect(runStepUpHealthChecks).not.toHaveBeenCalled();
  });

  // I3: no session → 401 + {ok: false, reason: "unauthenticated"}
  it("returns 401 and unauthenticated reason when there is no session", async () => {
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: false,
      status: 401,
      body: { ok: false, reason: "unauthenticated" },
    });

    const response = await GET(mockRequest);
    const json = await response.json();

    expect(response.status).toBe(401);
    expect(json).toEqual({ ok: false, reason: "unauthenticated" });
    expect(runStepUpHealthChecks).not.toHaveBeenCalled();
  });

  // I4: rate limit exhaustion
  it("returns 429 when rate limit is exceeded", async () => {
    vi.mocked(verifyReadinessRbac).mockResolvedValueOnce({
      ok: false,
      status: 429,
      body: { ok: false, status: "rate_limited", retryAt: new Date().toISOString() },
    });

    const response = await GET(mockRequest);
    const json = await response.json();

    expect(response.status).toBe(429);
    expect(json.ok).toBe(false);
    expect(json.status).toBe("rate_limited");
    expect(runStepUpHealthChecks).not.toHaveBeenCalled();
  });
});
