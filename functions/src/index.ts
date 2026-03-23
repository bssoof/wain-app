import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {
  ANALYTICS_TIMEZONE,
  bucketAnalyticsByDay,
  conversionRate,
  dayKeyInTimezone,
  dayOffsetKey,
} from "./analytics_helpers";
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

admin.initializeApp();
const db = admin.firestore();

// Helper: Hashing function
function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

const TRACKABLE_EVENT_TYPES = new Set(["view", "call", "story_view"]);
const LEGACY_TRACKABLE_EVENT_ALIASES: Record<string, string> = {
  venue_view: "view",
  whatsapp: "call",
  whatsapp_click: "call",
  call_click: "call",
  phone_call: "call",
  story: "story_view",
  storyview: "story_view",
};

function normalizeTrackableEventType(value: unknown): string {
  if (typeof value !== "string") return "";
  const normalized = value.trim().toLowerCase();
  if (!normalized) return "";
  return LEGACY_TRACKABLE_EVENT_ALIASES[normalized] ?? normalized;
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
  now: admin.firestore.Timestamp,
): "available" | "inactive" | "not_started" | "expired" {
  if (offerData.is_active === false) return "inactive";

  const startAt = offerData.start_at;
  if (startAt instanceof admin.firestore.Timestamp &&
      startAt.toMillis() > now.toMillis()) {
    return "not_started";
  }

  const endAt = offerData.end_at;
  if (endAt instanceof admin.firestore.Timestamp &&
      endAt.toMillis() <= now.toMillis()) {
    return "expired";
  }

  return "available";
}

function dayFromTimestamp(ts: unknown): Date | null {
  if (ts instanceof admin.firestore.Timestamp) {
    return ts.toDate();
  }
  if (ts instanceof Date) {
    return ts;
  }
  return null;
}


async function countQuery(query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData>): Promise<number> {
  try {
    const aggregate = await query.count().get();
    return aggregate.data().count;
  } catch (e) {
    // Fallback for environments where count aggregate is unavailable.
    const snap = await query.get();
    return snap.size;
  }
}

async function aggregateVenueAnalyticsForVenue(venueId: string, lookbackDays: number = 30): Promise<void> {
  const nowDate = new Date();
  const nowTs = admin.firestore.Timestamp.now();
  const safeLookback = Math.max(lookbackDays, 1);
  const todayKey = dayKeyInTimezone(nowDate, ANALYTICS_TIMEZONE);
  const periodStartKey = dayOffsetKey(todayKey, -(safeLookback - 1));
  const periodStartDate = new Date(`${periodStartKey}T00:00:00.000Z`);

  const [recentEventsSnap, recentNavsSnap] = await Promise.all([
    db.collection("venue_events")
      .where("venue_id", "==", venueId)
      .where("created_at", ">=", admin.firestore.Timestamp.fromDate(periodStartDate))
      .get(),
    db.collection("navigation_clicks")
      .where("venue_id", "==", venueId)
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(periodStartDate))
      .get(),
  ]);

  const events = recentEventsSnap.docs
    .map((doc) => {
      const data = doc.data();
      const eventType = data.event_type as string | undefined;
      const createdAt = dayFromTimestamp(data.created_at);
      if (!eventType || !createdAt) return null;
      return { eventType, at: createdAt };
    })
    .filter((event): event is { eventType: string; at: Date } => event !== null);

  const navigationClicks = recentNavsSnap.docs
    .map((doc) => {
      const data = doc.data();
      return dayFromTimestamp(data.timestamp);
    })
    .filter((ts): ts is Date => ts !== null);

  const bucketed = bucketAnalyticsByDay({
    nowDate,
    lookbackDays: safeLookback,
    events,
    navigationClicks,
    timeZone: ANALYTICS_TIMEZONE,
  });

  const [viewsTotal, callsTotal, storyViewsTotal, navsTotal] = await Promise.all([
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "view"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "call"),
    ),
    countQuery(
      db.collection("venue_events")
        .where("venue_id", "==", venueId)
        .where("event_type", "==", "story_view"),
    ),
    countQuery(
      db.collection("navigation_clicks")
        .where("venue_id", "==", venueId),
    ),
  ]);

  const summaryRef = db.collection("venue_analytics").doc(venueId);
  await summaryRef.set({
    venue_id: venueId,
    views_total: viewsTotal,
    views_this_week: bucketed.viewsThisWeek,
    views_last_week: bucketed.viewsLastWeek,
    calls_total: callsTotal,
    calls_this_week: bucketed.callsThisWeek,
    calls_last_week: bucketed.callsLastWeek,
    navs_total: navsTotal,
    navs_this_week: bucketed.navsThisWeek,
    navs_last_week: bucketed.navsLastWeek,
    story_views_total: storyViewsTotal,
    story_views_this_week: bucketed.storyViewsThisWeek,
    updated_at: nowTs,
  }, { merge: true });

  const batch = db.batch();
  for (const [key, bucket] of bucketed.dailyBuckets.entries()) {
    const dayRef = db.collection("venue_analytics_daily")
      .doc(venueId)
      .collection("days")
      .doc(key);

    batch.set(dayRef, {
      venue_id: venueId,
      date_key: key,
      views: bucket.views,
      calls: bucket.calls,
      navs: bucket.navs,
      story_views: bucket.story_views,
      updated_at: nowTs,
    }, { merge: true });
  }
  await batch.commit();
}

