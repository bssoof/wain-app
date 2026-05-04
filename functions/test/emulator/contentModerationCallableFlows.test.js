const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-content";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  listOffersForAdmin,
  listStoriesForAdmin,
  contentModerateOffer,
  contentModerateStory,
} = require("../../lib/index.js");

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

async function expectHttpsError(fn, codeOrCheck = null) {
  let threw = false;
  try {
    await fn();
  } catch (err) {
    threw = true;
    if (typeof codeOrCheck === "function") {
      assert.ok(codeOrCheck(err), `Error did not match custom check: ${err.message}`);
    } else if (typeof codeOrCheck === "string") {
      assert.ok(
        err.code === codeOrCheck || err.message.includes(codeOrCheck),
        `Expected error code or message to include "${codeOrCheck}", got code "${err.code}" and message "${err.message}"`
      );
    }
  }
  assert.equal(threw, true, "Expected function to throw an HttpsError");
}

test("Content Moderation Flow - Offers and Stories", async (t) => {
  if (process.env.SKIP_EMULATOR_TESTS === "true") {
    console.log("Skipping emulator tests.");
    return;
  }

  const venueId = "venue_test_1";
  const offerId = "offer_test_1";
  const storyId = "story_test_1";
  const extraOfferId = "offer_test_2";

  t.beforeEach(async () => {
    await clearFirestore();
    await db.collection("venues").doc(venueId).set({ name: "Test Venue" });
    await db.collection("offers").doc(offerId).set({
      venue_id: venueId,
      title: "Test Offer",
      is_active: true,
      admin_state: "pending",
    });
    await db.collection("stories").doc(storyId).set({
      venue_id: venueId,
      caption: "Test Story",
      is_active: true,
      admin_state: "pending",
    });
    await db.collection("offers").doc(extraOfferId).set({
      venue_id: venueId,
      title: "Approved Offer",
      is_active: true,
      admin_state: "approved",
    });
  });

  t.afterEach(async () => {
    await clearFirestore();
  });

  await t.test("CM01 - Content admin can approve an offer", async () => {
    const data = {
      offerId,
      venueId,
      action: "approve",
      reason: "quality_standard",
      commandId: "cmd_approve_1",
    };

    const result = await contentModerateOffer.run(data, {
      auth: { uid: "admin_123", token: { role: "content_admin", admin: true } },
      app: { appId: "mock_app", token: "mock_token" }
    });

    assert.equal(result.success, true);
    assert.equal(result.newAdminState, "approved");
    assert.equal(result.isActive, true);

    const doc = await db.collection("offers").doc(offerId).get();
    const docData = doc.data();
    assert.equal(docData.admin_state, "approved");
    assert.equal(docData.is_active, true);
    assert.equal(docData.moderation_reason, "quality_standard");
    assert.equal(docData.moderated_by_role, "content_admin");
  });

  await t.test("CM02 - Rejecting an offer forces is_active to false safely", async () => {
    const data = {
      offerId,
      venueId,
      action: "reject",
      reason: "policy_violation",
      commandId: "cmd_reject_1",
    };

    const result = await contentModerateOffer.run(data, {
      auth: { uid: "super_admin_888", token: { super_admin: true, admin: true } },
      app: { appId: "mock_app", token: "mock_token" }
    });

    assert.equal(result.success, true);
    assert.equal(result.newAdminState, "rejected");
    assert.equal(result.isActive, false);

    const doc = await db.collection("offers").doc(offerId).get();
    const docData = doc.data();
    assert.equal(docData.admin_state, "rejected");
    assert.equal(docData.is_active, false);
  });

  await t.test("CM03 - Finance admin cannot moderate", async () => {
    const data = {
      storyId,
      venueId,
      action: "approve",
      commandId: "cmd_approve_st_1",
    };

    await expectHttpsError(
      () => contentModerateStory.run(data, {
        auth: { uid: "fin_admin", token: { role: "finance_admin", admin: true } },
        app: { appId: "mock", token: "mock" }
      }),
      "content_role_not_authorized"
    );
  });

  await t.test("CM04 - Invalid or missing reason normalizes to 'other'", async () => {
    const data = {
      storyId,
      venueId,
      action: "flag",
      reason: "something_weird",
      commandId: "cmd_flag_st_1",
    };

    const result = await contentModerateStory.run(data, {
      auth: { uid: "admin_123", token: { role: "content_admin", admin: true } },
      app: { appId: "mock_app", token: "mock_token" }
    });

    assert.equal(result.success, true);
    assert.equal(result.newAdminState, "flagged");
    assert.equal(result.isActive, false);

    const doc = await db.collection("stories").doc(storyId).get();
    const docData = doc.data();
    assert.equal(docData.admin_state, "flagged");
    assert.equal(docData.moderation_reason, "other");
  });

  await t.test("CM05 - AppCheck is strictly required", async () => {
    const data = {
      offerId,
      venueId,
      action: "approve",
      commandId: "cmd_approve_no_ac",
    };

    await expectHttpsError(
      () => contentModerateOffer.run(data, {
        auth: { uid: "admin_123", token: { role: "content_admin", admin: true } }
      }),
      "App Check verification failed"
    );
  });

  await t.test("CM06 - Content admin can list offers with status filters", async () => {
    const result = await listOffersForAdmin.run(
      {
        venueId,
        statuses: ["pending"],
        limit: 10,
      },
      {
        auth: { uid: "admin_123", token: { role: "content_admin", admin: true } },
        app: { appId: "mock_app", token: "mock_token" },
      },
    );

    assert.equal(result.filtersApplied.venueId, venueId);
    assert.deepEqual(result.filtersApplied.statuses, ["pending"]);
    assert.equal(result.items.length, 1);
    assert.equal(result.items[0].id, offerId);
    assert.equal(result.items[0].adminState, "pending");
  });

  await t.test("CM07 - Finance admin cannot list stories for moderation", async () => {
    await expectHttpsError(
      () =>
        listStoriesForAdmin.run(
          { limit: 10 },
          {
            auth: { uid: "fin_admin", token: { role: "finance_admin", admin: true } },
            app: { appId: "mock_app", token: "mock_token" },
          },
        ),
      "content_role_not_authorized",
    );
  });

  await t.test("CM08 - Replaying the same offer command returns replay instead of duplicating", async () => {
    const data = {
      offerId,
      venueId,
      action: "approve",
      reason: "quality_standard",
      commandId: "cmd_offer_replay_1",
    };

    const firstResult = await contentModerateOffer.run(data, {
      auth: { uid: "admin_123", token: { role: "content_admin", admin: true } },
      app: { appId: "mock_app", token: "mock_token" },
    });
    const replayResult = await contentModerateOffer.run(data, {
      auth: { uid: "admin_123", token: { role: "content_admin", admin: true } },
      app: { appId: "mock_app", token: "mock_token" },
    });

    assert.equal(firstResult.replay, false);
    assert.equal(replayResult.replay, true);

    const commandDocs = await db
      .collection("content_governance_commands")
      .where("command_id", "==", "cmd_offer_replay_1")
      .get();
    assert.equal(commandDocs.size, 1);
  });

  await t.test("CM09 - Expected-state conflict is rejected explicitly", async () => {
    await expectHttpsError(
      () =>
        contentModerateStory.run(
          {
            storyId,
            venueId,
            action: "approve",
            reason: "quality_standard",
            commandId: "cmd_story_conflict_1",
            expectedState: {
              admin_state: "approved",
            },
          },
          {
            auth: { uid: "admin_123", token: { role: "content_admin", admin: true } },
            app: { appId: "mock_app", token: "mock_token" },
          },
        ),
      "content_expected_state_conflict",
    );
  });
});
