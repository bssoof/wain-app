const test = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { deleteDoc, doc, setDoc, Timestamp } = require("firebase/firestore");
const { FirestoreEmulator } = require(path.join(
  process.env.APPDATA,
  "npm",
  "node_modules",
  "firebase-tools",
  "lib",
  "emulator",
  "firestoreEmulator",
));
const { StorageEmulator } = require(path.join(
  process.env.APPDATA,
  "npm",
  "node_modules",
  "firebase-tools",
  "lib",
  "emulator",
  "storage",
));
const { EmulatorRegistry } = require(path.join(
  process.env.APPDATA,
  "npm",
  "node_modules",
  "firebase-tools",
  "lib",
  "emulator",
  "registry",
));

const projectId = "demo-wain-security-storage";
const firestoreRules = fs.readFileSync(path.resolve(__dirname, "../../../firestore.rules"), "utf8");
const storageRules = fs.readFileSync(path.resolve(__dirname, "../../../storage.rules"), "utf8");
const bucketUrl = `gs://${projectId}.appspot.com`;

let testEnv;
let firestoreEmulator;
let storageEmulator;

function nowTs() {
  return Timestamp.fromDate(new Date());
}

async function seedData(fn) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await fn(context.firestore());
  });
}

async function seedMerchantAndUser(db, uid, venueId) {
  await setDoc(doc(db, "merchants", uid), { uid, venue_id: venueId, updated_at: nowTs() });
  await setDoc(doc(db, "users", uid), { uid, merchant_venue_id: venueId, is_merchant: true, updated_at: nowTs(), created_at: nowTs() }, { merge: true });
}

async function revokeMerchant(db, uid, { clearUserLink = true, removeMerchantDoc = true } = {}) {
  if (removeMerchantDoc) {
    await deleteDoc(doc(db, "merchants", uid));
  }
  if (clearUserLink) {
    await setDoc(doc(db, "users", uid), {
      merchant_venue_id: null,
      is_merchant: null,
      updated_at: nowTs(),
    }, { merge: true });
  }
}

function makeBytes(sizeBytes, fill = 65) {
  return new Uint8Array(sizeBytes).fill(fill);
}

test.before(async () => {
  firestoreEmulator = new FirestoreEmulator({
    host: "127.0.0.1",
    port: 8080,
    websocket_port: 9150,
    project_id: projectId,
    rules: path.resolve(__dirname, "../../../firestore.rules"),
    single_project_mode: true,
  });
  await EmulatorRegistry.start(firestoreEmulator);

  storageEmulator = new StorageEmulator({
    host: "127.0.0.1",
    port: 9199,
    projectId,
    rules: {
      name: path.resolve(__dirname, "../../../storage.rules"),
      content: storageRules,
    },
  });
  await EmulatorRegistry.start(storageEmulator);

  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: firestoreRules, host: "127.0.0.1", port: 8080 },
    storage: { rules: storageRules, host: "127.0.0.1", port: 9199 },
  });
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

test.after(async () => {
  await testEnv.cleanup();
  await EmulatorRegistry.stop("storage");
  await EmulatorRegistry.stop("firestore");
});

test("E1 merchant cannot upload photo to another venue", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  const ref = storage.ref("venues/venue-b/photos/attack.jpg");
  await assertFails(ref.put(makeBytes(1024), { contentType: "image/jpeg" }));
});

test("E2 merchant cannot upload story media to another venue", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  const ref = storage.ref("venues/venue-b/stories/attack.mp4");
  await assertFails(ref.put(makeBytes(1024), { contentType: "video/mp4" }));
});

test("E3 file type and size boundaries are enforced", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);

  await assertFails(
    storage.ref("venues/venue-a/photos/bad.txt").put(makeBytes(512), { contentType: "text/plain" }),
  );

  await assertFails(
    storage.ref("venues/venue-a/photos/too-big.jpg").put(makeBytes(5 * 1024 * 1024 + 10), { contentType: "image/jpeg" }),
  );

  await assertFails(
    storage.ref("venues/venue-a/stories/too-big.mp4").put(makeBytes(50 * 1024 * 1024 + 10), { contentType: "video/mp4" }),
  );
});

test("E3b renamed extension alone does not bypass contentType checks", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  const ref = storage.ref("venues/venue-a/photos/fake.jpg");
  await assertFails(ref.put(makeBytes(512), { contentType: "text/plain" }));
});

test("E4 merchant cannot delete another venue file", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminStorage = context.storage(bucketUrl);
    await adminStorage.ref("venues/venue-b/photos/existing.jpg").put(makeBytes(512), { contentType: "image/jpeg" });
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  await assertFails(storage.ref("venues/venue-b/photos/existing.jpg").delete());
});

test("E5 merchant cannot overwrite known filename in another venue", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminStorage = context.storage(bucketUrl);
    await adminStorage.ref("venues/venue-b/photos/existing.jpg").put(makeBytes(512), { contentType: "image/jpeg" });
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  await assertFails(
    storage.ref("venues/venue-b/photos/existing.jpg").put(makeBytes(256), { contentType: "image/jpeg" }),
  );
});

test("E6 merchant cannot update metadata on another venue file", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminStorage = context.storage(bucketUrl);
    await adminStorage.ref("venues/venue-b/photos/existing.jpg").put(makeBytes(512), { contentType: "image/jpeg" });
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  await assertFails(
    storage.ref("venues/venue-b/photos/existing.jpg").updateMetadata({ contentType: "image/png" }),
  );
});

