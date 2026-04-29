import { NextResponse } from "next/server";

import { emitAdminSecurityAudit } from "@/lib/auth/admin-security-audit";
import { resolveServerAuthTokenForAdminProxy } from "@/lib/firebase/server-auth-token";
import { resolveServerAppCheckTokenForAdminProxy } from "@/lib/firebase/server-app-check";
import {
  isLiveFirebaseFunctionsUrl,
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
  session?: {
    uid: string;
    primaryRole: string;
    roles: string[];
  };
};

export type ProxySecurityAuditEventType =
  | "proxy_payload_invalid"
  | "proxy_authorization_denied"
  | "proxy_step_up_required"
  | "proxy_transport_rejected";

export function logProxySecurityAudit(options: {
  request: Request;
  serviceLabel: string;
  eventType: ProxySecurityAuditEventType;
  status: number;
  reason: string;
  command?: string;
  correlationId?: string;
  sessionUid?: string;
  sessionRole?: string;
}): void {
  emitAdminSecurityAudit({
    source: "admin-command-proxy",
    eventType: options.eventType,
    reason: options.reason,
    status: options.status,
    path: resolveRequestPath(options.request),
    serviceLabel: options.serviceLabel,
    ...(toNonEmptyString(options.command) ? { command: options.command } : {}),
    ...(toNonEmptyString(options.correlationId)
      ? { correlationId: options.correlationId }
      : {}),
    ...(toNonEmptyString(options.sessionUid)
      ? { sessionUid: options.sessionUid }
      : {}),
    ...(toNonEmptyString(options.sessionRole)
      ? { sessionRole: options.sessionRole }
      : {}),
  });
}

export async function resolveCallableProxyConfig(
  request: Request,
  options: ResolveProxyConfigOptions,
): Promise<CallableProxyConfig> {
  const mergedEnv: Record<string, string | undefined> = {
    ...process.env,
    ...options.env,
  };

  const baseUrl = pickFirstNonEmpty(mergedEnv, options.baseUrlEnvKeys);
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
    mergedEnv,
    options.serverAuthTokenEnvKeys,
  );
  const requestAuthToken = extractBearerToken(request.headers.get("authorization"));
  const mintedServerAuthToken =
    !serverAuthToken && options.session
      ? await resolveServerAuthTokenForAdminProxy(options.session, mergedEnv)
      : undefined;
  const authToken = serverAuthToken ?? mintedServerAuthToken ?? requestAuthToken;

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
    mergedEnv,
    options.serverAppCheckTokenEnvKeys,
  );
  const requestAppCheckToken =
    request.headers.get("x-firebase-appcheck")?.trim() || undefined;
  const isLiveUrl = isLiveFirebaseFunctionsUrl(baseUrl);
  const mintedServerAppCheckToken =
    !serverAppCheckToken && isLiveUrl
      ? await resolveServerAppCheckTokenForAdminProxy(mergedEnv)
      : undefined;
  const appCheckToken =
    serverAppCheckToken ?? mintedServerAppCheckToken ?? requestAppCheckToken;

  if (isLiveUrl && !appCheckToken) {
    return {
      ok: false,
      error: {
        status: 403,
        message: `${options.serviceLabel} proxy requires an App Check token for live callable transport.`,
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

function resolveRequestPath(request: Request): string {
  try {
    return new URL(request.url).pathname;
  } catch {
    return request.url;
  }
}
