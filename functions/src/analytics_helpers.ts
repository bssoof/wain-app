export const ANALYTICS_TIMEZONE = "Asia/Jerusalem";

export type DailyBucket = {
  views: number;
  calls: number;
  navs: number;
  story_views: number;
  offer_detail_views: number;
  claim_clicks: number;
  claims_created: number;
  redemptions: number;
};

export type TimedVenueEvent = {
  eventType: string;
  at: Date;
};

export type AnalyticsBucketingInput = {
  nowDate: Date;
  lookbackDays: number;
  events: TimedVenueEvent[];
  navigationClicks: Date[];
  timeZone?: string;
};

export type AnalyticsBucketingResult = {
  todayKey: string;
  dailyBuckets: Map<string, DailyBucket>;
  viewsThisWeek: number;
  viewsLastWeek: number;
  callsThisWeek: number;
  callsLastWeek: number;
  navsThisWeek: number;
  navsLastWeek: number;
  storyViewsThisWeek: number;
  views7d: number;
  viewsPrev7d: number;
  calls7d: number;
  callsPrev7d: number;
  navs7d: number;
  navsPrev7d: number;
  offerDetailViews7d: number;
  offerDetailViewsPrev7d: number;
  claimClicks7d: number;
  claimClicksPrev7d: number;
  claimsCreated7d: number;
  claimsCreatedPrev7d: number;
  redemptions7d: number;
  redemptionsPrev7d: number;
};

export function conversionRate(redeemed: number, claims: number): number {
  if (claims <= 0) return 0;
  return redeemed / claims;
}

export function dayKeyInTimezone(
  date: Date,
  timeZone: string = ANALYTICS_TIMEZONE,
): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

