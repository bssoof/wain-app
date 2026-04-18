import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import * as crypto from "crypto";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import {
  requireAdminAccessWithDb,
} from "./shared/admin-auth";
import {
  financeTimestampToIso,
  financeTimestampToIsoWithFallback,
  financeTimestampToMillis,
  financeTimestampToOptionalIso,
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
  workspaceString,
} from "./shared/finance-media-normalizers";
import {
  normalizeNumber,
  resolveWalletLedgerUiType,
} from "./shared/admin-surface-helpers";

import {
  getDefaultStorageBucket,
} from "./shared/storage";
export {
  createMenuImportJob,
  processMenuImport,
  enqueueMenuImport,
  runMenuOcr,
  extractMenuCandidates,
  mapExtractedMenu,
  onMenuImportTaskCreate,
} from "./menu_import";
export { aggregateVenueBusyTimes, backfillVenueBusyTimes } from "./busy_times/job";
export { createTransportHandoff, getTransportQuotes } from "./transport";
export {
  trackVenueEvent,
  searchVenuesInBounds,
  createClaimToken,
  validateToken,
  redeemToken,
  onReviewWrite,
  redeemInviteCode,
} from "./public_engagement";
export {
  aggregateVenueAnalytics,
  backfillMerchantAnalytics,
} from "./analytics_runtime";
export {
  updateVenueHasOffers,
  checkExpiringOffers,
} from "./analytics_offer_health";
export {
  isCurrentUserAdmin,
  verifyWalletOperationalReadiness,
} from "./wallet_runtime_readiness";
export {
  listMerchantTopUpRequestsForAdmin,
  listMerchantWalletLedgerEntriesForAdmin,
} from "./wallet_admin_reads";
export {
  createMerchantTopUpRequest,
  reviewMerchantTopUpRequest,
  reverseWalletEntry,
  approveWalletReversalRequest,
  rebuildWalletReportForVenue,
  promoteStory,
  pinOffer,
} from "./wallet_runtime_mutations";
export {
  runWalletLifecycleMaintenance,
  runWalletExpiryReminderMaintenance,
  walletLifecycleMaintenance,
  walletExpiryReminderMaintenance,
  rebuildWalletReportsDaily,
} from "./wallet_runtime_maintenance";
export { onWalletEntryWrite } from "./wallet_runtime_audit";
export { requireAppCheck, logSecurityAudit };
export {
  workspaceString,
  financeTimestampToIsoWithFallback,
  financeTimestampToOptionalIso,
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
};

if (admin.apps.length === 0) {
  admin.initializeApp();
}
export const db = admin.firestore();
const MEDIA_COMMAND_COLLECTION = "media_governance_commands";
const MEDIA_AUDIT_COLLECTION = "media_audit_events";
const MEDIA_ASSET_COLLECTION = "media_governance_assets";
const REVIEW_MODERATION_COMMAND_COLLECTION = "review_moderation_commands";
const REVIEW_MODERATION_AUDIT_COLLECTION = "review_moderation_events";
const DEFAULT_MEDIA_QUARANTINE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
const MEDIA_ACTION_ALLOWED_SOURCE_COLLECTIONS = new Set<string>([
  "merchant_topup_requests",
  "venues",
  "offers",
  "stories",
]);
const MEDIA_ACTION_ALLOWED_TARGET_TYPES = new Set<string>([
  "media_asset",
  "topup_proof",
  "venue_photo",
  "offer_image",
  "story_image",
]);
const REVIEW_MODERATION_ALLOWED_REASONS = new Set<string>([
  "spam",
  "abusive_language",
  "off_topic",
  "privacy_request",
  "legal_request",
  "duplicate",
  "manual_review",
  "appeal_approved",
  "other",
]);

export async function requireAdminAccess(
  context: functions.https.CallableContext,
): Promise<{ uid: string; source: "claim" | "document" }> {
  return requireAdminAccessWithDb(context, db);
}




