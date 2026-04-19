import {
  createFinanceCallableInvokerFromEnv,
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
  type FinanceCallableInvokerResolution,
} from "@/lib/finance/finance-command-transport";

import { createReviewModerationAdaptersTransport } from "./review-moderation-adapters";
import { createReviewModerationProxyTransport } from "./review-moderation-proxy-transport";
import type { ReviewModerationTransport } from "./review-moderation-transport";

function createContentCallableInvokerFromEnv(
  env: Record<string, string | undefined> = process.env,
): FinanceCallableInvokerResolution {
  return createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      env.NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      env.NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
  });
}

function buildDefaultReviewEnv(): Record<string, string | undefined> {
  return {
    NODE_ENV: process.env.NODE_ENV,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
    NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN:
      process.env.NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN,
  };
}

export function createDefaultReviewModerationTransport(): ReviewModerationTransport {
  const env = buildDefaultReviewEnv();
  const transportMode = resolveDefaultReviewModerationTransportMode(env);
  if (transportMode === "proxy") {
    return createReviewModerationProxyTransport();
  }

  const resolution = createContentCallableInvokerFromEnv(env);

  if (resolution.ok) {
    return createReviewModerationAdaptersTransport({
      invokeCallable: resolution.invokeCallable,
    });
  }

  return {
    async execute() {
      return {
        ok: false,
        error: {
          status: 503,
          message:
            `Reviews moderation transport is not connected. ${resolution.reason}`,
        },
      };
    },
  };
}

export type DefaultReviewModerationTransportMode = "proxy" | "callable";

export function resolveDefaultReviewModerationTransportMode(
  env: Record<string, string | undefined> = process.env,
): DefaultReviewModerationTransportMode {
  const baseUrl =
    env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL?.trim() ||
    env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim();

  if (!baseUrl) {
    return "callable";
  }

  if (isProductionRuntime(env) && isLiveFirebaseFunctionsUrl(baseUrl)) {
    return "proxy";
  }

  return "callable";
}
