import { NextResponse } from "next/server";

import {
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
} from "@/lib/finance/finance-command-transport";

export type CallableProxyConfig =
  | {
      ok: true;
      baseUrl: string;
      authToken: string;
      appCheckToken?: string;
    }
  | {
      ok: false;
      error: {
        status: 401 | 403 | 503;
        message: string;
      };
    };

export type ResolveProxyConfigOptions = {
  serviceLabel: string;
  env: Record<string, string | undefined>;
  baseUrlEnvKeys: string[];
  serverAuthTokenEnvKeys: string[];
  serverAppCheckTokenEnvKeys: string[];
};

export function resolveCallableProxyConfig(
  request: Request,
  options: ResolveProxyConfigOptions,
): CallableProxyConfig {
  const baseUrl = pickFirstNonEmpty(options.env, options.baseUrlEnvKeys);
  if (!baseUrl) {
    return {
      ok: false,
      error: {
        status: 503,
        message: `${options.serviceLabel} proxy is not configured. Missing functions base URL.`,
      },
    };
  }

  const serverAuthToken = pickFirstNonEmpty(
    options.env,
    options.serverAuthTokenEnvKeys,
  );
  const requestAuthToken = extractBearerToken(request.headers.get("authorization"));
  const authToken = serverAuthToken ?? requestAuthToken;

  if (!authToken) {
    return {
      ok: false,
      error: {
        status: 401,
        message: `${options.serviceLabel} proxy is missing an upstream auth token. Sign in again.`,
      },
    };
  }

  const serverAppCheckToken = pickFirstNonEmpty(
    options.env,
    options.serverAppCheckTokenEnvKeys,
  );
  const requestAppCheckToken =
    request.headers.get("x-firebase-appcheck")?.trim() || undefined;

  const inProduction = isProductionRuntime(options.env);
  const isLiveUrl = isLiveFirebaseFunctionsUrl(baseUrl);
  const appCheckToken =
    serverAppCheckToken ?? (!inProduction ? requestAppCheckToken : undefined);

  if (isLiveUrl && !appCheckToken) {
    return {
      ok: false,
      error: {
        status: 403,
        message: `${options.serviceLabel} proxy requires a server-side App Check token for live callable transport.`,
      },
    };
  }

  return {
    ok: true,
    baseUrl,
    authToken,
    ...(appCheckToken ? { appCheckToken } : {}),
  };
}

export function noStoreJson(
  body: Record<string, unknown>,
  init?: ResponseInit,
): NextResponse {
  return NextResponse.json(body, {
    ...init,
    headers: {
      "Cache-Control": "no-store",
      ...(init?.headers ?? {}),
    },
  });
}

export function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, any>;
}

export function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function pickFirstNonEmpty(
  env: Record<string, string | undefined>,
  keys: string[],
): string | undefined {
  for (const key of keys) {
    const value = env[key]?.trim();
    if (value) {
      return value;
    }
  }

  return undefined;
}

function extractBearerToken(rawHeader: string | null): string | undefined {
  if (!rawHeader) {
    return undefined;
  }

  const match = rawHeader.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return undefined;
  }

  const token = match[1].trim();
  return token.length > 0 ? token : undefined;
}
