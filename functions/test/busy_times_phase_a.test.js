const test = require("node:test");
const assert = require("node:assert/strict");
const { Timestamp } = require("firebase-admin/firestore");

const {
  BUSY_TIMES_SCHEMA_VERSION,
  buildInsufficientBusyTimesDoc,
  bucketSignalsToHistogram,
  computeCurrentTypicalLabel,
  dedupeSignals,
  determineInsufficientReason,
  doesHourBucketOverlapOpeningHours,
  isLocalTimeWithinOpeningHours,
  normalizeOpeningHours,
  resolveAuthorizedBackfillVenueId,
  resolveVenueTimezone,
} = require("../lib/busy_times");

test("resolveVenueTimezone prefers venue timezone, then city, then default", () => {
  const explicit = resolveVenueTimezone({
    venueTimezone: "Asia/Jerusalem",
    venueCity: "Tel Aviv-Yafo",
  });
  assert.equal(explicit.timezone, "Asia/Jerusalem");
  assert.equal(explicit.source, "venue");

  const cityFallback = resolveVenueTimezone({
    venueCity: "رام الله",
    defaultTimezone: "UTC",
  });
  assert.equal(cityFallback.timezone, "Asia/Jerusalem");
  assert.equal(cityFallback.source, "city");

  const defaultFallback = resolveVenueTimezone({
    venueCity: "Unknown City",
    defaultTimezone: "UTC",
  });
  assert.equal(defaultFallback.timezone, "UTC");
  assert.equal(defaultFallback.source, "default");
});

test("normalizeOpeningHours supports overnight windows and 24h venues", () => {
  const overnight = normalizeOpeningHours({
    hours: {
      monday: [{ open: "18:00", close: "02:00", spans_midnight: true }],
    },
  });

  assert.equal(overnight.insufficientReason, null);
  assert.ok(overnight.openingHours);
  assert.equal(
    isLocalTimeWithinOpeningHours("monday", 23 * 60 + 30, overnight.openingHours),
    true,
  );
  assert.equal(
    isLocalTimeWithinOpeningHours("tuesday", 60, overnight.openingHours),
    true,
  );
  assert.equal(
    isLocalTimeWithinOpeningHours("tuesday", 4 * 60, overnight.openingHours),
    false,
  );
  assert.equal(
    doesHourBucketOverlapOpeningHours("tuesday", 1, overnight.openingHours),
    true,
  );

  const alwaysOpen = normalizeOpeningHours({ is_24h: true });
  assert.equal(alwaysOpen.insufficientReason, null);
  assert.ok(alwaysOpen.openingHours);
  assert.equal(
    doesHourBucketOverlapOpeningHours("friday", 3, alwaysOpen.openingHours),
    true,
  );
});

test("buildInsufficientBusyTimesDoc writes null histogram and schema metadata", () => {
  const computedFrom = Timestamp.fromDate(new Date("2026-03-01T00:00:00.000Z"));
  const computedTo = Timestamp.fromDate(new Date("2026-03-31T00:00:00.000Z"));
  const lastComputedAt = Timestamp.fromDate(new Date("2026-03-14T12:00:00.000Z"));

  const doc = buildInsufficientBusyTimesDoc({
    venueId: "venue-1",
    timezone: "Asia/Jerusalem",
    resolvedTimezone: "Asia/Jerusalem",
    computedFrom,
    computedTo,
    insufficientReason: "missing_opening_hours",
    lastComputedAt,
  });

  assert.equal(doc.schema_version, BUSY_TIMES_SCHEMA_VERSION);
  assert.equal(doc.histogram, null);
  assert.equal(doc.insufficient_reason, "missing_opening_hours");
  assert.equal(doc.confidence, "insufficient");
  assert.equal(doc.demo_override_active, false);
});

