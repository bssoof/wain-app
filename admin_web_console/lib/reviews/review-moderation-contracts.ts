import type {
  AdminCapabilityKey,
  AdminRole,
} from "@/lib/navigation/admin-contract";

import type {
  ReviewModerationAction,

  ReviewModerationReason,
  ReviewModerationStatus,
} from "./review-moderation-models";

export type ReviewModerationErrorCode =
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_error"
  | "unavailable";

export type ReviewModerationErrorStatus = 401 | 403 | 409 | 422 | 503;

export type ReviewModerationError = {
  code: ReviewModerationErrorCode;
  status: ReviewModerationErrorStatus;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

const ERROR_STATUS_BY_CODE: Record<
  ReviewModerationErrorCode,
  ReviewModerationErrorStatus
> = {
  unauthorized: 401,
  forbidden: 403,
  conflict: 409,
  validation_error: 422,
  unavailable: 503,
};

const ERROR_RETRYABLE_BY_CODE: Record<ReviewModerationErrorCode, boolean> = {
  unauthorized: false,
  forbidden: false,
  conflict: true,
  validation_error: false,
  unavailable: true,
};

export function isReviewModerationErrorCode(
  value: unknown,
): value is ReviewModerationErrorCode {
  return (
    value === "unauthorized" ||
    value === "forbidden" ||
    value === "conflict" ||
    value === "validation_error" ||
    value === "unavailable"
  );
}

export function createReviewModerationError(
  code: ReviewModerationErrorCode,
  message: string,
  details?: Record<string, unknown>,
): ReviewModerationError {
  return {
    code,
    status: ERROR_STATUS_BY_CODE[code],
    message,
    retryable: ERROR_RETRYABLE_BY_CODE[code],
    details,
  };
}

export type ReviewModerationTarget = {
  venueId: string;
  reviewId: string;
};

export type ReviewModerationExpectedState = {
  moderation_state: ReviewModerationStatus;
};

export type ReviewModerationCommandRequest = {
  action: ReviewModerationAction;
  commandId: string;
  correlationId: string;
  reason: ReviewModerationReason;
  note?: string;
  submittedAt: string;
  target: ReviewModerationTarget;
  expectedState: ReviewModerationExpectedState;
};

export type ReviewModerationCommandResponse = {
  reviewId: string;
  venueId: string;
  status: ReviewModerationStatus;
  moderationState: ReviewModerationStatus;
  auditEventId: string;
  moderatedAt: number;
};

export type ReviewModerationCommandResult =
  | {
      ok: true;
      command: ReviewModerationAction;
      commandId: string;
      correlationId: string;
      data: ReviewModerationCommandResponse;
    }
  | {
      ok: false;
      command: ReviewModerationAction;
      commandId: string;
      correlationId: string;
      error: ReviewModerationError;
    };

export type ReviewModerationCommandMetadata = {
  requiredCapability: AdminCapabilityKey;
  allowedRoles: readonly AdminRole[];
};

export const REVIEW_MODERATION_COMMAND_METADATA: Record<
  ReviewModerationAction,
  ReviewModerationCommandMetadata
> = {
  review_publish: {
    requiredCapability: "review_publish",
    allowedRoles: ["super_admin", "content_admin"],
  },
  review_hide: {
    requiredCapability: "review_hide",
    allowedRoles: ["super_admin", "content_admin"],
  },
  review_escalate: {
    requiredCapability: "review_escalate",
    allowedRoles: ["super_admin", "content_admin"],
  },
};


export type { ReviewModerationAction };
