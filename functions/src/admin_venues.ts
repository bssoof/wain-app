import * as functions from "firebase-functions/v1";
import * as crypto from "crypto";
import { FieldPath, Timestamp } from "firebase-admin/firestore";

import { requireAdminAccessWithDb } from "./shared/admin-auth";
import { isEmulatorOwnerToken } from "./shared/admin-auth";
import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { db } from "./shared/firestore-db";
import {
  clampFinanceReadLimit,
  normalizeNumber,
  resolveWalletLedgerUiType,
  roundMoney,
  workspaceOfferStatus,
  workspaceReviewStatus,
  workspaceStoryStatus,
  workspaceStringArray,
} from "./shared/admin-surface-helpers";
import {
  financeTimestampToIso,
  mediaRecordOrNull,
  normalizeMediaIsoTimestamp,
  workspaceString,
} from "./shared/finance-media-normalizers";

async function requireAdminAccess(
  context: functions.https.CallableContext,
): Promise<{ uid: string; source: "claim" | "document" }> {
  return requireAdminAccessWithDb(context, db);
}

const VENUE_ADMIN_COMMAND_COLLECTION = "venue_admin_commands";
const VENUE_ADMIN_AUDIT_COLLECTION = "venue_admin_events";

/**
 * getAdminVenueWorkspaceReadBundle
 * Read-only workspace bundle for venue operations (admin only).
 */
export const getAdminVenueWorkspaceReadBundle = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    await requireAdminAccess(context);

    const venueId =
      typeof data?.venueId === "string" ? data.venueId.trim() : "";
    if (!venueId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "venue_id_required",
      );
    }

    const walletLimit = clampFinanceReadLimit(data?.walletLimit, 12, 1, 25);
    const offersLimit = clampFinanceReadLimit(data?.offersLimit, 12, 1, 25);
    const storiesLimit = clampFinanceReadLimit(data?.storiesLimit, 12, 1, 25);
    const reviewsLimit = clampFinanceReadLimit(data?.reviewsLimit, 12, 1, 25);
    const now = Timestamp.now();

    const venueRef = db.collection("venues").doc(venueId);
    const walletRef = db.collection("merchant_wallets").doc(venueId);
    const walletReportRef = db.collection("merchant_wallet_reports").doc(venueId);

    const [
      venueDoc,
      walletDoc,
      walletReportDoc,
      walletEntriesSnap,
      offersSnap,
      storiesSnap,
      reviewsSnap,
    ] = await Promise.all([
      venueRef.get(),
      walletRef.get(),
      walletReportRef.get(),
      walletRef.collection("entries")
        .orderBy("created_at", "desc")
        .limit(walletLimit)
        .get(),
      // Keep these reads index-light for the read-only workspace shell.
      db.collection("offers")
        .where("venue_id", "==", venueId)
        .limit(offersLimit)
        .get(),
      db.collection("stories")
        .where("venue_id", "==", venueId)
        .limit(storiesLimit)
        .get(),
      venueRef.collection("reviews")
        .limit(reviewsLimit)
        .get(),
    ]);

    if (!venueDoc.exists) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }

    const venueData = venueDoc.data() ?? {};
    const walletData = walletDoc.exists ? walletDoc.data() ?? {} : {};
    const walletReport = walletReportDoc.exists ? walletReportDoc.data() ?? {} : {};

    const venueName =
      workspaceString(venueData.name_ar) ||
      workspaceString(venueData.name) ||
      workspaceString(venueData.name_en) ||
      venueId;
    const walletCurrency =
      workspaceString(walletReport.currency).toUpperCase() === "USD" ||
        workspaceString(walletData.currency).toUpperCase() === "USD"
        ? "USD"
        : "ILS";
    const walletBalance = roundMoney(
      normalizeNumber(
        walletReport.available_balance ?? walletData.available_balance,
      ),
    );
    const lowBalanceThreshold = roundMoney(
      normalizeNumber(
        walletReport.low_balance_threshold ?? walletData.low_balance_threshold,
      ) || 10,
    );
    const readinessStatus =
      venueData.is_active === false
        ? "fail"
        : walletBalance <= lowBalanceThreshold
          ? "warning"
          : "ready";
    const readinessSummary =
      readinessStatus === "fail"
        ? "Venue is inactive in the current read model."
        : readinessStatus === "warning"
          ? `Wallet balance is below threshold (${lowBalanceThreshold} ${walletCurrency}).`
          : "Workspace reads are available for operational review.";

    const walletEntries = walletEntriesSnap.docs.map((doc) => {
      const row = doc.data();
      const uiType = resolveWalletLedgerUiType(row);
      const description =
        workspaceString(row.note) ||
        `${uiType} · ${workspaceString(row.reference_type) || "wallet"}`;
      return {
        id: doc.id,
        type: uiType,
        amount: Math.abs(normalizeNumber(row.amount)),
        currency:
          workspaceString(row.currency).toUpperCase() === "USD" ? "USD" : "ILS",
        description,
        createdAt: financeTimestampToIso(row.created_at),
      };
    });

    const offers = offersSnap.docs
      .map((doc) => {
        const row = doc.data();
        return {
          id: doc.id,
          title:
            workspaceString(row.title_ar) ||
            workspaceString(row.title) ||
            doc.id,
          status: workspaceOfferStatus(row, now),
          startsAt: financeTimestampToIso(row.start_at ?? row.starts_at ?? now),
          endsAt: financeTimestampToIso(row.end_at ?? row.ends_at ?? now),
        };
      })
      .sort((left, right) => Date.parse(right.endsAt) - Date.parse(left.endsAt));

    const stories = storiesSnap.docs
      .map((doc) => {
        const row = doc.data();
        return {
          id: doc.id,
          caption:
            workspaceString(row.caption) ||
            workspaceString(row.caption_ar) ||
            workspaceString(row.title_ar) ||
            doc.id,
          status: workspaceStoryStatus(row, now),
          expiresAt: financeTimestampToIso(row.expires_at ?? row.expire_at ?? now),
        };
      })
      .sort((left, right) => Date.parse(right.expiresAt) - Date.parse(left.expiresAt));

    const reviews = reviewsSnap.docs
      .map((doc) => {
        const row = doc.data();
        return {
          id: doc.id,
          authorName:
            workspaceString(row.author_name) ||
            workspaceString(row.display_name) ||
            workspaceString(row.user_name) ||
            "Guest",
          rating: Math.max(0, Math.min(5, normalizeNumber(row.rating))),
          status: workspaceReviewStatus(row),
          snippet:
            workspaceString(row.comment) ||
            workspaceString(row.review_text) ||
            workspaceString(row.text) ||
            "No review snippet available.",
          createdAt: financeTimestampToIso(row.created_at ?? now),
        };
      })
      .sort((left, right) => Date.parse(right.createdAt) - Date.parse(left.createdAt));

    return {
      checkedAt: now.toMillis(),
      context: {
        venueId,
        venueName,
        walletBalance,
        walletCurrency,
        readinessStatus,
        readinessSummary,
      },
      walletEntries,
      offers,
      stories,
      reviews,
    };
  },
);

