import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "./shared/firestore-db";
import { FieldValue } from "firebase-admin/firestore";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import {
  clampFinanceReadLimit,
  loadVenueDisplayLabels,
} from "./shared/admin-surface-helpers";
import {
  mediaRecordOrNull,
  workspaceString,
} from "./shared/finance-media-normalizers";
import {
  requireContentGovernanceAccess,
  normalizeContentStatuses,
  normalizeOfferAdminItem,
  normalizeStoryAdminItem,
  CONTENT_AUDIT_COLLECTION,
  CONTENT_COMMAND_COLLECTION,
  normalizeContentCommandEnvelope,
  contentTargetStateForAction,
  readContentCommandReplayResult,
  normalizeContentAdminState,
  contentActiveStateForTarget,
} from "./content_governance_access";
import {
  buildContentModerationPayloadShape,
  contentModerationCommandDocId,
  hashContentModerationPayload,
} from "./content_governance_hashing";

export const listOffersForAdmin = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  await requireContentGovernanceAccess(context);

  const venueId = workspaceString(data?.venueId);
  const limit = clampFinanceReadLimit(data?.limit, 50, 1, 100);
  const scanLimit = Math.min(limit * 4, 250);
  const correlationId = workspaceString(data?.correlationId) || null;
  const statusFilter = normalizeContentStatuses(data?.statuses);
  const now = Timestamp.now();

  const offersQuery = venueId
    ? db.collection("offers").where("venue_id", "==", venueId).limit(scanLimit)
    : db.collection("offers").limit(scanLimit);
  const offersSnap = await offersQuery.get();
  const venueNames = await loadVenueDisplayLabels(
    offersSnap.docs.map((doc: any) => workspaceString(doc.data()?.venue_id)),
  );

  const items = offersSnap.docs
    .map((doc: any) => normalizeOfferAdminItem(doc, venueNames, now))
    .filter((item: any): item is NonNullable<ReturnType<typeof normalizeOfferAdminItem>> => Boolean(item))
    .filter(
      (item: any) => statusFilter.length === 0 || statusFilter.includes(item.adminState),
    )
    .sort((left: any, right: any) => Date.parse(right.updatedAt) - Date.parse(left.updatedAt))
    .slice(0, limit);

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
});

export const listStoriesForAdmin = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  await requireContentGovernanceAccess(context);

  const venueId = workspaceString(data?.venueId);
  const limit = clampFinanceReadLimit(data?.limit, 50, 1, 100);
  const scanLimit = Math.min(limit * 4, 250);
  const correlationId = workspaceString(data?.correlationId) || null;
  const statusFilter = normalizeContentStatuses(data?.statuses);
  const now = Timestamp.now();

  const storiesQuery = venueId
    ? db.collection("stories").where("venue_id", "==", venueId).limit(scanLimit)
    : db.collection("stories").limit(scanLimit);
  const storiesSnap = await storiesQuery.get();
  const venueNames = await loadVenueDisplayLabels(
    storiesSnap.docs.map((doc: any) => workspaceString(doc.data()?.venue_id)),
  );

  const items = storiesSnap.docs
    .map((doc: any) => normalizeStoryAdminItem(doc, venueNames, now))
    .filter((item: any): item is NonNullable<ReturnType<typeof normalizeStoryAdminItem>> => Boolean(item))
    .filter(
      (item: any) => statusFilter.length === 0 || statusFilter.includes(item.adminState),
    )
    .sort((left: any, right: any) => Date.parse(right.updatedAt) - Date.parse(left.updatedAt))
    .slice(0, limit);

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
});

export const contentModerateOffer = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const { uid: adminUid, source: authSource, role: adminRole } =
    await requireContentGovernanceAccess(context);
  const now = Timestamp.now();

  const envelope = normalizeContentCommandEnvelope(data, now);
  const payload = mediaRecordOrNull(data) ?? {};
  const offerId = workspaceString(payload.offerId);
  const venueId = workspaceString(payload.venueId);

  if (!offerId || !venueId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing_offer_or_venue",
    );
  }

  const targetRef = db.collection("offers").doc(offerId);
  const commandDocId = contentModerationCommandDocId("offer", offerId, envelope.commandId);
  const commandRef = db.collection(CONTENT_COMMAND_COLLECTION).doc(commandDocId);
  const newAdminState = contentTargetStateForAction(envelope.action);
  const auditEventId = `offer_${envelope.action}_${commandDocId}`;
  const auditRef = db.collection(CONTENT_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = buildContentModerationPayloadShape(
    "offer",
    offerId,
    venueId,
    envelope,
  );
  const payloadHash = hashContentModerationPayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, targetDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(targetRef),
    ]);

    const replayResult = readContentCommandReplayResult(commandDoc, payloadHash);
    if (replayResult) {
      return replayResult;
    }

    if (!targetDoc.exists) {
      throw new functions.https.HttpsError("not-found", "offer_not_found");
    }

    const targetData = targetDoc.data() ?? {};
    if (workspaceString(targetData.venue_id) !== venueId) {
      throw new functions.https.HttpsError("failed-precondition", "venue_mismatch");
    }

    const currentAdminState = normalizeContentAdminState(targetData.admin_state);
    const expectedAdminState = workspaceString(
      envelope.expectedState?.admin_state,
    ).toLowerCase();
    if (expectedAdminState && expectedAdminState !== currentAdminState) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "content_expected_state_conflict",
      );
    }

    if (currentAdminState === newAdminState) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "content_already_in_target_state",
      );
    }

    const isActiveUpdate = contentActiveStateForTarget(
      newAdminState,
      targetData.is_active,
    );
    const resultData = {
      success: true,
      action: envelope.action,
      commandId: envelope.commandId,
      offerId,
      newAdminState,
      isActive: isActiveUpdate,
      auditEventId,
      replay: false,
    };

    transaction.set(
      targetRef,
      {
        admin_state: newAdminState,
        is_active: isActiveUpdate,
        moderation_reason: envelope.reason,
        moderation_note: envelope.note ?? FieldValue.delete(),
        moderated_at: now,
        moderated_by_uid: adminUid,
        moderated_by_role: adminRole,
        moderated_auth_source: authSource,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      auditRef,
      {
        category: "content_ops",
        event_type: `offer_${envelope.action}`,
        offer_id: offerId,
        venue_id: venueId,
        action: envelope.action,
        previous_admin_state: currentAdminState,
        admin_state: newAdminState,
        is_active: isActiveUpdate,
        reason: envelope.reason,
        note: envelope.note,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        idempotency_key: envelope.idempotencyKey,
        expected_state: envelope.expectedState,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        submitted_at: envelope.submittedAt,
        timestamp: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      commandRef,
      {
        command_id: envelope.commandId,
        action: envelope.action,
        idempotency_key: envelope.idempotencyKey,
        correlation_id: envelope.correlationId,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        target_type: "offer",
        target_id: offerId,
        venue_id: venueId,
        payload_hash: payloadHash,
        payload_shape: payloadShape,
        result: resultData,
        executed_at: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );

    return resultData;
  });

  logSecurityAudit("content_offer_moderated", {
    adminUid,
    adminRole,
    authSource,
    action: envelope.action,
    offerId,
    venueId,
    commandId: envelope.commandId,
    correlationId: envelope.correlationId,
    moderationState: result.newAdminState,
    timestamp: now.toMillis(),
  });

  return result;
});

