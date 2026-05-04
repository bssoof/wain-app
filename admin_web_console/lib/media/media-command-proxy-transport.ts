import {
  executeProxyCommand,
  type AdminCommandProxyTransportOptions,
} from "@/lib/admin-command-proxy/proxy-client";

import type {
  MediaCommandRequestMap,
  MediaCommandResponseMap,
  MediaCommandType,
} from "./media-command-contracts";
import type {
  MediaCommandTransport,
  MediaCommandTransportResult,
} from "./media-command-transport";

const DEFAULT_MEDIA_COMMAND_PROXY_ENDPOINT = "/api/admin/command/media";

export type MediaCommandProxyTransportOptions = AdminCommandProxyTransportOptions;

export function createMediaCommandProxyTransport(
  options: MediaCommandProxyTransportOptions = {},
): MediaCommandTransport {
  const endpoint = options.endpoint?.trim() || DEFAULT_MEDIA_COMMAND_PROXY_ENDPOINT;

  return {
    async execute<T extends MediaCommandType>(
      command: T,
      request: MediaCommandRequestMap[T],
    ): Promise<MediaCommandTransportResult<T>> {
      const result = await executeProxyCommand<MediaCommandResponseMap[T]>(
        {
          endpoint,
          fetchImpl: options.fetchImpl,
          resolveAuthToken: options.resolveAuthToken,
          resolveAppCheckToken: options.resolveAppCheckToken,
        },
        {
          command,
          request,
        },
        request.correlationId,
      );

      if (result.ok) {
        return {
          ok: true,
          correlationId: result.correlationId ?? request.correlationId,
          data: result.data,
        };
      }

      return {
        ok: false,
        correlationId: result.correlationId ?? request.correlationId,
        error: result.error,
      };
    },
  };
}
