import type { Timestamp } from "firebase-admin/firestore";
import {
  BUSY_TIMES_HOURLY_IDENTITY_CAP,
  BUSY_TIMES_MIN_ACTIVE_DAYS,
  BUSY_TIMES_MIN_DAYS_COVERED,
  BUSY_TIMES_MIN_SIGNALS,
  BUSY_TIMES_SCHEMA_VERSION,
  BUSY_TIMES_SIGNAL_DEDUP_MINUTES,
  BUSY_TIMES_WINDOW_DAYS,
  DAY_INDEX_TO_OPENING_DAY,
  DAY_INDEX_KEYS,
  LIGHT_SMOOTHING_WEIGHTS,
  type BestVisitWindowsByDay,
  type BusyTimesConfidence,
  type BusyTimesCurrentLabel,
  type BusyTimesHistogram,
  type BusyTimesInsufficientReason,
  type BusyTimesSourceBreakdown,
  type NormalizedOpeningHours,
  type VenueSignal,
  type VenueBusyTimesDoc,
} from "./types";
import { doesHourBucketOverlapOpeningHours, isLocalTimeWithinOpeningHours } from "./opening_hours";
import { getLocalTimeParts } from "./timezone";

export function createEmptyHistogram(): BusyTimesHistogram {
  return {
    day_0: Array.from({ length: 24 }, () => 0),
    day_1: Array.from({ length: 24 }, () => 0),
    day_2: Array.from({ length: 24 }, () => 0),
    day_3: Array.from({ length: 24 }, () => 0),
    day_4: Array.from({ length: 24 }, () => 0),
    day_5: Array.from({ length: 24 }, () => 0),
    day_6: Array.from({ length: 24 }, () => 0),
  };
}

export function smoothHourlySeries(values: number[]): number[] {
  return values.map((current, index) => {
    const previous = index > 0 ? values[index - 1] : current;
    const next = index < values.length - 1 ? values[index + 1] : current;

    return (
      (previous * LIGHT_SMOOTHING_WEIGHTS.previous) +
      (current * LIGHT_SMOOTHING_WEIGHTS.current) +
      (next * LIGHT_SMOOTHING_WEIGHTS.next)
    );
  });
}

export function smoothHistogram(histogram: BusyTimesHistogram): BusyTimesHistogram {
  return {
    day_0: smoothHourlySeries(histogram.day_0),
    day_1: smoothHourlySeries(histogram.day_1),
    day_2: smoothHourlySeries(histogram.day_2),
    day_3: smoothHourlySeries(histogram.day_3),
    day_4: smoothHourlySeries(histogram.day_4),
    day_5: smoothHourlySeries(histogram.day_5),
    day_6: smoothHourlySeries(histogram.day_6),
  };
}

export function determineInsufficientReason(input: {
  resolvedTimezone: string | null;
  openingHours: NormalizedOpeningHours | null;
  totalSignals30d: number;
  distinctActiveDays30d: number;
  daysCovered: number;
  demoMode?: boolean;
}): BusyTimesInsufficientReason | null {
  if (!input.resolvedTimezone) {
    return "missing_timezone";
  }

  if (!input.openingHours) {
    return "missing_opening_hours";
  }

  const minimumSignals = input.demoMode ? 1 : BUSY_TIMES_MIN_SIGNALS;
  if (input.totalSignals30d < minimumSignals) {
    return "not_enough_signals";
  }

  const minimumDaysCovered = input.demoMode ? 1 : BUSY_TIMES_MIN_DAYS_COVERED;
  const minimumActiveDays = input.demoMode ? 1 : BUSY_TIMES_MIN_ACTIVE_DAYS;
  if (
    input.daysCovered < minimumDaysCovered ||
    input.distinctActiveDays30d < minimumActiveDays
  ) {
    return "not_enough_active_days";
  }

  return null;
}

