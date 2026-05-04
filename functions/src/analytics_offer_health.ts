import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import { db } from "./shared/firestore-db";

// Trigger: Update Venue hasActiveOffers
// Listens to write on offers/{offerId} and re-evaluates the venue status.
export const updateVenueHasOffers = functions.firestore
  .document("offers/{offerId}")
  .onWrite(async (change) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    const venueId = after?.venue_id || before?.venue_id;
    if (!venueId) return null;

    console.log(`Checking offers for venue: ${venueId}`);

    const now = Timestamp.now();
    const activeOffersSnapshot = await db.collection("offers")
      .where("venue_id", "==", venueId)
      .where("is_active", "==", true)
      .get();

    let hasActive = false;
    for (const doc of activeOffersSnapshot.docs) {
      const offer = doc.data();
      if (offer.start_at && offer.start_at > now) continue;
      if (offer.end_at && offer.end_at < now) continue;
      hasActive = true;
      break;
    }

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

// Scheduled: Check Expiring Offers (Hourly)
// Ensures hasActiveOffers remains accurate even without offer writes.
export const checkExpiringOffers = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now = Timestamp.now();
    console.log("Running scheduled offer expiry check...");

    const venuesWithOffers = await db.collection("venues")
      .where("has_active_offers", "==", true)
      .get();

    let pendingUpdates = 0;
    const batch = db.batch();

    for (const doc of venuesWithOffers.docs) {
      const venueId = doc.id;

      const activeOffersSnapshot = await db.collection("offers")
        .where("venue_id", "==", venueId)
        .where("is_active", "==", true)
        .get();

      let hasValidOffer = false;
      for (const oDoc of activeOffersSnapshot.docs) {
        const offer = oDoc.data();
        if (offer.end_at && offer.end_at < now) continue;
        if (offer.start_at && offer.start_at > now) continue;

        hasValidOffer = true;
        break;
      }

      if (!hasValidOffer) {
        console.log(`Venue ${venueId} has no valid offers left. Disabling flag.`);
        batch.update(db.collection("venues").doc(doc.id), { has_active_offers: false });
        pendingUpdates += 1;
      }

      if (pendingUpdates >= 400) {
        await batch.commit();
        pendingUpdates = 0;
      }
    }

    if (pendingUpdates > 0) {
      await batch.commit();
    }

    console.log(`Completed expiry check. Updated ${pendingUpdates} venues.`);
    return null;
  });
