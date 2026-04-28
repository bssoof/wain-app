import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";
import * as crypto from "crypto";

import { requireAdminAccessWithDb } from "./admin-auth";
import { db } from "./firestore-db";
import {
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
  workspaceString,
} from "./finance-media-normalizers";

export const REVIEW_MODERATION_COMMAND_COLLECTION = "review_moderation_commands";
export const REVIEW_MODERATION_AUDIT_COLLECTION = "review_moderation_events";
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

export async function requireReviewModerationAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: ReviewModerationRole;
}> {
  const baseAccess = await requireAdminAccessWithDb(context, db);
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

export function normalizeReviewModerationAction(
  value: unknown,
): ReviewModerationAction {
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

export function normalizeReviewModerationTarget(
  data: unknown,
): ReviewModerationTarget {
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

export function normalizeReviewModerationEnvelope(
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

export function targetStatusForReviewAction(
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

export function reviewModerationCommandDocId(
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

export function hashReviewModerationPayload(
  payload: Record<string, unknown>,
): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(sortObjectForReviewHash(payload)))
    .digest("hex");
}

export function buildReviewModerationPayloadShape(
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
