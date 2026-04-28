import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  __resetMediaCenterBaselineCacheForTests,
  loadMediaCenterBaseline,
} from "./media-center-baseline";
import type { MediaCenterBaseline, MediaSectionKey } from "./media-center-models";

function sectionByKey(
  baseline: MediaCenterBaseline,
  key: MediaSectionKey,
) {
  const section = baseline.sections.find((entry) => entry.key === key);
  expect(section).toBeTruthy();
  if (!section) {
    throw new Error(`Missing section for key ${key}`);
  }
  return section;
}

describe("media center baseline loader", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    __resetMediaCenterBaselineCacheForTests();
  });

  it("maps callable rows into explicit section states and source labels", async () => {
    const baseline = await loadMediaCenterBaseline({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable: async () => ({
        checkedAt: "2026-04-10T09:59:00.000Z",
        referenceIndex: {
          status: "healthy",
          asOf: "2026-04-10T09:58:00.000Z",
          detail: "ok",
        },
        topupProofs: [
          {
            id: "proof_1",
            venueId: "venue_a",
            mediaUrl: "venues/venue_a/wallet_topups/proof_1.jpg",
            createdAt: "2026-04-10T09:57:00.000Z",
            status: "pending",
            sourceCollection: "merchant_topup_requests",
            sourceDocumentId: "proof_doc_1",
            sourceLabel: "merchant_topup_requests/proof_doc_1",
            safety: {
              referenceType: "topup_request",
              referenceId: "proof_doc_1",
              referenceIndexStatus: "healthy",
              purgeBlocked: false,
            },
          },
        ],
        venuePhotos: [
          {
            id: "photo_1",
            venueId: "venue_a",
            mediaUrl: "venues/venue_a/photos/photo_1.jpg",
            updatedAt: "2026-04-10T09:57:30.000Z",
            sourceCollection: "venues",
            sourceDocumentId: "venue_a",
            sourceLabel: "venues/venue_a",
            safety: {
              referenceType: "venue",
              referenceId: "venue_a",
              referenceIndexStatus: "healthy",
              purgeBlocked: false,
            },
          },
        ],
        offerImages: [],
        storyImages: [],
      }),
    });

    expect(baseline.generatedAt).toBe("2026-04-10T09:59:00.000Z");

    const proofs = sectionByKey(baseline, "proofs");
    expect(proofs.state).toBe("success");
    expect(proofs.source).toBe("callable:getAdminMediaInventoryReadBundle");
    expect(proofs.items).toHaveLength(1);
    expect(proofs.items[0].sourceLabel).toBe("merchant_topup_requests/proof_doc_1");
    expect(proofs.items[0].sourceDocument).toBe("merchant_topup_requests/proof_doc_1");
    expect(proofs.items[0].referenceSafety).toBe("safe");
    expect(proofs.items[0].mediaUrl).toBe("venues/venue_a/wallet_topups/proof_1.jpg");

    const venuePhotos = sectionByKey(baseline, "venue_photos");
    expect(venuePhotos.state).toBe("success");
    expect(venuePhotos.items[0].sourceLabel).toBe("venues/venue_a");
    expect(venuePhotos.items[0].mediaUrl).toBe("venues/venue_a/photos/photo_1.jpg");

    expect(sectionByKey(baseline, "offer_images").state).toBe("empty");
    expect(sectionByKey(baseline, "story_images").state).toBe("empty");
  });

  it("marks sections stale when media reference index is stale", async () => {
    const baseline = await loadMediaCenterBaseline({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable: async () => ({
        checkedAt: "2026-04-10T09:59:30.000Z",
        referenceIndex: {
          status: "stale",
          asOf: "2026-04-10T09:00:00.000Z",
          detail: "lagging",
        },
        topupProofs: [
          {
            id: "proof_2",
            venueId: "venue_b",
            mediaUrl: "venues/venue_b/wallet_topups/proof_2.jpg",
            createdAt: "2026-04-10T09:57:00.000Z",
            sourceLabel: "merchant_topup_requests/proof_2",
            safety: {
              referenceType: "topup_request",
              referenceId: "proof_2",
              referenceIndexStatus: "stale",
              purgeBlocked: true,
            },
          },
        ],
        venuePhotos: [],
        offerImages: [],
        storyImages: [],
      }),
    });

    const proofs = sectionByKey(baseline, "proofs");
    expect(proofs.state).toBe("stale");
    expect(proofs.referenceSafetyNote).toMatch(/قديم/i);
    expect(proofs.items[0].referenceSafety).toBe("unknown");
  });

  it("skips malformed rows and keeps valid rows readable", async () => {
    const baseline = await loadMediaCenterBaseline({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable: async () => ({
        checkedAt: "2026-04-10T09:59:00.000Z",
        referenceIndex: {
          status: "healthy",
          asOf: "2026-04-10T09:58:00.000Z",
          detail: "ok",
        },
        topupProofs: [
          {
            invalid: true,
          },
          {
            id: "proof_3",
            venueId: "venue_c",
            mediaUrl: "venues/venue_c/wallet_topups/proof_3.jpg",
            createdAt: "2026-04-10T09:57:00.000Z",
            sourceLabel: "merchant_topup_requests/proof_3",
            safety: {
              referenceType: "topup_request",
              referenceId: "proof_3",
              referenceIndexStatus: "healthy",
              purgeBlocked: true,
            },
          },
        ],
        venuePhotos: [],
        offerImages: [],
        storyImages: [],
      }),
    });

    const proofs = sectionByKey(baseline, "proofs");
    expect(proofs.state).toBe("success");
    expect(proofs.items).toHaveLength(1);
    expect(proofs.message).toMatch(/تم تجاهل 1 عنصر\/عناصر غير صالحة/i);
  });

  it("marks section unavailable when payload shape is malformed", async () => {
    const baseline = await loadMediaCenterBaseline({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable: async () => ({
        checkedAt: "2026-04-10T09:59:00.000Z",
        referenceIndex: {
          status: "healthy",
          asOf: "2026-04-10T09:58:00.000Z",
          detail: "ok",
        },
        topupProofs: {
          broken: true,
        },
        venuePhotos: [],
        offerImages: [],
        storyImages: [],
      }),
    });

    const proofs = sectionByKey(baseline, "proofs");
    expect(proofs.state).toBe("unavailable");
    expect(proofs.message).toMatch(/غير صالحة|استجابة غير صالحة/i);
  });

  it("returns unavailable sections when callable source fails", async () => {
    const baseline = await loadMediaCenterBaseline({
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable: async () => {
        throw new Error("network_down");
      },
    });

    const proofs = sectionByKey(baseline, "proofs");
    const photos = sectionByKey(baseline, "venue_photos");
    const offers = sectionByKey(baseline, "offer_images");
    const stories = sectionByKey(baseline, "story_images");

    expect(proofs.state).toBe("unavailable");
    expect(photos.state).toBe("unavailable");
    expect(offers.state).toBe("unavailable");
    expect(stories.state).toBe("unavailable");
    expect(proofs.source).toBe("callable:getAdminMediaInventoryReadBundle");
    expect(proofs.message).toMatch(/network_down/i);
  });

  it("reuses media baseline when shared cache is explicitly enabled", async () => {
    const invokeCallable = vi.fn(async () => ({
      checkedAt: "2026-04-10T09:59:00.000Z",
      referenceIndex: {
        status: "healthy",
        asOf: "2026-04-10T09:58:00.000Z",
        detail: "ok",
      },
      topupProofs: [],
      venuePhotos: [],
      offerImages: [],
      storyImages: [],
    }));

    const env = {
      WAIN_MEDIA_CENTER_SHARED_CACHE: "1",
      WAIN_MEDIA_CENTER_SHARED_CACHE_TTL_MS: "10000",
    };

    const first = await loadMediaCenterBaseline({
      env,
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable,
    });

    const second = await loadMediaCenterBaseline({
      env,
      now: () => new Date("2026-04-10T10:10:00.000Z"),
      invokeCallable,
    });

    expect(second.generatedAt).toBe(first.generatedAt);
    expect(invokeCallable).toHaveBeenCalledTimes(1);
  });

  it("does not reuse media baseline when shared cache is disabled", async () => {
    const invokeCallable = vi
      .fn()
      .mockResolvedValueOnce({
        checkedAt: "2026-04-10T09:59:00.000Z",
        referenceIndex: {
          status: "healthy",
          asOf: "2026-04-10T09:58:00.000Z",
          detail: "ok",
        },
        topupProofs: [],
        venuePhotos: [],
        offerImages: [],
        storyImages: [],
      })
      .mockResolvedValueOnce({
        checkedAt: "2026-04-10T09:59:30.000Z",
        referenceIndex: {
          status: "healthy",
          asOf: "2026-04-10T09:58:30.000Z",
          detail: "ok",
        },
        topupProofs: [],
        venuePhotos: [],
        offerImages: [],
        storyImages: [],
      });

    const env = {
      WAIN_MEDIA_CENTER_SHARED_CACHE: "0",
    };

    const first = await loadMediaCenterBaseline({
      env,
      now: () => new Date("2026-04-10T10:00:00.000Z"),
      invokeCallable,
    });

    const second = await loadMediaCenterBaseline({
      env,
      now: () => new Date("2026-04-10T10:10:00.000Z"),
      invokeCallable,
    });

    expect(first.generatedAt).toBe("2026-04-10T09:59:00.000Z");
    expect(second.generatedAt).toBe("2026-04-10T09:59:30.000Z");
    expect(invokeCallable).toHaveBeenCalledTimes(2);
  });
});
