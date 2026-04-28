"use server";

import { cookies } from "next/headers";
import {
  ADMIN_HOSTING_SESSION_COOKIE_NAME,
  ADMIN_SESSION_COOKIE_NAME,
  ADMIN_SESSION_EXPIRES_IN_MS,
  createAdminSessionCookieFromIdToken,
  revokeSessionCookie,
} from "@/lib/auth/session-cookie";

export async function createAdminSession(idToken: string) {
  try {
    const sessionCookie = await createAdminSessionCookieFromIdToken(idToken);
    const cookieOptions = {
      value: sessionCookie,
      maxAge: ADMIN_SESSION_EXPIRES_IN_MS / 1000,
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      path: "/",
      sameSite: "lax" as const,
    };

    const cookieStore = cookies();
    cookieStore.set({
      name: ADMIN_SESSION_COOKIE_NAME,
      ...cookieOptions,
    });
    cookieStore.set({
      name: ADMIN_HOSTING_SESSION_COOKIE_NAME,
      ...cookieOptions,
    });

    return { success: true };
  } catch (error) {
    console.error("Failed to create session:", error);
    return { success: false, error: "Failed to create session" };
  }
}

export async function destroyAdminSession() {
  const cookieStore = cookies();
  const sessionCookie =
    cookieStore.get(ADMIN_SESSION_COOKIE_NAME)?.value ??
    cookieStore.get(ADMIN_HOSTING_SESSION_COOKIE_NAME)?.value;

  if (sessionCookie) {
    try {
      await revokeSessionCookie(sessionCookie);
    } catch (e) {
      // Ignored
    }
  }

  cookieStore.delete(ADMIN_SESSION_COOKIE_NAME);
  cookieStore.delete(ADMIN_HOSTING_SESSION_COOKIE_NAME);
  return { success: true };
}
