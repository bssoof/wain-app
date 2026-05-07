import * as functions from "firebase-functions/v1";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as crypto from "crypto";

import { requireAdminAccessWithDb } from "./shared/admin-auth";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { db } from "./shared/firestore-db";
import { clampFinanceReadLimit } from "./shared/admin-surface-helpers";
import {
  financeTimestampToOptionalIso,
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
  workspaceString,
} from "./shared/finance-media-normalizers";

const walletConfigUtils = require("../src/wallet_config_utils.js") as {
  REQUIRED_PRICING_KEYS: string[];
  validateWalletPricingConfig: (
    pricing: Record<string, unknown>,
    options?: {
      allowNonPositive?: boolean;
      allowZeroOnly?: boolean;
    },
  ) => {
    valid: boolean;
    issues: Array<{
      code: string;
      field: string;
      message: string;
    }>;
    normalizedPricing: Record<string, unknown>;
  };
  formatIssues: (
    issues: Array<{
      code: string;
      field: string;
      message: string;
    }>,
  ) => string;
};

const CONFIG_GOVERNANCE_COMMAND_COLLECTION = "config_governance_commands";
const CONFIG_GOVERNANCE_AUDIT_COLLECTION = "config_audit_events";
const CONFIG_GOVERNANCE_DRAFT_COLLECTION = "config_governance_drafts";
const CONFIG_PUBLISH_HISTORY_COLLECTION = "config_publish_history";
const CONFIG_GOVERNANCE_SCOPE = "wallet_feature_pricing/default";
const CONFIG_GOVERNANCE_DRAFT_DOC_ID = "wallet_feature_pricing_default";

type ConfigGovernanceRole = "super_admin";

type ConfigGovernanceAction =
  | "config_upsert_draft"
  | "config_review_draft"
  | "publish_config"
  | "rollback_config";

type ConfigDraftStatus = "none" | "drafted" | "reviewed" | "published";

async function requireAdminAccess(
  context: functions.https.CallableContext,
): Promise<{ uid: string; source: "claim" | "document" }> {
  return requireAdminAccessWithDb(context, db);
}

type ConfigGovernanceCommandEnvelope = {
  action: ConfigGovernanceAction;
  commandId: string;
  correlationId: string | null;
  idempotencyKey: string;
  reason: string;
  note: string | null;
  submittedAt: string;
  expectedState: Record<string, unknown> | null;
};

function resolveConfigGovernanceRole(
  context: functions.https.CallableContext,
): ConfigGovernanceRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  return null;
}

async function requireConfigGovernanceAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: ConfigGovernanceRole;
}> {
  const role = resolveConfigGovernanceRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "config governance restricted to super_admin",
    );
  }

  const baseAccess = await requireAdminAccess(context);
  return {
    ...baseAccess,
    role,
  };
}

function normalizeConfigDraftStatus(value: unknown): ConfigDraftStatus {
  const normalized = workspaceString(value).toLowerCase();
  if (
    normalized === "drafted" ||
    normalized === "reviewed" ||
    normalized === "published"
  ) {
    return normalized;
  }
  return "none";
}

function normalizeNonNegativeInt(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number.parseInt(value.trim(), 10);
    if (Number.isFinite(parsed) && parsed >= 0) {
      return parsed;
    }
  }

  return null;
}

function normalizePositiveInt(value: unknown): number | null {
  const normalized = normalizeNonNegativeInt(value);
  return normalized !== null && normalized > 0 ? normalized : null;
}

function normalizeConfigVersion(value: unknown): number {
  return normalizeNonNegativeInt(value) ?? 0;
}

