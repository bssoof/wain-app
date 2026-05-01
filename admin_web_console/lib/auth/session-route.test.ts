import { beforeEach, describe, expect, it, vi } from "vitest";

const { createAdminSessionCookieFromIdTokenMock, revokeSessionCookieMock } =
  vi.hoisted(() => ({
    createAdminSessionCookieFromIdTokenMock: vi.fn(),
    revokeSessionCookieMock: vi.fn(),
  }));

vi.mock("@/lib/auth/session-cookie", () => {
  const SessionVerificationError = class SessionVerificationError extends Error {
    readonly code: string;

    constructor(code: string, message: string) {
      super(message);
      this.code = code;
      this.name = "SessionVerificationError";
    }
  };

  return {
    ADMIN_HOSTING_SESSION_COOKIE_NAME: "__session",
    ADMIN_SESSION_COOKIE_NAME: "wain_admin_session",
    ADMIN_SESSION_EXPIRES_IN_MS: 60 * 60 * 24 * 7 * 1000,
    SessionVerificationError,
    createAdminSessionCookieFromIdToken: (...args: unknown[]) =>
      createAdminSessionCookieFromIdTokenMock(...args),
    revokeSessionCookie: (...args: unknown[]) => revokeSessionCookieMock(...args),
  };
});

import { DELETE, POST } from "@/app/api/admin/session/route";
import {
  ADMIN_HOSTING_SESSION_COOKIE_NAME,
  ADMIN_SESSION_COOKIE_NAME,
  SessionVerificationError,
} from "@/lib/auth/session-cookie";

function makePostRequest(body: Record<string, unknown>) {
  return {
    json: async () => body,
  };
}

function makeRawPostRequest(body: unknown) {
  return {
    json: async () => body,
  };
}

function makeMalformedJsonPostRequest() {
  return {
    json: async () => {
      throw new SyntaxError("Unexpected token");
    },
  };
}

function makeDeleteRequest(sessionCookie?: string) {
  return {
    cookies: {
      get: (name: string) =>
        (name === ADMIN_SESSION_COOKIE_NAME ||
          name === ADMIN_HOSTING_SESSION_COOKIE_NAME) &&
        sessionCookie
          ? { value: sessionCookie }
          : undefined,
    },
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  createAdminSessionCookieFromIdTokenMock.mockResolvedValue("session-cookie-value");
  revokeSessionCookieMock.mockResolvedValue(undefined);
});

describe("admin session route", () => {
  it("returns 400 when idToken is missing", async () => {
    const response = await POST(makePostRequest({}) as any);
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload).toEqual({ success: false, error: "Missing idToken" });
  });

  it("returns 400 instead of 500 for malformed JSON", async () => {
    const response = await POST(makeMalformedJsonPostRequest() as any);
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload).toEqual({
      success: false,
      error: "Malformed JSON body",
    });
    expect(createAdminSessionCookieFromIdTokenMock).not.toHaveBeenCalled();
  });

  it("returns 400 instead of 500 for JSON primitives", async () => {
    const response = await POST(makeRawPostRequest(null) as any);
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload).toEqual({
      success: false,
      error: "Invalid request body",
    });
    expect(createAdminSessionCookieFromIdTokenMock).not.toHaveBeenCalled();
  });

  it("sets session cookie on successful POST", async () => {
    const response = await POST(makePostRequest({ idToken: "token-1" }) as any);
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({ success: true });
    expect(createAdminSessionCookieFromIdTokenMock).toHaveBeenCalledWith("token-1");
    expect(response.cookies.get(ADMIN_SESSION_COOKIE_NAME)?.value).toBe(
      "session-cookie-value",
    );
    expect(response.cookies.get(ADMIN_HOSTING_SESSION_COOKIE_NAME)?.value).toBe(
      "session-cookie-value",
    );
  });

  it("maps recent-sign-in policy errors to 401", async () => {
    createAdminSessionCookieFromIdTokenMock.mockRejectedValue(
      new SessionVerificationError(
        "recent_sign_in_required",
        "Recent sign in required",
      ),
    );

    const response = await POST(makePostRequest({ idToken: "token-1" }) as any);
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload).toEqual({
      success: false,
      error: "Recent sign in required",
    });
  });

  it("maps inactive-admin policy errors to 403", async () => {
    createAdminSessionCookieFromIdTokenMock.mockRejectedValue(
      new SessionVerificationError(
        "admin_inactive_or_missing",
        "Admin account is inactive or missing",
      ),
    );

    const response = await POST(makePostRequest({ idToken: "token-1" }) as any);
    const payload = await response.json();

    expect(response.status).toBe(403);
    expect(payload).toEqual({
      success: false,
      error: "Admin account is inactive or missing",
    });
  });

  it("returns generic 401 when unexpected error happens", async () => {
    const consoleErrorSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => undefined);
    createAdminSessionCookieFromIdTokenMock.mockRejectedValue(new Error("boom"));

    const response = await POST(makePostRequest({ idToken: "token-1" }) as any);
    const payload = await response.json();

    expect(response.status).toBe(401);
    expect(payload).toEqual({
      success: false,
      error: "Failed to create session",
    });

    consoleErrorSpy.mockRestore();
  });

  it("deletes cookie and revokes token on DELETE", async () => {
    const response = await DELETE(makeDeleteRequest("cookie-1") as any);
    const payload = await response.json();

    expect(payload).toEqual({ success: true });
    expect(response.status).toBe(200);
    expect(revokeSessionCookieMock).toHaveBeenCalledWith("cookie-1");
  });

  it("still succeeds DELETE when revoke fails", async () => {
    revokeSessionCookieMock.mockRejectedValue(new Error("revoke failed"));

    const response = await DELETE(makeDeleteRequest("cookie-1") as any);
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({ success: true });
  });

  it("skips revoke call when no session cookie exists", async () => {
    const response = await DELETE(makeDeleteRequest() as any);
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload).toEqual({ success: true });
    expect(revokeSessionCookieMock).not.toHaveBeenCalled();
  });
});
