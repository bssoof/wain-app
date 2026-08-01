"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  googlePlaceIdFromVenue,
  isVenueDiscoverable,
  loadGooglePlacePhotos,
  normalizePhotoLimit,
} = require("../lib/place_photos");

test("normalizes requested photo limits", () => {
  assert.equal(normalizePhotoLimit(undefined), 3);
  assert.equal(normalizePhotoLimit(0), 1);
  assert.equal(normalizePhotoLimit(4.9), 4);
  assert.equal(normalizePhotoLimit(99), 10);
});

test("reads only Google Places source identifiers", () => {
  assert.equal(
    googlePlaceIdFromVenue({
      external_source: { provider: "google_places", place_id: "place-1" },
    }),
    "place-1",
  );
  assert.equal(
    googlePlaceIdFromVenue({
      external_source: { provider: "manual", place_id: "place-1" },
    }),
    "",
  );
});

test("rejects hidden or inactive venue documents", () => {
  assert.equal(isVenueDiscoverable({}), true);
  assert.equal(isVenueDiscoverable({ visibility_status: "hidden" }), false);
  assert.equal(isVenueDiscoverable({ operational_status: "inactive" }), false);
  assert.equal(isVenueDiscoverable({ subscription_status: "expired" }), false);
});

test("resolves short-lived photo URLs with their attribution", async () => {
  const requests = [];
  const fetchImpl = async (url, init) => {
    requests.push({ url, headers: init.headers });
    if (url.endsWith("/places/place-1")) {
      return {
        ok: true,
        status: 200,
        json: async () => ({
          photos: [
            {
              name: "places/place-1/photos/photo-a",
              googleMapsUri: "https://maps.google.com/photo-a",
              authorAttributions: [
                {
                  displayName: "Photo Owner",
                  uri: "https://maps.google.com/user-a",
                  photoUri: "https://example.test/avatar-a",
                },
              ],
            },
          ],
        }),
      };
    }
    return {
      ok: true,
      status: 200,
      json: async () => ({ photoUri: "https://example.test/photo-a.jpg" }),
    };
  };

  const photos = await loadGooglePlacePhotos({
    placeId: "place-1",
    apiKey: "test-key",
    fetchImpl,
  });

  assert.deepEqual(photos, [
    {
      photoUri: "https://example.test/photo-a.jpg",
      googleMapsUri: "https://maps.google.com/photo-a",
      authorName: "Photo Owner",
      authorUri: "https://maps.google.com/user-a",
      authorPhotoUri: "https://example.test/avatar-a",
    },
  ]);
  assert.equal(requests.length, 2);
  assert.equal(requests[0].headers["X-Goog-FieldMask"], "photos");
});