export function clampFinanceReadLimit(
  value: unknown,
  fallback: number,
  min: number,
  max: number,
): number {
  const n =
    typeof value === "number" && Number.isFinite(value)
      ? Math.floor(value)
      : fallback;
  return Math.min(max, Math.max(min, n));
}

export async function loadVenueDisplayLabels(
  venueIds: string[],
): Promise<Map<string, string>> {
  const unique = [...new Set(venueIds.filter((id) => id.trim().length > 0))].slice(
    0,
    200,
  );
  const map = new Map<string, string>();
  await Promise.all(
    unique.map(async (id) => {
      const snap = await db.collection("venues").doc(id).get();
      if (!snap.exists) {
        map.set(id, id);
        return;
      }
      const d = snap.data() ?? {};
      const ar = typeof d.name_ar === "string" ? d.name_ar.trim() : "";
      const en = typeof d.name === "string" ? d.name.trim() : "";
      map.set(id, ar || en || id);
    }),
  );
  return map;
}

function workspaceStoryStatus(
  data: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "published" | "expired" | "draft" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "published" || explicit === "expired" || explicit === "draft") {
    return explicit;
  }

  const expiresAt = financeTimestampToMillis(data.expires_at ?? data.expiresAt);
  if (expiresAt > 0 && expiresAt <= now.toMillis()) {
    return "expired";
  }

  if (data.is_active === false || data.is_published === false) {
    return "draft";
  }

  return "published";
}

function workspaceOfferStatus(
  data: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "active" | "paused" | "expired" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "active" || explicit === "paused" || explicit === "expired") {
    return explicit;
  }

  const endAt = financeTimestampToMillis(data.end_at ?? data.ends_at ?? data.endAt);
  if (endAt > 0 && endAt <= now.toMillis()) {
    return "expired";
  }

  if (data.is_active === false || data.is_featured === false) {
    return "paused";
  }

  return "active";
}

function workspaceReviewStatus(
  data: FirebaseFirestore.DocumentData,
): "published" | "flagged" | "hidden" {
  const explicit = workspaceString(data.status).toLowerCase();
  if (explicit === "published" || explicit === "flagged" || explicit === "hidden") {
    return explicit;
  }

  if (data.hidden === true || data.is_hidden === true) {
    return "hidden";
  }

  if (data.flagged === true || data.is_flagged === true) {
    return "flagged";
  }

  return "published";
}

type ReviewModerationAction =
  | "review_publish"
  | "review_hide"
  | "review_escalate";

type ReviewModerationRole = "content_admin" | "super_admin";

type ReviewModerationStatus = "published" | "flagged" | "hidden";

type ReviewModerationTarget = {
  venueId: string;
  reviewId: string;
  sourcePath: string;
};

type ReviewModerationCommandEnvelope = {
  action: ReviewModerationAction;
  commandId: string;
  correlationId: string | null;
  idempotencyKey: string;
  reason: string;
  note: string | null;
  submittedAt: string;
  expectedState: Record<string, unknown> | null;
};

function resolveReviewModerationRole(
  context: functions.https.CallableContext,
): ReviewModerationRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  if (token.content_admin === true || token.role === "content_admin") {
    return "content_admin";
  }
  return null;
}

async function requireReviewModerationAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: ReviewModerationRole;
}> {
  const baseAccess = await requireAdminAccess(context);
  const role = resolveReviewModerationRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "review_moderation_role_not_authorized",
    );
  }

  return {
    ...baseAccess,
    role,
  };
}

function normalizeReviewModerationAction(value: unknown): ReviewModerationAction {
  const normalized = workspaceString(value).toLowerCase();
  if (
    normalized === "review_publish" ||
    normalized === "review_hide" ||
    normalized === "review_escalate"
  ) {
    return normalized;
  }

  throw new functions.https.HttpsError(
    "invalid-argument",
    "unsupported_review_moderation_action",
  );
}

