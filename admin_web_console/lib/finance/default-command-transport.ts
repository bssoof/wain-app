import { createFinanceCommandAdaptersTransport } from "./finance-command-adapters";
import { createFinanceCommandProxyTransport } from "./finance-command-proxy-transport";
import {
  createFinanceCallableInvokerFromEnv,
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
  type FinanceCommandTransport,
} from "./finance-command-transport";

/**
 * Phase 2 default transport: no direct data writes and no fake success.
 * Replace with Prompt A HTTP/streaming adapter when wiring production execution.
 *
 * NOTE: Next.js only inlines NEXT_PUBLIC_* env vars when accessed as literal
 * property lookups on process.env. Passing `process.env` as a dynamic object
 * does NOT work on the client side.
 */
export function createDefaultFinanceCommandTransport(): FinanceCommandTransport {
  const env: Record<string, string | undefined> = {
    NODE_ENV: process.env.NODE_ENV,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN: process.env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN: process.env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
  };

  const transportMode = resolveDefaultFinanceTransportMode(env);
  if (transportMode === "proxy") {
    return createFinanceCommandProxyTransport();
  }

  const callableInvokerResolution = createFinanceCallableInvokerFromEnv(env);

  if (callableInvokerResolution.ok) {
    return createFinanceCommandAdaptersTransport({
      invokeCallable: callableInvokerResolution.invokeCallable,
    });
  }

  return {
    async execute() {
      return {
        ok: false,
        error: {
          status: 503,
          message:
            `Finance command transport is not connected. ${callableInvokerResolution.reason}`,
        },
      };
    },
  };
}

export type DefaultFinanceTransportMode = "proxy" | "callable";

export function resolveDefaultFinanceTransportMode(
  env: Record<string, string | undefined> = process.env,
): DefaultFinanceTransportMode {
  const baseUrl = env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim();
  if (!baseUrl) {
    return "callable";
  }

  if (isProductionRuntime(env) && isLiveFirebaseFunctionsUrl(baseUrl)) {
    return "proxy";
  }

  return "callable";
}