/**
 * listVenuesForAdmin
 * Admin-wide venue directory read path. This intentionally does not reuse
 * app geo-search so the admin surface can see every venue even when lat/lng
 * has not been populated yet.
 */
export const listVenuesForAdmin = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  await requireAdminAccess(context);

  const limit = clampFinanceReadLimit(data?.limit, 150, 1, 500);
  const startAfterId = workspaceString(data?.startAfterId);
  const now = Timestamp.now();

  let query = db.collection("venues")
    .orderBy(FieldPath.documentId())
    .limit(limit);
  if (startAfterId) {
    query = query.startAfter(startAfterId);
  }

  const venuesSnap = await query.get();
  const venueDocs = venuesSnap.docs;
  const venueIds = venueDocs.map((doc) => doc.id);

  if (venueIds.length === 0) {
    return {
      checkedAt: now.toMillis(),
      correlationId:
        typeof data?.correlationId === "string"
          ? data.correlationId.trim()
          : null,
      items: [],
      nextCursor: null,
      filtersApplied: {
        limit,
      },
    };
  }

  const walletRefs = venueIds.map((venueId) =>
    db.collection("merchant_wallets").doc(venueId)
  );
  const walletReportRefs = venueIds.map((venueId) =>
    db.collection("merchant_wallet_reports").doc(venueId)
  );

  const [walletDocs, walletReportDocs, merchantCounts] = await Promise.all([
    db.getAll(...walletRefs),
    db.getAll(...walletReportRefs),
    loadMerchantCountsByVenueId(venueIds),
  ]);

  const walletByVenueId = new Map<string, Record<string, unknown>>();
  for (const walletDoc of walletDocs) {
    walletByVenueId.set(walletDoc.id, (walletDoc.data() ?? {}) as Record<string, unknown>);
  }

  const walletReportByVenueId = new Map<string, Record<string, unknown>>();
  for (const walletReportDoc of walletReportDocs) {
    walletReportByVenueId.set(
      walletReportDoc.id,
      (walletReportDoc.data() ?? {}) as Record<string, unknown>,
    );
  }

  const items = venueDocs.map((venueDoc) => {
    const venueData = (venueDoc.data() ?? {}) as Record<string, unknown>;
    const walletData = walletByVenueId.get(venueDoc.id) ?? {};
    const walletReport = walletReportByVenueId.get(venueDoc.id) ?? {};
    const walletBalance = roundMoney(
      normalizeNumber(
        walletReport.available_balance ?? walletData.available_balance,
      ),
    );
    const lowBalanceThreshold = roundMoney(
      normalizeNumber(
        walletReport.low_balance_threshold ?? walletData.low_balance_threshold,
      ) || 10,
    );
    const walletCurrency =
      workspaceString(walletReport.currency).toUpperCase() === "USD" ||
        workspaceString(walletData.currency).toUpperCase() === "USD"
        ? "USD"
        : "ILS";
    const merchantCount = merchantCounts.get(venueDoc.id) ?? 0;

    return {
      id: venueDoc.id,
      name_ar:
        workspaceString(venueData.name_ar) ||
        workspaceString(venueData.name) ||
        workspaceString(venueData.name_en) ||
        venueDoc.id,
      name_en: workspaceString(venueData.name_en),
      lat: parseVenueCoordinateValue(venueData.lat) ?? 0,
      lng: parseVenueCoordinateValue(venueData.lng) ?? 0,
      city: workspaceString(venueData.city),
      city_key:
        workspaceString(venueData.city_key) ||
        normalizeVenueCityKey(venueData.city),
      phone: workspaceString(venueData.phone),
      categories: workspaceStringArray(venueData.categories),
      is_active: venueData.is_active !== false,
      subscription_status: normalizeVenueSubscriptionStatus(
        venueData.subscription_status,
      ),
      visibility_status: normalizeVenueVisibilityStatus(
        venueData.visibility_status,
      ),
      operational_status: normalizeVenueOperationalStatus(
        venueData.operational_status,
      ),
      wallet_available_balance: walletBalance,
      wallet_low_balance_threshold: lowBalanceThreshold,
      wallet_currency: walletCurrency,
      merchant_count: merchantCount,
      merchant_linked: merchantCount > 0,
      created_at: venueData.created_at ?? null,
      updated_at: venueData.updated_at ?? null,
    };
  });

  return {
    checkedAt: now.toMillis(),
    correlationId:
      typeof data?.correlationId === "string"
        ? data.correlationId.trim()
        : null,
    items,
    nextCursor:
      venueDocs.length === limit
        ? venueDocs[venueDocs.length - 1]?.id ?? null
        : null,
    filtersApplied: {
      limit,
    },
  };
});
export const adminCreateVenue = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireVenueGovernanceAccess(context, "create_venue");
  const now = Timestamp.now();
  const envelope = normalizeVenueCommandEnvelope("create_venue", data, now);
  const input = normalizeVenueCreateInput(data);
  const commandDocId = venueCommandDocId(envelope.action, "create", envelope.commandId);
  const commandRef = db.collection(VENUE_ADMIN_COMMAND_COLLECTION).doc(commandDocId);
  const auditEventId = `venue_create_${commandDocId}`;
  const auditRef = db.collection(VENUE_ADMIN_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    create: input,
  };
  const payloadHash = hashVenuePayload(payloadShape);
  const venueRef = db.collection("venues").doc();

  const result = await db.runTransaction(async (transaction) => {
    const commandDoc = await transaction.get(commandRef);
    const replay = readVenueCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    const resultData = {
      action: envelope.action,
      venueId: venueRef.id,
      status: "created",
      auditEventId,
      replay: false,
    };

    transaction.set(venueRef, buildVenueCreateDocument(input, access.uid, now));
    transaction.set(auditRef, {
      category: "venue_ops",
      event_type: "venue_created",
      action: envelope.action,
      venue_id: venueRef.id,
      reason: envelope.reason,
      command_id: envelope.commandId,
      correlation_id: envelope.correlationId,
      idempotency_key: envelope.idempotencyKey,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      submitted_at: envelope.submittedAt,
      timestamp: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });
    transaction.set(commandRef, {
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      target_type: "venue",
      target_id: venueRef.id,
      payload_hash: payloadHash,
      payload_shape: payloadShape,
      result: resultData,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    return resultData;
  });

  logSecurityAudit("venue_created", {
    adminUid: access.uid,
    adminRole: access.role,
    authSource: access.source,
    venueId: result.venueId,
    commandId: envelope.commandId,
    correlationId: envelope.correlationId,
    timestamp: now.toMillis(),
  });

  return result;
});

