import type { AdminSession } from "@/lib/auth/guard-api";

import {
  createContentModerationError,
  isContentModerationErrorCode,
  type ContentModerationAction,
  type ContentModerationError,
  type ContentModerationResult,
  type ModerateOfferCommand,
  type ModerateStoryCommand,
} from "./content-command-contracts";
import {
  authorizeOfferModerationCommand,
  authorizeStoryModerationCommand,
} from "./content-command-policy";
import type { ContentCommandTransport } from "./content-command-transport";

const STATUS_TO_ERROR_CODE = {
  401: "unauthorized",
  403: "forbidden",
  409: "conflict",
  422: "validation_error",
  503: "unavailable",
} as const;

export type ContentModerationCommandResult =
  | {
      ok: true;
      command: ContentModerationAction;
      commandId: string;
      correlationId: string;
      data: ContentModerationResult;
    }
  | {
      ok: false;
      command: ContentModerationAction;
      commandId: string;
      correlationId: string;
      error: ContentModerationError;
    };

export function createContentModerationClient(transport: ContentCommandTransport) {
  return {
    async executeOffer(input: {
      session: AdminSession | null;
      action: ContentModerationAction;
      request: ModerateOfferCommand;
    }): Promise<ContentModerationCommandResult> {
      const authResult = authorizeOfferModerationCommand(
        input.session,
        input.action,
      );
      if (!authResult.allowed) {
        return toFailure(input.action, input.request, authResult.error);
      }

      try {
        const data = await transport.moderateOffer(input.request);
        return {
          ok: true,
          command: input.action,
          commandId: input.request.commandId,
          correlationId: input.request.correlationId,
          data,
        };
      } catch (error) {
        return toFailure(
          input.action,
          input.request,
          normalizeContentModerationError(error),
        );
      }
    },

    async executeStory(input: {
      session: AdminSession | null;
      action: ContentModerationAction;
      request: ModerateStoryCommand;
    }): Promise<ContentModerationCommandResult> {
      const authResult = authorizeStoryModerationCommand(
        input.session,
        input.action,
      );
      if (!authResult.allowed) {
        return toFailure(input.action, input.request, authResult.error);
      }

      try {
        const data = await transport.moderateStory(input.request);
        return {
          ok: true,
          command: input.action,
          commandId: input.request.commandId,
          correlationId: input.request.correlationId,
          data,
        };
      } catch (error) {
        return toFailure(
          input.action,
          input.request,
          normalizeContentModerationError(error),
        );
      }
    },
  };
}

export function normalizeContentModerationError(
  rawError: unknown,
): ContentModerationError {
  if (isRecord(rawError)) {
    const status =
      typeof rawError.status === "number" ? rawError.status : undefined;
    const codeFromStatus =
      status && status in STATUS_TO_ERROR_CODE
        ? STATUS_TO_ERROR_CODE[status as keyof typeof STATUS_TO_ERROR_CODE]
        : undefined;

    if (codeFromStatus) {
      return createContentModerationError(
        codeFromStatus,
        toMessage(rawError.message, "Content moderation failed."),
        toDetails(rawError.details),
      );
    }

    if (isContentModerationErrorCode(rawError.code)) {
      return createContentModerationError(
        rawError.code,
        toMessage(rawError.message, "Content moderation failed."),
        toDetails(rawError.details),
      );
    }
  }

  if (rawError instanceof Error) {
    return createContentModerationError("unavailable", rawError.message);
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return createContentModerationError("unavailable", rawError.trim());
  }

  return createContentModerationError(
    "unavailable",
    "Content moderation transport is unavailable.",
  );
}

function toFailure(
  action: ContentModerationAction,
  request: ModerateOfferCommand | ModerateStoryCommand,
  error: ContentModerationError,
): ContentModerationCommandResult {
  return {
    ok: false,
    command: action,
    commandId: request.commandId,
    correlationId: request.correlationId,
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
