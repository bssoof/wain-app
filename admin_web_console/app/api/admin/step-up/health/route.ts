import { NextResponse } from "next/server";

import { runStepUpHealthChecks } from "@/lib/auth/step-up-health";
import { checkStepUpHealthRateLimit } from "@/lib/auth/step-up-health-rate-limit";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const rateLimit = checkStepUpHealthRateLimit(resolveClientIp(request));
  if (!rateLimit.ok) {
    return noStoreJson(
      {
        status: "rate_limited",
        timestamp: new Date().toISOString(),
        retryAt: new Date(rateLimit.retryAtMs).toISOString(),
      },
      { status: 429 },
    );
  }

  const report = await runStepUpHealthChecks();
  return noStoreJson(report, {
    status: report.status === "healthy" ? 200 : 503,
  });
}

function resolveClientIp(request: Request): string {
  const forwardedFor = request.headers.get("x-forwarded-for");
  const firstForwardedIp = forwardedFor?.split(",")[0]?.trim();
  return (
    firstForwardedIp ||
    request.headers.get("x-real-ip")?.trim() ||
    "unknown"
  );
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
