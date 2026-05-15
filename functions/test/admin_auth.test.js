const test = require("node:test");
const assert = require("node:assert/strict");

const {
  requireAdminAccessWithDb,
  requireMerchantVenueAccess,
  resolveAdminExecutionRole,
} = require("../lib/shared/admin-auth.js");

function callableContext(uid, token = {}) {
  return {
    auth: {
      uid,
      token,
    },
  };
}

function dbWithAdminDoc(adminData) {
  return {
    collection(name) {
      assert.equal(name, "admins");
      return {
        doc(uid) {
          assert.ok(uid);
          return {
            async get() {
              return {
                exists: adminData != null,
                data: () => adminData,
              };
            },
          };
        },
      };
    },
  };
}

function dbWithMerchantDoc(merchantData) {
  return {
    collection(name) {
      assert.equal(name, "merchants");
      return {
        doc(uid) {
          assert.ok(uid);
          return {
            async get() {
              return {
                exists: merchantData != null,
                data: () => merchantData,
              };
            },
          };
        },
      };
    },
  };
}

async function expectPermissionDenied(action) {
  await assert.rejects(action, (error) => {
    assert.equal(error.code, "permission-denied");
    return true;
  });
}

test("admin auth denies token.admin=true without admins document", async () => {
  await expectPermissionDenied(() =>
    requireAdminAccessWithDb(
      callableContext("legacy-admin", { admin: true }),
      dbWithAdminDoc(null),
    ),
  );
});

test("admin auth denies token.admin=true when admins document is inactive", async () => {
  await expectPermissionDenied(() =>
    requireAdminAccessWithDb(
      callableContext("legacy-admin", { admin: true }),
      dbWithAdminDoc({ active: false, role: "finance_admin" }),
    ),
  );
});

test("admin auth allows role=admin only with active admins document role", async () => {
  const context = callableContext("legacy-admin", { role: "admin" });
  const access = await requireAdminAccessWithDb(
    context,
    dbWithAdminDoc({ active: true, role: "finance_admin" }),
  );

  assert.deepEqual(access, {
    uid: "legacy-admin",
    source: "document",
    role: "finance_admin",
  });
  assert.equal(resolveAdminExecutionRole(context, access), "finance_admin");
});

test("admin auth denies super_admin claim when admins document is inactive", async () => {
  await expectPermissionDenied(() =>
    requireAdminAccessWithDb(
      callableContext("super-admin", { super_admin: true, role: "super_admin" }),
      dbWithAdminDoc({ active: false, role: "super_admin" }),
    ),
  );
});

test("admin auth allows super_admin claim with active admins document", async () => {
  const context = callableContext("super-admin", { super_admin: true, role: "super_admin" });
  const access = await requireAdminAccessWithDb(
    context,
    dbWithAdminDoc({ active: true }),
  );

  assert.deepEqual(access, {
    uid: "super-admin",
    source: "document",
    role: null,
  });
  assert.equal(resolveAdminExecutionRole(context, access), "super_admin");
});

test("merchant auth returns the merchants venue link", async () => {
  const access = await requireMerchantVenueAccess(
    callableContext("merchant-1"),
    dbWithMerchantDoc({ venue_id: " venue_1 " }),
  );

  assert.deepEqual(access, {
    uid: "merchant-1",
    venueId: "venue_1",
    merchantUserRole: null,
  });
});

test("merchant auth denies users without merchants document", async () => {
  await assert.rejects(
    () => requireMerchantVenueAccess(callableContext("user-1"), dbWithMerchantDoc(null)),
    (error) => {
      assert.equal(error.code, "permission-denied");
      assert.equal(error.message, "not_a_merchant");
      return true;
    },
  );
});

test("merchant auth requires an assigned venue", async () => {
  await assert.rejects(
    () => requireMerchantVenueAccess(callableContext("merchant-1"), dbWithMerchantDoc({ venue_id: " " })),
    (error) => {
      assert.equal(error.code, "failed-precondition");
      assert.equal(error.message, "merchant_venue_not_assigned");
      return true;
    },
  );
});