function normalizeConfigGovernanceEnvelope(
  action: ConfigGovernanceAction,
  payload: unknown,
  now: Timestamp,
): ConfigGovernanceCommandEnvelope {
  const data = mediaRecordOrNull(payload) ?? {};
  const commandId = workspaceString(data.commandId);
  if (!commandId || commandId.length < 5 || commandId.length > 120) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "config_command_id_invalid",
    );
  }

  const reason = workspaceString(data.reason);
  if (!reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "config_action_reason_required",
    );
  }

  return {
    action,
    commandId,
    correlationId: workspaceString(data.correlationId) || null,
    idempotencyKey: workspaceString(data.idempotencyKey) || commandId,
    reason,
    note: workspaceString(data.note) || null,
    submittedAt: normalizeMediaIsoTimestamp(data.submittedAt, now),
    expectedState: mediaRecordOrNull(data.expectedState),
  };
}

function pickWalletPricingFields(
  source: Record<string, unknown>,
): Record<string, unknown> {
  const pricing: Record<string, unknown> = {};

  for (const key of walletConfigUtils.REQUIRED_PRICING_KEYS) {
    if (Object.prototype.hasOwnProperty.call(source, key)) {
      pricing[key] = source[key];
    }
  }

  if (Object.prototype.hasOwnProperty.call(source, "currency")) {
    pricing.currency = source.currency;
  }

  return pricing;
}

function extractStoredConfigPricing(value: unknown): Record<string, unknown> | null {
  const record = mediaRecordOrNull(value);
  if (!record) {
    return null;
  }

  const nestedPricing = mediaRecordOrNull(record.pricing);
  const pricing = pickWalletPricingFields(nestedPricing ?? record);
  return Object.keys(pricing).length > 0 ? pricing : null;
}

function validateConfigPricingPayload(
  value: unknown,
  failureCode: "invalid-argument" | "failed-precondition" = "invalid-argument",
): Record<string, unknown> {
  const payload = mediaRecordOrNull(value);
  if (!payload) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "config_pricing_payload_required",
    );
  }

  const candidate = pickWalletPricingFields(payload);
  const validation = walletConfigUtils.validateWalletPricingConfig(candidate);
  if (!validation.valid) {
    throw new functions.https.HttpsError(
      failureCode,
      "config_validation_failed",
      {
        issues: validation.issues,
      },
    );
  }

  return validation.normalizedPricing;
}

function sortObjectForConfigHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForConfigHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForConfigHash(record[key]);
    }
    return sorted;
  }

  return value;
}

function hashConfigPayload(payload: Record<string, unknown>): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(sortObjectForConfigHash(payload)))
    .digest("hex");
}

