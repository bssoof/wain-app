import { NextResponse } from "next/server";
import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { checkRateLimit } from "@/lib/admin/config-health/rate-limit";
import { runConfigHealthChecks } from "@/lib/admin/config-health/run-checks";

export const runtime = "nodejs";

export async function GET(request: Request) {
  try {
    const session = await getCurrentAdminSession();
    
    if (!session) {
      return NextResponse.json(
        { ok: false, reason: "unauthenticated" },
        { status: 401 }
      );
    }

    if (!session.roles?.includes("super_admin")) {
      return NextResponse.json(
        { ok: false, reason: "forbidden" },
        { status: 403 }
      );
    }

    const ip = request.headers.get("x-forwarded-for") || "unknown";
    const rateLimit = checkRateLimit(ip);
    if (!rateLimit.allowed) {
      return NextResponse.json(
        { ok: false, status: "rate_limited", retryAt: rateLimit.retryAt },
        { status: 429 }
      );
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
