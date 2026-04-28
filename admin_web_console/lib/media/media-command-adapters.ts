import {
  mapBackendErrorToTransportError,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";

import type {
  MediaCommandRequestMap,
  MediaCommandTarget,
  MediaCommandTargetType,
  MediaCommandType,
  MediaReferenceCheckSummary,
  MediaReferenceIndexStatus,
} from "./media-command-contracts";
import type {
  MediaCommandTransport,
  MediaCommandTransportResult,
} from "./media-command-transport";

type MediaCallableName =
  | "mediaSoftDeleteAsset"
  | "mediaQuarantineAsset"
  | "mediaReferenceCheckAsset"
  | "mediaPurgeAsset";

export const MEDIA_COMMAND_CALLABLE_SURFACES: Record<
  MediaCommandType,
  MediaCallableName | null
> = {
  media_soft_delete: "mediaSoftDeleteAsset",
  media_quarantine: "mediaQuarantineAsset",
  media_reference_check: "mediaReferenceCheckAsset",
  media_purge: "mediaPurgeAsset",
};

export type MediaCommandAdaptersOptions = {
  invokeCallable: FinanceCallableInvoker;
  now?: () => Date;
};

export function createMediaCommandAdaptersTransport(
  options: MediaCommandAdaptersOptions,
): MediaCommandTransport {
  const now = options.now ?? (() => new Date());

  return {
    async execute<T extends MediaCommandType>(
      command: T,
      request: MediaCommandRequestMap[T],
    ): Promise<MediaCommandTransportResult<T>> {
      switch (command) {
        case "media_soft_delete":
          return (await executeMediaSoftDelete(
            options.invokeCallable,
            request as MediaCommandRequestMap["media_soft_delete"],
          )) as
            MediaCommandTransportResult<T>;
        case "media_quarantine":
          return (await executeMediaQuarantine(
            options.invokeCallable,
            request as MediaCommandRequestMap["media_quarantine"],
          )) as
            MediaCommandTransportResult<T>;
        case "media_reference_check":
          return (await executeMediaReferenceCheck(
            options.invokeCallable,
            request as MediaCommandRequestMap["media_reference_check"],
            now,
          )) as MediaCommandTransportResult<T>;
        case "media_purge":
          return (await executeMediaPurge(
            options.invokeCallable,
            request as MediaCommandRequestMap["media_purge"],
          )) as
            MediaCommandTransportResult<T>;
        default:
          return missingSurfaceResult(command, request.correlationId, request);
      }
    },
  };
}

async function executeMediaSoftDelete(
  invokeCallable: FinanceCallableInvoker,
  request: MediaCommandRequestMap["media_soft_delete"],
): Promise<MediaCommandTransportResult<"media_soft_delete">> {
  try {
    const response = asRecord(
      await invokeCallable(
        MEDIA_COMMAND_CALLABLE_SURFACES.media_soft_delete!,
        {
          ...buildTargetPayload(request.target),
          reason: request.reason,
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          submittedAt: request.submittedAt,
        },
      ),
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "media_soft_delete",
        status: "soft_deleted",
        targetType: normalizeTargetType(response?.targetType) ?? request.target.targetType,
        targetId: toNonEmptyString(response?.targetId) ?? request.target.targetId,
        assetState: "soft_deleted",
        referenceCheck: normalizeReferenceCheck(
          response?.referenceCheck ?? response?.reference_check,
          () => new Date(request.submittedAt),
        ),
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:media_soft_delete`,
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeMediaQuarantine(
  invokeCallable: FinanceCallableInvoker,
  request: MediaCommandRequestMap["media_quarantine"],
): Promise<MediaCommandTransportResult<"media_quarantine">> {
  try {
    const response = asRecord(
      await invokeCallable(
        MEDIA_COMMAND_CALLABLE_SURFACES.media_quarantine!,
        {
          ...buildTargetPayload(request.target),
          reason: request.reason,
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          submittedAt: request.submittedAt,
          ...(request.quarantineUntil
            ? {
                quarantineUntil: request.quarantineUntil,
              }
            : {}),
          ...(typeof request.quarantineDays === "number"
            ? {
                quarantineDays: request.quarantineDays,
              }
            : {}),
        },
      ),
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "media_quarantine",
        status: "quarantined",
        targetType: normalizeTargetType(response?.targetType) ?? request.target.targetType,
        targetId: toNonEmptyString(response?.targetId) ?? request.target.targetId,
        assetState: "quarantined",
        quarantineUntil:
          toIsoString(response?.quarantineUntil) ??
          toIsoString(response?.quarantine_until) ??
          request.submittedAt,
        referenceCheck: normalizeReferenceCheck(
          response?.referenceCheck ?? response?.reference_check,
          () => new Date(request.submittedAt),
        ),
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:media_quarantine`,
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeMediaReferenceCheck(
  invokeCallable: FinanceCallableInvoker,
  request: MediaCommandRequestMap["media_reference_check"],
  now: () => Date,
): Promise<MediaCommandTransportResult<"media_reference_check">> {
  try {
    const response = asRecord(
      await invokeCallable(
        MEDIA_COMMAND_CALLABLE_SURFACES.media_reference_check!,
        {
          ...buildTargetPayload(request.target),
          reason: request.reason,
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          submittedAt: request.submittedAt,
        },
      ),
    );

    const referenceCheck = normalizeReferenceCheck(
      response?.referenceCheck ?? response?.reference_check,
      now,
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "media_reference_check",
        status: "checked",
        targetType: normalizeTargetType(response?.targetType) ?? request.target.targetType,
        targetId: toNonEmptyString(response?.targetId) ?? request.target.targetId,
        referenceCheck,
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:media_reference_check`,
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

async function executeMediaPurge(
  invokeCallable: FinanceCallableInvoker,
  request: MediaCommandRequestMap["media_purge"],
): Promise<MediaCommandTransportResult<"media_purge">> {
  try {
    const response = asRecord(
      await invokeCallable(
        MEDIA_COMMAND_CALLABLE_SURFACES.media_purge!,
        {
          ...buildTargetPayload(request.target),
          reason: request.reason,
          commandId: request.commandId,
          correlationId: request.correlationId,
          idempotencyKey: request.commandId,
          expectedState: request.expectedState,
          submittedAt: request.submittedAt,
        },
      ),
    );

    const storageDeleteStatus = normalizeStorageDeleteStatus(
      response?.storageDeleteStatus ?? response?.storage_delete_status,
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        action: "media_purge",
        status: "purged",
        targetType: normalizeTargetType(response?.targetType) ?? request.target.targetType,
        targetId: toNonEmptyString(response?.targetId) ?? request.target.targetId,
        assetState: "purged",
        storageDeleteStatus,
        referenceCheck: normalizeReferenceCheck(
          response?.referenceCheck ?? response?.reference_check,
          () => new Date(request.submittedAt),
        ),
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:media_purge`,
      },
    };
  } catch (error) {
    return toBackendFailureResult(request.correlationId, error);
  }
}

function buildTargetPayload(target: MediaCommandTarget): Record<string, unknown> {
  return {
    targetType: target.targetType,
    targetId: target.targetId,
    ...(target.venueId
      ? {
          venueId: target.venueId,
        }
      : {}),
    ...(target.sourceCollection
      ? {
          sourceCollection: target.sourceCollection,
        }
      : {}),
    ...(target.sourceDocumentId
      ? {
          sourceDocumentId: target.sourceDocumentId,
        }
      : {}),
    ...(target.mediaUrl
      ? {
          mediaUrl: target.mediaUrl,
        }
      : {}),
    ...(target.storagePath
      ? {
          storagePath: target.storagePath,
        }
      : {}),
    ...(target.referenceType
      ? {
          referenceType: target.referenceType,
        }
      : {}),
    ...(target.referenceId
      ? {
          referenceId: target.referenceId,
        }
      : {}),
  };
}

function normalizeReferenceCheck(
  value: unknown,
  now: () => Date,
): MediaReferenceCheckSummary {
  const record = asRecord(value);
  const checkedAt =
    toIsoString(record?.checkedAt) ??
    toIsoString(record?.checked_at) ??
    now().toISOString();
  const indexStatus = normalizeIndexStatus(
    toNonEmptyString(record?.indexStatus) ?? toNonEmptyString(record?.index_status),
  );

  return {
    checkedAt,
    referenceCount: toNumber(record?.referenceCount ?? record?.reference_count) ?? 0,
    indexStatus,
    indexAsOf:
      toIsoString(record?.indexAsOf) ??
      toIsoString(record?.index_as_of) ??
      null,
    indexDetail:
      toNonEmptyString(record?.indexDetail) ??
      toNonEmptyString(record?.index_detail) ??
      `reference_index_status_${indexStatus}`,
    purgeEligible:
      typeof record?.purgeEligible === "boolean"
        ? record.purgeEligible
        : record?.purge_eligible === true,
    blockedReason: normalizeBlockedReason(
      toNonEmptyString(record?.blockedReason) ?? toNonEmptyString(record?.blocked_reason),
    ),
    matchedSourcePaths: toStringArray(
      record?.matchedSourcePaths ?? record?.matched_source_paths,
    ),
  };
}

function normalizeTargetType(value: unknown): MediaCommandTargetType | undefined {
  return value === "media_asset" ||
    value === "topup_proof" ||
    value === "venue_photo" ||
    value === "offer_image" ||
    value === "story_image"
    ? value
    : undefined;
}

function normalizeIndexStatus(value: string | undefined): MediaReferenceIndexStatus {
  if (
    value === "healthy" ||
    value === "stale" ||
    value === "failed" ||
    value === "unavailable"
  ) {
    return value;
  }
  return "unavailable";
}

function normalizeBlockedReason(
  value: string | undefined,
): "reference_index_unhealthy" | "references_present" | null {
  return value === "reference_index_unhealthy" || value === "references_present"
    ? value
    : null;
}

function normalizeStorageDeleteStatus(
  value: unknown,
): "deleted" | "not_requested" | "not_found" {
  return value === "deleted" || value === "not_requested" || value === "not_found"
    ? value
    : "not_requested";
}

function toBackendFailureResult<T extends MediaCommandType>(
  correlationId: string,
  error: unknown,
): MediaCommandTransportResult<T> {
  return {
    ok: false,
    correlationId,
    error: mapBackendErrorToTransportError(error),
  };
}

function missingSurfaceResult<T extends MediaCommandType>(
  command: T,
  correlationId: string,
  request: { commandId: string },
): MediaCommandTransportResult<T> {
  return {
    ok: false,
    correlationId,
    error: {
      status: 503,
      message: `Media command ${command} is not mapped to a callable surface yet.`,
      details: {
        command,
        commandId: request.commandId,
      },
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

function toIsoString(value: unknown): string | undefined {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return new Date(value).toISOString();
  }
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (!trimmed) {
      return undefined;
    }
    const parsed = Date.parse(trimmed);
    if (Number.isFinite(parsed)) {
      return new Date(parsed).toISOString();
    }
  }
  return undefined;
}

function toNumber(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  return undefined;
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((entry): entry is string => typeof entry === "string")
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0);
}