export const adminUpdateVenueProfile = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireVenueGovernanceAccess(context, "update_venue_profile");
  const now = Timestamp.now();
  const envelope = normalizeVenueCommandEnvelope("update_venue_profile", data, now);
  const requiredExpectedState = requireVenueExpectedState(envelope.expectedState);
  const venueId = normalizeVenueIdFromPayload(data);
  const updates = normalizeVenueProfileUpdates(data);
  const venueRef = db.collection("venues").doc(venueId);
  const commandDocId = venueCommandDocId(envelope.action, venueId, envelope.commandId);
  const commandRef = db.collection(VENUE_ADMIN_COMMAND_COLLECTION).doc(commandDocId);
  const auditEventId = `venue_profile_${commandDocId}`;
  const auditRef = db.collection(VENUE_ADMIN_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    venueId,
    updates,
    expectedState: requiredExpectedState,
  };
  const payloadHash = hashVenuePayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, venueDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(venueRef),
    ]);
    const replay = readVenueCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    if (!venueDoc.exists) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }

    const row = venueDoc.data() ?? {};
    const currentOperationalStatus = normalizeVenueOperationalStatus(row.operational_status);
    const expectedOperationalStatus = requireVenueOperationalStatus(
      requiredExpectedState.operational_status,
    );
    if (expectedOperationalStatus !== currentOperationalStatus) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_expected_state_conflict",
      );
    }
    if (currentOperationalStatus !== "active") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_profile_inactive",
      );
    }

    const currentCity = workspaceString(row.city);
    const currentCityKey = workspaceString(row.city_key);
    const beforeSummary = {
      name_ar: workspaceString(row.name_ar),
      name_en: workspaceString(row.name_en),
      city: currentCity,
      city_key: currentCityKey || normalizeVenueCityKey(currentCity),
      phone: workspaceString(row.phone),
      categories: workspaceStringArray(row.categories),
      lat: parseVenueCoordinateValue(row.lat) ?? 0,
      lng: parseVenueCoordinateValue(row.lng) ?? 0,
      photos: workspaceStringArray(row.photos),
      menu_images: workspaceStringArray(row.menu_images),
    };
    const patch: Record<string, unknown> = { updated_at: now };

    if (updates.nameAr !== undefined && updates.nameAr !== beforeSummary.name_ar) {
      patch.name_ar = updates.nameAr;
      patch.name = updates.nameAr;
      patch.name_ar_norm = buildVenueNameNorm(updates.nameAr);
    }
    if (updates.nameEn !== undefined && updates.nameEn !== beforeSummary.name_en) {
      patch.name_en = updates.nameEn;
      patch.name_en_norm = buildVenueNameNorm(updates.nameEn);
    }
    if (updates.city !== undefined && updates.city !== beforeSummary.city) {
      patch.city = updates.city;
    }
    const nextCityKey = updates.city !== undefined
      ? normalizeVenueCityKey(updates.city)
      : normalizeVenueCityKey(beforeSummary.city);
    if (nextCityKey !== currentCityKey) {
      patch.city_key = nextCityKey;
    }
    if (updates.phone !== undefined && updates.phone !== beforeSummary.phone) {
      patch.phone = updates.phone;
    }
    if (
      updates.categories !== undefined &&
      updates.categories.join("|") !== beforeSummary.categories.join("|")
    ) {
      patch.categories = updates.categories;
    }
    if (
      updates.lat !== undefined &&
      updates.lng !== undefined &&
      (updates.lat !== beforeSummary.lat || updates.lng !== beforeSummary.lng)
    ) {
      patch.lat = updates.lat;
      patch.lng = updates.lng;
    }
    if (
      updates.photos !== undefined &&
      updates.photos.join("|") !== beforeSummary.photos.join("|")
    ) {
      patch.photos = updates.photos;
    }
    if (
      updates.menuImages !== undefined &&
      updates.menuImages.join("|") !== beforeSummary.menu_images.join("|")
    ) {
      patch.menu_images = updates.menuImages;
    }

    if (Object.keys(patch).length === 1) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_already_in_target_state",
      );
    }

    const resultData = {
      action: envelope.action,
      venueId,
      status: "updated",
      auditEventId,
      replay: false,
    };

    transaction.set(venueRef, patch, { merge: true });
    transaction.set(auditRef, {
      category: "venue_ops",
      event_type: "venue_profile_updated",
      action: envelope.action,
      venue_id: venueId,
      reason: envelope.reason,
      before_summary: beforeSummary,
      command_id: envelope.commandId,
      correlation_id: envelope.correlationId,
      idempotency_key: envelope.idempotencyKey,
      expected_state: requiredExpectedState,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      submitted_at: envelope.submittedAt,
      timestamp: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });
    transaction.set(commandRef, {
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      target_type: "venue",
      target_id: venueId,
      payload_hash: payloadHash,
      payload_shape: payloadShape,
      result: resultData,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    return resultData;
  });

  return result;
});

