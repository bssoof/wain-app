import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  CONTENT_MODERATION_ACTIONS,
  type ContentModerationAction,
  type ModerateOfferCommand,
  type ModerateStoryCommand,
} from "@/lib/content/content-command-contracts";
import { createContentModerationAdaptersTransport } from "@/lib/content/content-command-adapters";
import {
  authorizeOfferModerationCommand,
  authorizeStoryModerationCommand,
} from "@/lib/content/content-command-policy";
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

const CONTENT_PROXY_COMMANDS = ["offer", "story"] as const;

type ContentProxyCommand = (typeof CONTENT_PROXY_COMMANDS)[number];

export async function POST(request: Request) {
  const parsedBody = await readRequestBody(request);
  if (!parsedBody.ok) {
    logProxySecurityAudit({
      request,
      serviceLabel: "Content moderation",
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

  const { command, action, requestPayload } = parsedBody;
  const session = await getCurrentAdminSession();
  const authz =
    command === "offer"
      ? authorizeOfferModerationCommand(session, action)
      : authorizeStoryModerationCommand(session, action);

  if (!authz.allowed) {
    logProxySecurityAudit({
      request,
      serviceLabel: "Content moderation",
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

  const callableConfig = resolveCallableProxyConfig(request, {
    serviceLabel: "Content moderation",
    env: {
      NODE_ENV: process.env.NODE_ENV,
      WAIN_CONTENT_FUNCTIONS_BASE_URL: process.env.WAIN_CONTENT_FUNCTIONS_BASE_URL,
      WAIN_FINANCE_FUNCTIONS_BASE_URL: process.env.WAIN_FINANCE_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL,
      NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
        process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
      WAIN_CONTENT_SERVER_AUTH_TOKEN: process.env.WAIN_CONTENT_SERVER_AUTH_TOKEN,
      WAIN_FINANCE_SERVER_AUTH_TOKEN: process.env.WAIN_FINANCE_SERVER_AUTH_TOKEN,
      WAIN_CONTENT_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_CONTENT_SERVER_APP_CHECK_TOKEN,
      WAIN_FINANCE_SERVER_APP_CHECK_TOKEN:
        process.env.WAIN_FINANCE_SERVER_APP_CHECK_TOKEN,
    },
    baseUrlEnvKeys: [
      "WAIN_CONTENT_FUNCTIONS_BASE_URL",
      "WAIN_FINANCE_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL",
      "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL",
    ],
    serverAuthTokenEnvKeys: [
      "WAIN_CONTENT_SERVER_AUTH_TOKEN",
      "WAIN_FINANCE_SERVER_AUTH_TOKEN",
    ],
    serverAppCheckTokenEnvKeys: [
      "WAIN_CONTENT_SERVER_APP_CHECK_TOKEN",
      "WAIN_FINANCE_SERVER_APP_CHECK_TOKEN",
    ],
  });

  if (!callableConfig.ok) {
    const normalized = mapBackendErrorToTransportError(callableConfig.error);
    logProxySecurityAudit({
      request,
      serviceLabel: "Content moderation",
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

  const transport = createContentModerationAdaptersTransport({
    invokeCallable: createHttpsCallableInvoker({
      baseUrl: callableConfig.baseUrl,
      authToken: callableConfig.authToken,
      appCheckToken: callableConfig.appCheckToken,
    }),
  });

  const result =
    command === "offer"
      ? await transport.executeOffer(
          action,
          requestPayload as unknown as ModerateOfferCommand,
        )
      : await transport.executeStory(
          action,
          requestPayload as unknown as ModerateStoryCommand,
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
      command: ContentProxyCommand;
      action: ContentModerationAction;
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
        message: "Content proxy payload must be a JSON object.",
      };
    }

    const command = bodyRecord.command;
    if (!isContentProxyCommand(command)) {
      return {
        ok: false,
        message: "Content proxy payload contains an invalid command.",
      };
    }

    const requestPayload = asRecord(bodyRecord.request);
    if (!requestPayload) {
      return {
        ok: false,
        message: "Content proxy payload is missing command request body.",
      };
    }

    const action = toNonEmptyString(requestPayload.action);
    if (!isContentModerationAction(action)) {
      return {
        ok: false,
        message: "Content proxy payload contains an invalid moderation action.",
      };
    }

    return {
      ok: true,
      command,
      action,
      requestPayload,
    };
  } catch {
    return {
      ok: false,
      message: "Content proxy payload is not valid JSON.",
    };
  }
}

function isContentProxyCommand(value: unknown): value is ContentProxyCommand {
  return (
    typeof value === "string" &&
    CONTENT_PROXY_COMMANDS.includes(value as ContentProxyCommand)
  );
}

function isContentModerationAction(value: unknown): value is ContentModerationAction {
  return (
    typeof value === "string" &&
    CONTENT_MODERATION_ACTIONS.includes(value as ContentModerationAction)
  );
}