export const contentModerateStory = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const { uid: adminUid, source: authSource, role: adminRole } =
    await requireContentGovernanceAccess(context);
  const now = Timestamp.now();

  const envelope = normalizeContentCommandEnvelope(data, now);
  const payload = mediaRecordOrNull(data) ?? {};
  const storyId = workspaceString(payload.storyId);
  const venueId = workspaceString(payload.venueId);

  if (!storyId || !venueId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing_story_or_venue",
    );
  }

  const targetRef = db.collection("stories").doc(storyId);
  const commandDocId = contentModerationCommandDocId("story", storyId, envelope.commandId);
  const commandRef = db.collection(CONTENT_COMMAND_COLLECTION).doc(commandDocId);
  const newAdminState = contentTargetStateForAction(envelope.action);
  const auditEventId = `story_${envelope.action}_${commandDocId}`;
  const auditRef = db.collection(CONTENT_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = buildContentModerationPayloadShape(
    "story",
    storyId,
    venueId,
    envelope,
  );
  const payloadHash = hashContentModerationPayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, targetDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(targetRef),
    ]);

    const replayResult = readContentCommandReplayResult(commandDoc, payloadHash);
    if (replayResult) {
      return replayResult;
    }

    if (!targetDoc.exists) {
      throw new functions.https.HttpsError("not-found", "story_not_found");
    }

    const targetData = targetDoc.data() ?? {};
    if (workspaceString(targetData.venue_id) !== venueId) {
      throw new functions.https.HttpsError("failed-precondition", "venue_mismatch");
    }

    const currentAdminState = normalizeContentAdminState(targetData.admin_state);
    const expectedAdminState = workspaceString(
      envelope.expectedState?.admin_state,
    ).toLowerCase();
    if (expectedAdminState && expectedAdminState !== currentAdminState) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "content_expected_state_conflict",
      );
    }

    if (currentAdminState === newAdminState) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "content_already_in_target_state",
      );
    }

    const isActiveUpdate = contentActiveStateForTarget(
      newAdminState,
      targetData.is_active,
    );
    const resultData = {
      success: true,
      action: envelope.action,
      commandId: envelope.commandId,
      storyId,
      newAdminState,
      isActive: isActiveUpdate,
      auditEventId,
      replay: false,
    };

    transaction.set(
      targetRef,
      {
        admin_state: newAdminState,
        is_active: isActiveUpdate,
        moderation_reason: envelope.reason,
        moderation_note: envelope.note ?? FieldValue.delete(),
        moderated_at: now,
        moderated_by_uid: adminUid,
        moderated_by_role: adminRole,
        moderated_auth_source: authSource,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      auditRef,
      {
        category: "content_ops",
        event_type: `story_${envelope.action}`,
        story_id: storyId,
        venue_id: venueId,
        action: envelope.action,
        previous_admin_state: currentAdminState,
        admin_state: newAdminState,
        is_active: isActiveUpdate,
        reason: envelope.reason,
        note: envelope.note,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        idempotency_key: envelope.idempotencyKey,
        expected_state: envelope.expectedState,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        submitted_at: envelope.submittedAt,
        timestamp: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
    transaction.set(
      commandRef,
      {
        command_id: envelope.commandId,
        action: envelope.action,
        idempotency_key: envelope.idempotencyKey,
        correlation_id: envelope.correlationId,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        target_type: "story",
        target_id: storyId,
        venue_id: venueId,
        payload_hash: payloadHash,
        payload_shape: payloadShape,
        result: resultData,
        executed_at: now,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );

    return resultData;
  });

  logSecurityAudit("content_story_moderated", {
    adminUid,
    adminRole,
    authSource,
    action: envelope.action,
    storyId,
    venueId,
    commandId: envelope.commandId,
    correlationId: envelope.correlationId,
    moderationState: result.newAdminState,
    timestamp: now.toMillis(),
  });

  return result;
});
