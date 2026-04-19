import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  VENUE_COMMANDS,
  createVenueCommandError,
  type VenueCommandRequestMap,
  type VenueCommandType,
} from "@/lib/venues/venue-command-contracts";
import { createVenueAdaptersTransport } from "@/lib/venues/venue-command-adapters";
import {
  canExecuteVenueCommand,
  getVenueCommandDenialReason,
} from "@/lib/venues/venue-command-policy";
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
  if (!session) {
    const error = createVenueCommandError(
      "unauthorized",
      "Admin session is required for venue commands.",
    );
    return noStoreJson(
      {
        ok: false,
        correlationId: requestPayload.correlationId,
        error,
      },
      { status: error.status },
    );
  }

  if (!canExecuteVenueCommand(session, command)) {
    const error = createVenueCommandError(
      "forbidden",
      getVenueCommandDenialReason(session, command) ??
        `Role ${session.primaryRole} is not authorized for ${command}.`,
    );
    return noStoreJson(
      {
        ok: false,
        correlationId: requestPayload.correlationId,
        error,
      },
      { status: error.status },
    );
  }

  const callableConfig = resolveCallableProxyConfig(request, {
    serviceLabel: "Venue command",
    env: {
      NODE_ENV: process.env.NODE_ENV,
      WAIN_VENUE_FUNCTIONS_BASE_URL: process.env.WAIN_VENUE_FUNCTIONS_BASE_URL,
      WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.WAIN_FINANCE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
      WAIN_VENUE_SERVER_AUTH_TOKEN: process.env.WAIN_VENUE_SERVER_AUTH_TOKEN,
      WAIN_FINANCE_SERVER_AUTH_TOKEN: process.env.WAIN_FINANCE_SERVER_AUTH_TOKEN,
      WAIN_VENUE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_VENUE_SERVER_APP_CHECK_TOKEN,
      WAIN_FINANCE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN,
    },
    baseUrlEnvKeys: [
      "WAIN_VENUE_FUNCTIONS_BASE_URL",
      "WAIN_FINANCE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL",
    ],
    serverAuthTokenEnvKeys: [
      "WAIN_VENUE_SERVER_AUTH_TOKEN",
      "WAIN_FINANCE_SERVER_AUTH_TOKEN",
    ],
    serverAppCheckTokenEnvKeys: [
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

  const transport = createVenueAdaptersTransport({
    invokeCallable: createHttpsCallableInvoker({
      baseUrl: callableConfig.baseUrl,
      authToken: callableConfig.authToken,
      appCheckToken: callableConfig.appCheckToken,
    }),
  });

  const typedRequest = requestPayload as VenueCommandRequestMap[typeof command];
  const result = await transport.execute(typedRequest);

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
      command: VenueCommandType;
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
        message: "Venue proxy payload must be a JSON object.",
      };
    }

    const command = bodyRecord.command;
    if (!isVenueCommandType(command)) {
      return {
        ok: false,
        message: "Venue proxy payload contains an invalid command.",
      };
    }

    const requestPayload = asRecord(bodyRecord.request);
    if (!requestPayload) {
      return {
        ok: false,
        message: "Venue proxy payload is missing command request body.",
      };
    }

    const action = toNonEmptyString(requestPayload.action);
    if (action && action !== command) {
      return {
        ok: false,
        message: "Venue proxy payload action does not match command.",
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
      message: "Venue proxy payload is not valid JSON.",
    };
  }
}

function isVenueCommandType(value: unknown): value is VenueCommandType {
  return typeof value === "string" && VENUE_COMMANDS.includes(value as VenueCommandType);
}