export const adminUpdateVenueVisibility = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireVenueGovernanceAccess(context, "update_venue_visibility");
  const now = Timestamp.now();
  const envelope = normalizeVenueCommandEnvelope("update_venue_visibility", data, now);
  const requiredExpectedState = requireVenueExpectedState(envelope.expectedState);
  const venueId = normalizeVenueIdFromPayload(data);
  const payload = mediaRecordOrNull(data) ?? {};
  const newVisibility = requireVenueVisibilityStatus(payload.newVisibility);
  const venueRef = db.collection("venues").doc(venueId);
  const commandDocId = venueCommandDocId(envelope.action, venueId, envelope.commandId);
  const commandRef = db.collection(VENUE_ADMIN_COMMAND_COLLECTION).doc(commandDocId);
  const auditEventId = `venue_visibility_${commandDocId}`;
  const auditRef = db.collection(VENUE_ADMIN_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    venueId,
    newVisibility,
    expectedState: requiredExpectedState,
  };
  const payloadHash = hashVenuePayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, venueDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(venueRef),
    ]);
    const replay = readVenueCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    if (!venueDoc.exists) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }

    const row = venueDoc.data() ?? {};
    const currentVisibility = normalizeVenueVisibilityStatus(row.visibility_status);
    const currentOperationalStatus = normalizeVenueOperationalStatus(row.operational_status);
    const currentSubscriptionStatus = normalizeVenueSubscriptionStatus(row.subscription_status);
    const expectedVisibility = requireVenueVisibilityStatus(
      requiredExpectedState.current_visibility,
    );
    const expectedOperational = requireVenueOperationalStatus(
      requiredExpectedState.operational_status,
    );

    if (
      expectedVisibility !== currentVisibility ||
      expectedOperational !== currentOperationalStatus
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_expected_state_conflict",
      );
    }

    if (currentOperationalStatus !== "active") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_not_active",
      );
    }

    if (currentVisibility === newVisibility) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_already_in_target_state",
      );
    }

    if (newVisibility === "visible" && !workspaceString(row.phone)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "venue_phone_required_for_visibility",
      );
    }

    const nextIsActive = computeVenueIsActive(
      newVisibility,
      currentOperationalStatus,
      currentSubscriptionStatus,
    );
    const resultData = {
      action: envelope.action,
      venueId,
      newVisibility,
      status: "updated",
      auditEventId,
      replay: false,
    };

    transaction.set(venueRef, {
      visibility_status: newVisibility,
      is_active: nextIsActive,
      admin_status_updated_at: now,
      admin_status_updated_by: access.uid,
      updated_at: now,
    }, { merge: true });
    transaction.set(auditRef, {
      category: "venue_ops",
      event_type: "venue_visibility_changed",
      action: envelope.action,
      venue_id: venueId,
      previous_visibility: currentVisibility,
      visibility_status: newVisibility,
      is_active: nextIsActive,
      reason: envelope.reason,
      command_id: envelope.commandId,
      correlation_id: envelope.correlationId,
      idempotency_key: envelope.idempotencyKey,
      expected_state: requiredExpectedState,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      submitted_at: envelope.submittedAt,
      timestamp: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });
    transaction.set(commandRef, {
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      target_type: "venue",
      target_id: venueId,
      payload_hash: payloadHash,
      payload_shape: payloadShape,
      result: resultData,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    return resultData;
  });

  return result;
});

export const adminUpdateVenueOperationalStatus = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireVenueGovernanceAccess(context, "update_venue_operational_status");
  const now = Timestamp.now();
  const envelope = normalizeVenueCommandEnvelope("update_venue_operational_status", data, now);
  const requiredExpectedState = requireVenueExpectedState(envelope.expectedState);
  const venueId = normalizeVenueIdFromPayload(data);
  const payload = mediaRecordOrNull(data) ?? {};
  const newStatus = requireVenueOperationalStatus(payload.newStatus);
  const venueRef = db.collection("venues").doc(venueId);
  const commandDocId = venueCommandDocId(envelope.action, venueId, envelope.commandId);
  const commandRef = db.collection(VENUE_ADMIN_COMMAND_COLLECTION).doc(commandDocId);
  const auditEventId = `venue_operational_${commandDocId}`;
  const auditRef = db.collection(VENUE_ADMIN_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    venueId,
    newStatus,
    expectedState: requiredExpectedState,
  };
  const payloadHash = hashVenuePayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, venueDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(venueRef),
    ]);
    const replay = readVenueCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    if (!venueDoc.exists) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }

    const row = venueDoc.data() ?? {};
    const currentStatus = normalizeVenueOperationalStatus(row.operational_status);
    const expectedCurrentStatus = requireVenueOperationalStatus(
      requiredExpectedState.current_operational_status,
    );
    if (expectedCurrentStatus !== currentStatus) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_expected_state_conflict",
      );
    }
    if (currentStatus === newStatus) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_already_in_target_state",
      );
    }

    const currentVisibility = normalizeVenueVisibilityStatus(row.visibility_status);
    const currentSubscriptionStatus = normalizeVenueSubscriptionStatus(row.subscription_status);
    const nextVisibility = newStatus === "active" ? currentVisibility : "hidden";
    const nextIsActive = computeVenueIsActive(
      nextVisibility,
      newStatus,
      currentSubscriptionStatus,
    );
    const resultData = {
      action: envelope.action,
      venueId,
      newStatus,
      status: "updated",
      auditEventId,
      replay: false,
    };

    transaction.set(venueRef, {
      operational_status: newStatus,
      visibility_status: nextVisibility,
      is_active: nextIsActive,
      admin_status_updated_at: now,
      admin_status_updated_by: access.uid,
      updated_at: now,
    }, { merge: true });
    transaction.set(auditRef, {
      category: "venue_ops",
      event_type: "venue_operational_status_changed",
      action: envelope.action,
      venue_id: venueId,
      previous_operational_status: currentStatus,
      operational_status: newStatus,
      visibility_status: nextVisibility,
      is_active: nextIsActive,
      reason: envelope.reason,
      command_id: envelope.commandId,
      correlation_id: envelope.correlationId,
      idempotency_key: envelope.idempotencyKey,
      expected_state: requiredExpectedState,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      submitted_at: envelope.submittedAt,
      timestamp: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });
    transaction.set(commandRef, {
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      target_type: "venue",
      target_id: venueId,
      payload_hash: payloadHash,
      payload_shape: payloadShape,
      result: resultData,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    return resultData;
  });

  return result;
});

