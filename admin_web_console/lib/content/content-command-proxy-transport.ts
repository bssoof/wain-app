import {
  executeProxyCommand,
  type AdminCommandProxyTransportOptions,
} from "@/lib/admin-command-proxy/proxy-client";

import type {
  ContentModerationResult,
  ModerateOfferCommand,
  ModerateStoryCommand,
} from "./content-command-contracts";
import type { ContentCommandTransport } from "./content-command-transport";

const DEFAULT_CONTENT_COMMAND_PROXY_ENDPOINT = "/api/admin/command/content";

export type ContentCommandProxyTransportOptions = AdminCommandProxyTransportOptions;

export function createContentCommandProxyTransport(
  options: ContentCommandProxyTransportOptions = {},
): ContentCommandTransport {
  const endpoint =
    options.endpoint?.trim() || DEFAULT_CONTENT_COMMAND_PROXY_ENDPOINT;

  return {
    async moderateOffer(command: ModerateOfferCommand): Promise<ContentModerationResult> {
      const result = await executeProxyCommand<ContentModerationResult>(
        {
          endpoint,
          fetchImpl: options.fetchImpl,
          resolveAuthToken: options.resolveAuthToken,
          resolveAppCheckToken: options.resolveAppCheckToken,
        },
        {
          command: "offer",
          request: command,
        },
        command.correlationId,
      );

      if (result.ok) {
        return result.data;
      }

      throw result.error;
    },

    async moderateStory(command: ModerateStoryCommand): Promise<ContentModerationResult> {
      const result = await executeProxyCommand<ContentModerationResult>(
        {
          endpoint,
          fetchImpl: options.fetchImpl,
          resolveAuthToken: options.resolveAuthToken,
          resolveAppCheckToken: options.resolveAppCheckToken,
        },
        {
          command: "story",
          request: command,
        },
        command.correlationId,
      );

      if (result.ok) {
        return result.data;
      }

      throw result.error;
    },
  };
}