// â”€â”€â”€ Helper: Send notification to merchant(s) of a venue â”€â”€â”€
async function sendMerchantNotification(params: {
  venueId: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, any>;
}) {
  try {
    const merchantQuery = await db.collection('merchants')
        .where('venue_id', '==', params.venueId)
        .limit(3)
        .get();
    
    if (merchantQuery.empty) {
      console.log(`No merchant found for venue ${params.venueId}`);
      return;
    }
    
    for (const doc of merchantQuery.docs) {
      const merchantUid = doc.data().uid;
      if (!merchantUid) continue;
      
      await db.collection('users').doc(merchantUid)
          .collection('notifications').add({
            title: params.title,
            body: params.body,
            type: params.type,
            data: params.data || {},
            is_read: false,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          });
      
      console.log(`âœ… Notification sent to merchant ${merchantUid}: ${params.title}`);
    }
  } catch (error) {
    console.error('â‌Œ Error sending merchant notification:', error);
  }
}

// Track venue-level interaction events for merchant analytics.
// Input: venueId, eventType(view|call|story_view), source, deviceId?
export const trackVenueEvent = functions.https.onCall(async (data, context) => {
  const venueId = typeof data?.venueId === "string" ? data.venueId.trim() : "";
  const rawEventType = typeof data?.eventType === "string" ? data.eventType.trim() : "";
  const eventType = normalizeTrackableEventType(rawEventType);
  const source = typeof data?.source === "string" ? data.source.trim() : "unknown";
  const deviceId = typeof data?.deviceId === "string" ? data.deviceId.trim() : null;

  if (!venueId) {
    throw new functions.https.HttpsError("invalid-argument", "venueId is required");
  }
  if (!TRACKABLE_EVENT_TYPES.has(eventType)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid eventType");
  }

  await db.collection("venue_events").add({
    venue_id: venueId,
    event_type: eventType,
    event_type_raw: rawEventType || null,
    source: source || "unknown",
    user_id: context.auth?.uid ?? null,
    device_id: deviceId,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// 1. Create Claim Token
// Input: offerId, venueId, city, source, deviceId
// Output: claimId, token, expiresAt
// 1. Create Claim Token
// Input: offerId, venueId, city, source, deviceId
// Output: claimId, token, expiresAt
export const createClaimToken = functions.https.onCall(async (data, context) => {
  const { offerId, venueId, city, source, deviceId } = data;
  if (!offerId || !venueId || !deviceId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  const uid = context.auth?.uid;
  const now = admin.firestore.Timestamp.now();
  const offerRef = db.collection("offers").doc(offerId);
  const offerDoc = await offerRef.get();
  if (!offerDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Offer not found");
  }

  const offerData = offerDoc.data() ?? {};
  const availabilityState = getOfferAvailabilityState(offerData, now);
  if (availabilityState !== "available") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `offer_${availabilityState}`,
    );
  }
  const singleUsePerCustomer = offerData.single_use_per_customer !== false;

  const claimDocsById = new Map<string, FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>>();

  const deviceSnapshot = await db.collection("offer_claims")
    .where("offer_id", "==", offerId)
    .where("device_id", "==", deviceId)
    .get();

  for (const doc of deviceSnapshot.docs) {
    claimDocsById.set(doc.id, doc);
  }

  if (uid) {
    const userSnapshot = await db.collection("offer_claims")
      .where("offer_id", "==", offerId)
      .where("user_id", "==", uid)
      .get();

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
      const expiresAt = claim.expires_at;
      if (expiresAt instanceof admin.firestore.Timestamp &&
          expiresAt.toMillis() > now.toMillis() &&
          claim.token) {
        return {
          claimId: doc.id,
          token: claim.token,
          expiresAt: expiresAt.toMillis(),
        };
      }

      await doc.ref.delete();
    }
  }

  const token = crypto.randomBytes(16).toString("hex");
  const tokenHash = hashToken(token);
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + 10 * 60 * 1000,
  );

  const claimData = {
    offer_id: offerId,
    venue_id: venueId,
    city: city || "unknown",
    source: source || "unknown",
    device_id: deviceId,
    user_id: uid || null,
    status: "pending",
    timestamp: now,
    created_at: now,
    expires_at: expiresAt,
    token,
    token_hash: tokenHash,
  };

  const claimRef = db.collection("offer_claims").doc();

  await db.runTransaction(async (t) => {
    const freshOfferDoc = await t.get(offerRef);
    if (!freshOfferDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Offer not found");
    }

    const freshOfferData = freshOfferDoc.data() ?? {};
    const currentClaims = toInt(freshOfferData.claims_count);
    const currentRedeemed = toInt(freshOfferData.redeemed_count);
    const nextClaims = currentClaims + 1;
    const nextConversion = conversionRate(currentRedeemed, nextClaims);

    t.set(claimRef, claimData);
    t.set(offerRef, {
      claims_count: nextClaims,
      conversion_rate: nextConversion,
      updated_at: now,
    }, { merge: true });
  });

  return {
    claimId: claimRef.id,
    token,
    expiresAt: expiresAt.toMillis(),
  };
});

// 2. Validate Token (Merchant Only ideally, but open for scan preview)
// Input: token
// Output: status, offer details
export const validateToken = functions.https.onCall(async (data, context) => {
  // AUTH CHECK: Merchant must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Merchant login required");
  }

  const { token } = data;
  if (!token) {
    throw new functions.https.HttpsError("invalid-argument", "Missing token");
  }

  const tokenHash = hashToken(token);

  // Find claim by hash
  const snapshot = await db.collection("offer_claims")
    .where("token_hash", "==", tokenHash)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new functions.https.HttpsError("not-found", "Invalid token");
  }

  const claimDoc = snapshot.docs[0];
  const claim = claimDoc.data();

  // SECURITY: Verify Merchant owns the Venue for this offer
  const merchantRef = db.collection("merchants").doc(context.auth.uid);
  const merchantDoc = await merchantRef.get();

  if (!merchantDoc.exists) {
    throw new functions.https.HttpsError("permission-denied", "Not a registered merchant");
  }

  const merchantVenueId = merchantDoc.data()?.venue_id;
  if (merchantVenueId !== claim.venue_id) {
    throw new functions.https.HttpsError(
      "permission-denied", 
      "This offer belongs to a different venue"
    );
  }

  // Check Expiry
  const now = admin.firestore.Timestamp.now();
  if (claim.expires_at < now) {
      return { 
          valid: false, 
          reason: "expired", 
          claimId: claimDoc.id,
          offerId: claim.offer_id 
      };
  }

  // Check Status
  if (claim.status !== "pending") {
      return { 
          valid: false, 
          reason: "already_redeemed", 
          claimId: claimDoc.id,
          offerId: claim.offer_id,
          redeemedAt: claim.redeemed_at?.toMillis()
      };
  }

  // Fetch Offer & Venue details for Preview
  const offerDoc = await db.collection("offers").doc(claim.offer_id).get();
  const venueDoc = await db.collection("venues").doc(claim.venue_id).get();
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
    canRedeem: true // Already verified above
  };
});


