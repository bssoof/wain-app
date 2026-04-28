import { auth, app } from "@/lib/firebase/client";

import {
  connectStorageEmulator,
  getDownloadURL,
  getStorage,
  ref,
  uploadBytes,
} from "firebase/storage";

export type VenueImageUploadKind = "photos" | "menu_images";

export type VenueImageUploadFailure = {
  fileName: string;
  reason: string;
};

export type VenueImageUploadResult = {
  uploadedUrls: string[];
  uploadedPaths: string[];
  failed: VenueImageUploadFailure[];
};

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const IMAGE_MIME_PREFIX = "image/";

let storageEmulatorConnected = false;

export async function uploadVenueImageBatch(input: {
  venueId: string;
  kind: VenueImageUploadKind;
  files: File[];
}): Promise<VenueImageUploadResult> {
  if (input.files.length === 0) {
    return {
      uploadedUrls: [],
      uploadedPaths: [],
      failed: [],
    };
  }

  if (!auth.currentUser) {
    throw new Error("Admin authentication is required before uploading images.");
  }

  const storage = resolveStorageClient();
  const uploadedUrls: string[] = [];
  const uploadedPaths: string[] = [];
  const failed: VenueImageUploadFailure[] = [];

  for (const file of input.files) {
    const validationError = validateImageFile(file);
    if (validationError) {
      failed.push({
        fileName: file.name,
        reason: validationError,
      });
      continue;
    }

    const storagePath = buildVenueImagePath(input.venueId, input.kind, file.name);

    try {
      const storageRef = ref(storage, storagePath);
      await uploadBytes(storageRef, file, {
        contentType: file.type || "application/octet-stream",
      });
      const downloadUrl = await getDownloadURL(storageRef);
      uploadedPaths.push(storagePath);
      uploadedUrls.push(downloadUrl);
    } catch (error) {
      failed.push({
        fileName: file.name,
        reason: toUploadErrorMessage(error),
      });
    }
  }

  return {
    uploadedUrls,
    uploadedPaths,
    failed,
  };
}

function resolveStorageClient() {
  const storage = getStorage(app);
  const useEmulators = process.env.NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS === "1";

  if (process.env.NODE_ENV === "development" && useEmulators && !storageEmulatorConnected) {
    const emulatorHost = process.env.NEXT_PUBLIC_FIREBASE_STORAGE_EMULATOR_HOST;
    const parsed = parseStorageEmulatorHost(emulatorHost);
    if (parsed) {
      connectStorageEmulator(storage, parsed.host, parsed.port);
      storageEmulatorConnected = true;
    }
  }

  return storage;
}

function parseStorageEmulatorHost(
  value: string | undefined,
): { host: string; port: number } | null {
  if (!value || value.trim().length === 0) {
    return null;
  }

  const [host, portValue] = value.trim().split(":");
  const port = Number(portValue);
  if (!host || !Number.isFinite(port) || port <= 0) {
    return null;
  }

  return {
    host,
    port,
  };
}

function validateImageFile(file: File): string | null {
  if (!file.type || !file.type.startsWith(IMAGE_MIME_PREFIX)) {
    return "Only image files are allowed.";
  }

  if (file.size <= 0) {
    return "Empty files cannot be uploaded.";
  }

  if (file.size > MAX_IMAGE_BYTES) {
    return "Image must be 5MB or smaller.";
  }

  return null;
}

function buildVenueImagePath(
  venueId: string,
  kind: VenueImageUploadKind,
  originalName: string,
): string {
  const folder = kind === "menu_images" ? "menu_images" : "photos";
  const timestamp = Date.now();
  const randomSuffix = Math.random().toString(36).slice(2, 8);
  const safeBaseName = sanitizeFileBaseName(originalName);
  const extension = inferImageExtension(originalName);

  return `venues/${venueId}/${folder}/${timestamp}_${randomSuffix}_${safeBaseName}.${extension}`;
}

function sanitizeFileBaseName(fileName: string): string {
  const withoutExtension = fileName.replace(/\.[^/.]+$/, "");
  const sanitized = withoutExtension
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);

  return sanitized || "image";
}

function inferImageExtension(fileName: string): string {
  const lower = fileName.toLowerCase();
  if (lower.endsWith(".png")) return "png";
  if (lower.endsWith(".webp")) return "webp";
  if (lower.endsWith(".gif")) return "gif";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "jpg";
  return "jpg";
}

function toUploadErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message;
  }

  if (typeof error === "string" && error.trim().length > 0) {
    return error.trim();
  }

  return "Image upload failed.";
}
