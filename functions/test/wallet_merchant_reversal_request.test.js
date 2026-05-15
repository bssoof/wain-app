const test = require("node:test");
const assert = require("node:assert/strict");
const { Timestamp } = require("firebase-admin/firestore");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-wallet";

class FakeDocumentSnapshot {
  constructor(ref, data) {
    this.ref = ref;
    this.id = ref.id;
    this.exists = data !== undefined;
    this._data = data;
  }

  data() {
    return this._data;
  }
}

class FakeDocumentReference {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    this.id = path.split("/").pop();
  }

  collection(name) {
    return new FakeCollectionReference(this._db, `${this.path}/${name}`);
  }

  async get() {
    return new FakeDocumentSnapshot(this, this._db.getData(this.path));
  }

  async set(data, options = {}) {
    this._db.setData(this.path, data, options);
  }

  async update(data) {
    this._db.updateData(this.path, data);
  }
}

class FakeCollectionReference {
  constructor(db, path) {
    this._db = db;
    this.path = path;
  }

  doc(id) {
    return new FakeDocumentReference(this._db, `${this.path}/${id ?? this._db.nextId()}`);
  }

  where(field, op, value) {
    return new FakeQuery(this._db, this.path, [{ field, op, value }]);
  }

  orderBy(field) {
    return new FakeQuery(this._db, this.path, [], field);
  }

  limit(count) {
    return new FakeQuery(this._db, this.path, [], null, count);
  }

  async get() {
    return new FakeQuery(this._db, this.path).get();
  }
}

class FakeQuery {
  constructor(db, path, filters = [], orderField = null, limitCount = null) {
    this._db = db;
    this.path = path;
    this._filters = filters;
    this._orderField = orderField;
    this._limitCount = limitCount;
  }

  where(field, op, value) {
    return new FakeQuery(
      this._db,
      this.path,
      [...this._filters, { field, op, value }],
      this._orderField,
      this._limitCount,
    );
  }

  orderBy(field) {
    return new FakeQuery(
      this._db,
      this.path,
      this._filters,
      field,
      this._limitCount,
    );
  }

  limit(count) {
    return new FakeQuery(
      this._db,
      this.path,
      this._filters,
      this._orderField,
      count,
    );
  }

  startAfter() {
    return this;
  }

  async get() {
    let docs = this._db.listCollectionDocs(this.path);
    for (const filter of this._filters) {
      if (filter.op !== "==") continue;
      docs = docs.filter((doc) => doc.data()?.[filter.field] === filter.value);
    }
    if (this._orderField) {
      docs = [...docs].sort((left, right) => left.id.localeCompare(right.id));
    }
    if (typeof this._limitCount === "number") {
      docs = docs.slice(0, this._limitCount);
    }
    return {
      docs,
      empty: docs.length === 0,
      size: docs.length,
    };
  }
}

class FakeTransaction {
  async get(ref) {
    return ref.get();
  }

  set(ref, data, options = {}) {
    ref._db.setData(ref.path, data, options);
  }

  update(ref, data) {
    ref._db.updateData(ref.path, data);
  }
}

class FakeFirestore {
  constructor() {
    this.reset();
  }

  reset() {
    this._store = new Map();
    this._nextId = 1;
  }

  nextId() {
    const id = `auto_${this._nextId}`;
    this._nextId += 1;
    return id;
  }

  collection(name) {
    return new FakeCollectionReference(this, name);
  }

  async getAll(...refs) {
    return refs.map((ref) => new FakeDocumentSnapshot(ref, this.getData(ref.path)));
  }

  async runTransaction(callback) {
    return callback(new FakeTransaction());
  }

  seed(path, data) {
    this._store.set(path, data);
  }

  getData(path) {
    return this._store.get(path);
  }

  listCollectionDocs(path) {
    const prefix = `${path}/`;
    return [...this._store.entries()]
      .filter(([docPath]) => {
        if (!docPath.startsWith(prefix)) return false;
        const remainder = docPath.slice(prefix.length);
        return remainder.length > 0 && !remainder.includes("/");
      })
      .map(([docPath, data]) => new FakeDocumentSnapshot(
        new FakeDocumentReference(this, docPath),
        data,
      ));
  }

  setData(path, data, options = {}) {
    if (options.merge === true) {
      this._store.set(path, {
        ...(this._store.get(path) ?? {}),
        ...data,
      });
      return;
    }
    this._store.set(path, data);
  }

  updateData(path, data) {
    const current = this._store.get(path);
    if (current === undefined) {
      throw new Error(`Missing document at ${path}`);
    }
    this._store.set(path, {
      ...current,
      ...data,
    });
  }
}