export function determineConfidence(input: {
  insufficientReason: BusyTimesInsufficientReason | null;
  totalSignals30d: number;
  distinctActiveDays30d: number;
}): BusyTimesConfidence {
  if (input.insufficientReason) {
    return "insufficient";
  }

  if (
    input.totalSignals30d >= 200 &&
    input.distinctActiveDays30d >= 21
  ) {
    return "high";
  }

  if (
    input.totalSignals30d >= 100 &&
    input.distinctActiveDays30d >= 14
  ) {
    return "medium";
  }

  return "low";
}

export function buildEmptySourceBreakdown(): BusyTimesSourceBreakdown {
  return {
    qr_redemption_count: 0,
    directions_click_count: 0,
    offer_claim_count: 0,
    deduped_signal_count: 0,
  };
}

export function buildInsufficientBusyTimesDoc(input: {
  venueId: string;
  demoOverrideActive?: boolean;
  timezone: string | null;
  resolvedTimezone: string | null;
  computedFrom: Timestamp;
  computedTo: Timestamp;
  insufficientReason: BusyTimesInsufficientReason;
  totalSignals30d?: number;
  distinctActiveDays30d?: number;
  daysCovered?: number;
  sourceBreakdown30d?: BusyTimesSourceBreakdown;
  lastComputedAt: Timestamp;
}): VenueBusyTimesDoc {
  return {
    venue_id: input.venueId,
    schema_version: BUSY_TIMES_SCHEMA_VERSION,
    demo_override_active: input.demoOverrideActive ?? false,
    timezone: input.timezone,
    resolved_timezone: input.resolvedTimezone,
    computed_from: input.computedFrom,
    computed_to: input.computedTo,
    window_days: BUSY_TIMES_WINDOW_DAYS,
    day_index_base: "monday",
    histogram: null,
    confidence: "insufficient",
    insufficient_reason: input.insufficientReason,
    total_signals_30d: input.totalSignals30d ?? 0,
    distinct_active_days_30d: input.distinctActiveDays30d ?? 0,
    days_covered: input.daysCovered ?? 0,
    current_typical_label: null,
    peak_day: null,
    peak_hour: null,
    best_visit_windows_by_day: null,
    source_breakdown_30d: input.sourceBreakdown30d ?? buildEmptySourceBreakdown(),
    last_computed_at: input.lastComputedAt,
  };
}

export function buildEmptyBestVisitWindowsByDay(): BestVisitWindowsByDay {
  return Object.fromEntries(
    DAY_INDEX_KEYS.map((dayKey) => [dayKey, []]),
  ) as BestVisitWindowsByDay;
}

export function clampHourlyIdentityContribution(score: number): number {
  return Math.max(0, Math.min(score, BUSY_TIMES_HOURLY_IDENTITY_CAP));
}

export function normalizePercentileToLabel(percentile: number): BusyTimesCurrentLabel {
  if (percentile < 0.35) {
    return "quiet";
  }
  if (percentile < 0.7) {
    return "medium";
  }
  return "busy";
}

export function floorTo30MinuteBucket(date: Date): number {
  const bucketMs = BUSY_TIMES_SIGNAL_DEDUP_MINUTES * 60 * 1000;
  return Math.floor(date.getTime() / bucketMs) * bucketMs;
}

export function dedupeSignals(signals: VenueSignal[]): VenueSignal[] {
  const uniqueSignals = new Map<string, VenueSignal>();

  for (const signal of signals) {
    const bucket30m = floorTo30MinuteBucket(signal.eventAt);
    const key = `${signal.venueId}:${signal.eventType}:${signal.identity}:${bucket30m}`;
    const existing = uniqueSignals.get(key);

    if (!existing || existing.eventAt.getTime() > signal.eventAt.getTime()) {
      uniqueSignals.set(key, signal);
    }
  }

  return Array.from(uniqueSignals.values()).sort((left, right) => left.eventAt.getTime() - right.eventAt.getTime());
}

