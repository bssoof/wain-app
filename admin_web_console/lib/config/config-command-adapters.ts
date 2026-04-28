import {
  mapBackendErrorToTransportError,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";

import type {
  ConfigCommandRequestMap,
  ConfigCommandType,
  ConfigReviewDraftCommandRequest,
  ConfigUpsertDraftCommandRequest,
  PublishConfigCommandRequest,
  RollbackConfigCommandRequest,
} from "./config-command-contracts";
import type {
  ConfigCommandTransport,
  ConfigCommandTransportResult,
} from "./config-command-transport";

export const CONFIG_COMMAND_CALLABLE_SURFACES: Record<
  ConfigCommandType,
  string
> = {
  config_upsert_draft: "configUpsertDraft",
  config_review_draft: "configReviewDraft",
  publish_config: "configPublishDraft",
  rollback_config: "configRollbackVersion",
};

export function createConfigCommandAdaptersTransport(options: {
  invokeCallable: FinanceCallableInvoker;
}): ConfigCommandTransport {
  return {
    async execute<T extends ConfigCommandType>(
      command: T,
      request: ConfigCommandRequestMap[T],
    ): Promise<ConfigCommandTransportResult<T>> {
      switch (command) {
        case "config_upsert_draft":
          return (await executeUpsertDraft(
            options.invokeCallable,
            request as ConfigUpsertDraftCommandRequest,
          )) as ConfigCommandTransportResult<T>;
        case "config_review_draft":
          return (await executeReviewDraft(
            options.invokeCallable,
            request as ConfigReviewDraftCommandRequest,
          )) as ConfigCommandTransportResult<T>;
        case "publish_config":
          return (await executePublishConfig(
            options.invokeCallable,
            request as PublishConfigCommandRequest,
          )) as ConfigCommandTransportResult<T>;
        case "rollback_config":
          return (await executeRollbackConfig(
            options.invokeCallable,
            request as RollbackConfigCommandRequest,
          )) as ConfigCommandTransportResult<T>;
        default:
          return {
            ok: false,
            correlationId: request.correlationId,
            error: {
              status: 503,
              message: `No callable surface found for command ${command}.`,
            },
          } as ConfigCommandTransportResult<T>;
      }
    },
  };
}

async function executeUpsertDraft(
  invokeCallable: FinanceCallableInvoker,
  request: ConfigUpsertDraftCommandRequest,
): Promise<ConfigCommandTransportResult<"config_upsert_draft">> {
  try {
    const response = asRecord(
      await invokeCallable(CONFIG_COMMAND_CALLABLE_SURFACES.config_upsert_draft, {
        commandId: request.commandId,
        correlationId: request.correlationId,
        idempotencyKey: request.commandId,
        reason: request.reason,
        note: request.note,
        submittedAt: request.submittedAt,
        expectedState: request.expectedState,
        pricing: request.pricing,
      }),
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        status: "drafted",
        draftStatus: "drafted",
        draftVersion:
          toNumber(response?.draftVersion ?? response?.draft_version) ?? 0,
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:config_draft`,
        replay: response?.replay === true,
      },
    };
  } catch (error) {
    return {
      ok: false,
      correlationId: request.correlationId,
      error: mapBackendErrorToTransportError(error),
    };
  }
}

async function executeReviewDraft(
  invokeCallable: FinanceCallableInvoker,
  request: ConfigReviewDraftCommandRequest,
): Promise<ConfigCommandTransportResult<"config_review_draft">> {
  try {
    const response = asRecord(
      await invokeCallable(CONFIG_COMMAND_CALLABLE_SURFACES.config_review_draft, {
        commandId: request.commandId,
        correlationId: request.correlationId,
        idempotencyKey: request.commandId,
        reason: request.reason,
        note: request.note,
        submittedAt: request.submittedAt,
        expectedState: request.expectedState,
      }),
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        status: "reviewed",
        draftStatus: "reviewed",
        draftVersion:
          toNumber(response?.draftVersion ?? response?.draft_version) ?? 0,
        reviewedByUid:
          toNonEmptyString(response?.reviewedByUid) ??
          toNonEmptyString(response?.reviewed_by_uid) ??
          "unknown",
        reviewedAt:
          toNumber(response?.reviewedAt ?? response?.reviewed_at) ?? Date.now(),
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:config_review`,
        replay: response?.replay === true,
      },
    };
  } catch (error) {
    return {
      ok: false,
      correlationId: request.correlationId,
      error: mapBackendErrorToTransportError(error),
    };
  }
}

async function executePublishConfig(
  invokeCallable: FinanceCallableInvoker,
  request: PublishConfigCommandRequest,
): Promise<ConfigCommandTransportResult<"publish_config">> {
  try {
    const response = asRecord(
      await invokeCallable(CONFIG_COMMAND_CALLABLE_SURFACES.publish_config, {
        commandId: request.commandId,
        correlationId: request.correlationId,
        idempotencyKey: request.commandId,
        reason: request.reason,
        note: request.note,
        submittedAt: request.submittedAt,
        expectedState: request.expectedState,
      }),
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        status: "published",
        liveVersion: toNumber(response?.liveVersion ?? response?.live_version) ?? 0,
        previousLiveVersion:
          toNumber(
            response?.previousLiveVersion ?? response?.previous_live_version,
          ) ?? 0,
        draftVersion:
          toNumber(response?.draftVersion ?? response?.draft_version) ?? 0,
        historyId:
          toNonEmptyString(response?.historyId) ??
          toNonEmptyString(response?.history_id) ??
          `${request.commandId}:history`,
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:config_publish`,
        replay: response?.replay === true,
      },
    };
  } catch (error) {
    return {
      ok: false,
      correlationId: request.correlationId,
      error: mapBackendErrorToTransportError(error),
    };
  }
}

async function executeRollbackConfig(
  invokeCallable: FinanceCallableInvoker,
  request: RollbackConfigCommandRequest,
): Promise<ConfigCommandTransportResult<"rollback_config">> {
  try {
    const response = asRecord(
      await invokeCallable(CONFIG_COMMAND_CALLABLE_SURFACES.rollback_config, {
        commandId: request.commandId,
        correlationId: request.correlationId,
        idempotencyKey: request.commandId,
        reason: request.reason,
        note: request.note,
        submittedAt: request.submittedAt,
        expectedState: request.expectedState,
        rollbackToVersion: request.rollbackToVersion,
      }),
    );

    return {
      ok: true,
      correlationId: request.correlationId,
      data: {
        status: "rolled_back",
        liveVersion: toNumber(response?.liveVersion ?? response?.live_version) ?? 0,
        previousLiveVersion:
          toNumber(
            response?.previousLiveVersion ?? response?.previous_live_version,
          ) ?? 0,
        rollbackToVersion:
          toNumber(
            response?.rollbackToVersion ?? response?.rollback_to_version,
          ) ?? request.rollbackToVersion,
        historyId:
          toNonEmptyString(response?.historyId) ??
          toNonEmptyString(response?.history_id) ??
          `${request.commandId}:history`,
        auditEventId:
          toNonEmptyString(response?.auditEventId) ??
          toNonEmptyString(response?.audit_event_id) ??
          `${request.commandId}:config_rollback`,
        replay: response?.replay === true,
      },
    };
  } catch (error) {
    return {
      ok: false,
      correlationId: request.correlationId,
      error: mapBackendErrorToTransportError(error),
    };
  }
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
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value.trim());
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return undefined;
}
