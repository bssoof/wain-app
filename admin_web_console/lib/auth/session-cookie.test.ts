import { beforeEach, describe, expect, it, vi } from "vitest";

const verifyIdTokenMock = vi.fn();
const createSessionCookieMock = vi.fn();
const verifySessionCookieMock = vi.fn();
const revokeRefreshTokensMock = vi.fn();
const adminDocGetMock = vi.fn();
const adminCollectionMock = vi.fn();

vi.mock("@/lib/firebase/server", () => ({
  adminAuth: {
    verifyIdToken: (...args: unknown[]) => verifyIdTokenMock(...args),
    createSessionCookie: (...args: unknown[]) => createSessionCookieMock(...args),
    verifySessionCookie: (...args: unknown[]) => verifySessionCookieMock(...args),
    revokeRefreshTokens: (...args: unknown[]) => revokeRefreshTokensMock(...args),
  },
  adminDb: {
    collection: (...args: unknown[]) => adminCollectionMock(...args),
  },
}));

import {
  __resetSessionVerificationCacheForTests,
  ADMIN_SESSION_EXPIRES_IN_MS,
  createAdminSessionCookieFromIdToken,
  revokeSessionCookie,
  verifyAdminSessionCookieWithProfile,
  verifyIdTokenForAdminSession,
} from "./session-cookie";

function activeAdminDoc(data: Record<string, unknown> = {}) {
  return {
    exists: true,
    data: () => ({ active: true, role: "super_admin", ...data }),
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  __resetSessionVerificationCacheForTests();

  adminCollectionMock.mockImplementation(() => ({
    doc: (uid: string) => ({
      get: () => adminDocGetMock(uid),
    }),
  }));

  verifyIdTokenMock.mockResolvedValue({
    uid: "uid-1",
    email: "admin@wain.app",
    auth_time: Math.floor(Date.now() / 1000),
  });

  createSessionCookieMock.mockResolvedValue("session-cookie-value");

  verifySessionCookieMock.mockResolvedValue({
    uid: "uid-1",
    sub: "uid-1",
    email: "admin@wain.app",
  });

  revokeRefreshTokensMock.mockResolvedValue(undefined);
  adminDocGetMock.mockResolvedValue(activeAdminDoc());
});

describe("session-cookie", () => {
  it("rejects blank id token", async () => {
    await expect(verifyIdTokenForAdminSession("   ")).rejects.toMatchObject({
      code: "missing_id_token",
      message: "Missing idToken",
    });
  });

  it("enforces recent sign-in requirement", async () => {
    verifyIdTokenMock.mockResolvedValue({
      uid: "uid-1",
      email: "admin@wain.app",
      auth_time: Math.floor(Date.now() / 1000) - 301,
    });

    await expect(verifyIdTokenForAdminSession("token-1")).rejects.toMatchObject({
      code: "recent_sign_in_required",
      message: "Recent sign in required",
    });
  });

  it("rejects inactive or missing admin profile", async () => {
    adminDocGetMock.mockResolvedValue({
      exists: false,
      data: () => undefined,
    });

    await expect(verifyIdTokenForAdminSession("token-1")).rejects.toMatchObject({
      code: "admin_inactive_or_missing",
      message: "Admin account is inactive or missing",
    });
  });

  it("mints session cookie only after policy verification", async () => {
    const sessionCookie = await createAdminSessionCookieFromIdToken("  token-1  ");

    expect(sessionCookie).toBe("session-cookie-value");
    expect(verifyIdTokenMock).toHaveBeenCalledWith("token-1");
    expect(createSessionCookieMock).toHaveBeenCalledWith("token-1", {
      expiresIn: ADMIN_SESSION_EXPIRES_IN_MS,
    });
  });

  it("warms session verification cache during session mint", async () => {
    const sessionCookie = await createAdminSessionCookieFromIdToken("token-1");
    await verifyAdminSessionCookieWithProfile(sessionCookie);

    expect(verifySessionCookieMock).not.toHaveBeenCalled();
    expect(adminDocGetMock).toHaveBeenCalledTimes(1);
  });

  it("verifies admin session cookie with revocation check enabled", async () => {
    const verified = await verifyAdminSessionCookieWithProfile("cookie-1");

    expect(verifySessionCookieMock).toHaveBeenCalledWith("cookie-1", true);
    expect(verified.decodedToken.uid).toBe("uid-1");
    expect(verified.adminProfile.uid).toBe("uid-1");
  });

  it("supports disabling revocation check via env flag", async () => {
    const previous = process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION;
    process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION = "0";

    try {
      await verifyAdminSessionCookieWithProfile("cookie-no-revoke");
      expect(verifySessionCookieMock).toHaveBeenCalledWith(
        "cookie-no-revoke",
        false,
      );
    } finally {
      if (previous === undefined) {
        delete process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION;
      } else {
        process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION = previous;
      }
    }
  });

  it("caches verified session cookie for repeated reads", async () => {
    await verifyAdminSessionCookieWithProfile("cookie-cached");
    await verifyAdminSessionCookieWithProfile("cookie-cached");

    expect(verifySessionCookieMock).toHaveBeenCalledTimes(1);
    expect(adminDocGetMock).toHaveBeenCalledTimes(1);
  });

  it("revokes refresh tokens from verified session cookie", async () => {
    verifySessionCookieMock.mockResolvedValue({
      uid: "uid-9",
      sub: "uid-9",
    });

    await revokeSessionCookie("cookie-9");

    expect(verifySessionCookieMock).toHaveBeenCalledWith("cookie-9");
    expect(revokeRefreshTokensMock).toHaveBeenCalledWith("uid-9");
  });
});