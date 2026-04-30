import { beforeEach, describe, expect, it, vi } from "vitest";

const { adminDocGetMock, getCurrentAdminSessionMock } = vi.hoisted(() => ({
  adminDocGetMock: vi.fn(),
  getCurrentAdminSessionMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: () => getCurrentAdminSessionMock(),
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

beforeEach(() => {
  vi.clearAllMocks();
  getCurrentAdminSessionMock.mockResolvedValue({
    uid: "admin-1",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
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
    const response = await GET();
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      success: true,
      bannerMessage: "رسالة تشغيلية",
      bannerSeverity: "warning",
    });
  });

  it("requires an admin session", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(null);

    const response = await GET();
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload).toEqual({
      success: false,
      error: "Admin session required",
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

    const response = await GET();
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

    const response = await GET();
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.bannerSeverity).toBe("info");
  });

  it("returns 503 when config cannot be read", async () => {
    adminDocGetMock.mockRejectedValue(new Error("firestore unavailable"));

    const response = await GET();
    const payload = await response.json();

    expect(response.status).toBe(503);
    expect(payload).toEqual({
      success: false,
      error: "Failed to read admin banner config",
    });
  });
});
