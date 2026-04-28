import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import {
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
  requireMediaGovernanceAccess,
  upsertMediaAuditEvent,
} from "./shared/media-governance";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { requireAdminAccessWithDb } from "./shared/admin-auth";
import {
  clampFinanceReadLimit,
  workspaceMediaUrl,
  workspaceOfferStatus,
  workspaceStoryStatus,
  workspaceStringArray,
} from "./shared/admin-surface-helpers";
import {
  financeTimestampToIsoWithFallback,
  financeTimestampToOptionalIso,
  mediaRecordOrNull,
  workspaceString,
} from "./shared/finance-media-normalizers";
import { db } from "./shared/firestore-db";

async function requireAdminAccess(
  context: functions.https.CallableContext,
): Promise<{ uid: string; source: "claim" | "document" }> {
  return requireAdminAccessWithDb(context, db);
}

/**
 * getAdminMediaInventoryReadBundle
 * Read-only media inventory baseline for proofs, venue photos, offer images, and story images.
 */
export const getAdminMediaInventoryReadBundle = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    await requireAdminAccess(context);

    const venueFilter =
      typeof data?.venueId === "string" ? data.venueId.trim() : "";
    const proofLimit = clampFinanceReadLimit(data?.proofLimit, 30, 1, 120);
    const venuePhotoLimit = clampFinanceReadLimit(data?.venuePhotoLimit, 40, 1, 160);
    const offerImageLimit = clampFinanceReadLimit(data?.offerImageLimit, 40, 1, 160);
    const storyImageLimit = clampFinanceReadLimit(data?.storyImageLimit, 40, 1, 160);
    const now = Timestamp.now();

    let proofQuery: FirebaseFirestore.Query = db.collection("merchant_topup_requests");
    let offersQuery: FirebaseFirestore.Query = db.collection("offers");
    let storiesQuery: FirebaseFirestore.Query = db.collection("stories");
    if (venueFilter) {
      proofQuery = proofQuery.where("venue_id", "==", venueFilter);
      offersQuery = offersQuery.where("venue_id", "==", venueFilter);
      storiesQuery = storiesQuery.where("venue_id", "==", venueFilter);
    }

    const [proofSnap, offersSnap, storiesSnap, referenceIndex] = await Promise.all([
      proofQuery.orderBy("created_at", "desc").limit(Math.min(500, proofLimit * 8)).get(),
      offersQuery.orderBy("created_at", "desc").limit(Math.min(500, offerImageLimit * 6)).get(),
      storiesQuery.orderBy("created_at", "desc").limit(Math.min(500, storyImageLimit * 6)).get(),
      loadMediaReferenceIndexHealth(now),
    ]);

    const venueDocs: Array<{
      id: string;
      data: () => FirebaseFirestore.DocumentData | undefined;
    }> = [];
    if (venueFilter) {
      const venueDoc = await db.collection("venues").doc(venueFilter).get();
      if (venueDoc.exists) {
        venueDocs.push(venueDoc);
      }
    } else {
      const venueSnap = await db.collection("venues").limit(Math.min(250, venuePhotoLimit * 4)).get();
      venueDocs.push(...venueSnap.docs);
    }

    const topupProofs: Array<Record<string, unknown>> = [];
    for (const doc of proofSnap.docs) {
      const row = doc.data() ?? {};
      const proofUrl = workspaceString(row.proof_image_url);
      if (!proofUrl) {
        continue;
      }

      const venueId = workspaceString(row.venue_id);
      if (venueFilter && venueId !== venueFilter) {
        continue;
      }

      topupProofs.push({
        id: doc.id,
        venueId,
        mediaUrl: proofUrl,
        storagePath: mediaStoragePathFromUrl(proofUrl),
        status: workspaceString(row.status) || "pending",
        createdAt: financeTimestampToIsoWithFallback(row.created_at, now),
        reviewedAt: financeTimestampToOptionalIso(row.reviewed_at),
        retentionUntil: financeTimestampToOptionalIso(row.proof_retention_until),
        deletedAt: financeTimestampToOptionalIso(row.proof_deleted_at),
        storageDeleted: row.proof_storage_deleted === true,
        sourceCollection: "merchant_topup_requests",
        sourceDocumentId: doc.id,
        sourceLabel: `merchant_topup_requests/${doc.id}`,
        safety: buildMediaSafetyMetadata({
          referenceType: "topup_request",
          referenceId: doc.id,
          sourceCollection: "merchant_topup_requests",
          sourceDocumentId: doc.id,
          indexHealth: referenceIndex,
        }),
      });

      if (topupProofs.length >= proofLimit) {
        break;
      }
    }

    const venuePhotos: Array<Record<string, unknown>> = [];
    for (const doc of venueDocs) {
      const row = doc.data() ?? {};
      const venueId = doc.id;
      const photos = workspaceStringArray(row.photos);
      if (photos.length === 0) {
        continue;
      }

      for (let photoIndex = 0; photoIndex < photos.length; photoIndex += 1) {
        const mediaUrl = photos[photoIndex];
        venuePhotos.push({
          id: `${venueId}:photo:${photoIndex}`,
          venueId,
          mediaUrl,
          storagePath: mediaStoragePathFromUrl(mediaUrl),
          ordinal: photoIndex,
          createdAt: financeTimestampToIsoWithFallback(row.created_at, now),
          updatedAt: financeTimestampToIsoWithFallback(row.updated_at, now),
          sourceCollection: "venues",
          sourceDocumentId: venueId,
          sourceLabel: `venues/${venueId}`,
          safety: buildMediaSafetyMetadata({
            referenceType: "venue",
            referenceId: venueId,
            sourceCollection: "venues",
            sourceDocumentId: venueId,
            indexHealth: referenceIndex,
          }),
        });

        if (venuePhotos.length >= venuePhotoLimit) {
          break;
        }
      }

      if (venuePhotos.length >= venuePhotoLimit) {
        break;
      }
    }

    const offerImages: Array<Record<string, unknown>> = [];
    for (const doc of offersSnap.docs) {
      const row = doc.data() ?? {};
      const mediaUrl = workspaceMediaUrl(row, [
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
      if (!mediaUrl) {
        continue;
      }

      const venueId = workspaceString(row.venue_id);
      offerImages.push({
        id: doc.id,
        venueId,
        title:
          workspaceString(row.title_ar) ||
          workspaceString(row.title) ||
          doc.id,
        status: workspaceOfferStatus(row, now),
        mediaUrl,
        storagePath: mediaStoragePathFromUrl(mediaUrl),
        startsAt: financeTimestampToOptionalIso(row.start_at ?? row.starts_at),
        endsAt: financeTimestampToOptionalIso(row.end_at ?? row.ends_at),
        createdAt: financeTimestampToIsoWithFallback(row.created_at, now),
        updatedAt: financeTimestampToIsoWithFallback(row.updated_at, now),
        sourceCollection: "offers",
        sourceDocumentId: doc.id,
        sourceLabel: `offers/${doc.id}`,
        safety: buildMediaSafetyMetadata({
          referenceType: "offer",
          referenceId: doc.id,
          sourceCollection: "offers",
          sourceDocumentId: doc.id,
          indexHealth: referenceIndex,
        }),
      });

      if (offerImages.length >= offerImageLimit) {
        break;
      }
    }

    const storyImages: Array<Record<string, unknown>> = [];
    for (const doc of storiesSnap.docs) {
      const row = doc.data() ?? {};
      const mediaUrl = workspaceMediaUrl(row, [
        "image_url",
        "imageUrl",
        "media_url",
        "mediaUrl",
        "photo_url",
        "photoUrl",
        "thumbnail_url",
        "thumbnailUrl",
      ]);
      if (!mediaUrl) {
        continue;
      }

      const venueId = workspaceString(row.venue_id);
      storyImages.push({
        id: doc.id,
        venueId,
        caption:
          workspaceString(row.caption) ||
          workspaceString(row.text) ||
          workspaceString(row.caption_ar) ||
          doc.id,
        status: workspaceStoryStatus(row, now),
        mediaUrl,
        storagePath: mediaStoragePathFromUrl(mediaUrl),
        expiresAt: financeTimestampToOptionalIso(row.expires_at ?? row.expire_at),
        createdAt: financeTimestampToIsoWithFallback(row.created_at, now),
        updatedAt: financeTimestampToIsoWithFallback(row.updated_at, now),
        sourceCollection: "stories",
        sourceDocumentId: doc.id,
        sourceLabel: `stories/${doc.id}`,
        safety: buildMediaSafetyMetadata({
          referenceType: "story",
          referenceId: doc.id,
          sourceCollection: "stories",
          sourceDocumentId: doc.id,
          indexHealth: referenceIndex,
        }),
      });

      if (storyImages.length >= storyImageLimit) {
        break;
      }
    }

    return {
      checkedAt: now.toMillis(),
      correlationId:
        typeof data?.correlationId === "string"
          ? data.correlationId.trim()
          : null,
      referenceIndex,
      topupProofs,
      venuePhotos,
      offerImages,
      storyImages,
    };
  },
);

