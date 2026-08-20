import { beforeEach, describe, expect, it, vi } from "vitest";

const { adminDocGetMock, verifyReadinessRbacMock, runConfigHealthChecksMock } = vi.hoisted(() => ({
  adminDocGetMock: vi.fn(),
  verifyReadinessRbacMock: vi.fn(),
  runConfigHealthChecksMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/admin/route-guards/readiness-rbac", () => ({
  verifyReadinessRbac: (...args: unknown[]) => verifyReadinessRbacMock(...args),
}));

vi.mock("@/lib/admin/config-health/run-checks", () => ({
  runConfigHealthChecks: () => runConfigHealthChecksMock(),
}));

vi.mock("@/lib/firebase/server", () => ({
  adminDb: {
    collection: () => ({
      doc: () => ({
        get: () => adminDocGetMock(),
      }),
    }),
  },
}));

import { GET } from "@/app/api/admin/step-up/banner/route";

function makeRequest(): Request {
  return new Request("https://wain-admin.web.app/api/admin/step-up/banner", {
    method: "GET",
    headers: { "x-forwarded-for": "192.0.2.1" },
  });
}

beforeEach(() => {
  vi.clearAllMocks();
  verifyReadinessRbacMock.mockResolvedValue({
    ok: true,
    user: {
      uid: "admin-1",
      primaryRole: "finance_admin",
      roles: ["finance_admin"],
      roleSource: "claims",
    },
    role: "finance_admin",
  });
  adminDocGetMock.mockResolvedValue({
    exists: true,
    data: () => ({
      bannerMessage: "رسالة تشغيلية",
      bannerSeverity: "warning",
    }),
  });
  runConfigHealthChecksMock.mockResolvedValue({ disabled: true });
});

describe("admin step-up banner route", () => {
  it("returns the admin banner config for signed-in admins", async () => {
    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      success: true,
      bannerMessage: "رسالة تشغيلية",
      bannerSeverity: "warning",
    });
  });

  it("requires an admin session", async () => {
    verifyReadinessRbacMock.mockResolvedValueOnce({
      ok: false,
      status: 401,
      body: { ok: false, reason: "unauthenticated" },
    });

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload).toEqual({
      ok: false,
      reason: "unauthenticated",
    });
    expect(adminDocGetMock).not.toHaveBeenCalled();
  });

  it("returns null when no banner message is configured", async () => {
    adminDocGetMock.mockResolvedValue({
      exists: true,
      data: () => ({
        bannerMessage: "   ",
        bannerSeverity: "critical",
      }),
    });

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      success: true,
      bannerMessage: null,
      bannerSeverity: "critical",
    });
  });

  it("normalizes unknown severity to info", async () => {
    adminDocGetMock.mockResolvedValue({
      exists: true,
      data: () => ({
        bannerMessage: "رسالة",
        bannerSeverity: "unknown",
      }),
    });

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.bannerSeverity).toBe("info");
  });

  it("returns 503 when config cannot be read", async () => {
    adminDocGetMock.mockRejectedValue(new Error("firestore unavailable"));

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(503);
    expect(payload).toEqual({
      success: false,
      error: "Failed to read admin banner config",
    });
  });

  it("merges config health errors into banner for super_admin", async () => {
    verifyReadinessRbacMock.mockResolvedValue({
      ok: true,
      user: {
        uid: "admin-1",
        primaryRole: "super_admin",
        roles: ["super_admin"],
        roleSource: "claims",
      },
      role: "super_admin",
    });
    adminDocGetMock.mockResolvedValue({
      exists: true,
      data: () => ({
        bannerMessage: "رسالة عادية",
        bannerSeverity: "info",
      }),
    });
    runConfigHealthChecksMock.mockResolvedValue({
      ok: false,
      summary: { errorCount: 1, warnCount: 0, unknownCount: 0 },
    });

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.bannerSeverity).toBe("critical");
    expect(payload.bannerMessage).toContain("أخطاء حرجة");
  });

  it("merges config health warnings into banner for super_admin", async () => {
    verifyReadinessRbacMock.mockResolvedValue({
      ok: true,
      user: {
        uid: "admin-1",
        primaryRole: "super_admin",
        roles: ["super_admin"],
        roleSource: "claims",
      },
      role: "super_admin",
    });
    adminDocGetMock.mockResolvedValue({
      exists: true,
      data: () => ({
        bannerMessage: null,
        bannerSeverity: "info",
      }),
    });
    runConfigHealthChecksMock.mockResolvedValue({
      ok: true, // No tier 1 errors, but has warnings
      summary: { errorCount: 0, warnCount: 2, unknownCount: 0 },
    });

    const response = await GET(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.bannerSeverity).toBe("warning");
    expect(payload.bannerMessage).toContain("تحذيرات");
  });

  it("does not run config health checks for non-super_admin", async () => {
    const response = await GET(makeRequest());

    expect(response.status).toBe(200);
    expect(runConfigHealthChecksMock).not.toHaveBeenCalled();
  });
});
