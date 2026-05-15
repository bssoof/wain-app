import { beforeEach, describe, expect, it, vi } from "vitest";

import { loadVenueWorkspaceReadBundle } from "./venue-workspace-read-loader";
import { FIXTURE_FALLBACK_DISABLED_MESSAGE_AR } from "@/lib/admin/fixture-fallback-policy";

const mockAdminDb = {
  collection: vi.fn(),
};

vi.mock("@/lib/firebase/server", () => ({
  adminDb: mockAdminDb,
}));

describe("venue workspace read loader", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockAdminDb.collection.mockImplementation(() => {
      throw new Error("Firestore mock not configured");
    });
  });

  it("returns callable-backed workspace reads when admin callable transport is available", async () => {
    const result = await loadVenueWorkspaceReadBundle("venue_test_1", {
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {},
      invokeCallable: async () => ({
        checkedAt: "2026-04-10T09:58:00.000Z",
        context: {
          venueId: "venue_test_1",
          venueName: "Venue Server",
          walletBalance: 220,
          walletCurrency: "ILS",
          readinessStatus: "ready",
          readinessSummary: "Server-backed workspace snapshot.",
        },
        walletEntries: [
          {
            id: "entry_server_1",
            type: "credit",
            amount: 55,
            currency: "ILS",
            description: "Server entry",
            createdAt: "2026-04-10T09:57:00.000Z",
          },
        ],
        offers: [],
        stories: [],
        reviews: [],
      }),
    });

    expect(result.context.venueId).toBe("venue_test_1");
    expect(result.context.venueName).toBe("Venue Server");
    expect(result.wallet.kind).toBe("success");
    expect(result.offers.kind).toBe("success");
    expect(result.stories.kind).toBe("success");
    expect(result.reviews.kind).toBe("success");
    if (result.wallet.kind === "success") {
      expect(result.wallet.source).toBe("callable:getAdminVenueWorkspaceReadBundle");
      expect(result.wallet.data.entries[0].id).toBe("entry_server_1");
    }
  });

  it("returns unavailable state for all tabs when force flag is enabled", async () => {
    const result = await loadVenueWorkspaceReadBundle("venue_test_2", {
      env: {
        WAIN_VENUE_WORKSPACE_FORCE_UNAVAILABLE: "1",
      },
    });

    expect(result.wallet.kind).toBe("unavailable");
    expect(result.offers.kind).toBe("unavailable");
    expect(result.stories.kind).toBe("unavailable");
    expect(result.reviews.kind).toBe("unavailable");
  });

  it("marks reads as stale when snapshot age exceeds configured threshold", async () => {
    const result = await loadVenueWorkspaceReadBundle("venue_test_3", {
      env: {
        WAIN_VENUE_WORKSPACE_SKIP_FIRESTORE: "1",
        WAIN_VENUE_WORKSPACE_FIXTURE_AS_OF: "2026-04-10T09:00:00.000Z",
        WAIN_VENUE_WORKSPACE_STALE_AFTER_MS: "60000",
      },
      now: () => new Date("2026-04-10T10:30:00.000Z"),
    });

    expect(result.wallet.kind).toBe("success");
    if (result.wallet.kind === "success") {
      expect(result.wallet.stale).toBe(true);
      expect(result.wallet.source).toBe("development_fixture");
    }
  });

  it("falls back honestly to fixture when callable transport fails", async () => {
    const result = await loadVenueWorkspaceReadBundle("venue_test_4", {
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {
        WAIN_VENUE_WORKSPACE_SKIP_FIRESTORE: "1",
      },
      invokeCallable: async () => {
        throw new Error("callable unavailable");
      },
    });

    expect(result.wallet.kind).toBe("success");
    if (result.wallet.kind === "success") {
      expect(result.wallet.source).toContain(
        "callable:getAdminVenueWorkspaceReadBundle -> development_fixture",
      );
    }
  });

  it("loads real venue workspace reads from Firestore Admin in production when callable transport is unavailable", async () => {
    configureFirestoreWorkspaceMock({
      venueId: "venue_live_1",
      venue: {
        name_ar: "مطعم مباشر",
        is_active: true,
      },
      wallet: {
        available_balance: 150,
        low_balance_threshold: 10,
        currency: "ILS",
      },
      walletReport: {
        available_balance: 175,
        currency: "ILS",
      },
      walletEntries: [
        makeDoc("entry_1", {
          amount: 25,
          currency: "ILS",
          note: "Top-up credited",
          created_at: "2026-04-10T09:50:00.000Z",
        }),
      ],
      offers: [
        makeDoc("offer_1", {
          title_ar: "عرض مباشر",
          venue_id: "venue_live_1",
          start_at: "2026-04-10T08:00:00.000Z",
          end_at: "2026-04-11T08:00:00.000Z",
        }),
      ],
      stories: [
        makeDoc("story_1", {
          caption: "قصة مباشرة",
          venue_id: "venue_live_1",
          expires_at: "2026-04-11T08:00:00.000Z",
        }),
      ],
      reviews: [
        makeDoc("review_1", {
          author_name: "زائر مباشر",
          rating: 5,
          comment: "ممتاز",
          created_at: "2026-04-10T09:00:00.000Z",
        }),
      ],
    });

    const result = await loadVenueWorkspaceReadBundle("venue_live_1", {
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      },
      now: () => new Date("2026-04-10T10:00:00.000Z"),
    });

    expect(result.context.venueName).toBe("مطعم مباشر");
    expect(result.context.walletBalance).toBe(175);
    expect(result.wallet.kind).toBe("success");
    expect(result.offers.kind).toBe("success");
    expect(result.stories.kind).toBe("success");
    expect(result.reviews.kind).toBe("success");
    if (result.wallet.kind === "success") {
      expect(result.wallet.source).toBe("firestore:venue_workspace");
      expect(result.wallet.data.entries[0].id).toBe("entry_1");
    }
    if (result.offers.kind === "success") {
      expect(result.offers.data.items[0].title).toBe("عرض مباشر");
    }
  });

  it("returns unavailable tabs when fixture fallback is blocked in production", async () => {
    const result = await loadVenueWorkspaceReadBundle("venue_test_5", {
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      },
    });

    expect(result.wallet.kind).toBe("unavailable");
    if (result.wallet.kind === "unavailable") {
      expect(result.wallet.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
      expect(result.wallet.attemptedSource).toContain("fixture_fallback_disabled");
    }
  });
});

