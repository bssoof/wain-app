import {
  executeProxyCommand,
  type AdminCommandProxyTransportOptions,
} from "@/lib/admin-command-proxy/proxy-client";

import type {
  ConfigCommandRequestMap,
  ConfigCommandResponseMap,
  ConfigCommandType,
} from "./config-command-contracts";
import type {
  ConfigCommandTransport,
  ConfigCommandTransportResult,
} from "./config-command-transport";

const DEFAULT_CONFIG_COMMAND_PROXY_ENDPOINT = "/api/admin/command/config";

export type ConfigCommandProxyTransportOptions = AdminCommandProxyTransportOptions;

export function createConfigCommandProxyTransport(
  options: ConfigCommandProxyTransportOptions = {},
): ConfigCommandTransport {
  const endpoint =
    options.endpoint?.trim() || DEFAULT_CONFIG_COMMAND_PROXY_ENDPOINT;

  return {
    async execute<T extends ConfigCommandType>(
      command: T,
      request: ConfigCommandRequestMap[T],
    ): Promise<ConfigCommandTransportResult<T>> {
      const result = await executeProxyCommand<ConfigCommandResponseMap[T]>(
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
