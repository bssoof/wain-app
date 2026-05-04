// Using the same sliding window pattern as step-up-health-rate-limit.ts

const WINDOW_MS = 60 * 1000;
const MAX_REQUESTS = 30; // 30 requests / minute / IP

interface RateLimitRecord {
  count: number;
  resetAt: number;
}

const rateLimits = new Map<string, RateLimitRecord>();

export function buildRateLimitKey(endpoint: string, ip: string): string {
  return `${endpoint}:${ip}`;
}

export function checkRateLimit(ipOrKey: string): { allowed: boolean; retryAt?: Date } {
  const now = Date.now();
  const record = rateLimits.get(ipOrKey);

  if (!record) {
    rateLimits.set(ipOrKey, { count: 1, resetAt: now + WINDOW_MS });
    return { allowed: true };
  }

  if (now > record.resetAt) {
    record.count = 1;
    record.resetAt = now + WINDOW_MS;
    return { allowed: true };
  }

  if (record.count >= MAX_REQUESTS) {
    return { allowed: false, retryAt: new Date(record.resetAt) };
  }

  record.count++;
  return { allowed: true };
}

// For testing purposes
export function resetRateLimits() {
  rateLimits.clear();
}
