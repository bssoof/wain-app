import "server-only";

import { getAppCheck } from "firebase-admin/app-check";

import { getAdminApp } from "@/lib/firebase/server";

const DEFAULT_FIREBASE_APP_ID = "1:620614484841:web:ac86320829e764bc41b3f8";
const TOKEN_REFRESH_BUFFER_MS = 60_000;
const FALLBACK_TOKEN_TTL_MS = 15 * 60 * 1000;

type CachedServerToken = {
  token: string;
  expiresAtEpochMs: number;
};

let cachedServerToken: CachedServerToken | null = null;
let inflightServerToken: Promise<string | undefined> | null = null;

export async function resolveServerAppCheckTokenForAdminProxy(
  env: Record<string, string | undefined> = process.env,
): Promise<string | undefined> {
  const now = Date.now();
  if (
    cachedServerToken &&
    cachedServerToken.expiresAtEpochMs - TOKEN_REFRESH_BUFFER_MS > now
  ) {
    return cachedServerToken.token;
  }

  if (inflightServerToken) {
    return await inflightServerToken;
  }

  const appId =
    toNonEmptyString(env.NEXT_PUBLIC_FIREBASE_APP_ID) ?? DEFAULT_FIREBASE_APP_ID;

  inflightServerToken = mintServerAppCheckToken(appId).finally(() => {
    inflightServerToken = null;
  });

  return await inflightServerToken;
}

async function mintServerAppCheckToken(
  appId: string,
): Promise<string | undefined> {
  try {
    const appCheck = getAppCheck(getAdminApp());
    const response = await appCheck.createToken(appId);
    const token = toNonEmptyString(response.token);
    if (!token) {
      return undefined;
    }

    cachedServerToken = {
      token,
      expiresAtEpochMs:
        decodeJwtExpiryEpochMs(token) ?? Date.now() + FALLBACK_TOKEN_TTL_MS,
    };

    return token;
  } catch {
    return undefined;
  }
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
