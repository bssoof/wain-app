import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";

import {
  createReviewModerationError,
  REVIEW_MODERATION_COMMAND_METADATA,
  type ReviewModerationAction,
} from "./review-moderation-contracts";

export function authorizeReviewModerationCommand(
  session: AdminSession | null,
  action: ReviewModerationAction,
) {
  const metadata = REVIEW_MODERATION_COMMAND_METADATA[action];
  if (!session) {
    return {
      allowed: false as const,
      error: createReviewModerationError(
        "unauthorized",
        "Admin session is required for review moderation.",
      ),
    };
  }

  if (!canRenderAction(session, metadata.requiredCapability)) {
    return {
      allowed: false as const,
      error: createReviewModerationError(
        "forbidden",
        "Review moderation role is not authorized for this action.",
      ),
    };
  }

  return {
    allowed: true as const,
  };
}