export type HistogramBuildResult = {
  histogram: BusyTimesHistogram;
  totalSignals30d: number;
  distinctActiveDays30d: number;
  sourceBreakdown30d: BusyTimesSourceBreakdown;
};

export function bucketSignalsToHistogram(input: {
  signals: VenueSignal[];
  timeZone: string;
  openingHours: NormalizedOpeningHours;
}): HistogramBuildResult {
  const histogram = createEmptyHistogram();
  const activeDays = new Set<string>();
  const sourceBreakdown30d = buildEmptySourceBreakdown();
  const identityHourContributions = new Map<string, number>();

  for (const signal of input.signals) {
    const localTime = getLocalTimeParts(signal.eventAt, input.timeZone);
    if (!isLocalTimeWithinOpeningHours(localTime.weekday, localTime.minuteOfDay, input.openingHours)) {
      continue;
    }

    sourceBreakdown30d.deduped_signal_count += 1;
    if (signal.eventType === "qr_redemption") {
      sourceBreakdown30d.qr_redemption_count += 1;
    } else if (signal.eventType === "directions_click") {
      sourceBreakdown30d.directions_click_count += 1;
    } else if (signal.eventType === "offer_claim") {
      sourceBreakdown30d.offer_claim_count += 1;
    }

    const identityHourKey = `${signal.identity}:${localTime.isoDate}:${localTime.hour}`;
    const currentContribution = identityHourContributions.get(identityHourKey) ?? 0;
    const nextContribution = clampHourlyIdentityContribution(
      currentContribution + signal.sourceWeight,
    ) - currentContribution;

    if (nextContribution <= 0) {
      continue;
    }

    identityHourContributions.set(
      identityHourKey,
      currentContribution + nextContribution,
    );

    histogram[localTime.dayIndexKey][localTime.hour] += nextContribution;
    activeDays.add(localTime.isoDate);
  }

  return {
    histogram,
    totalSignals30d: sourceBreakdown30d.deduped_signal_count,
    distinctActiveDays30d: activeDays.size,
    sourceBreakdown30d,
  };
}

export function computeCurrentTypicalLabel(input: {
  histogram: BusyTimesHistogram;
  timeZone: string;
  openingHours: NormalizedOpeningHours;
  now: Date;
}): BusyTimesCurrentLabel | null {
  const localNow = getLocalTimeParts(input.now, input.timeZone);
  if (!isLocalTimeWithinOpeningHours(localNow.weekday, localNow.minuteOfDay, input.openingHours)) {
    return null;
  }

  const validValues: number[] = [];
  for (const dayKey of DAY_INDEX_KEYS) {
    const openingDayValues = input.histogram[dayKey];
    for (let hourIndex = 0; hourIndex < 24; hourIndex += 1) {
      if (
        doesHourBucketOverlapOpeningHours(
          DAY_INDEX_TO_OPENING_DAY[dayKey],
          hourIndex,
          input.openingHours,
        )
      ) {
        validValues.push(openingDayValues[hourIndex] ?? 0);
      }
    }
  }

  if (validValues.length === 0) {
    return null;
  }

  const currentValue = input.histogram[localNow.dayIndexKey][localNow.hour] ?? 0;
  const sortedValues = [...validValues].sort((left, right) => left - right);
  const lowerBoundIndex = sortedValues.findIndex((value) => value >= currentValue);
  const effectiveIndex = lowerBoundIndex === -1 ? sortedValues.length - 1 : lowerBoundIndex;
  const percentile = sortedValues.length <= 1 ? 0 : effectiveIndex / (sortedValues.length - 1);
  return normalizePercentileToLabel(percentile);
}

