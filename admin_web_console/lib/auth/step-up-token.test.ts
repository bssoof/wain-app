import { describe, expect, it, vi } from "vitest";

vi.mock("server-only", () => ({}));

import {
  STEP_UP_ISSUE_MAX_AUTH_AGE_SECONDS,
  STEP_UP_TTL_MS,
} from "./step-up-required";
import {
  StepUpTokenError,
  issueStepUpToken,
  resolveStepUpSigningKey,
  verifyStepUpToken,
} from "./step-up-token";

const SIGNING_KEY = "test-step-up-signing-key";
const NOW_MS = Date.UTC(2026, 3, 30, 10, 0, 0);
const NOW_SECONDS = Math.floor(NOW_MS / 1000);

describe("step-up token", () => {
  it("issues and verifies a valid token", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS,
        jti: "jti-valid",
      },
    );

    const payload = await verifyStepUpToken(
      issued.token,
      {
        scope: "finance",
        subject: "admin-1",
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS + 1_000,
      },
    );

    expect(payload).toEqual({
      sub: "admin-1",
      scope: "finance",
      iat: NOW_SECONDS,
      exp: NOW_SECONDS + Math.floor(STEP_UP_TTL_MS / 1000),
      authTime: NOW_SECONDS,
      jti: "jti-valid",
    });
  });

  it("rejects expired tokens", async () => {
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

    await expect(
      verifyStepUpToken(
        issued.token,
        {
          scope: "finance",
          subject: "admin-1",
        },
        {
          signingKey: SIGNING_KEY,
          nowMs: NOW_MS + STEP_UP_TTL_MS + 1_000,
        },
      ),
    ).rejects.toMatchObject({
      code: "expired_token",
    });
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

    await expect(
      verifyStepUpToken(
        issued.token,
        {
          scope: "finance",
          subject: "admin-1",
        },
        {
          signingKey: SIGNING_KEY,
          nowMs: NOW_MS + 1_000,
        },
      ),
    ).rejects.toMatchObject({
      code: "scope_mismatch",
    });
  });

  it("rejects subject mismatch", async () => {
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

    await expect(
      verifyStepUpToken(
        issued.token,
        {
          scope: "finance",
          subject: "admin-2",
        },
        {
          signingKey: SIGNING_KEY,
          nowMs: NOW_MS + 1_000,
        },
      ),
    ).rejects.toMatchObject({
      code: "subject_mismatch",
    });
  });

  it("rejects stale auth_time during issue", async () => {
    await expect(
      issueStepUpToken(
        {
          sub: "admin-1",
          scope: "finance",
          authTime: NOW_SECONDS - STEP_UP_ISSUE_MAX_AUTH_AGE_SECONDS - 1,
        },
        {
          signingKey: SIGNING_KEY,
          nowMs: NOW_MS,
        },
      ),
    ).rejects.toMatchObject({
      code: "stale_auth_time",
    });
  });

  it("rejects direct env signing keys in production", async () => {
    await expect(
      resolveStepUpSigningKey({
        env: {
          NODE_ENV: "production",
          WAIN_ADMIN_STEP_UP_SIGNING_KEY: "prod-env-secret",
        },
      }),
    ).rejects.toBeInstanceOf(StepUpTokenError);
  });
});
