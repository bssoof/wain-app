const test = require("node:test");
const assert = require("node:assert/strict");

const {
  conversionRate,
  dayKeyInTimezone,
  bucketAnalyticsByDay,
} = require("../lib/analytics_helpers");

test("conversionRate protects division-by-zero", () => {
  assert.equal(conversionRate(5, 0), 0);
  assert.equal(conversionRate(5, -3), 0);
  assert.equal(conversionRate(3, 6), 0.5);
});

test("dayKeyInTimezone buckets by Asia/Jerusalem local date", () => {
  const utcDate = new Date("2026-02-15T22:30:00.000Z"); // 00:30 local on Feb 16
  assert.equal(dayKeyInTimezone(utcDate, "Asia/Jerusalem"), "2026-02-16");
});

test("bucketAnalyticsByDay aggregates daily buckets and WoW boundaries", () => {
  const result = bucketAnalyticsByDay({
    nowDate: new Date("2026-02-16T12:00:00.000Z"), // Monday
    lookbackDays: 3,
    timeZone: "Asia/Jerusalem",
    events: [
      { eventType: "view", at: new Date("2026-02-15T22:30:00.000Z") }, // Monday local
      { eventType: "call", at: new Date("2026-02-15T21:30:00.000Z") }, // Sunday local
      { eventType: "story_view", at: new Date("2026-02-16T05:00:00.000Z") }, // Monday local
    ],
    navigationClicks: [
      new Date("2026-02-15T23:10:00.000Z"), // Monday local
    ],
  });

  assert.equal(result.todayKey, "2026-02-16");

  const monday = result.dailyBuckets.get("2026-02-16");
  const sunday = result.dailyBuckets.get("2026-02-15");

  assert.ok(monday);
  assert.ok(sunday);
  assert.equal(monday.views, 1);
  assert.equal(monday.calls, 0);
  assert.equal(monday.story_views, 1);
  assert.equal(monday.navs, 1);
  assert.equal(monday.offer_detail_views, 0);
  assert.equal(monday.claim_clicks, 0);
  assert.equal(monday.claims_created, 0);
  assert.equal(monday.redemptions, 0);

  assert.equal(sunday.views, 0);
  assert.equal(sunday.calls, 1);
  assert.equal(sunday.story_views, 0);
  assert.equal(sunday.navs, 0);
  assert.equal(sunday.offer_detail_views, 0);
  assert.equal(sunday.claim_clicks, 0);
  assert.equal(sunday.claims_created, 0);
  assert.equal(sunday.redemptions, 0);

  // Week starts on Monday in helper logic.
  assert.equal(result.viewsThisWeek, 1);
  assert.equal(result.viewsLastWeek, 0);
  assert.equal(result.callsThisWeek, 0);
  assert.equal(result.callsLastWeek, 1);
  assert.equal(result.navsThisWeek, 1);
  assert.equal(result.navsLastWeek, 0);
  assert.equal(result.storyViewsThisWeek, 1);
});

test("bucketAnalyticsByDay tracks additive offer metrics across rolling 7d windows", () => {
  const result = bucketAnalyticsByDay({
    nowDate: new Date("2026-02-16T12:00:00.000Z"),
    lookbackDays: 14,
    timeZone: "Asia/Jerusalem",
    events: [
      { eventType: "offer_detail_view", at: new Date("2026-02-15T12:00:00.000Z") },
      { eventType: "offer_claim_click", at: new Date("2026-02-15T13:00:00.000Z") },
      { eventType: "offer_claim_created", at: new Date("2026-02-08T12:00:00.000Z") },
      { eventType: "offer_redeemed", at: new Date("2026-02-08T13:00:00.000Z") },
      { eventType: "noise", at: new Date("2026-02-15T14:00:00.000Z") },
    ],
    navigationClicks: [],
  });

  const currentDay = result.dailyBuckets.get("2026-02-15");
  const prevDay = result.dailyBuckets.get("2026-02-08");

  assert.ok(currentDay);
  assert.ok(prevDay);
  assert.equal(currentDay.offer_detail_views, 1);
  assert.equal(currentDay.claim_clicks, 1);
  assert.equal(currentDay.claims_created, 0);
  assert.equal(currentDay.redemptions, 0);
  assert.equal(prevDay.offer_detail_views, 0);
  assert.equal(prevDay.claim_clicks, 0);
  assert.equal(prevDay.claims_created, 1);
  assert.equal(prevDay.redemptions, 1);

  assert.equal(result.offerDetailViews7d, 1);
  assert.equal(result.offerDetailViewsPrev7d, 0);
  assert.equal(result.claimClicks7d, 1);
  assert.equal(result.claimClicksPrev7d, 0);
  assert.equal(result.claimsCreated7d, 0);
  assert.equal(result.claimsCreatedPrev7d, 1);
  assert.equal(result.redemptions7d, 0);
  assert.equal(result.redemptionsPrev7d, 1);
});

test("bucketAnalyticsByDay treats non-positive lookback as 1 day", () => {
  const result = bucketAnalyticsByDay({
    nowDate: new Date("2026-02-16T12:00:00.000Z"),
    lookbackDays: 0,
    events: [],
    navigationClicks: [],
  });

  assert.equal(result.dailyBuckets.size, 1);
  assert.ok(result.dailyBuckets.has("2026-02-16"));
});
