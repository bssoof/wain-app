#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * seed_transport_mvp.js
 *
 * Usage:
 *   node seed_transport_mvp.js --venue venueA --venue venueB --city ramallah
 *   node seed_transport_mvp.js --venue venueA --partner-id taxi-anbar --contact-mode whatsapp
 *   node seed_transport_mvp.js --all-venues
 *
 * WARNING:
 *   Run only with Admin SDK credentials or inside Firebase Emulator.
 *   This script enables transport on venue docs and seeds the managed partner + pricing rule.
 */
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function parseArgs(argv) {
  const opts = {
    venueIds: [],
    allVenues: false,
    city: "ramallah",
    partnerId: "taxi-anbar",
    partnerName: "تكسي انبار",
    contactMode: "whatsapp",
    currency: "ILS",
    whatsapp: "972599123456",
    phone: "+972599123456",
    deepLinkUrlTemplate:
      "https://wa.me/{venue_name}?text={pickup_lat},{pickup_lng}->{dropoff_lat},{dropoff_lng}",
    baseFare: 14,
    perKmRate: 4.25,
    minimumFare: 18,
    serviceFee: 2,
    pricingVersion: "anbar-test-v1",
    notesAr: "أسعار تجريبية مقدمة من تكسي انبار",
    notesEn: "Test transport prices provided by Taxi Anbar",
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) {
      opts.venueIds.push(token.trim());
      continue;
    }

    const [key, inlineValue] = token.split("=");
    const value = inlineValue ?? argv[i + 1];
    const consume = !inlineValue;

    switch (key) {
      case "--venue":
        if (typeof value === "string" && value.trim()) {
          opts.venueIds.push(value.trim());
        }
        if (consume) i += 1;
        break;
      case "--all-venues":
        opts.allVenues = true;
        break;
      case "--city":
        if (typeof value === "string" && value.trim()) opts.city = value.trim();
        if (consume) i += 1;
        break;
      case "--partner-id":
        if (typeof value === "string" && value.trim()) opts.partnerId = value.trim();
        if (consume) i += 1;
        break;
      case "--partner-name":
        if (typeof value === "string" && value.trim()) opts.partnerName = value.trim();
        if (consume) i += 1;
        break;
      case "--contact-mode":
        if (typeof value === "string" && value.trim()) opts.contactMode = value.trim();
        if (consume) i += 1;
        break;
      case "--currency":
        if (typeof value === "string" && value.trim()) opts.currency = value.trim();
        if (consume) i += 1;
        break;
      case "--whatsapp":
        if (typeof value === "string" && value.trim()) opts.whatsapp = value.trim();
        if (consume) i += 1;
        break;
      case "--phone":
        if (typeof value === "string" && value.trim()) opts.phone = value.trim();
        if (consume) i += 1;
        break;
      case "--deep-link-url-template":
        if (typeof value === "string" && value.trim()) opts.deepLinkUrlTemplate = value.trim();
        if (consume) i += 1;
        break;
      case "--base-fare":
        opts.baseFare = Number(value);
        if (consume) i += 1;
        break;
      case "--per-km-rate":
        opts.perKmRate = Number(value);
        if (consume) i += 1;
        break;
      case "--minimum-fare":
        opts.minimumFare = Number(value);
        if (consume) i += 1;
        break;
      case "--service-fee":
        opts.serviceFee = Number(value);
        if (consume) i += 1;
        break;
      case "--pricing-version":
        if (typeof value === "string" && value.trim()) opts.pricingVersion = value.trim();
        if (consume) i += 1;
        break;
      case "--notes-ar":
        if (typeof value === "string") opts.notesAr = value.trim();
        if (consume) i += 1;
        break;
      case "--notes-en":
        if (typeof value === "string") opts.notesEn = value.trim();
        if (consume) i += 1;
        break;
      default:
        console.warn(`[WARN] Unknown argument ignored: ${key}`);
        if (consume && typeof value === "string" && !value.startsWith("--")) i += 1;
        break;
    }
  }

  opts.venueIds = [...new Set(opts.venueIds.filter(Boolean))];
  return opts;
}

