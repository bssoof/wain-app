import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as crypto from "crypto";

import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { db } from "./shared/firestore-db";

const TRACKABLE_EVENT_TYPES = new Set([
  "view",
  "call",
  "story_view",
  "nav_click",
  "offer_detail_view",
  "offer_claim_click",
]);

const LEGACY_TRACKABLE_EVENT_ALIASES: Record<string, string> = {
  venue_view: "view",
  whatsapp: "call",
  whatsapp_click: "call",
  call_click: "call",
  phone_call: "call",
  story: "story_view",
  storyview: "story_view",
  navigation_click: "nav_click",
  offer_view: "offer_detail_view",
};

function normalizeTrackableEventType(value: unknown): string {
  if (typeof value !== "string") return "";
  const normalized = value.trim().toLowerCase();
  if (!normalized) return "";
  return LEGACY_TRACKABLE_EVENT_ALIASES[normalized] ?? normalized;
}

// Track venue-level interaction events for merchant analytics.
// Input: venueId, eventType, source, optional deviceId/offerId/navApp
export const trackVenueEvent = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);

  const venueId = typeof data?.venueId === "string" ? data.venueId.trim() : "";
  const rawEventType = typeof data?.eventType === "string" ? data.eventType.trim() : "";
  const eventType = normalizeTrackableEventType(rawEventType);
  const source = typeof data?.source === "string" ? data.source.trim() : "unknown";
  const deviceId = typeof data?.deviceId === "string" ? data.deviceId.trim() : null;
  const offerId = typeof data?.offerId === "string" ? data.offerId.trim() : "";
  const navApp = typeof data?.navApp === "string" ? data.navApp.trim() : "";

  if (!venueId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId is required");
  }
  if (!TRACKABLE_EVENT_TYPES.has(eventType)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid eventType");
  }
  if ((eventType === "offer_detail_view" || eventType === "offer_claim_click") && !offerId) {
    console.warn(JSON.stringify({
      event: "trackVenueEvent_missing_offer_id",
      venueId,
      eventType,
      rawEventType,
      source,
    }));
  }
  if (eventType === "nav_click" && !navApp) {
    console.warn(JSON.stringify({
      event: "trackVenueEvent_missing_nav_app",
      venueId,
      eventType,
      rawEventType,
      source,
    }));
  }

  const eventData: Record<string, unknown> = {
    venue_id: venueId,
    event_type: eventType,
    event_type_raw: rawEventType || null,
    source: source || "unknown",
    created_at: FieldValue.serverTimestamp(),
  };
  if (deviceId) {
    eventData.device_id = deviceId;
  }
  if (offerId) {
    eventData.offer_id = offerId;
  }
  if (navApp) {
    eventData.nav_app = navApp;
  }

  await db.collection("venue_events").add(eventData);

  return { success: true };
});

function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const earthRadiusKm = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

// Search venues by viewport bounds with bounded window size and basic per-device throttling.
export const searchVenuesInBounds = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);

  const { minLat, maxLat, minLng, maxLng, startAfter } = data;
  const limit = Math.min(data.limit || 50, 100);

  if (!minLat || !maxLat || !minLng || !maxLng) {
    throw new functions.https.HttpsError("invalid-argument", "Missing bounds");
  }

  const diagonalKm = calculateDistance(minLat, minLng, maxLat, maxLng);
  if (diagonalKm > 20.0) {
    throw new functions.https.HttpsError("out-of-range", "bounds_too_large");
  }

  const documentIdOrderField =
    typeof (admin.firestore as any)?.FieldPath?.documentId === "function"
      ? (admin.firestore as any).FieldPath.documentId()
      : "__name__";

  let query = db.collection("venues")
    .orderBy("lat")
    .orderBy(documentIdOrderField)
    .where("lat", ">=", minLat)
    .where("lat", "<=", maxLat);

  const deviceId = data.deviceId || "unknown";
  const nowMin = Math.floor(Date.now() / 60000);
  const rateRef = db.collection("rate_limits").doc(`${nowMin}_${deviceId}`);

  try {
    await db.runTransaction(async (t) => {
      const doc = await t.get(rateRef);
      const count = doc.exists ? doc.data()?.count || 0 : 0;
      if (count > 20) {
        throw new functions.https.HttpsError("resource-exhausted", "Rate limit exceeded");
      }
      t.set(rateRef, { count: count + 1 }, { merge: true });
    });
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.warn("Rate limit check failed, proceeding:", error);
  }

  if (startAfter) {
    const startDoc = await db.collection("venues").doc(startAfter).get();
    if (startDoc.exists) {
      query = query.startAfter(startDoc);
    }
  }

  const snapshot = await query.limit(200).get();
  const venues: any[] = [];

  for (const doc of snapshot.docs) {
    const d = doc.data();
    if (d.lng >= minLng && d.lng <= maxLng) {
      if (venues.length < limit) {
        venues.push({
          id: doc.id,
          ...d,
          created_at: d.created_at?.toMillis ? d.created_at.toMillis() : null,
        });
      } else {
        break;
      }
    }
  }

  const nextCursor = venues.length > 0
    ? venues[venues.length - 1].id
    : null;

  return { venues, nextCursor };
});

