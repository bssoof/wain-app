import { describe, expect, it } from "vitest";

import { loadVenueWorkspaceReadBundle } from "./venue-workspace-read-loader";
import { FIXTURE_FALLBACK_DISABLED_MESSAGE_AR } from "@/lib/admin/fixture-fallback-policy";

describe("venue workspace read loader", () => {
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
