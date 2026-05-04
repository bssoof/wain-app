import {
  FINANCE_READ_CALLABLE_SURFACES,
  createFinanceReadAdaptersTransport,
} from "./finance-read-adapters";
import {
  createFinanceCallableInvokerFromEnv,
  type FinanceCallableInvoker,
} from "./finance-command-transport";
import {
  createFinanceReadSnapshotTransport,
  createLayeredFinanceReadTransport,
} from "./finance-read-snapshot-transport";
import type { FinanceReadTransport } from "./finance-read-transport";
import type { FinanceReadResult, FinanceReadSuccess } from "./finance-read-types";
import type {
  FinanceReadFailure,
  FinanceReadFreshness,
  FinanceReadSource,
  TopUpRequest,
  WalletLedgerEntry,
  WalletReadinessReport,
} from "./read-models";

export type TopUpReadData = { pending: TopUpRequest[] };
export type LedgerReadData = { entries: WalletLedgerEntry[] };
export type ReadinessReadData = { report: WalletReadinessReport };

export type FinanceReadLoaderOptions = {
  env?: Record<string, string | undefined>;
  now?: () => Date;
  invokeCallable?: FinanceCallableInvoker;
  fetchImpl?: typeof fetch;
};

type LoaderContext = {
  env: Record<string, string | undefined>;
  transport: FinanceReadTransport;
};

type LoaderContextResolution =
  | {
      ok: true;
      context: LoaderContext;
    }
  | {
      ok: false;
      message: string;
      attemptedSource: string;
    };

export async function loadTopUpQueueRead(
  options?: FinanceReadLoaderOptions,
): Promise<FinanceReadResult<TopUpReadData>> {
  const resolved = resolveLoaderContext(options);
  if (!resolved.ok) {
    return {
      kind: "unavailable",
      message: resolved.message,
      attemptedSource: resolved.attemptedSource,
    };
  }

  const result = await resolved.context.transport.readTopUpQueue({
    maxAgeMs: resolveMaxAgeMs(resolved.context.env, "topup_queue"),
  });

  if (!result.ok) {
    return toUnavailableResult(result);
  }

  const pending =
    result.state === "empty"
      ? []
      : result.data.filter((request) => request.status === "pending");

  return toSuccessResult(
    {
      pending,
    },
    result.freshness,
    result.state,
  );
}

export async function loadWalletLedgerRead(
  options?: FinanceReadLoaderOptions,
): Promise<FinanceReadResult<LedgerReadData>> {
  const resolved = resolveLoaderContext(options);
  if (!resolved.ok) {
    return {
      kind: "unavailable",
      message: resolved.message,
      attemptedSource: resolved.attemptedSource,
    };
  }

  const result = await resolved.context.transport.readWalletAudit({
    maxAgeMs: resolveMaxAgeMs(resolved.context.env, "wallet_audit"),
  });

  if (!result.ok) {
    return toUnavailableResult(result);
  }

  const entries = result.state === "empty" ? [] : result.data;

  return toSuccessResult(
    {
      entries,
    },
    result.freshness,
    result.state,
  );
}

export async function loadReadinessRead(
  options?: FinanceReadLoaderOptions,
): Promise<FinanceReadResult<ReadinessReadData>> {
  const resolved = resolveLoaderContext(options);
  if (!resolved.ok) {
    return {
      kind: "unavailable",
      message: resolved.message,
      attemptedSource: resolved.attemptedSource,
    };
  }

  const result = await resolved.context.transport.readWalletReadiness({
    reason: "Admin web console readiness read",
    maxAgeMs: resolveMaxAgeMs(resolved.context.env, "wallet_readiness"),
  });

  if (!result.ok) {
    return toUnavailableResult(result);
  }

  const report =
    result.state === "empty"
      ? buildEmptyReadinessReport(result.freshness.checkedAt)
      : result.data;

  return toSuccessResult(
    {
      report,
    },
    result.freshness,
    result.state,
  );
}

