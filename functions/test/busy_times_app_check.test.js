const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-analytics";

const { backfillVenueBusyTimes } = require("../lib/index.js");

test("backfillVenueBusyTimes rejects missing App Check", async () => {
  await assert.rejects(
    () =>
      backfillVenueBusyTimes.run(
        { venueId: "venue-busy-app-check" },
        { auth: { uid: "merchant-busy-app-check" } },
      ),
    (error) => {
      assert.equal(error.code, "failed-precondition");
      assert.match(error.message, /App Check/i);
      return true;
    },
  );
});
