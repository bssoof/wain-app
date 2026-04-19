import { createVenueAdaptersTransport } from "./venue-command-adapters";
import { createVenueCallableInvokerFromEnv } from "./venue-callable-env";
import { createVenueCommandProxyTransport } from "./venue-command-proxy-transport";
import type { VenueManagementTransport } from "./venue-command-adapters";
import {
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
} from "@/lib/finance/finance-command-transport";

export function createDefaultVenueCommandTransport(): VenueManagementTransport {
  // Next.js only inlines NEXT_PUBLIC_* env vars when accessed as literal
  // property lookups on process.env (e.g. process.env.NEXT_PUBLIC_X).
  // Passing `process.env` as a dynamic object to a function does NOT work
  // on the client side because Next.js replaces only static references.
  const env: Record<string, string | undefined> = {
    NODE_ENV: process.env.NODE_ENV,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN: process.env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN: process.env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
    NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL: process.env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_VENUE_AUTH_TOKEN: process.env.NEXT_PUBLIC_WAIN_VENUE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN: process.env.NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN,
  };

  const transportMode = resolveDefaultVenueTransportMode(env);
  if (transportMode === "proxy") {
    return createVenueCommandProxyTransport();
  }

  const resolution = createVenueCallableInvokerFromEnv(env);

  if (resolution.ok) {
    return createVenueAdaptersTransport({
      invokeCallable: resolution.invokeCallable,
    });
  }

  return {
    async execute(command) {
      return {
        ok: false,
        correlationId: command.correlationId,
        error: {
          status: 503,
          message: `Venue management transport is unavailable. ${resolution.reason}`,
        },
      };
    },
  };
}

export type DefaultVenueTransportMode = "proxy" | "callable";

export function resolveDefaultVenueTransportMode(
  env: Record<string, string | undefined> = process.env,
): DefaultVenueTransportMode {
  const baseUrl =
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
