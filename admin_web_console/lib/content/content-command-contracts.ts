import type { AdminCapabilityKey, AdminRole } from "@/lib/navigation/admin-contract";
import type { ContentModerationReason, ContentAdminState } from "./content-models";

export type { ContentAdminState, ContentModerationReason };

export type ContentModerationAction = "approve" | "reject" | "flag" | "pause";

export const CONTENT_MODERATION_ACTIONS: ContentModerationAction[] = [
  "approve",
  "reject",
  "flag",
  "pause",
];

// -- Error types --

export type ContentModerationErrorCode =
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_error"
  | "unavailable";

export type ContentModerationErrorStatus = 401 | 403 | 409 | 422 | 503;

export type ContentModerationError = {
  code: ContentModerationErrorCode;
  status: ContentModerationErrorStatus;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

const ERROR_STATUS_BY_CODE: Record<
  ContentModerationErrorCode,
  ContentModerationErrorStatus
> = {
  unauthorized: 401,
  forbidden: 403,
  conflict: 409,
  validation_error: 422,
  unavailable: 503,
};

const ERROR_RETRYABLE_BY_CODE: Record<ContentModerationErrorCode, boolean> = {
  unauthorized: false,
  forbidden: false,
  conflict: true,
  validation_error: false,
  unavailable: true,
};

export function isContentModerationErrorCode(
  value: unknown,
): value is ContentModerationErrorCode {
  return (
    value === "unauthorized" ||
    value === "forbidden" ||
    value === "conflict" ||
    value === "validation_error" ||
    value === "unavailable"
  );
}

export function createContentModerationError(
  code: ContentModerationErrorCode,
  message: string,
  details?: Record<string, unknown>,
): ContentModerationError {
  return {
    code,
    status: ERROR_STATUS_BY_CODE[code],
    message,
    retryable: ERROR_RETRYABLE_BY_CODE[code],
    details,
  };
}

// -- Expected state --

export type ContentModerationExpectedState = {
  admin_state: ContentAdminState;
};

// -- Command requests --

export interface ModerateOfferCommand {
  commandId: string;
  action: ContentModerationAction;
  offerId: string;
  venueId: string;
  reason: ContentModerationReason;
  note?: string;
  correlationId: string;
  submittedAt: string;
  expectedState: ContentModerationExpectedState;
}

export interface ModerateStoryCommand {
  commandId: string;
  action: ContentModerationAction;
  storyId: string;
  venueId: string;
  reason: ContentModerationReason;
  note?: string;
  correlationId: string;
  submittedAt: string;
  expectedState: ContentModerationExpectedState;
}

// -- Command response --

export interface ContentModerationResult {
  success: boolean;
  action: ContentModerationAction;
  commandId: string;
  newAdminState: ContentAdminState;
  isActive: boolean;
  auditEventId: string;
  replay?: boolean;
}

// -- Command metadata for RBAC --

export type ContentModerationCommandMetadata = {
  requiredCapability: AdminCapabilityKey;
  allowedRoles: readonly AdminRole[];
};

export const OFFER_MODERATION_COMMAND_METADATA: Record<
  ContentModerationAction,
  ContentModerationCommandMetadata
> = {
  approve: {
    requiredCapability: "offer_approve",
    allowedRoles: ["super_admin", "content_admin"],
  },
  reject: {
    requiredCapability: "offer_reject",
    allowedRoles: ["super_admin", "content_admin"],
  },
  flag: {
    requiredCapability: "offer_flag",
    allowedRoles: ["super_admin", "content_admin"],
  },
  pause: {
    requiredCapability: "offer_pause",
    allowedRoles: ["super_admin", "content_admin"],
  },
};

export const STORY_MODERATION_COMMAND_METADATA: Record<
  ContentModerationAction,
  ContentModerationCommandMetadata
> = {
  approve: {
    requiredCapability: "story_approve",
    allowedRoles: ["super_admin", "content_admin"],
  },
  reject: {
    requiredCapability: "story_reject",
    allowedRoles: ["super_admin", "content_admin"],
  },
  flag: {
    requiredCapability: "story_flag",
    allowedRoles: ["super_admin", "content_admin"],
  },
  pause: {
    requiredCapability: "story_pause",
    allowedRoles: ["super_admin", "content_admin"],
  },
};

// -- State transition map --

export const CONTENT_MODERATION_ACTION_TO_ADMIN_STATE: Record<
  ContentModerationAction,
  ContentAdminState
> = {
  approve: "approved",
  reject: "rejected",
  flag: "flagged",
  pause: "paused",
};
