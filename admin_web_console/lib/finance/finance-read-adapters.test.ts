import { describe, expect, it, vi } from "vitest";

import {
  FINANCE_READ_CALLABLE_SURFACES,
  createFinanceReadAdaptersTransport,
} from "./finance-read-adapters";
import {
  createTypeSafeMockInvoker,
  readCallableMockCall,
} from "../testing/type-safe-mock-invoker";

describe("finance read adapters", () => {
  it("exposes callable surfaces for top-up queue and wallet audit", () => {
    expect(FINANCE_READ_CALLABLE_SURFACES.topup_queue).toBe(
      "listMerchantTopUpRequestsForAdmin",
    );
    expect(FINANCE_READ_CALLABLE_SURFACES.wallet_audit).toBe(
      "listMerchantWalletLedgerEntriesForAdmin",
    );
  });

  it("maps top-up queue payload to success when freshness is within threshold", async () => {
    const now = new Date("2026-04-10T10:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T09:59:00.000Z").getTime(),
      requests: [
        {
          id: "req-1",
          venueId: "venue_001",
          userId: "u1",
          userName: "Test Venue",
          amount: 100,
          currency: "ILS",
          providerReference: "REF-1",
          createdAt: "2026-04-10T09:00:00.000Z",
          status: "pending",
        },
      ],
    }));

    const transport = createFinanceReadAdaptersTransport({
      invokeCallable,
      now: () => new Date(now),
    });

    const result = await transport.readTopUpQueue({
      venueId: "venue_001",
      statuses: ["pending"],
      limit: 20,
      correlationId: "corr-topup-1",
    });

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);
    expect(callableName).toBe("listMerchantTopUpRequestsForAdmin");
    expect(payload.venueId).toBe("venue_001");
    expect(payload.statuses).toEqual(["pending"]);
    expect(payload.limit).toBe(20);
    expect(payload.correlationId).toBe("corr-topup-1");

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("success");
      expect(result.data).toHaveLength(1);
      expect(result.data?.[0]?.id).toBe("req-1");
      expect(result.freshness.source).toBe("topup_queue");
      expect(result.freshness.channel).toBe(
        "callable:listMerchantTopUpRequestsForAdmin",
      );
    }
  });

  it("returns empty top-up queue when backend returns an empty requests array", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: "2026-04-10T10:00:00.000Z",
      requests: [],
    }));

    const transport = createFinanceReadAdaptersTransport({ invokeCallable });
    const result = await transport.readTopUpQueue({ limit: 10 });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("empty");
      expect(result.data).toBeNull();
    }
  });

  it("returns stale when top-up checkedAt exceeds configured max age", async () => {
    const now = new Date("2026-04-10T10:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T09:00:00.000Z").getTime(),
      requests: [
        {
          id: "req-1",
          userId: "u1",
          userName: "V",
          amount: 1,
          currency: "ILS",
          providerReference: "",
          createdAt: "2026-04-10T09:30:00.000Z",
          status: "pending",
        },
      ],
    }));

    const transport = createFinanceReadAdaptersTransport({
      invokeCallable,
      now: () => new Date(now),
    });

    const result = await transport.readTopUpQueue({ maxAgeMs: 60_000 });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("stale");
    }
  });

  it("maps wallet audit payload to success", async () => {
    const now = new Date("2026-04-10T10:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T09:59:30.000Z").getTime(),
      entries: [
        {
          id: "e1",
          venueId: "venue_001",
          userId: "admin-1",
          userName: "Admin operator",
          type: "debit",
          amount: 10,
          currency: "ILS",
          description: "Story promotion",
          reference: "story_promotion_x",
          createdAt: "2026-04-10T09:55:00.000Z",
        },
      ],
    }));

    const transport = createFinanceReadAdaptersTransport({
      invokeCallable,
      now: () => new Date(now),
    });

    const result = await transport.readWalletAudit({
      venueId: "venue_001",
      entryTypes: ["debit"],
      limit: 25,
    });

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);
    expect(callableName).toBe("listMerchantWalletLedgerEntriesForAdmin");
    expect(payload.venueId).toBe("venue_001");
    expect(payload.entryTypes).toEqual(["debit"]);
    expect(payload.limit).toBe(25);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("success");
      expect(result.data).toHaveLength(1);
      expect(result.freshness.channel).toBe(
        "callable:listMerchantWalletLedgerEntriesForAdmin",
      );
    }
  });

  it("returns empty wallet audit when entries array is empty", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: Date.now(),
      entries: [],
    }));

    const transport = createFinanceReadAdaptersTransport({ invokeCallable });
    const result = await transport.readWalletAudit({});

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("empty");
      expect(result.data).toBeNull();
    }
  });

  it("returns unavailable when wallet audit response is malformed", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: Date.now(),
      entries: [{ id: "bad" }],
    }));

    const transport = createFinanceReadAdaptersTransport({ invokeCallable });
    const result = await transport.readWalletAudit({});

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.state).toBe("unavailable");
      expect(result.retryable).toBe(true);
    }
  });

  it("normalizes top-up and wallet-audit unauthorized and forbidden errors", async () => {
    const topUnauthorized = createFinanceReadAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw { code: "unauthenticated", message: "sign in first" };
      }),
    });
    const tu = await topUnauthorized.readTopUpQueue({});
    expect(tu.ok).toBe(false);
    if (!tu.ok) expect(tu.state).toBe("unauthorized");

    const topForbidden = createFinanceReadAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw { code: "permission-denied", message: "nope" };
      }),
    });
    const tf = await topForbidden.readTopUpQueue({});
    expect(tf.ok).toBe(false);
    if (!tf.ok) expect(tf.state).toBe("forbidden");

    const walUnauthorized = createFinanceReadAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw { code: "unauthenticated", message: "sign in first" };
      }),
    });
    const wu = await walUnauthorized.readWalletAudit({});
    expect(wu.ok).toBe(false);
    if (!wu.ok) expect(wu.state).toBe("unauthorized");
  });

  it("maps readiness diagnostics to success when freshness is within threshold", async () => {
    const now = new Date("2026-04-10T10:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T09:59:00.000Z").getTime(),
      overallStatus: "WARN",
      failureChecks: [],
      warningChecks: ["read_models"],
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

    const transport = createFinanceReadAdaptersTransport({
      invokeCallable,
      now: () => new Date(now),
    });

    const result = await transport.readWalletReadiness({
      correlationId: "corr-readiness-1",
      reason: "admin-console-check",
    });

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);
    expect(callableName).toBe("verifyWalletOperationalReadiness");
    expect(payload.reason).toBe("admin-console-check");
    expect(payload.correlationId).toBe("corr-readiness-1");

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("success");
      expect(result.data?.overallStatus).toBe("warning");
      expect(result.data?.checks.length ?? 0).toBeGreaterThan(0);
      expect(result.freshness.source).toBe("wallet_readiness");
    }
  });

  it("returns stale when readiness checkedAt exceeds configured max age", async () => {
    const now = new Date("2026-04-10T10:00:00.000Z");
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: new Date("2026-04-10T09:00:00.000Z").toISOString(),
      overallStatus: "PASS",
      failureChecks: [],
      warningChecks: [],
      pricing: {
        status: "PASS",
        exists: true,
        issues: [],
      },
    }));

    const transport = createFinanceReadAdaptersTransport({
      invokeCallable,
      now: () => new Date(now),
    });

    const result = await transport.readWalletReadiness({
      maxAgeMs: 60_000,
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("stale");
      expect(result.freshness.ageMs).toBeGreaterThan(result.freshness.staleAfterMs);
    }
  });

  it("returns empty when readiness payload has no actionable diagnostics", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      checkedAt: "2026-04-10T10:00:00.000Z",
    }));

    const transport = createFinanceReadAdaptersTransport({ invokeCallable });
    const result = await transport.readWalletReadiness();

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.state).toBe("empty");
      expect(result.data).toBeNull();
    }
  });

  it("normalizes readiness unauthorized and forbidden errors", async () => {
    const unauthorizedTransport = createFinanceReadAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw {
          code: "unauthenticated",
          message: "sign in first",
        };
      }),
    });

    const unauthorizedResult = await unauthorizedTransport.readWalletReadiness();
    expect(unauthorizedResult.ok).toBe(false);
    if (!unauthorizedResult.ok) {
      expect(unauthorizedResult.state).toBe("unauthorized");
      expect(unauthorizedResult.retryable).toBe(false);
    }

    const forbiddenTransport = createFinanceReadAdaptersTransport({
      invokeCallable: createTypeSafeMockInvoker(async () => {
        throw {
          code: "permission-denied",
          message: "insufficient role",
        };
      }),
    });

    const forbiddenResult = await forbiddenTransport.readWalletReadiness();
    expect(forbiddenResult.ok).toBe(false);
    if (!forbiddenResult.ok) {
      expect(forbiddenResult.state).toBe("forbidden");
      expect(forbiddenResult.retryable).toBe(false);
    }
  });
});