// Helper: Hashing function
function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function toInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  return 0;
}

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

function getOfferAvailabilityState(
  offerData: FirebaseFirestore.DocumentData,
  now: Timestamp,
): "available" | "inactive" | "not_started" | "expired" {
  if (offerData.is_active === false) return "inactive";

  const startAt = offerData.start_at;
  if (startAt instanceof Timestamp &&
      startAt.toMillis() > now.toMillis()) {
    return "not_started";
  }

  const endAt = offerData.end_at;
  if (endAt instanceof Timestamp &&
      endAt.toMillis() <= now.toMillis()) {
    return "expired";
  }

  return "available";
}

// Helper: Send notification to merchant(s) of a venue
async function sendMerchantNotification(params: {
  venueId: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, any>;
}) {
  try {
    const merchantQuery = await db.collection("merchants")
      .where("venue_id", "==", params.venueId)
      .limit(3)
      .get();

    if (merchantQuery.empty) {
      console.log(`No merchant found for venue ${params.venueId}`);
      return;
    }

    for (const doc of merchantQuery.docs) {
      const merchantUid = doc.data().uid;
      if (!merchantUid) continue;

      await db.collection("users").doc(merchantUid)
        .collection("notifications").add({
          title: params.title,
          body: params.body,
          type: params.type,
          data: params.data || {},
          is_read: false,
          created_at: FieldValue.serverTimestamp(),
        });

      console.log(`Notification sent to merchant ${merchantUid}: ${params.title}`);
    }
  } catch (error) {
    console.error("Error sending merchant notification:", error);
  }
}