/**
 * mediaSoftDeleteAsset
 * Server-authorized media soft-delete command.
 */
export const mediaSoftDeleteAsset = functions.https.onCall(async (data, context) => {
    requireAppCheck(context);
    const { uid: adminUid, source: authSource, role: adminRole } =
      await requireMediaGovernanceAccess(context);
    const now = Timestamp.now();
    const target = normalizeMediaGovernanceTarget(data);
    const envelope = normalizeMediaCommandEnvelope(
      "media_soft_delete",
      data,
      target,
      now,
    );

    const expectedMediaState = workspaceString(envelope.expectedState?.media_state).toLowerCase();
    if (
      expectedMediaState &&
      expectedMediaState !== "active" &&
      expectedMediaState !== "quarantined" &&
      expectedMediaState !== "soft_deleted"
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_soft_delete_expected_state_conflict",
      );
    }

    const commandPayload = buildMediaPayloadShape(target, envelope);
    const payloadHash = hashMediaPayload(commandPayload);
    const commandDocId = mediaCommandDocId(
      envelope.action,
      target,
      envelope.commandId,
    );
    const commandRef = db.collection(MEDIA_COMMAND_COLLECTION).doc(commandDocId);
    const existingCommandDoc = await commandRef.get();
    const replayResult = readMediaCommandReplayResult(
      existingCommandDoc,
      payloadHash,
      envelope.correlationId,
    );
    if (replayResult) {
      return replayResult;
    }

    const [referenceCheck, assetDoc] = await Promise.all([
      evaluateMediaReferenceCheck(target, now),
      db.collection(MEDIA_ASSET_COLLECTION).doc(mediaAssetDocIdFromKey(target.assetKey)).get(),
    ]);
    const assetData = assetDoc.data() ?? {};
    const currentState = workspaceString(assetData.current_state).toLowerCase();
    if (currentState === "purged") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_asset_already_purged",
      );
    }

    const assetRef = db.collection(MEDIA_ASSET_COLLECTION).doc(mediaAssetDocIdFromKey(target.assetKey));
    const createdAt = assetData.created_at instanceof Timestamp
      ? assetData.created_at
      : now;
    const auditEventId = `media_soft_deleted_${commandDocId}`;

    await Promise.all([
      assetRef.set({
        asset_key: target.assetKey,
        target_type: target.targetType,
        target_id: target.targetId,
        venue_id: target.venueId,
        source_collection: target.sourceCollection,
        source_document_id: target.sourceDocumentId,
        source_path: target.sourcePath,
        media_url: target.mediaUrl,
        storage_path: target.storagePath,
        reference_type: target.referenceType,
        reference_id: target.referenceId,
        current_state: "soft_deleted",
        last_action: "media_soft_delete",
        soft_deleted_at: now,
        soft_deleted_by_uid: adminUid,
        soft_deleted_by_role: adminRole,
        soft_delete_reason: envelope.reason,
        last_reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        last_command_id: envelope.commandId,
        updated_at: now,
        created_at: createdAt,
      }, { merge: true }),
      upsertMediaAuditEvent(auditEventId, {
        category: "media_ops",
        event_type: "media_soft_deleted",
        action: envelope.action,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        target_type: target.targetType,
        target_id: target.targetId,
        asset_key: target.assetKey,
        source_path: target.sourcePath,
        reason: envelope.reason,
        reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        submitted_at: envelope.submittedAt,
        timestamp: now,
        created_at: now,
        updated_at: now,
      }),
    ]);

    const result: Record<string, unknown> = {
      success: true,
      action: envelope.action,
      commandId: envelope.commandId,
      correlationId: envelope.correlationId,
      targetType: target.targetType,
      targetId: target.targetId,
      status: "soft_deleted",
      assetState: "soft_deleted",
      referenceCheck,
      auditEventId,
      idempotent: false,
    };

    await commandRef.set({
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: adminUid,
      actor_role: adminRole,
      auth_source: authSource,
      target_type: target.targetType,
      target_id: target.targetId,
      asset_key: target.assetKey,
      payload_hash: payloadHash,
      payload: commandPayload,
      result,
      submitted_at: envelope.submittedAt,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    logSecurityAudit("media_soft_delete_executed", {
      adminUid,
      adminRole,
      authSource,
      commandId: envelope.commandId,
      targetType: target.targetType,
      targetId: target.targetId,
      assetKey: target.assetKey,
      correlationId: envelope.correlationId,
      timestamp: now.toMillis(),
    });

    return result;
  });

