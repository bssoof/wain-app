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
  mapBackendErrorToTransportError,
} from "@/lib/finance/finance-command-transport";
import {
  asRecord,
  logProxySecurityAudit,
  noStoreJson,
  resolveCallableProxyConfig,
  toNonEmptyString,
} from "../shared/proxy-helpers";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const parsedBody = await readRequestBody(request);
  if (!parsedBody.ok) {
    logProxySecurityAudit({
      request,
      serviceLabel: "Finance command",
      eventType: "proxy_payload_invalid",
      status: 422,
      reason: parsedBody.message,
    });
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
    logProxySecurityAudit({
      request,
      serviceLabel: "Finance command",
      eventType: "proxy_authorization_denied",
      status: authz.error.status,
      reason: authz.error.message,
      command,
      correlationId: toNonEmptyString(requestPayload.correlationId),
      sessionUid: session?.uid,
      sessionRole: session?.primaryRole,
    });
    return noStoreJson(
      {
        ok: false,
        correlationId: requestPayload.correlationId,
        error: authz.error,
      },
      { status: authz.error.status },
    );
  }

  const callableConfig = await resolveCallableProxyConfig(request, {
    serviceLabel: "Finance command",
    env: {
      NODE_ENV: process.env.NODE_ENV,
      WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.WAIN_FINANCE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
      WAIN_FINANCE_SERVER_AUTH_TOKEN: process.env.WAIN_FINANCE_SERVER_AUTH_TOKEN,
      WAIN_FINANCE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN,
    },
    baseUrlEnvKeys: [
      "WAIN_FINANCE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL",
    ],
    serverAuthTokenEnvKeys: ["WAIN_FINANCE_SERVER_AUTH_TOKEN"],
    serverAppCheckTokenEnvKeys: ["WAIN_FINANCE_SERVER_APP_CHECK_TOKEN"],
    ...(session
      ? {
          session: {
            uid: session.uid,
            primaryRole: session.primaryRole,
            roles: session.roles,
          },
        }
      : {}),
  });
  if (!callableConfig.ok) {
    const normalized = mapBackendErrorToTransportError(callableConfig.error);
    logProxySecurityAudit({
      request,
      serviceLabel: "Finance command",
      eventType: "proxy_transport_rejected",
      status: normalized.status,
      reason: normalized.message,
      command,
      correlationId: toNonEmptyString(requestPayload.correlationId),
      sessionUid: session?.uid,
      sessionRole: session?.primaryRole,
    });
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

function isFinanceCommandType(value: unknown): value is FinanceCommandType {
  return typeof value === "string" && FINANCE_COMMANDS.includes(value as FinanceCommandType);
}