function normalizeReviewModerationTarget(data: unknown): ReviewModerationTarget {
  const payload = mediaRecordOrNull(data) ?? {};
  const venueId = workspaceString(payload.venueId);
  const reviewId = workspaceString(payload.reviewId);

  if (!venueId || !reviewId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "review_target_requires_venue_and_review_id",
    );
  }

  return {
    venueId,
    reviewId,
    sourcePath: `venues/${venueId}/reviews/${reviewId}`,
  };
}

function normalizeReviewModerationReason(value: unknown): string {
  const normalized = workspaceString(value).toLowerCase();
  if (!normalized || !REVIEW_MODERATION_ALLOWED_REASONS.has(normalized)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "review_moderation_reason_invalid",
    );
  }
  return normalized;
}

function normalizeReviewModerationEnvelope(
  action: ReviewModerationAction,
  payload: unknown,
  target: ReviewModerationTarget,
  now: Timestamp,
): ReviewModerationCommandEnvelope {
  const data = mediaRecordOrNull(payload) ?? {};
  const commandId =
    workspaceString(data.commandId) || `${action}_${target.reviewId}`;
  const correlationId = workspaceString(data.correlationId) || null;
  const idempotencyKey = workspaceString(data.idempotencyKey) || commandId;
  const submittedAt = normalizeMediaIsoTimestamp(data.submittedAt, now);
  const expectedState = mediaRecordOrNull(data.expectedState);
  const reason = normalizeReviewModerationReason(data.reason);
  const note = workspaceString(data.note) || null;

  return {
    action,
    commandId,
    correlationId,
    idempotencyKey,
    reason,
    note,
    submittedAt,
    expectedState,
  };
}

function targetStatusForReviewAction(
  action: ReviewModerationAction,
): ReviewModerationStatus {
  switch (action) {
    case "review_publish":
      return "published";
    case "review_hide":
      return "hidden";
    case "review_escalate":
      return "flagged";
  }
}

