import type { DecodedIdToken } from "firebase-admin/auth";

import { adminAuth, adminDb } from "@/lib/firebase/server";

export const ADMIN_SESSION_COOKIE_NAME = "wain_admin_session";
export const ADMIN_HOSTING_SESSION_COOKIE_NAME = "__session";
export const ADMIN_SESSION_EXPIRES_IN_MS = 60 * 60 * 24 * 7 * 1000;

const RECENT_SIGN_IN_WINDOW_SECONDS = 5 * 60;
const DEFAULT_SESSION_VERIFICATION_CACHE_TTL_MS = 180_000;
const MAX_SESSION_VERIFICATION_CACHE_SIZE = 256;

type SessionVerificationErrorCode =
  | "missing_id_token"
  | "recent_sign_in_required"
  | "admin_inactive_or_missing";

type AdminDocData = {
  active?: unknown;
  role?: unknown;
  roles?: unknown;
  name?: unknown;
  email?: unknown;
};

export type ActiveAdminProfile = {
  uid: string;
  role?: unknown;
  roles?: unknown;
  name?: string;
  email?: string;
};

type VerifiedAdminSession = {
  decodedToken: DecodedIdToken;
  adminProfile: ActiveAdminProfile;
};

type SessionVerificationCacheEntry = {
  value: VerifiedAdminSession;
  expiresAt: number;
};

const g = globalThis as any;
g.sessionVerificationCache ??= new Map<string, SessionVerificationCacheEntry>();
const sessionVerificationCache: Map<string, SessionVerificationCacheEntry> = g.sessionVerificationCache;

function resolveSessionVerificationCacheTtlMs(): number {
  const rawValue = process.env.WAIN_ADMIN_SESSION_VERIFY_CACHE_TTL_MS;
  const parsed = rawValue ? Number(rawValue) : DEFAULT_SESSION_VERIFICATION_CACHE_TTL_MS;

  if (!Number.isFinite(parsed)) {
    return DEFAULT_SESSION_VERIFICATION_CACHE_TTL_MS;
  }

  return Math.max(0, Math.min(Math.floor(parsed), 60_000));
}

const SESSION_VERIFICATION_CACHE_TTL_MS = resolveSessionVerificationCacheTtlMs();

function resolveSessionVerificationRevocationCheck(): boolean {
  const rawValue = process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION;
  if (!rawValue) {
    return true;
  }

  const normalized = rawValue.trim().toLowerCase();
  if (normalized === "0" || normalized === "false" || normalized === "off") {
    return false;
  }

  if (normalized === "1" || normalized === "true" || normalized === "on") {
    return true;
  }

  return true;
}

function readSessionVerificationCache(sessionCookie: string): VerifiedAdminSession | null {
  if (SESSION_VERIFICATION_CACHE_TTL_MS <= 0) {
    return null;
  }

  const entry = sessionVerificationCache.get(sessionCookie);
  if (!entry) {
    return null;
  }

  if (entry.expiresAt <= Date.now()) {
    sessionVerificationCache.delete(sessionCookie);
    return null;
  }

  return entry.value;
}

function writeSessionVerificationCache(
  sessionCookie: string,
  value: VerifiedAdminSession,
): void {
  if (SESSION_VERIFICATION_CACHE_TTL_MS <= 0) {
    return;
  }

  sessionVerificationCache.set(sessionCookie, {
    value,
    expiresAt: Date.now() + SESSION_VERIFICATION_CACHE_TTL_MS,
  });

  if (sessionVerificationCache.size > MAX_SESSION_VERIFICATION_CACHE_SIZE) {
    const oldestKey = sessionVerificationCache.keys().next().value as
      | string
      | undefined;
    if (oldestKey) {
      sessionVerificationCache.delete(oldestKey);
    }
  }
}

function clearSessionVerificationCache(sessionCookie: string): void {
  sessionVerificationCache.delete(sessionCookie);
}

export function __resetSessionVerificationCacheForTests(): void {
  sessionVerificationCache.clear();
}

export class SessionVerificationError extends Error {
  readonly code: SessionVerificationErrorCode;

  constructor(code: SessionVerificationErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = "SessionVerificationError";
  }
}

function toOptionalString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed ? trimmed : undefined;
}