test("E7 nested path spoof does not escape tenant path ownership", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  const ref = storage.ref("venues/venue-a/photos/../../../venue-b/photos/hacked.jpg");

  await assertFails(ref.put(makeBytes(512), { contentType: "image/jpeg" }));
});

test("J1 storage upload is blocked after full revocation", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
    await revokeMerchant(db, "merchant-a", { clearUserLink: true, removeMerchantDoc: true });
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  const ref = storage.ref("venues/venue-a/photos/revoked.jpg");

  await assertFails(ref.put(makeBytes(512), { contentType: "image/jpeg" }));
});

test("J1b storage upload still succeeds if only merchant doc is revoked but user link remains", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
    await revokeMerchant(db, "merchant-a", { clearUserLink: false, removeMerchantDoc: true });
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  const ref = storage.ref("venues/venue-a/photos/still-linked.jpg");

  await assertSucceeds(ref.put(makeBytes(512), { contentType: "image/jpeg" }));
});

test("W15 merchant can upload receipt only to own wallet_topups path", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
  });

  const storage = testEnv.authenticatedContext("merchant-a").storage(bucketUrl);
  await assertSucceeds(
    storage
      .ref("venues/venue-a/wallet_topups/proof-a.jpg")
      .put(makeBytes(2048), { contentType: "image/jpeg" }),
  );
  await assertFails(
    storage
      .ref("venues/venue-b/wallet_topups/proof-b.jpg")
      .put(makeBytes(2048), { contentType: "image/jpeg" }),
  );
});

test("W16 admin can read receipt stored as storage path", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
    await setDoc(doc(db, "admins", "admin-doc"), {
      uid: "admin-doc",
      active: true,
      updated_at: nowTs(),
    });
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminStorage = context.storage(bucketUrl);
    await adminStorage
      .ref("venues/venue-a/wallet_topups/proof-path.jpg")
      .put(makeBytes(512), { contentType: "image/jpeg" });
  });

  const adminStorage = testEnv.authenticatedContext("admin-doc").storage(bucketUrl);
  await assertSucceeds(
    adminStorage.ref("venues/venue-a/wallet_topups/proof-path.jpg").getMetadata(),
  );
});

async function seedWalletReceipt(pathName = "venues/venue-a/wallet_topups/m01-proof.jpg") {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminStorage = context.storage(bucketUrl);
    await adminStorage.ref(pathName).put(makeBytes(512), { contentType: "image/jpeg" });
  });
  return pathName;
}

test("M01 Storage denies token.admin=true without active admins document", async () => {
  const pathName = await seedWalletReceipt();

  const storage = testEnv.authenticatedContext("legacy-admin-no-doc", { admin: true }).storage(bucketUrl);
  await assertFails(storage.ref(pathName).getMetadata());
});

test("M01 Storage denies token.admin=true with inactive admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "admins", "legacy-admin-inactive"), {
      active: false,
      role: "finance_admin",
      updated_at: nowTs(),
    });
  });
  const pathName = await seedWalletReceipt();

  const storage = testEnv.authenticatedContext("legacy-admin-inactive", { admin: true }).storage(bucketUrl);
  await assertFails(storage.ref(pathName).getMetadata());
});

test("M01 Storage allows role=admin with active admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "admins", "legacy-admin-active"), {
      active: true,
      role: "finance_admin",
      updated_at: nowTs(),
    });
  });
  const pathName = await seedWalletReceipt();

  const storage = testEnv.authenticatedContext("legacy-admin-active", { role: "admin" }).storage(bucketUrl);
  await assertSucceeds(storage.ref(pathName).getMetadata());
});

test("M01 Storage denies super_admin claim with inactive admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "admins", "super-admin-inactive"), {
      active: false,
      role: "super_admin",
      roles: ["super_admin"],
      updated_at: nowTs(),
    });
  });
  const pathName = await seedWalletReceipt();

  const storage = testEnv.authenticatedContext("super-admin-inactive", {
    super_admin: true,
    role: "super_admin",
  }).storage(bucketUrl);
  await assertFails(storage.ref(pathName).getMetadata());
});

test("M01 Storage allows super_admin claim with active admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "admins", "super-admin-active"), {
      active: true,
      role: "super_admin",
      roles: ["super_admin"],
      updated_at: nowTs(),
    });
  });
  const pathName = await seedWalletReceipt();

  const storage = testEnv.authenticatedContext("super-admin-active", {
    super_admin: true,
    role: "super_admin",
  }).storage(bucketUrl);
  await assertSucceeds(storage.ref(pathName).getMetadata());
});

test("W17 non-admin and other venue merchant cannot read wallet receipts", async () => {
  await seedData(async (db) => {
    await seedMerchantAndUser(db, "merchant-a", "venue-a");
    await seedMerchantAndUser(db, "merchant-b", "venue-b");
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminStorage = context.storage(bucketUrl);
    await adminStorage
      .ref("venues/venue-a/wallet_topups/proof-locked.jpg")
      .put(makeBytes(512), { contentType: "image/jpeg" });
  });

  const plainUserStorage = testEnv.authenticatedContext("user-a").storage(bucketUrl);
  await assertFails(
    plainUserStorage.ref("venues/venue-a/wallet_topups/proof-locked.jpg").getMetadata(),
  );

  const otherMerchantStorage = testEnv.authenticatedContext("merchant-b").storage(bucketUrl);
  await assertFails(
    otherMerchantStorage.ref("venues/venue-a/wallet_topups/proof-locked.jpg").getMetadata(),
  );
});
