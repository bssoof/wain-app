import * as functions from "firebase-functions/v1";
import { firestore } from "firebase-admin";

import { requireAdminAccessWithDb } from "./shared/admin-auth";
import { db } from "./shared/firestore-db";
import {
  mediaRecordOrNull,
  workspaceString,
  normalizeMediaIsoTimestamp,
  financeTimestampToOptionalIso,
  financeTimestampToIsoWithFallback,
} from "./shared/finance-media-normalizers";

export const CONTENT_AUDIT_COLLECTION = "content_audit_events";
export const CONTENT_COMMAND_COLLECTION = "content_governance_commands";

export type ContentGovernanceRole = "content_admin" | "super_admin";

export function resolveContentGovernanceRole(
  context: functions.https.CallableContext,
): ContentGovernanceRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  if (token.content_admin === true || token.role === "content_admin") {
    return "content_admin";
  }
  return null;
}

export async function requireContentGovernanceAccess(
  context: functions.https.CallableContext,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: ContentGovernanceRole;
}> {
  const baseAccess = await requireAdminAccessWithDb(context, db);
  const role = resolveContentGovernanceRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "content_role_not_authorized",
    );
  }
  return { ...baseAccess, role };
}

const ALLOWED_CONTENT_MODERATION_REASONS = new Set([
  "policy_violation",
  "inappropriate_content",
  "merchant_request",
  "quality_standard",
  "other"
]);

const ALLOWED_CONTENT_ACTIONS = new Set(["approve", "reject", "flag", "pause"]);

export function normalizeContentModerationReason(reason: unknown): string {
  if (typeof reason !== "string") return "other";
  const norm = reason.trim().toLowerCase();
  return ALLOWED_CONTENT_MODERATION_REASONS.has(norm) ? norm : "other";
}

export function normalizeContentCommandEnvelope(data: unknown, now: firestore.Timestamp) {
  const payload = mediaRecordOrNull(data) ?? {};

  const action = typeof payload.action === "string" ? payload.action.trim() : "";
  if (!ALLOWED_CONTENT_ACTIONS.has(action)) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_content_action");
  }

  const commandId = typeof payload.commandId === "string" ? payload.commandId.trim() : "";
  if (!commandId || commandId.length < 5 || commandId.length > 100) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_command_id");
  }

  return {
    commandId,
    action,
    idempotencyKey:
      typeof payload.idempotencyKey === "string" &&
      payload.idempotencyKey.trim().length > 0
        ? payload.idempotencyKey.trim()
        : commandId,
    reason: normalizeContentModerationReason(payload.reason),
    note: typeof payload.note === "string" ? payload.note.trim().slice(0, 500) : null,
    correlationId: typeof payload.correlationId === "string" ? payload.correlationId.trim() : null,
    submittedAt: normalizeMediaIsoTimestamp(payload.submittedAt, now),
    expectedState: mediaRecordOrNull(payload.expectedState),
  };
}

export type ContentAdminModerationState =
  | "pending"
  | "approved"
  | "rejected"
  | "flagged"
  | "paused";

export function normalizeContentAdminState(value: unknown): ContentAdminModerationState {
  const normalized = workspaceString(value).toLowerCase();
  if (
    normalized === "approved" ||
    normalized === "rejected" ||
    normalized === "flagged" ||
    normalized === "paused"
  ) {
    return normalized;
  }
  return "pending";
}

export function contentTargetStateForAction(action: string): ContentAdminModerationState {
  switch (action) {
    case "approve":
      return "approved";
    case "reject":
      return "rejected";
    case "flag":
      return "flagged";
    case "pause":
      return "paused";
    default:
      return "pending";
  }
}

export function contentActiveStateForTarget(
  targetState: ContentAdminModerationState,
  currentIsActive: unknown,
): boolean {
  if (targetState === "approved") {
    return true;
  }
  if (
    targetState === "rejected" ||
    targetState === "flagged" ||
    targetState === "paused"
  ) {
    return false;
  }
  return currentIsActive !== false;
}

export function readContentCommandReplayResult(
  existingCommandDoc: firestore.DocumentSnapshot,
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
      "content_moderation_command_payload_conflict",
    );
  }

  const storedResult = mediaRecordOrNull(existing.result);
  if (!storedResult) {
    return null;
  }

  return {
    ...storedResult,
    replay: true,
  };
}

export function normalizeContentStatuses(value: unknown): ContentAdminModerationState[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => normalizeContentAdminState(entry))
    .filter((entry, index, all) => all.indexOf(entry) === index);
}

export function normalizeOfferAdminItem(
  doc: firestore.QueryDocumentSnapshot,
  venueNames: Map<string, string>,
  now: firestore.Timestamp,
) {
  const row = doc.data() ?? {};
  const venueId = workspaceString(row.venue_id);
  if (!venueId) {
    return null;
  }

  return {
    id: doc.id,
    venueId,
    venueName: venueNames.get(venueId) ?? venueId,
    title:
      workspaceString(row.title_ar) ||
      workspaceString(row.title) ||
      workspaceString(row.name) ||
      doc.id,
    description:
      workspaceString(row.description_ar) ||
      workspaceString(row.description) ||
      null,
    adminState: normalizeContentAdminState(row.admin_state),
    isActive: row.is_active !== false,
    isFeatured: row.is_featured === true || row.isFeatured === true,
    featuredUntil: financeTimestampToOptionalIso(
      row.featured_until ?? row.featuredUntil,
    ),
    startAt: financeTimestampToOptionalIso(row.start_at ?? row.starts_at),
    endAt: financeTimestampToOptionalIso(row.end_at ?? row.ends_at),
    moderationReason: workspaceString(row.moderation_reason) || null,
    moderationNote: workspaceString(row.moderation_note) || null,
    moderatedAt: financeTimestampToOptionalIso(row.moderated_at),
    createdAt: financeTimestampToIsoWithFallback(row.created_at, now),
    updatedAt: financeTimestampToIsoWithFallback(
      row.updated_at ?? row.created_at,
      now,
    ),
  };
}

export function normalizeStoryAdminItem(
  doc: firestore.QueryDocumentSnapshot,
  venueNames: Map<string, string>,
  now: firestore.Timestamp,
) {
  const row = doc.data() ?? {};
  const venueId = workspaceString(row.venue_id);
  if (!venueId) {
    return null;
  }

  return {
    id: doc.id,
    venueId,
    venueName: venueNames.get(venueId) ?? venueId,
    caption:
      workspaceString(row.caption) ||
      workspaceString(row.text) ||
      workspaceString(row.caption_ar) ||
      doc.id,
    adminState: normalizeContentAdminState(row.admin_state),
    isActive: row.is_active !== false,
    isPromoted: row.is_promoted === true || row.isPromoted === true,
    promotedUntil: financeTimestampToOptionalIso(
      row.promoted_until ?? row.promotedUntil,
    ),
    expiresAt: financeTimestampToOptionalIso(row.expires_at ?? row.expire_at),
    mediaUrl:
      workspaceString(row.image_url) ||
      workspaceString(row.imageUrl) ||
      workspaceString(row.media_url) ||
      null,
    moderationReason: workspaceString(row.moderation_reason) || null,
    moderationNote: workspaceString(row.moderation_note) || null,
    moderatedAt: financeTimestampToOptionalIso(row.moderated_at),
    createdAt: financeTimestampToIsoWithFallback(row.created_at, now),
    updatedAt: financeTimestampToIsoWithFallback(
      row.updated_at ?? row.created_at,
      now,
    ),
  };
}
