import type {
  AdminCapabilityKey,
  AdminRole,
} from "@/lib/navigation/admin-contract";

export const MEDIA_COMMANDS = [
  "media_soft_delete",
  "media_quarantine",
  "media_reference_check",
  "media_purge",
] as const;

export type MediaCommandType = (typeof MEDIA_COMMANDS)[number];

export type MediaReferenceIndexStatus =
  | "healthy"
  | "stale"
  | "failed"
  | "unavailable";

export type MediaReferenceCheckBlockedReason =
  | "reference_index_unhealthy"
  | "references_present"
  | null;

export type MediaCommandErrorCode =
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_error"
  | "unavailable";

export type MediaCommandErrorStatus = 401 | 403 | 409 | 422 | 503;

export type MediaCommandError = {
  code: MediaCommandErrorCode;
  status: MediaCommandErrorStatus;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

const ERROR_STATUS_BY_CODE: Record<MediaCommandErrorCode, MediaCommandErrorStatus> =
  {
    unauthorized: 401,
    forbidden: 403,
    conflict: 409,
    validation_error: 422,
    unavailable: 503,
  };

const ERROR_RETRYABLE_BY_CODE: Record<MediaCommandErrorCode, boolean> = {
  unauthorized: false,
  forbidden: false,
  conflict: true,
  validation_error: false,
  unavailable: true,
};

export function isMediaCommandErrorCode(value: unknown): value is MediaCommandErrorCode {
  return (
    value === "unauthorized" ||
    value === "forbidden" ||
    value === "conflict" ||
    value === "validation_error" ||
    value === "unavailable"
  );
}

export function createMediaCommandError(
  code: MediaCommandErrorCode,
  message: string,
  details?: Record<string, unknown>,
): MediaCommandError {
  return {
    code,
    status: ERROR_STATUS_BY_CODE[code],
    message,
    retryable: ERROR_RETRYABLE_BY_CODE[code],
    details,
  };
}

export type MediaCommandTargetType =
  | "media_asset"
  | "topup_proof"
  | "venue_photo"
  | "offer_image"
  | "story_image";

export type MediaCommandTarget = {
  targetType: MediaCommandTargetType;
  targetId: string;
  venueId?: string;
  sourceCollection?: "merchant_topup_requests" | "venues" | "offers" | "stories";
  sourceDocumentId?: string;
  mediaUrl?: string;
  storagePath?: string;
  referenceType?: "topup_request" | "venue" | "offer" | "story";
  referenceId?: string;
};

export type MediaCommandRequestBase = {
  commandId: string;
  correlationId: string;
  reason: string;
  submittedAt: string;
  target: MediaCommandTarget;
};

export type MediaSoftDeleteExpectedState = {
  media_state: "active" | "soft_deleted" | "quarantined";
};

export type MediaQuarantineExpectedState = {
  media_state: "active" | "soft_deleted" | "quarantined";
};

export type MediaReferenceCheckExpectedState = {
  reference_index_health?: MediaReferenceIndexStatus;
};

export type MediaPurgeExpectedState = {
  media_state: "quarantined";
  reference_count: 0;
  reference_index_health: "healthy";
};

export type MediaSoftDeleteCommandRequest = MediaCommandRequestBase & {
  action: "media_soft_delete";
  expectedState: MediaSoftDeleteExpectedState;
};

export type MediaQuarantineCommandRequest = MediaCommandRequestBase & {
  action: "media_quarantine";
  quarantineUntil?: string;
  quarantineDays?: number;
  expectedState: MediaQuarantineExpectedState;
};

export type MediaReferenceCheckCommandRequest = MediaCommandRequestBase & {
  action: "media_reference_check";
  expectedState?: MediaReferenceCheckExpectedState;
};

export type MediaPurgeCommandRequest = MediaCommandRequestBase & {
  action: "media_purge";
  expectedState: MediaPurgeExpectedState;
};

export type MediaReferenceCheckSummary = {
  checkedAt: string;
  referenceCount: number;
  indexStatus: MediaReferenceIndexStatus;
  indexAsOf: string | null;
  indexDetail: string;
  purgeEligible: boolean;
  blockedReason: MediaReferenceCheckBlockedReason;
  matchedSourcePaths: string[];
};

export type MediaSoftDeleteCommandResponse = {
  action: "media_soft_delete";
  status: "soft_deleted";
  targetType: MediaCommandTargetType;
  targetId: string;
  assetState: "soft_deleted";
  referenceCheck: MediaReferenceCheckSummary;
  auditEventId: string;
};

export type MediaQuarantineCommandResponse = {
  action: "media_quarantine";
  status: "quarantined";
  targetType: MediaCommandTargetType;
  targetId: string;
  assetState: "quarantined";
  quarantineUntil: string;
  referenceCheck: MediaReferenceCheckSummary;
  auditEventId: string;
};

export type MediaReferenceCheckCommandResponse = {
  action: "media_reference_check";
  status: "checked";
  targetType: MediaCommandTargetType;
  targetId: string;
  referenceCheck: MediaReferenceCheckSummary;
  auditEventId: string;
};

export type MediaPurgeCommandResponse = {
  action: "media_purge";
  status: "purged";
  targetType: MediaCommandTargetType;
  targetId: string;
  assetState: "purged";
  storageDeleteStatus: "deleted" | "not_requested" | "not_found";
  referenceCheck: MediaReferenceCheckSummary;
  auditEventId: string;
};

export type MediaCommandRequest = MediaCommandRequestMap[MediaCommandType];
export type MediaCommandResponse = MediaCommandResponseMap[MediaCommandType];

export type MediaCommandRequestMap = {
  media_soft_delete: MediaSoftDeleteCommandRequest;
  media_quarantine: MediaQuarantineCommandRequest;
  media_reference_check: MediaReferenceCheckCommandRequest;
  media_purge: MediaPurgeCommandRequest;
};

export type MediaCommandResponseMap = {
  media_soft_delete: MediaSoftDeleteCommandResponse;
  media_quarantine: MediaQuarantineCommandResponse;
  media_reference_check: MediaReferenceCheckCommandResponse;
  media_purge: MediaPurgeCommandResponse;
};

export type MediaCommandSuccess<T extends MediaCommandType> = {
  ok: true;
  command: T;
  commandId: string;
  correlationId: string;
  data: MediaCommandResponseMap[T];
};

export type MediaCommandFailure<T extends MediaCommandType> = {
  ok: false;
  command: T;
  commandId: string;
  correlationId: string;
  error: MediaCommandError;
};

export type MediaCommandResult<T extends MediaCommandType> =
  | MediaCommandSuccess<T>
  | MediaCommandFailure<T>;

export type CommandIdempotencyExpectation = {
  required: true;
  keyField: "commandId";
  replayRule:
    | "same_command_same_payload_returns_original"
    | "same_command_different_payload_rejected";
};

export type CommandExpectedStateExpectation = {
  required: boolean;
  requiredFields: readonly string[];
};

export type MediaCommandMetadata = {
  requiredCapability: AdminCapabilityKey;
  allowedRoles: readonly AdminRole[];
  idempotency: CommandIdempotencyExpectation;
  expectedState: CommandExpectedStateExpectation;
  destructive: boolean;
};

const MEDIA_ACTION_ROLES: readonly AdminRole[] = ["super_admin", "content_admin"];

const SHARED_IDEMPOTENCY: CommandIdempotencyExpectation = {
  required: true,
  keyField: "commandId",
  replayRule: "same_command_same_payload_returns_original",
};

export const MEDIA_COMMAND_METADATA: Record<MediaCommandType, MediaCommandMetadata> = {
  media_soft_delete: {
    requiredCapability: "media_soft_delete",
    allowedRoles: MEDIA_ACTION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["media_state"],
    },
    destructive: true,
  },
  media_quarantine: {
    requiredCapability: "media_quarantine",
    allowedRoles: MEDIA_ACTION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["media_state"],
    },
    destructive: true,
  },
  media_reference_check: {
    requiredCapability: "media_reference_check",
    allowedRoles: MEDIA_ACTION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: false,
      requiredFields: [],
    },
    destructive: false,
  },
  media_purge: {
    requiredCapability: "media_purge",
    allowedRoles: MEDIA_ACTION_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: [
        "media_state",
        "reference_count",
        "reference_index_health",
      ],
    },
    destructive: true,
  },
};
