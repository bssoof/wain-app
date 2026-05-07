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

test("D1b user can update only their own wallet notification preferences", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "users", "user-a"), {
      uid: "user-a",
      created_at: nowTs(),
      display_name: "User A",
      username: "usera",
    });
  });

  const db = testEnv.authenticatedContext("user-a").firestore();
  await assertSucceeds(updateDoc(doc(db, "users", "user-a"), {
    wallet_notifications_enabled: false,
    wallet_expiry_reminders_enabled: true,
    admin_wallet_notifications_enabled: false,
  }));
  await assertFails(updateDoc(doc(db, "users", "user-a"), {
    wallet_notifications_enabled: true,
    reviews_count: 9,
  }));
});

test("D1c another user cannot read or update wallet notification preferences", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "users", "user-a"), {
      uid: "user-a",
      created_at: nowTs(),
      wallet_notifications_enabled: true,
    });
  });

  const db = testEnv.authenticatedContext("user-b").firestore();
  await assertFails(getDoc(doc(db, "users", "user-a")));
  await assertFails(updateDoc(doc(db, "users", "user-a"), {
    wallet_notifications_enabled: false,
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

test("W1 merchant can read own wallet and requests", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "merchant_wallets", "venue-a"), {
      venue_id: "venue-a",
      currency: "ILS",
      status: "active",
      available_balance: 100,
      low_balance_threshold: 10,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_topup_requests", "request-a"), {
      venue_id: "venue-a",
      requested_by_uid: "merchant-a",
      amount: 100,
      currency: "ILS",
      status: "pending",
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertSucceeds(getDoc(doc(db, "merchant_wallets", "venue-a")));
  await assertSucceeds(getDoc(doc(db, "merchant_topup_requests", "request-a")));
});

test("W2 merchant cannot read wallet or top-up request for another venue", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "merchant_wallets", "venue-b"), {
      venue_id: "venue-b",
      currency: "ILS",
      status: "active",
      available_balance: 40,
      low_balance_threshold: 10,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_topup_requests", "request-b"), {
      venue_id: "venue-b",
      requested_by_uid: "merchant-b",
      amount: 80,
      currency: "ILS",
      status: "pending",
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(getDoc(doc(db, "merchant_wallets", "venue-b")));
  await assertFails(getDoc(doc(db, "merchant_topup_requests", "request-b")));
});

test("W2b merchant can read own ledger entry but not another venue entry", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "merchant_wallets", "venue-a"), {
      venue_id: "venue-a",
      currency: "ILS",
      status: "active",
      available_balance: 40,
      low_balance_threshold: 10,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_wallets", "venue-a", "entries", "entry-a"), {
      venue_id: "venue-a",
      type: "credit",
      amount: 10,
      currency: "ILS",
      balance_after: 40,
      created_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_wallets", "venue-b"), {
      venue_id: "venue-b",
      currency: "ILS",
      status: "active",
      available_balance: 70,
      low_balance_threshold: 10,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_wallets", "venue-b", "entries", "entry-b"), {
      venue_id: "venue-b",
      type: "debit",
      amount: 7,
      currency: "ILS",
      balance_after: 63,
      created_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertSucceeds(getDoc(doc(db, "merchant_wallets", "venue-a", "entries", "entry-a")));
  await assertFails(getDoc(doc(db, "merchant_wallets", "venue-b", "entries", "entry-b")));
});

test("W3 merchant cannot write wallet state or ledger entries", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "merchant_wallets", "venue-a"), {
      venue_id: "venue-a",
      currency: "ILS",
      status: "active",
      available_balance: 25,
      low_balance_threshold: 10,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(updateDoc(doc(db, "merchant_wallets", "venue-a"), {
    available_balance: 999,
  }));
  await assertFails(setDoc(doc(db, "merchant_wallets", "venue-a", "entries", "entry-a"), {
    venue_id: "venue-a",
    type: "credit",
    amount: 999,
    currency: "ILS",
    balance_after: 999,
    created_at: nowTs(),
  }));
});

test("W4 merchant cannot bypass callable and create top-up request directly", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(setDoc(doc(db, "merchant_topup_requests", "request-a"), {
    venue_id: "venue-a",
    requested_by_uid: "merchant-a",
    amount: 100,
    currency: "ILS",
    status: "pending",
    created_at: nowTs(),
    updated_at: nowTs(),
  }));
});

test("W4c merchant cannot client-update offer featured fields directly", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "offers", "offer-a"), {
      venue_id: "venue-a",
      title_ar: "Offer A",
      is_active: true,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(updateDoc(doc(db, "offers", "offer-a"), {
    is_featured: true,
    featured_until: nowTs(),
  }));
});

test("W4b non-admin non-merchant cannot read top-up review queue", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchant_topup_requests", "request-a"), {
      venue_id: "venue-a",
      requested_by_uid: "merchant-a",
      amount: 100,
      currency: "ILS",
      status: "pending",
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("user-a").firestore();
  await assertFails(getDocs(collection(db, "merchant_topup_requests")));
});