function reviewModerationCommandDocId(
  action: ReviewModerationAction,
  target: ReviewModerationTarget,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${action}|${target.sourcePath}|${commandId}`)
    .digest("hex");
}

function sortObjectForReviewHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForReviewHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForReviewHash(record[key]);
    }
    return sorted;
  }

  return value;
}

function hashReviewModerationPayload(payload: Record<string, unknown>): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(sortObjectForReviewHash(payload)))
    .digest("hex");
}

function buildReviewModerationPayloadShape(
  target: ReviewModerationTarget,
  envelope: ReviewModerationCommandEnvelope,
): Record<string, unknown> {
  return {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    note: envelope.note,
    expectedState: envelope.expectedState,
    target,
  };
}

export {
  REVIEW_MODERATION_AUDIT_COLLECTION,
  REVIEW_MODERATION_COMMAND_COLLECTION,
  buildReviewModerationPayloadShape,
  financeTimestampToIso,
  hashReviewModerationPayload,
  normalizeNumber,
  normalizeReviewModerationAction,
  normalizeReviewModerationEnvelope,
  normalizeReviewModerationTarget,
  requireReviewModerationAccess,
  reviewModerationCommandDocId,
  targetStatusForReviewAction,
  workspaceReviewStatus,
};

type MediaReferenceIndexHealthStatus =
  | "healthy"
  | "stale"
  | "failed"
  | "unavailable";

function normalizeMediaReferenceIndexHealth(
  value: unknown,
): MediaReferenceIndexHealthStatus {
  const normalized = workspaceString(value).toLowerCase();
  if (normalized === "healthy" || normalized === "stale" || normalized === "failed") {
    return normalized;
  }
  return "unavailable";
}

function workspaceStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => workspaceString(entry))
    .filter((entry) => entry.length > 0);
}

function workspaceMediaUrl(
  data: FirebaseFirestore.DocumentData,
  candidates: string[],
): string {
  for (const candidate of candidates) {
    const value = workspaceString(data[candidate]);
    if (value.length > 0) {
      return value;
    }
  }
  return "";
}

function mediaStoragePathFromUrl(value: string): string | null {
  if (!value || /^https?:\/\//i.test(value) || value.startsWith("gs://")) {
    return null;
  }
  return value;
}

async function loadMediaReferenceIndexHealth(now: Timestamp): Promise<{
  status: MediaReferenceIndexHealthStatus;
  asOf: string | null;
  detail: string;
}> {
  const healthDocId = "health";
  const healthDocPath = `media_reference_index/${healthDocId}`;

  try {
    const healthDoc = await db.collection("media_reference_index").doc(healthDocId).get();
    if (!healthDoc.exists) {
      return {
        status: "unavailable",
        asOf: null,
        detail: `${healthDocPath} missing`,
      };
    }

    const row = healthDoc.data() ?? {};
    const status = normalizeMediaReferenceIndexHealth(
      row.current_health_status ?? row.health_status ?? row.status,
    );
    const asOfMs = financeTimestampToMillis(
      row.last_successful_build_at ?? row.as_of ?? row.updated_at,
    );

    return {
      status,
      asOf: asOfMs > 0 ? new Date(asOfMs).toISOString() : null,
      detail:
        status === "unavailable"
          ? `${healthDocPath} status invalid`
          : "ok",
    };
  } catch (error) {
    return {
      status: "unavailable",
      asOf: null,
      detail: `${healthDocPath} read error: ${
        error instanceof Error ? error.message : String(error)
      }`,
    };
  }
}

function buildMediaSafetyMetadata(args: {
  referenceType: "topup_request" | "venue" | "offer" | "story";
  referenceId: string;
  sourceCollection: string;
  sourceDocumentId: string;
  indexHealth: {
    status: MediaReferenceIndexHealthStatus;
    asOf: string | null;
  };
}): Record<string, unknown> {
  const blockedByIndex = args.indexHealth.status !== "healthy";
  return {
    referenceType: args.referenceType,
    referenceId: args.referenceId,
    sourceCollection: args.sourceCollection,
    sourceDocumentId: args.sourceDocumentId,
    sourcePath: `${args.sourceCollection}/${args.sourceDocumentId}`,
    referenceCount: 1,
    referenceIndexStatus: args.indexHealth.status,
    referenceIndexAsOf: args.indexHealth.asOf,
    purgeBlocked: true,
    purgeBlockReason: blockedByIndex
      ? "reference_index_unavailable_or_unhealthy"
      : "reference_count_unverified_read_only_baseline",
  };
}

type MediaGovernanceAction =
  | "media_soft_delete"
  | "media_quarantine"
  | "media_reference_check"
  | "media_purge";

type MediaGovernanceRole = "content_admin" | "super_admin";

type MediaGovernanceTarget = {
  targetType: string;
  targetId: string;
  assetKey: string;
  venueId: string | null;
  sourceCollection: string | null;
  sourceDocumentId: string | null;
  sourcePath: string | null;
  mediaUrl: string | null;
  storagePath: string | null;
  referenceType: string | null;
  referenceId: string | null;
};

type MediaGovernanceCommandEnvelope = {
  action: MediaGovernanceAction;
  commandId: string;
  correlationId: string | null;
  idempotencyKey: string;
  reason: string;
  submittedAt: string;
  expectedState: Record<string, unknown> | null;
};

type MediaReferenceCheckSummary = {
  checkedAt: string;
  referenceCount: number;
  indexStatus: MediaReferenceIndexHealthStatus;
  indexAsOf: string | null;
  indexDetail: string;
  purgeEligible: boolean;
  blockedReason: "reference_index_unhealthy" | "references_present" | null;
  matchedSourcePaths: string[];
};

function resolveMediaGovernanceRole(
  context: functions.https.CallableContext,
): MediaGovernanceRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  if (token.content_admin === true || token.role === "content_admin") {
    return "content_admin";
  }
  return null;
}

async function requireMediaGovernanceAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: MediaGovernanceRole;
}> {
  const baseAccess = await requireAdminAccess(context);
  const role = resolveMediaGovernanceRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "media_role_not_authorized",
    );
  }

  return {
    ...baseAccess,
    role,
  };
}

function normalizeMediaGovernanceTarget(data: unknown): MediaGovernanceTarget {
  const payload = mediaRecordOrNull(data) ?? {};

  const targetType = workspaceString(payload.targetType) || "media_asset";
  if (!MEDIA_ACTION_ALLOWED_TARGET_TYPES.has(targetType)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "unsupported_media_target_type",
    );
  }

  const targetId = workspaceString(payload.targetId) || workspaceString(payload.assetId);
  if (!targetId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "media_target_id_required",
    );
  }

  const mediaUrlRaw = workspaceString(payload.mediaUrl);
  const storagePathRaw = workspaceString(payload.storagePath);
  const derivedStoragePath = mediaStoragePathFromUrl(mediaUrlRaw);
  const storagePath = storagePathRaw || derivedStoragePath || null;
  const mediaUrl = mediaUrlRaw || (storagePath ? storagePath : null);

  const sourceCollectionRaw = workspaceString(payload.sourceCollection);
  const sourceCollection = sourceCollectionRaw || null;
  const sourceDocumentId = workspaceString(payload.sourceDocumentId) || null;
  if (sourceCollection && !MEDIA_ACTION_ALLOWED_SOURCE_COLLECTIONS.has(sourceCollection)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "unsupported_media_source_collection",
    );
  }
  if (Boolean(sourceCollection) !== Boolean(sourceDocumentId)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "media_source_collection_and_document_id_must_pair",
    );
  }

  const sourcePath =
    sourceCollection && sourceDocumentId
      ? `${sourceCollection}/${sourceDocumentId}`
      : null;
  const assetKey =
    storagePath ||
    mediaUrl ||
    sourcePath ||
    targetId;

  return {
    targetType,
    targetId,
    assetKey,
    venueId: workspaceString(payload.venueId) || null,
    sourceCollection,
    sourceDocumentId,
    sourcePath,
    mediaUrl,
    storagePath,
    referenceType: workspaceString(payload.referenceType) || null,
    referenceId: workspaceString(payload.referenceId) || null,
  };
}

function normalizeMediaExpectedState(value: unknown): Record<string, unknown> | null {
  const state = mediaRecordOrNull(value);
  return state ?? null;
}

function normalizeMediaCommandEnvelope(
  action: MediaGovernanceAction,
  payload: unknown,
  target: MediaGovernanceTarget,
  now: Timestamp,
): MediaGovernanceCommandEnvelope {
  const data = mediaRecordOrNull(payload) ?? {};
  const commandId =
    workspaceString(data.commandId) ||
    `${action}_${target.targetId}`;
  const correlationId = workspaceString(data.correlationId) || null;
  const idempotencyKey = workspaceString(data.idempotencyKey) || commandId;
  const submittedAt = normalizeMediaIsoTimestamp(data.submittedAt, now);
  const expectedState = normalizeMediaExpectedState(data.expectedState);
  const reasonRaw = workspaceString(data.reason);
  const reason =
    reasonRaw ||
    (action === "media_reference_check" ? "media_reference_check" : "");

  if (!reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "media_action_reason_required",
    );
  }

  return {
    action,
    commandId,
    correlationId,
    idempotencyKey,
    reason,
    submittedAt,
    expectedState,
  };
}

function normalizeMediaQuarantineUntil(payload: unknown, now: Timestamp): Timestamp {
  const data = mediaRecordOrNull(payload) ?? {};

  const explicitIso = workspaceString(data.quarantineUntil);
  if (explicitIso) {
    const parsed = Date.parse(explicitIso);
    if (Number.isFinite(parsed) && parsed > now.toMillis()) {
      return Timestamp.fromMillis(parsed);
    }
  }

  const quarantineDays =
    typeof data.quarantineDays === "number" && Number.isFinite(data.quarantineDays)
      ? Math.max(1, Math.min(90, Math.trunc(data.quarantineDays)))
      : null;
  if (quarantineDays !== null) {
    return Timestamp.fromMillis(
      now.toMillis() + quarantineDays * 24 * 60 * 60 * 1000,
    );
  }

  return Timestamp.fromMillis(now.toMillis() + DEFAULT_MEDIA_QUARANTINE_WINDOW_MS);
}

function mediaAssetDocIdFromKey(assetKey: string): string {
  return crypto.createHash("sha1").update(assetKey).digest("hex");
}

function mediaCommandDocId(
  action: MediaGovernanceAction,
  target: MediaGovernanceTarget,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${action}|${target.assetKey}|${commandId}`)
    .digest("hex");
}

function sortObjectForMediaHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForMediaHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForMediaHash(record[key]);
    }
    return sorted;
  }

  return value;
}

function hashMediaPayload(payload: Record<string, unknown>): string {
  const normalized = sortObjectForMediaHash(payload);
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(normalized))
    .digest("hex");
}

function buildMediaPayloadShape(
  target: MediaGovernanceTarget,
  envelope: MediaGovernanceCommandEnvelope,
): Record<string, unknown> {
  return {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    submittedAt: envelope.submittedAt,
    expectedState: envelope.expectedState,
    target: {
      targetType: target.targetType,
      targetId: target.targetId,
      assetKey: target.assetKey,
      venueId: target.venueId,
      sourceCollection: target.sourceCollection,
      sourceDocumentId: target.sourceDocumentId,
      mediaUrl: target.mediaUrl,
      storagePath: target.storagePath,
      referenceType: target.referenceType,
      referenceId: target.referenceId,
    },
  };
}

function buildMediaTargetCandidates(target: MediaGovernanceTarget): Set<string> {
  const candidates = new Set<string>();
  if (target.mediaUrl) {
    candidates.add(target.mediaUrl);
    const derivedPath = mediaStoragePathFromUrl(target.mediaUrl);
    if (derivedPath) {
      candidates.add(derivedPath);
    }
  }
  if (target.storagePath) {
    candidates.add(target.storagePath);
  }
  return candidates;
}