function configureFirestoreWorkspaceMock({
  venueId,
  venue,
  wallet,
  walletReport,
  walletEntries,
  offers,
  stories,
  reviews,
}: {
  venueId: string;
  venue: Record<string, unknown>;
  wallet?: Record<string, unknown>;
  walletReport?: Record<string, unknown>;
  walletEntries?: any[];
  offers?: any[];
  stories?: any[];
  reviews?: any[];
}) {
  const reviewsQuery = makeQuery(reviews ?? []);
  const walletEntriesQuery = makeQuery(walletEntries ?? []);
  const venueDoc = makeDoc(venueId, venue, {
    reviews: reviewsQuery,
  });
  const walletDoc = makeDoc(venueId, wallet ?? {}, {
    entries: walletEntriesQuery,
  });
  const walletReportDoc = makeDoc(venueId, walletReport ?? {});
  const offersQuery = makeQuery(offers ?? []);
  const storiesQuery = makeQuery(stories ?? []);

  mockAdminDb.collection.mockImplementation((name: string) => {
    if (name === "venues") {
      return makeCollection({ [venueId]: venueDoc });
    }
    if (name === "merchant_wallets") {
      return makeCollection({ [venueId]: walletDoc });
    }
    if (name === "merchant_wallet_reports") {
      return makeCollection({ [venueId]: walletReportDoc });
    }
    if (name === "offers") {
      return offersQuery;
    }
    if (name === "stories") {
      return storiesQuery;
    }
    throw new Error(`Unexpected collection ${name}`);
  });
}

function makeCollection(docsById: Record<string, any>) {
  return {
    doc: vi.fn((id: string) => docsById[id] ?? makeMissingDoc(id)),
  };
}

function makeDoc(
  id: string,
  data: Record<string, unknown>,
  subcollections: Record<string, any> = {},
) {
  return {
    id,
    exists: true,
    data: () => data,
    get: vi.fn(async () => makeDoc(id, data, subcollections)),
    collection: vi.fn((name: string) => subcollections[name] ?? makeQuery([])),
  };
}

function makeMissingDoc(id: string) {
  return {
    id,
    exists: false,
    data: () => undefined,
    get: vi.fn(async () => makeMissingDoc(id)),
    collection: vi.fn(() => makeQuery([])),
  };
}

function makeQuery(docs: any[]) {
  const query: any = {
    docs,
    where: vi.fn(() => query),
    orderBy: vi.fn(() => query),
    limit: vi.fn(() => query),
    get: vi.fn(async () => ({ docs })),
  };
  return query;
}
