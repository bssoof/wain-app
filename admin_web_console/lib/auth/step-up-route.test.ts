import { beforeEach, describe, expect, it, vi } from "vitest";

const { issueStepUpTokenForIdTokenMock } = vi.hoisted(() => ({
  issueStepUpTokenForIdTokenMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("@/lib/auth/step-up-token", async () => {
  const actual = await vi.importActual<typeof import("./step-up-token")>(
    "./step-up-token",
  );

  return {
    ...actual,
    issueStepUpTokenForIdToken: (...args: unknown[]) =>
      issueStepUpTokenForIdTokenMock(...args),
  };
});

import { POST } from "@/app/api/admin/step-up/issue/route";
import { STEP_UP_COOKIE_NAME } from "./step-up-required";
import { StepUpTokenError } from "./step-up-token";

function makePostRequest(body: Record<string, unknown>) {
  return {
    json: async () => body,
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  issueStepUpTokenForIdTokenMock.mockResolvedValue({
    token: "step-up-token-value",
    payload: {
      sub: "admin-1",
      scope: "finance",
      iat: 1777543200,
      exp: 1777544100,
      authTime: 1777543200,
      jti: "jti-1",
    },
    expiresAtEpochMs: 1777544100000,
  });
});

describe("admin step-up issue route", () => {
  it("rejects missing idToken", async () => {
    const response = await POST(makePostRequest({ scope: "finance" }) as any);
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload).toEqual({ success: false, error: "Missing idToken" });
    expect(issueStepUpTokenForIdTokenMock).not.toHaveBeenCalled();
  });

  it("rejects invalid scope", async () => {
    const response = await POST(
      makePostRequest({ idToken: "fresh-id-token", scope: "unknown" }) as any,
    );
    const payload = await response.json();

    expect(response.status).toBe(422);
    expect(payload).toEqual({
      success: false,
      error: "Invalid step-up scope",
    });
    expect(issueStepUpTokenForIdTokenMock).not.toHaveBeenCalled();
  });

  it("sets an HTTP-only strict step-up cookie on success", async () => {
    const response = await POST(
      makePostRequest({ idToken: "fresh-id-token", scope: "finance" }) as any,
    );
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({
      success: true,
      scope: "finance",
      expiresAt: "2026-04-30T10:15:00.000Z",
      issuedAt: "2026-04-30T10:00:00.000Z",
    });
    expect(issueStepUpTokenForIdTokenMock).toHaveBeenCalledWith(
      "fresh-id-token",
      "finance",
    );

    const cookie = response.cookies.get(STEP_UP_COOKIE_NAME);
    expect(cookie?.value).toBe("step-up-token-value");
    expect(cookie?.httpOnly).toBe(true);
    expect(cookie?.sameSite).toBe("strict");
    expect(cookie?.path).toBe("/");
    expect(cookie?.maxAge).toBe(900);
  });

  it("maps stale auth_time to 401", async () => {
    issueStepUpTokenForIdTokenMock.mockRejectedValue(
      new StepUpTokenError("stale_auth_time", "Fresh re-authentication is required"),
    );

    const response = await POST(
      makePostRequest({ idToken: "old-id-token", scope: "finance" }) as any,
    );
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload).toEqual({
      success: false,
      error: "Fresh re-authentication is required",
    });
  });
});