export function computePeakWindow(histogram: BusyTimesHistogram): {
  peakDay: number | null;
  peakHour: number | null;
} {
  let peakDay: number | null = null;
  let peakHour: number | null = null;
  let peakValue = Number.NEGATIVE_INFINITY;

  for (const dayKey of DAY_INDEX_KEYS) {
    const dayIndex = Number.parseInt(dayKey.slice(4), 10);
    for (let hourIndex = 0; hourIndex < 24; hourIndex += 1) {
      const value = histogram[dayKey][hourIndex] ?? 0;
      if (value > peakValue) {
        peakValue = value;
        peakDay = dayIndex;
        peakHour = hourIndex;
      }
    }
  }

  if (!Number.isFinite(peakValue) || peakValue <= 0) {
    return { peakDay: null, peakHour: null };
  }

  return { peakDay, peakHour };
}

export function computeBestVisitWindowsByDay(input: {
  histogram: BusyTimesHistogram;
  openingHours: NormalizedOpeningHours;
}): BestVisitWindowsByDay {
  const result = buildEmptyBestVisitWindowsByDay();
  const openingDays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] as const;

  for (const dayKey of DAY_INDEX_KEYS) {
    const dayIndex = Number.parseInt(dayKey.slice(4), 10);
    const openingDay = openingDays[dayIndex];
    const candidates: Array<{ start: number; end: number; score: number }> = [];

    for (let startHour = 0; startHour <= 22; startHour += 1) {
      const firstHourOpen = doesHourBucketOverlapOpeningHours(openingDay, startHour, input.openingHours);
      const secondHourOpen = doesHourBucketOverlapOpeningHours(openingDay, startHour + 1, input.openingHours);
      if (!firstHourOpen || !secondHourOpen) {
        continue;
      }

      const score = (
        (input.histogram[dayKey][startHour] ?? 0) +
        (input.histogram[dayKey][startHour + 1] ?? 0)
      ) / 2;

      candidates.push({
        start: startHour,
        end: startHour + 2,
        score,
      });
    }

    candidates.sort((left, right) => {
      if (left.score !== right.score) {
        return left.score - right.score;
      }
      return left.start - right.start;
    });

    result[dayKey] = candidates.slice(0, 3).map((candidate) => ({
      start_hour: candidate.start,
      end_hour: candidate.end,
    }));
  }

  return result;
}

export function buildSuccessfulBusyTimesDoc(input: {
  venueId: string;
  demoOverrideActive?: boolean;
  timezone: string | null;
  resolvedTimezone: string;
  computedFrom: Timestamp;
  computedTo: Timestamp;
  histogram: BusyTimesHistogram;
  confidence: BusyTimesConfidence;
  totalSignals30d: number;
  distinctActiveDays30d: number;
  daysCovered: number;
  currentTypicalLabel: BusyTimesCurrentLabel | null;
  peakDay: number | null;
  peakHour: number | null;
  bestVisitWindowsByDay: BestVisitWindowsByDay;
  sourceBreakdown30d: BusyTimesSourceBreakdown;
  lastComputedAt: Timestamp;
}): VenueBusyTimesDoc {
  return {
    venue_id: input.venueId,
    schema_version: BUSY_TIMES_SCHEMA_VERSION,
    demo_override_active: input.demoOverrideActive ?? false,
    timezone: input.timezone,
    resolved_timezone: input.resolvedTimezone,
    computed_from: input.computedFrom,
    computed_to: input.computedTo,
    window_days: BUSY_TIMES_WINDOW_DAYS,
    day_index_base: "monday",
    histogram: input.histogram,
    confidence: input.confidence,
    insufficient_reason: null,
    total_signals_30d: input.totalSignals30d,
    distinct_active_days_30d: input.distinctActiveDays30d,
    days_covered: input.daysCovered,
    current_typical_label: input.currentTypicalLabel,
    peak_day: input.peakDay,
    peak_hour: input.peakHour,
    best_visit_windows_by_day: input.bestVisitWindowsByDay,
    source_breakdown_30d: input.sourceBreakdown30d,
    last_computed_at: input.lastComputedAt,
  };
}