// Input: token
// Security: Merchant Auth Required
export const redeemToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Merchant login required");
  }

  const { token } = data;
  const rawBillAmount = typeof data.billAmount === "number"
    ? data.billAmount
    : (typeof data.billAmount === "string" ? Number(data.billAmount) : null);
  const hasBillAmount = typeof rawBillAmount === "number" &&
    Number.isFinite(rawBillAmount) &&
    rawBillAmount > 0;
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

  const now = admin.firestore.Timestamp.now();
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
    const offerState = getOfferAvailabilityState(offerData, now);
    if (offerState !== "available") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `offer_${offerState}`,
      );
    }
    const claimsCount = toInt(offerData.claims_count);
    const redeemedCount = toInt(offerData.redeemed_count);
    const nextRedeemed = redeemedCount + 1;
    const nextConversion = conversionRate(nextRedeemed, claimsCount);
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

// Helper: Calculate distance in km
function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371; // Earth radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

// 4. Search Venues in Bounds (Geo-Search)
// Input: bounds { minLat, maxLat, minLng, maxLng }, limit, startAfter (id)
export const searchVenuesInBounds = functions.https.onCall(async (data, context) => {
    const { minLat, maxLat, minLng, maxLng, startAfter } = data;
    const limit = Math.min(data.limit || 50, 100); // Cap at 100

    // 0. Security: App Check Verification
    if (!context.app) {
        console.warn("âڑ ï¸ڈ searchVenuesInBounds called without AppCheck token.");
        // reject? For now allow but log.
        // throw new functions.https.HttpsError('failed-precondition', 'The function must be called from an App Check verified app.');
    }

    // 1. Validation
    if (!minLat || !maxLat || !minLng || !maxLng) {
        throw new functions.https.HttpsError("invalid-argument", "Missing bounds");
    }

    // Check diagonal distance (Limit to ~20km to prevent scraping/overload)
    const diagonalKm = calculateDistance(minLat, minLng, maxLat, maxLng);
    if (diagonalKm > 20.0) {
        throw new functions.https.HttpsError(
            "out-of-range",
            "bounds_too_large" // Custom error code for client
        );
    }

    // 2. Query
    // Firestore allows range filter on ONE field. We filter by Lat, then filter Lng in memory.
    // Deterministic Sort: orderBy 'lat' then '__name__' (key) to ensure stable pagination.
    let query = db.collection("venues")
        .orderBy("lat")
        .orderBy(admin.firestore.FieldPath.documentId()) // Secondary sort for stability
        .where("lat", ">=", minLat)
        .where("lat", "<=", maxLat);

    // Rate Limiting (Basic per-device/IP check)
    // We use a simplified Token Bucket or Counter in Firestore
    const deviceId = data.deviceId || "unknown";
    const nowMin = Math.floor(Date.now() / 60000); // Current minute epoch
    const rateRef = db.collection("rate_limits").doc(`${nowMin}_${deviceId}`);

    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(rateRef);
            const count = doc.exists ? doc.data()?.count || 0 : 0;
            if (count > 20) { // Limit: 20 searches per minute
                throw new functions.https.HttpsError("resource-exhausted", "Rate limit exceeded");
            }
            t.set(rateRef, { count: count + 1 }, { merge: true });
        });
    } catch (e) {
         if (e instanceof functions.https.HttpsError) throw e;
         console.warn("Rate limit check failed, proceeding:", e);
    }

    // Pagination: If cursor provided, fetch doc to start after
    if (startAfter) {
        const startDoc = await db.collection("venues").doc(startAfter).get();
        if (startDoc.exists) {
            query = query.startAfter(startDoc);
        }
    }

    const snapshot = await query.limit(200).get(); // Fetch bit more to filter Lng

    // 3. Filter & Map
    const venues: any[] = [];

    for (const doc of snapshot.docs) {
        const d = doc.data();
        // Lng check
        if (d.lng >= minLng && d.lng <= maxLng) {
             if (venues.length < limit) {
                venues.push({
                    id: doc.id,
                    ...d,
                    created_at: d.created_at?.toMillis ? d.created_at.toMillis() : null
                });
             } else {
                 break; // Reached limit
             }
        }
    }

    // Optimized Cursor: Ideally we return the ID of the last *checked* doc,
    // but simplified to just last yielded ID for now.
    // A robust geo-cursor is complex; passing last ID is okay for simple 'load more'.
    const nextCursor = venues.length > 0 ? venues[venues.length - 1].id : null;

    return { venues, nextCursor };
});

