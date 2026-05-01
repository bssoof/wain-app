import { NextRequest, NextResponse } from "next/server";

import {
  ADMIN_HOSTING_SESSION_COOKIE_NAME,
  ADMIN_SESSION_COOKIE_NAME,
  ADMIN_SESSION_EXPIRES_IN_MS,
  SessionVerificationError,
  createAdminSessionCookieFromIdToken,
  revokeSessionCookie,
} from "@/lib/auth/session-cookie";

export const runtime = "nodejs";

type SessionPostBody = {
  idToken?: unknown;
};

export async function POST(request: NextRequest) {
  try {
    const bodyResult = await readSessionPostBody(request);
    if (!bodyResult.ok) {
      return NextResponse.json(
        { success: false, error: bodyResult.error },
        { status: 400 },
      );
    }

    const body = bodyResult.body;
    const idToken = typeof body?.idToken === "string" ? body.idToken : "";

    if (!idToken) {
      return NextResponse.json(
        { success: false, error: "Missing idToken" },
        { status: 400 },
      );
    }

    const sessionCookie = await createAdminSessionCookieFromIdToken(idToken);
    const cookieOptions = {
      value: sessionCookie,
      maxAge: ADMIN_SESSION_EXPIRES_IN_MS / 1000,
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      path: "/",
      sameSite: "lax" as const,
    };

    const response = NextResponse.json({ success: true });
    response.cookies.set({
      name: ADMIN_SESSION_COOKIE_NAME,
      ...cookieOptions,
    });
    response.cookies.set({
      name: ADMIN_HOSTING_SESSION_COOKIE_NAME,
      ...cookieOptions,
    });

    return response;
  } catch (error) {
    if (error instanceof SessionVerificationError) {
      const statusByCode: Record<string, number> = {
        missing_id_token: 400,
        recent_sign_in_required: 401,
        admin_inactive_or_missing: 403,
      };

      return NextResponse.json(
        { success: false, error: error.message },
        { status: statusByCode[error.code] ?? 401 },
      );
    }

    console.error("Failed to create session:", error);
    return NextResponse.json(
      { success: false, error: "Failed to create session" },
      { status: 401 },
    );
  }
}

async function readSessionPostBody(
  request: NextRequest,
): Promise<
  | { ok: true; body: SessionPostBody }
  | { ok: false; error: "Malformed JSON body" | "Invalid request body" }
> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return { ok: false, error: "Malformed JSON body" };
  }

  if (!isRecord(body)) {
    return { ok: false, error: "Invalid request body" };
  }

  return { ok: true, body };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return (
    typeof value === "object" &&
    value !== null &&
    !Array.isArray(value)
  );
}

export async function DELETE(request: NextRequest) {
  const sessionCookie =
    request.cookies.get(ADMIN_SESSION_COOKIE_NAME)?.value ??
    request.cookies.get(ADMIN_HOSTING_SESSION_COOKIE_NAME)?.value;

  if (sessionCookie) {
    try {
      await revokeSessionCookie(sessionCookie);
    } catch {
      // Ignore cleanup failures and proceed with cookie deletion.
    }
  }

  const response = NextResponse.json({ success: true });
  response.cookies.delete(ADMIN_SESSION_COOKIE_NAME);
  response.cookies.delete(ADMIN_HOSTING_SESSION_COOKIE_NAME);
  return response;
}
