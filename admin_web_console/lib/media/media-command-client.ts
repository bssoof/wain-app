import type { AdminSession } from "@/lib/auth/guard-api";

import {
  createMediaCommandError,
  isMediaCommandErrorCode,
  type MediaCommandError,
  type MediaCommandErrorCode,
  type MediaCommandFailure,
  type MediaCommandRequestMap,
  type MediaCommandResult,
  type MediaCommandType,
} from "./media-command-contracts";
import { authorizeMediaCommand } from "./media-command-policy";
import type { MediaCommandTransport } from "./media-command-transport";

const STATUS_TO_ERROR_CODE: Record<number, MediaCommandErrorCode> = {
  401: "unauthorized",
  403: "forbidden",
  409: "conflict",
  422: "validation_error",
  503: "unavailable",
};

export type ExecuteMediaCommandInput<T extends MediaCommandType> = {
  session: AdminSession | null;
  command: T;
  request: MediaCommandRequestMap[T];
};

export function createMediaCommandClient(transport: MediaCommandTransport) {
  return {
    async execute<T extends MediaCommandType>(
      input: ExecuteMediaCommandInput<T>,
    ): Promise<MediaCommandResult<T>> {
      const { session, command, request } = input;
      const authResult = authorizeMediaCommand(session, command);

      if (!authResult.allowed) {
        return toFailure(command, request, authResult.error);
      }

      try {
        const transportResult = await transport.execute(command, request);
        if (transportResult.ok) {
          return {
            ok: true,
            command,
            commandId: request.commandId,
            correlationId: transportResult.correlationId ?? request.correlationId,
            data: transportResult.data,
          };
        }

        return toFailure(
          command,
          request,
          normalizeMediaCommandError(transportResult.error),
          transportResult.correlationId,
        );
      } catch (error) {
        return toFailure(command, request, normalizeMediaCommandError(error));
      }
    },
  };
}

export function normalizeMediaCommandError(rawError: unknown): MediaCommandError {
  if (isRecord(rawError)) {
    const status = typeof rawError.status === "number" ? rawError.status : undefined;
    const codeFromStatus = status ? STATUS_TO_ERROR_CODE[status] : undefined;

    if (codeFromStatus) {
      return createMediaCommandError(
        codeFromStatus,
        toMessage(rawError.message, "Media command failed."),
        toDetails(rawError.details),
      );
    }

    if (isMediaCommandErrorCode(rawError.code)) {
      return createMediaCommandError(
        rawError.code,
        toMessage(rawError.message, "Media command failed."),
        toDetails(rawError.details),
      );
    }

    return createMediaCommandError(
      "unavailable",
      toMessage(rawError.message, "Media command transport is unavailable."),
      toDetails(rawError),
    );
  }

  if (rawError instanceof Error) {
    return createMediaCommandError("unavailable", rawError.message);
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return createMediaCommandError("unavailable", rawError.trim());
  }

  return createMediaCommandError(
    "unavailable",
    "Media command transport is unavailable.",
  );
}

function toFailure<T extends MediaCommandType>(
  command: T,
  request: MediaCommandRequestMap[T],
  error: MediaCommandError,
  correlationId?: string,
): MediaCommandFailure<T> {
  return {
    ok: false,
    command,
    commandId: request.commandId,
    correlationId: correlationId ?? request.correlationId,
    error,
  };
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
