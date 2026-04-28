import type { AdminSession } from "@/lib/auth/guard-api";

import {
  createFinanceCommandError,
  isFinanceCommandErrorCode,
  type FinanceCommandError,
  type FinanceCommandErrorCode,
  type FinanceCommandFailure,
  type FinanceCommandRequestMap,
  type FinanceCommandResult,
  type FinanceCommandType,
} from "./command-contracts";
import { authorizeFinanceCommand } from "./command-policy";
import type { FinanceCommandTransport } from "./finance-command-transport";

export type {
  FinanceCommandTransport,
  FinanceCommandTransportFailure,
  FinanceCommandTransportResult,
  FinanceCommandTransportSuccess,
} from "./finance-command-transport";

const STATUS_TO_ERROR_CODE: Record<number, FinanceCommandErrorCode> = {
  401: "unauthorized",
  403: "forbidden",
  409: "conflict",
  422: "validation_error",
  503: "unavailable",
};

export type ExecuteFinanceCommandInput<T extends FinanceCommandType> = {
  session: AdminSession | null;
  command: T;
  request: FinanceCommandRequestMap[T];
};

export function createFinanceCommandClient(transport: FinanceCommandTransport) {
  return {
    async execute<T extends FinanceCommandType>(
      input: ExecuteFinanceCommandInput<T>,
    ): Promise<FinanceCommandResult<T>> {
      const { session, command, request } = input;
      const authResult = authorizeFinanceCommand(session, command);

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
          normalizeFinanceCommandError(transportResult.error),
          transportResult.correlationId,
        );
      } catch (error) {
        return toFailure(command, request, normalizeFinanceCommandError(error));
      }
    },
  };
}

export function normalizeFinanceCommandError(rawError: unknown): FinanceCommandError {
  if (isRecord(rawError)) {
    const status = typeof rawError.status === "number" ? rawError.status : undefined;
    const codeFromStatus = status ? STATUS_TO_ERROR_CODE[status] : undefined;

    if (codeFromStatus) {
      return createFinanceCommandError(
        codeFromStatus,
        toMessage(rawError.message, "Finance command failed."),
        toDetails(rawError.details),
      );
    }

    if (isFinanceCommandErrorCode(rawError.code)) {
      return createFinanceCommandError(
        rawError.code,
        toMessage(rawError.message, "Finance command failed."),
        toDetails(rawError.details),
      );
    }

    return createFinanceCommandError(
      "unavailable",
      toMessage(rawError.message, "Finance command transport is unavailable."),
      toDetails(rawError),
    );
  }

  if (rawError instanceof Error) {
    return createFinanceCommandError("unavailable", rawError.message);
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return createFinanceCommandError("unavailable", rawError.trim());
  }

  return createFinanceCommandError(
    "unavailable",
    "Finance command transport is unavailable.",
  );
}

function toFailure<T extends FinanceCommandType>(
  command: T,
  request: FinanceCommandRequestMap[T],
  error: FinanceCommandError,
  correlationId?: string,
): FinanceCommandFailure<T> {
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
