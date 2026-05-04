import { beforeEach, describe, expect, it } from "vitest";

import {
  __resetVenueDirectoryReadCacheForTests,
  filterVenueDirectoryItems,
  loadVenueDirectoryRead,
} from "./venue-directory-read-loader";
import { FIXTURE_FALLBACK_DISABLED_MESSAGE_AR } from "@/lib/admin/fixture-fallback-policy";
import type { VenueDirectoryReadData } from "./venue-directory-models";
import type { VenueDirectoryReadResult } from "./venue-directory-read-types";

function getSuccessData(result: VenueDirectoryReadResult<VenueDirectoryReadData>) {
  expect(result.kind).toBe("success");
  if (result.kind !== "success") {
    throw new Error("Expected success result");
  }
  return result;
}

beforeEach(() => {
  __resetVenueDirectoryReadCacheForTests();
});

describe("venue directory read loader", () => {
  it("returns callable-backed venue directory rows when callable transport is available", async () => {
    const result = await loadVenueDirectoryRead({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {},
      invokeCallable: async () => ({
        items: [
          {
            id: "venue_alpha",
            name_ar: "Venue Alpha",
            city: "Ramallah",
            categories: ["cafe"],
            is_active: true,
            wallet_available_balance: 42,
            wallet_currency: "ILS",
            merchant_uid: "merchant_alpha",
          },
        ],
        nextCursor: null,
      }),
    });

    const success = getSuccessData(result);
    expect(success.source).toContain("callable:listVenuesForAdmin");
    expect(success.data.items.length).toBe(1);
    expect(success.data.items[0].venueId).toBe("venue_alpha");
    expect(success.data.items[0].city).toBe("Ramallah");
    expect(success.data.items[0].venueNameEn).toBeNull();
    expect(success.data.items[0].phone).toBeNull();
    expect(success.data.items[0].subscriptionStatus).toBe("active");
    expect(success.data.items[0].visibilityStatus).toBe("visible");
    expect(success.data.items[0].operationalStatus).toBe("active");
    expect(success.data.summary.totalVenues).toBe(1);
    expect(success.data.summary.subscriptions.active).toBe(1);
    expect(success.data.filters.cities).toEqual(["Ramallah"]);
    expect(success.data.readBudget.sourceMode).toBe("admin_list_callable");
    expect(success.data.readBudget.partialResults).toBe(false);
  });

  it("returns unavailable state when force flag is enabled", async () => {
    const result = await loadVenueDirectoryRead({
      env: {
        WAIN_VENUE_DIRECTORY_FORCE_UNAVAILABLE: "1",
      },
    });

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.attemptedSource).toContain("forced_unavailable");
    }
  });

  it("marks snapshot as stale when as-of age exceeds configured threshold", async () => {
    const result = await loadVenueDirectoryRead({
      env: {
        WAIN_VENUE_DIRECTORY_FIXTURE_AS_OF: "2026-04-10T09:00:00.000Z",
        WAIN_VENUE_DIRECTORY_STALE_AFTER_MS: "60000",
        WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE: "1",
      },
      now: () => new Date("2026-04-10T10:30:00.000Z"),
    });

    const success = getSuccessData(result);
    expect(success.stale).toBe(true);
  });

  it("filters by search, city, and category using shared helper", async () => {
    const read = await loadVenueDirectoryRead({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {
        WAIN_VENUE_DIRECTORY_IDS: "venue_alpha,venue_nablus_bistro,venue_beta_cafe",
        WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE: "1",
      },
    });

    const success = getSuccessData(read);
    const bySearch = filterVenueDirectoryItems(success.data.items, {
      searchTerm: "nablus",
    });
    expect(bySearch.length).toBe(1);

    const byCityAndCategory = filterVenueDirectoryItems(success.data.items, {
      city: "Ramallah",
      category: "cafe",
    });
    expect(byCityAndCategory.length).toBe(1);
  });

  it("surfaces callable-to-fixture fallback honestly when live transport fails", async () => {
    let callCount = 0;
    const result = await loadVenueDirectoryRead({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {
        WAIN_VENUE_DIRECTORY_IDS: "venue_alpha",
        WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE: "1",
      },
      invokeCallable: async () => {
        callCount += 1;
        throw new Error("callable unavailable");
      },
    });

    const success = getSuccessData(result);
    expect(callCount).toBe(1);
    expect(success.source).toContain("callable:listVenuesForAdmin -> development_fixture");
    expect(success.data.readBudget.sourceMode).toBe("snapshot");
  });

  it("returns unavailable when fixture fallback is blocked in production", async () => {
    const result = await loadVenueDirectoryRead({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
        WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE: "1",
      },
    });

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
      expect(result.attemptedSource).toContain("fixture_fallback_disabled");
    }
  });

  it("reports admin venue list reads as full backend-linked reads", async () => {
    const result = await loadVenueDirectoryRead({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      env: {
        WAIN_VENUE_DIRECTORY_ADMIN_LIMIT: "1",
      },
      invokeCallable: async () => ({
        items: [
          {
            id: "venue_full",
            name_ar: "Venue Full",
            city: "Ramallah",
            categories: ["cafe"],
            is_active: true,
          },
        ],
      }),
    });

    const success = getSuccessData(result);
    expect(success.source).toContain("callable:listVenuesForAdmin");
    expect(success.data.readBudget.sourceMode).toBe("admin_list_callable");
    expect(success.data.readBudget.partialResults).toBe(false);
    expect(success.data.readBudget.maxResultsBudget).toBe(1);
    expect(success.data.readBudget.truncatedBounds).toEqual([]);
  });

  it("reuses cached read result when shared cache is explicitly enabled", async () => {
    const env = {
      WAIN_VENUE_DIRECTORY_SHARED_CACHE: "1",
      WAIN_VENUE_DIRECTORY_SHARED_CACHE_TTL_MS: "60000",
      WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE: "1",
      WAIN_VENUE_DIRECTORY_FIXTURE_AS_OF: "2026-04-10T10:00:00.000Z",
    };

    const first = getSuccessData(
      await loadVenueDirectoryRead({
        env,
        now: () => new Date("2026-04-10T10:00:00.000Z"),
      }),
    );

    const second = getSuccessData(
      await loadVenueDirectoryRead({
        env,
        now: () => new Date("2026-04-10T10:10:00.000Z"),
      }),
    );

    expect(second.fetchedAt).toBe(first.fetchedAt);
    expect(second.source).toBe(first.source);
    expect(second.data.items.length).toBe(first.data.items.length);
  });

  it("does not reuse read result when shared cache is disabled", async () => {
    const env = {
      WAIN_VENUE_DIRECTORY_SHARED_CACHE: "0",
      WAIN_VENUE_DIRECTORY_SKIP_FIRESTORE: "1",
      WAIN_VENUE_DIRECTORY_FIXTURE_AS_OF: "2026-04-10T10:00:00.000Z",
    };

    const first = getSuccessData(
      await loadVenueDirectoryRead({
        env,
        now: () => new Date("2026-04-10T10:00:00.000Z"),
      }),
    );

    const second = getSuccessData(
      await loadVenueDirectoryRead({
        env,
        now: () => new Date("2026-04-10T10:10:00.000Z"),
      }),
    );

    expect(second.fetchedAt).not.toBe(first.fetchedAt);
  });
});
