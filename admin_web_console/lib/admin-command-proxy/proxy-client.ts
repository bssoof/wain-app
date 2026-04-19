import { mapBackendErrorToTransportError } from "@/lib/finance/finance-command-transport";

export type ProxyTransportResponseBody = {
  ok?: boolean;
  correlationId?: string;
  data?: unknown;
  error?: Record<string, unknown>;
};

export type AdminCommandProxyTransportOptions = {
  endpoint?: string;
  fetchImpl?: typeof fetch;
  resolveAuthToken?: () => Promise<string | undefined>;
  resolveAppCheckToken?: () => Promise<string | undefined>;
};

export type ProxyExecutionSuccess<TData> = {
  ok: true;
  data: TData;
  correlationId?: string;
};

export type ProxyExecutionFailure = {
  ok: false;
  error: ReturnType<typeof mapBackendErrorToTransportError>;
  correlationId?: string;
};

export type ProxyExecutionResult<TData> =
  | ProxyExecutionSuccess<TData>
  | ProxyExecutionFailure;

export async function executeProxyCommand<TData>(
  options: AdminCommandProxyTransportOptions & { endpoint: string },
  body: Record<string, unknown>,
  fallbackCorrelationId?: string,
): Promise<ProxyExecutionResult<TData>> {
  const endpoint = options.endpoint.trim();
  if (!endpoint) {
    return {
      ok: false,
      correlationId: fallbackCorrelationId,
      error: {
        status: 503,
        message: "Admin command proxy endpoint is not configured.",
      },
    };
  }

  const fetchImpl = options.fetchImpl ?? fetch;
  const resolveAuthToken = options.resolveAuthToken ?? defaultResolveAuthToken;
  const resolveAppCheckToken =
    options.resolveAppCheckToken ?? defaultResolveAppCheckToken;

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
      body: JSON.stringify(body),
    });

    const rawText = await response.text();
    const parsed = parseJsonSafely(rawText);
    const parsedRecord = asRecord(parsed);
    const parsedError = asRecord(parsedRecord?.error);

    if (!response.ok || parsedError) {
      return {
        ok: false,
        correlationId:
          toNonEmptyString(parsedRecord?.correlationId) ?? fallbackCorrelationId,
        error: mapBackendErrorToTransportError({
          status: response.status,
          ...(parsedError ?? {}),
        }),
      };
    }

    const data = (parsedRecord?.data as TData | undefined) ?? (parsed as TData);

    if (!asRecord(data)) {
      return {
        ok: false,
        correlationId:
          toNonEmptyString(parsedRecord?.correlationId) ?? fallbackCorrelationId,
        error: {
          status: 503,
          message: "Admin command proxy returned a malformed response.",
        },
      };
    }

    return {
      ok: true,
      data,
      correlationId:
        toNonEmptyString(parsedRecord?.correlationId) ?? fallbackCorrelationId,
    };
  } catch (error) {
    return {
      ok: false,
      correlationId: fallbackCorrelationId,
      error: mapBackendErrorToTransportError(error),
    };
  }
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
  // Public static App Check tokens are intentionally not injected by default.
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
