import { NextRequest, NextResponse } from "next/server";

import {
  SessionVerificationError,
  verifyIdTokenForAdminSession,
} from "@/lib/auth/session-cookie";
import {
  StepUpIssueRateLimitError,
  assertStepUpIssueNotRateLimited,
  clearStepUpIssueFailures,
  recordStepUpIssueFailure,
} from "@/lib/auth/step-up-issue-rate-limit";
import {
  STEP_UP_COOKIE_NAME,
  STEP_UP_TTL_MS,
  isStepUpScope,
} from "@/lib/auth/step-up-required";
import {
  StepUpTokenError,
  issueStepUpTokenForIdToken,
} from "@/lib/auth/step-up-token";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  let rateLimitUid: string | undefined;

  try {
    const body = (await request.json()) as unknown;
    const bodyRecord =
      body && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const idToken = typeof bodyRecord.idToken === "string" ? bodyRecord.idToken : "";
    const scope = bodyRecord.scope;

    if (!idToken.trim()) {
      return noStoreJson(
        { success: false, error: "Missing idToken" },
        { status: 400 },
      );
    }

    if (!isStepUpScope(scope)) {
      return noStoreJson(
        { success: false, error: "Invalid step-up scope" },
        { status: 422 },
      );
    }

    const verified = await verifyIdTokenForAdminSession(idToken);
    rateLimitUid = verified.decodedIdToken.uid;
    await assertStepUpIssueNotRateLimited(rateLimitUid);

    const issued = await issueStepUpTokenForIdToken(idToken, scope);
    await clearStepUpIssueFailures(rateLimitUid);

    const response = noStoreJson({
      success: true,
      scope: issued.payload.scope,
      expiresAt: new Date(issued.expiresAtEpochMs).toISOString(),
      issuedAt: new Date(issued.payload.iat * 1000).toISOString(),
    });

    response.cookies.set({
      name: STEP_UP_COOKIE_NAME,
      value: issued.token,
      maxAge: Math.floor(STEP_UP_TTL_MS / 1000),
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      path: "/api/admin",
    });

    return response;
  } catch (error) {
    if (error instanceof StepUpIssueRateLimitError) {
      return noStoreJson(
        {
          success: false,
          error: error.message,
          retryAt: new Date(error.retryAtMs).toISOString(),
        },
        { status: 429 },
      );
    }

    if (error instanceof StepUpTokenError) {
      if (error.code === "stale_auth_time" && rateLimitUid) {
        const lockout = await recordStepUpIssueFailure(rateLimitUid);
        if (lockout.locked && lockout.retryAtMs) {
          return noStoreJson(
            {
              success: false,
              error: "Too many step-up attempts. Try again later.",
              retryAt: new Date(lockout.retryAtMs).toISOString(),
            },
            { status: 429 },
          );
        }
      }

      return noStoreJson(
        { success: false, error: mapStepUpTokenErrorMessage(error) },
        { status: mapStepUpTokenErrorStatus(error) },
      );
    }

    if (error instanceof SessionVerificationError) {
      const statusByCode: Record<string, number> = {
        missing_id_token: 400,
        recent_sign_in_required: 401,
        admin_inactive_or_missing: 403,
      };

      return noStoreJson(
        { success: false, error: error.message },
        { status: statusByCode[error.code] ?? 401 },
      );
    }

    return noStoreJson(
      { success: false, error: "Failed to issue step-up token" },
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

function mapStepUpTokenErrorStatus(error: StepUpTokenError): 400 | 401 | 422 | 503 {
  switch (error.code) {
    case "missing_id_token":
      return 400;
    case "invalid_scope":
      return 422;
    case "stale_auth_time":
      return 401;
    default:
      return 503;
  }
}

function mapStepUpTokenErrorMessage(error: StepUpTokenError): string {
  if (error.code === "stale_auth_time") {
    return "Fresh re-authentication is required";
  }

  return error.message;
}
