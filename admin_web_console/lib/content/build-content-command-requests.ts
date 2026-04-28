import type {
  ContentModerationAction,
  ModerateOfferCommand,
  ModerateStoryCommand,
} from "./content-command-contracts";
import type {
  ContentModerationReason,
  OfferAdminItem,
  StoryAdminItem,
} from "./content-models";

export function buildOfferModerationCommandRequest(args: {
  action: ContentModerationAction;
  item: OfferAdminItem;
  reason: ContentModerationReason;
  note?: string;
}): ModerateOfferCommand {
  const { commandId, correlationId } = newIds();
  return {
    commandId,
    action: args.action,
    offerId: args.item.id,
    venueId: args.item.venueId,
    reason: args.reason,
    note: args.note,
    correlationId,
    submittedAt: new Date().toISOString(),
    expectedState: {
      admin_state: args.item.adminState,
    },
  };
}

export function buildStoryModerationCommandRequest(args: {
  action: ContentModerationAction;
  item: StoryAdminItem;
  reason: ContentModerationReason;
  note?: string;
}): ModerateStoryCommand {
  const { commandId, correlationId } = newIds();
  return {
    commandId,
    action: args.action,
    storyId: args.item.id,
    venueId: args.item.venueId,
    reason: args.reason,
    note: args.note,
    correlationId,
    submittedAt: new Date().toISOString(),
    expectedState: {
      admin_state: args.item.adminState,
    },
  };
}

export function offerCommandKey(action: ContentModerationAction, offerId: string): string {
  return `offer_${action}:${offerId}`;
}

export function storyCommandKey(action: ContentModerationAction, storyId: string): string {
  return `story_${action}:${storyId}`;
}

function newIds() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return {
      commandId: crypto.randomUUID(),
      correlationId: crypto.randomUUID(),
    };
  }

  const fallback = `content_cmd_${Date.now()}_${Math.random().toString(16).slice(2)}`;
  return {
    commandId: fallback,
    correlationId: `${fallback}_corr`,
  };
}
