import type {
  FinanceCommandRequestMap,
  FinanceCommandResponseMap,
  FinanceCommandType,
} from "./command-contracts";

export type FinanceCommandTransportSuccess<T extends FinanceCommandType> = {
  ok: true;
  data: FinanceCommandResponseMap[T];
  correlationId?: string;
};

export type FinanceCommandTransportFailure = {
  ok: false;
  error: unknown;
  correlationId?: string;
};

export type FinanceCommandTransportResult<T extends FinanceCommandType> =
  | FinanceCommandTransportSuccess<T>
  | FinanceCommandTransportFailure;

export type FinanceCommandTransport = {
  execute<T extends FinanceCommandType>(
    command: T,
    request: FinanceCommandRequestMap[T],
  ): Promise<FinanceCommandTransportResult<T>>;
};

export type FinanceCallableInvoker = (
  callableName: string,
  payload: Record<string, unknown>,
) => Promise<unknown>;

export type FinanceTransportErrorStatus = 401 | 403 | 409 | 422 | 503;

export type FinanceTransportError = {
  status: FinanceTransportErrorStatus;
  message: string;
  details?: Record<string, unknown>;
};

export type HttpsCallableInvokerConfig = {
  baseUrl: string;
  authToken?: string | (() => Promise<string | undefined>);
  appCheckToken?: string | (() => Promise<string | undefined>);
  fetchImpl?: typeof fetch;
};

const CALLABLE_CODE_TO_TRANSPORT_STATUS: Record<string, FinanceTransportErrorStatus> = {
  unauthenticated: 401,
  permission_denied: 403,
  failed_precondition: 409,
  already_exists: 409,
  aborted: 409,
  invalid_argument: 422,
  not_found: 422,
  out_of_range: 422,
  unavailable: 503,
  internal: 503,
  unknown: 503,
  deadline_exceeded: 503,
  resource_exhausted: 503,
};

const HTTP_STATUS_TO_TRANSPORT_STATUS: Record<number, FinanceTransportErrorStatus> = {
  400: 422,
  401: 401,
  403: 403,
  404: 422,
  409: 409,
  412: 409,
  422: 422,
  429: 503,
  500: 503,
  502: 503,
  503: 503,
  504: 503,
};

export function createHttpsCallableInvoker(
  config: HttpsCallableInvokerConfig,
): FinanceCallableInvoker {
  const fetchImpl = config.fetchImpl ?? fetch;
  const baseUrl = config.baseUrl.trim().replace(/\/+$/, "");

  return async (
    callableName: string,
    payload: Record<string, unknown>,
  ): Promise<unknown> => {
    let finalAuthToken = typeof config.authToken === "function" ? await config.authToken() : config.authToken;
    const finalAppCheckToken = typeof config.appCheckToken === "function" ? await config.appCheckToken() : config.appCheckToken;

    if (!finalAuthToken) {
       try {
          const { auth } = await import("@/lib/firebase/client");
          if (auth.currentUser) {
            finalAuthToken = await auth.currentUser.getIdToken();
          }
       } catch (e) {
          // Client SDK not available on server, or similar issue
       }
    }

    const response = await fetchImpl(`${baseUrl}/${callableName}`, {
      method: "POST",
      cache: "no-store",
      headers: {
        "Content-Type": "application/json",
        ...(finalAuthToken
          ? {
              Authorization: `Bearer ${finalAuthToken}`,
            }
          : {}),
        ...(finalAppCheckToken
          ? {
              "X-Firebase-AppCheck": finalAppCheckToken,
            }
          : {}),
      },
      body: JSON.stringify({ data: payload }),
    });

    const responseText = await response.text();
    const parsed = parseJsonSafely(responseText);
    const parsedRecord = asRecord(parsed);
    const parsedError = asRecord(parsedRecord?.error);

    if (!response.ok || parsedError) {
      throw {
        code:
          toNonEmptyString(parsedError?.status) ??
          toNonEmptyString(parsedError?.code) ??
          undefined,
        status: response.status,
        message:
          toNonEmptyString(parsedError?.message) ??
          `Callable ${callableName} failed with status ${response.status}.`,
        details: parsedError?.details ?? parsed ?? responseText,
      };
    }

    if (parsedRecord && "result" in parsedRecord) {
      return parsedRecord.result;
    }

    if (parsedRecord && "data" in parsedRecord) {
      return parsedRecord.data;
    }

    return parsed;
  };
}

