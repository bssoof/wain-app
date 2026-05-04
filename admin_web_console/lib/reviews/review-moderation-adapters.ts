import {
  mapBackendErrorToTransportError,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";

import type {
  ReviewModerationAction,
  ReviewModerationCommandRequest,
} from "./review-moderation-contracts";
import type {
  ReviewModerationTransport,
  ReviewModerationTransportResult,
} from "./review-moderation-transport";

export const REVIEW_MODERATION_CALLABLE_SURFACES: Record<
  ReviewModerationAction,
  string
> = {
  review_publish: "moderateVenueReviewForAdmin",
  review_hide: "moderateVenueReviewForAdmin",
  review_escalate: "moderateVenueReviewForAdmin",
};

export function createReviewModerationAdaptersTransport(options: {
  invokeCallable: FinanceCallableInvoker;
}): ReviewModerationTransport {
  return {
    async execute(
      action: ReviewModerationAction,
      request: ReviewModerationCommandRequest,
    ): Promise<ReviewModerationTransportResult> {
      try {
        const response = asRecord(
          await options.invokeCallable(REVIEW_MODERATION_CALLABLE_SURFACES[action], {
            action,
            venueId: request.target.venueId,
            reviewId: request.target.reviewId,
            reason: request.reason,
            note: request.note,
            commandId: request.commandId,
            correlationId: request.correlationId,
            idempotencyKey: request.commandId,
            submittedAt: request.submittedAt,
            expectedState: request.expectedState,
          }),
        );

        return {
          ok: true,
          correlationId: request.correlationId,
          data: {
            reviewId: toNonEmptyString(response?.reviewId) ?? request.target.reviewId,
            venueId: toNonEmptyString(response?.venueId) ?? request.target.venueId,
            status: normalizeStatus(response?.status),
            moderationState: normalizeStatus(
              response?.moderationState ?? response?.moderation_state,
            ),
            auditEventId:
              toNonEmptyString(response?.auditEventId) ??
              toNonEmptyString(response?.audit_event_id) ??
              `${request.commandId}:review_moderation`,
            moderatedAt:
              toNumber(response?.moderatedAt ?? response?.moderated_at) ?? Date.now(),
          },
        };
      } catch (error) {
        return {
          ok: false,
          correlationId: request.correlationId,
          error: mapBackendErrorToTransportError(error),
        };
      }
    },
  };
}

function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, any>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function toNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function normalizeStatus(value: unknown): "published" | "flagged" | "hidden" {
  return value === "hidden" || value === "flagged" ? value : "published";
}