test("determineInsufficientReason relaxes signal thresholds in demo mode only", () => {
  const opening = normalizeOpeningHours({ is_24h: true });

  const productionReason = determineInsufficientReason({
    resolvedTimezone: "Asia/Jerusalem",
    openingHours: opening.openingHours,
    totalSignals30d: 6,
    distinctActiveDays30d: 1,
    daysCovered: 30,
    demoMode: false,
  });
  assert.equal(productionReason, "not_enough_signals");

  const demoReason = determineInsufficientReason({
    resolvedTimezone: "Asia/Jerusalem",
    openingHours: opening.openingHours,
    totalSignals30d: 6,
    distinctActiveDays30d: 1,
    daysCovered: 30,
    demoMode: true,
  });
  assert.equal(demoReason, null);
});

test("dedupeSignals and hourly cap prevent inflated same-visit weighting", () => {
  const opening = normalizeOpeningHours({ is_24h: true });
  const deduped = dedupeSignals([
    {
      venueId: "venue-1",
      identity: "device-1",
      eventType: "offer_claim",
      eventAt: new Date("2026-03-10T10:05:00.000Z"),
      sourceWeight: 0.5,
    },
    {
      venueId: "venue-1",
      identity: "device-1",
      eventType: "offer_claim",
      eventAt: new Date("2026-03-10T10:12:00.000Z"),
      sourceWeight: 0.5,
    },
    {
      venueId: "venue-1",
      identity: "device-1",
      eventType: "qr_redemption",
      eventAt: new Date("2026-03-10T10:20:00.000Z"),
      sourceWeight: 1.0,
    },
    {
      venueId: "venue-1",
      identity: "device-1",
      eventType: "directions_click",
      eventAt: new Date("2026-03-10T10:25:00.000Z"),
      sourceWeight: 0.7,
    },
  ]);

  assert.equal(deduped.length, 3);

  const built = bucketSignalsToHistogram({
    signals: deduped,
    timeZone: "Asia/Jerusalem",
    openingHours: opening.openingHours,
  });

  const hourValue = built.histogram.day_1[12]; // 2026-03-10 is Tuesday; 10:xx UTC => 12:xx local
  assert.equal(Number(hourValue.toFixed(2)), 1.2);
  assert.equal(built.totalSignals30d, 3);
});

test("computeCurrentTypicalLabel returns null when venue is closed now", () => {
  const opening = normalizeOpeningHours({
    hours: {
      monday: [{ open: "18:00", close: "23:00" }],
    },
  });

  const label = computeCurrentTypicalLabel({
    histogram: {
      day_0: Array.from({ length: 24 }, () => 0),
      day_1: Array.from({ length: 24 }, () => 0),
      day_2: Array.from({ length: 24 }, () => 0),
      day_3: Array.from({ length: 24 }, () => 0),
      day_4: Array.from({ length: 24 }, () => 0),
      day_5: Array.from({ length: 24 }, () => 0),
      day_6: Array.from({ length: 24 }, () => 0),
    },
    timeZone: "Asia/Jerusalem",
    openingHours: opening.openingHours,
    now: new Date("2026-02-16T08:00:00.000Z"), // 10:00 local, closed
  });

  assert.equal(label, null);
});

test("resolveAuthorizedBackfillVenueId only allows the merchant linked venue", () => {
  assert.equal(
    resolveAuthorizedBackfillVenueId({
      requestedVenueId: "",
      merchantVenueId: "venue-1",
    }),
    "venue-1",
  );

  assert.equal(
    resolveAuthorizedBackfillVenueId({
      requestedVenueId: "venue-1",
      merchantVenueId: "venue-1",
    }),
    "venue-1",
  );

  assert.throws(
    () => resolveAuthorizedBackfillVenueId({
      requestedVenueId: "venue-2",
      merchantVenueId: "venue-1",
    }),
    /Cannot backfill another merchant venue/,
  );

  assert.throws(
    () => resolveAuthorizedBackfillVenueId({
      requestedVenueId: "venue-1",
      merchantVenueId: "",
    }),
    /Not a linked merchant account/,
  );
});
