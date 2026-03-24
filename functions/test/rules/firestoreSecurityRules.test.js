const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  setDoc,
  updateDoc,
  getDoc,
  getDocs,
  collection,
  Timestamp,
  addDoc,
} = require("firebase/firestore");

const projectId = "demo-wain-security-rules";
const rules = fs.readFileSync(path.resolve(__dirname, "../../../firestore.rules"), "utf8");

let testEnv;

function nowTs() {
  return Timestamp.fromDate(new Date());
}

async function seedData(fn) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await fn(context.firestore());
  });
}

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules, host: "127.0.0.1", port: 8080 },
  });
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

test.after(async () => {
  await testEnv.cleanup();
});

test("B1 merchant cannot read another merchant doc", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), { uid: "merchant-a", venue_id: "venue-a" });
    await setDoc(doc(db, "merchants", "merchant-b"), { uid: "merchant-b", venue_id: "venue-b" });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(getDoc(doc(db, "merchants", "merchant-b")));
});

test("D1 user profile escalation fields are denied", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "users", "user-a"), {
      uid: "user-a",
      created_at: nowTs(),
      display_name: "User A",
      username: "usera",
    });
  });

  const db = testEnv.authenticatedContext("user-a").firestore();
  await assertFails(updateDoc(doc(db, "users", "user-a"), {
    merchant_venue_id: "venue-a",
    is_merchant: true,
  }));
});

test("D2 merchant_invites cannot be read directly from client", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchant_invites", "invite-1"), {
      code: "WAIN-READTEST",
      venue_id: "venue-a",
      status: "active",
      expires_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("user-a").firestore();
  await assertFails(getDoc(doc(db, "merchant_invites", "invite-1")));
});

test("D3 authenticated user cannot read another user's claim", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "offer_claims", "claim-1"), {
      user_id: "user-a",
      offer_id: "offer-a",
      venue_id: "venue-a",
      status: "pending",
      created_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("user-b").firestore();
  await assertFails(getDoc(doc(db, "offer_claims", "claim-1")));
});

test("D3b unscoped offer_claims query/list does not enumerate other users", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "offer_claims", "claim-1"), {
      user_id: "user-a",
      offer_id: "offer-a",
      venue_id: "venue-a",
      status: "pending",
      created_at: nowTs(),
    });
    await setDoc(doc(db, "offer_claims", "claim-2"), {
      user_id: "user-b",
      offer_id: "offer-b",
      venue_id: "venue-b",
      status: "pending",
      created_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("user-a").firestore();
  await assertFails(getDocs(collection(db, "offer_claims")));
});

test("D4 venue write boundary denies ordinary user", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "venues", "venue-a"), { name_ar: "Venue A", updated_at: nowTs() });
  });

  const db = testEnv.authenticatedContext("user-a").firestore();
  await assertFails(updateDoc(doc(db, "venues", "venue-a"), { name_ar: "Tampered" }));
});

test("D6 merchant owner cannot tamper with server-maintained offer stats", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), { uid: "merchant-a", venue_id: "venue-a" });
    await setDoc(doc(db, "offers", "offer-a"), {
      venue_id: "venue-a",
      title_ar: "Offer A",
      claims_count: 0,
      redeemed_count: 0,
      conversion_rate: 0,
      last_redeemed_at: nowTs(),
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(updateDoc(doc(db, "offers", "offer-a"), { claims_count: 999 }));
});

test("D5 navigation_clicks requires auth for create", async () => {
  const guestDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(addDoc(collection(guestDb, "navigation_clicks"), {
    venue_id: "venue-a",
    user_id: null,
    timestamp: nowTs(),
    nav_app: "google_maps",
  }));

  const authDb = testEnv.authenticatedContext("user-a").firestore();
  await assertSucceeds(addDoc(collection(authDb, "navigation_clicks"), {
    venue_id: "venue-a",
    user_id: "user-a",
    device_id: "device-a",
    timestamp: nowTs(),
    nav_app: "google_maps",
  }));
});
