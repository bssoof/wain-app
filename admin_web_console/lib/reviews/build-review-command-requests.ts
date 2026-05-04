import type {
  ReviewModerationAction,
  ReviewModerationCommandRequest,
} from "./review-moderation-contracts";
import type {
  ReviewModerationItem,
  ReviewModerationReason,
} from "./review-moderation-models";

export function buildReviewModerationCommandRequest(args: {
  action: ReviewModerationAction;
  item: ReviewModerationItem;
  reason: ReviewModerationReason;
  note?: string;
}): ReviewModerationCommandRequest {
  const { commandId, correlationId } = newIds();
  return {
    action: args.action,
    commandId,
    correlationId,
    reason: args.reason,
    note: args.note,
    submittedAt: new Date().toISOString(),
    target: {
      venueId: args.item.venueId,
      reviewId: args.item.id,
    },
    expectedState: {
      moderation_state: args.item.status,
    },
  };
}

export function commandKey(action: ReviewModerationAction, reviewId: string): string {
  return `${action}:${reviewId}`;
}

function newIds() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return {
      commandId: crypto.randomUUID(),
      correlationId: crypto.randomUUID(),
    };
  }

  const fallback = `review_cmd_${Date.now()}_${Math.random().toString(16).slice(2)}`;
  return {
    commandId: fallback,
    correlationId: `${fallback}_corr`,
  };
}
