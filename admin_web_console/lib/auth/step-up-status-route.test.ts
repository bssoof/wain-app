import { beforeEach, describe, expect, it, vi } from "vitest";

const { getCurrentAdminSessionMock, verifyStepUpForCommandMock } = vi.hoisted(() => ({
  getCurrentAdminSessionMock: vi.fn(),
  verifyStepUpForCommandMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: () => getCurrentAdminSessionMock(),
}));

vi.mock("@/lib/auth/step-up-middleware", () => ({
  verifyStepUpForCommand: (...args: unknown[]) => verifyStepUpForCommandMock(...args),
}));

import { GET } from "@/app/api/admin/step-up/status/route";

beforeEach(() => {
  vi.clearAllMocks();
  getCurrentAdminSessionMock.mockResolvedValue({
    uid: "admin-1",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  });
  verifyStepUpForCommandMock.mockResolvedValue({
    ok: true,
    required: false,
  });
});

describe("admin step-up status route", () => {
  it("rejects invalid scope", async () => {
    const response = await GET(
      new Request(
        "https://wain-admin.web.app/api/admin/step-up/status?scope=unknown&command=approve_topup",
      ),
    );
    const payload = await response.json();

    expect(response.status).toBe(422);
    expect(payload).toEqual({
      success: false,
      error: "Invalid step-up scope",
    });
    expect(verifyStepUpForCommandMock).not.toHaveBeenCalled();
  });

  it("rejects missing command", async () => {
    const response = await GET(
      new Request("https://wain-admin.web.app/api/admin/step-up/status?scope=finance"),
    );
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload).toEqual({
      success: false,
      error: "Missing command",
    });
    expect(verifyStepUpForCommandMock).not.toHaveBeenCalled();
  });

  it("returns required=true when challenge is needed", async () => {
    verifyStepUpForCommandMock.mockResolvedValue({
      ok: false,
      error: {
        details: {
          reason: "missing_token",
        },
      },
    });

    const response = await GET(
      new Request(
        "https://wain-admin.web.app/api/admin/step-up/status?scope=finance&command=approve_topup",
      ),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      success: true,
      scope: "finance",
      command: "approve_topup",
      sensitive: true,
      required: true,
      reason: "missing_token",
    });
  });

  it("returns active step-up metadata when token is already valid", async () => {
    verifyStepUpForCommandMock.mockResolvedValue({
      ok: true,
      required: true,
      payload: {
        sub: "admin-1",
        scope: "finance",
        iat: 1777543200,
        exp: 1777544100,
        authTime: 1777543200,
        jti: "jti-1",
      },
    });

    const response = await GET(
      new Request(
        "https://wain-admin.web.app/api/admin/step-up/status?scope=finance&command=approve_topup",
      ),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      success: true,
      scope: "finance",
      command: "approve_topup",
      sensitive: true,
      required: false,
      active: true,
      expiresAt: "2026-04-30T10:15:00.000Z",
      issuedAt: "2026-04-30T10:00:00.000Z",
    });
  });
});