export function mapBackendErrorToTransportError(rawError: unknown): FinanceTransportError {
  const errorRecord = asRecord(rawError);

  if (errorRecord) {
    const code = normalizeBackendCode(
      toNonEmptyString(errorRecord.code) ?? toNonEmptyString(errorRecord.status),
    );
    const message = toNonEmptyString(errorRecord.message);
    const details = toDetails(errorRecord.details);

    if (isAppCheckFailure(code, message, details)) {
      return {
        status: 403,
        message: message ?? "App Check verification failed.",
        details,
      };
    }

    if (code && CALLABLE_CODE_TO_TRANSPORT_STATUS[code]) {
      return {
        status: CALLABLE_CODE_TO_TRANSPORT_STATUS[code],
        message: message ?? "Finance command failed.",
        details,
      };
    }

    const httpStatus =
      typeof errorRecord.status === "number"
        ? errorRecord.status
        : typeof errorRecord.httpStatus === "number"
          ? errorRecord.httpStatus
          : undefined;

    if (httpStatus && HTTP_STATUS_TO_TRANSPORT_STATUS[httpStatus]) {
      return {
        status: HTTP_STATUS_TO_TRANSPORT_STATUS[httpStatus],
        message: message ?? "Finance command failed.",
        details: toDetails(errorRecord.details) ?? toDetails(errorRecord),
      };
    }

    return {
      status: 503,
      message:
        message ??
        "Finance backend transport is unavailable.",
      details: toDetails(errorRecord),
    };
  }

  if (rawError instanceof Error) {
    return {
      status: 503,
      message: rawError.message,
    };
  }

  if (typeof rawError === "string" && rawError.trim().length > 0) {
    return {
      status: 503,
      message: rawError.trim(),
    };
  }

  return {
    status: 503,
    message: "Finance backend transport is unavailable.",
  };
}

export type FinanceCallableInvokerResolution =
  | {
      ok: true;
      invokeCallable: FinanceCallableInvoker;
    }
  | {
      ok: false;
      reason: string;
    };

export function createFinanceCallableInvokerFromEnv(
  env: Record<string, string | undefined> = process.env,
): FinanceCallableInvokerResolution {
  const baseUrl = env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL?.trim();
  if (!baseUrl) {
    return {
      ok: false,
      reason:
        "NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL is not configured for callable transport.",
    };
  }

  if (isLiveFirebaseFunctionsUrl(baseUrl) && isProductionRuntime(env)) {
    if (hasConfiguredToken(env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN)) {
      return {
        ok: false,
        reason:
          "NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN is forbidden in production. Use a server-side admin command proxy.",
      };
    }

    if (hasConfiguredToken(env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN)) {
      return {
        ok: false,
        reason:
          "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is forbidden in production. Use a server-side admin command proxy.",
      };
    }
  }

  const appCheckToken = env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN?.trim();
  if (isLiveFirebaseFunctionsUrl(baseUrl)) {
    if (!appCheckToken) {
      return {
        ok: false,
        reason:
          "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is not configured for live callable transport.",
      };
    }

    if (isPlaceholderAppCheckToken(appCheckToken)) {
      return {
        ok: false,
        reason:
          "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is a placeholder and cannot call live Firebase Functions.",
      };
    }
  }

  return {
    ok: true,
    invokeCallable: createHttpsCallableInvoker({
      baseUrl,
      authToken: env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
      appCheckToken,
    }),
  };
}

function normalizeBackendCode(code: string | undefined): string | undefined {
  if (!code) {
    return undefined;
  }

  return code.trim().toLowerCase().replace(/-/g, "_");
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

function toDetails(value: unknown): Record<string, unknown> | undefined {
  const record = asRecord(value);
  if (!record) {
    return undefined;
  }

  const details: Record<string, unknown> = {};
  for (const [key, entry] of Object.entries(record)) {
    details[key] = entry;
  }
  return details;
}

function isAppCheckFailure(
  code: string | undefined,
  message: string | undefined,
  details: Record<string, unknown> | undefined,
): boolean {
  const detailsText = details ? JSON.stringify(details) : "";
  return [code, message, detailsText].some((value) =>
    typeof value === "string" && value.toLowerCase().includes("app check"),
  );
}

export function isLiveFirebaseFunctionsUrl(value: string): boolean {
  return /^https:\/\/[^/]+\.cloudfunctions\.net(?:\/|$)/i.test(value.trim());
}

function isPlaceholderAppCheckToken(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  return (
    normalized === "local-dev-app-check" ||
    normalized.includes("placeholder") ||
    normalized.includes("dummy") ||
    normalized.includes("invalid")
  );
}

export function isProductionRuntime(env: Record<string, string | undefined>): boolean {
  return env.NODE_ENV?.trim().toLowerCase() === "production";
}

function hasConfiguredToken(value: string | undefined): boolean {
  return typeof value === "string" && value.trim().length > 0;
}