test("W4d merchant can read own wallet report only", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "merchant_wallet_reports", "venue-a"), {
      venue_id: "venue-a",
      total_credited: 100,
      total_debited: 30,
      last_30d_debited: 20,
      debit_by_feature: { story_promotion: 20, offer_pin: 10 },
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_wallet_reports", "venue-b"), {
      venue_id: "venue-b",
      total_credited: 90,
      total_debited: 40,
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertSucceeds(getDoc(doc(db, "merchant_wallet_reports", "venue-a")));
  await assertFails(getDoc(doc(db, "merchant_wallet_reports", "venue-b")));
});

test("W4e wallet audit events are admin-readable only", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "wallet_audit_events", "audit-1"), {
      event_type: "topup_request_approved",
      venue_id: "venue-a",
      request_id: "request-a",
      created_at: nowTs(),
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "admins", "admin-doc"), {
      active: true,
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const userDb = testEnv.authenticatedContext("user-a").firestore();
  await assertFails(getDoc(doc(userDb, "wallet_audit_events", "audit-1")));

  const adminDb = testEnv.authenticatedContext("admin-doc").firestore();
  await assertSucceeds(getDoc(doc(adminDb, "wallet_audit_events", "audit-1")));
});

test("M01 Firestore denies token.admin=true without active admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "app_config", "admin_step_up"), {
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("legacy-admin-no-doc", { admin: true }).firestore();
  await assertFails(getDoc(doc(db, "app_config", "admin_step_up")));
});

test("M01 Firestore denies token.admin=true with inactive admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "app_config", "admin_step_up"), {
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "admins", "legacy-admin-inactive"), {
      active: false,
      role: "finance_admin",
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("legacy-admin-inactive", { admin: true }).firestore();
  await assertFails(getDoc(doc(db, "app_config", "admin_step_up")));
});

test("M01 Firestore allows role=admin with active admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "app_config", "admin_step_up"), {
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "admins", "legacy-admin-active"), {
      active: true,
      role: "finance_admin",
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("legacy-admin-active", { role: "admin" }).firestore();
  await assertSucceeds(getDoc(doc(db, "app_config", "admin_step_up")));
});

test("M01 Firestore denies super_admin claim with inactive admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "admin_step_up_audit_events", "event-1"), {
      event_type: "admin_step_up_verified",
      created_at: nowTs(),
    });
    await setDoc(doc(db, "admins", "super-admin-inactive"), {
      active: false,
      role: "super_admin",
      roles: ["super_admin"],
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("super-admin-inactive", {
    super_admin: true,
    role: "super_admin",
  }).firestore();
  await assertFails(getDoc(doc(db, "admin_step_up_audit_events", "event-1")));
});

test("M01 Firestore allows super_admin claim with active admins document", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "admin_step_up_audit_events", "event-1"), {
      event_type: "admin_step_up_verified",
      created_at: nowTs(),
    });
    await setDoc(doc(db, "admins", "super-admin-active"), {
      active: true,
      role: "super_admin",
      roles: ["super_admin"],
      updated_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("super-admin-active", {
    super_admin: true,
    role: "super_admin",
  }).firestore();
  await assertSucceeds(getDoc(doc(db, "admin_step_up_audit_events", "event-1")));
});

test("W4f merchant cannot mutate reversal fields on own wallet entries", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "merchants", "merchant-a"), {
      uid: "merchant-a",
      venue_id: "venue-a",
    });
    await setDoc(doc(db, "merchant_wallets", "venue-a"), {
      venue_id: "venue-a",
      available_balance: 20,
      status: "active",
      currency: "ILS",
      created_at: nowTs(),
      updated_at: nowTs(),
    });
    await setDoc(doc(db, "merchant_wallets", "venue-a", "entries", "entry-a"), {
      venue_id: "venue-a",
      type: "debit",
      amount: 3,
      currency: "ILS",
      balance_after: 17,
      feature_key: "story_promotion",
      reference_type: "story",
      reference_id: "story-a",
      created_at: nowTs(),
    });
  });

  const db = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(updateDoc(doc(db, "merchant_wallets", "venue-a", "entries", "entry-a"), {
    reversed_at: nowTs(),
    reversed_by_uid: "merchant-a",
    reversal_entry_id: "reversal_entry-a",
  }));
});

test("W4g wallet notification dedupe events are server-only", async () => {
  await seedData(async (db) => {
    await setDoc(doc(db, "wallet_notification_events", "event-a"), {
      event_key: "event-a",
      user_uid: "merchant-a",
      type: "wallet_low_balance",
      created_at: nowTs(),
      updated_at: nowTs(),
    });
  });

  const merchantDb = testEnv.authenticatedContext("merchant-a").firestore();
  await assertFails(getDoc(doc(merchantDb, "wallet_notification_events", "event-a")));
  await assertFails(setDoc(doc(merchantDb, "wallet_notification_events", "event-b"), {
    event_key: "event-b",
    user_uid: "merchant-a",
    type: "wallet_low_balance",
    created_at: nowTs(),
    updated_at: nowTs(),
  }));
});
