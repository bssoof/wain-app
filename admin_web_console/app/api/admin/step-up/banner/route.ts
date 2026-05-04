import { NextResponse } from "next/server";

import { adminDb } from "@/lib/firebase/server";
import { runConfigHealthChecks } from "@/lib/admin/config-health/run-checks";
import type { HealthReport } from "@/lib/admin/config-health/types";
import { verifyReadinessRbac } from "@/lib/admin/route-guards/readiness-rbac";

export const runtime = "nodejs";

type BannerSeverity = "info" | "warning" | "critical";

const CONFIG_COLLECTION = "app_config";
const CONFIG_DOCUMENT_ID = "admin_step_up";

export async function GET(request: Request) {
  try {
    const guard = await verifyReadinessRbac(request, {
      endpoint: "/api/admin/step-up/banner",
      allowedRoles: [
        "super_admin",
        "finance_admin",
        "content_admin",
        "support_admin",
        "ops_viewer",
      ],
    });

    if (!guard.ok) {
      // The original code returned { success: false, error: "Admin session required" } on 401.
      // For consistency with AWC-QA-010 we use the standard { ok: false, reason: ... } which is wrapped in guard.body.
      return noStoreJson(guard.body as Record<string, unknown>, {
        status: guard.status,
      });
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

    // Safe Fallback: isolated try/catch for health checks
    let configHealth: HealthReport | undefined = undefined;
    const sessionRoles = (guard.user as { roles?: string[] })?.roles || [];
    if (guard.role === "super_admin" || sessionRoles.includes("super_admin")) {
      try {
        configHealth = await runConfigHealthChecks();
      } catch (e) {
        console.error("Failed to run config health checks:", e);
        // We do not fail the banner response if config health fails
      }
    }

    return noStoreJson({
      success: true,
      bannerMessage: rawMessage || null,
      bannerSeverity: normalizeBannerSeverity(payload?.bannerSeverity),
      configHealth,
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
