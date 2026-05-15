const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-story-smoke";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  aggregateVenueAnalytics,
  trackVenueEvent,
} = require("../../lib/index.js");
const {
  dayKeyInTimezone,
} = require("../../lib/analytics_helpers.js");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
const timezone = "Asia/Jerusalem";

function callableContext({ uid = "user-story-smoke", appCheck = true } = {}) {
  return {
    auth: uid ? { uid, token: {} } : null,
    app: appCheck ? { appId: "emu-app" } : undefined,
  };
}

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

async function seedSmokeData() {
  const now = admin.firestore.Timestamp.now();
  await db.collection("merchants").doc("merchant-story-smoke").set({
    uid: "merchant-story-smoke",
    venue_id: "venue-story-smoke",
  });
  await db.collection("users").doc("merchant-story-smoke").set({
    is_merchant: true,
    merchant_venue_id: "venue-story-smoke",
  });
  await db.collection("venues").doc("venue-story-smoke").set({
    name: "Story Smoke Venue",
    name_ar: "جهة اختبار الستوري",
    is_active: true,
    visibility: "public",
  });

  await db.collection("stories").doc("story-smoke-1").set({
    venue_id: "venue-story-smoke",
    venue_name: "Story Smoke Venue",
    status: "published",
    view_count: 0,
    created_at: now,
  });
  await db.collection("stories").doc("story-smoke-2").set({
    venue_id: "venue-story-smoke",
    venue_name: "Story Smoke Venue",
    status: "published",
    view_count: 0,
    created_at: now,
  });
}

async function simulateStoryView(storyId) {
  await db.collection("stories").doc(storyId).update({
    view_count: admin.firestore.FieldValue.increment(1),
  });
  await trackVenueEvent.run(
    {
      venueId: "venue-story-smoke",
      eventType: "story_view",
      source: "story_viewer",
      storyId,
    },
    callableContext(),
  );
}

async function simulateVenueVisitFromStory({ storyId, firstAttribution }) {
  await trackVenueEvent.run(
    {
      venueId: "venue-story-smoke",
      eventType: "view",
      source: firstAttribution ? "story_viewer" : "venue_details",
      ...(firstAttribution ? { storyId } : {}),
    },
    callableContext(),
  );
}

async function eventsMatching(whereClauses) {
  let query = db.collection("venue_events");
  for (const [field, value] of whereClauses) {
    query = query.where(field, "==", value);
  }
  const snap = await query.get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

test.before(async () => {
  await clearFirestore();
});

test.after(async () => {
  await clearFirestore();
});

test("manual smoke: story attribution funnel end-to-end", async () => {
  await clearFirestore();
  await seedSmokeData();

  // Mandatory scenario, steps 3-7:
  // User views story #1, opens venue from it, then repeats the tap in the same session.
  await simulateStoryView("story-smoke-1");
  const story1AfterView = await db.collection("stories").doc("story-smoke-1").get();
  assert.equal(story1AfterView.data().view_count, 1);

  await simulateVenueVisitFromStory({
    storyId: "story-smoke-1",
    firstAttribution: true,
  });

  const storyAttributedViews = await eventsMatching([
    ["venue_id", "venue-story-smoke"],
    ["event_type", "view"],
    ["source", "story_viewer"],
  ]);
  assert.equal(storyAttributedViews.length, 1);
  assert.equal(storyAttributedViews[0].story_id, "story-smoke-1");

  await simulateVenueVisitFromStory({
    storyId: "story-smoke-1",
    firstAttribution: false,
  });

  const regularViews = await eventsMatching([
    ["venue_id", "venue-story-smoke"],
    ["event_type", "view"],
    ["source", "venue_details"],
  ]);
  assert.equal(regularViews.length, 1);
  assert.equal(Object.prototype.hasOwnProperty.call(regularViews[0], "story_id"), false);

  // Mandatory scenario, steps 8-9:
  await aggregateVenueAnalytics.run();

  const mandatorySummarySnap = await db
    .collection("venue_analytics")
    .doc("venue-story-smoke")
    .get();
  assert.equal(mandatorySummarySnap.exists, true);
  const mandatorySummary = mandatorySummarySnap.data();
  assert.equal(mandatorySummary.story_to_venue_views_total, 1);
  assert.equal(mandatorySummary.story_to_venue_views_this_week, 1);
  assert.equal(mandatorySummary.story_to_venue_views_7d, 1);
  assert.equal(mandatorySummary.story_views_total, 1);
  assert.equal(mandatorySummary.views_total, 1);

  const todayKey = dayKeyInTimezone(new Date(), timezone);
  const mandatoryDaySnap = await db
    .collection("venue_analytics_daily")
    .doc("venue-story-smoke")
    .collection("days")
    .doc(todayKey)
    .get();
  assert.equal(mandatoryDaySnap.exists, true);
  const mandatoryDay = mandatoryDaySnap.data();
  assert.equal(mandatoryDay.story_to_venue_views, 1);
  assert.equal(mandatoryDay.story_views, 1);
  assert.equal(mandatoryDay.views, 1);

  // Edge 1: viewing a story without pressing visit increases exposure only.
  await simulateStoryView("story-smoke-2");
  const story2AfterView = await db.collection("stories").doc("story-smoke-2").get();
  assert.equal(story2AfterView.data().view_count, 1);
  const story2AttributedBeforeClick = await eventsMatching([
    ["venue_id", "venue-story-smoke"],
    ["event_type", "view"],
    ["source", "story_viewer"],
    ["story_id", "story-smoke-2"],
  ]);
  assert.equal(story2AttributedBeforeClick.length, 0);

  // Edge 2: clicking from a different story creates a distinct story_id attribution.
  await simulateVenueVisitFromStory({
    storyId: "story-smoke-2",
    firstAttribution: true,
  });
  const story2AttributedAfterClick = await eventsMatching([
    ["venue_id", "venue-story-smoke"],
    ["event_type", "view"],
    ["source", "story_viewer"],
    ["story_id", "story-smoke-2"],
  ]);
  assert.equal(story2AttributedAfterClick.length, 1);

  // Edge 3: a new app session can attribute the same story again.
  await simulateVenueVisitFromStory({
    storyId: "story-smoke-1",
    firstAttribution: true,
  });

  await aggregateVenueAnalytics.run();
  const finalSummarySnap = await db
    .collection("venue_analytics")
    .doc("venue-story-smoke")
    .get();
  const finalSummary = finalSummarySnap.data();
  assert.equal(finalSummary.story_to_venue_views_total, 3);
  assert.equal(finalSummary.story_views_total, 2);
  assert.equal(finalSummary.views_total, 1);

  const finalDaySnap = await db
    .collection("venue_analytics_daily")
    .doc("venue-story-smoke")
    .collection("days")
    .doc(todayKey)
    .get();
  const finalDay = finalDaySnap.data();
  assert.equal(finalDay.story_to_venue_views, 3);
  assert.equal(finalDay.story_views, 2);
  assert.equal(finalDay.views, 1);
});