export const adminUpdateVenueSubscriptionStatus = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);
  const access = await requireVenueGovernanceAccess(context, "update_venue_subscription_status");
  const now = Timestamp.now();
  const envelope = normalizeVenueCommandEnvelope("update_venue_subscription_status", data, now);
  const requiredExpectedState = requireVenueExpectedState(envelope.expectedState);
  const venueId = normalizeVenueIdFromPayload(data);
  const payload = mediaRecordOrNull(data) ?? {};
  const newStatus = requireVenueSubscriptionStatus(payload.newStatus);
  const venueRef = db.collection("venues").doc(venueId);
  const commandDocId = venueCommandDocId(envelope.action, venueId, envelope.commandId);
  const commandRef = db.collection(VENUE_ADMIN_COMMAND_COLLECTION).doc(commandDocId);
  const auditEventId = `venue_subscription_${commandDocId}`;
  const auditRef = db.collection(VENUE_ADMIN_AUDIT_COLLECTION).doc(auditEventId);
  const payloadShape = {
    action: envelope.action,
    commandId: envelope.commandId,
    idempotencyKey: envelope.idempotencyKey,
    reason: envelope.reason,
    venueId,
    newStatus,
    expectedState: requiredExpectedState,
  };
  const payloadHash = hashVenuePayload(payloadShape);

  const result = await db.runTransaction(async (transaction) => {
    const [commandDoc, venueDoc] = await Promise.all([
      transaction.get(commandRef),
      transaction.get(venueRef),
    ]);
    const replay = readVenueCommandReplayResult(commandDoc, payloadHash);
    if (replay) {
      return replay;
    }

    if (!venueDoc.exists) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }

    const row = venueDoc.data() ?? {};
    const currentStatus = normalizeVenueSubscriptionStatus(row.subscription_status);
    const expectedCurrentStatus = requireVenueSubscriptionStatus(
      requiredExpectedState.current_subscription_status,
    );
    if (expectedCurrentStatus !== currentStatus) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_expected_state_conflict",
      );
    }
    if (currentStatus === newStatus) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_already_in_target_state",
      );
    }

    const currentVisibility = normalizeVenueVisibilityStatus(row.visibility_status);
    const currentOperationalStatus = normalizeVenueOperationalStatus(row.operational_status);
    const nextIsActive = computeVenueIsActive(
      currentVisibility,
      currentOperationalStatus,
      newStatus,
    );
    const resultData = {
      action: envelope.action,
      venueId,
      newStatus,
      status: "updated",
      auditEventId,
      replay: false,
    };

    transaction.set(venueRef, {
      subscription_status: newStatus,
      is_active: nextIsActive,
      admin_status_updated_at: now,
      admin_status_updated_by: access.uid,
      updated_at: now,
    }, { merge: true });
    transaction.set(auditRef, {
      category: "venue_ops",
      event_type: "venue_subscription_status_changed",
      action: envelope.action,
      venue_id: venueId,
      previous_subscription_status: currentStatus,
      subscription_status: newStatus,
      is_active: nextIsActive,
      reason: envelope.reason,
      command_id: envelope.commandId,
      correlation_id: envelope.correlationId,
      idempotency_key: envelope.idempotencyKey,
      expected_state: requiredExpectedState,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      submitted_at: envelope.submittedAt,
      timestamp: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });
    transaction.set(commandRef, {
      command_id: envelope.commandId,
      action: envelope.action,
      idempotency_key: envelope.idempotencyKey,
      correlation_id: envelope.correlationId,
      actor_uid: access.uid,
      actor_role: access.role,
      auth_source: access.source,
      target_type: "venue",
      target_id: venueId,
      payload_hash: payloadHash,
      payload_shape: payloadShape,
      result: resultData,
      executed_at: now,
      created_at: now,
      updated_at: now,
    }, { merge: true });

    return resultData;
  });

  return result;
});
async function requireVenueGovernanceAccess(
  context: functions.https.CallableContext,
  action: VenueAdminCommandAction,
): Promise<{
  uid: string;
  source: "claim" | "document";
  role: VenueGovernanceRole;
}> {
  const baseAccess = await requireAdminAccess(context);
  const role = resolveVenueGovernanceRole(context);
  if (!role) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "venue_role_not_authorized",
    );
  }

  if (
    (action === "create_venue" ||
      action === "update_venue_operational_status" ||
      action === "update_venue_subscription_status") &&
    role !== "super_admin"
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "venue_role_not_authorized",
    );
  }

  return { ...baseAccess, role };
}

function normalizeVenueCommandEnvelope(
  action: VenueAdminCommandAction,
  data: unknown,
  now: Timestamp,
): VenueCommandEnvelope {
  const payload = mediaRecordOrNull(data) ?? {};
  const providedAction = workspaceString(payload.action).toLowerCase();
  if (providedAction && providedAction !== action) {
    throw new functions.https.HttpsError("invalid-argument", "venue_action_mismatch");
  }

  const commandId = workspaceString(payload.commandId);
  if (!commandId || commandId.length < 5 || commandId.length > 100) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_command_id");
  }

  const reason = workspaceString(payload.reason);
  if (!reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing_required_venue_fields",
    );
  }

  return {
    action,
    commandId,
    correlationId: workspaceString(payload.correlationId) || null,
    idempotencyKey: workspaceString(payload.idempotencyKey) || commandId,
    reason,
    submittedAt: normalizeMediaIsoTimestamp(payload.submittedAt, now),
    expectedState: mediaRecordOrNull(payload.expectedState),
  };
}

function requireVenueExpectedState(
  expectedState: Record<string, unknown> | null,
): Record<string, unknown> {
  if (!expectedState) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "venue_expected_state_required",
    );
  }

  return expectedState;
}

function parseVenueSubscriptionStatus(
  value: unknown,
): VenueSubscriptionStatus | null {
  const normalized = workspaceString(value).toLowerCase();
  if (normalized === "active" || normalized === "expired" || normalized === "paused") {
    return normalized;
  }

  return null;
}

function requireVenueSubscriptionStatus(value: unknown): VenueSubscriptionStatus {
  const normalized = parseVenueSubscriptionStatus(value);
  if (!normalized) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_venue_subscription_status",
    );
  }

  return normalized;
}

function parseVenueVisibilityStatus(value: unknown): VenueVisibilityStatus | null {
  const normalized = workspaceString(value).toLowerCase();
  if (normalized === "visible" || normalized === "hidden") {
    return normalized;
  }

  return null;
}

function requireVenueVisibilityStatus(value: unknown): VenueVisibilityStatus {
  const normalized = parseVenueVisibilityStatus(value);
  if (!normalized) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_venue_visibility_status",
    );
  }

  return normalized;
}

