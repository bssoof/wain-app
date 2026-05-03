import { describe, it, expect, vi, beforeEach } from "vitest";
import { verifyReadinessRbac } from "./readiness-rbac";
import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { adminDb } from "@/lib/firebase/server";
import { resetRateLimits } from "@/lib/admin/config-health/rate-limit";

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: vi.fn(),
}));

const addMock = vi.fn().mockResolvedValue({ id: "test-doc-id" });
const getMock = vi.fn();

vi.mock("@/lib/firebase/server", () => ({
  adminDb: {
    collection: vi.fn(() => ({
      doc: vi.fn(() => ({
        get: getMock,
      })),
      add: addMock,
    })),
  },
}));

describe("verifyReadinessRbac", () => {
  const mockRequest = new Request("https://admin.example.com/api/test", {
    method: "GET",
    headers: new Headers({
      "x-forwarded-for": "127.0.0.1",
      "authorization": "Bearer token123",
    }),
  });

  const basePolicy = {
    endpoint: "/api/test",
    allowedRoles: ["super_admin"],
  };

  beforeEach(() => {
    vi.clearAllMocks();
    resetRateLimits();
    
    // Enable feature flag by default for tests
    getMock.mockResolvedValue({
      exists: true,
      data: () => ({ readinessRbacEnabled: true }),
    });
  });

  // T1
  it("Unauthenticated request returns 401 with { ok: false, reason: 'unauthenticated' }", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce(null);

    const result = await verifyReadinessRbac(mockRequest, basePolicy);

    expect(result).toEqual({
      ok: false,
      status: 401,
      body: { ok: false, reason: "unauthenticated" },
    });
  });

  // T2
  it("Authenticated user without required role returns 403", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce({
      uid: "user-1",
      email: "test@example.com",
      roles: ["editor"],
      claims: {},
    } as any);

    const result = await verifyReadinessRbac(mockRequest, basePolicy);

    expect(result).toEqual({
      ok: false,
      status: 403,
      body: { ok: false, reason: "forbidden" },
    });
  });

  // T3
  it("Optional hidden endpoint policy returns 404 instead of 403", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce({
      uid: "user-1",
      roles: ["editor"],
      claims: {},
    } as any);

    const result = await verifyReadinessRbac(mockRequest, {
      ...basePolicy,
      hideWhenForbidden: true,
    });

    expect(result).toEqual({
      ok: false,
      status: 404,
      body: { ok: false, reason: "not_found" },
    });
  });

  // T4
  it("super_admin can access protected readiness endpoint", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce({
      uid: "user-1",
      roles: ["super_admin"],
      claims: {},
    } as any);

    const result = await verifyReadinessRbac(mockRequest, basePolicy);

    expect(result).toEqual({
      ok: true,
      user: expect.any(Object),
      role: "super_admin",
    });
  });

  // T5
  it("Denial response does not include stack traces, tokens, or raw headers", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce({
      uid: "user-1",
      roles: ["editor"],
      claims: {},
    } as any);

    const result = await verifyReadinessRbac(mockRequest, basePolicy);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.body).not.toHaveProperty("stack");
      expect(result.body).not.toHaveProperty("headers");
      expect(result.body).not.toHaveProperty("token");
      expect(result.body).toEqual({ ok: false, reason: "forbidden" });
    }
  });

  // T6
  it("Rate-limited request returns 429 with retry metadata", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValue({
      uid: "user-1",
      roles: ["super_admin"],
      claims: {},
    } as any);

    // Exhaust the rate limit (MAX_REQUESTS is 30)
    for (let i = 0; i < 30; i++) {
      await verifyReadinessRbac(mockRequest, basePolicy);
    }

    // The 31st request should be rate-limited
    const result = await verifyReadinessRbac(mockRequest, basePolicy);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.status).toBe(429);
      expect((result.body as any).status).toBe("rate_limited");
      expect((result.body as any).retryAt).toBeInstanceOf(Date);
    }
  });

  // T7
  it("Emits structured audit event on denial", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce({
      uid: "user-1",
      roles: ["editor"],
      claims: {},
    } as any);

    await verifyReadinessRbac(mockRequest, basePolicy);

    expect(adminDb.collection).toHaveBeenCalledWith("admin_step_up_audit_events");
    expect(addMock).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: "admin_readiness_rbac_forbidden",
        endpoint: "/api/test",
        method: "GET",
        userId: "user-1",
        role: "editor",
        requiredRoles: ["super_admin"],
        status: 403,
        source: "readiness-rbac",
      })
    );
  });

  // T8
  it("Does not log secrets", async () => {
    vi.mocked(getCurrentAdminSession).mockResolvedValueOnce({
      uid: "user-1",
      roles: ["editor"],
      claims: {},
    } as any);

    await verifyReadinessRbac(mockRequest, basePolicy);

    const logCallArgs = addMock.mock.calls[0][0];
    expect(logCallArgs).not.toHaveProperty("headers");
    expect(logCallArgs).not.toHaveProperty("token");
    expect(logCallArgs).not.toHaveProperty("cookie");
    expect(logCallArgs.authorization).toBeUndefined();
  });
});
