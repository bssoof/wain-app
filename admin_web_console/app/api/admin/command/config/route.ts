import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  CONFIG_COMMANDS,
  type ConfigCommandRequestMap,
  type ConfigCommandType,
} from "@/lib/config/config-command-contracts";
import { createConfigCommandAdaptersTransport } from "@/lib/config/config-command-adapters";
import { authorizeConfigCommand } from "@/lib/config/config-command-policy";
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
  const authz = authorizeConfigCommand(session, command);
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
    serviceLabel: "Config command",
    env: {
      NODE_ENV: process.env.NODE_ENV,
      WAIN_CONFIG_FUNCTIONS_BASE_URL: process.env.WAIN_CONFIG_FUNCTIONS_BASE_URL,
      WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.WAIN_FINANCE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
      WAIN_CONFIG_SERVER_AUTH_TOKEN: process.env.WAIN_CONFIG_SERVER_AUTH_TOKEN,
      WAIN_FINANCE_SERVER_AUTH_TOKEN: process.env.WAIN_FINANCE_SERVER_AUTH_TOKEN,
      WAIN_CONFIG_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_CONFIG_SERVER_APP_CHECK_TOKEN,
      WAIN_FINANCE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN,
    },
    baseUrlEnvKeys: [
      "WAIN_CONFIG_FUNCTIONS_BASE_URL",
      "WAIN_FINANCE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL",
    ],
    serverAuthTokenEnvKeys: [
      "WAIN_CONFIG_SERVER_AUTH_TOKEN",
      "WAIN_FINANCE_SERVER_AUTH_TOKEN",
    ],
    serverAppCheckTokenEnvKeys: [
      "WAIN_CONFIG_SERVER_APP_CHECK_TOKEN",
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

  const transport = createConfigCommandAdaptersTransport({
    invokeCallable: createHttpsCallableInvoker({
      baseUrl: callableConfig.baseUrl,
      authToken: callableConfig.authToken,
      appCheckToken: callableConfig.appCheckToken,
    }),
  });

  const result = await transport.execute(
    command,
    requestPayload as ConfigCommandRequestMap[typeof command],
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
      command: ConfigCommandType;
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
        message: "Config proxy payload must be a JSON object.",
      };
    }

    const command = bodyRecord.command;
    if (!isConfigCommandType(command)) {
      return {
        ok: false,
        message: "Config proxy payload contains an invalid command.",
      };
    }

    const requestPayload = asRecord(bodyRecord.request);
    if (!requestPayload) {
      return {
        ok: false,
        message: "Config proxy payload is missing command request body.",
      };
    }

    const action = toNonEmptyString(requestPayload.action);
    if (action && action !== command) {
      return {
        ok: false,
        message: "Config proxy payload action does not match command.",
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
      message: "Config proxy payload is not valid JSON.",
    };
  }
}

function isConfigCommandType(value: unknown): value is ConfigCommandType {
  return typeof value === "string" && CONFIG_COMMANDS.includes(value as ConfigCommandType);
}