function parseVenueOperationalStatus(value: unknown): VenueOperationalStatus | null {
  const normalized = workspaceString(value).toLowerCase();
  if (
    normalized === "active" ||
    normalized === "suspended" ||
    normalized === "archived"
  ) {
    return normalized;
  }

  return null;
}

function requireVenueOperationalStatus(value: unknown): VenueOperationalStatus {
  const normalized = parseVenueOperationalStatus(value);
  if (!normalized) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_venue_operational_status",
    );
  }

  return normalized;
}

function normalizeVenueSubscriptionStatus(value: unknown): VenueSubscriptionStatus {
  return parseVenueSubscriptionStatus(value) ?? "active";
}

function normalizeVenueVisibilityStatus(value: unknown): VenueVisibilityStatus {
  return parseVenueVisibilityStatus(value) ?? "visible";
}

function normalizeVenueOperationalStatus(value: unknown): VenueOperationalStatus {
  return parseVenueOperationalStatus(value) ?? "active";
}

function normalizeVenueCategories(value: unknown): string[] {
  return Array.from(
    new Set(
      workspaceStringArray(value).filter((entry) => entry.length > 0),
    ),
  );
}

const VENUE_HOURS_DAY_KEYS = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
] as const;

type VenueHoursDayKey = (typeof VENUE_HOURS_DAY_KEYS)[number];

type VenueCreateHoursSlot = {
  open: string;
  close: string;
  spans_midnight: boolean;
};

type VenueCreateHoursMap = Partial<Record<VenueHoursDayKey, VenueCreateHoursSlot[]>>;

type VenueCreateTagsMap = {
  mood: string[];
  occasion: string[];
  time_of_day: string[];
  meal: string[];
};

function normalizeVenueStringList(value: unknown): string[] {
  return Array.from(
    new Set(
      workspaceStringArray(value).filter((entry) => entry.length > 0),
    ),
  );
}

function parseVenueOptionalNonNegativeNumber(
  value: unknown,
  errorCode: string,
): number | null {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === "string" && value.trim().length === 0) {
    return null;
  }

  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new functions.https.HttpsError("invalid-argument", errorCode);
  }

  return Math.floor(parsed);
}

function normalizeVenueCurrency(value: unknown): "ILS" | "USD" {
  return workspaceString(value).toUpperCase() === "USD" ? "USD" : "ILS";
}

function parseVenueTimeToMinutes(
  value: string,
  options: { allow24Hour?: boolean } = {},
): number | null {
  const match = /^(\d{2}):(\d{2})$/.exec(value.trim());
  if (!match) {
    return null;
  }

  const hour = Number.parseInt(match[1], 10);
  const minute = Number.parseInt(match[2], 10);
  if (Number.isNaN(hour) || Number.isNaN(minute)) {
    return null;
  }

  if (options.allow24Hour && hour === 24 && minute === 0) {
    return 1440;
  }

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }

  return hour * 60 + minute;
}

function formatVenueTime(minutes: number): string {
  if (minutes === 1440) {
    return "24:00";
  }

  const hour = Math.floor(minutes / 60);
  const minute = minutes % 60;
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function normalizeVenueHoursInput(value: unknown): VenueCreateHoursMap {
  const hoursRecord = mediaRecordOrNull(value);
  if (!hoursRecord) {
    return {};
  }

  const normalized: VenueCreateHoursMap = {};
  const allowedDays = new Set(VENUE_HOURS_DAY_KEYS);

  for (const [dayKey, dayValue] of Object.entries(hoursRecord)) {
    if (!allowedDays.has(dayKey as VenueHoursDayKey)) {
      throw new functions.https.HttpsError("invalid-argument", "invalid_venue_hours");
    }

    if (!Array.isArray(dayValue)) {
      throw new functions.https.HttpsError("invalid-argument", "invalid_venue_hours");
    }

    const slots = dayValue.map((entry) => {
      const row = mediaRecordOrNull(entry);
      if (!row) {
        throw new functions.https.HttpsError("invalid-argument", "invalid_venue_hours");
      }

      const openValue = workspaceString(row.open);
      const closeValue = workspaceString(row.close);
      const openMinutes = parseVenueTimeToMinutes(openValue);
      const closeMinutes = parseVenueTimeToMinutes(closeValue, {
        allow24Hour: true,
      });

      if (
        openMinutes === null ||
        closeMinutes === null ||
        openMinutes === closeMinutes
      ) {
        throw new functions.https.HttpsError("invalid-argument", "invalid_venue_hours");
      }

      const explicitOvernight = row.spans_midnight === true || row.spansMidnight === true;

      return {
        open: formatVenueTime(openMinutes),
        close: formatVenueTime(closeMinutes),
        spans_midnight: explicitOvernight || closeMinutes < openMinutes,
      };
    });

    normalized[dayKey as VenueHoursDayKey] = slots;
  }

  return normalized;
}

function normalizeVenueTagsInput(value: unknown): VenueCreateTagsMap {
  const tagsRecord = mediaRecordOrNull(value) ?? {};

  return {
    mood: normalizeVenueStringList(tagsRecord.mood),
    occasion: normalizeVenueStringList(tagsRecord.occasion),
    time_of_day: normalizeVenueStringList(
      tagsRecord.time_of_day ?? tagsRecord.timeOfDay,
    ),
    meal: normalizeVenueStringList(tagsRecord.meal),
  };
}

function buildVenueAllTags(tags: VenueCreateTagsMap): string[] {
  return Array.from(
    new Set([
      ...tags.mood,
      ...tags.occasion,
      ...tags.time_of_day,
      ...tags.meal,
    ]),
  );
}

function hasVenueCoordinateValue(value: unknown): boolean {
  if (value === null || value === undefined) {
    return false;
  }

  if (typeof value === "string") {
    return value.trim().length > 0;
  }

  return true;
}

function parseVenueCoordinateValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const trimmed = value.trim();
    if (!trimmed) {
      return null;
    }
    const parsed = Number(trimmed);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return null;
}

function requireVenueLatLngPair(latValue: unknown, lngValue: unknown): {
  lat: number;
  lng: number;
} {
  const lat = parseVenueCoordinateValue(latValue);
  const lng = parseVenueCoordinateValue(lngValue);

  if (
    lat === null ||
    lng === null ||
    lat < -90 ||
    lat > 90 ||
    lng < -180 ||
    lng > 180
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_venue_coordinates",
    );
  }

  return { lat, lng };
}

