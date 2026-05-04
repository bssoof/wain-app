import { createConfigCommandAdaptersTransport } from "./config-command-adapters";
import { createConfigCommandProxyTransport } from "./config-command-proxy-transport";
import { createConfigCallableInvokerFromEnv } from "./config-callable-env";
import type { ConfigCommandTransport } from "./config-command-transport";
import {
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
} from "@/lib/finance/finance-command-transport";

function buildDefaultConfigEnv(): Record<string, string | undefined> {
  return {
    NODE_ENV: process.env.NODE_ENV,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
    NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_CONFIG_AUTH_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_CONFIG_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN,
  };
}

export function createDefaultConfigCommandTransport(): ConfigCommandTransport {
  const env = buildDefaultConfigEnv();
  const transportMode = resolveDefaultConfigTransportMode(env);
  if (transportMode === "proxy") {
    return createConfigCommandProxyTransport();
  }

  const callableInvokerResolution = createConfigCallableInvokerFromEnv(env);

  if (callableInvokerResolution.ok) {
    return createConfigCommandAdaptersTransport({
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
            `Config governance transport is not connected. ${callableInvokerResolution.reason}`,
        },
      };
    },
  };
}

export type DefaultConfigTransportMode = "proxy" | "callable";

export function resolveDefaultConfigTransportMode(
  env: Record<string, string | undefined> = process.env,
): DefaultConfigTransportMode {
  const baseUrl =
    env.NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL?.trim() ||
    env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim();

  if (!baseUrl) {
    return "callable";
  }

  if (isProductionRuntime(env) && isLiveFirebaseFunctionsUrl(baseUrl)) {
    return "proxy";
  }

  return "callable";
}
