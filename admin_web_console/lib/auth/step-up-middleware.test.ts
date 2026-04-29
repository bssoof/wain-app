import { describe, expect, it, vi } from "vitest";

vi.mock("server-only", () => ({}));

import type { AdminSession } from "./guard-api";
import { STEP_UP_COOKIE_NAME } from "./step-up-required";
import { issueStepUpToken } from "./step-up-token";
import { verifyStepUpForCommand } from "./step-up-middleware";

const SIGNING_KEY = "test-step-up-signing-key";
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
      nowMs: NOW_MS + 1_000,
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.required).toBe(true);
      expect(result.payload?.sub).toBe("admin-1");
    }
  });

  it("rejects a required finance command without a cookie", async () => {
    const result = await verifyStepUpForCommand({
      request: requestWithCookie(),
      session: session("admin-1"),
      scope: "finance",
      command: "approve_reversal",
      signingKey: SIGNING_KEY,
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
      nowMs: NOW_MS + 1_000,
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.details.reason).toBe("scope_mismatch");
    }
  });

  it("does not require step-up for non-sensitive finance reads/ops", async () => {
    const result = await verifyStepUpForCommand({
      request: requestWithCookie(),
      session: session("admin-1"),
      scope: "finance",
      command: "verify_wallet_readiness",
      signingKey: SIGNING_KEY,
      nowMs: NOW_MS,
    });

    expect(result).toEqual({
      ok: true,
      required: false,
    });
  });
});