const fakeDb = new FakeFirestore();
const firestoreDbPath = require.resolve("../lib/shared/firestore-db.js");
require.cache[firestoreDbPath] = {
  id: firestoreDbPath,
  filename: firestoreDbPath,
  loaded: true,
  exports: { db: fakeDb },
};
const walletNotificationsPath = require.resolve("../lib/shared/wallet-notifications.js");
require.cache[walletNotificationsPath] = {
  id: walletNotificationsPath,
  filename: walletNotificationsPath,
  loaded: true,
  exports: {
    formatCurrencyAmount: (amount, currency = "ILS") => `${amount.toFixed(2)} ${currency}`,
    sendWalletAdminNotification: async () => 0,
    sendWalletMerchantNotification: async () => 0,
  },
};

const {
  approveWalletReversalRequest,
  createMerchantWalletReversalRequest,
  reviewMerchantWalletReversalRequest,
} = require("../lib/wallet_runtime_mutations.js");

function merchantContext(uid = "merchant-1") {
  return {
    auth: { uid, token: {} },
    app: { appId: "unit-app" },
  };
}

function adminContext(uid = "admin-1") {
  return {
    auth: { uid, token: { admin: true } },
    app: { appId: "unit-app" },
  };
}

function seedValidReversalFixture(overrides = {}) {
  fakeDb.reset();
  fakeDb.seed("merchants/merchant-1", { venue_id: "venue_1", uid: "merchant-1" });
  fakeDb.seed("merchant_wallets/venue_1", { status: "active", currency: "ILS" });
  fakeDb.seed("merchant_wallets/venue_1/entries/entry_1", {
    venue_id: "venue_1",
    type: "debit",
    amount: 150,
    currency: "ILS",
    feature_key: "story_promotion",
    reference_type: "story",
    reference_id: "story_1",
    ...overrides.entry,
  });
  if (overrides.request) {
    fakeDb.seed("wallet_reversal_requests/merchant_review_entry_1", overrides.request);
  }
}

function seedAdmin(uid = "admin-1", role = "finance_admin") {
  fakeDb.seed(`admins/${uid}`, { active: true, role });
}

async function createPendingMerchantReview({
  amount = 80,
  entryOverrides = {},
} = {}) {
  seedValidReversalFixture({
    entry: {
      amount,
      ...entryOverrides,
    },
  });
  const result = await createMerchantWalletReversalRequest.run(
    {
      entryId: "entry_1",
      venueId: "venue_1",
      reason: "charge disputed by merchant",
      merchantNote: "please review",
    },
    merchantContext(),
  );
  return result.requestId;
}

async function expectHttpsError(action, code, message) {
  await assert.rejects(action, (error) => {
    assert.equal(error.code, code);
    assert.equal(error.message, message);
    return true;
  });
}

test("merchant reversal request creates a pending review document", async () => {
  seedValidReversalFixture();

  const result = await createMerchantWalletReversalRequest.run(
    {
      entryId: "entry_1",
      venueId: "venue_1",
      reason: "charge disputed",
      merchantNote: "please review",
    },
    merchantContext(),
  );

  assert.deepEqual(result, {
    success: true,
    requestId: "merchant_review_entry_1",
    status: "pending_review",
  });

  const request = fakeDb.getData("wallet_reversal_requests/merchant_review_entry_1");
  assert.equal(request.source, "merchant");
  assert.equal(request.status, "pending_review");
  assert.equal(request.original_amount, 150);
  assert.equal(request.original_feature_key, "story_promotion");
  assert.equal(request.requested_by_uid, "merchant-1");
  assert.equal(request.merchant_user_role, null);
  assert.equal(request.reason, "charge disputed");
  assert.equal(request.merchant_note, "please review");
  assert.equal(request.reviewed_by_uid, null);
  assert.equal(request.required_second_approver_role, null);
  assert.equal(request.expires_at, null);

  const audit = fakeDb.getData("wallet_audit_events/merchant_review_entry_1");
  assert.equal(audit.event_type, "merchant_review_requested");
  assert.equal(audit.request_id, "merchant_review_entry_1");
});

test("merchant reversal request denies users without merchant document", async () => {
  fakeDb.reset();

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: "review" },
      merchantContext("user-1"),
    ),
    "permission-denied",
    "not_a_merchant",
  );
});

test("merchant reversal request denies venue mismatch", async () => {
  seedValidReversalFixture();

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_2", reason: "review" },
      merchantContext(),
    ),
    "permission-denied",
    "merchant_venue_mismatch",
  );
});

