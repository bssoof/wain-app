import { describe, expect, it, vi } from "vitest";

import {
  loadReadinessRead,
  loadTopUpQueueRead,
  loadWalletLedgerRead,
} from "./finance-read-loader";
import { FIXTURE_FALLBACK_DISABLED_MESSAGE_AR } from "@/lib/admin/fixture-fallback-policy";
import {
  createTypeSafeMockInvoker,
  readMockCallArgs,
} from "../testing/type-safe-mock-invoker";

const minimalReadiness = {
  generatedAt: "2026-01-01T00:00:00.000Z",
  overallStatus: "ready" as const,
  summary: "ok",
  checks: [] as const,
};

const INLINE_FINANCE_SNAPSHOT = JSON.stringify({
  asOf: "2026-04-01T12:00:00.000Z",
  topups: [
    {
      id: "inline-topup-1",
      venueId: "venue-inline-1",
      userId: "merchant-inline-1",
      userName: "Inline Venue",
      amount: 100,
      currency: "ILS",
      providerReference: "INLINE-REF-1",
      createdAt: "2026-04-01T11:55:00.000Z",
      status: "pending",
    },
  ],
  ledger: [
    {
      id: "inline-ledger-1",
      venueId: "venue-inline-1",
      userId: "admin-inline-1",
      userName: "Inline Admin",
      type: "credit",
      amount: 10,
      currency: "ILS",
      description: "Inline top-up",
      reference: "inline-topup-ref",
      createdAt: "2026-04-01T11:56:00.000Z",
    },
  ],
  readiness: minimalReadiness,
});

function baseEnv(overrides: Record<string, string> = {}): Record<string, string | undefined> {
  return {
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: undefined,
    WAIN_FINANCE_READ_FORCE_UNAVAILABLE: undefined,
    WAIN_FINANCE_READ_INLINE_JSON: undefined,
    WAIN_FINANCE_READ_HTTP_URL: undefined,
    WAIN_FINANCE_READ_FIXTURE_AS_OF: undefined,
    WAIN_FINANCE_READ_STALE_AFTER_MS: undefined,
    WAIN_FINANCE_TOPUP_READ_STALE_AFTER_MS: undefined,
    WAIN_FINANCE_LEDGER_READ_STALE_AFTER_MS: undefined,
    WAIN_FINANCE_READINESS_READ_STALE_AFTER_MS: undefined,
    ...overrides,
  };
}

