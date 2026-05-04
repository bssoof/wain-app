import * as functions from "firebase-functions/v1";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

import {
  REVIEW_MODERATION_AUDIT_COLLECTION,
  REVIEW_MODERATION_COMMAND_COLLECTION,
  buildReviewModerationPayloadShape,
  hashReviewModerationPayload,
  normalizeReviewModerationAction,
  normalizeReviewModerationEnvelope,
  normalizeReviewModerationTarget,
  requireReviewModerationAccess,
  reviewModerationCommandDocId,
  targetStatusForReviewAction,
} from "./shared/review-moderation";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { db } from "./shared/firestore-db";
import {
  clampFinanceReadLimit,
  normalizeNumber,
  workspaceReviewStatus,
} from "./shared/admin-surface-helpers";
import {
  financeTimestampToIso,
  mediaRecordOrNull,
  workspaceString,
} from "./shared/finance-media-normalizers";

/**
 * listVenueReviewsForAdmin
 * Dedicated admin review moderation read surface (content roles only).
 */
export const listVenueReviewsForAdmin = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    await requireReviewModerationAccess(context);

    const venueId =
      typeof data?.venueId === "string" ? data.venueId.trim() : "";
    const limit = clampFinanceReadLimit(data?.limit, 25, 1, 80);
    const correlationId =
      typeof data?.correlationId === "string" ? data.correlationId.trim() : null;
    const rawStatuses = Array.isArray(data?.statuses) ? data.statuses : [];
    const statusFilter = rawStatuses
      .map((value: unknown) => workspaceString(value).toLowerCase())
      .filter(
        (value: unknown): value is "published" | "flagged" | "hidden" =>
          value === "published" || value === "flagged" || value === "hidden",
      );
    const now = Timestamp.now();

    const reviewsSnap = venueId
      ? await db.collection("venues").doc(venueId).collection("reviews").limit(limit).get()
      : await db.collectionGroup("reviews").limit(limit).get();

    const venueIds = Array.from(
      new Set(
        reviewsSnap.docs
          .map((doc) => doc.ref.parent.parent?.id)
          .filter((value): value is string => typeof value === "string" && value.length > 0),
      ),
    );
    const venueDocs = await Promise.all(
      venueIds.map(async (id) => [id, await db.collection("venues").doc(id).get()] as const),
    );
    const venueNames = new Map<string, string>(
      venueDocs.map(([id, doc]) => {
        const row = doc.data() ?? {};
        return [
          id,
          workspaceString(row.name_ar) ||
            workspaceString(row.name) ||
            workspaceString(row.name_en) ||
            id,
        ];
      }),
    );

    const items = reviewsSnap.docs
      .map((doc) => {
        const row = doc.data() ?? {};
        const parentVenueId = doc.ref.parent.parent?.id ?? venueId;
        const status = workspaceReviewStatus(row);
        return {
          id: doc.id,
          venueId: parentVenueId,
          venueName: venueNames.get(parentVenueId) ?? parentVenueId,
          authorName:
            workspaceString(row.author_name) ||
            workspaceString(row.display_name) ||
            workspaceString(row.user_name) ||
            "Guest",
          rating: Math.max(0, Math.min(5, normalizeNumber(row.rating))),
          status,
          snippet:
            workspaceString(row.comment) ||
            workspaceString(row.review_text) ||
            workspaceString(row.text) ||
            "No review snippet available.",
          createdAt: financeTimestampToIso(row.created_at ?? now),
          moderationReason:
            workspaceString(row.moderation_reason) ||
            workspaceString(row.flag_reason) ||
            null,
          moderationNote: workspaceString(row.moderation_note) || null,
          moderatedAt:
            financeTimestampToIso(row.moderated_at) ||
            financeTimestampToIso(row.updated_at) ||
            null,
          moderatedByUid: workspaceString(row.moderated_by_uid) || null,
        };
      })
      .filter((item) => statusFilter.length === 0 || statusFilter.includes(item.status))
      .sort((left, right) => Date.parse(right.createdAt) - Date.parse(left.createdAt));

    return {
      checkedAt: now.toMillis(),
      correlationId,
      filtersApplied: {
        venueId: venueId || null,
        statuses: statusFilter,
        limit,
      },
      items,
    };
  },
);

/**
 * moderateVenueReviewForAdmin
 * Server-authorized review moderation command.
 */
