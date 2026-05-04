import { beforeEach, describe, expect, it, vi } from "vitest";

const { adminDocGetMock, verifyReadinessRbacMock } = vi.hoisted(() => ({
  adminDocGetMock: vi.fn(),
  verifyReadinessRbacMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/admin/route-guards/readiness-rbac", () => ({
  verifyReadinessRbac: (...args: unknown[]) => verifyReadinessRbacMock(...args),
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
});