function mediaCandidateMatchesTarget(
  candidateRaw: unknown,
  targetCandidates: Set<string>,
): boolean {
  const candidate = workspaceString(candidateRaw);
  if (!candidate) {
    return false;
  }

  if (targetCandidates.has(candidate)) {
    return true;
  }

  const candidatePath = mediaStoragePathFromUrl(candidate);
  return candidatePath ? targetCandidates.has(candidatePath) : false;
}

async function loadMediaReferenceMatchCount(target: MediaGovernanceTarget): Promise<{
  referenceCount: number;
  matchedSourcePaths: string[];
}> {
  if (!target.sourceCollection || !target.sourceDocumentId) {
    return {
      referenceCount: 0,
      matchedSourcePaths: [],
    };
  }

  const sourcePath = `${target.sourceCollection}/${target.sourceDocumentId}`;
  const sourceDoc = await db
    .collection(target.sourceCollection)
    .doc(target.sourceDocumentId)
    .get();
  if (!sourceDoc.exists) {
    return {
      referenceCount: 0,
      matchedSourcePaths: [],
    };
  }

  const sourceData = sourceDoc.data() ?? {};
  const targetCandidates = buildMediaTargetCandidates(target);
  if (targetCandidates.size === 0) {
    return {
      referenceCount: 1,
      matchedSourcePaths: [sourcePath],
    };
  }

  if (target.sourceCollection === "merchant_topup_requests") {
    const proofDeleted =
      sourceData.proof_storage_deleted === true ||
      financeTimestampToMillis(sourceData.proof_deleted_at) > 0;
    if (!proofDeleted && mediaCandidateMatchesTarget(sourceData.proof_image_url, targetCandidates)) {
      return {
        referenceCount: 1,
        matchedSourcePaths: [sourcePath],
      };
    }
    return {
      referenceCount: 0,
      matchedSourcePaths: [],
    };
  }

  if (target.sourceCollection === "venues") {
    const photos = workspaceStringArray(sourceData.photos);
    const matchedCount = photos.filter((photo) =>
      mediaCandidateMatchesTarget(photo, targetCandidates),
    ).length;
    return {
      referenceCount: matchedCount,
      matchedSourcePaths: matchedCount > 0 ? [sourcePath] : [],
    };
  }

  if (target.sourceCollection === "offers") {
    const offerMediaUrl = workspaceMediaUrl(sourceData, [
      "image_url",
      "imageUrl",
      "media_url",
      "mediaUrl",
      "photo_url",
      "photoUrl",
      "cover_image_url",
      "coverImageUrl",
      "banner_image_url",
      "bannerImageUrl",
    ]);
    return {
      referenceCount: mediaCandidateMatchesTarget(offerMediaUrl, targetCandidates)
        ? 1
        : 0,
      matchedSourcePaths: mediaCandidateMatchesTarget(offerMediaUrl, targetCandidates)
        ? [sourcePath]
        : [],
    };
  }

  if (target.sourceCollection === "stories") {
    const storyMediaUrl = workspaceMediaUrl(sourceData, [
      "image_url",
      "imageUrl",
      "media_url",
      "mediaUrl",
      "photo_url",
      "photoUrl",
      "thumbnail_url",
      "thumbnailUrl",
    ]);
    return {
      referenceCount: mediaCandidateMatchesTarget(storyMediaUrl, targetCandidates)
        ? 1
        : 0,
      matchedSourcePaths: mediaCandidateMatchesTarget(storyMediaUrl, targetCandidates)
        ? [sourcePath]
        : [],
    };
  }

  return {
    referenceCount: 1,
    matchedSourcePaths: [sourcePath],
  };
}