function resolveLoaderContext(
  options: FinanceReadLoaderOptions | undefined,
): LoaderContextResolution {
  const _t0 = performance.now();
  const env = options?.env ?? process.env;
  const nowFn = options?.now ?? (() => new Date());
  const fetchImpl = options?.fetchImpl ?? fetch;

  const snapshotTransport = createFinanceReadSnapshotTransport({
    env,
    now: nowFn,
    fetchImpl,
  });

  if (options?.invokeCallable) {
    const callableTransport = createFinanceReadAdaptersTransport({
      invokeCallable: options.invokeCallable,
      now: nowFn,
    });
    console.log(`[PERF] resolveLoaderContext: ${(performance.now() - _t0).toFixed(0)}ms (explicit callable)`);
    return {
      ok: true,
      context: {
        env,
        transport: createLayeredFinanceReadTransport({
          snapshot: snapshotTransport,
          callable: callableTransport,
        }),
      },
    };
  }

  const invokerResolution = createFinanceCallableInvokerFromEnv(env);
  if (invokerResolution.ok) {
    const callableTransport = createFinanceReadAdaptersTransport({
      invokeCallable: invokerResolution.invokeCallable,
      now: nowFn,
    });
    console.log(`[PERF] resolveLoaderContext: ${(performance.now() - _t0).toFixed(0)}ms (env callable)`);
    return {
      ok: true,
      context: {
        env,
        transport: createLayeredFinanceReadTransport({
          snapshot: snapshotTransport,
          callable: callableTransport,
        }),
      },
    };
  }

  console.log(`[PERF] resolveLoaderContext: ${(performance.now() - _t0).toFixed(0)}ms (snapshot only)`);
  return {
    ok: true,
    context: {
      env,
      transport: snapshotTransport,
    },
  };
}

function resolveMaxAgeMs(
  env: Record<string, string | undefined>,
  source: FinanceReadSource,
): number | undefined {
  const sourceKey =
    source === "topup_queue"
      ? "WAIN_FINANCE_TOPUP_READ_STALE_AFTER_MS"
      : source === "wallet_audit"
        ? "WAIN_FINANCE_LEDGER_READ_STALE_AFTER_MS"
        : "WAIN_FINANCE_READINESS_READ_STALE_AFTER_MS";

  const sourceValue = parsePositiveInt(env[sourceKey]);
  if (sourceValue !== undefined) {
    return sourceValue;
  }

  return parsePositiveInt(env.WAIN_FINANCE_READ_STALE_AFTER_MS);
}

function toSuccessResult<TData>(
  data: TData,
  freshness: FinanceReadFreshness,
  state: "success" | "stale" | "empty",
): FinanceReadSuccess<TData> {
  return {
    kind: "success",
    data,
    asOf: freshness.checkedAt,
    fetchedAt: freshness.fetchedAt,
    source: freshness.channel ?? formatReadSource(freshness.source),
    stale: state === "stale" || freshness.ageMs > freshness.staleAfterMs,
  };
}

function toUnavailableResult(failure: FinanceReadFailure): FinanceReadResult<never> {
  const reasonPrefix =
    failure.state === "unauthorized"
      ? "Unauthorized"
      : failure.state === "forbidden"
        ? "Forbidden"
        : null;

  return {
    kind: "unavailable",
    message: reasonPrefix ? `${reasonPrefix}: ${failure.message}` : failure.message,
    attemptedSource: resolveAttemptedSource(failure),
  };
}

function resolveAttemptedSource(failure: FinanceReadFailure): string {
  const details = asRecord(failure.details);
  if (details) {
    const channel = toNonEmptyString(details.channel);
    if (channel) {
      return channel;
    }
    const requiredSurface = toNonEmptyString(details.requiredSurface);
    if (requiredSurface) {
      return `callable:${requiredSurface}`;
    }
  }

  return formatReadSource(failure.source);
}

function formatReadSource(source: FinanceReadSource): string {
  const callableSurface = FINANCE_READ_CALLABLE_SURFACES[source];
  return callableSurface
    ? `callable:${callableSurface}`
    : `missing_surface:${source}`;
}

function buildEmptyReadinessReport(generatedAt: string): WalletReadinessReport {
  return {
    generatedAt,
    overallStatus: "warning",
    summary: "لم تُرجع الخدمة الخلفية أي تشخيصات للجاهزية.",
    checks: [],
  };
}

function parsePositiveInt(raw: string | undefined): number | undefined {
  if (raw === undefined || raw.trim().length === 0) {
    return undefined;
  }

  const value = Number.parseInt(raw, 10);
  return Number.isFinite(value) && value > 0 ? value : undefined;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, unknown>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}
