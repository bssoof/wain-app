import {
  mapBackendErrorToTransportError,
  type FinanceTransportError,
} from "./finance-command-transport";
import type {
  FinanceReadFailure,
  FinanceReadFreshness,
  FinanceReadSource,
  FinanceReadSuccess,
  FinanceReadSuccessState,
  TopUpQueueReadQuery,
  TopUpQueueReadResult,
  WalletAuditReadQuery,
  WalletAuditReadResult,
  WalletReadinessReadQuery,
  WalletReadinessReadResult,
} from "./read-models";

export type FinanceReadTransport = {
  readTopUpQueue(query?: TopUpQueueReadQuery): Promise<TopUpQueueReadResult>;
  readWalletAudit(query?: WalletAuditReadQuery): Promise<WalletAuditReadResult>;
  readWalletReadiness(query?: WalletReadinessReadQuery): Promise<WalletReadinessReadResult>;
};

export const FINANCE_READ_STALE_AFTER_MS: Record<FinanceReadSource, number> = {
  topup_queue: 5 * 60 * 1000,
  wallet_audit: 5 * 60 * 1000,
  wallet_readiness: 5 * 60 * 1000,
};

export function resolveReadFreshness(params: {
  source: FinanceReadSource;
  checkedAt: unknown;
  fetchedAt?: Date;
  staleAfterMs?: number;
  channel?: string;
}): FinanceReadFreshness {
  const fetchedAt = params.fetchedAt ?? new Date();
  const checkedAtIso = toIsoDateString(params.checkedAt) ?? fetchedAt.toISOString();
  const checkedAtMillis = new Date(checkedAtIso).getTime();
  const fetchedAtMillis = fetchedAt.getTime();
  const ageMs = Math.max(0, fetchedAtMillis - checkedAtMillis);
  const staleAfterMs =
    params.staleAfterMs ?? FINANCE_READ_STALE_AFTER_MS[params.source];

  return {
    source: params.source,
    checkedAt: checkedAtIso,
    fetchedAt: fetchedAt.toISOString(),
    ageMs,
    staleAfterMs,
    ...(params.channel ? { channel: params.channel } : {}),
  };
}

export function toReadSuccessState(
  freshness: FinanceReadFreshness,
): FinanceReadSuccessState {
  return freshness.ageMs > freshness.staleAfterMs ? "stale" : "success";
}

export function createFinanceReadSuccess<TData>(params: {
  data: TData;
  freshness: FinanceReadFreshness;
}): FinanceReadSuccess<TData> {
  return {
    ok: true,
    state: toReadSuccessState(params.freshness),
    data: params.data,
    freshness: params.freshness,
  };
}

export function createFinanceReadEmpty(params: {
  freshness: FinanceReadFreshness;
}): {
  ok: true;
  state: "empty";
  data: null;
  freshness: FinanceReadFreshness;
} {
  return {
    ok: true,
    state: "empty",
    data: null,
    freshness: params.freshness,
  };
}

export function normalizeFinanceReadFailure(
  source: FinanceReadSource,
  error: unknown,
): FinanceReadFailure {
  const transportError = mapBackendErrorToTransportError(error);
  const mapped = mapTransportErrorState(transportError);

  return {
    ok: false,
    source,
    state: mapped.state,
    message: transportError.message,
    retryable: mapped.retryable,
    ...(transportError.details ? { details: transportError.details } : {}),
  };
}

function mapTransportErrorState(error: FinanceTransportError): {
  state: FinanceReadFailure["state"];
  retryable: boolean;
} {
  if (error.status === 401) {
    return {
      state: "unauthorized",
      retryable: false,
    };
  }

  if (error.status === 403) {
    return {
      state: "forbidden",
      retryable: false,
    };
  }

  return {
    state: "unavailable",
    retryable: true,
  };
}

function toIsoDateString(value: unknown): string | undefined {
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
    return undefined;
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value).toISOString();
  }

  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return value.toISOString();
  }

  return undefined;
}
