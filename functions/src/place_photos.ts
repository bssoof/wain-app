import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { requireAppCheck } from "./shared/app-check";

const GOOGLE_PLACES_API_KEY = "GOOGLE_PLACES_API_KEY";
const GOOGLE_PLACES_BASE_URL = "https://places.googleapis.com/v1";
const DEFAULT_PHOTO_LIMIT = 3;
const MAX_PHOTO_LIMIT = 10;

type FetchLike = (
  input: string,
  init?: RequestInit,
) => Promise<Pick<Response, "ok" | "status" | "json">>;

interface GoogleAuthorAttribution {
  displayName?: unknown;
  uri?: unknown;
  photoUri?: unknown;
}

interface GooglePhotoResource {
  name?: unknown;
  googleMapsUri?: unknown;
  authorAttributions?: unknown;
}

export interface VenuePlacePhoto {
  photoUri: string;
  googleMapsUri: string;
  authorName: string;
  authorUri: string;
  authorPhotoUri: string;
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export function normalizePhotoLimit(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return DEFAULT_PHOTO_LIMIT;
  }
  return Math.min(MAX_PHOTO_LIMIT, Math.max(1, Math.trunc(value)));
}

export function googlePlaceIdFromVenue(
  data: FirebaseFirestore.DocumentData,
): string {
  const source = data.external_source;
  if (!source || typeof source !== "object") return "";

  const provider = stringValue(source.provider).toLowerCase();
  if (provider !== "google_places") return "";
  return stringValue(source.place_id);
}

export function isVenueDiscoverable(
  data: FirebaseFirestore.DocumentData,
): boolean {
  const visibility = stringValue(data.visibility_status || "visible").toLowerCase();
  const operational = stringValue(data.operational_status || "active").toLowerCase();
  const subscription = stringValue(data.subscription_status || "active").toLowerCase();
  return visibility === "visible" &&
    operational === "active" &&
    subscription === "active";
}

function authorFromPhoto(photo: GooglePhotoResource): GoogleAuthorAttribution {
  const authors = photo.authorAttributions;
  if (!Array.isArray(authors) || authors.length === 0) return {};
  const first = authors[0];
  return first && typeof first === "object"
    ? first as GoogleAuthorAttribution
    : {};
}

async function fetchGoogleJson(
  url: string,
  apiKey: string,
  fetchImpl: FetchLike,
  fieldMask?: string,
): Promise<Record<string, unknown>> {
  const headers: Record<string, string> = {
    "X-Goog-Api-Key": apiKey,
  };
  if (fieldMask) headers["X-Goog-FieldMask"] = fieldMask;

  const response = await fetchImpl(url, { headers });
  if (!response.ok) {
    throw new Error(`google_places_http_${response.status}`);
  }
  const json = await response.json();
  if (!json || typeof json !== "object") {
    throw new Error("google_places_response_invalid");
  }
  return json as Record<string, unknown>;
}

export async function loadGooglePlacePhotos({
  placeId,
  apiKey,
  limit = DEFAULT_PHOTO_LIMIT,
  fetchImpl = fetch,
}: {
  placeId: string;
  apiKey: string;
  limit?: number;
  fetchImpl?: FetchLike;
}): Promise<VenuePlacePhoto[]> {
  const encodedPlaceId = encodeURIComponent(placeId);
  const details = await fetchGoogleJson(
    `${GOOGLE_PLACES_BASE_URL}/places/${encodedPlaceId}`,
    apiKey,
    fetchImpl,
    "photos",
  );
  const resources = Array.isArray(details.photos)
    ? details.photos.slice(0, normalizePhotoLimit(limit))
    : [];

  const photos: VenuePlacePhoto[] = [];
  for (const rawResource of resources) {
    if (!rawResource || typeof rawResource !== "object") continue;
    const resource = rawResource as GooglePhotoResource;
    const name = stringValue(resource.name);
    if (!name.startsWith(`places/${placeId}/photos/`)) continue;

    const media = await fetchGoogleJson(
      `${GOOGLE_PLACES_BASE_URL}/${name}/media?maxWidthPx=1600&skipHttpRedirect=true`,
      apiKey,
      fetchImpl,
    );
    const photoUri = stringValue(media.photoUri);
    if (!photoUri.startsWith("https://")) continue;

    const author = authorFromPhoto(resource);
    photos.push({
      photoUri,
      googleMapsUri: stringValue(resource.googleMapsUri),
      authorName: stringValue(author.displayName),
      authorUri: stringValue(author.uri),
      authorPhotoUri: stringValue(author.photoUri),
    });
  }
  return photos;
}

export const getVenuePlacePhotos = functions
  .runWith({
    secrets: [GOOGLE_PLACES_API_KEY],
    timeoutSeconds: 15,
    memory: "256MB",
    maxInstances: 10,
  })
  .https.onCall(async (data, context) => {
    if (process.env.FUNCTIONS_EMULATOR !== "true") {
      requireAppCheck(context);
    }

    const venueId = stringValue(data?.venueId);
    if (!/^[A-Za-z0-9_-]{1,128}$/.test(venueId)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "venue_id_invalid",
      );
    }

    const venueDoc = await admin.firestore().collection("venues").doc(venueId).get();
    if (!venueDoc.exists) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }

    const venue = venueDoc.data() ?? {};
    if (!isVenueDiscoverable(venue)) {
      throw new functions.https.HttpsError("not-found", "venue_not_found");
    }
    const placeId = googlePlaceIdFromVenue(venue);
    if (!placeId) return { photos: [], source: "google_maps" };

    const apiKey = stringValue(process.env[GOOGLE_PLACES_API_KEY]);
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "places_api_not_configured",
      );
    }

    try {
      const photos = await loadGooglePlacePhotos({
        placeId,
        apiKey,
        limit: normalizePhotoLimit(data?.limit),
      });
      return { photos, source: "google_maps" };
    } catch (error) {
      functions.logger.warn("place_photos_fetch_failed", {
        venueId,
        error: error instanceof Error ? error.message : "unknown_error",
      });
      throw new functions.https.HttpsError(
        "unavailable",
        "place_photos_unavailable",
      );
    }
  });
