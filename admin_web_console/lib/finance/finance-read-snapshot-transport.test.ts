import { beforeEach, describe, expect, it, vi } from "vitest";

const { getAdminDbMock } = vi.hoisted(() => ({
  getAdminDbMock: vi.fn(),
}));

vi.mock("@/lib/firebase/server", () => ({
  get adminDb() {
    return getAdminDbMock();
  },
}));

import {
  __financeReadSnapshotTransportForTests,
  createFinanceReadSnapshotTransport,
} from "./finance-read-snapshot-transport";

const {
  loadLedgerEntriesWithFallback,
  resetOrderedLedgerQueryRetryCooldown,
  resetSharedSnapshotCaches,
} =
  __financeReadSnapshotTransportForTests;

beforeEach(() => {
  resetOrderedLedgerQueryRetryCooldown();
  resetSharedSnapshotCaches();
  getAdminDbMock.mockReset();
});

function makeLedgerDoc(id: string, createdAt: string, venueId = "venue_1") {
  return {
    id,
    data: () => ({ created_at: createdAt }),
    ref: {
      parent: {
        parent: {
          id: venueId,
        },
      },
    },
  };
}

function makeWalletDoc(id: string, docs: any[]) {
  return {
    id,
    ref: {
      collection: vi.fn((_collectionName: string) => ({
        limit: vi.fn((limit: number) => ({
          get: vi.fn(async () => ({ docs: docs.slice(0, limit) })),
        })),
      })),
    },
  };
}

function makeTopupDoc(id: string, venueId: string, createdAt: string) {
  return {
    id,
    data: () => ({
      venue_id: venueId,
      requested_by_uid: `${venueId}_merchant`,
      amount: 125,
      currency: "ILS",
      transfer_reference: `${id}_trx`,
      created_at: createdAt,
      status: "pending",
    }),
  };
}

describe("loadLedgerEntriesWithFallback", () => {
  it("recovers using unordered collectionGroup when ordered query fails precondition", async () => {
    const orderedGet = vi
      .fn()
      .mockRejectedValue({ code: "failed-precondition", message: "index required" });

    const unorderedDocs = [
      makeLedgerDoc("entry_old", "2026-04-10T10:00:00.000Z"),
      makeLedgerDoc("entry_new", "2026-04-10T12:00:00.000Z"),
      makeLedgerDoc("entry_mid", "2026-04-10T11:00:00.000Z"),
    ];
    const unorderedGet = vi.fn().mockResolvedValue({ docs: unorderedDocs });

    const collectionGroup = vi.fn(() => ({
      orderBy: vi.fn(() => ({
        limit: vi.fn(() => ({ get: orderedGet })),
      })),
      limit: vi.fn(() => ({ get: unorderedGet })),
    }));

    const merchantWalletsGet = vi.fn();
    const adminDb = {
      collectionGroup,
      collection: vi.fn((name: string) => {
        if (name === "merchant_wallets") {
          return {
            limit: vi.fn(() => ({ get: merchantWalletsGet })),
          };
        }
        throw new Error(`Unexpected collection: ${name}`);
      }),
    };

    const docs = await loadLedgerEntriesWithFallback(adminDb, 2, {
      env: {
        WAIN_FINANCE_LEDGER_UNORDERED_OVERSCAN_FACTOR: "3",
      },
      getHintVenueIds: async () => [],
    });

    expect(docs).toHaveLength(2);
    expect(docs[0].id).toBe("entry_new");
    expect(docs[1].id).toBe("entry_mid");
    expect(unorderedGet).toHaveBeenCalledTimes(1);
    expect(merchantWalletsGet).not.toHaveBeenCalled();
  });

  it("falls back to wallet fan-out when unordered collectionGroup also fails", async () => {
    const orderedGet = vi
      .fn()
      .mockRejectedValue({ code: "failed-precondition", message: "index required" });
    const unorderedGet = vi
      .fn()
      .mockRejectedValue(new Error("collectionGroup transport unavailable"));

    const collectionGroup = vi.fn(() => ({
      orderBy: vi.fn(() => ({
        limit: vi.fn(() => ({ get: orderedGet })),
      })),
      limit: vi.fn(() => ({ get: unorderedGet })),
    }));

    const walletAEntries = [makeLedgerDoc("wallet_a_new", "2026-04-10T12:00:00.000Z", "wallet_a")];
    const walletBEntries = [makeLedgerDoc("wallet_b_old", "2026-04-10T11:00:00.000Z", "wallet_b")];

    const walletDocs = [
      makeWalletDoc("wallet_a", walletAEntries),
      makeWalletDoc("wallet_b", walletBEntries),
    ];

    const merchantWalletsGet = vi.fn().mockResolvedValue({
      empty: false,
      size: walletDocs.length,
      docs: walletDocs,
    });

    const adminDb = {
      collectionGroup,
      collection: vi.fn((name: string) => {
        if (name === "merchant_wallets") {
          return {
            limit: vi.fn(() => ({ get: merchantWalletsGet })),
          };
        }
        throw new Error(`Unexpected collection: ${name}`);
      }),
    };

    const docs = await loadLedgerEntriesWithFallback(adminDb, 2, {
      env: {
        WAIN_FINANCE_LEDGER_FALLBACK_WALLETS_SCAN_LIMIT: "10",
      },
      getHintVenueIds: async () => [],
    });

    expect(merchantWalletsGet).toHaveBeenCalledTimes(1);
    expect(docs).toHaveLength(2);
    expect(docs[0].id).toBe("wallet_a_new");
    expect(docs[1].id).toBe("wallet_b_old");
  });

  it("skips ordered collectionGroup during cooldown after prior precondition failure", async () => {
    const orderedGet = vi
      .fn()
      .mockRejectedValue({ code: "failed-precondition", message: "index required" });

    const unorderedDocs = [
      makeLedgerDoc("entry_1", "2026-04-10T12:00:00.000Z"),
      makeLedgerDoc("entry_2", "2026-04-10T11:00:00.000Z"),
    ];
    const unorderedGet = vi.fn().mockResolvedValue({ docs: unorderedDocs });

    const collectionGroup = vi.fn(() => ({
      orderBy: vi.fn(() => ({
        limit: vi.fn(() => ({ get: orderedGet })),
      })),
      limit: vi.fn(() => ({ get: unorderedGet })),
    }));

    const adminDb = {
      collectionGroup,
      collection: vi.fn((name: string) => {
        if (name === "merchant_wallets") {
          return {
            limit: vi.fn(() => ({
              get: vi.fn().mockResolvedValue({ empty: true, size: 0, docs: [] }),
            })),
          };
        }
        throw new Error(`Unexpected collection: ${name}`);
      }),
    };

    await loadLedgerEntriesWithFallback(adminDb, 2, {
      env: {
        WAIN_FINANCE_LEDGER_ORDERED_QUERY_RETRY_COOLDOWN_MS: "60000",
      },
      getHintVenueIds: async () => [],
    });

    await loadLedgerEntriesWithFallback(adminDb, 2, {
      env: {
        WAIN_FINANCE_LEDGER_ORDERED_QUERY_RETRY_COOLDOWN_MS: "60000",
      },
      getHintVenueIds: async () => [],
    });

    expect(orderedGet).toHaveBeenCalledTimes(1);
    expect(unorderedGet).toHaveBeenCalledTimes(2);
  });
});

