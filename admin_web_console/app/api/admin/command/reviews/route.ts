import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  type ReviewModerationAction,
  type ReviewModerationCommandRequest,
} from "@/lib/reviews/review-moderation-contracts";
import { createReviewModerationAdaptersTransport } from "@/lib/reviews/review-moderation-adapters";
import { authorizeReviewModerationCommand } from "@/lib/reviews/review-moderation-policy";
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
      serviceLabel: "Review moderation",
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

  const { action, requestPayload } = parsedBody;
  const session = await getCurrentAdminSession();
  const authz = authorizeReviewModerationCommand(session, action);
  if (!authz.allowed) {
    logProxySecurityAudit({
      request,
      serviceLabel: "Review moderation",
      eventType: "proxy_authorization_denied",
      status: authz.error.status,
      reason: authz.error.message,
      command: action,
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
    serviceLabel: "Review moderation",
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
      serviceLabel: "Review moderation",
      eventType: "proxy_transport_rejected",
      status: normalized.status,
      reason: normalized.message,
      command: action,
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

  const transport = createReviewModerationAdaptersTransport({
    invokeCallable: createHttpsCallableInvoker({
      baseUrl: callableConfig.baseUrl,
      authToken: callableConfig.authToken,
      appCheckToken: callableConfig.appCheckToken,
    }),
  });

  const result = await transport.execute(
    action,
    requestPayload as ReviewModerationCommandRequest,
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
      action: ReviewModerationAction;
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
        message: "Review moderation proxy payload must be a JSON object.",
      };
    }

    const action = bodyRecord.action;
    if (!isReviewModerationAction(action)) {
      return {
        ok: false,
        message: "Review moderation proxy payload contains an invalid action.",
      };
    }

    const requestPayload = asRecord(bodyRecord.request);
    if (!requestPayload) {
      return {
        ok: false,
        message: "Review moderation proxy payload is missing command request body.",
      };
    }

    const requestAction = toNonEmptyString(requestPayload.action);
    if (requestAction && requestAction !== action) {
      return {
        ok: false,
        message: "Review moderation proxy payload action does not match request body.",
      };
    }

    return {
      ok: true,
      action,
      requestPayload,
    };
  } catch {
    return {
      ok: false,
      message: "Review moderation proxy payload is not valid JSON.",
    };
  }
}

function isReviewModerationAction(value: unknown): value is ReviewModerationAction {
  return value === "review_publish" || value === "review_hide" || value === "review_escalate";
}