// 1. Create Claim Token
// Input: offerId, venueId, city, source, deviceId
// Output: claimId, token, expiresAt
export const createClaimToken = functions.https.onCall(async (data, context) => {
  requireAppCheck(context);

  const offerId = typeof data?.offerId === "string" ? data.offerId.trim() : "";
  const requestedVenueId = typeof data?.venueId === "string" ? data.venueId.trim() : "";
  const city = typeof data?.city === "string" && data.city.trim().length > 0
    ? data.city.trim()
    : "unknown";
  const source = typeof data?.source === "string" && data.source.trim().length > 0
    ? data.source.trim()
    : "unknown";
  const deviceId = typeof data?.deviceId === "string" ? data.deviceId.trim() : "";

  if (!offerId || !deviceId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  const uid = context.auth?.uid;
  const now = Timestamp.now();
  const offerRef = db.collection("offers").doc(offerId);
  const token = crypto.randomBytes(16).toString("hex");
  const tokenHash = hashToken(token);
  const expiresAt = Timestamp.fromMillis(
    now.toMillis() + 10 * 60 * 1000,
  );

  const claimRef = db.collection("offer_claims").doc();
  let response:
    | {
      claimId: string;
      token: string;
      expiresAt: number;
    }
    | null = null;

  await db.runTransaction(async (t) => {
    const freshOfferDoc = await t.get(offerRef);
    if (!freshOfferDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Offer not found");
    }

    const freshOfferData = freshOfferDoc.data() ?? {};
    const freshOfferVenueId = typeof freshOfferData.venue_id === "string"
      ? freshOfferData.venue_id.trim()
      : "";
    if (!freshOfferVenueId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "offer_missing_venue",
      );
    }
    if (requestedVenueId && requestedVenueId !== freshOfferVenueId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "venue_mismatch",
      );
    }
    const availabilityState = getOfferAvailabilityState(freshOfferData, now);
    if (availabilityState !== "available") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `offer_${availabilityState}`,
      );
    }
    const singleUsePerCustomer = freshOfferData.single_use_per_customer !== false;
    const claimDocsById =
      new Map<string, FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>>();
    const expiredPendingRefs: FirebaseFirestore.DocumentReference[] = [];

    const deviceSnapshot = await t.get(
      db.collection("offer_claims")
        .where("offer_id", "==", offerId)
        .where("device_id", "==", deviceId),
    );
    for (const doc of deviceSnapshot.docs) {
      claimDocsById.set(doc.id, doc);
    }

    if (uid) {
      const userSnapshot = await t.get(
        db.collection("offer_claims")
          .where("offer_id", "==", offerId)
          .where("user_id", "==", uid),
      );
      for (const doc of userSnapshot.docs) {
        claimDocsById.set(doc.id, doc);
      }
    }

    for (const doc of claimDocsById.values()) {
      const claim = doc.data();

      if (claim.status === "redeemed" && singleUsePerCustomer) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "offer_already_used",
        );
      }

      if (claim.status === "pending") {
        const existingExpiresAt = claim.expires_at;
        if (existingExpiresAt instanceof Timestamp &&
            existingExpiresAt.toMillis() > now.toMillis() &&
            typeof claim.token === "string" &&
            claim.token.length > 0) {
          response = {
            claimId: doc.id,
            token: claim.token,
            expiresAt: existingExpiresAt.toMillis(),
          };
          return;
        }

        expiredPendingRefs.push(doc.ref);
      }
    }

    for (const expiredPendingRef of expiredPendingRefs) {
      t.delete(expiredPendingRef);
    }

    const currentClaims = toInt(freshOfferData.claims_count);
    const currentRedeemed = toInt(freshOfferData.redeemed_count);
    const nextClaims = currentClaims + 1;
    const nextConversion = currentClaims + 1 > 0 ? currentRedeemed / (currentClaims + 1) : 0;
    const claimData = {
      offer_id: offerId,
      venue_id: freshOfferVenueId,
      city,
      source,
      device_id: deviceId,
      user_id: uid || null,
      status: "pending",
      timestamp: now,
      created_at: now,
      expires_at: expiresAt,
      token,
      token_hash: tokenHash,
    };

    const claimCreatedEventRef = db.collection("venue_events")
      .doc(`offer_claim_created:${claimRef.id}`);

    t.set(claimRef, claimData);
    t.set(offerRef, {
      claims_count: nextClaims,
      conversion_rate: nextConversion,
      updated_at: now,
    }, { merge: true });
    t.set(claimCreatedEventRef, {
      venue_id: freshOfferVenueId,
      event_type: "offer_claim_created",
      offer_id: offerId,
      source,
      created_at: now,
    });

    response = {
      claimId: claimRef.id,
      token,
      expiresAt: expiresAt.toMillis(),
    };
  });

  return response!;
});

// 2. Validate Token (Merchant Only ideally, but open for scan preview)
// Input: token
// Output: status, offer details
export const validateToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Merchant login required");
  }
  requireAppCheck(context);

  const { token } = data;
  if (!token) {
    throw new functions.https.HttpsError("invalid-argument", "Missing token");
  }

  const tokenHash = hashToken(token);

  const snapshot = await db.collection("offer_claims")
    .where("token_hash", "==", tokenHash)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new functions.https.HttpsError("not-found", "Invalid token");
  }

  const claimDoc = snapshot.docs[0];
  const claim = claimDoc.data();

  const merchantRef = db.collection("merchants").doc(context.auth.uid);
  const merchantDoc = await merchantRef.get();

  if (!merchantDoc.exists) {
    throw new functions.https.HttpsError("permission-denied", "Not a registered merchant");
  }

  const merchantVenueId = merchantDoc.data()?.venue_id;
  if (merchantVenueId !== claim.venue_id) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "This offer belongs to a different venue",
    );
  }

  const now = Timestamp.now();
  if (claim.expires_at < now) {
    return {
      valid: false,
      reason: "expired",
      claimId: claimDoc.id,
      offerId: claim.offer_id,
    };
  }

  if (claim.status !== "pending") {
    return {
      valid: false,
      reason: "already_redeemed",
      claimId: claimDoc.id,
      offerId: claim.offer_id,
      redeemedAt: claim.redeemed_at?.toMillis(),
    };
  }

  const offerDoc = await db.collection("offers").doc(claim.offer_id).get();
  const venueDoc = await db.collection("venues").doc(claim.venue_id).get();
  const offerVenueId = typeof offerDoc.data()?.venue_id === "string"
    ? offerDoc.data()!.venue_id.trim()
    : "";
  if (offerDoc.exists && (!offerVenueId || offerVenueId !== claim.venue_id)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "claim_offer_venue_mismatch",
    );
  }
  if (venueDoc.data()?.is_active === false) {
    return {
      valid: false,
      reason: "venue_inactive",
      claimId: claimDoc.id,
      offerId: claim.offer_id,
    };
  }
  if (offerDoc.exists) {
    const offerState = getOfferAvailabilityState(
      offerDoc.data() ?? {},
      now,
    );
    if (offerState !== "available") {
      return {
        valid: false,
        reason: `offer_${offerState}`,
        claimId: claimDoc.id,
        offerId: claim.offer_id,
      };
    }
  }

  return {
    valid: true,
    claimId: claimDoc.id,
    offer: offerDoc.exists ? offerDoc.data() : null,
    venue: venueDoc.exists ? venueDoc.data() : null,
    canRedeem: true,
  };
});