describe("createFinanceReadSnapshotTransport segmented loads", () => {
  it("does not issue ledger collectionGroup reads for topups/readiness paths", async () => {
    const topupsGet = vi.fn().mockResolvedValue({
      docs: [makeTopupDoc("topup_1", "venue_alpha", "2026-04-10T11:30:00.000Z")],
    });
    const reportsGet = vi.fn().mockResolvedValue({
      size: 1,
      docs: [
        {
          id: "venue_alpha",
          data: () => ({
            available_balance: 140,
            low_balance_threshold: 20,
          }),
        },
      ],
    });

    const orderedLedgerGet = vi.fn().mockResolvedValue({
      docs: [makeLedgerDoc("ledger_1", "2026-04-10T11:45:00.000Z", "venue_alpha")],
    });
    const unorderedLedgerGet = vi.fn().mockResolvedValue({ docs: [] });
    const collectionGroup = vi.fn(() => ({
      orderBy: vi.fn(() => ({
        limit: vi.fn(() => ({ get: orderedLedgerGet })),
      })),
      limit: vi.fn(() => ({ get: unorderedLedgerGet })),
    }));

    const adminDb = {
      collectionGroup,
      collection: vi.fn((name: string) => {
        if (name === "merchant_topup_requests") {
          return {
            orderBy: vi.fn(() => ({
              limit: vi.fn(() => ({ get: topupsGet })),
            })),
            limit: vi.fn(() => ({ get: topupsGet })),
          };
        }

        if (name === "merchant_wallet_reports") {
          return {
            limit: vi.fn(() => ({ get: reportsGet })),
          };
        }

        if (name === "venues") {
          return {
            doc: vi.fn((venueId: string) => ({ id: venueId })),
          };
        }

        throw new Error(`Unexpected collection in test: ${name}`);
      }),
      getAll: vi.fn(async (...refs: Array<{ id: string }>) =>
        refs.map((ref) => ({
          id: ref.id,
          data: () => ({ name_ar: `Venue ${ref.id}` }),
        })),
      ),
    };

    getAdminDbMock.mockReturnValue(adminDb);

    const transport = createFinanceReadSnapshotTransport({
      env: {
        NODE_ENV: "development",
        VITEST: "false",
        WAIN_FINANCE_SHARED_SNAPSHOT_CACHE_TTL_MS: "5000",
      },
      now: () => new Date("2026-04-10T12:00:00.000Z"),
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });

    const [topupsResult, readinessResult] = await Promise.all([
      transport.readTopUpQueue({ maxAgeMs: 120_000 }),
      transport.readWalletReadiness({ maxAgeMs: 120_000 }),
    ]);

    expect(topupsResult.ok).toBe(true);
    expect(readinessResult.ok).toBe(true);
    expect(collectionGroup).not.toHaveBeenCalled();
    expect(topupsGet).toHaveBeenCalledTimes(1);

    await transport.readWalletAudit({ maxAgeMs: 120_000 });
    expect(collectionGroup).toHaveBeenCalledTimes(1);
  }, 10_000);

  it("reuses venue name lookups across transport instances when enabled", async () => {
    const topupsGet = vi.fn().mockResolvedValue({
      docs: [makeTopupDoc("topup_1", "venue_alpha", "2026-04-10T11:30:00.000Z")],
    });

    const getAll = vi.fn(async (...refs: Array<{ id: string }>) =>
      refs.map((ref) => ({
        id: ref.id,
        data: () => ({ name_ar: `Venue ${ref.id}` }),
      })),
    );

    const adminDb = {
      collectionGroup: vi.fn(),
      collection: vi.fn((name: string) => {
        if (name === "merchant_topup_requests") {
          return {
            orderBy: vi.fn(() => ({
              limit: vi.fn(() => ({ get: topupsGet })),
            })),
            limit: vi.fn(() => ({ get: topupsGet })),
          };
        }

        if (name === "venues") {
          return {
            doc: vi.fn((venueId: string) => ({ id: venueId })),
          };
        }

        throw new Error(`Unexpected collection in test: ${name}`);
      }),
      getAll,
    };

    getAdminDbMock.mockReturnValue(adminDb);

    const makeTransport = () =>
      createFinanceReadSnapshotTransport({
        env: {
          NODE_ENV: "development",
          VITEST: "false",
          WAIN_FINANCE_SHARED_SNAPSHOT_CACHE: "0",
          WAIN_FINANCE_VENUE_NAME_CACHE_TTL_MS: "60000",
        },
        now: () => new Date("2026-04-10T12:00:00.000Z"),
        fetchImpl: vi.fn() as unknown as typeof fetch,
      });

    await makeTransport().readTopUpQueue({ maxAgeMs: 120_000 });
    await makeTransport().readTopUpQueue({ maxAgeMs: 120_000 });

    expect(topupsGet).toHaveBeenCalledTimes(2);
    expect(getAll).toHaveBeenCalledTimes(1);
  });

  it("honors venue name cache opt-out env flag", async () => {
    const topupsGet = vi.fn().mockResolvedValue({
      docs: [makeTopupDoc("topup_1", "venue_alpha", "2026-04-10T11:30:00.000Z")],
    });

    const getAll = vi.fn(async (...refs: Array<{ id: string }>) =>
      refs.map((ref) => ({
        id: ref.id,
        data: () => ({ name_ar: `Venue ${ref.id}` }),
      })),
    );

    const adminDb = {
      collectionGroup: vi.fn(),
      collection: vi.fn((name: string) => {
        if (name === "merchant_topup_requests") {
          return {
            orderBy: vi.fn(() => ({
              limit: vi.fn(() => ({ get: topupsGet })),
            })),
            limit: vi.fn(() => ({ get: topupsGet })),
          };
        }

        if (name === "venues") {
          return {
            doc: vi.fn((venueId: string) => ({ id: venueId })),
          };
        }

        throw new Error(`Unexpected collection in test: ${name}`);
      }),
      getAll,
    };

    getAdminDbMock.mockReturnValue(adminDb);

    const makeTransport = () =>
      createFinanceReadSnapshotTransport({
        env: {
          NODE_ENV: "development",
          VITEST: "false",
          WAIN_FINANCE_SHARED_SNAPSHOT_CACHE: "0",
          WAIN_FINANCE_VENUE_NAME_CACHE: "0",
          WAIN_FINANCE_VENUE_NAME_CACHE_TTL_MS: "60000",
        },
        now: () => new Date("2026-04-10T12:00:00.000Z"),
        fetchImpl: vi.fn() as unknown as typeof fetch,
      });

    await makeTransport().readTopUpQueue({ maxAgeMs: 120_000 });
    await makeTransport().readTopUpQueue({ maxAgeMs: 120_000 });

    expect(topupsGet).toHaveBeenCalledTimes(2);
    expect(getAll).toHaveBeenCalledTimes(2);
  });
});
