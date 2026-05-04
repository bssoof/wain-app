import { describe, expect, it } from "vitest";

import {
  createFinanceReadSuccess,
  normalizeFinanceReadFailure,
  resolveReadFreshness,
  toReadSuccessState,
} from "./finance-read-transport";

describe("finance read transport", () => {
  it("marks freshness as stale when age exceeds staleAfterMs", () => {
    const fetchedAt = new Date("2026-04-10T10:00:00.000Z");
    const freshness = resolveReadFreshness({
      source: "wallet_readiness",
      checkedAt: "2026-04-10T09:50:00.000Z",
      fetchedAt,
      staleAfterMs: 60_000,
    });

    expect(freshness.ageMs).toBe(10 * 60 * 1000);
    expect(toReadSuccessState(freshness)).toBe("stale");

    const result = createFinanceReadSuccess({
      data: { id: "payload" },
      freshness,
    });

    expect(result.state).toBe("stale");
  });

  it("normalizes unauthenticated errors to unauthorized read failures", () => {
    const result = normalizeFinanceReadFailure("wallet_readiness", {
      code: "unauthenticated",
      message: "Sign in required",
    });

    expect(result.ok).toBe(false);
    expect(result.state).toBe("unauthorized");
    expect(result.retryable).toBe(false);
    expect(result.message).toBe("Sign in required");
  });

  it("normalizes permission-denied errors to forbidden read failures", () => {
    const result = normalizeFinanceReadFailure("wallet_readiness", {
      code: "permission-denied",
      message: "Not allowed",
    });

    expect(result.ok).toBe(false);
    expect(result.state).toBe("forbidden");
    expect(result.retryable).toBe(false);
    expect(result.message).toBe("Not allowed");
  });

  it("normalizes transport failures to unavailable read failures", () => {
    const result = normalizeFinanceReadFailure("wallet_readiness", {
      code: "unavailable",
      message: "Service unavailable",
    });

    expect(result.ok).toBe(false);
    expect(result.state).toBe("unavailable");
    expect(result.retryable).toBe(true);
    expect(result.message).toBe("Service unavailable");
  });
});
