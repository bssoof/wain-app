import { NextResponse } from "next/server";

import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { adminDb } from "@/lib/firebase/server";

export const runtime = "nodejs";

type BannerSeverity = "info" | "warning" | "critical";

const CONFIG_COLLECTION = "app_config";
const CONFIG_DOCUMENT_ID = "admin_step_up";

export async function GET() {
  try {
    const session = await getCurrentAdminSession();
    if (!session) {
      return noStoreJson(
        { success: false, error: "Admin session required" },
        { status: 401 },
      );
    }

    const snapshot = await adminDb
      .collection(CONFIG_COLLECTION)
      .doc(CONFIG_DOCUMENT_ID)
      .get();
    const payload = snapshot.exists ? asRecord(snapshot.data()) : undefined;
    const rawMessage =
      typeof payload?.bannerMessage === "string"
        ? payload.bannerMessage.trim()
        : "";

    return noStoreJson({
      success: true,
      bannerMessage: rawMessage || null,
      bannerSeverity: normalizeBannerSeverity(payload?.bannerSeverity),
    });
  } catch {
    return noStoreJson(
      { success: false, error: "Failed to read admin banner config" },
      { status: 503 },
    );
  }
}

function normalizeBannerSeverity(value: unknown): BannerSeverity {
  return value === "warning" || value === "critical" || value === "info"
    ? value
    : "info";
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object"
    ? (value as Record<string, unknown>)
    : undefined;
}

function noStoreJson(body: Record<string, unknown>, init?: ResponseInit) {
  return NextResponse.json(body, {
    ...init,
    headers: {
      "Cache-Control": "no-store",
      ...(init?.headers ?? {}),
    },
  });
}