export const moderateVenueReviewForAdmin = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    const access = await requireReviewModerationAccess(context);

    const target = normalizeReviewModerationTarget(data);
    const action = normalizeReviewModerationAction(data?.action);
    const now = Timestamp.now();
    const envelope = normalizeReviewModerationEnvelope(action, data, target, now);
    const targetStatus = targetStatusForReviewAction(action);
    const reviewRef = db
      .collection("venues")
      .doc(target.venueId)
      .collection("reviews")
      .doc(target.reviewId);
    const commandDocId = reviewModerationCommandDocId(
      action,
      target,
      envelope.commandId,
    );
    const commandRef = db
      .collection(REVIEW_MODERATION_COMMAND_COLLECTION)
      .doc(commandDocId);
    const auditEventId = `review_moderated_${commandDocId}`;
    const auditRef = db.collection(REVIEW_MODERATION_AUDIT_COLLECTION).doc(auditEventId);
    const payloadShape = buildReviewModerationPayloadShape(target, envelope);
    const payloadHash = hashReviewModerationPayload(payloadShape);

    const result = await db.runTransaction(async (transaction) => {
      const [commandDoc, reviewDoc] = await Promise.all([
        transaction.get(commandRef),
        transaction.get(reviewRef),
      ]);

      if (commandDoc.exists) {
        const existing = commandDoc.data() ?? {};
        if (existing.payload_hash !== payloadHash) {
          throw new functions.https.HttpsError(
            "already-exists",
            "review_moderation_command_payload_conflict",
          );
        }

        const storedResult = mediaRecordOrNull(existing.result);
        if (storedResult) {
          return storedResult;
        }
      }

      if (!reviewDoc.exists) {
        throw new functions.https.HttpsError("not-found", "review_not_found");
      }

      const reviewData = reviewDoc.data() ?? {};
      const currentStatus = workspaceReviewStatus(reviewData);
      const expectedStatus = workspaceString(
        envelope.expectedState?.moderation_state,
      ).toLowerCase();
      if (expectedStatus && expectedStatus !== currentStatus) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "review_moderation_expected_state_conflict",
        );
      }

      if (currentStatus === targetStatus) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "review_already_in_target_state",
        );
      }

      const resultData = {
        reviewId: target.reviewId,
        venueId: target.venueId,
        status: targetStatus,
        moderationState: targetStatus,
        auditEventId,
        moderatedAt: now.toMillis(),
      };

      transaction.set(
        reviewRef,
        {
          status: targetStatus,
          moderation_state: targetStatus,
          hidden: targetStatus === "hidden",
          is_hidden: targetStatus === "hidden",
          flagged: targetStatus === "flagged",
          is_flagged: targetStatus === "flagged",
          moderation_reason: envelope.reason,
          moderation_note: envelope.note ?? FieldValue.delete(),
          moderated_by_uid: access.uid,
          moderated_by_role: access.role,
          moderated_auth_source: access.source,
          moderated_at: now,
          updated_at: now,
        },
        { merge: true },
      );
      transaction.set(
        auditRef,
        {
          review_id: target.reviewId,
          venue_id: target.venueId,
          source_path: target.sourcePath,
          action,
          previous_status: currentStatus,
          target_status: targetStatus,
          moderation_reason: envelope.reason,
          moderation_note: envelope.note,
          command_id: envelope.commandId,
          correlation_id: envelope.correlationId,
          idempotency_key: envelope.idempotencyKey,
          expected_state: envelope.expectedState,
          moderated_by_uid: access.uid,
          moderated_by_role: access.role,
          moderated_auth_source: access.source,
          created_at: now,
          updated_at: now,
        },
        { merge: true },
      );
      transaction.set(
        commandRef,
        {
          review_id: target.reviewId,
          venue_id: target.venueId,
          source_path: target.sourcePath,
          action,
          command_id: envelope.commandId,
          correlation_id: envelope.correlationId,
          idempotency_key: envelope.idempotencyKey,
          payload_hash: payloadHash,
          payload_shape: payloadShape,
          result: resultData,
          moderated_by_uid: access.uid,
          moderated_by_role: access.role,
          created_at: now,
          updated_at: now,
        },
        { merge: true },
      );

      return resultData;
    });

    logSecurityAudit("review_moderation_applied", {
      uid: access.uid,
      role: access.role,
      action,
      venueId: target.venueId,
      reviewId: target.reviewId,
      moderationState: result.moderationState,
      commandId: envelope.commandId,
      correlationId: envelope.correlationId,
      timestamp: now.toMillis(),
    });

    return result;
  },
);
