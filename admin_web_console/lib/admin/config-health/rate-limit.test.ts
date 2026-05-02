import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { checkRateLimit, resetRateLimits } from "./rate-limit";

describe("checkRateLimit", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2025-01-01T00:00:00Z"));
    resetRateLimits();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("allows 5 requests from the same IP when limit is 30/min", () => {
    const ip = "10.0.0.1";
    for (let i = 0; i < 5; i++) {
      const result = checkRateLimit(ip);
      expect(result.allowed).toBe(true);
      expect(result.retryAt).toBeUndefined();
    }
  });

  it("returns retryAt on the (limit+1)th request from the same IP", () => {
    const ip = "10.0.0.2";
    // First 30 requests should all be allowed
    for (let i = 0; i < 30; i++) {
      const result = checkRateLimit(ip);
      expect(result.allowed).toBe(true);
    }
    // 31st request should be rejected
    const rejected = checkRateLimit(ip);
    expect(rejected.allowed).toBe(false);
    expect(rejected.retryAt).toBeInstanceOf(Date);
    expect(rejected.retryAt!.getTime()).toBe(Date.now() + 60_000);
  });

  it("does not count requests older than the sliding window (vi.setSystemTime)", () => {
    const ip = "10.0.0.3";
    // Exhaust the limit
    for (let i = 0; i < 30; i++) {
      checkRateLimit(ip);
    }
    // Confirm blocked
    expect(checkRateLimit(ip).allowed).toBe(false);

    // Advance time past the 60-second window
    vi.setSystemTime(new Date("2025-01-01T00:01:01Z"));

    // Should be allowed again because the window has reset
    const result = checkRateLimit(ip);
    expect(result.allowed).toBe(true);
    expect(result.retryAt).toBeUndefined();
  });

  it("tracks different IPs independently — IP A at limit does not affect IP B", () => {
    const ipA = "10.0.0.10";
    const ipB = "10.0.0.11";

    // Exhaust limit for IP A
    for (let i = 0; i < 30; i++) {
      checkRateLimit(ipA);
    }
    expect(checkRateLimit(ipA).allowed).toBe(false);

    // IP B should still be allowed
    const resultB = checkRateLimit(ipB);
    expect(resultB.allowed).toBe(true);
    expect(resultB.retryAt).toBeUndefined();
  });

  it("cleans old entries — after window expires IP A is under limit again with no leakage", () => {
    const ipA = "10.0.0.20";
    const ipB = "10.0.0.21";

    // Exhaust limit for both IPs
    for (let i = 0; i < 30; i++) {
      checkRateLimit(ipA);
      checkRateLimit(ipB);
    }
    expect(checkRateLimit(ipA).allowed).toBe(false);
    expect(checkRateLimit(ipB).allowed).toBe(false);

    // Advance past the window
    vi.setSystemTime(new Date("2025-01-01T00:01:01Z"));

    // IP A should be allowed and start fresh (count = 1)
    const freshA = checkRateLimit(ipA);
    expect(freshA.allowed).toBe(true);
    expect(freshA.retryAt).toBeUndefined();

    // Verify the counter truly reset — we can make 29 more requests (total 30)
    for (let i = 0; i < 29; i++) {
      expect(checkRateLimit(ipA).allowed).toBe(true);
    }
    // 31st overall (but 1st after the fresh window filled) should be blocked
    expect(checkRateLimit(ipA).allowed).toBe(false);
  });
});