// Input: token
// Security: Merchant Auth Required
export const redeemToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Merchant login required");
  }
  requireAppCheck(context);

  const MAX_BILL_AMOUNT = 100000;
  const { token } = data;
  const rawBillAmount = typeof data.billAmount === "number"
    ? data.billAmount
    : (typeof data.billAmount === "string" ? Number(data.billAmount) : null);
  const hasBillAmount = typeof rawBillAmount === "number" &&
    Number.isFinite(rawBillAmount) &&
    rawBillAmount > 0 &&
    rawBillAmount <= MAX_BILL_AMOUNT;
  if (data.billAmount != null && !hasBillAmount) {
    throw new functions.https.HttpsError("invalid-argument", "invalid_bill_amount");
  }
  const tokenHash = hashToken(token);

  const snapshot = await db.collection("offer_claims")
    .where("token_hash", "==", tokenHash)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new functions.https.HttpsError("not-found", "Invalid token");
  }

  const claimDoc = snapshot.docs[0];
  const claim = claimDoc.data();

  if (claim.status !== "pending") {
    throw new functions.https.HttpsError("failed-precondition", "Claim already processed");
  }

  const now = Timestamp.now();
  if (claim.expires_at < now) {
    throw new functions.https.HttpsError("failed-precondition", "Token expired");
  }

  const merchantRef = db.collection("merchants").doc(context.auth.uid);
  const merchantDoc = await merchantRef.get();
  if (!merchantDoc.exists) {
    throw new functions.https.HttpsError("permission-denied", "Not a registered merchant");
  }

  const merchantVenueId = merchantDoc.data()?.venue_id;
  if (merchantVenueId !== claim.venue_id) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not authorized to redeem offers for this venue",
    );
  }

  await db.runTransaction(async (t) => {
    const freshClaimDoc = await t.get(claimDoc.ref);
    const freshClaim = freshClaimDoc.data();
    if (!freshClaim || freshClaim.status !== "pending") {
      throw new functions.https.HttpsError("aborted", "Already redeemed");
    }

    const offerRef = db.collection("offers").doc(claim.offer_id);
    const offerDoc = await t.get(offerRef);
    if (!offerDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Offer not found");
    }

    const offerData = offerDoc.data() ?? {};
    const offerVenueId = typeof offerData.venue_id === "string"
      ? offerData.venue_id.trim()
      : "";
    if (!offerVenueId || offerVenueId !== claim.venue_id) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "claim_offer_venue_mismatch",
      );
    }
    const offerState = getOfferAvailabilityState(offerData, now);
    if (offerState !== "available") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `offer_${offerState}`,
      );
    }
    const venueRef = db.collection("venues").doc(claim.venue_id);
    const venueDoc = await t.get(venueRef);
    if (venueDoc.data()?.is_active === false) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "venue_inactive",
      );
    }
    const claimsCount = toInt(offerData.claims_count);
    const redeemedCount = toInt(offerData.redeemed_count);
    const nextRedeemed = redeemedCount + 1;
    const nextConversion = claimsCount > 0 ? nextRedeemed / claimsCount : 0;
    const discountType = typeof offerData.discount_type === "string" ? offerData.discount_type : "percent";
    const discountValue = typeof offerData.discount_value === "number"
      ? offerData.discount_value
      : Number(offerData.discount_value || 0);
    const currency = typeof offerData.currency === "string" && offerData.currency.trim().length > 0
      ? offerData.currency
      : "ILS";
    let appliedSavings = discountType === "amount" ? discountValue : null;
    let appliedBillAmount: number | null = null;
    let appliedFinalAmount: number | null = null;
    if (discountType === "percent" && hasBillAmount) {
      appliedBillAmount = roundMoney(rawBillAmount!);
      const rawSavings = (appliedBillAmount * discountValue) / 100;
      appliedSavings = roundMoney(Math.min(rawSavings, appliedBillAmount));
      appliedFinalAmount = roundMoney(
        Math.max(0, appliedBillAmount - appliedSavings),
      );
    }
    const offerTitleAr = typeof offerData.title_ar === "string" && offerData.title_ar.trim().length > 0
      ? offerData.title_ar
      : (typeof offerData.title === "string" ? offerData.title : null);

    const redeemEventRef = db.collection("venue_events")
      .doc(`offer_redeemed:${claimDoc.id}`);

    t.update(claimDoc.ref, {
      status: "redeemed",
      redeemed_at: now,
      merchant_id: context.auth!.uid,
      applied_discount_type: discountType,
      applied_discount_value: discountValue,
      applied_currency: currency,
      applied_savings: appliedSavings,
      applied_bill_amount: appliedBillAmount,
      applied_final_amount: appliedFinalAmount,
      applied_offer_title_ar: offerTitleAr,
    });

    const visitRef = db.collection("visits").doc();
    t.set(visitRef, {
      claim_id: claimDoc.id,
      offer_id: claim.offer_id,
      venue_id: claim.venue_id,
      merchant_id: context.auth!.uid,
      redeemed_at: now,
      device_id: claim.device_id,
      scanner_device_id: data.deviceId || "unknown",
    });

    t.set(offerRef, {
      redeemed_count: nextRedeemed,
      conversion_rate: nextConversion,
      last_redeemed_at: now,
      updated_at: now,
    }, { merge: true });

    t.set(redeemEventRef, {
      venue_id: claim.venue_id,
      event_type: "offer_redeemed",
      offer_id: claim.offer_id,
      source: "redeem_token",
      created_at: now,
    });
  });

  logSecurityAudit("redeemToken", {
    uid: context.auth.uid,
    claimId: claimDoc.id,
    offerId: claim.offer_id,
    venueId: claim.venue_id,
    timestamp: now.toMillis(),
    result: "redeemed",
  });

  try {
    const offerDoc = await db.collection("offers").doc(claim.offer_id).get();
    const offerTitle = offerDoc.data()?.title_ar || offerDoc.data()?.title || "عرض";
    await sendMerchantNotification({
      venueId: claim.venue_id,
      title: "تم استخدام عرض!",
      body: `تم استخدام عرض "${offerTitle}" الآن`,
      type: "offer_redeemed",
      data: { offer_id: claim.offer_id, claim_id: claimDoc.id },
    });
  } catch (e) {
    console.error("Notification error (non-critical):", e);
  }

  return { success: true };
});

