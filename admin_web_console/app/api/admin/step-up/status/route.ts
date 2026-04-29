import { NextResponse } from "next/server";

import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { verifyStepUpForCommand } from "@/lib/auth/step-up-middleware";
import { isStepUpScope } from "@/lib/auth/step-up-required";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const searchParams = new URL(request.url).searchParams;
  const scope = searchParams.get("scope");
  const command = searchParams.get("command");

  if (!isStepUpScope(scope)) {
    return noStoreJson(
      { success: false, error: "Invalid step-up scope" },
      { status: 422 },
    );
  }

  if (!command || command.trim().length === 0) {
    return noStoreJson(
      { success: false, error: "Missing command" },
      { status: 400 },
    );
  }

  try {
    const session = await getCurrentAdminSession();
    const result = await verifyStepUpForCommand({
      request,
      session,
      scope,
      command,
    });

    if (!result.ok) {
      return noStoreJson({
        success: true,
        scope,
        command,
        sensitive: true,
        required: true,
        reason: result.error.details.reason,
      });
    }

    return noStoreJson({
      success: true,
      scope,
      command,
      sensitive: result.required,
      required: false,
      active: result.required,
      ...(result.payload
        ? {
            expiresAt: new Date(result.payload.exp * 1000).toISOString(),
            issuedAt: new Date(result.payload.iat * 1000).toISOString(),
          }
        : {}),
    });
  } catch {
    return noStoreJson(
      { success: false, error: "Failed to read step-up status" },
      { status: 503 },
    );
  }
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
