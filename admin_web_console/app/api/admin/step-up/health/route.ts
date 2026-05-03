import { NextResponse } from "next/server";

import { runStepUpHealthChecks } from "@/lib/auth/step-up-health";
import { verifyReadinessRbac } from "@/lib/admin/route-guards/readiness-rbac";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const guard = await verifyReadinessRbac(request, {
    endpoint: "/api/admin/step-up/health",
    allowedRoles: ["super_admin"],
  });

  if (!guard.ok) {
    return noStoreJson(guard.body as Record<string, unknown>, {
      status: guard.status,
    });
  }

  const report = await runStepUpHealthChecks();
  return noStoreJson(report, {
    status: report.status === "healthy" ? 200 : 503,
  });
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
