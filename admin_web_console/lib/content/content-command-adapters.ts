import {
  mapBackendErrorToTransportError,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";

import type {
  ContentModerationAction,
  ModerateOfferCommand,
  ModerateStoryCommand,
  ContentAdminState,
} from "./content-command-contracts";
import type {
  ContentModerationTransport,
  ContentCommandTransportResult,
} from "./content-command-transport";

export const CONTENT_MODERATION_CALLABLE_SURFACES = {
  offer: "contentModerateOffer",
  story: "contentModerateStory",
} as const;

export function createContentModerationAdaptersTransport(options: {
  invokeCallable: FinanceCallableInvoker;
}): ContentModerationTransport {
  return {
    async executeOffer(
      action: ContentModerationAction,
      command: ModerateOfferCommand,
    ): Promise<ContentCommandTransportResult> {
      try {
        const response = asRecord(
          await options.invokeCallable(CONTENT_MODERATION_CALLABLE_SURFACES.offer, {
            action,
            offerId: command.offerId,
            venueId: command.venueId,
            reason: command.reason,
            note: command.note,
            commandId: command.commandId,
            correlationId: command.correlationId,
            idempotencyKey: command.commandId,
            submittedAt: command.submittedAt,
            expectedState: command.expectedState,
          }),
        );

        return {
          ok: true,
          correlationId: command.correlationId,
          data: {
            success: true,
            action,
            commandId: command.commandId,
            newAdminState: normalizeAdminState(response?.newAdminState ?? response?.new_admin_state),
            isActive: Boolean(response?.isActive ?? response?.is_active ?? true),
            auditEventId:
              toNonEmptyString(response?.auditEventId) ??
              toNonEmptyString(response?.audit_event_id) ??
              `${command.commandId}:offer_moderation`,
            replay: response?.replay === true,
          },
        };
      } catch (error) {
        return {
          ok: false,
          correlationId: command.correlationId,
          error: mapBackendErrorToTransportError(error),
        };
      }
    },

    async executeStory(
      action: ContentModerationAction,
      command: ModerateStoryCommand,
    ): Promise<ContentCommandTransportResult> {
      try {
        const response = asRecord(
          await options.invokeCallable(CONTENT_MODERATION_CALLABLE_SURFACES.story, {
            action,
            storyId: command.storyId,
            venueId: command.venueId,
            reason: command.reason,
            note: command.note,
            commandId: command.commandId,
            correlationId: command.correlationId,
            idempotencyKey: command.commandId,
            submittedAt: command.submittedAt,
            expectedState: command.expectedState,
          }),
        );

        return {
          ok: true,
          correlationId: command.correlationId,
          data: {
            success: true,
            action,
            commandId: command.commandId,
            newAdminState: normalizeAdminState(response?.newAdminState ?? response?.new_admin_state),
            isActive: Boolean(response?.isActive ?? response?.is_active ?? true),
            auditEventId:
              toNonEmptyString(response?.auditEventId) ??
              toNonEmptyString(response?.audit_event_id) ??
              `${command.commandId}:story_moderation`,
            replay: response?.replay === true,
          },
        };
      } catch (error) {
        return {
          ok: false,
          correlationId: command.correlationId,
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

function normalizeAdminState(value: unknown): ContentAdminState {
  if (
    value === "approved" ||
    value === "rejected" ||
    value === "flagged" ||
    value === "paused" ||
    value === "pending"
  ) {
    return value;
  }
  return "pending";
}