// Maintain review counters and notify merchants on new reviews.
export const onReviewWrite = functions.firestore
  .document("venues/{venueId}/reviews/{reviewId}")
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    if (!before && after) {
      const uid = after.user_id;
      if (uid) {
        await db.collection("users").doc(uid).update({
          reviews_count: FieldValue.increment(1),
        }).catch((e) => console.log("Error incrementing review count:", e));
      }

      const venueId = context.params.venueId;
      const rating = after.rating || 0;
      const userName = after.user_name || "مستخدم";
      const stars = "★".repeat(Math.min(Math.round(rating), 5));

      await sendMerchantNotification({
        venueId,
        title: `${stars} تقييم جديد (${rating}/5)`,
        body: after.comment
          ? `${userName}: \"${String(after.comment).substring(0, 100)}\"`
          : `${userName} أعطاك تقييم ${rating} من 5`,
        type: "review",
        data: { venue_id: venueId, review_id: context.params.reviewId },
      });
    } else if (before && !after) {
      const uid = before.user_id;
      if (uid) {
        await db.collection("users").doc(uid).update({
          reviews_count: FieldValue.increment(-1),
        }).catch((e) => console.log("Error decrementing review count:", e));
      }
    }

    return null;
  });
// 7. Redeem Invite Code (Merchant Onboarding)
// Input: code
// Security: App Check + Auth Required + Rate Limit
export const redeemInviteCode = functions.https.onCall(async (data, context) => {
    // 1. Security Checks
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    requireAppCheck(context);

    const { code } = data;
    if (!code || typeof code !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "Invalid invite code");
    }
    const normalizedCode = code.trim().toUpperCase();
    if (!normalizedCode) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid invite code");
    }

    const uid = context.auth.uid;
    const now = Timestamp.now();

    // 2. Rate Limiting (5 attempts per hour per user)
    const rateLimitKey = `redeem_invite_${uid}_${Math.floor(Date.now() / 3600000)}`; // Hourly bucket
    const rateRef = db.collection("rate_limits").doc(rateLimitKey);

    await db.runTransaction(async (t) => {
        const doc = await t.get(rateRef);
        const count = doc.exists ? doc.data()?.count || 0 : 0;
        if (count >= 5) {
            throw new functions.https.HttpsError("resource-exhausted", "Too many attempts. Try again later.");
        }
        t.set(rateRef, { count: count + 1 }, { merge: true });
    });

    // 3. Redeem Transaction
    const userRef = db.collection("users").doc(uid);
    const merchantRef = db.collection("merchants").doc(uid);

    // We need to query for the invite code first (since DocID is random)
    // Query is not supported inside transaction directly for dynamic keys unless we read it first.
    // But we need the doc reference for the transaction.
    const inviteQuery = await db.collection("merchant_invites")
        .where("code", "==", normalizedCode)
        .limit(2) // Fetch 2 to detect duplicates
        .get();

    if (inviteQuery.empty) {
        throw new functions.https.HttpsError("not-found", "Invalid invite code");
    }

    // Safety Check: Ambiguous Code
    if (inviteQuery.size > 1) {
        throw new functions.https.HttpsError("aborted", "Ambiguous invite code. Please contact support.");
    }

    // Get the reference to standardise the transaction lock
    const inviteRef = inviteQuery.docs[0].ref;
    const result = await db.runTransaction(async (t) => {
        // A. Lock & Validate Invite
        const inviteDoc = await t.get(inviteRef);
        if (!inviteDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Invalid invite code (intermittent)");
        }

        const invite = inviteDoc.data()!;

        if (invite.status !== 'active') {
            throw new functions.https.HttpsError("failed-precondition", "Invite code already used or inactive");
        }
        if (invite.used_by) {
             throw new functions.https.HttpsError("failed-precondition", "Invite code already used");
        }
        if (invite.expires_at && invite.expires_at < now) {
            throw new functions.https.HttpsError("failed-precondition", "Invite code expired");
        }

        // B. Check User Status (Anti-Relinking)
        const userDoc = await t.get(userRef);
        const userData = userDoc.data();

        if (userData?.merchant_venue_id) {
            // User is already a merchant.
            // Only allow if they are re-claiming the SAME venue (e.g. fix broken link)
            // Otherwise, reject to prevent hijacking or accidental overwrite.
            if (userData.merchant_venue_id !== invite.venue_id) {
                throw new functions.https.HttpsError("failed-precondition", "User is already linked to another venue.");
            }
        }

        // C. Read merchant profile before writes (Firestore requires all reads before writes)
        const merchantDoc = await t.get(merchantRef);

        // D. Update Invite
        t.update(inviteRef, {
            status: 'used',
            used_by: uid,
            used_at: now,
            updated_at: now
        });

        // E. Upsert User (Grant Merchant Role)
        // Use set+merge to avoid failing when users/{uid} does not exist yet.
        t.set(userRef, {
            merchant_venue_id: invite.venue_id,
            is_merchant: true,
            updated_at: now
        }, { merge: true });

        // F. Create/Update Merchant Profile
        if (!merchantDoc.exists) {
             t.set(merchantRef, {
                uid: uid,
                venue_id: invite.venue_id,
                created_at: now,
                updated_at: now
            });
        } else {
             t.update(merchantRef, {
                venue_id: invite.venue_id,
                updated_at: now
             });
        }

        // Create welcome notification inside the merchant invite transaction.
        const notifRef = db.collection('users').doc(uid).collection('notifications').doc();
        t.set(notifRef, {
          title: 'مرحباً بك كتاجر!',
          body: 'تم ربط محلك بنجاح. يمكنك الآن إدارة العروض والتقييمات من لوحة التحكم.',
          type: 'welcome',
          data: { venue_id: invite.venue_id },
          is_read: false,
          created_at: now,
        });

        return { success: true, venueId: invite.venue_id };
    });

    logSecurityAudit("redeemInviteCode", {
      uid,
      inviteId: inviteRef.id,
      venueId: result.venueId ?? null,
      timestamp: now.toMillis(),
      result: "success",
    });

    return result;
});