function normalizeVenueCreateInput(data: unknown): {
  nameAr: string;
  nameEn: string;
  city: string;
  cityKey: string;
  phone: string;
  categories: string[];
  lat: number;
  lng: number;
  instagram: string;
  whatsapp: string;
  facebook: string;
  website: string;
  minPrice: number;
  maxPrice: number;
  currency: "ILS" | "USD";
  photos: string[];
  menuImages: string[];
  hours: VenueCreateHoursMap;
  is24h: boolean;
  tags: VenueCreateTagsMap;
  allTags: string[];
  transportEnabled: boolean;
  transportPartnerIds: string[];
  transportNotesAr: string;
  transportNotesEn: string;
} {
  const payload = mediaRecordOrNull(data) ?? {};
  const nameAr = workspaceString(payload.nameAr ?? payload.name_ar);
  const nameEn = workspaceString(payload.nameEn ?? payload.name_en);
  const city = workspaceString(payload.city);
  const cityKey = normalizeVenueCityKey(city);
  const phone = workspaceString(payload.phone);
  const instagram = workspaceString(payload.instagram);
  const whatsapp = workspaceString(payload.whatsapp);
  const facebook = workspaceString(payload.facebook);
  const website = workspaceString(payload.website);
  const categories = normalizeVenueCategories(payload.categories);
  const photos = normalizeVenueStringList(payload.photos);
  const menuImages = normalizeVenueStringList(
    payload.menuImages ?? payload.menu_images,
  );
  const tags = normalizeVenueTagsInput(payload.tags);
  const allTags = buildVenueAllTags(tags);
  const is24h = payload.is24h === true || payload.is_24h === true;
  const hours = is24h ? {} : normalizeVenueHoursInput(payload.hours);

  const rawMinPrice = parseVenueOptionalNonNegativeNumber(
    payload.minPrice ?? payload.min_price,
    "invalid_venue_price",
  );
  const rawMaxPrice = parseVenueOptionalNonNegativeNumber(
    payload.maxPrice ?? payload.max_price,
    "invalid_venue_price",
  );
  let minPrice = 0;
  let maxPrice = 0;

  if (rawMinPrice === null && rawMaxPrice === null) {
    minPrice = 0;
    maxPrice = 0;
  } else if (
    rawMinPrice === null ||
    rawMaxPrice === null ||
    rawMaxPrice < rawMinPrice
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_venue_price_range",
    );
  } else {
    minPrice = rawMinPrice;
    maxPrice = rawMaxPrice;
  }

  const currency = normalizeVenueCurrency(payload.currency);
  const transportEnabled =
    payload.transportEnabled === true || payload.transport_enabled === true;
  const transportPartnerIds = transportEnabled
    ? normalizeVenueStringList(
      payload.transportPartnerIds ?? payload.transport_partner_ids,
    )
    : [];
  const transportNotesAr = transportEnabled
    ? workspaceString(payload.transportNotesAr ?? payload.transport_notes_ar)
    : "";
  const transportNotesEn = transportEnabled
    ? workspaceString(payload.transportNotesEn ?? payload.transport_notes_en)
    : "";

  const hasLat = hasVenueCoordinateValue(payload.lat);
  const hasLng = hasVenueCoordinateValue(payload.lng);

  if (!hasLat || !hasLng) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid_venue_coordinates",
    );
  }

  const coordinates = requireVenueLatLngPair(payload.lat, payload.lng);

  if (!nameAr || !city || categories.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing_required_venue_fields",
    );
  }

  return {
    nameAr,
    nameEn,
    city,
    cityKey,
    phone,
    categories,
    ...coordinates,
    instagram,
    whatsapp,
    facebook,
    website,
    minPrice,
    maxPrice,
    currency,
    photos,
    menuImages,
    hours,
    is24h,
    tags,
    allTags,
    transportEnabled,
    transportPartnerIds,
    transportNotesAr,
    transportNotesEn,
  };
}

function normalizeVenueProfileUpdates(data: unknown): {
  nameAr?: string;
  nameEn?: string;
  city?: string;
  phone?: string;
  categories?: string[];
  lat?: number;
  lng?: number;
  photos?: string[];
  menuImages?: string[];
} {
  const payload = mediaRecordOrNull(data) ?? {};
  const rawUpdates = mediaRecordOrNull(payload.updates) ?? {};
  const updates: {
    nameAr?: string;
    nameEn?: string;
    city?: string;
    phone?: string;
    categories?: string[];
    lat?: number;
    lng?: number;
    photos?: string[];
    menuImages?: string[];
  } = {};

  if ("nameAr" in rawUpdates || "name_ar" in rawUpdates) {
    const nameAr = workspaceString(rawUpdates.nameAr ?? rawUpdates.name_ar);
    if (!nameAr) {
      throw new functions.https.HttpsError("invalid-argument", "missing_required_venue_fields");
    }
    updates.nameAr = nameAr;
  }

  if ("nameEn" in rawUpdates || "name_en" in rawUpdates) {
    updates.nameEn = workspaceString(rawUpdates.nameEn ?? rawUpdates.name_en);
  }

  if ("city" in rawUpdates) {
    const city = workspaceString(rawUpdates.city);
    if (!city) {
      throw new functions.https.HttpsError("invalid-argument", "missing_required_venue_fields");
    }
    updates.city = city;
  }

  if ("phone" in rawUpdates) {
    updates.phone = workspaceString(rawUpdates.phone);
  }

  if ("categories" in rawUpdates) {
    const categories = normalizeVenueCategories(rawUpdates.categories);
    if (categories.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "missing_required_venue_fields");
    }
    updates.categories = categories;
  }

  const hasLatUpdate = "lat" in rawUpdates;
  const hasLngUpdate = "lng" in rawUpdates;
  if (hasLatUpdate || hasLngUpdate) {
    if (!hasLatUpdate || !hasLngUpdate) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid_venue_coordinates",
      );
    }

    const coordinates = requireVenueLatLngPair(rawUpdates.lat, rawUpdates.lng);
    updates.lat = coordinates.lat;
    updates.lng = coordinates.lng;
  }

  if ("photos" in rawUpdates) {
    updates.photos = normalizeVenueStringList(rawUpdates.photos);
  }

  if ("menuImages" in rawUpdates || "menu_images" in rawUpdates) {
    updates.menuImages = normalizeVenueStringList(
      rawUpdates.menuImages ?? rawUpdates.menu_images,
    );
  }

  if (Object.keys(updates).length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "missing_required_venue_fields");
  }

  return updates;
}

