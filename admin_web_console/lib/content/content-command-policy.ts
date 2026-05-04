import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";

import {
  createContentModerationError,
  OFFER_MODERATION_COMMAND_METADATA,
  STORY_MODERATION_COMMAND_METADATA,
  type ContentModerationAction,
} from "./content-command-contracts";

export function authorizeOfferModerationCommand(
  session: AdminSession | null,
  action: ContentModerationAction,
) {
  const metadata = OFFER_MODERATION_COMMAND_METADATA[action];
  if (!session) {
    return {
      allowed: false as const,
      error: createContentModerationError(
        "unauthorized",
        "Admin session is required for offer moderation.",
      ),
    };
  }

  if (!canRenderAction(session, metadata.requiredCapability)) {
    return {
      allowed: false as const,
      error: createContentModerationError(
        "forbidden",
        "Offer moderation role is not authorized for this action.",
      ),
    };
  }

  return {
    allowed: true as const,
  };
}

export function authorizeStoryModerationCommand(
  session: AdminSession | null,
  action: ContentModerationAction,
) {
  const metadata = STORY_MODERATION_COMMAND_METADATA[action];
  if (!session) {
    return {
      allowed: false as const,
      error: createContentModerationError(
        "unauthorized",
        "Admin session is required for story moderation.",
      ),
    };
  }

  if (!canRenderAction(session, metadata.requiredCapability)) {
    return {
      allowed: false as const,
      error: createContentModerationError(
        "forbidden",
        "Story moderation role is not authorized for this action.",
      ),
    };
  }

  return {
    allowed: true as const,
  };
}