/**
 * mediaQuarantineAsset
 * Server-authorized media quarantine command.
 */
export const mediaQuarantineAsset = functions.https.onCall(async (data, context) => {
    requireAppCheck(context);
    const { uid: adminUid, source: authSource, role: adminRole } =
      await requireMediaGovernanceAccess(context);
    const now = Timestamp.now();
    const target = normalizeMediaGovernanceTarget(data);
    const envelope = normalizeMediaCommandEnvelope(
      "media_quarantine",
      data,
      target,
      now,
    );

    const expectedMediaState = workspaceString(envelope.expectedState?.media_state).toLowerCase();
    if (
      expectedMediaState &&
      expectedMediaState !== "active" &&
      expectedMediaState !== "soft_deleted" &&
      expectedMediaState !== "quarantined"
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_quarantine_expected_state_conflict",
      );
    }

    const commandPayload = buildMediaPayloadShape(target, envelope);
    const payloadHash = hashMediaPayload(commandPayload);
    const commandDocId = mediaCommandDocId(
      envelope.action,
      target,
      envelope.commandId,
    );
    const commandRef = db.collection(MEDIA_COMMAND_COLLECTION).doc(commandDocId);
    const existingCommandDoc = await commandRef.get();
    const replayResult = readMediaCommandReplayResult(
      existingCommandDoc,
      payloadHash,
      envelope.correlationId,
    );
    if (replayResult) {
      return replayResult;
    }

    const quarantineUntil = normalizeMediaQuarantineUntil(data, now);
    const [referenceCheck, assetDoc] = await Promise.all([
      evaluateMediaReferenceCheck(target, now),
      db.collection(MEDIA_ASSET_COLLECTION).doc(mediaAssetDocIdFromKey(target.assetKey)).get(),
    ]);
    const assetData = assetDoc.data() ?? {};
    const currentState = workspaceString(assetData.current_state).toLowerCase();
    if (currentState === "purged") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_asset_already_purged",
      );
    }

    const assetRef = db.collection(MEDIA_ASSET_COLLECTION).doc(mediaAssetDocIdFromKey(target.assetKey));
    const createdAt = assetData.created_at instanceof Timestamp
      ? assetData.created_at
      : now;
    const auditEventId = `media_quarantined_${commandDocId}`;

    await Promise.all([
      assetRef.set({
        asset_key: target.assetKey,
        target_type: target.targetType,
        target_id: target.targetId,
        venue_id: target.venueId,
        source_collection: target.sourceCollection,
        source_document_id: target.sourceDocumentId,
        source_path: target.sourcePath,
        media_url: target.mediaUrl,
        storage_path: target.storagePath,
        reference_type: target.referenceType,
        reference_id: target.referenceId,
        current_state: "quarantined",
        last_action: "media_quarantine",
        quarantine_started_at: now,
        quarantine_until: quarantineUntil,
        quarantined_by_uid: adminUid,
        quarantined_by_role: adminRole,
        quarantine_reason: envelope.reason,
        last_reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        last_command_id: envelope.commandId,
        updated_at: now,
        created_at: createdAt,
      }, { merge: true }),
      upsertMediaAuditEvent(auditEventId, {
        category: "media_ops",
        event_type: "media_quarantined",
        action: envelope.action,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        target_type: target.targetType,
        target_id: target.targetId,
        asset_key: target.assetKey,
        source_path: target.sourcePath,
        reason: envelope.reason,
        quarantine_until: quarantineUntil,
        reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        submitted_at: envelope.submittedAt,
        timestamp: now,
        created_at: now,
        updated_at: now,
      }),
    ]);

    const result: Record<string, unknown> = {
      success: true,
      action: envelope.action,
      commandId: envelope.commandId,
      correlationId: envelope.correlationId,
      targetType: target.targetType,
      targetId: target.targetId,
      status: "quarantined",
      assetState: "quarantined",
      quarantineUntil: quarantineUntil.toDate().toISOString(),
      referenceCheck,
      auditEventId,
      idempotent: false,
    };

    await commandRef.set({
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: adminUid,
      actor_role: adminRole,
      auth_source: authSource,
      target_type: target.targetType,
      target_id: target.targetId,
      asset_key: target.assetKey,
      payload_hash: payloadHash,
      payload: commandPayload,
      result,
      submitted_at: envelope.submittedAt,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    logSecurityAudit("media_quarantine_executed", {
      adminUid,
      adminRole,
      authSource,
      commandId: envelope.commandId,
      targetType: target.targetType,
      targetId: target.targetId,
      assetKey: target.assetKey,
      correlationId: envelope.correlationId,
      timestamp: now.toMillis(),
    });

    return result;
  });

