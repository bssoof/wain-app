import type { AdminCapabilityKey, AdminRole } from "@/lib/navigation/admin-contract";

import type { ConfigDraftStatus, ConfigPricing } from "./config-governance-models";

export const CONFIG_COMMANDS = [
  "config_upsert_draft",
  "config_review_draft",
  "publish_config",
  "rollback_config",
] as const;

export type ConfigCommandType = (typeof CONFIG_COMMANDS)[number];

export type ConfigCommandErrorCode =
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_error"
  | "unavailable";

export type ConfigCommandErrorStatus = 401 | 403 | 409 | 422 | 503;

export type ConfigCommandError = {
  code: ConfigCommandErrorCode;
  status: ConfigCommandErrorStatus;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

const ERROR_STATUS_BY_CODE: Record<ConfigCommandErrorCode, ConfigCommandErrorStatus> = {
  unauthorized: 401,
  forbidden: 403,
  conflict: 409,
  validation_error: 422,
  unavailable: 503,
};

const ERROR_RETRYABLE_BY_CODE: Record<ConfigCommandErrorCode, boolean> = {
  unauthorized: false,
  forbidden: false,
  conflict: true,
  validation_error: false,
  unavailable: true,
};

export function isConfigCommandErrorCode(
  value: unknown,
): value is ConfigCommandErrorCode {
  return (
    value === "unauthorized" ||
    value === "forbidden" ||
    value === "conflict" ||
    value === "validation_error" ||
    value === "unavailable"
  );
}

export function createConfigCommandError(
  code: ConfigCommandErrorCode,
  message: string,
  details?: Record<string, unknown>,
): ConfigCommandError {
  return {
    code,
    status: ERROR_STATUS_BY_CODE[code],
    message,
    retryable: ERROR_RETRYABLE_BY_CODE[code],
    details,
  };
}

export type ConfigCommandRequestBase = {
  commandId: string;
  correlationId: string;
  reason: string;
  submittedAt: string;
  note?: string;
};

export type ConfigDraftExpectedState = {
  draft_status?: ConfigDraftStatus;
  draft_version?: number;
};

export type PublishConfigExpectedState = {
  draft_status: "reviewed";
  target_live_version: number;
  draft_version?: number;
};

export type RollbackConfigExpectedState = {
  current_live_version: number;
};

export type ConfigUpsertDraftCommandRequest = ConfigCommandRequestBase & {
  action: "config_upsert_draft";
  pricing: ConfigPricing;
  expectedState?: ConfigDraftExpectedState;
};

export type ConfigReviewDraftCommandRequest = ConfigCommandRequestBase & {
  action: "config_review_draft";
  expectedState: {
    draft_status: "drafted";
    draft_version?: number;
  };
};

export type PublishConfigCommandRequest = ConfigCommandRequestBase & {
  action: "publish_config";
  expectedState: PublishConfigExpectedState;
};

export type RollbackConfigCommandRequest = ConfigCommandRequestBase & {
  action: "rollback_config";
  rollbackToVersion: number;
  expectedState: RollbackConfigExpectedState;
};

export type ConfigUpsertDraftCommandResponse = {
  status: "drafted";
  draftStatus: "drafted";
  draftVersion: number;
  auditEventId: string;
  replay?: boolean;
};

export type ConfigReviewDraftCommandResponse = {
  status: "reviewed";
  draftStatus: "reviewed";
  draftVersion: number;
  reviewedByUid: string;
  reviewedAt: number;
  auditEventId: string;
  replay?: boolean;
};

export type PublishConfigCommandResponse = {
  status: "published";
  liveVersion: number;
  previousLiveVersion: number;
  draftVersion: number;
  historyId: string;
  auditEventId: string;
  replay?: boolean;
};

export type RollbackConfigCommandResponse = {
  status: "rolled_back";
  liveVersion: number;
  previousLiveVersion: number;
  rollbackToVersion: number;
  historyId: string;
  auditEventId: string;
  replay?: boolean;
};

export type ConfigCommandRequestMap = {
  config_upsert_draft: ConfigUpsertDraftCommandRequest;
  config_review_draft: ConfigReviewDraftCommandRequest;
  publish_config: PublishConfigCommandRequest;
  rollback_config: RollbackConfigCommandRequest;
};

export type ConfigCommandResponseMap = {
  config_upsert_draft: ConfigUpsertDraftCommandResponse;
  config_review_draft: ConfigReviewDraftCommandResponse;
  publish_config: PublishConfigCommandResponse;
  rollback_config: RollbackConfigCommandResponse;
};

export type ConfigCommandMetadata = {
  requiredCapability: AdminCapabilityKey;
  allowedRoles: readonly AdminRole[];
};

const CONFIG_MUTATION_ROLES: readonly AdminRole[] = ["super_admin", "finance_admin"];

export const CONFIG_COMMAND_METADATA: Record<ConfigCommandType, ConfigCommandMetadata> = {
  config_upsert_draft: {
    requiredCapability: "config_draft_write",
    allowedRoles: CONFIG_MUTATION_ROLES,
  },
  config_review_draft: {
    requiredCapability: "config_review",
    allowedRoles: CONFIG_MUTATION_ROLES,
  },
  publish_config: {
    requiredCapability: "publish_config",
    allowedRoles: CONFIG_MUTATION_ROLES,
  },
  rollback_config: {
    requiredCapability: "rollback_config",
    allowedRoles: CONFIG_MUTATION_ROLES,
  },
};
