import { NextRequest, NextResponse } from "next/server";
import { getStorage } from "firebase-admin/storage";

import { canAccessRoute } from "@/lib/auth/guard-api";
import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { getAdminApp } from "@/lib/firebase/server";

export const runtime = "nodejs";

const TOPUP_PROOF_PATH_PATTERN = /^venues\/[^/]+\/wallet_topups\/[^/]+$/;

export async function GET(request: NextRequest) {
  const session = await getCurrentAdminSession();
  if (!session) {
    return jsonError("Admin session required.", 401);
  }

  if (!canAccessRoute(session, "topups")) {
    return jsonError("Forbidden.", 403);
  }

  const storagePath = request.nextUrl.searchParams.get("path")?.trim() ?? "";
  if (!isValidTopupProofPath(storagePath)) {
    return jsonError("Invalid proof path.", 422);
  }

  try {
    const file = resolveStorageBucket().file(storagePath);
    const [exists] = await file.exists();
    if (!exists) {
      return jsonError("Proof file was not found.", 404);
    }

    const [[buffer], [metadata]] = await Promise.all([
      file.download(),
      file.getMetadata(),
    ]);
    const contentType =
      typeof metadata.contentType === "string" && metadata.contentType.trim()
        ? metadata.contentType
        : "application/octet-stream";

    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        "Cache-Control": "private, no-store",
        "Content-Disposition": `inline; filename="${encodeHeaderFilename(storagePath)}"`,
        "Content-Type": contentType,
        "X-Content-Type-Options": "nosniff",
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonError(`Failed to load proof file: ${message}`, 503);
  }
}

function isValidTopupProofPath(value: string): boolean {
  return (
    TOPUP_PROOF_PATH_PATTERN.test(value) &&
    !value.includes("..") &&
    !value.startsWith("/") &&
    !value.includes("\\")
  );
}

function resolveStorageBucket() {
  const app = getAdminApp();
  const configuredBucket =
    app.options.storageBucket ||
    process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ||
    process.env.FIREBASE_STORAGE_BUCKET ||
    process.env.STORAGE_BUCKET ||
    resolveFallbackStorageBucketName();

  return getStorage(app).bucket(configuredBucket);
}

function resolveFallbackStorageBucketName(): string {
  const projectId =
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID ||
    "wain-d2e28";

  return `${projectId}.firebasestorage.app`;
}

function encodeHeaderFilename(storagePath: string): string {
  return storagePath.split("/").pop()?.replace(/["\\]/g, "_") || "topup-proof";
}

function jsonError(message: string, status: 401 | 403 | 404 | 422 | 503) {
  return NextResponse.json(
    { success: false, error: message },
    {
      status,
      headers: {
        "Cache-Control": "no-store",
      },
    },
  );
}
