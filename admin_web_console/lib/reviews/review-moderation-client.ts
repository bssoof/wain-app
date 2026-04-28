import type { AdminSession } from "@/lib/auth/guard-api";

import {
  createReviewModerationError,
  isReviewModerationErrorCode,
  type ReviewModerationAction,
  type ReviewModerationCommandRequest,
  type ReviewModerationCommandResult,
  type ReviewModerationError,
} from "./review-moderation-contracts";
import { authorizeReviewModerationCommand } from "./review-moderation-policy";
import type { ReviewModerationTransport } from "./review-moderation-transport";

const STATUS_TO_ERROR_CODE = {
  401: "unauthorized",
  403: "forbidden",
  409: "conflict",
  422: "validation_error",
  503: "unavailable",
} as const;

export function createReviewModerationClient(
  transport: ReviewModerationTransport,
) {
  return {
    async execute(input: {
      session: AdminSession | null;
      action: ReviewModerationAction;
      request: ReviewModerationCommandRequest;
    }): Promise<ReviewModerationCommandResult> {
      const authResult = authorizeReviewModerationCommand(
        input.session,
        input.action,
      );
      if (!authResult.allowed) {
        return toFailure(input.action, input.request, authResult.error);
      }

      try {
        const transportResult = await transport.execute(
          input.action,
          input.request,
        );
        if (transportResult.ok) {
          return {
            ok: true,
            command: input.action,
            commandId: input.request.commandId,
            correlationId:
              transportResult.correlationId ?? input.request.correlationId,
            data: transportResult.data,
          };
        }

        return toFailure(
          input.action,
          input.request,
          normalizeReviewModerationError(transportResult.error),
          transportResult.correlationId,
        );
      } catch (error) {
        return toFailure(
          input.action,
          input.request,
          normalizeReviewModerationError(error),
        );
      }
    },
  };
}

export function normalizeReviewModerationError(
  rawError: unknown,
): ReviewModerationError {
  if (isRecord(rawError)) {
    const status = typeof rawError.status === "number" ? rawError.status : undefined;
    const codeFromStatus =
      status && status in STATUS_TO_ERROR_CODE
        ? STATUS_TO_ERROR_CODE[status as keyof typeof STATUS_TO_ERROR_CODE]
        : undefined;

    if (codeFromStatus) {
      return createReviewModerationError(
        codeFromStatus,
        toMessage(rawError.message, "Review moderation failed."),
        toDetails(rawError.details),
      );
    }

    if (isReviewModerationErrorCode(rawError.code)) {
      return createReviewModerationError(
        rawError.code,
        toMessage(rawError.message, "Review moderation failed."),
        toDetails(rawError.details),
      );
    }
  }

  if (rawError instanceof Error) {
    return createReviewModerationError("unavailable", rawError.message);
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return createReviewModerationError("unavailable", rawError.trim());
  }

  return createReviewModerationError(
    "unavailable",
    "Review moderation transport is unavailable.",
  );
}

function toFailure(
  action: ReviewModerationAction,
  request: ReviewModerationCommandRequest,
  error: ReviewModerationError,
  correlationId?: string,
): ReviewModerationCommandResult {
  return {
    ok: false,
    command: action,
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
