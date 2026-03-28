const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-transport-seed";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const { seedTransportMvp, normalizeRuleId } = require("../../scripts/seed_transport_mvp.js");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
}

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

test.beforeEach(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("seedTransportMvp enables venues and writes managed partner config", async () => {
  await db.collection("venues").doc("venue-a").set({ name_ar: "Venue A" });
  await db.collection("venues").doc("venue-b").set({ name_ar: "Venue B" });

  const result = await seedTransportMvp({
    venueIds: ["venue-a", "venue-b"],
    city: "ramallah",
    partnerId: "waselni-a",
    partnerName: "Waselni Partner",
    contactMode: "whatsapp",
    currency: "ILS",
    whatsapp: "972599111111",
    phone: "+972599111111",
    deepLinkUrlTemplate: "https://example.com",
    baseFare: 10,
    perKmRate: 4,
    minimumFare: 14,
    serviceFee: 1,
    pricingVersion: "v1",
    notesAr: "أسعار تقديرية",
    notesEn: "Estimated fares",
    db,
    logger: { log() {} },
  });

  assert.equal(result.result, "seeded");
  assert.equal(result.partnerId, "waselni-a");

  const partnerDoc = await db.collection("transport_partners").doc("waselni-a").get();
  assert.equal(partnerDoc.exists, true);
  assert.equal(partnerDoc.data().quote_mode, "managed");
  assert.equal(partnerDoc.data().contact_mode, "whatsapp");

  const ruleDoc = await db.collection("transport_partner_rules")
    .doc(normalizeRuleId("waselni-a", "ramallah"))
    .get();
  assert.equal(ruleDoc.exists, true);
  assert.equal(ruleDoc.data().base_fare, 10);

  const venueADoc = await db.collection("venues").doc("venue-a").get();
  assert.equal(venueADoc.data().transport_enabled, true);
  assert.deepEqual(venueADoc.data().transport_partner_ids, ["waselni-a"]);
  assert.equal(venueADoc.data().transport_notes_ar, "أسعار تقديرية");

  const venueBDoc = await db.collection("venues").doc("venue-b").get();
  assert.equal(venueBDoc.data().transport_enabled, true);
  assert.deepEqual(venueBDoc.data().transport_partner_ids, ["waselni-a"]);
});
