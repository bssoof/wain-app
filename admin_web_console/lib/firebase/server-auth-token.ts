import "server-only";

import { getAdminAuth } from "@/lib/firebase/server";

const DEFAULT_FIREBASE_API_KEY = "AIzaSyC9YKkNcRIbFkVeiO-sBbA2zgJxEzm6rlM";
const TOKEN_REFRESH_BUFFER_MS = 60_000;
const FALLBACK_TOKEN_TTL_MS = 50 * 60 * 1000;
const SERVER_AUTH_REFRESH_TOKEN_ENV_KEYS = [
  "WAIN_SERVER_AUTH_REFRESH_TOKEN",
  "WAIN_FINANCE_SERVER_AUTH_REFRESH_TOKEN",
  "WAIN_VENUE_SERVER_AUTH_REFRESH_TOKEN",
  "WAIN_CONTENT_SERVER_AUTH_REFRESH_TOKEN",
  "WAIN_CONFIG_SERVER_AUTH_REFRESH_TOKEN",
  "WAIN_MEDIA_SERVER_AUTH_REFRESH_TOKEN",
] as const;

type ServerProxySession = {
  uid: string;
  primaryRole: string;
  roles: string[];
};

type CachedAuthToken = {
  token: string;
  expiresAtEpochMs: number;
};

const cachedAuthTokens = new Map<string, CachedAuthToken>();
const inflightAuthTokenRequests = new Map<string, Promise<string | undefined>>();

export async function resolveServerAuthTokenForAdminProxy(
  session: ServerProxySession,
  env: Record<string, string | undefined> = process.env,
): Promise<string | undefined> {
  const normalizedSession = normalizeSession(session);
  const cacheKey = buildCacheKey(normalizedSession);
  const now = Date.now();

  const cached = cachedAuthTokens.get(cacheKey);
  if (cached && cached.expiresAtEpochMs - TOKEN_REFRESH_BUFFER_MS > now) {
    return cached.token;
  }

  const inflight = inflightAuthTokenRequests.get(cacheKey);
  if (inflight) {
    return await inflight;
  }

  const request = mintAndExchangeServerToken(normalizedSession, env)
    .then((token) => {
      if (!token) {
        return undefined;
      }

      cachedAuthTokens.set(cacheKey, {
        token,
        expiresAtEpochMs:
          decodeJwtExpiryEpochMs(token) ?? Date.now() + FALLBACK_TOKEN_TTL_MS,
      });

      return token;
    })
    .finally(() => {
      inflightAuthTokenRequests.delete(cacheKey);
    });

  inflightAuthTokenRequests.set(cacheKey, request);
  return await request;
}

async function mintAndExchangeServerToken(
  session: ServerProxySession,
  env: Record<string, string | undefined>,
): Promise<string | undefined> {
  const refreshToken = pickFirstNonEmpty(env, SERVER_AUTH_REFRESH_TOKEN_ENV_KEYS);
  if (refreshToken) {
    const refreshedToken = await exchangeRefreshTokenForIdToken(refreshToken, env);
    if (refreshedToken) {
      return refreshedToken;
    }
  }

  try {
    const adminAuth = getAdminAuth();
    const customToken = await adminAuth.createCustomToken(
      session.uid,
      buildCustomClaims(session),
    );

    for (const apiKey of resolveApiKeyCandidates(env)) {
      const response = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${encodeURIComponent(apiKey)}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            token: customToken,
            returnSecureToken: true,
          }),
        },
      );

      if (!response.ok) {
        continue;
      }

      const body = (await response.json()) as { idToken?: unknown };
      const idToken = toNonEmptyString(body.idToken);
      if (idToken) {
        return idToken;
      }
    }

    return undefined;
  } catch {
    return undefined;
  }
}

async function exchangeRefreshTokenForIdToken(
  refreshToken: string,
  env: Record<string, string | undefined>,
): Promise<string | undefined> {
  const encodedPayload = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refreshToken,
  }).toString();

  for (const apiKey of resolveApiKeyCandidates(env)) {
    try {
      const response = await fetch(
        `https://securetoken.googleapis.com/v1/token?key=${encodeURIComponent(apiKey)}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: encodedPayload,
        },
      );

      if (!response.ok) {
        continue;
      }

      const body = (await response.json()) as { id_token?: unknown };
      const idToken = toNonEmptyString(body.id_token);
      if (idToken) {
        return idToken;
      }
    } catch {
      continue;
    }
  }

  return undefined;
}

function normalizeSession(session: ServerProxySession): ServerProxySession {
  const roles = new Set<string>();
  for (const value of [session.primaryRole, ...session.roles]) {
    const normalized = toNonEmptyString(value);
    if (!normalized) {
      continue;
    }
    roles.add(normalized);
  }

  return {
    uid: session.uid,
    primaryRole: session.primaryRole,
    roles: [...roles],
  };
}

function buildCacheKey(session: ServerProxySession): string {
  const sortedRoles = [...session.roles].sort((left, right) =>
    left.localeCompare(right),
  );
  return `${session.uid}|${session.primaryRole}|${sortedRoles.join(",")}`;
}

function buildCustomClaims(session: ServerProxySession): Record<string, unknown> {
  const roles = new Set(session.roles);

  return {
    admin: true,
    isAdmin: true,
    role: session.primaryRole,
    roles: [...roles],
    super_admin: roles.has("super_admin"),
    content_admin: roles.has("content_admin"),
    finance_admin: roles.has("finance_admin"),
  };
}

function resolveApiKeyCandidates(
  env: Record<string, string | undefined>,
): string[] {
  const candidates = [
    toNonEmptyString(env.NEXT_PUBLIC_FIREBASE_API_KEY),
    toNonEmptyString(env.WAIN_FIREBASE_API_KEY),
    DEFAULT_FIREBASE_API_KEY,
  ];

  const deduped: string[] = [];
  for (const candidate of candidates) {
    if (!candidate) {
      continue;
    }

    if (!deduped.includes(candidate)) {
      deduped.push(candidate);
    }
  }

  return deduped;
}

function pickFirstNonEmpty(
  env: Record<string, string | undefined>,
  keys: readonly string[],
): string | undefined {
  for (const key of keys) {
    const value = toNonEmptyString(env[key]);
    if (value) {
      return value;
    }
  }

  return undefined;
}

function decodeJwtExpiryEpochMs(token: string): number | undefined {
  const parts = token.split(".");
  if (parts.length < 2) {
    return undefined;
  }

  try {
    const payload = JSON.parse(
      Buffer.from(parts[1], "base64url").toString("utf8"),
    ) as { exp?: unknown };

    if (typeof payload.exp !== "number") {
      return undefined;
    }

    return payload.exp * 1000;
  } catch {
    return undefined;
  }
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}
