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

vi.mock("@/lib/config/config-command-adapters", () => ({
  createConfigCommandAdaptersTransport: () => ({
    execute: executeMock,
  }),
}));

import { POST } from "./route";

const ORIGINAL_ENV = { ...process.env };

function makeRequest(body: Record<string, unknown>, cookie?: string): Request {
  return new Request("https://wain-admin.web.app/api/admin/command/config", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(cookie ? { Cookie: cookie } : {}),
    },
    body: JSON.stringify(body),
  });
}

function publishConfigBody() {
  return {
    command: "publish_config",
    request: {
      action: "publish_config",
      commandId: "cmd-publish-config-1",
      correlationId: "corr-publish-config-1",
      reason: "Publish reviewed config",
      submittedAt: "2026-05-07T12:00:00.000Z",
      expectedState: {
        draft_status: "reviewed",
        draft_version: 1,
        target_live_version: 0,
      },
    },
  };
}

function rollbackConfigBody() {
  return {
    command: "rollback_config",
    request: {
      action: "rollback_config",
      commandId: "cmd-rollback-config-1",
      correlationId: "corr-rollback-config-1",
      reason: "Rollback bad config",
      submittedAt: "2026-05-07T12:05:00.000Z",
      rollbackToVersion: 1,
      expectedState: {
        current_live_version: 2,
      },
    },
  };
}

function stepUpRequired(reason: string, command: string) {
  return {
    ok: false,
    error: {
      code: "step_up_required",
      status: 403,
      message: "STEP_UP_REQUIRED",
      retryable: false,
      details: {
        reason,
        scope: "config",
        command,
      },
    },
  };
}

beforeEach(() => {
  vi.useRealTimers();
  vi.clearAllMocks();
  process.env = {
    ...ORIGINAL_ENV,
    WAIN_CONFIG_FUNCTIONS_BASE_URL: "http://127.0.0.1:5001",
    WAIN_CONFIG_SERVER_AUTH_TOKEN: "server-auth-token",
  };
  getCurrentAdminSessionMock.mockResolvedValue({
    uid: "super-admin-1",
    email: "super@wain.app",
    primaryRole: "super_admin",
    roles: ["super_admin"],
    roleSource: "claims",
  });
  emitStepUpAuditEventMock.mockResolvedValue(undefined);
  verifyStepUpForCommandMock.mockResolvedValue({
    ok: true,
    required: false,
  });
  executeMock.mockResolvedValue({
    ok: true,
    command: "publish_config",
    commandId: "cmd-publish-config-1",
    correlationId: "corr-publish-config-1",
    data: {
      status: "published",
      liveVersion: 1,
      previousLiveVersion: 0,
      draftVersion: 1,
      historyId: "history-1",
      auditEventId: "audit-1",
    },
  });
});

afterEach(() => {
  vi.useRealTimers();
  process.env = ORIGINAL_ENV;
});

describe("config command route step-up guard", () => {
  it("rejects publish_config without a step-up cookie", async () => {
    verifyStepUpForCommandMock.mockResolvedValue(
      stepUpRequired("missing_token", "publish_config"),
    );

    const response = await POST(makeRequest(publishConfigBody()));
    const payload = await response.json();

    expect(response.status).toBe(403);
    expect(payload).toEqual({
      ok: false,
      correlationId: "corr-publish-config-1",
      error: {
        code: "step_up_required",
        status: 403,
        message: "STEP_UP_REQUIRED",
        retryable: false,
        details: {
          reason: "missing_token",
          scope: "config",
          command: "publish_config",
        },
      },
    });
    expect(verifyStepUpForCommandMock).toHaveBeenCalledWith({
      request: expect.any(Request),
      session: expect.objectContaining({ uid: "super-admin-1" }),
      scope: "config",
      command: "publish_config",
    });
    expect(executeMock).not.toHaveBeenCalled();
    expect(emitStepUpAuditEventMock).toHaveBeenCalledWith({
      eventType: "step_up_rejected",
      userId: "super-admin-1",
      sessionRole: "super_admin",
      command: "publish_config",
      correlationId: "corr-publish-config-1",
      scope: "config",
      reason: "missing_token",
      enforcementMode: "enabled",
      status: 403,
    });
  });

  it("rejects publish_config with an expired step-up cookie", async () => {
    verifyStepUpForCommandMock.mockResolvedValue(
      stepUpRequired("expired_token", "publish_config"),
    );

    const response = await POST(
      makeRequest(publishConfigBody(), "wain_admin_step_up=expired"),
    );
    const payload = await response.json();

    expect(response.status).toBe(403);
    expect(payload.error.details).toEqual({
      reason: "expired_token",
      scope: "config",
      command: "publish_config",
    });
    expect(executeMock).not.toHaveBeenCalled();
  });

  it("rejects rollback_config without a step-up cookie", async () => {
    verifyStepUpForCommandMock.mockResolvedValue(
      stepUpRequired("missing_token", "rollback_config"),
    );

    const response = await POST(makeRequest(rollbackConfigBody()));
    const payload = await response.json();

    expect(response.status).toBe(403);
    expect(payload.error.details).toEqual({
      reason: "missing_token",
      scope: "config",
      command: "rollback_config",
    });
    expect(executeMock).not.toHaveBeenCalled();
  });

  it("executes publish_config with a valid step-up token", async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-07T12:01:00.000Z"));
    verifyStepUpForCommandMock.mockResolvedValue({
      ok: true,
      required: true,
      enforcementMode: "enabled",
      payload: {
        sub: "super-admin-1",
        scope: "config",
        iat: 1778155200,
        exp: 1778156100,
        authTime: 1778155200,
        jti: "jti-config-step-up",
      },
    });

    const response = await POST(
      makeRequest(publishConfigBody(), "wain_admin_step_up=valid"),
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      ok: true,
      correlationId: "corr-publish-config-1",
      data: {
        status: "published",
        liveVersion: 1,
        previousLiveVersion: 0,
        draftVersion: 1,
        historyId: "history-1",
        auditEventId: "audit-1",
      },
    });
    expect(executeMock).toHaveBeenCalledWith(
      "publish_config",
      publishConfigBody().request,
    );
    expect(emitStepUpAuditEventMock).toHaveBeenCalledWith({
      eventType: "step_up_verified",
      userId: "super-admin-1",
      sessionRole: "super_admin",
      command: "publish_config",
      correlationId: "corr-publish-config-1",
      scope: "config",
      enforcementMode: "enabled",
      tokenJti: "jti-config-step-up",
      tokenIssuedAt: "2026-05-07T12:00:00.000Z",
      tokenAge_ms: 60_000,
      expiresAt: "2026-05-07T12:15:00.000Z",
    });
  });
});