function initAdmin() {
  if (admin.apps.length) return;

  const serviceAccountPath = path.resolve(__dirname, "../../service-account-key.json");
  if (fs.existsSync(serviceAccountPath)) {
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    return;
  }

  admin.initializeApp();
}

function normalizeCityKey(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function normalizeRuleId(partnerId, city) {
  return `${partnerId}_${normalizeCityKey(city)}`.replace(/[^a-z0-9_-]/g, "-");
}

async function seedTransportMvp({
  venueIds,
  allVenues = false,
  city,
  partnerId,
  partnerName,
  contactMode,
  currency,
  whatsapp,
  phone,
  deepLinkUrlTemplate,
  baseFare,
  perKmRate,
  minimumFare,
  serviceFee,
  pricingVersion,
  notesAr,
  notesEn,
  db = admin.firestore(),
  logger = console,
}) {
  if (!allVenues && (!Array.isArray(venueIds) || venueIds.length === 0)) {
    throw new Error("At least one venue id is required unless --all-venues is used");
  }

  let targetVenueIds = Array.isArray(venueIds) ? [...venueIds] : [];
  let venueRefs = targetVenueIds.map((venueId) => db.collection("venues").doc(venueId));
  let venueDocs = await Promise.all(venueRefs.map((ref) => ref.get()));

  if (allVenues) {
    const allVenueSnapshot = await db.collection("venues").get();
    targetVenueIds = allVenueSnapshot.docs.map((doc) => doc.id);
    venueRefs = allVenueSnapshot.docs.map((doc) => doc.ref);
    venueDocs = allVenueSnapshot.docs;
  }

  if (targetVenueIds.length === 0) {
    throw new Error("No venue docs found to enable transport on");
  }

  const missing = venueDocs
    .map((doc, index) => (doc.exists ? null : targetVenueIds[index]))
    .filter(Boolean);

  if (missing.length) {
    throw new Error(`Missing venue docs: ${missing.join(", ")}`);
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const partnerRef = db.collection("transport_partners").doc(partnerId);
  const ruleRef = db.collection("transport_partner_rules").doc(
    normalizeRuleId(partnerId, city),
  );

  const batch = db.batch();
  batch.set(partnerRef, {
    name: partnerName,
    is_active: true,
    quote_mode: "managed",
    contact_mode: contactMode,
    supported_cities: [normalizeCityKey(city)],
    currency,
    min_eta_minutes: 6,
    max_eta_minutes: 10,
    whatsapp,
    phone,
    deep_link_url_template: deepLinkUrlTemplate,
    created_at: now,
    updated_at: now,
  }, { merge: true });

  batch.set(ruleRef, {
    partner_id: partnerId,
    city: normalizeCityKey(city),
    base_fare: baseFare,
    per_km_rate: perKmRate,
    minimum_fare: minimumFare,
    service_fee: serviceFee,
    is_active: true,
    pricing_version: pricingVersion,
    created_at: now,
    updated_at: now,
  }, { merge: true });

  for (const venueRef of venueRefs) {
    batch.set(venueRef, {
      transport_enabled: true,
      transport_partner_ids: admin.firestore.FieldValue.arrayUnion(partnerId),
      transport_notes_ar: notesAr,
      transport_notes_en: notesEn,
      updated_at: now,
    }, { merge: true });
  }

  await batch.commit();

  const result = {
    venueIds: targetVenueIds,
    allVenues,
    venuesCount: targetVenueIds.length,
    city: normalizeCityKey(city),
    partnerId,
    ruleId: ruleRef.id,
    timestamp: new Date().toISOString(),
    result: "seeded",
  };

  logger.log(result);
  return result;
}

async function main() {
  initAdmin();
  const opts = parseArgs(process.argv.slice(2));
  await seedTransportMvp(opts);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  parseArgs,
  seedTransportMvp,
  normalizeRuleId,
};