test("merchant reversal request returns entry_not_found for missing entry", async () => {
  fakeDb.reset();
  fakeDb.seed("merchants/merchant-1", { venue_id: "venue_1" });
  fakeDb.seed("merchant_wallets/venue_1", { status: "active", currency: "ILS" });

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: "review" },
      merchantContext(),
    ),
    "not-found",
    "entry_not_found",
  );
});

test("merchant reversal request rejects credit entries", async () => {
  seedValidReversalFixture({ entry: { type: "credit" } });

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: "review" },
      merchantContext(),
    ),
    "failed-precondition",
    "reversal_only_for_debit",
  );
});

test("merchant reversal request rejects unsupported feature keys", async () => {
  seedValidReversalFixture({ entry: { feature_key: "manual_adjustment" } });

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: "review" },
      merchantContext(),
    ),
    "failed-precondition",
    "unsupported_reversal_feature",
  );
});

test("merchant reversal request rejects already reversed entries", async () => {
  seedValidReversalFixture({ entry: { reversal_entry_id: "reversal_entry_1" } });

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: "review" },
      merchantContext(),
    ),
    "failed-precondition",
    "entry_already_reversed",
  );
});

test("merchant reversal request rejects duplicate open reviews", async () => {
  seedValidReversalFixture({
    request: {
      status: "pending_review",
    },
  });

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: "review" },
      merchantContext(),
    ),
    "failed-precondition",
    "merchant_review_already_open",
  );
});

test("merchant reversal request requires a reason", async () => {
  seedValidReversalFixture();

  await expectHttpsError(
    () => createMerchantWalletReversalRequest.run(
      { entryId: "entry_1", venueId: "venue_1", reason: " " },
      merchantContext(),
    ),
    "invalid-argument",
    "invalid_merchant_review_arguments",
  );
});

test("merchant reversal review rejects pending request with reason", async () => {
  const requestId = await createPendingMerchantReview();
  seedAdmin();

  const result = await reviewMerchantWalletReversalRequest.run(
    {
      requestId,
      decision: "reject",
      rejectionReason: "not eligible",
      adminNote: "Reviewed by finance",
    },
    adminContext(),
  );

  assert.deepEqual(result, { success: true, status: "rejected" });
  const request = fakeDb.getData(`wallet_reversal_requests/${requestId}`);
  assert.equal(request.status, "rejected");
  assert.equal(request.admin_decision, "rejected");
  assert.equal(request.rejection_reason, "not eligible");
  assert.equal(request.reviewed_by_uid, "admin-1");
  assert.equal(request.reviewed_by_role, "finance_admin");
});

test("merchant reversal review requires rejection reason", async () => {
  const requestId = await createPendingMerchantReview();
  seedAdmin();

  await expectHttpsError(
    () => reviewMerchantWalletReversalRequest.run(
      { requestId, decision: "reject", rejectionReason: " " },
      adminContext(),
    ),
    "invalid-argument",
    "rejection_reason_required",
  );
});

test("merchant reversal review approves small amounts and executes reversal", async () => {
  const requestId = await createPendingMerchantReview({ amount: 80 });
  seedAdmin();

  const result = await reviewMerchantWalletReversalRequest.run(
    { requestId, decision: "approve", adminNote: "valid dispute" },
    adminContext(),
  );

  assert.equal(result.success, true);
  assert.equal(result.status, "approved_and_executed");
  assert.equal(result.reversalEntryId, "reversal_entry_1");

  const wallet = fakeDb.getData("merchant_wallets/venue_1");
  const originalEntry = fakeDb.getData("merchant_wallets/venue_1/entries/entry_1");
  const reversalEntry = fakeDb.getData("merchant_wallets/venue_1/entries/reversal_entry_1");
  const request = fakeDb.getData(`wallet_reversal_requests/${requestId}`);
  assert.equal(wallet.available_balance, 80);
  assert.equal(originalEntry.reversal_entry_id, "reversal_entry_1");
  assert.equal(reversalEntry.type, "credit");
  assert.equal(reversalEntry.amount, 80);
  assert.equal(request.status, "approved_and_executed");
  assert.equal(request.reversal_entry_id, "reversal_entry_1");
});

test("merchant reversal review approves larger amounts into second approval", async () => {
  const requestId = await createPendingMerchantReview({ amount: 150 });
  seedAdmin();

  const result = await reviewMerchantWalletReversalRequest.run(
    { requestId, decision: "approve" },
    adminContext(),
  );

  assert.equal(result.success, true);
  assert.equal(result.status, "pending_second_approval");
  assert.equal(result.requiredSecondApproverRole, "finance_admin");
  assert.equal(typeof result.approvalExpiresAt, "number");

  const request = fakeDb.getData(`wallet_reversal_requests/${requestId}`);
  assert.equal(request.status, "pending_second_approval");
  assert.equal(request.reviewed_by_uid, "admin-1");
  assert.equal(request.required_second_approver_role, "finance_admin");
  assert.ok(request.expires_at);
});

