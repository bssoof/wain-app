import { afterEach, describe, expect, it, vi } from "vitest";

import {
  createFinanceCommandProxyTransport,
  type ProxyTransportResponseBody,
} from "./finance-command-proxy-transport";
import type { FinanceCommandResponseMap } from "./command-contracts";

const READINESS_COMMAND = "verify_wallet_readiness" as const;

function readinessResponse(
  overrides?: Partial<FinanceCommandResponseMap[typeof READINESS_COMMAND]>,
): FinanceCommandResponseMap[typeof READINESS_COMMAND] {
  return {
    action: READINESS_COMMAND,
    status: "PASS",
    warningChecks: [],
    failureChecks: [],
    checkedAt: "2026-04-19T00:00:00.000Z",
    ...overrides,
  };
}

function jsonResponse(status: number, body: ProxyTransportResponseBody): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    text: async () => JSON.stringify(body),
  } as Response;
}

function readinessCommandRequest(correlationId: string) {
  return {
    action: READINESS_COMMAND,
    commandId: `cmd-${correlationId}`,
    correlationId,
    reason: "proxy transport test",
    submittedAt: "2026-04-19T00:00:00.000Z",
  };
}

afterEach(() => {
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
});

describe("createFinanceCommandProxyTransport", () => {
  it("sends finance command through admin proxy endpoint", async () => {
    const fetchImpl = vi.fn(
      async (_input: RequestInfo | URL, _init?: RequestInit) =>
      jsonResponse(200, {
        ok: true,
        correlationId: "corr-proxy-1",
        data: readinessResponse(),
      }),
    );

    const transport = createFinanceCommandProxyTransport({
      fetchImpl,
      resolveAuthToken: async () => "id-token-1",
      resolveAppCheckToken: async () => "app-check-1",
    });

    const result = await transport.execute(
      READINESS_COMMAND,
      readinessCommandRequest("corr-proxy-1"),
    );

    expect(result.ok).toBe(true);
    if (!result.ok) {
      return;
    }

    expect(result.data.status).toBe("PASS");
    expect(fetchImpl).toHaveBeenCalledTimes(1);
    expect(fetchImpl).toHaveBeenCalledWith(
      "/api/admin/command/finance",
      expect.objectContaining({
        method: "POST",
        cache: "no-store",
        headers: expect.objectContaining({
          "Content-Type": "application/json",
          Authorization: "Bearer id-token-1",
          "X-Firebase-AppCheck": "app-check-1",
        }),
      }),
    );
  });

  it("omits default static app check token in production runtime", async () => {
    vi.stubEnv("NODE_ENV", "production");

    const fetchImpl = vi.fn(
      async (_input: RequestInfo | URL, _init?: RequestInit) =>
      jsonResponse(200, {
        ok: true,
        correlationId: "corr-proxy-2",
        data: readinessResponse(),
      }),
    );

    const transport = createFinanceCommandProxyTransport({
      fetchImpl,
      resolveAuthToken: async () => "id-token-2",
    });

    await transport.execute(
      READINESS_COMMAND,
      readinessCommandRequest("corr-proxy-2"),
    );

    const call = fetchImpl.mock.calls[0];
    expect(call).toBeDefined();
    if (!call) {
      return;
    }

    const init = call[1] as RequestInit | undefined;
    const headers = (init?.headers ?? {}) as Record<string, string>;
    expect(headers.Authorization).toBe("Bearer id-token-2");
    expect(headers["X-Firebase-AppCheck"]).toBeUndefined();
  });
});
