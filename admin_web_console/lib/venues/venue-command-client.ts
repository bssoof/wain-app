import type { AdminSession } from "@/lib/auth/guard-api";
import type {
  VenueCommandError,
  VenueCommandRequest,
  VenueCommandResult,
  VenueCommandType,
} from "./venue-command-contracts";
import { createVenueCommandError } from "./venue-command-contracts";
import type { VenueManagementTransport } from "./venue-command-adapters";
import { canExecuteVenueCommand, getVenueCommandDenialReason } from "./venue-command-policy";

const STATUS_TO_ERROR_CODE = {
  401: "unauthorized",
  403: "forbidden",
  409: "conflict",
  422: "validation_error",
  503: "unavailable",
} as const;

export type VenueCommandClientDeps = {
  transport: VenueManagementTransport;
  session: AdminSession;
};

export function createVenueCommandClient(deps: VenueCommandClientDeps) {
  return {
    async execute<T extends VenueCommandType>(
      request: VenueCommandRequest & { action: T },
    ): Promise<VenueCommandResult<T>> {
      // 1. Policy check
      if (!canExecuteVenueCommand(deps.session, request.action)) {
        const reason = getVenueCommandDenialReason(deps.session, request.action);
        return {
          ok: false,
          command: request.action as T,
          commandId: request.commandId,
          correlationId: request.correlationId,
          error: createVenueCommandError(
            "forbidden",
            reason ?? `Not authorized for ${request.action}`,
          ),
        };
      }

      // 2. Transport execution
      const result = await deps.transport.execute(request);

      if (result.ok) {
        return {
          ok: true,
          command: request.action as T,
          commandId: request.commandId,
          correlationId: request.correlationId,
          data: result.data as any,
        };
      }

      // 3. Error handling
      const error = normalizeVenueCommandError(result.error, request.action);

      return {
        ok: false,
        command: request.action as T,
        commandId: request.commandId,
        correlationId: request.correlationId,
        error,
      };
    },
  };
}

function normalizeVenueCommandError(
  rawError: unknown,
  action: VenueCommandType,
): VenueCommandError {
  if (isRecord(rawError)) {
    const status =
      typeof rawError.status === "number" ? rawError.status : undefined;
    const codeFromStatus =
      status && status in STATUS_TO_ERROR_CODE
        ? STATUS_TO_ERROR_CODE[status as keyof typeof STATUS_TO_ERROR_CODE]
        : undefined;

    if (codeFromStatus) {
      return createVenueCommandError(
        codeFromStatus,
        toMessage(rawError.message, `Venue command "${action}" failed.`),
        toDetails(rawError.details),
      );
    }

    const errorCode = rawError.code;
    if (
      errorCode === "unauthorized" ||
      errorCode === "forbidden" ||
      errorCode === "conflict" ||
      errorCode === "validation_error" ||
      errorCode === "unavailable"
    ) {
      return createVenueCommandError(
        errorCode,
        toMessage(rawError.message, `Venue command "${action}" failed.`),
        toDetails(rawError.details),
      );
    }
  }

  if (rawError instanceof Error) {
    return createVenueCommandError("unavailable", rawError.message);
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return createVenueCommandError("unavailable", rawError.trim());
  }

  return createVenueCommandError(
    "unavailable",
    `Venue command "${action}" failed.`,
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