async function evaluateMediaReferenceCheck(
  target: MediaGovernanceTarget,
  now: Timestamp,
): Promise<MediaReferenceCheckSummary> {
  const [indexHealth, referenceMatches] = await Promise.all([
    loadMediaReferenceIndexHealth(now),
    loadMediaReferenceMatchCount(target),
  ]);

  let blockedReason: "reference_index_unhealthy" | "references_present" | null = null;
  if (indexHealth.status !== "healthy") {
    blockedReason = "reference_index_unhealthy";
  } else if (referenceMatches.referenceCount > 0) {
    blockedReason = "references_present";
  }

  return {
    checkedAt: now.toDate().toISOString(),
    referenceCount: referenceMatches.referenceCount,
    indexStatus: indexHealth.status,
    indexAsOf: indexHealth.asOf,
    indexDetail: indexHealth.detail,
    purgeEligible: blockedReason === null,
    blockedReason,
    matchedSourcePaths: referenceMatches.matchedSourcePaths,
  };
}

function mediaReferenceCheckToFirestore(
  summary: MediaReferenceCheckSummary,
): Record<string, unknown> {
  return {
    checked_at: summary.checkedAt,
    reference_count: summary.referenceCount,
    index_status: summary.indexStatus,
    index_as_of: summary.indexAsOf,
    index_detail: summary.indexDetail,
    purge_eligible: summary.purgeEligible,
    blocked_reason: summary.blockedReason,
    matched_source_paths: summary.matchedSourcePaths,
  };
}

