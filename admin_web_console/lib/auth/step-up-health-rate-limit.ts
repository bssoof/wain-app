import "server-only";

const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 60;

type RateLimitBucket = {
  count: number;
  resetAtMs: number;
};

const rateLimitBuckets = new Map<string, RateLimitBucket>();

export function checkStepUpHealthRateLimit(
  clientIp: string,
  nowMs: number = Date.now(),
): { ok: true } | { ok: false; retryAtMs: number } {
  const current = rateLimitBuckets.get(clientIp);
  if (!current || current.resetAtMs <= nowMs) {
    rateLimitBuckets.set(clientIp, {
      count: 1,
      resetAtMs: nowMs + RATE_LIMIT_WINDOW_MS,
    });
    return { ok: true };
  }

  if (current.count >= RATE_LIMIT_MAX_REQUESTS) {
    return { ok: false, retryAtMs: current.resetAtMs };
  }

  current.count += 1;
  return { ok: true };
}

export function clearStepUpHealthRateLimitForTests(): void {
  rateLimitBuckets.clear();
}