// 5. Trigger: Update Venue hasActiveOffers
// Listens to write on `offers/{offerId}`
// If offer changes, re-evaluate the venue's status.
export const updateVenueHasOffers = functions.firestore
    .document("offers/{offerId}")
    .onWrite(async (change, context) => {
        const after = change.after.exists ? change.after.data() : null;
        const before = change.before.exists ? change.before.data() : null;

        const venueId = after?.venue_id || before?.venue_id;

        if (!venueId) return null; // Should not happen

        console.log(`Checking offers for venue: ${venueId}`);

        // Query ALL active offers for this venue
        const now = admin.firestore.Timestamp.now();
        const activeOffersSnapshot = await db.collection("offers")
            .where("venue_id", "==", venueId)
            .where("is_active", "==", true)
            .get(); // We can't filter dates easily with boolean in one index, so fetch all active

        let hasActive = false;

        for (const doc of activeOffersSnapshot.docs) {
            const offer = doc.data();
            // Client-side date check
            if (offer.start_at && offer.start_at > now) continue; // Not started yet
            if (offer.end_at && offer.end_at < now) continue;   // Ended

            hasActive = true;
            break;
        }

        // Update Venue
        // Check current status to avoid infinite loops or redundant writes
        const venueRef = db.collection("venues").doc(venueId);
        const venueDoc = await venueRef.get();

        if (venueDoc.exists) {
             const vData = venueDoc.data();
             if (vData?.has_active_offers !== hasActive) {
                 await venueRef.update({ has_active_offers: hasActive });
                 console.log(`Updated venue ${venueId} has_active_offers to ${hasActive}`);
             }
        }

        return null;
    });