describe("finance read loader", () => {
  it("deduplicates snapshot loads across separate loaders when shared cache is enabled", async () => {
    const fetchImpl = vi.fn(async () => ({
      ok: true,
      status: 200,
      statusText: "OK",
      text: async () => INLINE_FINANCE_SNAPSHOT,
    })) as unknown as typeof fetch;

    const env = baseEnv({
      NODE_ENV: "development",
      VITEST: "false",
      WAIN_FINANCE_READ_HTTP_URL: "https://example.invalid/finance-read",
      WAIN_FINANCE_SHARED_SNAPSHOT_CACHE_TTL_MS: "5000",
    });

    const [topupResult, readinessResult, ledgerResult] = await Promise.all([
      loadTopUpQueueRead({ env, fetchImpl }),
      loadReadinessRead({ env, fetchImpl }),
      loadWalletLedgerRead({ env, fetchImpl }),
    ]);

    expect(fetchImpl).toHaveBeenCalledTimes(1);
    expect(topupResult.kind).toBe("success");
    expect(readinessResult.kind).toBe("success");
    expect(ledgerResult.kind).toBe("success");
  });

  it("serves top-ups from the snapshot fixture when no callable URL is configured", async () => {
    const result = await loadTopUpQueueRead({
      env: baseEnv({ WAIN_FINANCE_READ_INLINE_JSON: INLINE_FINANCE_SNAPSHOT }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.source).toBe("inline_json");
      expect(result.data.pending.length).toBeGreaterThan(0);
    }
  });

  it("returns unavailable when read is forced unavailable", async () => {
    const result = await loadTopUpQueueRead({
      env: baseEnv({ WAIN_FINANCE_READ_FORCE_UNAVAILABLE: "1" }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.message).toMatch(/forced unavailable/i);
      expect(result.attemptedSource).toBe("force_unavailable");
    }
  });

  it("blocks fixture fallback in production when no live snapshot sources are available", async () => {
    vi.stubGlobal("window", {});
    const result = await loadTopUpQueueRead({
      env: baseEnv({
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });
    vi.unstubAllGlobals();

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
      expect(result.attemptedSource).toContain("fixture_fallback_disabled");
    }
  });

  it("parses inline JSON for empty top-up queue", async () => {
    const inline = JSON.stringify({
      asOf: "2026-04-01T12:00:00.000Z",
      topups: [],
      ledger: [],
      readiness: minimalReadiness,
    });

    const result = await loadTopUpQueueRead({
      env: baseEnv({ WAIN_FINANCE_READ_INLINE_JSON: inline }),
      now: () => new Date("2026-04-01T12:05:00.000Z"),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.data.pending).toEqual([]);
      expect(result.source).toBe("inline_json");
    }
  });

  it("maps HTTP failures to unavailable without fabricating rows", async () => {
    const fetchImpl = vi.fn(async () => ({
      ok: false,
      status: 502,
      statusText: "Bad Gateway",
      text: async () => "",
    })) as unknown as typeof fetch;

    const result = await loadTopUpQueueRead({
      env: baseEnv({ WAIN_FINANCE_READ_HTTP_URL: "https://example.invalid/finance-read" }),
      fetchImpl,
    });

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.message).toMatch(/502/i);
    }
  });

  it("loads readiness from callable diagnostics when backend surface exists", async () => {
    const now = new Date("2026-04-10T12:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T11:59:00.000Z").getTime(),
      overallStatus: "WARN",
      warningChecks: ["read_models"],
      failureChecks: [],
      pricing: {
        status: "PASS",
        exists: true,
        issues: [],
      },
      readModels: {
        status: "WARN",
        hasAnyWalletReport: false,
      },
      walletDefaults: {
        status: "PASS",
        hasAnyWalletDoc: true,
      },
      notifications: {
        status: "PASS",
        hasAnyExpiryReminderEvent: true,
      },
    }));

    const result = await loadReadinessRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable,
      now: () => new Date(now),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName] = readMockCallArgs<[string, Record<string, unknown>]>(
      invokeCallable,
    );
    expect(callableName).toBe("verifyWalletOperationalReadiness");

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.data.report.overallStatus).toBe("warning");
      expect(result.data.report.checks.length).toBeGreaterThan(0);
      expect(result.source).toContain("callable:verifyWalletOperationalReadiness");
      expect(result.stale).toBe(false);
    }
  });

  it("marks readiness as stale when checkedAt exceeds configured freshness", async () => {
    const now = new Date("2026-04-10T12:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T11:00:00.000Z").toISOString(),
      overallStatus: "PASS",
      warningChecks: [],
      failureChecks: [],
      pricing: {
        status: "PASS",
        exists: true,
        issues: [],
      },
    }));

    const result = await loadReadinessRead({
      env: baseEnv({
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test",
        WAIN_FINANCE_READINESS_READ_STALE_AFTER_MS: "60000",
      }),
      invokeCallable,
      now: () => new Date(now),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.stale).toBe(true);
    }
  });

  it("maps readiness unauthorized and forbidden failures to unavailable outputs", async () => {
    const unauthorized = await loadReadinessRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw {
          code: "unauthenticated",
          message: "sign in required",
        };
      }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(unauthorized.kind).toBe("unavailable");
    if (unauthorized.kind === "unavailable") {
      expect(unauthorized.message).toMatch(/^Unauthorized:/);
    }

    const forbidden = await loadReadinessRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw {
          code: "permission-denied",
          message: "insufficient role",
        };
      }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(forbidden.kind).toBe("unavailable");
    if (forbidden.kind === "unavailable") {
      expect(forbidden.message).toMatch(/^Forbidden:/);
    }
  });

  it("converts empty readiness diagnostics into non-fabricated empty report", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: "2026-04-10T12:00:00.000Z",
    }));

    const result = await loadReadinessRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable,
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.data.report.checks).toEqual([]);
      expect(result.data.report.summary).toBe("لم تُرجع الخدمة الخلفية أي تشخيصات للجاهزية.");
    }
  });

  it("loads ledger slice from the same snapshot transport as top-ups", async () => {
    const result = await loadWalletLedgerRead({
      env: baseEnv({ WAIN_FINANCE_READ_INLINE_JSON: INLINE_FINANCE_SNAPSHOT }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.data.entries.length).toBeGreaterThan(0);
      expect(result.source).toBe("inline_json");
    }
  });

  it("prefers callable top-up read when configured and maps pending slice", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T12:00:00.000Z").getTime(),
      requests: [
        {
          id: "live-1",
          venueId: "venue-x",
          userId: "m1",
          userName: "Venue X",
          amount: 50,
          currency: "ILS" as const,
          providerReference: "TRX-1",
          createdAt: "2026-04-10T11:00:00.000Z",
          status: "pending" as const,
        },
        {
          id: "live-2",
          userId: "m2",
          userName: "Venue Y",
          amount: 10,
          currency: "ILS" as const,
          providerReference: "",
          createdAt: "2026-04-10T11:10:00.000Z",
          status: "credited" as const,
        },
      ],
    }));

    const result = await loadTopUpQueueRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable,
      now: () => new Date("2026-04-10T12:05:00.000Z"),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(invokeCallable).toHaveBeenCalled();
    const [name] = readMockCallArgs<[string]>(invokeCallable);
    expect(name).toBe("listMerchantTopUpRequestsForAdmin");

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.data.pending).toHaveLength(1);
      expect(result.data.pending[0].id).toBe("live-1");
      expect(result.source).toContain("callable:listMerchantTopUpRequestsForAdmin");
    }
  });

  it("falls back to snapshot top-ups when callable read is retryably unavailable", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => {
      throw { code: "unavailable", message: "cloud function cold" };
    });

    const result = await loadTopUpQueueRead({
      env: baseEnv({
        NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test",
        WAIN_FINANCE_READ_INLINE_JSON: INLINE_FINANCE_SNAPSHOT,
      }),
      invokeCallable,
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.source).toBe("inline_json");
      expect(result.data.pending.length).toBeGreaterThan(0);
    }
  });

  it("prefers callable wallet audit when configured", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T12:00:00.000Z").getTime(),
      entries: [
        {
          id: "le-1",
          venueId: "venue-x",
          userId: "u",
          userName: "Admin operator",
          type: "credit" as const,
          amount: 5,
          currency: "ILS" as const,
          description: "Top-up",
          reference: "topup_1",
          createdAt: "2026-04-10T11:00:00.000Z",
        },
      ],
    }));

    const result = await loadWalletLedgerRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable,
      now: () => new Date("2026-04-10T12:05:00.000Z"),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(invokeCallable).toHaveBeenCalled();
    const [name] = readMockCallArgs<[string]>(invokeCallable);
    expect(name).toBe("listMerchantWalletLedgerEntriesForAdmin");

    expect(result.kind).toBe("success");
    if (result.kind === "success") {
      expect(result.data.entries).toHaveLength(1);
      expect(result.source).toContain(
        "callable:listMerchantWalletLedgerEntriesForAdmin",
      );
    }
  });

  it("maps top-up unauthorized from callable to unavailable result", async () => {
    const result = await loadTopUpQueueRead({
      env: baseEnv({ NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL: "https://example.test" }),
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw { code: "unauthenticated", message: "sign in" };
      }),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.message).toMatch(/^Unauthorized:/);
    }
  });
});
