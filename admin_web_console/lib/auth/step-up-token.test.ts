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
const PREVIOUS_SIGNING_KEY = "test-step-up-previous-signing-key";
const UNKNOWN_SIGNING_KEY = "test-step-up-unknown-signing-key";
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

  it("verifies current-key tokens before trying previous keys", async () => {
    const onVerifyKeyMatch = vi.fn();
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        nowMs: NOW_MS,
        jti: "jti-current-key",
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
        previousSigningKey: PREVIOUS_SIGNING_KEY,
        nowMs: NOW_MS + 1_000,
        onVerifyKeyMatch,
      },
    );

    expect(payload.jti).toBe("jti-current-key");
    expect(onVerifyKeyMatch).toHaveBeenCalledWith({
      keySlot: "current",
      jti: "jti-current-key",
      sub: "admin-1",
      scope: "finance",
      exp: NOW_SECONDS + Math.floor(STEP_UP_TTL_MS / 1000),
    });
  });

  it("verifies previous-key tokens during rotation", async () => {
    const onVerifyKeyMatch = vi.fn();
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

    const payload = await verifyStepUpToken(
      issued.token,
      {
        scope: "finance",
        subject: "admin-1",
      },
      {
        signingKey: SIGNING_KEY,
        previousSigningKey: PREVIOUS_SIGNING_KEY,
        nowMs: NOW_MS + 1_000,
        onVerifyKeyMatch,
      },
    );

    expect(payload.jti).toBe("jti-previous-key");
    expect(onVerifyKeyMatch).toHaveBeenCalledWith({
      keySlot: "previous",
      jti: "jti-previous-key",
      sub: "admin-1",
      scope: "finance",
      exp: NOW_SECONDS + Math.floor(STEP_UP_TTL_MS / 1000),
    });
  });

  it("rejects previous-key tokens when previous key is not configured", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: PREVIOUS_SIGNING_KEY,
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
      code: "invalid_token",
    });
  });

  it("rejects tokens not signed by current or previous key", async () => {
    const onVerifyKeyMatch = vi.fn();
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: UNKNOWN_SIGNING_KEY,
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
          previousSigningKey: PREVIOUS_SIGNING_KEY,
          nowMs: NOW_MS + 1_000,
          onVerifyKeyMatch,
        },
      ),
    ).rejects.toMatchObject({
      code: "invalid_token",
    });
    expect(onVerifyKeyMatch).not.toHaveBeenCalled();
  });

  it("issues new tokens with current key only during rotation", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: SIGNING_KEY,
        previousSigningKey: PREVIOUS_SIGNING_KEY,
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
    ).resolves.toMatchObject({
      sub: "admin-1",
      scope: "finance",
    });

    await expect(
      verifyStepUpToken(
        issued.token,
        {
          scope: "finance",
          subject: "admin-1",
        },
        {
          signingKey: PREVIOUS_SIGNING_KEY,
          nowMs: NOW_MS + 1_000,
        },
      ),
    ).rejects.toMatchObject({
      code: "invalid_token",
    });
  });

  it("reads optional previous key from non-production env", async () => {
    const onVerifyKeyMatch = vi.fn();
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: PREVIOUS_SIGNING_KEY,
        nowMs: NOW_MS,
        jti: "jti-env-previous-key",
      },
    );

    const payload = await verifyStepUpToken(
      issued.token,
      {
        scope: "finance",
        subject: "admin-1",
      },
      {
        env: {
          NODE_ENV: "development",
          WAIN_ADMIN_STEP_UP_SIGNING_KEY: SIGNING_KEY,
          WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS: PREVIOUS_SIGNING_KEY,
        },
        nowMs: NOW_MS + 1_000,
        onVerifyKeyMatch,
      },
    );

    expect(payload.jti).toBe("jti-env-previous-key");
    expect(onVerifyKeyMatch).toHaveBeenCalledWith(
      expect.objectContaining({
        keySlot: "previous",
        jti: "jti-env-previous-key",
      }),
    );
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

  it("rejects direct previous env signing keys in production", async () => {
    const issued = await issueStepUpToken(
      {
        sub: "admin-1",
        scope: "finance",
        authTime: NOW_SECONDS,
      },
      {
        signingKey: PREVIOUS_SIGNING_KEY,
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
          env: {
            NODE_ENV: "production",
            WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION:
              "projects/test/secrets/current/versions/latest",
            WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS: PREVIOUS_SIGNING_KEY,
            WAIN_GOOGLE_OAUTH_ACCESS_TOKEN: "test-token",
          },
          fetchImpl: async () =>
            new Response(
              JSON.stringify({
                payload: {
                  data: Buffer.from(SIGNING_KEY, "utf8").toString("base64"),
                },
              }),
              { status: 200 },
            ),
          nowMs: NOW_MS + 1_000,
        },
      ),
    ).rejects.toBeInstanceOf(StepUpTokenError);
  });
});
