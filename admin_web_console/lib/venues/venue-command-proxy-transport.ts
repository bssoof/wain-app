import {
  executeProxyCommand,
  type AdminCommandProxyTransportOptions,
} from "@/lib/admin-command-proxy/proxy-client";

import type {
  VenueCommandRequest,
  VenueCommandResponse,
} from "./venue-command-contracts";
import type {
  VenueCommandTransportResult,
  VenueManagementTransport,
} from "./venue-command-adapters";

const DEFAULT_VENUE_COMMAND_PROXY_ENDPOINT = "/api/admin/command/venues";

export type VenueCommandProxyTransportOptions = AdminCommandProxyTransportOptions;

export function createVenueCommandProxyTransport(
  options: VenueCommandProxyTransportOptions = {},
): VenueManagementTransport {
  const endpoint = options.endpoint?.trim() || DEFAULT_VENUE_COMMAND_PROXY_ENDPOINT;

  return {
    async execute(command: VenueCommandRequest): Promise<VenueCommandTransportResult> {
      const result = await executeProxyCommand<VenueCommandResponse>(
        {
          endpoint,
          fetchImpl: options.fetchImpl,
          resolveAuthToken: options.resolveAuthToken,
          resolveAppCheckToken: options.resolveAppCheckToken,
        },
        {
          command: command.action,
          request: command,
        },
        command.correlationId,
      );

      if (result.ok) {
        return {
          ok: true,
          correlationId: result.correlationId ?? command.correlationId,
          data: result.data,
        };
      }

      return {
        ok: false,
        correlationId: result.correlationId ?? command.correlationId,
        error: result.error,
      };
    },
  };
}
