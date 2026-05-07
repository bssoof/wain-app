const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-admin-config";

const {
  getAdminConfigGovernanceBundle,
  configUpsertDraft,
  configReviewDraft,
  configPublishDraft,
  configRollbackVersion,
} = require("../lib/admin_config.js");

function financeAdminContext() {
  return {
    auth: {
      uid: "finance-admin-1",
      token: {
        admin: true,
        role: "finance_admin",
        finance_admin: true,
      },
    },
    app: {
      appId: "unit-app",
    },
  };
}

async function expectConfigGovernanceDenied(action) {
  await assert.rejects(action, (error) => {
    assert.equal(error.code, "permission-denied");
    assert.match(error.message, /config governance restricted to super_admin/);
    return true;
  });
}

test("admin config governance denies finance_admin on getAdminConfigGovernanceBundle", async () => {
  await expectConfigGovernanceDenied(() =>
    getAdminConfigGovernanceBundle.run({ historyLimit: 1 }, financeAdminContext()),
  );
});

test("admin config governance denies finance_admin on configUpsertDraft", async () => {
  await expectConfigGovernanceDenied(() =>
    configUpsertDraft.run(
      {
        commandId: "unit_config_upsert",
        reason: "unit_denied",
        pricing: {},
      },
      financeAdminContext(),
    ),
  );
});

test("admin config governance denies finance_admin on configReviewDraft", async () => {
  await expectConfigGovernanceDenied(() =>
    configReviewDraft.run(
      {
        commandId: "unit_config_review",
        reason: "unit_denied",
        expectedState: {
          draft_status: "drafted",
        },
      },
      financeAdminContext(),
    ),
  );
});

test("admin config governance denies finance_admin on configPublishDraft", async () => {
  await expectConfigGovernanceDenied(() =>
    configPublishDraft.run(
      {
        commandId: "unit_config_publish",
        reason: "unit_denied",
        expectedState: {
          draft_status: "reviewed",
          target_live_version: 0,
        },
      },
      financeAdminContext(),
    ),
  );
});

test("admin config governance denies finance_admin on configRollbackVersion", async () => {
  await expectConfigGovernanceDenied(() =>
    configRollbackVersion.run(
      {
        commandId: "unit_config_rollback",
        reason: "unit_denied",
        rollbackToVersion: 1,
        expectedState: {
          current_live_version: 1,
        },
      },
      financeAdminContext(),
    ),
  );
});
