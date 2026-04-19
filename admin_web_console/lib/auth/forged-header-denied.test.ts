import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { headersMock, cookiesMock, verifyAdminSessionCookieWithProfileMock } = vi.hoisted(() => ({
  headersMock: vi.fn(),
  cookiesMock: vi.fn(),
  verifyAdminSessionCookieWithProfileMock: vi.fn(),
}));

vi.mock("server-only", () => ({}));

vi.mock("next/headers", () => ({
  headers: () => headersMock(),
  cookies: () => cookiesMock(),
}));

vi.mock("@/lib/auth/session-cookie", () => ({
  ADMIN_SESSION_COOKIE_NAME: "wain_admin_session",
  verifyAdminSessionCookieWithProfile: (...args: unknown[]) =>
    verifyAdminSessionCookieWithProfileMock(...args),
}));

import {
  getCurrentAdminSession,
  readHeaderBasedSessionContext,
  readRuntimeAdminSessionContext,
} from "@/lib/auth/session-server";

type EnvSnapshot = Record<string, string | undefined>;

const TARGET_ENV_KEYS = [
  "NODE_ENV",
  "WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION",
  "WAIN_ADMIN_SESSION_JSON",
  "WAIN_STRICT_AUTH",
] as const;

function snapshotEnv(): EnvSnapshot {
  return {
    NODE_ENV: process.env.NODE_ENV,
    WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION:
      process.env.WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION,
    WAIN_ADMIN_SESSION_JSON: process.env.WAIN_ADMIN_SESSION_JSON,
    WAIN_STRICT_AUTH: process.env.WAIN_STRICT_AUTH,
  };
}

function restoreEnv(snapshot: EnvSnapshot): void {
  const mutableEnv = process.env as Record<string, string | undefined>;
  for (const key of TARGET_ENV_KEYS) {
    const value = snapshot[key];
    if (value === undefined) {
      delete process.env[key];
    } else {
      mutableEnv[key] = value;
    }
  }
}

function setForgedAdminHeaders(): void {
  headersMock.mockReturnValue({
    get(name: string) {
      const map = new Map<string, string>([
        ["x-wain-admin-uid", "attacker-uid"],
        ["x-wain-admin-email", "attacker@example.com"],
        ["x-wain-admin-role", "super_admin"],
        ["x-wain-admin-admin", "true"],
        ["x-wain-admin-is-admin", "true"],
      ]);
      return map.get(name) ?? null;
    },
  });
}

describe("security: forged header sessions", () => {
  let envBefore: EnvSnapshot;

  beforeEach(() => {
    envBefore = snapshotEnv();
    vi.clearAllMocks();
    cookiesMock.mockReturnValue({
      get() {
        return undefined;
      },
    });
    verifyAdminSessionCookieWithProfileMock.mockResolvedValue(undefined);
    setForgedAdminHeaders();
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    restoreEnv(envBefore);
  });

  it("rejects forged admin headers in production even if unsafe flag is set", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION", "true");

    await expect(readHeaderBasedSessionContext()).resolves.toBeNull();
    await expect(readRuntimeAdminSessionContext()).resolves.toBeNull();
    await expect(getCurrentAdminSession()).resolves.toBeNull();
  });

  it("allows header session only in non-production when explicit unsafe flag is enabled", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION", "true");

    const context = await readHeaderBasedSessionContext();
    expect(context).toMatchObject({
      uid: "attacker-uid",
      claims: {
        role: "super_admin",
        admin: true,
      },
    });
  });

  it("denies header session when unsafe flag is not explicitly enabled", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION", "");

    await expect(readHeaderBasedSessionContext()).resolves.toBeNull();
    await expect(readRuntimeAdminSessionContext()).resolves.toBeNull();
  });

  it("rejects WAIN_ADMIN_SESSION_JSON in production", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv(
      "WAIN_ADMIN_SESSION_JSON",
      JSON.stringify({
        uid: "json-attacker",
        claims: {
          role: "super_admin",
          admin: true,
          isAdmin: true,
        },
      }),
    );

    await expect(readRuntimeAdminSessionContext()).resolves.toBeNull();
    await expect(getCurrentAdminSession()).resolves.toBeNull();
  });
});
