import { NextResponse } from "next/server";
import { runConfigHealthChecks } from "@/lib/admin/config-health/run-checks";
import { verifyReadinessRbac } from "@/lib/admin/route-guards/readiness-rbac";

export const runtime = "nodejs";

export async function GET(request: Request) {
  try {
    const guard = await verifyReadinessRbac(request, {
      endpoint: "/api/admin/health/config",
      allowedRoles: ["super_admin"],
    });

    if (!guard.ok) {
      return NextResponse.json(guard.body as Record<string, unknown>, {
        status: guard.status,
      });
    }

    const report = await runConfigHealthChecks();

    return NextResponse.json(report, {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    return NextResponse.json(
      { ok: false, reason: "internal_error" },
      { status: 500 }
    );
  }
}