function configGovernanceCommandDocId(
  action: ConfigGovernanceAction,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${action}|${CONFIG_GOVERNANCE_SCOPE}|${commandId}`)
    .digest("hex");
}

function readConfigCommandReplayResult(
  existingCommandDoc: FirebaseFirestore.DocumentSnapshot,
  payloadHash: string,
): Record<string, unknown> | null {
  if (!existingCommandDoc.exists) {
    return null;
  }

  const existing = existingCommandDoc.data() ?? {};
  const existingPayloadHash = workspaceString(existing.payload_hash);
  if (existingPayloadHash && existingPayloadHash !== payloadHash) {
    throw new functions.https.HttpsError(
      "already-exists",
      "config_command_payload_conflict",
    );
  }

  const existingResult = mediaRecordOrNull(existing.result);
  if (!existingResult) {
    return null;
  }

  return {
    ...existingResult,
    replay: true,
  };
}

export const getAdminConfigGovernanceBundle = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    await requireConfigGovernanceAccess(context);

    const historyLimit = clampFinanceReadLimit(data?.historyLimit, 12, 1, 50);
    const now = Timestamp.now();

    const liveRef = db.collection("wallet_feature_pricing").doc("default");
    const draftRef = db
      .collection(CONFIG_GOVERNANCE_DRAFT_COLLECTION)
      .doc(CONFIG_GOVERNANCE_DRAFT_DOC_ID);

    const [liveDoc, draftDoc, historySnap] = await Promise.all([
      liveRef.get(),
      draftRef.get(),
      db
        .collection(CONFIG_PUBLISH_HISTORY_COLLECTION)
        .orderBy("published_at", "desc")
        .limit(historyLimit)
        .get(),
    ]);

    const liveData = liveDoc.data() ?? {};
    const draftData = draftDoc.data() ?? {};

    const livePricing = extractStoredConfigPricing(liveData);
    const draftPricing = extractStoredConfigPricing(draftData.pricing ?? draftData);

    const draftValidation = draftPricing
      ? walletConfigUtils.validateWalletPricingConfig(draftPricing)
      : null;

    const history = historySnap.docs.map((doc) => {
      const row = doc.data() ?? {};
      return {
        id: doc.id,
        eventType: workspaceString(row.event_type) || "config_published",
        liveVersion: normalizeConfigVersion(row.live_version),
        previousLiveVersion: normalizeConfigVersion(row.previous_live_version),
        rollbackToVersion: normalizePositiveInt(row.rollback_to_version),
        sourceHistoryId: workspaceString(row.source_history_id) || null,
        commandId: workspaceString(row.command_id) || null,
        correlationId: workspaceString(row.correlation_id) || null,
        reason: workspaceString(row.reason) || null,
        note: workspaceString(row.note) || null,
        publishedByUid:
          workspaceString(row.actor_uid) ||
          workspaceString(row.published_by_uid) ||
          null,
        publishedByRole:
          workspaceString(row.actor_role) ||
          workspaceString(row.published_by_role) ||
          null,
        reviewedByUid: workspaceString(row.reviewed_by_uid) || null,
        publishedAt:
          financeTimestampToOptionalIso(row.published_at ?? row.created_at) ??
          now.toDate().toISOString(),
      };
    });

    return {
      generatedAt: now.toMillis(),
      source: "callable:getAdminConfigGovernanceBundle",
      scope: CONFIG_GOVERNANCE_SCOPE,
      live: {
        exists: liveDoc.exists,
        version: normalizeConfigVersion(liveData.live_version),
        pricing: livePricing,
        updatedAt: financeTimestampToOptionalIso(liveData.updated_at),
        updatedByUid: workspaceString(liveData.updated_by_uid) || null,
        updatedByRole: workspaceString(liveData.updated_by_role) || null,
      },
      draft: {
        exists: draftDoc.exists,
        status: normalizeConfigDraftStatus(draftData.draft_status),
        draftVersion: normalizeConfigVersion(draftData.draft_version),
        pricing: draftPricing,
        validationIssues:
          draftValidation && !draftValidation.valid ? draftValidation.issues : [],
        reviewedByUid: workspaceString(draftData.reviewed_by_uid) || null,
        reviewedAt: financeTimestampToOptionalIso(draftData.reviewed_at),
        updatedAt: financeTimestampToOptionalIso(draftData.updated_at),
      },
      history,
    };
  },
);

export const configUpsertDraft = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireConfigGovernanceAccess(context);
  const now = Timestamp.now();

  const envelope = normalizeConfigGovernanceEnvelope(
    "config_upsert_draft",
    data,
    now,
  );
  const payload = mediaRecordOrNull(data) ?? {};
  const pricing = validateConfigPricingPayload(payload.pricing, "invalid-argument");

  const commandDocId = configGovernanceCommandDocId(
    envelope.action,
    envelope.commandId,
  );
  const commandRef = db
    .collection(CONFIG_GOVERNANCE_COMMAND_COLLECTION)
    .doc(commandDocId);
  const draftRef = db
    .collection(CONFIG_GOVERNANCE_DRAFT_COLLECTION)
    .doc(CONFIG_GOVERNANCE_DRAFT_DOC_ID);
  const auditEventId = `config_draft_saved_${commandDocId}`;
  const auditRef = db.collection(CONFIG_GOVERNANCE_AUDIT_COLLECTION).doc(auditEventId);

  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    note: envelope.note,
    expectedState: envelope.expectedState,
    scope: CONFIG_GOVERNANCE_SCOPE,
    pricing,
  };
  const payloadHash = hashConfigPayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, draftDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(draftRef),
    ]);

    const replay = readConfigCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    const draftData = draftDoc.data() ?? {};
    const currentDraftStatus = normalizeConfigDraftStatus(draftData.draft_status);
    const currentDraftVersion = normalizeConfigVersion(draftData.draft_version);

    const expectedDraftStatus = workspaceString(
      envelope.expectedState?.draft_status,
    ).toLowerCase();
    if (expectedDraftStatus && expectedDraftStatus !== currentDraftStatus) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_expected_state_conflict",
      );
    }

    const expectedDraftVersion = normalizeNonNegativeInt(
      envelope.expectedState?.draft_version,
    );
    if (
      expectedDraftVersion !== null &&
      expectedDraftVersion !== currentDraftVersion
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_version_conflict",
      );
    }

    const nextDraftVersion = currentDraftVersion + 1;
    const eventType = draftDoc.exists ? "config_draft_updated" : "config_draft_created";
    const resultData = {
      status: "drafted",
      draftStatus: "drafted",
      draftVersion: nextDraftVersion,
      auditEventId,
      replay: false,
    };

    const draftWritePayload: Record<string, unknown> = {
      config_scope: CONFIG_GOVERNANCE_SCOPE,
      draft_status: "drafted",
      draft_version: nextDraftVersion,
      pricing,
      last_reason: envelope.reason,
      last_note: envelope.note,
      updated_at: now,
      updated_by_uid: access.uid,
      updated_by_role: access.role,
      updated_auth_source: access.source,
      reviewed_by_uid: FieldValue.delete(),
      reviewed_by_role: FieldValue.delete(),
      reviewed_at: FieldValue.delete(),
      review_note: FieldValue.delete(),
      published_at: FieldValue.delete(),
      published_by_uid: FieldValue.delete(),
      published_by_role: FieldValue.delete(),
      published_live_version: FieldValue.delete(),
    };
    if (!draftDoc.exists) {
      draftWritePayload.created_at = now;
    }

    transaction.set(draftRef, draftWritePayload, { merge: true });
    transaction.set(
      auditRef,
      {
        category: "config_governance",
        event_type: eventType,
        scope: CONFIG_GOVERNANCE_SCOPE,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        idempotency_key: envelope.idempotencyKey,
        expected_state: envelope.expectedState,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        previous_draft_status: currentDraftStatus,
        draft_status: "drafted",
        draft_version: nextDraftVersion,
        old_pricing: extractStoredConfigPricing(draftData.pricing),
        new_pricing: pricing,
        reason: envelope.reason,
        note: envelope.note,
        submitted_at: envelope.submittedAt,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      commandRef,
      {
        action: envelope.action,
        command_id: envelope.commandId,
        idempotency_key: envelope.idempotencyKey,
        correlation_id: envelope.correlationId,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        scope: CONFIG_GOVERNANCE_SCOPE,
        payload_hash: payloadHash,
        payload_shape: payloadShape,
        expected_state: envelope.expectedState,
        result: resultData,
        executed_at: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );

    return resultData;
  });

  logSecurityAudit("config_draft_upserted", {
    uid: access.uid,
    role: access.role,
    source: access.source,
    commandId: envelope.commandId,
    correlationId: envelope.correlationId,
    draftVersion: result.draftVersion,
    timestamp: now.toMillis(),
  });

  return result;
});

export const configReviewDraft = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireConfigGovernanceAccess(context);
  const now = Timestamp.now();

  const envelope = normalizeConfigGovernanceEnvelope(
    "config_review_draft",
    data,
    now,
  );

  const expectedDraftStatus = workspaceString(
    envelope.expectedState?.draft_status,
  ).toLowerCase();
  if (expectedDraftStatus !== "drafted") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "config_review_expected_state_required",
    );
  }

  const commandDocId = configGovernanceCommandDocId(
    envelope.action,
    envelope.commandId,
  );
  const commandRef = db
    .collection(CONFIG_GOVERNANCE_COMMAND_COLLECTION)
    .doc(commandDocId);
  const draftRef = db
    .collection(CONFIG_GOVERNANCE_DRAFT_COLLECTION)
    .doc(CONFIG_GOVERNANCE_DRAFT_DOC_ID);
  const auditEventId = `config_draft_reviewed_${commandDocId}`;
  const auditRef = db.collection(CONFIG_GOVERNANCE_AUDIT_COLLECTION).doc(auditEventId);

  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    note: envelope.note,
    expectedState: envelope.expectedState,
    scope: CONFIG_GOVERNANCE_SCOPE,
  };
  const payloadHash = hashConfigPayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, draftDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(draftRef),
    ]);

    const replay = readConfigCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    if (!draftDoc.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_not_found",
      );
    }

    const draftData = draftDoc.data() ?? {};
    const currentDraftStatus = normalizeConfigDraftStatus(draftData.draft_status);
    if (currentDraftStatus !== "drafted") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_not_ready_for_review",
      );
    }

    const draftVersion = normalizeConfigVersion(draftData.draft_version);
    if (draftVersion <= 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_version_invalid",
      );
    }

    const expectedDraftVersion = normalizeNonNegativeInt(
      envelope.expectedState?.draft_version,
    );
    if (expectedDraftVersion !== null && expectedDraftVersion !== draftVersion) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_version_conflict",
      );
    }

    const draftPricing = extractStoredConfigPricing(draftData.pricing);
    if (!draftPricing) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_pricing_missing",
      );
    }
    validateConfigPricingPayload(draftPricing, "failed-precondition");

    const resultData = {
      status: "reviewed",
      draftStatus: "reviewed",
      draftVersion,
      reviewedByUid: access.uid,
      reviewedAt: now.toMillis(),
      auditEventId,
      replay: false,
    };

    transaction.set(
      draftRef,
      {
        draft_status: "reviewed",
        review_note: envelope.note,
        reviewed_by_uid: access.uid,
        reviewed_by_role: access.role,
        reviewed_auth_source: access.source,
        reviewed_at: now,
        updated_at: now,
        updated_by_uid: access.uid,
        updated_by_role: access.role,
      },
      { merge: true },
    );
    transaction.set(
      auditRef,
      {
        category: "config_governance",
        event_type: "config_draft_reviewed",
        scope: CONFIG_GOVERNANCE_SCOPE,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        idempotency_key: envelope.idempotencyKey,
        expected_state: envelope.expectedState,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        previous_draft_status: currentDraftStatus,
        draft_status: "reviewed",
        draft_version: draftVersion,
        review_reason: envelope.reason,
        review_note: envelope.note,
        submitted_at: envelope.submittedAt,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      commandRef,
      {
        action: envelope.action,
        command_id: envelope.commandId,
        idempotency_key: envelope.idempotencyKey,
        correlation_id: envelope.correlationId,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        scope: CONFIG_GOVERNANCE_SCOPE,
        payload_hash: payloadHash,
        payload_shape: payloadShape,
        expected_state: envelope.expectedState,
        result: resultData,
        executed_at: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );

    return resultData;
  });

  logSecurityAudit("config_draft_reviewed", {
    uid: access.uid,
    role: access.role,
    source: access.source,
    commandId: envelope.commandId,
    correlationId: envelope.correlationId,
    draftVersion: result.draftVersion,
    timestamp: now.toMillis(),
  });

  return result;
});

export const configPublishDraft = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireConfigGovernanceAccess(context);
  const now = Timestamp.now();

  const envelope = normalizeConfigGovernanceEnvelope("publish_config", data, now);

  const expectedDraftStatus = workspaceString(
    envelope.expectedState?.draft_status,
  ).toLowerCase();
  const targetLiveVersion = normalizeNonNegativeInt(
    envelope.expectedState?.target_live_version,
  );
  if (expectedDraftStatus !== "reviewed" || targetLiveVersion === null) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "publish_config_expected_state_required",
    );
  }

  const commandDocId = configGovernanceCommandDocId(
    envelope.action,
    envelope.commandId,
  );
  const commandRef = db
    .collection(CONFIG_GOVERNANCE_COMMAND_COLLECTION)
    .doc(commandDocId);
  const draftRef = db
    .collection(CONFIG_GOVERNANCE_DRAFT_COLLECTION)
    .doc(CONFIG_GOVERNANCE_DRAFT_DOC_ID);
  const liveRef = db.collection("wallet_feature_pricing").doc("default");
  const auditEventId = `config_published_${commandDocId}`;
  const auditRef = db.collection(CONFIG_GOVERNANCE_AUDIT_COLLECTION).doc(auditEventId);

  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    note: envelope.note,
    expectedState: envelope.expectedState,
    scope: CONFIG_GOVERNANCE_SCOPE,
  };
  const payloadHash = hashConfigPayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, draftDoc, liveDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(draftRef),
      transaction.get(liveRef),
    ]);

    const replay = readConfigCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    if (!draftDoc.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_not_found",
      );
    }

    const draftData = draftDoc.data() ?? {};
    const draftStatus = normalizeConfigDraftStatus(draftData.draft_status);
    if (draftStatus !== "reviewed") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_not_reviewed",
      );
    }

    const reviewedByUid = workspaceString(draftData.reviewed_by_uid);
    if (reviewedByUid && reviewedByUid === access.uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "config_publish_requires_distinct_reviewer_and_publisher",
      );
    }

    const draftVersion = normalizeConfigVersion(draftData.draft_version);
    const expectedDraftVersion = normalizeNonNegativeInt(
      envelope.expectedState?.draft_version,
    );
    if (expectedDraftVersion !== null && expectedDraftVersion !== draftVersion) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_version_conflict",
      );
    }

    const draftPricing = extractStoredConfigPricing(draftData.pricing);
    if (!draftPricing) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_draft_pricing_missing",
      );
    }
    const normalizedDraftPricing = validateConfigPricingPayload(
      draftPricing,
      "failed-precondition",
    );

    const liveData = liveDoc.data() ?? {};
    const currentLiveVersion = normalizeConfigVersion(liveData.live_version);
    if (currentLiveVersion !== targetLiveVersion) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "config_live_version_conflict",
      );
    }

    const nextLiveVersion = currentLiveVersion + 1;
    const historyId = `config_publish_${nextLiveVersion}_${commandDocId.slice(0, 12)}`;
    const historyRef = db.collection(CONFIG_PUBLISH_HISTORY_COLLECTION).doc(historyId);
    const previousLivePricing = extractStoredConfigPricing(liveData);

    const resultData = {
      status: "published",
      liveVersion: nextLiveVersion,
      previousLiveVersion: currentLiveVersion,
      draftVersion,
      historyId,
      auditEventId,
      replay: false,
    };

    const liveWritePayload: Record<string, unknown> = {
      ...normalizedDraftPricing,
      live_version: nextLiveVersion,
      published_from_draft_version: draftVersion,
      published_from_command_id: envelope.commandId,
      updated_at: now,
      updated_by_uid: access.uid,
      updated_by_role: access.role,
      published_at: now,
      published_by_uid: access.uid,
      published_by_role: access.role,
    };
    if (!liveDoc.exists) {
      liveWritePayload.created_at = now;
    }

    transaction.set(liveRef, liveWritePayload, { merge: true });
    transaction.set(
      historyRef,
      {
        config_scope: CONFIG_GOVERNANCE_SCOPE,
        event_type: "config_published",
        live_version: nextLiveVersion,
        previous_live_version: currentLiveVersion,
        draft_version: draftVersion,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        idempotency_key: envelope.idempotencyKey,
        reason: envelope.reason,
        note: envelope.note,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        reviewed_by_uid: reviewedByUid || null,
        reviewed_by_role: workspaceString(draftData.reviewed_by_role) || null,
        old_pricing: previousLivePricing,
        new_pricing: normalizedDraftPricing,
        published_at: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      draftRef,
      {
        draft_status: "published",
        published_at: now,
        published_by_uid: access.uid,
        published_by_role: access.role,
        published_live_version: nextLiveVersion,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      auditRef,
      {
        category: "config_governance",
        event_type: "config_published",
        scope: CONFIG_GOVERNANCE_SCOPE,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        idempotency_key: envelope.idempotencyKey,
        expected_state: envelope.expectedState,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        reviewed_by_uid: reviewedByUid || null,
        previous_live_version: currentLiveVersion,
        live_version: nextLiveVersion,
        draft_version: draftVersion,
        old_pricing: previousLivePricing,
        new_pricing: normalizedDraftPricing,
        reason: envelope.reason,
        note: envelope.note,
        submitted_at: envelope.submittedAt,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      commandRef,
      {
        action: envelope.action,
        command_id: envelope.commandId,
        idempotency_key: envelope.idempotencyKey,
        correlation_id: envelope.correlationId,
        actor_uid: access.uid,
        actor_role: access.role,
        actor_auth_source: access.source,
        scope: CONFIG_GOVERNANCE_SCOPE,
        payload_hash: payloadHash,
        payload_shape: payloadShape,
        expected_state: envelope.expectedState,
        result: resultData,
        executed_at: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );

    return resultData;
  });

  logSecurityAudit("config_published", {
    uid: access.uid,
    role: access.role,
    source: access.source,
    commandId: envelope.commandId,
    correlationId: envelope.correlationId,
    liveVersion: result.liveVersion,
    timestamp: now.toMillis(),
  });

  return result;
});

export const configRollbackVersion = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    const access = await requireConfigGovernanceAccess(context);
    const now = Timestamp.now();

    const envelope = normalizeConfigGovernanceEnvelope(
      "rollback_config",
      data,
      now,
    );

    const rollbackToVersion = normalizePositiveInt(
      data?.rollbackToVersion ?? data?.targetVersion,
    );
    if (rollbackToVersion === null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "config_rollback_target_version_required",
      );
    }

    const expectedCurrentLiveVersion = normalizeNonNegativeInt(
      envelope.expectedState?.current_live_version,
    );
    if (expectedCurrentLiveVersion === null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "rollback_config_expected_state_required",
      );
    }

    const commandDocId = configGovernanceCommandDocId(
      envelope.action,
      envelope.commandId,
    );
    const commandRef = db
      .collection(CONFIG_GOVERNANCE_COMMAND_COLLECTION)
      .doc(commandDocId);
    const liveRef = db.collection("wallet_feature_pricing").doc("default");
    const auditEventId = `config_rollback_${commandDocId}`;
    const auditRef = db.collection(CONFIG_GOVERNANCE_AUDIT_COLLECTION).doc(auditEventId);

    const payloadShape = {
      action: envelope.action,
      commandId: envelope.commandId,
      idempotencyKey: envelope.idempotencyKey,
      correlationId: envelope.correlationId,
      reason: envelope.reason,
      note: envelope.note,
      expectedState: envelope.expectedState,
      rollbackToVersion,
      scope: CONFIG_GOVERNANCE_SCOPE,
    };
    const payloadHash = hashConfigPayload(payloadShape);

    const result = await db.runTransaction(async (transaction) => {
      const historyQuery = db
        .collection(CONFIG_PUBLISH_HISTORY_COLLECTION)
        .where("live_version", "==", rollbackToVersion)
        .limit(1);

      const [commandDoc, liveDoc, historySnap] = await Promise.all([
        transaction.get(commandRef),
        transaction.get(liveRef),
        transaction.get(historyQuery),
      ]);

      const replay = readConfigCommandReplayResult(commandDoc, payloadHash);
      if (replay) {
        return replay;
      }

      if (historySnap.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "config_publish_history_version_not_found",
        );
      }

      const sourceHistoryDoc = historySnap.docs[0];
      const sourceHistoryData = sourceHistoryDoc.data() ?? {};
      const rollbackPricing = extractStoredConfigPricing(sourceHistoryData.new_pricing);
      if (!rollbackPricing) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "config_rollback_pricing_missing",
        );
      }
      const normalizedRollbackPricing = validateConfigPricingPayload(
        rollbackPricing,
        "failed-precondition",
      );

      const liveData = liveDoc.data() ?? {};
      const currentLiveVersion = normalizeConfigVersion(liveData.live_version);
      if (currentLiveVersion !== expectedCurrentLiveVersion) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "config_live_version_conflict",
        );
      }

      if (rollbackToVersion === currentLiveVersion) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "config_already_at_target_live_version",
        );
      }

      const nextLiveVersion = currentLiveVersion + 1;
      const historyId = `config_rollback_${nextLiveVersion}_${commandDocId.slice(0, 12)}`;
      const historyRef = db.collection(CONFIG_PUBLISH_HISTORY_COLLECTION).doc(historyId);
      const previousLivePricing = extractStoredConfigPricing(liveData);

      const resultData = {
        status: "rolled_back",
        liveVersion: nextLiveVersion,
        previousLiveVersion: currentLiveVersion,
        rollbackToVersion,
        sourceHistoryId: sourceHistoryDoc.id,
        historyId,
        auditEventId,
        replay: false,
      };

      transaction.set(
        liveRef,
        {
          ...normalizedRollbackPricing,
          live_version: nextLiveVersion,
          rollback_to_version: rollbackToVersion,
          rollback_from_version: currentLiveVersion,
          rollback_source_history_id: sourceHistoryDoc.id,
          rollback_reason: envelope.reason,
          rollback_note: envelope.note,
          rollback_at: now,
          updated_at: now,
          updated_by_uid: access.uid,
          updated_by_role: access.role,
        },
        { merge: true },
      );
      transaction.set(
        historyRef,
        {
          config_scope: CONFIG_GOVERNANCE_SCOPE,
          event_type: "config_rollback_published",
          live_version: nextLiveVersion,
          previous_live_version: currentLiveVersion,
          rollback_to_version: rollbackToVersion,
          source_history_id: sourceHistoryDoc.id,
          command_id: envelope.commandId,
          correlation_id: envelope.correlationId,
          idempotency_key: envelope.idempotencyKey,
          reason: envelope.reason,
          note: envelope.note,
          actor_uid: access.uid,
          actor_role: access.role,
          actor_auth_source: access.source,
          old_pricing: previousLivePricing,
          new_pricing: normalizedRollbackPricing,
          published_at: now,
          created_at: now,
          updated_at: now,
        },
        { merge: true },
      );
      transaction.set(
        auditRef,
        {
          category: "config_governance",
          event_type: "config_rollback_published",
          scope: CONFIG_GOVERNANCE_SCOPE,
          command_id: envelope.commandId,
          correlation_id: envelope.correlationId,
          idempotency_key: envelope.idempotencyKey,
          expected_state: envelope.expectedState,
          actor_uid: access.uid,
          actor_role: access.role,
          actor_auth_source: access.source,
          previous_live_version: currentLiveVersion,
          live_version: nextLiveVersion,
          rollback_to_version: rollbackToVersion,
          source_history_id: sourceHistoryDoc.id,
          old_pricing: previousLivePricing,
          new_pricing: normalizedRollbackPricing,
          reason: envelope.reason,
          note: envelope.note,
          submitted_at: envelope.submittedAt,
          created_at: now,
          updated_at: now,
        },
        { merge: true },
      );
      transaction.set(
        commandRef,
        {
          action: envelope.action,
          command_id: envelope.commandId,
          idempotency_key: envelope.idempotencyKey,
          correlation_id: envelope.correlationId,
          actor_uid: access.uid,
          actor_role: access.role,
          actor_auth_source: access.source,
          scope: CONFIG_GOVERNANCE_SCOPE,
          payload_hash: payloadHash,
          payload_shape: payloadShape,
          expected_state: envelope.expectedState,
          result: resultData,
          executed_at: now,
          created_at: now,
          updated_at: now,
        },
        { merge: true },
      );

      return resultData;
    });

    logSecurityAudit("config_rollback_published", {
      uid: access.uid,
      role: access.role,
      source: access.source,
      commandId: envelope.commandId,
      correlationId: envelope.correlationId,
      rollbackToVersion,
      liveVersion: result.liveVersion,
      timestamp: now.toMillis(),
    });

    return result;
  },
);
