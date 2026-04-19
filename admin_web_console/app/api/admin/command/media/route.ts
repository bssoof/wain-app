import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  MEDIA_COMMANDS,
  type MediaCommandRequestMap,
  type MediaCommandType,
} from "@/lib/media/media-command-contracts";
import { createMediaCommandAdaptersTransport } from "@/lib/media/media-command-adapters";
import { authorizeMediaCommand } from "@/lib/media/media-command-policy";
import {
  createHttpsCallableInvoker,
  mapBackendErrorToTransportError,
} from "@/lib/finance/finance-command-transport";

import {
  asRecord,
  noStoreJson,
  resolveCallableProxyConfig,
  toNonEmptyString,
} from "../shared/proxy-helpers";

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
  const authz = authorizeMediaCommand(session, command);
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

  const callableConfig = resolveCallableProxyConfig(request, {
    serviceLabel: "Media command",
    env: {
      NODE_ENV: process.env.NODE_ENV,
      WAIN_MEDIA_FUNCTIONS_BASE_URL: process.env.WAIN_MEDIA_FUNCTIONS_BASE_URL,
      WAIN_VENUE_FUNCTIONS_BASE_URL: process.env.WAIN_VENUE_FUNCTIONS_BASE_URL,
      WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.WAIN_FINANCE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
      WAIN_MEDIA_SERVER_AUTH_TOKEN: process.env.WAIN_MEDIA_SERVER_AUTH_TOKEN,
      WAIN_VENUE_SERVER_AUTH_TOKEN: process.env.WAIN_VENUE_SERVER_AUTH_TOKEN,
      WAIN_FINANCE_SERVER_AUTH_TOKEN: process.env.WAIN_FINANCE_SERVER_AUTH_TOKEN,
      WAIN_MEDIA_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_MEDIA_SERVER_APP_CHECK_TOKEN,
      WAIN_VENUE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_VENUE_SERVER_APP_CHECK_TOKEN,
      WAIN_FINANCE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN,
    },
    baseUrlEnvKeys: [
      "WAIN_MEDIA_FUNCTIONS_BASE_URL",
      "WAIN_VENUE_FUNCTIONS_BASE_URL",
      "WAIN_FINANCE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL",
    ],
    serverAuthTokenEnvKeys: [
      "WAIN_MEDIA_SERVER_AUTH_TOKEN",
      "WAIN_VENUE_SERVER_AUTH_TOKEN",
      "WAIN_FINANCE_SERVER_AUTH_TOKEN",
    ],
    serverAppCheckTokenEnvKeys: [
      "WAIN_MEDIA_SERVER_APP_CHECK_TOKEN",
      "WAIN_VENUE_SERVER_APP_CHECK_TOKEN",
      "WAIN_FINANCE_SERVER_APP_CHECK_TOKEN",
    ],
  });

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

  const transport = createMediaCommandAdaptersTransport({
    invokeCallable: createHttpsCallableInvoker({
      baseUrl: callableConfig.baseUrl,
      authToken: callableConfig.authToken,
      appCheckToken: callableConfig.appCheckToken,
    }),
  });

  const result = await transport.execute(
    command,
    requestPayload as MediaCommandRequestMap[typeof command],
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
      command: MediaCommandType;
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
        message: "Media proxy payload must be a JSON object.",
      };
    }

    const command = bodyRecord.command;
    if (!isMediaCommandType(command)) {
      return {
        ok: false,
        message: "Media proxy payload contains an invalid command.",
      };
    }

    const requestPayload = asRecord(bodyRecord.request);
    if (!requestPayload) {
      return {
        ok: false,
        message: "Media proxy payload is missing command request body.",
      };
    }

    const action = toNonEmptyString(requestPayload.action);
    if (action && action !== command) {
      return {
        ok: false,
        message: "Media proxy payload action does not match command.",
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
      message: "Media proxy payload is not valid JSON.",
    };
  }
}

function isMediaCommandType(value: unknown): value is MediaCommandType {
  return typeof value === "string" && MEDIA_COMMANDS.includes(value as MediaCommandType);
}
