import { createContentModerationAdaptersTransport } from "./content-command-adapters";
import { createContentCommandProxyTransport } from "./content-command-proxy-transport";
import { createContentCallableInvokerFromEnv } from "./content-callable-env";
import type { ContentCommandTransport } from "./content-command-transport";
import type {
  ModerateOfferCommand,
  ModerateStoryCommand,
  ContentModerationResult,
} from "./content-command-contracts";
import {
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
} from "@/lib/finance/finance-command-transport";

function buildDefaultContentEnv(): Record<string, string | undefined> {
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

export class DefaultContentCommandTransport implements ContentCommandTransport {
  private readonly transport: ContentCommandTransport | null;
  private readonly unavailableMessage: string;

  constructor(env: Record<string, string | undefined> = buildDefaultContentEnv()) {
    const transportMode = resolveDefaultContentTransportMode(env);
    if (transportMode === "proxy") {
      this.transport = createContentCommandProxyTransport();
      this.unavailableMessage = "";
      return;
    }

    const resolution = createContentCallableInvokerFromEnv(env);
    if (resolution.ok) {
      const adaptersTransport = createContentModerationAdaptersTransport({
        invokeCallable: resolution.invokeCallable,
      });
      this.transport = {
        async moderateOffer(command) {
          const result = await adaptersTransport.executeOffer(command.action, command);
          if (result.ok) {
            return result.data;
          }
          throw result.error;
        },
        async moderateStory(command) {
          const result = await adaptersTransport.executeStory(command.action, command);
          if (result.ok) {
            return result.data;
          }
          throw result.error;
        },
      };
      this.unavailableMessage = "";
      return;
    }

    this.transport = null;
    this.unavailableMessage =
      `Content moderation transport is not connected. ${resolution.reason}`;
  }

  async moderateOffer(command: ModerateOfferCommand): Promise<ContentModerationResult> {
    if (!this.transport) {
      throw this.buildUnavailableError("contentModerateOffer", command.commandId);
    }

    return this.transport.moderateOffer(command);
  }

  async moderateStory(command: ModerateStoryCommand): Promise<ContentModerationResult> {
    if (!this.transport) {
      throw this.buildUnavailableError("contentModerateStory", command.commandId);
    }

    return this.transport.moderateStory(command);
  }

  private buildUnavailableError(callableName: string, commandId: string): Error {
    return new Error(
      `${this.unavailableMessage} Callable=${callableName}, commandId=${commandId}.`,
    );
  }
}

export type DefaultContentTransportMode = "proxy" | "callable";

export function resolveDefaultContentTransportMode(
  env: Record<string, string | undefined> = process.env,
): DefaultContentTransportMode {
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