function normalizeVenueIdFromPayload(data: unknown): string {
  const payload = mediaRecordOrNull(data) ?? {};
  const venueId = workspaceString(payload.venueId);
  if (!venueId) {
    throw new functions.https.HttpsError("invalid-argument", "venue_id_required");
  }
  return venueId;
}

function computeVenueIsActive(
  visibilityStatus: VenueVisibilityStatus,
  operationalStatus: VenueOperationalStatus,
  subscriptionStatus: VenueSubscriptionStatus,
): boolean {
  return (
    visibilityStatus === "visible" &&
    operationalStatus === "active" &&
    subscriptionStatus === "active"
  );
}

function buildVenueNameNorm(value: string): string {
  return value.trim().toLowerCase();
}

const VENUE_CITY_KEY_ALIASES: Record<string, string[]> = {
  ramallah: ["ramallah", "رام الله", "رامالله"],
  jerusalem: ["jerusalem", "القدس"],
  nablus: ["nablus", "نابلس"],
  bethlehem: ["bethlehem", "بيت لحم", "بيتلحم"],
};

function normalizeVenueCityKey(value: unknown): string {
  const normalized = workspaceString(value).toLowerCase().trim();
  if (!normalized) {
    return "";
  }

  const compact = normalized.replace(/\s+/g, "");
  for (const [cityKey, aliases] of Object.entries(VENUE_CITY_KEY_ALIASES)) {
    for (const alias of aliases) {
      const normalizedAlias = alias.toLowerCase().trim();
      const compactAlias = normalizedAlias.replace(/\s+/g, "");
      if (normalized === normalizedAlias || compact === compactAlias) {
        return cityKey;
      }
    }
  }

  return normalized.replace(/\s+/g, "_");
}

function venueCommandDocId(
  action: VenueAdminCommandAction,
  venueId: string,
  commandId: string,
): string {
  return crypto
    .createHash("sha1")
    .update(`${action}|${venueId}|${commandId}`)
    .digest("hex");
}

function sortObjectForVenueHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => sortObjectForVenueHash(entry));
  }

  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(record).sort()) {
      sorted[key] = sortObjectForVenueHash(record[key]);
    }
    return sorted;
  }

  return value;
}

function hashVenuePayload(payload: Record<string, unknown>): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(sortObjectForVenueHash(payload)))
    .digest("hex");
}

function readVenueCommandReplayResult(
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
      "venue_command_payload_conflict",
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

function buildVenueCreateDocument(
  input: ReturnType<typeof normalizeVenueCreateInput>,
  adminUid: string,
  now: Timestamp,
) {
  return {
    name_ar: input.nameAr,
    name_en: input.nameEn,
    name: input.nameAr,
    name_ar_norm: buildVenueNameNorm(input.nameAr),
    name_en_norm: buildVenueNameNorm(input.nameEn),
    lat: input.lat,
    lng: input.lng,
    city: input.city,
    city_key: input.cityKey,
    categories: input.categories,
    tags: input.tags,
    all_tags: input.allTags,
    min_price: input.minPrice,
    max_price: input.maxPrice,
    currency: input.currency,
    rating: 0,
    phone: input.phone,
    instagram: input.instagram,
    whatsapp: input.whatsapp,
    facebook: input.facebook,
    website: input.website,
    photos: input.photos,
    menu_images: input.menuImages,
    hours: input.hours,
    is_24h: input.is24h,
    partner: {
      is_partner: false,
      tier: "C",
    },
    has_active_offers: false,
    transport_enabled: input.transportEnabled,
    transport_partner_ids: input.transportPartnerIds,
    transport_notes_ar: input.transportNotesAr,
    transport_notes_en: input.transportNotesEn,
    is_active: true,
    subscription_status: "active",
    visibility_status: "visible",
    operational_status: "active",
    admin_status_updated_at: now,
    admin_status_updated_by: adminUid,
    created_at: now,
    updated_at: now,
  };
}

function chunkVenueIds(values: string[], size: number): string[][] {
  const normalizedSize = Math.max(1, Math.floor(size));
  const chunks: string[][] = [];

  for (let index = 0; index < values.length; index += normalizedSize) {
    chunks.push(values.slice(index, index + normalizedSize));
  }

  return chunks;
}

async function loadMerchantCountsByVenueId(
  venueIds: string[],
): Promise<Map<string, number>> {
  const counts = new Map<string, number>();

  for (const venueId of venueIds) {
    counts.set(venueId, 0);
  }

  for (const chunk of chunkVenueIds(venueIds, 10)) {
    const merchantSnap = await db.collection("merchants")
      .where("venue_id", "in", chunk)
      .get();

    for (const doc of merchantSnap.docs) {
      const venueId = workspaceString(doc.data()?.venue_id);
      if (!venueId) {
        continue;
      }
      counts.set(venueId, (counts.get(venueId) ?? 0) + 1);
    }
  }

  return counts;
}

type VenueAdminCommandAction =
  | "create_venue"
  | "update_venue_profile"
  | "update_venue_visibility"
  | "update_venue_operational_status"
  | "update_venue_subscription_status";

type VenueGovernanceRole = "super_admin" | "content_admin";
type VenueSubscriptionStatus = "active" | "expired" | "paused";
type VenueVisibilityStatus = "visible" | "hidden";
type VenueOperationalStatus = "active" | "suspended" | "archived";

type VenueCommandEnvelope = {
  action: VenueAdminCommandAction;
  commandId: string;
  correlationId: string | null;
  idempotencyKey: string;
  reason: string;
  submittedAt: string;
  expectedState: Record<string, unknown> | null;
};

function resolveVenueGovernanceRole(
  context: functions.https.CallableContext,
): VenueGovernanceRole | null {
  const token = (context.auth?.token ?? {}) as Record<string, unknown>;
  if (token.super_admin === true || token.role === "super_admin") {
    return "super_admin";
  }
  if (token.content_admin === true || token.role === "content_admin") {
    return "content_admin";
  }
  if (isEmulatorOwnerToken(context)) {
    return "super_admin";
  }
  return null;
}
