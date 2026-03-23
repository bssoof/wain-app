import type { Timestamp } from "firebase-admin/firestore";

export const BUSY_TIMES_SCHEMA_VERSION = 1;
export const BUSY_TIMES_WINDOW_DAYS = 30;
export const BUSY_TIMES_MIN_DAYS_COVERED = 14;
export const BUSY_TIMES_MIN_SIGNALS = 50;
export const BUSY_TIMES_MIN_ACTIVE_DAYS = 7;
export const BUSY_TIMES_SIGNAL_DEDUP_MINUTES = 30;
export const BUSY_TIMES_HOURLY_IDENTITY_CAP = 1.2;
export const BUSY_TIMES_JOB_CRON = "30 3 * * *";
export const BUSY_TIMES_JOB_TIMEZONE = "UTC";

export const LIGHT_SMOOTHING_WEIGHTS = {
  previous: 0.25,
  current: 0.5,
  next: 0.25,
} as const;

export const BUSY_LABEL_QUIET_PERCENTILE_MAX = 0.35;
export const BUSY_LABEL_MEDIUM_PERCENTILE_MAX = 0.7;

export type VenueSignalType =
  | "offer_claim"
  | "qr_redemption"
  | "directions_click";

export type BusyTimesConfidence =
  | "insufficient"
  | "low"
  | "medium"
  | "high";

export type BusyTimesInsufficientReason =
  | "missing_opening_hours"
  | "not_enough_signals"
  | "not_enough_active_days"
  | "missing_timezone";

export type BusyTimesCurrentLabel = "quiet" | "medium" | "busy";

export type OpeningDayKey =
  | "monday"
  | "tuesday"
  | "wednesday"
  | "thursday"
  | "friday"
  | "saturday"
  | "sunday";

export type DayIndexKey =
  | "day_0"
  | "day_1"
  | "day_2"
  | "day_3"
  | "day_4"
  | "day_5"
  | "day_6";

export const OPENING_DAY_KEYS: readonly OpeningDayKey[] = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
] as const;

export const DAY_INDEX_KEYS: readonly DayIndexKey[] = [
  "day_0",
  "day_1",
  "day_2",
  "day_3",
  "day_4",
  "day_5",
  "day_6",
] as const;

export const DAY_INDEX_TO_OPENING_DAY: Readonly<Record<DayIndexKey, OpeningDayKey>> = {
  day_0: "monday",
  day_1: "tuesday",
  day_2: "wednesday",
  day_3: "thursday",
  day_4: "friday",
  day_5: "saturday",
  day_6: "sunday",
};

export const OPENING_DAY_TO_INDEX: Readonly<Record<OpeningDayKey, DayIndexKey>> = {
  monday: "day_0",
  tuesday: "day_1",
  wednesday: "day_2",
  thursday: "day_3",
  friday: "day_4",
  saturday: "day_5",
  sunday: "day_6",
};

export type VenueSignal = {
  venueId: string;
  identity: string;
  eventType: VenueSignalType;
  eventAt: Date;
  sourceWeight: number;
};

export type NormalizedOpeningWindow = {
  open: string;
  close: string;
  openMinutes: number;
  closeMinutes: number;
  spansMidnight: boolean;
};

export type NormalizedOpeningHours = Record<
  OpeningDayKey,
  NormalizedOpeningWindow[]
>;

export type TimezoneResolutionSource = "venue" | "city" | "default" | "missing";

export type ResolvedTimezone = {
  timezone: string | null;
  source: TimezoneResolutionSource;
  cityKey: string | null;
  insufficientReason: BusyTimesInsufficientReason | null;
};

export type BestVisitWindow = {
  start_hour: number;
  end_hour: number;
};

export type BestVisitWindowsByDay = Partial<Record<DayIndexKey, BestVisitWindow[]>>;

export type BusyTimesHistogram = Record<DayIndexKey, number[]>;

export type BusyTimesSourceBreakdown = {
  qr_redemption_count: number;
  directions_click_count: number;
  offer_claim_count: number;
  deduped_signal_count: number;
};

export type VenueBusyTimesDoc = {
  venue_id: string;
  schema_version: number;
  demo_override_active: boolean;
  timezone: string | null;
  resolved_timezone: string | null;
  computed_from: Timestamp;
  computed_to: Timestamp;
  window_days: number;
  day_index_base: "monday";
  histogram: BusyTimesHistogram | null;
  confidence: BusyTimesConfidence;
  insufficient_reason: BusyTimesInsufficientReason | null;
  total_signals_30d: number;
  distinct_active_days_30d: number;
  days_covered: number;
  current_typical_label: BusyTimesCurrentLabel | null;
  peak_day: number | null;
  peak_hour: number | null;
  best_visit_windows_by_day: BestVisitWindowsByDay | null;
  source_breakdown_30d: BusyTimesSourceBreakdown;
  last_computed_at: Timestamp;
};