// 6. Scheduled: Check Expiring Offers (Hourly)
// Ensures 'hasActiveOffers' is accurate even if no writes happen.
export const checkExpiringOffers = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    console.log('âڈ° Running scheduled offer expiry check...');

    // 1. Find venues with matches that MIGHT have expired
    // Optimized: We could query venues with has_active_offers=true.
    const venuesWithOffers = await db.collection("venues")
        .where("has_active_offers", "==", true)
        .get();

    let updatedCount = 0;
    const batch = db.batch();

    for (const doc of venuesWithOffers.docs) {
        const venueId = doc.id;

        // Check actual active offers
        // Check actual active offers
        // Fix: Don't filter by 'end_at' in query because it excludes offers with null end_at (perpetual)
        const activeOffersSnapshot = await db.collection("offers")
            .where("venue_id", "==", venueId)
            .where("is_active", "==", true)
            .get();

        let hasValidOffer = false;

        for (const oDoc of activeOffersSnapshot.docs) {
             const offer = oDoc.data();
             // Check expiry in memory
             if (offer.end_at && offer.end_at < now) continue;
             if (offer.start_at && offer.start_at > now) continue;

             hasValidOffer = true;
             break;
        }

        // If no active offers found (but venue says true), disable it
        if (!hasValidOffer) {
             console.log(`Venue ${venueId} has no valid offers left. Disabling flag.`);
             batch.update(db.collection('venues').doc(doc.id), { has_active_offers: false });
             updatedCount++;
        }

        // Check batch size limit (500)
        if (updatedCount >= 400) {
            await batch.commit();
            updatedCount = 0;
        }
    }

    if (updatedCount > 0) {
        await batch.commit();
    }

    console.log(`âœ… Completed expiry check. Updated ${updatedCount} venues.`);
    return null;
});

// 7. Scheduled: Aggregate Venue Analytics (Hourly)
// Reads venue_events + navigation_clicks and writes:
// - venue_analytics/{venueId}
// - venue_analytics_daily/{venueId}/days/{YYYY-MM-DD}
export const aggregateVenueAnalytics = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const merchantSnap = await db.collection("merchants").get();
    const venueIds = new Set<string>();

    for (const doc of merchantSnap.docs) {
      const venueId = doc.data().venue_id;
      if (typeof venueId === "string" && venueId.trim().length > 0) {
        venueIds.add(venueId.trim());
      }
    }

    let ok = 0;
    let failed = 0;
    for (const venueId of venueIds) {
      try {
        await aggregateVenueAnalyticsForVenue(venueId, 30);
        ok += 1;
      } catch (e) {
        failed += 1;
        console.error(`Failed to aggregate analytics for venue ${venueId}`, e);
      }
    }

    console.log(`âœ… aggregateVenueAnalytics finished. ok=${ok}, failed=${failed}`);
    return null;
  });