function readMediaCommandReplayResult(
  existingCommandDoc: FirebaseFirestore.DocumentSnapshot,
  payloadHash: string,
  fallbackCorrelationId: string | null,
): Record<string, unknown> | null {
  if (!existingCommandDoc.exists) {
    return null;
  }

  const existing = existingCommandDoc.data() ?? {};
  const existingPayloadHash = workspaceString(existing.payload_hash);
  if (existingPayloadHash && existingPayloadHash !== payloadHash) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "media_command_payload_mismatch",
    );
  }

  const existingResult = mediaRecordOrNull(existing.result);
  if (!existingResult) {
    return null;
  }

  const existingCorrelationId =
    workspaceString(existingResult.correlationId) ||
    workspaceString(existing.correlation_id) ||
    fallbackCorrelationId;

  return {
    ...existingResult,
    idempotent: true,
    correlationId: existingCorrelationId || null,
  };
}

async function upsertMediaAuditEvent(
  id: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await db.collection(MEDIA_AUDIT_COLLECTION).doc(id).set(payload, { merge: true });
}

function assertMediaPurgeExpectedState(
  expectedState: Record<string, unknown> | null,
): void {
  const expectedMediaState = workspaceString(expectedState?.media_state).toLowerCase();
  const expectedReferenceHealth = workspaceString(
    expectedState?.reference_index_health,
  ).toLowerCase();
  const expectedReferenceCount =
    typeof expectedState?.reference_count === "number"
      ? expectedState.reference_count
      : Number.NaN;

  if (
    expectedMediaState !== "quarantined" ||
    expectedReferenceHealth !== "healthy" ||
    expectedReferenceCount !== 0
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "media_purge_expected_state_conflict",
    );
  }
}

function normalizeStorageDeleteError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === "string" && error.trim().length > 0) {
    return error.trim();
  }
  return "unknown_storage_delete_error";
}

export {
  MEDIA_ASSET_COLLECTION,
  MEDIA_COMMAND_COLLECTION,
  assertMediaPurgeExpectedState,
  buildMediaPayloadShape,
  buildMediaSafetyMetadata,
  evaluateMediaReferenceCheck,
  getDefaultStorageBucket,
  hashMediaPayload,
  loadMediaReferenceIndexHealth,
  mediaAssetDocIdFromKey,
  mediaCommandDocId,
  mediaReferenceCheckToFirestore,
  mediaStoragePathFromUrl,
  normalizeMediaCommandEnvelope,
  normalizeMediaGovernanceTarget,
  normalizeMediaQuarantineUntil,
  normalizeStorageDeleteError,
  readMediaCommandReplayResult,
  resolveWalletLedgerUiType,
  requireMediaGovernanceAccess,
  upsertMediaAuditEvent,
  workspaceMediaUrl,
  workspaceOfferStatus,
  workspaceStoryStatus,
  workspaceStringArray,
};

export {
  listVenueReviewsForAdmin,
  moderateVenueReviewForAdmin,
} from "./admin_reviews";

export {
  getAdminMediaInventoryReadBundle,
  mediaSoftDeleteAsset,
  mediaQuarantineAsset,
  mediaReferenceCheckAsset,
  mediaPurgeAsset,
} from "./admin_media";

export {
  getAdminVenueWorkspaceReadBundle,
  listVenuesForAdmin,
  adminCreateVenue,
  adminUpdateVenueProfile,
  adminUpdateVenueVisibility,
  adminUpdateVenueOperationalStatus,
  adminUpdateVenueSubscriptionStatus
} from "./admin_venues";


// CONFIG GOVERNANCE

export {
  getAdminConfigGovernanceBundle,
  configUpsertDraft,
  configReviewDraft,
  configPublishDraft,
  configRollbackVersion,
} from "./admin_config";

// CONTENT GOVERNANCE




export {
  listOffersForAdmin,
  listStoriesForAdmin,
  contentModerateOffer,
  contentModerateStory
} from "./admin_content";
