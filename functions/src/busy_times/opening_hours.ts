import {
  OPENING_DAY_KEYS,
  type BusyTimesInsufficientReason,
  type NormalizedOpeningHours,
  type NormalizedOpeningWindow,
  type OpeningDayKey,
} from "./types";

type RawOpeningWindow = {
  open?: unknown;
  close?: unknown;
  spans_midnight?: unknown;
};

export type OpeningHoursNormalizationResult = {
  is24Hours: boolean;
  openingHours: NormalizedOpeningHours | null;
  insufficientReason: BusyTimesInsufficientReason | null;
};

function createEmptyOpeningHours(): NormalizedOpeningHours {
  return {
    monday: [],
    tuesday: [],
    wednesday: [],
    thursday: [],
    friday: [],
    saturday: [],
    sunday: [],
  };
}

function zeroPad(value: number): string {
  return String(value).padStart(2, "0");
}

export function parseTimeToMinutes(
  value: string,
  options: { allow24Hour?: boolean } = {},
): number | null {
  const match = /^(\d{2}):(\d{2})$/.exec(value.trim());
  if (!match) {
    return null;
  }

  const hour = Number.parseInt(match[1], 10);
  const minute = Number.parseInt(match[2], 10);
  if (Number.isNaN(hour) || Number.isNaN(minute)) {
    return null;
  }

  if (options.allow24Hour && hour === 24 && minute === 0) {
    return 1440;
  }

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }

  return hour * 60 + minute;
}

function formatMinutes(minutes: number): string {
  if (minutes === 1440) {
    return "24:00";
  }

  const normalized = Math.max(0, Math.min(minutes, 1439));
  const hour = Math.floor(normalized / 60);
  const minute = normalized % 60;
  return `${zeroPad(hour)}:${zeroPad(minute)}`;
}

function normalizeOpeningWindow(raw: unknown): NormalizedOpeningWindow | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return null;
  }

  const typedRaw = raw as RawOpeningWindow;
  const open = typeof typedRaw.open === "string" ? typedRaw.open.trim() : "";
  const close = typeof typedRaw.close === "string" ? typedRaw.close.trim() : "";
  const openMinutes = parseTimeToMinutes(open);
  const closeMinutes = parseTimeToMinutes(close, { allow24Hour: true });

  if (openMinutes === null || closeMinutes === null || openMinutes === closeMinutes) {
    return null;
  }

  const explicitOvernight = typedRaw.spans_midnight === true;
  const spansMidnight = explicitOvernight || closeMinutes < openMinutes;

  return {
    open: formatMinutes(openMinutes),
    close: formatMinutes(closeMinutes),
    openMinutes,
    closeMinutes,
    spansMidnight,
  };
}

function normalizeDayWindows(rawDay: unknown): NormalizedOpeningWindow[] {
  if (!Array.isArray(rawDay)) {
    return [];
  }

  return rawDay
    .map((entry) => normalizeOpeningWindow(entry))
    .filter((entry): entry is NormalizedOpeningWindow => entry !== null)
    .sort((left, right) => left.openMinutes - right.openMinutes);
}

function create24HourOpeningHours(): NormalizedOpeningHours {
  const openingHours = createEmptyOpeningHours();
  for (const dayKey of OPENING_DAY_KEYS) {
    openingHours[dayKey] = [{
      open: "00:00",
      close: "24:00",
      openMinutes: 0,
      closeMinutes: 1440,
      spansMidnight: false,
    }];
  }
  return openingHours;
}

export function normalizeOpeningHours(
  venueData: Record<string, unknown>,
): OpeningHoursNormalizationResult {
  if (venueData.is_24h === true) {
    return {
      is24Hours: true,
      openingHours: create24HourOpeningHours(),
      insufficientReason: null,
    };
  }

  const hours = venueData.hours;
  if (!hours || typeof hours !== "object" || Array.isArray(hours)) {
    return {
      is24Hours: false,
      openingHours: null,
      insufficientReason: "missing_opening_hours",
    };
  }

  const openingHours = createEmptyOpeningHours();
  let totalWindows = 0;
  const hoursMap = hours as Record<string, unknown>;

  for (const dayKey of OPENING_DAY_KEYS) {
    const normalizedWindows = normalizeDayWindows(hoursMap[dayKey]);
    openingHours[dayKey] = normalizedWindows;
    totalWindows += normalizedWindows.length;
  }

  if (totalWindows === 0) {
    return {
      is24Hours: false,
      openingHours: null,
      insufficientReason: "missing_opening_hours",
    };
  }

  return {
    is24Hours: false,
    openingHours,
    insufficientReason: null,
  };
}

function previousDayKey(dayKey: OpeningDayKey): OpeningDayKey {
  const index = OPENING_DAY_KEYS.indexOf(dayKey);
  if (index <= 0) {
    return OPENING_DAY_KEYS[OPENING_DAY_KEYS.length - 1];
  }
  return OPENING_DAY_KEYS[index - 1];
}

function intervalOverlaps(
  intervalStart: number,
  intervalEnd: number,
  windowStart: number,
  windowEnd: number,
): boolean {
  return intervalStart < windowEnd && windowStart < intervalEnd;
}

export function isLocalTimeWithinOpeningHours(
  dayKey: OpeningDayKey,
  minuteOfDay: number,
  openingHours: NormalizedOpeningHours,
): boolean {
  const todayWindows = openingHours[dayKey] ?? [];
  for (const window of todayWindows) {
    if (window.spansMidnight) {
      if (minuteOfDay >= window.openMinutes) {
        return true;
      }
      continue;
    }

    if (minuteOfDay >= window.openMinutes && minuteOfDay < window.closeMinutes) {
      return true;
    }
  }

  const previousWindows = openingHours[previousDayKey(dayKey)] ?? [];
  for (const window of previousWindows) {
    if (!window.spansMidnight) {
      continue;
    }
    if (minuteOfDay < window.closeMinutes) {
      return true;
    }
  }

  return false;
}

export function doesHourBucketOverlapOpeningHours(
  dayKey: OpeningDayKey,
  hourIndex: number,
  openingHours: NormalizedOpeningHours,
): boolean {
  const intervalStart = Math.max(0, hourIndex * 60);
  const intervalEnd = Math.min(1440, intervalStart + 60);

  const todayWindows = openingHours[dayKey] ?? [];
  for (const window of todayWindows) {
    if (window.spansMidnight) {
      if (intervalOverlaps(intervalStart, intervalEnd, window.openMinutes, 1440)) {
        return true;
      }
      continue;
    }

    if (intervalOverlaps(intervalStart, intervalEnd, window.openMinutes, window.closeMinutes)) {
      return true;
    }
  }

  const previousWindows = openingHours[previousDayKey(dayKey)] ?? [];
  for (const window of previousWindows) {
    if (!window.spansMidnight) {
      continue;
    }
    if (intervalOverlaps(intervalStart, intervalEnd, 0, window.closeMinutes)) {
      return true;
    }
  }

  return false;
}