test("merchant reversal review requires super admin second approval above threshold", async () => {
  const requestId = await createPendingMerchantReview({ amount: 600 });
  seedAdmin();

  const result = await reviewMerchantWalletReversalRequest.run(
    { requestId, decision: "approve" },
    adminContext(),
  );

  assert.equal(result.status, "pending_second_approval");
  assert.equal(result.requiredSecondApproverRole, "super_admin");
});

test("merchant reversal review rejects non-pending requests", async () => {
  const requestId = await createPendingMerchantReview();
  seedAdmin();
  await reviewMerchantWalletReversalRequest.run(
    { requestId, decision: "reject", rejectionReason: "not eligible" },
    adminContext(),
  );

  await expectHttpsError(
    () => reviewMerchantWalletReversalRequest.run(
      { requestId, decision: "approve" },
      adminContext(),
    ),
    "failed-precondition",
    "request_not_pending_review",
  );
});

test("merchant reversal review rejects missing requests", async () => {
  fakeDb.reset();
  seedAdmin();

  await expectHttpsError(
    () => reviewMerchantWalletReversalRequest.run(
      { requestId: "merchant_review_missing", decision: "approve" },
      adminContext(),
    ),
    "not-found",
    "request_not_found",
  );
});

test("merchant reversal review denies admin without finance execution role", async () => {
  const requestId = await createPendingMerchantReview();
  seedAdmin("admin-1", "support_admin");

  await expectHttpsError(
    () => reviewMerchantWalletReversalRequest.run(
      { requestId, decision: "approve" },
      adminContext(),
    ),
    "permission-denied",
    "Requires active admin role",
  );
});

test("merchant reversal review revalidates already reversed entry", async () => {
  const requestId = await createPendingMerchantReview();
  seedAdmin();
  fakeDb.updateData("merchant_wallets/venue_1/entries/entry_1", {
    reversal_entry_id: "reversal_entry_1",
  });

  await expectHttpsError(
    () => reviewMerchantWalletReversalRequest.run(
      { requestId, decision: "approve" },
      adminContext(),
    ),
    "failed-precondition",
    "entry_already_reversed",
  );
});

test("approveWalletReversalRequest completes merchant second approval by requestId", async () => {
  const requestId = await createPendingMerchantReview({ amount: 150 });
  seedAdmin("admin-1", "finance_admin");
  seedAdmin("admin-2", "finance_admin");

  await reviewMerchantWalletReversalRequest.run(
    { requestId, decision: "approve" },
    adminContext("admin-1"),
  );

  const result = await approveWalletReversalRequest.run(
    {
      requestId,
      commandId: "approve_merchant_review_1",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    },
    adminContext("admin-2"),
  );

  assert.equal(result.success, true);
  assert.equal(result.status, "approved_and_executed");
  assert.equal(result.executedReversalEntryId, "reversal_entry_1");

  const request = fakeDb.getData(`wallet_reversal_requests/${requestId}`);
  assert.equal(request.status, "approved_and_executed");
  assert.equal(request.reversal_entry_id, "reversal_entry_1");
  assert.equal(request.approved_by_uid, "admin-2");
});

test("approveWalletReversalRequest preserves admin request approval by reversalRequestId", async () => {
  seedValidReversalFixture({ entry: { amount: 150 } });
  seedAdmin("admin-1", "finance_admin");
  seedAdmin("admin-2", "finance_admin");
  fakeDb.seed("wallet_reversal_requests/reversal_request_entry_1", {
    request_id: "reversal_request_entry_1",
    venue_id: "venue_1",
    entry_id: "entry_1",
    status: "pending_second_approval",
    requested_by_uid: "admin-1",
    requested_by_role: "finance_admin",
    required_second_approver_role: "finance_admin",
    original_amount: 150,
    reason: "admin reversal",
    expires_at: Timestamp.fromMillis(Date.now() + 60_000),
  });

  const result = await approveWalletReversalRequest.run(
    {
      reversalRequestId: "reversal_request_entry_1",
      commandId: "approve_admin_request_1",
      expectedState: {
        approval_state: "pending_second_approval",
        request_not_expired: true,
      },
    },
    adminContext("admin-2"),
  );

  assert.equal(result.success, true);
  assert.equal(result.status, "approved_and_executed");
  assert.equal(result.executedReversalEntryId, "reversal_entry_1");

  const request = fakeDb.getData("wallet_reversal_requests/reversal_request_entry_1");
  assert.equal(request.status, "approved_and_executed");
  assert.equal(request.approved_by_uid, "admin-2");
});
