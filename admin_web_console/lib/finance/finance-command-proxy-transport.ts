import type {
  FinanceCommandRequestMap,
  FinanceCommandResponseMap,
  FinanceCommandType,
} from "./command-contracts";
import {
  mapBackendErrorToTransportError,
  type FinanceCommandTransport,
  type FinanceCommandTransportResult,
} from "./finance-command-transport";

const DEFAULT_FINANCE_COMMAND_PROXY_ENDPOINT = "/api/admin/command/finance";

export type FinanceCommandProxyTransportOptions = {
  endpoint?: string;
  fetchImpl?: typeof fetch;
  resolveAuthToken?: () => Promise<string | undefined>;
  resolveAppCheckToken?: () => Promise<string | undefined>;
};

export type ProxyTransportResponseBody = {
  ok?: boolean;
  correlationId?: string;
  data?: unknown;
  error?: Record<string, unknown>;
};

export function createFinanceCommandProxyTransport(
  options: FinanceCommandProxyTransportOptions = {},
): FinanceCommandTransport {
  const endpoint =
    options.endpoint?.trim() || DEFAULT_FINANCE_COMMAND_PROXY_ENDPOINT;
  const fetchImpl = options.fetchImpl ?? fetch;
  const resolveAuthToken = options.resolveAuthToken ?? defaultResolveAuthToken;
  const resolveAppCheckToken =
    options.resolveAppCheckToken ?? defaultResolveAppCheckToken;

  return {
    async execute<T extends FinanceCommandType>(
      command: T,
      request: FinanceCommandRequestMap[T],
    ): Promise<FinanceCommandTransportResult<T>> {
      try {
        const authToken = await resolveAuthToken();
        const appCheckToken = await resolveAppCheckToken();

        const response = await fetchImpl(endpoint, {
          method: "POST",
          cache: "no-store",
          headers: {
            "Content-Type": "application/json",
            ...(authToken
              ? {
                  Authorization: `Bearer ${authToken}`,
                }
              : {}),
            ...(appCheckToken
              ? {
                  "X-Firebase-AppCheck": appCheckToken,
                }
              : {}),
          },
          body: JSON.stringify({
            command,
            request,
          }),
        });

        const rawText = await response.text();
        const parsed = parseJsonSafely(rawText);
        const parsedRecord = asRecord(parsed);
        const parsedError = asRecord(parsedRecord?.error);

        if (!response.ok || parsedError) {
          return {
            ok: false,
            correlationId:
              toNonEmptyString(parsedRecord?.correlationId) ??
              request.correlationId,
            error: mapBackendErrorToTransportError({
              status: response.status,
              ...(parsedError ?? {}),
            }),
          };
        }

        const data =
          (parsedRecord?.data as FinanceCommandResponseMap[T] | undefined) ??
          (parsed as FinanceCommandResponseMap[T]);

        if (!asRecord(data)) {
          return {
            ok: false,
            correlationId: request.correlationId,
            error: {
              status: 503,
              message:
                "Finance command proxy returned a malformed response.",
            },
          };
        }

        return {
          ok: true,
          correlationId:
            toNonEmptyString(parsedRecord?.correlationId) ??
            request.correlationId,
          data,
        };
      } catch (error) {
        return {
          ok: false,
          correlationId: request.correlationId,
          error: mapBackendErrorToTransportError(error),
        };
      }
    },
  };
}

async function defaultResolveAuthToken(): Promise<string | undefined> {
  try {
    const { auth } = await import("@/lib/firebase/client");
    if (!auth.currentUser) {
      return undefined;
    }

    return await auth.currentUser.getIdToken();
  } catch {
    return undefined;
  }
}

async function defaultResolveAppCheckToken(): Promise<string | undefined> {
  // The default proxy path never injects static public App Check values.
  // Server route is responsible for enforcing server-side App Check policy.
  return undefined;
}

function parseJsonSafely(value: string): unknown {
  if (!value) {
    return null;
  }

  try {
    return JSON.parse(value) as unknown;
  } catch {
    return value;
  }
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
