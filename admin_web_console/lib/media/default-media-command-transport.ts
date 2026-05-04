import {
  createFinanceCallableInvokerFromEnv,
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
  type FinanceCallableInvokerResolution,
} from "@/lib/finance/finance-command-transport";

import { createMediaCommandAdaptersTransport } from "./media-command-adapters";
import { createMediaCommandProxyTransport } from "./media-command-proxy-transport";
import type { MediaCommandTransport } from "./media-command-transport";

function createMediaCallableInvokerFromEnv(
  env: Record<string, string | undefined> = process.env,
): FinanceCallableInvokerResolution {
  return createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      env.NEXT_PUBLIC_WAIN_MEDIA_AUTH_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      env.NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
  });
}

function buildDefaultMediaEnv(): Record<string, string | undefined> {
  return {
    NODE_ENV: process.env.NODE_ENV,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
    NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_MEDIA_AUTH_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_MEDIA_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN,
  };
}

export function createDefaultMediaCommandTransport(): MediaCommandTransport {
  const env = buildDefaultMediaEnv();
  const transportMode = resolveDefaultMediaTransportMode(env);
  if (transportMode === "proxy") {
    return createMediaCommandProxyTransport();
  }

  const callableInvokerResolution = createMediaCallableInvokerFromEnv(env);

  if (callableInvokerResolution.ok) {
    return createMediaCommandAdaptersTransport({
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
            `Media action transport is not connected. ${callableInvokerResolution.reason}`,
        },
      };
    },
  };
}

export type DefaultMediaTransportMode = "proxy" | "callable";

export function resolveDefaultMediaTransportMode(
  env: Record<string, string | undefined> = process.env,
): DefaultMediaTransportMode {
  const baseUrl =
    env.NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL?.trim() ||
    env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL?.trim() ||
    env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim();

  if (!baseUrl) {
    return "callable";
  }

  if (isProductionRuntime(env) && isLiveFirebaseFunctionsUrl(baseUrl)) {
    return "proxy";
  }

  return "callable";
}