// Optional one-off backfill for merchant's own venue.
// Input: { days?: number } where days is capped at 30.
export const backfillMerchantAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const uid = context.auth.uid;
  const merchantRef = db.collection("merchants").doc(uid);
  const userRef = db.collection("users").doc(uid);

  const [merchantDoc, userDoc] = await Promise.all([
    merchantRef.get(),
    userRef.get(),
  ]);

  const merchantVenueId = merchantDoc.data()?.venue_id as string | undefined;
  const userVenueId = userDoc.data()?.merchant_venue_id as string | undefined;

  const normalizedMerchantVenueId = typeof merchantVenueId === "string" ? merchantVenueId.trim() : "";
  const normalizedUserVenueId = typeof userVenueId === "string" ? userVenueId.trim() : "";

  // Prefer users/{uid}.merchant_venue_id because dashboard access is based on it.
  const venueId = normalizedUserVenueId || normalizedMerchantVenueId;
  if (!venueId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Not a linked merchant account",
    );
  }

  // Auto-heal legacy accounts that have user link but no merchant profile.
  if (!normalizedMerchantVenueId || normalizedMerchantVenueId !== venueId) {
    await merchantRef.set(
      {
        uid,
        venue_id: venueId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  const requestedDays = typeof data?.days === "number" ? Math.trunc(data.days) : 30;
  const days = Math.max(1, Math.min(requestedDays, 30));

  try {
    await aggregateVenueAnalyticsForVenue(venueId, days);
  } catch (error) {
    const rawMessage = error instanceof Error ? error.message : String(error);
    console.error("backfillMerchantAnalytics failed", { uid, venueId, rawMessage });
    const lowered = rawMessage.toLowerCase();

    if (lowered.includes("index")) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Missing Firestore index for analytics queries",
      );
    }

    throw new functions.https.HttpsError(
      "internal",
      "Failed to aggregate merchant analytics",
    );
  }

  const summarySnap = await db.collection("venue_analytics").doc(venueId).get();
  const summary = summarySnap.exists ? summarySnap.data() : null;
  return {
    success: true,
    venueId,
    days,
    summary: summary ? {
      views_total: toInt(summary.views_total),
      calls_total: toInt(summary.calls_total),
      navs_total: toInt(summary.navs_total),
      story_views_total: toInt(summary.story_views_total),
    } : null,
  };
});

// 7. Redeem Invite Code (Merchant Onboarding)
// Input: code
// Security: App Check + Auth Required + Rate Limit
export const redeemInviteCode = functions.https.onCall(async (data, context) => {
    // 1. Security Checks
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    if (!context.app) {
        throw new functions.https.HttpsError("failed-precondition", "App Check verification failed");
    }

    const { code } = data;
    if (!code || typeof code !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "Invalid invite code");
    }
    const normalizedCode = code.trim().toUpperCase();
    if (!normalizedCode) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid invite code");
    }

    const uid = context.auth.uid;
    const now = admin.firestore.Timestamp.now();

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

    return db.runTransaction(async (t) => {
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

        // ًں”” Create welcome notification (inside transaction for the new merchant)
        const notifRef = db.collection('users').doc(uid).collection('notifications').doc();
        t.set(notifRef, {
          title: 'ًںژ‰ ظ…ط±ط­ط¨ط§ظ‹ ط¨ظƒ ظƒطھط§ط¬ط±!',
          body: 'طھظ… ط±ط¨ط· ظ…ط­ظ„ظƒ ط¨ظ†ط¬ط§ط­. ظٹظ…ظƒظ†ظƒ ط§ظ„ط¢ظ† ط¥ط¯ط§ط±ط© ط§ظ„ط¹ط±ظˆط¶ ظˆط§ظ„طھظ‚ظٹظٹظ…ط§طھ ظ…ظ† ظ„ظˆط­ط© ط§ظ„طھط­ظƒظ….',
          type: 'welcome',
          data: { venue_id: invite.venue_id },
          is_read: false,
          created_at: now,
        });

        return { success: true, venueId: invite.venue_id };
    });
});

