import { describe, expect, it, vi } from "vitest";

import {
  createHttpsCallableInvoker,
  createFinanceCallableInvokerFromEnv,
  mapBackendErrorToTransportError,
} from "./finance-command-transport";

describe("mapBackendErrorToTransportError", () => {
  it("keeps failed precondition business conflicts as conflicts", () => {
    expect(
      mapBackendErrorToTransportError({
        code: "failed-precondition",
        message: "reversal_request_expired",
      }),
    ).toMatchObject({
      status: 409,
      message: "reversal_request_expired",
    });
  });

  it("maps App Check failures to forbidden instead of conflict", () => {
    expect(
      mapBackendErrorToTransportError({
        code: "failed-precondition",
        message: "App Check verification failed",
      }),
    ).toMatchObject({
      status: 403,
      message: "App Check verification failed",
    });
  });

  it("rejects live callable transport when App Check token is missing", () => {
    expect(
      createFinanceCallableInvokerFromEnv({
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
          "https://us-central1-wain-d2e28.cloudfunctions.net",
      }),
    ).toMatchObject({
      ok: false,
      reason:
        "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is not configured for live callable transport.",
    });
  });

  it("rejects placeholder App Check tokens for live callable transport", () => {
    expect(
      createFinanceCallableInvokerFromEnv({
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
          "https://us-central1-wain-d2e28.cloudfunctions.net",
        NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN: "local-dev-app-check",
      }),
    ).toMatchObject({
      ok: false,
      reason:
        "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is a placeholder and cannot call live Firebase Functions.",
    });
  });

  it("allows placeholder App Check tokens for local emulator URLs", () => {
    expect(
      createFinanceCallableInvokerFromEnv({
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
          "http://127.0.0.1:5001/wain-d2e28/us-central1",
        NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN: "local-dev-app-check",
      }),
    ).toMatchObject({
      ok: true,
    });
  });

  it("marks callable fetch requests as no-store to avoid stale admin actions", async () => {
    const fetchImpl = vi.fn(async () => ({
      ok: true,
      status: 200,
      text: async () => JSON.stringify({ result: { success: true } }),
    })) as unknown as typeof fetch;

    const invokeCallable = createHttpsCallableInvoker({
      baseUrl: "http://127.0.0.1:5001/wain-d2e28/us-central1",
      authToken: "local-auth-token",
      appCheckToken: "local-dev-app-check",
      fetchImpl,
    });

    await invokeCallable("listMerchantTopUpRequestsForAdmin", { limit: 5 });

    expect(fetchImpl).toHaveBeenCalledWith(
      "http://127.0.0.1:5001/wain-d2e28/us-central1/listMerchantTopUpRequestsForAdmin",
      expect.objectContaining({
        method: "POST",
        cache: "no-store",
      }),
    );
  });
});
