import { NextResponse } from "next/server";

import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  FINANCE_COMMANDS,
  type FinanceCommandRequestMap,
  type FinanceCommandType,
} from "@/lib/finance/command-contracts";
import { authorizeFinanceCommand } from "@/lib/finance/command-policy";
import { createFinanceCommandAdaptersTransport } from "@/lib/finance/finance-command-adapters";
import {
  createHttpsCallableInvoker,
  isLiveFirebaseFunctionsUrl,
  isProductionRuntime,
  mapBackendErrorToTransportError,
} from "@/lib/finance/finance-command-transport";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const parsedBody = await readRequestBody(request);
  if (!parsedBody.ok) {
    return noStoreJson(
      {
        ok: false,
        error: {
          status: 422,
          message: parsedBody.message,
        },
      },
      { status: 422 },
    );
  }

  const { command, requestPayload } = parsedBody;
  const session = await getCurrentAdminSession();
  const authz = authorizeFinanceCommand(session, command);
  if (!authz.allowed) {
    return noStoreJson(
      {
        ok: false,
        correlationId: requestPayload.correlationId,
        error: authz.error,
      },
      { status: authz.error.status },
    );
  }

  const callableConfig = resolveCallableProxyConfig(request);
  if (!callableConfig.ok) {
    const normalized = mapBackendErrorToTransportError(callableConfig.error);
    return noStoreJson(
      {
        ok: false,
        correlationId: requestPayload.correlationId,
        error: normalized,
      },
      { status: normalized.status },
    );
  }

  const transport = createFinanceCommandAdaptersTransport({
    invokeCallable: createHttpsCallableInvoker({
      baseUrl: callableConfig.baseUrl,
      authToken: callableConfig.authToken,
      appCheckToken: callableConfig.appCheckToken,
    }),
  });

  const result = await transport.execute(
    command,
    requestPayload as FinanceCommandRequestMap[typeof command],
  );

  if (result.ok) {
    return noStoreJson({
      ok: true,
      correlationId: result.correlationId ?? requestPayload.correlationId,
      data: result.data,
    });
  }

  const normalized = mapBackendErrorToTransportError(result.error);
  return noStoreJson(
    {
      ok: false,
      correlationId: result.correlationId ?? requestPayload.correlationId,
      error: normalized,
    },
    { status: normalized.status },
  );
}

type ParsedRequestBody =
  | {
      ok: true;
      command: FinanceCommandType;
      requestPayload: Record<string, unknown>;
    }
  | {
      ok: false;
      message: string;
    };

async function readRequestBody(request: Request): Promise<ParsedRequestBody> {
  try {
    const body = (await request.json()) as unknown;
    const bodyRecord = asRecord(body);
    if (!bodyRecord) {
      return {
        ok: false,
        message: "Finance proxy payload must be a JSON object.",
      };
    }

    const command = bodyRecord.command;
    if (!isFinanceCommandType(command)) {
      return {
        ok: false,
        message: "Finance proxy payload contains an invalid command.",
      };
    }

    const requestPayload = asRecord(bodyRecord.request);
    if (!requestPayload) {
      return {
        ok: false,
        message: "Finance proxy payload is missing command request body.",
      };
    }

    const action = toNonEmptyString(requestPayload.action);
    if (action && action !== command) {
      return {
        ok: false,
        message: "Finance proxy payload action does not match command.",
      };
    }

    return {
      ok: true,
      command,
      requestPayload,
    };
  } catch {
    return {
      ok: false,
      message: "Finance proxy payload is not valid JSON.",
    };
  }
}

type CallableProxyConfig =
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

function resolveCallableProxyConfig(request: Request): CallableProxyConfig {
  const env: Record<string, string | undefined> = {
    NODE_ENV: process.env.NODE_ENV,
    WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    WAIN_FINANCE_SERVER_AUTH_TOKEN: process.env.WAIN_FINANCE_SERVER_AUTH_TOKEN,
    WAIN_FINANCE_SERVER_APP_CHECK_TOKEN:
      process.env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN,
  };

  const baseUrl =
    env.WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim() ||
    env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim();
  if (!baseUrl) {
    return {
      ok: false,
      error: {
        status: 503,
        message:
          "Finance command proxy is not configured. Missing finance functions base URL.",
      },
    };
  }

  const serverAuthToken = env.WAIN_FINANCE_SERVER_AUTH_TOKEN?.trim();
  const requestAuthToken = extractBearerToken(request.headers.get("authorization"));
  const authToken = serverAuthToken || requestAuthToken;

  if (!authToken) {
    return {
      ok: false,
      error: {
        status: 401,
        message:
          "Finance command proxy is missing an upstream auth token. Sign in again.",
      },
    };
  }

  const serverAppCheckToken = env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN?.trim();
  const requestAppCheckToken =
    request.headers.get("x-firebase-appcheck")?.trim() || undefined;

  const isLiveUrl = isLiveFirebaseFunctionsUrl(baseUrl);
  const inProduction = isProductionRuntime(env);
  const appCheckToken =
    serverAppCheckToken || (!inProduction ? requestAppCheckToken : undefined);

  if (isLiveUrl && !appCheckToken) {
    return {
      ok: false,
      error: {
        status: 403,
        message:
          "Finance command proxy requires a server-side App Check token for live callable transport.",
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

function isFinanceCommandType(value: unknown): value is FinanceCommandType {
  return typeof value === "string" && FINANCE_COMMANDS.includes(value as FinanceCommandType);
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

function noStoreJson(
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

function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, any>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}
