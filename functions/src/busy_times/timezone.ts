import { ANALYTICS_TIMEZONE } from "../analytics_helpers";
import {
  OPENING_DAY_KEYS,
  type DayIndexKey,
  type OpeningDayKey,
  type ResolvedTimezone,
} from "./types";

const DEFAULT_BUSY_TIMES_TIMEZONE = ANALYTICS_TIMEZONE;

const WEEKDAY_LABEL_TO_DAY_KEY: Readonly<Record<string, OpeningDayKey>> = {
  monday: "monday",
  tuesday: "tuesday",
  wednesday: "wednesday",
  thursday: "thursday",
  friday: "friday",
  saturday: "saturday",
  sunday: "sunday",
};

const CITY_TIMEZONE_MAP: Readonly<Record<string, string>> = {
  "al quds": "Asia/Jerusalem",
  "\u0627\u0644\u0642\u062f\u0633": "Asia/Jerusalem",
  jerusalem: "Asia/Jerusalem",
  "tel aviv": "Asia/Jerusalem",
  "tel aviv yafo": "Asia/Jerusalem",
  yafo: "Asia/Jerusalem",
  "\u064a\u0627\u0641\u0627": "Asia/Jerusalem",
  ramallah: "Asia/Jerusalem",
  "\u0631\u0627\u0645\u0627\u0644\u0644\u0647": "Asia/Jerusalem",
  "\u0631\u0627\u0645 \u0627\u0644\u0644\u0647": "Asia/Jerusalem",
  nablus: "Asia/Jerusalem",
  "\u0646\u0627\u0628\u0644\u0633": "Asia/Jerusalem",
  hebron: "Asia/Jerusalem",
  "\u0627\u0644\u062e\u0644\u064a\u0644": "Asia/Jerusalem",
  bethlehem: "Asia/Jerusalem",
  "beit lahm": "Asia/Jerusalem",
  "\u0628\u064a\u062a \u0644\u062d\u0645": "Asia/Jerusalem",
  haifa: "Asia/Jerusalem",
  "\u062d\u064a\u0641\u0627": "Asia/Jerusalem",
  nazareth: "Asia/Jerusalem",
  "\u0627\u0644\u0646\u0627\u0635\u0631\u0629": "Asia/Jerusalem",
  jenin: "Asia/Jerusalem",
  "\u062c\u0646\u064a\u0646": "Asia/Jerusalem",
  tulkarm: "Asia/Jerusalem",
  "\u0637\u0648\u0644\u0643\u0631\u0645": "Asia/Jerusalem",
  qalqilya: "Asia/Jerusalem",
  "\u0642\u0644\u0642\u064a\u0644\u064a\u0629": "Asia/Jerusalem",
  jericho: "Asia/Jerusalem",
  "\u0623\u0631\u064a\u062d\u0627": "Asia/Jerusalem",
  "\u0627\u0631\u064a\u062d\u0627": "Asia/Jerusalem",
};

function buildZonedFormatter(timeZone: string): Intl.DateTimeFormat {
  return new Intl.DateTimeFormat("en-US", {
    timeZone,
    weekday: "long",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
}

function normalizeString(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9\u0600-\u06FF]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function isValidTimeZone(value: string | null | undefined): value is string {
  if (typeof value !== "string" || value.trim().length === 0) {
    return false;
  }
  try {
    buildZonedFormatter(value.trim()).format(new Date());
    return true;
  } catch {
    return false;
  }
}

export function normalizeCityKey(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = normalizeString(value);
  return normalized.length > 0 ? normalized : null;
}

export function resolveVenueTimezone(input: {
  venueTimezone?: unknown;
  venueCity?: unknown;
  defaultTimezone?: string | null;
}): ResolvedTimezone {
  const rawVenueTimezone = typeof input.venueTimezone === "string" ?
    input.venueTimezone.trim() :
    "";
  if (isValidTimeZone(rawVenueTimezone)) {
    return {
      timezone: rawVenueTimezone,
      source: "venue",
      cityKey: normalizeCityKey(input.venueCity),
      insufficientReason: null,
    };
  }

  const cityKey = normalizeCityKey(input.venueCity);
  const cityTimezone = cityKey ? CITY_TIMEZONE_MAP[cityKey] : null;
  if (cityTimezone && isValidTimeZone(cityTimezone)) {
    return {
      timezone: cityTimezone,
      source: "city",
      cityKey,
      insufficientReason: null,
    };
  }

  const fallbackTimezone = input.defaultTimezone ?? DEFAULT_BUSY_TIMES_TIMEZONE;
  if (isValidTimeZone(fallbackTimezone)) {
    return {
      timezone: fallbackTimezone,
      source: "default",
      cityKey,
      insufficientReason: null,
    };
  }

  return {
    timezone: null,
    source: "missing",
    cityKey,
    insufficientReason: "missing_timezone",
  };
}

export function getLocalTimeParts(date: Date, timeZone: string): {
  weekday: OpeningDayKey;
  dayIndex: number;
  dayIndexKey: DayIndexKey;
  hour: number;
  minute: number;
  minuteOfDay: number;
  isoDate: string;
} {
  const parts = buildZonedFormatter(timeZone).formatToParts(date);
  const values = new Map<string, string>();
  for (const part of parts) {
    if (part.type !== "literal") {
      values.set(part.type, part.value);
    }
  }

  const weekdayLabel = (values.get("weekday") ?? "").toLowerCase();
  const weekday = WEEKDAY_LABEL_TO_DAY_KEY[weekdayLabel];
  if (!weekday) {
    throw new Error(`Unsupported weekday label "${weekdayLabel}" for timezone ${timeZone}`);
  }

  const dayIndex = OPENING_DAY_KEYS.indexOf(weekday);
  const hour = Number.parseInt(values.get("hour") ?? "", 10);
  const minute = Number.parseInt(values.get("minute") ?? "", 10);
  const year = values.get("year") ?? "0000";
  const month = values.get("month") ?? "00";
  const day = values.get("day") ?? "00";

  if (!Number.isInteger(hour) || !Number.isInteger(minute)) {
    throw new Error(`Failed to extract local time parts for timezone ${timeZone}`);
  }

  return {
    weekday,
    dayIndex,
    dayIndexKey: `day_${dayIndex}` as DayIndexKey,
    hour,
    minute,
    minuteOfDay: hour * 60 + minute,
    isoDate: `${year}-${month}-${day}`,
  };
}