/**
 * mediaReferenceCheckAsset
 * Server-authorized media reference check command.
 */
export const mediaReferenceCheckAsset = functions.https.onCall(async (data, context) => {
    requireAppCheck(context);
    const { uid: adminUid, source: authSource, role: adminRole } =
      await requireMediaGovernanceAccess(context);
    const now = Timestamp.now();
    const target = normalizeMediaGovernanceTarget(data);
    const envelope = normalizeMediaCommandEnvelope(
      "media_reference_check",
      data,
      target,
      now,
    );

    const commandPayload = buildMediaPayloadShape(target, envelope);
    const payloadHash = hashMediaPayload(commandPayload);
    const commandDocId = mediaCommandDocId(
      envelope.action,
      target,
      envelope.commandId,
    );
    const commandRef = db.collection(MEDIA_COMMAND_COLLECTION).doc(commandDocId);
    const existingCommandDoc = await commandRef.get();
    const replayResult = readMediaCommandReplayResult(
      existingCommandDoc,
      payloadHash,
      envelope.correlationId,
    );
    if (replayResult) {
      return replayResult;
    }

    const referenceCheck = await evaluateMediaReferenceCheck(target, now);
    const assetRef = db.collection(MEDIA_ASSET_COLLECTION).doc(mediaAssetDocIdFromKey(target.assetKey));
    const assetDoc = await assetRef.get();
    const assetData = assetDoc.data() ?? {};
    const createdAt = assetData.created_at instanceof Timestamp
      ? assetData.created_at
      : now;
    const auditEventId = `media_reference_checked_${commandDocId}`;

    await Promise.all([
      assetRef.set({
        asset_key: target.assetKey,
        target_type: target.targetType,
        target_id: target.targetId,
        venue_id: target.venueId,
        source_collection: target.sourceCollection,
        source_document_id: target.sourceDocumentId,
        source_path: target.sourcePath,
        media_url: target.mediaUrl,
        storage_path: target.storagePath,
        reference_type: target.referenceType,
        reference_id: target.referenceId,
        last_action: "media_reference_check",
        last_reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        last_command_id: envelope.commandId,
        updated_at: now,
        created_at: createdAt,
      }, { merge: true }),
      upsertMediaAuditEvent(auditEventId, {
        category: "media_ops",
        event_type: "media_reference_checked",
        action: envelope.action,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        target_type: target.targetType,
        target_id: target.targetId,
        asset_key: target.assetKey,
        source_path: target.sourcePath,
        reason: envelope.reason,
        reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        submitted_at: envelope.submittedAt,
        timestamp: now,
        created_at: now,
        updated_at: now,
      }),
    ]);

    const result: Record<string, unknown> = {
      success: true,
      action: envelope.action,
      commandId: envelope.commandId,
      correlationId: envelope.correlationId,
      targetType: target.targetType,
      targetId: target.targetId,
      status: "checked",
      referenceCheck,
      auditEventId,
      idempotent: false,
    };

    await commandRef.set({
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: adminUid,
      actor_role: adminRole,
      auth_source: authSource,
      target_type: target.targetType,
      target_id: target.targetId,
      asset_key: target.assetKey,
      payload_hash: payloadHash,
      payload: commandPayload,
      result,
      submitted_at: envelope.submittedAt,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    logSecurityAudit("media_reference_check_executed", {
      adminUid,
      adminRole,
      authSource,
      commandId: envelope.commandId,
      targetType: target.targetType,
      targetId: target.targetId,
      assetKey: target.assetKey,
      purgeEligible: referenceCheck.purgeEligible,
      referenceCount: referenceCheck.referenceCount,
      referenceIndexStatus: referenceCheck.indexStatus,
      correlationId: envelope.correlationId,
      timestamp: now.toMillis(),
    });

    return result;
  });

/**
 * mediaPurgeAsset
 * Server-authorized media purge command (hard delete gated by reference check + index health).
 */
export const mediaPurgeAsset = functions.https.onCall(async (data, context) => {
    requireAppCheck(context);
    const { uid: adminUid, source: authSource, role: adminRole } =
      await requireMediaGovernanceAccess(context);
    const now = Timestamp.now();
    const target = normalizeMediaGovernanceTarget(data);
    const envelope = normalizeMediaCommandEnvelope(
      "media_purge",
      data,
      target,
      now,
    );
    assertMediaPurgeExpectedState(envelope.expectedState);

    const commandPayload = buildMediaPayloadShape(target, envelope);
    const payloadHash = hashMediaPayload(commandPayload);
    const commandDocId = mediaCommandDocId(
      envelope.action,
      target,
      envelope.commandId,
    );
    const commandRef = db.collection(MEDIA_COMMAND_COLLECTION).doc(commandDocId);
    const existingCommandDoc = await commandRef.get();
    const replayResult = readMediaCommandReplayResult(
      existingCommandDoc,
      payloadHash,
      envelope.correlationId,
    );
    if (replayResult) {
      return replayResult;
    }

    const assetRef = db.collection(MEDIA_ASSET_COLLECTION).doc(mediaAssetDocIdFromKey(target.assetKey));
    const assetDoc = await assetRef.get();
    const assetData = assetDoc.data() ?? {};
    const currentState = workspaceString(assetData.current_state).toLowerCase();
    if (!assetDoc.exists || currentState !== "quarantined") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_asset_not_quarantined_for_purge",
      );
    }

    const referenceCheck = await evaluateMediaReferenceCheck(target, now);
    if (referenceCheck.indexStatus !== "healthy") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_purge_reference_index_unhealthy",
      );
    }
    if (referenceCheck.referenceCount > 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "media_purge_references_present",
      );
    }

    let storageDeleteStatus: "deleted" | "not_requested" | "not_found" = "not_requested";
    if (target.storagePath) {
      try {
        await getDefaultStorageBucket().file(target.storagePath).delete();
        storageDeleteStatus = "deleted";
      } catch (error) {
        const message = normalizeStorageDeleteError(error);
        const code = mediaRecordOrNull(error)?.code;
        if (
          code === 404 ||
          workspaceString(code) === "404" ||
          /No such object/i.test(message)
        ) {
          storageDeleteStatus = "not_found";
        } else {
          throw new functions.https.HttpsError(
            "failed-precondition",
            `media_purge_storage_delete_failed:${message}`,
          );
        }
      }
    }

    const createdAt = assetData.created_at instanceof Timestamp
      ? assetData.created_at
      : now;
    const auditEventId = `media_purged_${commandDocId}`;

    await Promise.all([
      assetRef.set({
        asset_key: target.assetKey,
        target_type: target.targetType,
        target_id: target.targetId,
        venue_id: target.venueId,
        source_collection: target.sourceCollection,
        source_document_id: target.sourceDocumentId,
        source_path: target.sourcePath,
        media_url: target.mediaUrl,
        storage_path: target.storagePath,
        reference_type: target.referenceType,
        reference_id: target.referenceId,
        current_state: "purged",
        last_action: "media_purge",
        purged_at: now,
        purged_by_uid: adminUid,
        purged_by_role: adminRole,
        purge_reason: envelope.reason,
        storage_delete_status: storageDeleteStatus,
        last_reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        last_command_id: envelope.commandId,
        updated_at: now,
        created_at: createdAt,
      }, { merge: true }),
      upsertMediaAuditEvent(auditEventId, {
        category: "media_ops",
        event_type: "media_purged",
        action: envelope.action,
        command_id: envelope.commandId,
        correlation_id: envelope.correlationId,
        actor_uid: adminUid,
        actor_role: adminRole,
        auth_source: authSource,
        target_type: target.targetType,
        target_id: target.targetId,
        asset_key: target.assetKey,
        source_path: target.sourcePath,
        reason: envelope.reason,
        storage_delete_status: storageDeleteStatus,
        reference_check: mediaReferenceCheckToFirestore(referenceCheck),
        submitted_at: envelope.submittedAt,
        timestamp: now,
        created_at: now,
        updated_at: now,
      }),
    ]);

    const result: Record<string, unknown> = {
      success: true,
      action: envelope.action,
      commandId: envelope.commandId,
      correlationId: envelope.correlationId,
      targetType: target.targetType,
      targetId: target.targetId,
      status: "purged",
      assetState: "purged",
      storageDeleteStatus,
      referenceCheck,
      auditEventId,
      idempotent: false,
    };

    await commandRef.set({
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: adminUid,
      actor_role: adminRole,
      auth_source: authSource,
      target_type: target.targetType,
      target_id: target.targetId,
      asset_key: target.assetKey,
      payload_hash: payloadHash,
      payload: commandPayload,
      result,
      submitted_at: envelope.submittedAt,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    logSecurityAudit("media_purge_executed", {
      adminUid,
      adminRole,
      authSource,
      commandId: envelope.commandId,
      targetType: target.targetType,
      targetId: target.targetId,
      assetKey: target.assetKey,
      storageDeleteStatus,
      referenceIndexStatus: referenceCheck.indexStatus,
      correlationId: envelope.correlationId,
      timestamp: now.toMillis(),
    });

    return result;
  });
