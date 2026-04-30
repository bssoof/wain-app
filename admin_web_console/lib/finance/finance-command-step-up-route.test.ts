import { beforeEach, describe, expect, it, vi } from "vitest";

const { getCurrentAdminSessionMock, getStepUpEnforcementModeMock } = vi.hoisted(() => ({
  getCurrentAdminSessionMock: vi.fn(),
  getStepUpEnforcementModeMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: (...args: unknown[]) =>
    getCurrentAdminSessionMock(...args),
}));

vi.mock("@/lib/auth/step-up-config", () => ({
  getStepUpEnforcementMode: () => getStepUpEnforcementModeMock(),
}));

import { POST } from "@/app/api/admin/command/finance/route";
import type { AdminSession } from "@/lib/auth/guard-api";

function financeSession(): AdminSession {
  return {
    uid: "admin-1",
    email: "finance@wain.app",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function makeRequest(body: Record<string, unknown>, cookie?: string): Request {
  return new Request("https://wain-admin.web.app/api/admin/command/finance", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(cookie ? { Cookie: cookie } : {}),
    },
    body: JSON.stringify(body),
  });
}

function topupApproveBody() {
  return {
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
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  getCurrentAdminSessionMock.mockResolvedValue(financeSession());
  getStepUpEnforcementModeMock.mockResolvedValue("enabled");
});

describe("finance command route step-up guard", () => {
  it("rejects sensitive finance commands without a step-up cookie", async () => {
    const response = await POST(makeRequest(topupApproveBody()));
    const payload = await response.json();

    expect(response.status).toBe(403);
    expect(payload).toEqual({
      ok: false,
      correlationId: "corr-approve-topup-1",
      error: {
        code: "step_up_required",
        status: 403,
        message: "STEP_UP_REQUIRED",
        retryable: false,
        details: {
          reason: "missing_token",
          scope: "finance",
          command: "approve_topup",
        },
      },
    });
  });
});
