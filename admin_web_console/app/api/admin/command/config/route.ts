import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { emitStepUpAuditEvent } from "@/lib/auth/step-up-audit";
import { verifyStepUpForCommand } from "@/lib/auth/step-up-middleware";
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
      serviceLabel: "Config command",
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
  const authz = authorizeConfigCommand(session, command);
  if (!authz.allowed) {
    logProxySecurityAudit({
      request,
      serviceLabel: "Config command",
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

  const stepUp = await verifyStepUpForCommand({
    request,
    session,
    scope: "config",
    command,
  });
  if (!stepUp.ok) {
    await emitStepUpAuditEvent({
      eventType: "step_up_rejected",
      userId: session?.uid,
      sessionRole: session?.primaryRole,
      command,
      correlationId: toNonEmptyString(requestPayload.correlationId),
      scope: "config",
      reason: stepUp.error.details.reason,
      enforcementMode: "enabled",
      status: stepUp.error.status,
    });

    logProxySecurityAudit({
      request,
      serviceLabel: "Config command",
      eventType: "proxy_step_up_required",
      status: stepUp.error.status,
      reason: stepUp.error.message,
      command,
      correlationId: toNonEmptyString(requestPayload.correlationId),
      sessionUid: session?.uid,
      sessionRole: session?.primaryRole,
    });
    return noStoreJson(
      {
        ok: false,
        correlationId: requestPayload.correlationId,
        error: stepUp.error,
      },
      { status: stepUp.error.status },
    );
  }

  if (stepUp.required && stepUp.payload) {
    const issuedAtMs = stepUp.payload.iat * 1000;
    await emitStepUpAuditEvent({
      eventType: "step_up_verified",
      userId: session?.uid,
      sessionRole: session?.primaryRole,
      command,
      correlationId: toNonEmptyString(requestPayload.correlationId),
      scope: "config",
      enforcementMode: stepUp.enforcementMode ?? "enabled",
      tokenJti: stepUp.payload.jti,
      tokenIssuedAt: new Date(issuedAtMs).toISOString(),
      tokenAge_ms: Date.now() - issuedAtMs,
      expiresAt: new Date(stepUp.payload.exp * 1000).toISOString(),
    });
  }

  const callableConfig = await resolveCallableProxyConfig(request, {
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
      serviceLabel: "Config command",
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
