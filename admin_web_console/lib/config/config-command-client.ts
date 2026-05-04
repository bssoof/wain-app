import type { AdminSession } from "@/lib/auth/guard-api";

import {
  createConfigCommandError,
  isConfigCommandErrorCode,
  type ConfigCommandError,
  type ConfigCommandErrorCode,
  type ConfigCommandRequestMap,
  type ConfigCommandResponseMap,
  type ConfigCommandType,
} from "./config-command-contracts";
import { authorizeConfigCommand } from "./config-command-policy";
import type {
  ConfigCommandTransport,
  ConfigCommandTransportResult,
} from "./config-command-transport";

const STATUS_TO_ERROR_CODE: Record<number, ConfigCommandErrorCode> = {
  401: "unauthorized",
  403: "forbidden",
  409: "conflict",
  422: "validation_error",
  503: "unavailable",
};

export type ConfigCommandResult<T extends ConfigCommandType> =
  | {
      ok: true;
      command: T;
      commandId: string;
      correlationId: string;
      data: ConfigCommandResponseMap[T];
    }
  | {
      ok: false;
      command: T;
      commandId: string;
      correlationId: string;
      error: ConfigCommandError;
    };

export function createConfigCommandClient(transport: ConfigCommandTransport) {
  return {
    async execute<T extends ConfigCommandType>(input: {
      session: AdminSession | null;
      command: T;
      request: ConfigCommandRequestMap[T];
    }): Promise<ConfigCommandResult<T>> {
      const authResult = authorizeConfigCommand(input.session, input.command);

      if (!authResult.allowed) {
        return {
          ok: false,
          command: input.command,
          commandId: input.request.commandId,
          correlationId: input.request.correlationId,
          error: authResult.error,
        };
      }

      try {
        const transportResult: ConfigCommandTransportResult<T> =
          await transport.execute(input.command, input.request);

        if (transportResult.ok) {
          return {
            ok: true,
            command: input.command,
            commandId: input.request.commandId,
            correlationId: transportResult.correlationId ?? input.request.correlationId,
            data: transportResult.data,
          };
        }

        return {
          ok: false,
          command: input.command,
          commandId: input.request.commandId,
          correlationId: transportResult.correlationId ?? input.request.correlationId,
          error: normalizeConfigCommandError(transportResult.error),
        };
      } catch (error) {
        return {
          ok: false,
          command: input.command,
          commandId: input.request.commandId,
          correlationId: input.request.correlationId,
          error: normalizeConfigCommandError(error),
        };
      }
    },
  };
}

export function normalizeConfigCommandError(rawError: unknown): ConfigCommandError {
  if (isRecord(rawError)) {
    const status = typeof rawError.status === "number" ? rawError.status : undefined;
    const codeFromStatus = status ? STATUS_TO_ERROR_CODE[status] : undefined;

    if (codeFromStatus) {
      return createConfigCommandError(
        codeFromStatus,
        toMessage(rawError.message, "Config governance command failed."),
        toDetails(rawError.details),
      );
    }

    if (isConfigCommandErrorCode(rawError.code)) {
      return createConfigCommandError(
        rawError.code,
        toMessage(rawError.message, "Config governance command failed."),
        toDetails(rawError.details),
      );
    }

    return createConfigCommandError(
      "unavailable",
      toMessage(rawError.message, "Config governance transport is unavailable."),
      toDetails(rawError),
    );
  }

  if (rawError instanceof Error) {
    return createConfigCommandError("unavailable", rawError.message);
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return createConfigCommandError("unavailable", rawError.trim());
  }

  return createConfigCommandError(
    "unavailable",
    "Config governance transport is unavailable.",
  );
}

function isRecord(value: unknown): value is Record<string, any> {
  return Boolean(value && typeof value === "object");
}

function toMessage(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim().length > 0 ? value : fallback;
}

function toDetails(value: unknown): Record<string, unknown> | undefined {
  if (!isRecord(value)) {
    return undefined;
  }

  const details: Record<string, unknown> = {};
  for (const [key, entry] of Object.entries(value)) {
    details[key] = entry;
  }
  return details;
}
