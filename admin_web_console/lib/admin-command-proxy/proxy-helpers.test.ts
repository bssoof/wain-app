import { afterEach, describe, expect, it, vi } from "vitest";

const {
  resolveServerAppCheckTokenForAdminProxyMock,
  resolveServerAuthTokenForAdminProxyMock,
} = vi.hoisted(() => ({
  resolveServerAppCheckTokenForAdminProxyMock: vi.fn(),
  resolveServerAuthTokenForAdminProxyMock: vi.fn(),
}));

vi.mock("@/lib/firebase/server-app-check", () => ({
  resolveServerAppCheckTokenForAdminProxy: (...args: unknown[]) =>
    resolveServerAppCheckTokenForAdminProxyMock(...args),
}));

vi.mock("@/lib/firebase/server-auth-token", () => ({
  resolveServerAuthTokenForAdminProxy: (...args: unknown[]) =>
    resolveServerAuthTokenForAdminProxyMock(...args),
}));

import { resolveCallableProxyConfig } from "@/app/api/admin/command/shared/proxy-helpers";

const LIVE_BASE_URL = "https://us-central1-wain-d2e28.cloudfunctions.net";

function buildOptions(
  envOverrides: Record<string, string | undefined> = {},
) {
  return {
    serviceLabel: "Venue command",
    env: {
      NODE_ENV: "production",
      NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL: LIVE_BASE_URL,
      ...envOverrides,
    },
    baseUrlEnvKeys: ["NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL"],
    serverAuthTokenEnvKeys: ["WAIN_VENUE_SERVER_AUTH_TOKEN"],
    serverAppCheckTokenEnvKeys: ["WAIN_VENUE_SERVER_APP_CHECK_TOKEN"],
  };
}

function createRequest(overrides?: {
  authorization?: string;
  appCheck?: string;
}): Request {
  return new Request("https://wain-admin.web.app/api/admin/command/venues", {
    method: "POST",
    headers: {
      ...(overrides?.authorization
        ? { Authorization: `Bearer ${overrides.authorization}` }
        : {}),
      ...(overrides?.appCheck
        ? { "X-Firebase-AppCheck": overrides.appCheck }
        : {}),
    },
  });
}

afterEach(() => {
  resolveServerAppCheckTokenForAdminProxyMock.mockReset();
  resolveServerAuthTokenForAdminProxyMock.mockReset();
  vi.restoreAllMocks();
});

describe("resolveCallableProxyConfig", () => {
  it("prefers configured server App Check token", async () => {
    resolveServerAppCheckTokenForAdminProxyMock.mockResolvedValue("minted-app-check");

    const result = await resolveCallableProxyConfig(
      createRequest({ authorization: "id-token-1" }),
      buildOptions({ WAIN_VENUE_SERVER_APP_CHECK_TOKEN: "env-app-check" }),
    );

    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }

    expect(result.appCheckToken).toBe("env-app-check");
    expect(resolveServerAppCheckTokenForAdminProxyMock).not.toHaveBeenCalled();
  });

  it("uses minted server App Check token for live URLs when env token is missing", async () => {
    resolveServerAppCheckTokenForAdminProxyMock.mockResolvedValue("minted-app-check");

    const result = await resolveCallableProxyConfig(
      createRequest({ authorization: "id-token-2" }),
      buildOptions(),
    );

    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }

    expect(result.appCheckToken).toBe("minted-app-check");
    expect(resolveServerAppCheckTokenForAdminProxyMock).toHaveBeenCalledTimes(1);
  });

  it("falls back to request App Check token when minting is unavailable", async () => {
    resolveServerAppCheckTokenForAdminProxyMock.mockResolvedValue(undefined);

    const result = await resolveCallableProxyConfig(
      createRequest({
        authorization: "id-token-3",
        appCheck: "request-app-check",
      }),
      buildOptions(),
    );

    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }

    expect(result.appCheckToken).toBe("request-app-check");
  });

  it("returns 403 when live App Check token is unavailable", async () => {
    resolveServerAppCheckTokenForAdminProxyMock.mockResolvedValue(undefined);

    const result = await resolveCallableProxyConfig(
      createRequest({ authorization: "id-token-4" }),
      buildOptions(),
    );

    expect(result.ok).toBe(false);
    if (result.ok) {
      return;
    }

    expect(result.error.status).toBe(403);
    expect(result.error.message).toContain("requires an App Check token");
  });

  it("uses a minted server auth token when session context is provided", async () => {
    resolveServerAppCheckTokenForAdminProxyMock.mockResolvedValue("minted-app-check");
    resolveServerAuthTokenForAdminProxyMock.mockResolvedValue("minted-auth-token");

    const result = await resolveCallableProxyConfig(
      createRequest({ authorization: "request-id-token" }),
      {
        ...buildOptions(),
        session: {
          uid: "admin-uid-1",
          primaryRole: "super_admin",
          roles: ["super_admin"],
        },
      },
    );

    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }

    expect(result.authToken).toBe("minted-auth-token");
    expect(resolveServerAuthTokenForAdminProxyMock).toHaveBeenCalledTimes(1);
  });
});
