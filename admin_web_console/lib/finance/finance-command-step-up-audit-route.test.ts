import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const {
  emitStepUpAuditEventMock,
  executeMock,
  getCurrentAdminSessionMock,
  verifyStepUpForCommandMock,
} = vi.hoisted(() => ({
  emitStepUpAuditEventMock: vi.fn(),
  executeMock: vi.fn(),
  getCurrentAdminSessionMock: vi.fn(),
  verifyStepUpForCommandMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: (...args: unknown[]) =>
    getCurrentAdminSessionMock(...args),
}));

vi.mock("@/lib/auth/step-up-audit", () => ({
  emitStepUpAuditEvent: (...args: unknown[]) =>
    emitStepUpAuditEventMock(...args),
}));

vi.mock("@/lib/auth/step-up-middleware", () => ({
  verifyStepUpForCommand: (...args: unknown[]) =>
    verifyStepUpForCommandMock(...args),
}));

vi.mock("@/lib/finance/finance-command-adapters", () => ({
  createFinanceCommandAdaptersTransport: () => ({
    execute: executeMock,
  }),
}));

import { POST } from "@/app/api/admin/command/finance/route";

const ORIGINAL_ENV = { ...process.env };

function makeRequest(): Request {
  return new Request("https://wain-admin.web.app/api/admin/command/finance", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      command: "approve_topup",
      request: {
        action: "approve_topup",
        commandId: "cmd-approve-topup-1",
        correlationId: "corr-approve-topup-1",
        reason: "Approve test topup",
        submittedAt: "2026-04-30T10:00:00.000Z",
        requestId: "topup-1",
        venueId: "venue-1",
        expectedState: {
          status: "pending",
          decision_state: "unreviewed",
        },
      },
    }),
  });
}

beforeEach(() => {
  vi.useRealTimers();
  vi.clearAllMocks();
  process.env = {
    ...ORIGINAL_ENV,
    WAIN_FINANCE_FUNCTIONS_BASE_URL: "http://127.0.0.1:5001",
    WAIN_FINANCE_SERVER_AUTH_TOKEN: "server-auth-token",
  };
  getCurrentAdminSessionMock.mockResolvedValue({
    uid: "admin-1",
    email: "finance@wain.app",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  });
  emitStepUpAuditEventMock.mockResolvedValue(undefined);
  verifyStepUpForCommandMock.mockResolvedValue({
    ok: true,
    required: true,
    enforcementMode: "enabled",
    payload: {
      sub: "admin-1",
      scope: "finance",
      iat: 1777543200,
      exp: 1777544100,
      authTime: 1777543200,
      jti: "jti-verified",
    },
  });
  executeMock.mockResolvedValue({
    ok: true,
    command: "approve_topup",
    commandId: "cmd-approve-topup-1",
    correlationId: "corr-approve-topup-1",
    data: {
      action: "approve_topup",
      requestId: "topup-1",
      venueId: "venue-1",
      status: "credited",
    },
  });
});

afterEach(() => {
  vi.useRealTimers();
  process.env = ORIGINAL_ENV;
});

describe("finance command route step-up audit", () => {
  it("emits step_up_verified when a sensitive command has a valid token", async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-04-30T10:01:00.000Z"));

    const response = await POST(makeRequest());
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.ok).toBe(true);
    expect(emitStepUpAuditEventMock).toHaveBeenCalledWith({
      eventType: "step_up_verified",
      userId: "admin-1",
      sessionRole: "finance_admin",
      command: "approve_topup",
      correlationId: "corr-approve-topup-1",
      scope: "finance",
      enforcementMode: "enabled",
      tokenJti: "jti-verified",
      tokenIssuedAt: "2026-04-30T10:00:00.000Z",
      tokenAge_ms: 60_000,
      expiresAt: "2026-04-30T10:15:00.000Z",
    });
  });
});