export function dayOffsetKey(baseKey: string, offsetDays: number): string {
  const [y, m, d] = baseKey.split("-").map((v) => parseInt(v, 10));
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + offsetDays);
  const year = dt.getUTCFullYear();
  const month = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const day = String(dt.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function weekStartKey(
  now: Date,
  timeZone: string = ANALYTICS_TIMEZONE,
): string {
  const dayKey = dayKeyInTimezone(now, timeZone);
  const weekdayLabel = new Intl.DateTimeFormat("en-US", {
    timeZone,
    weekday: "short",
  }).format(now);
  const weekdayIndexMap: Record<string, number> = {
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
    Sun: 7,
  };
  const weekday = weekdayIndexMap[weekdayLabel] ?? 1;
  return dayOffsetKey(dayKey, -(weekday - 1));
}

export function keyInRange(
  key: string,
  startInclusive: string,
  endExclusive: string,
): boolean {
  return key >= startInclusive && key < endExclusive;
}

export function bucketAnalyticsByDay(
  input: AnalyticsBucketingInput,
): AnalyticsBucketingResult {
  const timeZone = input.timeZone ?? ANALYTICS_TIMEZONE;
  const safeLookback = Math.max(1, input.lookbackDays);
  const todayKey = dayKeyInTimezone(input.nowDate, timeZone);
  const thisWeekStart = weekStartKey(input.nowDate, timeZone);
  const thisWeekEnd = dayOffsetKey(thisWeekStart, 7);
  const lastWeekStart = dayOffsetKey(thisWeekStart, -7);
  const lastWeekEnd = thisWeekStart;
  const current7dStart = dayOffsetKey(todayKey, -6);
  const current7dEnd = dayOffsetKey(todayKey, 1);
  const prev7dStart = dayOffsetKey(todayKey, -13);
  const prev7dEnd = current7dStart;

  const dailyBuckets = new Map<string, DailyBucket>();
  for (let i = 0; i < safeLookback; i++) {
    const key = dayOffsetKey(todayKey, -i);
    dailyBuckets.set(key, {
      views: 0,
      calls: 0,
      navs: 0,
      story_views: 0,
      offer_detail_views: 0,
      claim_clicks: 0,
      claims_created: 0,
      redemptions: 0,
    });
  }

  let viewsThisWeek = 0;
  let viewsLastWeek = 0;
  let callsThisWeek = 0;
  let callsLastWeek = 0;
  let navsThisWeek = 0;
  let navsLastWeek = 0;
  let storyViewsThisWeek = 0;
  let views7d = 0;
  let viewsPrev7d = 0;
  let calls7d = 0;
  let callsPrev7d = 0;
  let navs7d = 0;
  let navsPrev7d = 0;
  let offerDetailViews7d = 0;
  let offerDetailViewsPrev7d = 0;
  let claimClicks7d = 0;
  let claimClicksPrev7d = 0;
  let claimsCreated7d = 0;
  let claimsCreatedPrev7d = 0;
  let redemptions7d = 0;
  let redemptionsPrev7d = 0;

  for (const event of input.events) {
    const key = dayKeyInTimezone(event.at, timeZone);
    const bucket = dailyBuckets.get(key);
    if (bucket) {
      if (event.eventType === "view") bucket.views += 1;
      if (event.eventType === "call") bucket.calls += 1;
      if (event.eventType === "story_view") bucket.story_views += 1;
      if (event.eventType === "offer_detail_view") bucket.offer_detail_views += 1;
      if (event.eventType === "offer_claim_click") bucket.claim_clicks += 1;
      if (event.eventType === "offer_claim_created") bucket.claims_created += 1;
      if (event.eventType === "offer_redeemed") bucket.redemptions += 1;
    }

    if (event.eventType === "view") {
      if (keyInRange(key, thisWeekStart, thisWeekEnd)) viewsThisWeek += 1;
      else if (keyInRange(key, lastWeekStart, lastWeekEnd)) viewsLastWeek += 1;
      if (keyInRange(key, current7dStart, current7dEnd)) views7d += 1;
      else if (keyInRange(key, prev7dStart, prev7dEnd)) viewsPrev7d += 1;
    } else if (event.eventType === "call") {
      if (keyInRange(key, thisWeekStart, thisWeekEnd)) callsThisWeek += 1;
      else if (keyInRange(key, lastWeekStart, lastWeekEnd)) callsLastWeek += 1;
      if (keyInRange(key, current7dStart, current7dEnd)) calls7d += 1;
      else if (keyInRange(key, prev7dStart, prev7dEnd)) callsPrev7d += 1;
    } else if (event.eventType === "story_view") {
      if (keyInRange(key, thisWeekStart, thisWeekEnd)) storyViewsThisWeek += 1;
    } else if (event.eventType === "offer_detail_view") {
      if (keyInRange(key, current7dStart, current7dEnd)) offerDetailViews7d += 1;
      else if (keyInRange(key, prev7dStart, prev7dEnd)) offerDetailViewsPrev7d += 1;
    } else if (event.eventType === "offer_claim_click") {
      if (keyInRange(key, current7dStart, current7dEnd)) claimClicks7d += 1;
      else if (keyInRange(key, prev7dStart, prev7dEnd)) claimClicksPrev7d += 1;
    } else if (event.eventType === "offer_claim_created") {
      if (keyInRange(key, current7dStart, current7dEnd)) claimsCreated7d += 1;
      else if (keyInRange(key, prev7dStart, prev7dEnd)) claimsCreatedPrev7d += 1;
    } else if (event.eventType === "offer_redeemed") {
      if (keyInRange(key, current7dStart, current7dEnd)) redemptions7d += 1;
      else if (keyInRange(key, prev7dStart, prev7dEnd)) redemptionsPrev7d += 1;
    }
  }

  for (const navAt of input.navigationClicks) {
    const key = dayKeyInTimezone(navAt, timeZone);
    const bucket = dailyBuckets.get(key);
    if (bucket) {
      bucket.navs += 1;
    }
    if (keyInRange(key, thisWeekStart, thisWeekEnd)) navsThisWeek += 1;
    else if (keyInRange(key, lastWeekStart, lastWeekEnd)) navsLastWeek += 1;
    if (keyInRange(key, current7dStart, current7dEnd)) navs7d += 1;
    else if (keyInRange(key, prev7dStart, prev7dEnd)) navsPrev7d += 1;
  }

  return {
    todayKey,
    dailyBuckets,
    viewsThisWeek,
    viewsLastWeek,
    callsThisWeek,
    callsLastWeek,
    navsThisWeek,
    navsLastWeek,
    storyViewsThisWeek,
    views7d,
    viewsPrev7d,
    calls7d,
    callsPrev7d,
    navs7d,
    navsPrev7d,
    offerDetailViews7d,
    offerDetailViewsPrev7d,
    claimClicks7d,
    claimClicksPrev7d,
    claimsCreated7d,
    claimsCreatedPrev7d,
    redemptions7d,
    redemptionsPrev7d,
  };
}
