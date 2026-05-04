import { describe, expect, it, vi } from "vitest";

vi.mock("server-only", () => ({}));

import type { AdminSession } from "./guard-api";
import { STEP_UP_COOKIE_NAME } from "./step-up-required";
import { issueStepUpToken } from "./step-up-token";
import { verifyStepUpForCommand } from "./step-up-middleware";

const SIGNING_KEY = "test-step-up-signing-key";
const PREVIOUS_SIGNING_KEY = "test-step-up-previous-signing-key";
const NOW_MS = Date.UTC(2026, 3, 30, 10, 0, 0);
const NOW_SECONDS = Math.floor(NOW_MS / 1000);

function session(uid = "admin-1"): AdminSession {
  return {
    uid,
    email: "admin@wain.app",
    primaryRole: "finance_admin",
    roles: ["finance_admin"],
    roleSource: "claims",
  };
}

function requestWithCookie(token?: string): Request {
  return new Request("https://wain-admin.web.app/api/admin/command/finance", {
    headers: token
      ? {
          Cookie: `${STEP_UP_COOKIE_NAME}=${encodeURIComponent(token)}`,
        }
      : {},
  });
}

describe("verifyStepUpForCommand", () => {
  it("allows a finance command with a valid step-up token", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS,
      },
    );

    const result = await verifyStepUpForCommand({
      request: requestWithCookie(issued.token),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_topup",
      signingKey: SIGNING_KEY,
      enforcementMode: "enabled",
      nowMs: NOW_MS + 1_000,
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.required).toBe(true);
      expect(result.payload?.sub).toBe("admin-1");
    }
  });

  it("allows previous-key tokens during rotation and logs previous-key usage", async () => {
    const emitAuditEvent = vi.fn().mockResolvedValue(undefined);
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: PREVIOUS_SIGNING_KEY,
        nowMs: NOW_MS,
        jti: "jti-previous-key",
      },
    );

    const result = await verifyStepUpForCommand({
      request: requestWithCookie(issued.token),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_topup",
      signingKey: SIGNING_KEY,
      previousSigningKey: PREVIOUS_SIGNING_KEY,
      enforcementMode: "enabled",
      nowMs: NOW_MS + 1_000,
      emitAuditEvent,
    });

    expect(result.ok).toBe(true);
    expect(emitAuditEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: "step_up_previous_key_verified",
        userId: "admin-1",
        sessionRole: "finance_admin",
        command: "approve_topup",
        scope: "finance",
        tokenJti: "jti-previous-key",
        tokenIssuedAt: "2026-04-30T10:00:00.000Z",
        tokenAge_ms: 1000,
        expiresAt: "2026-04-30T10:15:00.000Z",
        currentKeyVersion: "latest",
        previousKeyVersion: "previous",
      }),
    );
  });

  it("rejects a required finance command without a cookie", async () => {
    const result = await verifyStepUpForCommand({
      request: requestWithCookie(),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_reversal",
      signingKey: SIGNING_KEY,
      enforcementMode: "enabled",
      nowMs: NOW_MS,
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toMatchObject({
        code: "step_up_required",
        status: 403,
        message: "STEP_UP_REQUIRED",
        details: {
          reason: "missing_token",
          scope: "finance",
          command: "approve_reversal",
        },
      });
    }
  });

  it("rejects scope mismatch", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "config",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS,
      },
    );

    const result = await verifyStepUpForCommand({
      request: requestWithCookie(issued.token),
      session: session("admin-1"),
      scope: "finance",
      command: "reject_topup",
      signingKey: SIGNING_KEY,
      enforcementMode: "enabled",
      nowMs: NOW_MS + 1_000,
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.details.reason).toBe("scope_mismatch");
    }
  });

  it("rejects expired tokens with an explicit step-up required reason", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS,
      },
    );

    const result = await verifyStepUpForCommand({
      request: requestWithCookie(issued.token),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_topup",
      signingKey: SIGNING_KEY,
      enforcementMode: "enabled",
      nowMs: NOW_MS + 16 * 60 * 1000,
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toMatchObject({
        code: "step_up_required",
        status: 403,
        message: "STEP_UP_REQUIRED",
        details: {
          reason: "expired_token",
          scope: "finance",
          command: "approve_topup",
        },
      });
    }
  });

  it("does not require step-up for non-sensitive finance reads/ops", async () => {
    const result = await verifyStepUpForCommand({
      request: requestWithCookie(),
      session: session("admin-1"),
      scope: "finance",
      command: "verify_wallet_readiness",
      signingKey: SIGNING_KEY,
      enforcementMode: "enabled",
      nowMs: NOW_MS,
    });

    expect(result).toEqual({
      ok: true,
      required: false,
    });
  });

  it("bypasses sensitive commands when enforcement mode is disabled", async () => {
    const result = await verifyStepUpForCommand({
      request: requestWithCookie(),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_topup",
      signingKey: SIGNING_KEY,
      enforcementMode: "disabled",
      nowMs: NOW_MS,
    });

    expect(result).toEqual({
      ok: true,
      required: true,
      enforcementMode: "disabled",
      bypassed: true,
      bypassReason: "enforcement_disabled",
    });
  });

  it("allows invalid step-up state in log-only mode and emits an audit event", async () => {
    const emitAuditEvent = vi.fn().mockResolvedValue(undefined);
    const result = await verifyStepUpForCommand({
      request: requestWithCookie(),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_topup",
      signingKey: SIGNING_KEY,
      enforcementMode: "log_only",
      nowMs: NOW_MS,
      emitAuditEvent,
    });

    expect(result).toEqual({
      ok: true,
      required: true,
      enforcementMode: "log_only",
      bypassed: true,
      bypassReason: "missing_token",
    });
    expect(emitAuditEvent).toHaveBeenCalledWith({
      eventType: "step_up_log_only_would_reject",
      enforcementMode: "log_only",
      reason: "missing_token",
      command: "approve_topup",
      scope: "finance",
      userId: "admin-1",
      sessionRole: "finance_admin",
    });
  });

  it("does not emit log-only rejection audit events for valid tokens", async () => {
    const emitAuditEvent = vi.fn().mockResolvedValue(undefined);
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS,
      },
    );

    const result = await verifyStepUpForCommand({
      request: requestWithCookie(issued.token),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_topup",
      signingKey: SIGNING_KEY,
      enforcementMode: "log_only",
      nowMs: NOW_MS + 1_000,
      emitAuditEvent,
    });

    expect(result.ok).toBe(true);
    expect(emitAuditEvent).not.toHaveBeenCalled();
  });
});
