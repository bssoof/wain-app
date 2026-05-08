const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-public-engagement";

const {
  calculateReviewRatingAggregate,
} = require("../lib/public_engagement.js");

test("calculateReviewRatingAggregate returns empty aggregate for no reviews", () => {
  assert.deepEqual(calculateReviewRatingAggregate([]), {
    rating: 0,
    review_count: 0,
  });
});

test("calculateReviewRatingAggregate averages ratings to one decimal", () => {
  assert.deepEqual(
    calculateReviewRatingAggregate([
      { rating: 5 },
      { rating: 4 },
      { rating: 3 },
    ]),
    {
      rating: 4,
      review_count: 3,
    },
  );
});

test("calculateReviewRatingAggregate keeps legacy missing ratings as zero", () => {
  assert.deepEqual(
    calculateReviewRatingAggregate([
      { rating: 5 },
      {},
    ]),
    {
      rating: 2.5,
      review_count: 2,
    },
  );
});