function assertRecentSignIn(decodedIdToken: DecodedIdToken): void {
  const authTimeSeconds = Number(decodedIdToken.auth_time);
  const elapsedSeconds = Date.now() / 1000 - authTimeSeconds;

  if (!Number.isFinite(authTimeSeconds) || elapsedSeconds > RECENT_SIGN_IN_WINDOW_SECONDS) {
    throw new SessionVerificationError(
      "recent_sign_in_required",
      "Recent sign in required",
    );
  }
}

export async function readActiveAdminProfile(
  uid: string,
): Promise<ActiveAdminProfile | null> {
  const adminDoc = await adminDb.collection("admins").doc(uid).get();
  if (!adminDoc.exists) {
    return null;
  }

  const data = (adminDoc.data() ?? {}) as AdminDocData;
  if (data.active === false) {
    return null;
  }

  return {
    uid,
    role: data.role,
    roles: data.roles,
    name: toOptionalString(data.name),
    email: toOptionalString(data.email),
  };
}

export async function verifyIdTokenForAdminSession(
  idToken: string,
): Promise<{ decodedIdToken: DecodedIdToken; adminProfile: ActiveAdminProfile }> {
  const normalizedToken = idToken.trim();
  if (!normalizedToken) {
    throw new SessionVerificationError("missing_id_token", "Missing idToken");
  }

  const decodedIdToken = await adminAuth.verifyIdToken(normalizedToken);
  assertRecentSignIn(decodedIdToken);

  const adminProfile = await readActiveAdminProfile(decodedIdToken.uid);
  if (!adminProfile) {
    throw new SessionVerificationError(
      "admin_inactive_or_missing",
      "Admin account is inactive or missing",
    );
  }

  return { decodedIdToken, adminProfile };
}

export async function createAdminSessionCookieFromIdToken(
  idToken: string,
): Promise<string> {
  const normalizedToken = idToken.trim();
  const { decodedIdToken, adminProfile } =
    await verifyIdTokenForAdminSession(normalizedToken);

  const sessionCookie = await adminAuth.createSessionCookie(normalizedToken, {
    expiresIn: ADMIN_SESSION_EXPIRES_IN_MS,
  });

  writeSessionVerificationCache(sessionCookie, {
    decodedToken: decodedIdToken,
    adminProfile,
  });

  return sessionCookie;
}

export async function verifyAdminSessionCookieWithProfile(
  sessionCookie: string,
): Promise<VerifiedAdminSession> {
  const _t0 = performance.now();
  const normalizedSessionCookie = sessionCookie.trim();
  const cachedVerification = readSessionVerificationCache(normalizedSessionCookie);
  if (cachedVerification) {
    console.log(`[PERF] verifyAdminSessionCookie: ${(performance.now() - _t0).toFixed(0)}ms (CACHE HIT)`);
    return cachedVerification;
  }

  const checkRevoked = resolveSessionVerificationRevocationCheck();
  const decodedToken = await adminAuth.verifySessionCookie(
    normalizedSessionCookie,
    checkRevoked,
  );
  const _t1 = performance.now();
  console.log(`[PERF] verifySessionCookie (Auth): ${(_t1 - _t0).toFixed(0)}ms`);
  const adminProfile = await readActiveAdminProfile(decodedToken.uid);
  console.log(`[PERF] readActiveAdminProfile (Firestore): ${(performance.now() - _t1).toFixed(0)}ms`);

  if (!adminProfile) {
    throw new SessionVerificationError(
      "admin_inactive_or_missing",
      "Admin account is inactive or missing",
    );
  }

  const verifiedSession: VerifiedAdminSession = { decodedToken, adminProfile };
  writeSessionVerificationCache(normalizedSessionCookie, verifiedSession);

  console.log(
    `[PERF] verifyAdminSessionCookie: ${(performance.now() - _t0).toFixed(0)}ms (FULL VERIFY${checkRevoked ? "" : " revocation=off"})`,
  );
  return verifiedSession;
}

export async function revokeSessionCookie(sessionCookie: string): Promise<void> {
  const normalizedSessionCookie = sessionCookie.trim();
  const decodedClaims = await adminAuth.verifySessionCookie(normalizedSessionCookie);
  clearSessionVerificationCache(normalizedSessionCookie);
  await adminAuth.revokeRefreshTokens(decodedClaims.sub);
}