// 8. Maintain Review Counts (Trigger) + Merchant Notifications
// Listener: venues/{venueId}/reviews/{reviewId}
// Action: atomic increment/decrement on user profile + notify merchant
export const onReviewWrite = functions.firestore
    .document("venues/{venueId}/reviews/{reviewId}") 
    .onWrite(async (change, context) => {
        const after = change.after.exists ? change.after.data() : null;
        const before = change.before.exists ? change.before.data() : null;

        // 1. Create: Increment + Notify Merchant
        if (!before && after) {
            const uid = after.user_id;
            if (uid) {
                await db.collection("users").doc(uid).update({
                    reviews_count: admin.firestore.FieldValue.increment(1)
                }).catch(e => console.log("Error incrementing review count:", e));
            }

            // ًں”” Notify merchant about the new review
            const venueId = context.params.venueId;
            const rating = after.rating || 0;
            const userName = after.user_name || 'ظ…ط³طھط®ط¯ظ…';
            const stars = 'â­گ'.repeat(Math.min(Math.round(rating), 5));
            
            await sendMerchantNotification({
              venueId: venueId,
              title: `${stars} طھظ‚ظٹظٹظ… ط¬ط¯ظٹط¯ (${rating}/5)`,
              body: after.comment 
                ? `${userName}: "${after.comment.substring(0, 100)}"` 
                : `${userName} ط£ط¹ط·ط§ظƒ طھظ‚ظٹظٹظ… ${rating} ظ…ظ† 5`,
              type: 'review',
              data: { venue_id: venueId, review_id: context.params.reviewId },
            });
        }
        
        // 2. Delete: Decrement
        else if (before && !after) {
             const uid = before.user_id;
             if (uid) {
                await db.collection("users").doc(uid).update({
                    reviews_count: admin.firestore.FieldValue.increment(-1)
                }).catch(e => console.log("Error decrementing review count:", e));
             }
        }

        return null;
    });

// 9. Promote Story (Paid Feature Simulation)
// Input: storyId, durationDays (int)
// Security: App Check + Auth + Ownership
export const promoteStory = functions.https.onCall(async (data, context) => {
    // 1. Security Checks
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    if (!context.app) {
        console.warn("âڑ ï¸ڈ promoteStory called without AppCheck token.");
        // throw new functions.https.HttpsError("failed-precondition", "App Check verification failed");
    }

    const { storyId, durationDays } = data;
    
    if (!storyId || typeof storyId !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "Invalid story ID");
    }
    if (!durationDays || typeof durationDays !== 'number' || durationDays <= 0 || durationDays > 7) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid duration (1-7 days)");
    }

    const uid = context.auth.uid;
    const db = admin.firestore();
    
    // 2. Fetch Merchant Profile & Story
    // We need to find the story. Since we don't know the venueId from input (securely),
    // we should first get the merchant's venueId.
    
    const merchantDoc = await db.collection("merchants").doc(uid).get();
    if (!merchantDoc.exists) {
        throw new functions.https.HttpsError("permission-denied", "Not a merchant");
    }
    
    const venueId = merchantDoc.data()!.venue_id;
    if (!venueId) {
        throw new functions.https.HttpsError("failed-precondition", "Merchant has no venue");
    }
    
    // Stories are stored in top-level "stories" collection.
    const storyRef = db.collection("stories").doc(storyId);
    
    return db.runTransaction(async (t) => {
        const storyDoc = await t.get(storyRef);
        
        if (!storyDoc.exists) {
             throw new functions.https.HttpsError("not-found", "Story not found or access denied");
        }
        
        const story = storyDoc.data()!;
        const storyVenueId = story.venue_id;
        if (!storyVenueId || storyVenueId !== venueId) {
            throw new functions.https.HttpsError("permission-denied", "Cannot promote story outside your venue");
        }
        const now = admin.firestore.Timestamp.now();
        const expiresAt = story.expires_at; // Timestamp
        
        // 3. Calculate Promotion Period
        // Start from NOW (or extend if already promoted?) -> Business rule: From NOW.
        let promoteUntilDate = new Date();
        promoteUntilDate.setDate(promoteUntilDate.getDate() + durationDays);
        let promoteUntilTs = admin.firestore.Timestamp.fromDate(promoteUntilDate);
        
        // 4. Clamp to Expiry
        // Cannot promote a story beyond its life
        if (promoteUntilTs.toMillis() > expiresAt.toMillis()) {
            promoteUntilTs = expiresAt;
        }
        
        // If story is already expired, fail
        if (now.toMillis() > expiresAt.toMillis()) {
             throw new functions.https.HttpsError("failed-precondition", "Story has expired");
        }

        // 5. Update Story
        t.update(storyRef, {
            promoted_until: promoteUntilTs,
            is_promoted: true, // Helper flag
            updated_at: now
        });
        
        return { 
            success: true, 
            promoted_until: promoteUntilTs.toDate().toISOString(),
            clamped: promoteUntilTs.toMillis() !== admin.firestore.Timestamp.fromDate(new Date(Date.now() + durationDays * 86400000)).toMillis() // Rough check
        };
    });
});



