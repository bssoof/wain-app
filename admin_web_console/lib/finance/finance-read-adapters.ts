import type { FinanceCallableInvoker } from "./finance-command-transport";
import {
  FINANCE_READ_STALE_AFTER_MS,
  createFinanceReadEmpty,
  createFinanceReadSuccess,
  normalizeFinanceReadFailure,
  resolveReadFreshness,
  type FinanceReadTransport,
} from "./finance-read-transport";
import type {
  FinanceReadFailure,
  FinanceReadSource,
  TopUpQueueReadQuery,
  TopUpQueueReadResult,
  TopUpRequest,
  WalletAuditReadQuery,
  WalletAuditReadResult,
  WalletLedgerEntry,
  WalletReadinessReadQuery,
  WalletReadinessReadResult,
  WalletReadinessReport,
} from "./read-models";

type FinanceReadCallableName =
  | "verifyWalletOperationalReadiness"
  | "listMerchantTopUpRequestsForAdmin"
  | "listMerchantWalletLedgerEntriesForAdmin";

export const FINANCE_READ_CALLABLE_SURFACES: Record<
  FinanceReadSource,
  FinanceReadCallableName | null
> = {
  topup_queue: "listMerchantTopUpRequestsForAdmin",
  wallet_audit: "listMerchantWalletLedgerEntriesForAdmin",
  wallet_readiness: "verifyWalletOperationalReadiness",
};

export type FinanceReadAdaptersOptions = {
  invokeCallable: FinanceCallableInvoker;
  now?: () => Date;
  staleAfterMsBySource?: Partial<Record<FinanceReadSource, number>>;
};

export function createFinanceReadAdaptersTransport(
  options: FinanceReadAdaptersOptions,
): FinanceReadTransport {
  const now = options.now ?? (() => new Date());

  return {
    async readTopUpQueue(query?: TopUpQueueReadQuery): Promise<TopUpQueueReadResult> {
      const source: FinanceReadSource = "topup_queue";
      const surface = FINANCE_READ_CALLABLE_SURFACES.topup_queue;
      if (!surface) {
        return missingSurfaceFailure(source, query);
      }

      const fetchedAt = now();
      const staleAfterMs = resolveStaleAfterMs(source, query?.maxAgeMs, options);

      try {
        const raw = asRecord(
          await options.invokeCallable(surface, buildTopUpQueuePayload(query)),
        );

        const freshness = resolveReadFreshness({
          source,
          checkedAt: raw?.checkedAt,
          fetchedAt,
          staleAfterMs,
          channel: `callable:${surface}`,
        });

        const requests = parseTopUpRequestsPayload(raw?.requests);
        if (requests === null) {
          return normalizeFinanceReadFailure(source, {
            code: "internal",
            message: "Top-up read response was missing or malformed.",
          });
        }

        if (requests.length === 0) {
          return createFinanceReadEmpty({ freshness });
        }

        return createFinanceReadSuccess({
          data: requests,
          freshness,
        });
      } catch (error) {
        return normalizeFinanceReadFailure(source, error);
      }
    },

    async readWalletAudit(
      query?: WalletAuditReadQuery,
    ): Promise<WalletAuditReadResult> {
      const source: FinanceReadSource = "wallet_audit";
      const surface = FINANCE_READ_CALLABLE_SURFACES.wallet_audit;
      if (!surface) {
        return missingSurfaceFailure(source, query);
      }

      const fetchedAt = now();
      const staleAfterMs = resolveStaleAfterMs(source, query?.maxAgeMs, options);

      try {
        const raw = asRecord(
          await options.invokeCallable(surface, buildWalletAuditPayload(query)),
        );

        const freshness = resolveReadFreshness({
          source,
          checkedAt: raw?.checkedAt,
          fetchedAt,
          staleAfterMs,
          channel: `callable:${surface}`,
        });

        const entries = parseWalletLedgerEntriesPayload(raw?.entries);
        if (entries === null) {
          return normalizeFinanceReadFailure(source, {
            code: "internal",
            message: "Wallet audit read response was missing or malformed.",
          });
        }

        if (entries.length === 0) {
          return createFinanceReadEmpty({ freshness });
        }

        return createFinanceReadSuccess({
          data: entries,
          freshness,
        });
      } catch (error) {
        return normalizeFinanceReadFailure(source, error);
      }
    },

    async readWalletReadiness(
      query?: WalletReadinessReadQuery,
    ): Promise<WalletReadinessReadResult> {
      const source: FinanceReadSource = "wallet_readiness";
      const surface = FINANCE_READ_CALLABLE_SURFACES.wallet_readiness;
      if (!surface) {
        return missingSurfaceFailure(source, query);
      }

      const fetchedAt = now();
      const staleAfterMs = resolveStaleAfterMs(source, query?.maxAgeMs, options);

      try {
        const diagnostics = asRecord(
          await options.invokeCallable(surface, buildReadinessPayload(query)),
        );

        const freshness = resolveReadFreshness({
          source,
          checkedAt: diagnostics?.checkedAt,
          fetchedAt,
          staleAfterMs,
          channel: `callable:${surface}`,
        });

        const report = toWalletReadinessReport(diagnostics, freshness.checkedAt);
        if (!report) {
          return createFinanceReadEmpty({ freshness });
        }

        return createFinanceReadSuccess({
          data: report,
          freshness,
        });
      } catch (error) {
        return normalizeFinanceReadFailure(source, error);
      }
    },
  };
}

function buildTopUpQueuePayload(
  query: TopUpQueueReadQuery | undefined,
): Record<string, unknown> {
  return {
    ...(query?.venueId ? { venueId: query.venueId } : {}),
    ...(typeof query?.limit === "number" ? { limit: query.limit } : {}),
    ...(query?.statuses && query.statuses.length > 0
      ? { statuses: query.statuses }
      : {}),
    ...(query?.createdAfter ? { createdAfter: query.createdAfter } : {}),
    ...(query?.createdBefore ? { createdBefore: query.createdBefore } : {}),
    ...(query?.correlationId ? { correlationId: query.correlationId } : {}),
  };
}

function buildWalletAuditPayload(
  query: WalletAuditReadQuery | undefined,
): Record<string, unknown> {
  return {
    ...(query?.venueId ? { venueId: query.venueId } : {}),
    ...(typeof query?.limit === "number" ? { limit: query.limit } : {}),
    ...(query?.entryTypes && query.entryTypes.length > 0
      ? { entryTypes: query.entryTypes }
      : {}),
    ...(query?.createdAfter ? { createdAfter: query.createdAfter } : {}),
    ...(query?.createdBefore ? { createdBefore: query.createdBefore } : {}),
    ...(query?.correlationId ? { correlationId: query.correlationId } : {}),
  };
}

function buildReadinessPayload(
  query: WalletReadinessReadQuery | undefined,
): Record<string, unknown> {
  return {
    ...(query?.reason
      ? {
          reason: query.reason,
        }
      : {}),
    ...(query?.correlationId
      ? {
          correlationId: query.correlationId,
        }
      : {}),
  };
}

function resolveStaleAfterMs(
  source: FinanceReadSource,
  queryMaxAgeMs: number | undefined,
  options: FinanceReadAdaptersOptions,
): number {
  if (typeof queryMaxAgeMs === "number" && Number.isFinite(queryMaxAgeMs)) {
    return queryMaxAgeMs;
  }

  const configured = options.staleAfterMsBySource?.[source];
  if (typeof configured === "number" && Number.isFinite(configured)) {
    return configured;
  }

  return FINANCE_READ_STALE_AFTER_MS[source];
}

function toWalletReadinessReport(
  diagnostics: Record<string, any> | undefined,
  checkedAtIso: string,
): WalletReadinessReport | null {
  if (!diagnostics) {
    return null;
  }

  const failureChecks = toStringArray(diagnostics.failureChecks);
  const warningChecks = toStringArray(diagnostics.warningChecks);

  const checks = buildReadinessChecks(diagnostics);
  const overallStatus =
    normalizeOverallStatus(diagnostics.overallStatus) ??
    (failureChecks.length > 0
      ? "blocked"
      : warningChecks.length > 0
        ? "warning"
        : checks.length > 0
          ? "ready"
          : undefined);

  if (!overallStatus && checks.length === 0) {
    return null;
  }

  return {
    generatedAt: checkedAtIso,
    overallStatus: overallStatus ?? "warning",
    summary: buildReadinessSummary(overallStatus, failureChecks, warningChecks, checks.length),
    checks,
  };
}

function buildReadinessSummary(
  overallStatus: WalletReadinessReport["overallStatus"] | undefined,
  failureChecks: string[],
  warningChecks: string[],
  checksCount: number,
): string {
  if (overallStatus === "blocked") {
    const failures = failureChecks.length > 0 ? failureChecks.join("، ") : "فحوصات حرجة";
    return `تعذرت جاهزية التشغيل بسبب: ${failures}.`;
  }

  if (overallStatus === "warning") {
    const warnings = warningChecks.length > 0 ? warningChecks.join("، ") : "فحوصات تحتاج متابعة";
    return `تم رصد تنبيهات جاهزية في: ${warnings}.`;
  }

  if (checksCount > 0) {
    return "اجتازت المحافظ فحوصات الجاهزية التشغيلية.";
  }

  return "لم تُرجع الخدمة الخلفية أي تشخيصات للجاهزية.";
}

function buildReadinessChecks(
  diagnostics: Record<string, any>,
): WalletReadinessReport["checks"] {
  const checks: WalletReadinessReport["checks"] = [];

  const pushCheck = (
    id: string,
    label: string,
    statusValue: unknown,
    details: string,
  ) => {
    const status = normalizeCheckStatus(statusValue);
    if (!status) {
      return;
    }

    checks.push({
      id,
      label,
      status,
      details,
    });
  };

  const pricing = asRecord(diagnostics.pricing);
  if (pricing) {
    const pricingIssues = toStringArray(pricing.issues);
    pushCheck(
      "readiness_pricing",
      "إعدادات التسعير",
      pricing.status,
      pricingIssues.length > 0
        ? pricingIssues.join("; ")
        : pricing.exists === false
          ? "مستند إعدادات التسعير غير موجود."
          : "تم التحقق من إعدادات التسعير.",
    );
  }

  const readModels = asRecord(diagnostics.readModels);
  if (readModels) {
    pushCheck(
      "readiness_read_models",
      "نماذج القراءة",
      readModels.status,
      readModels.hasAnyWalletReport
        ? "نموذج قراءة تقارير المحافظ متاح."
        : "نموذج قراءة تقارير المحافظ لا يحتوي بيانات بعد.",
    );
  }

  const walletDefaults = asRecord(diagnostics.walletDefaults);
  if (walletDefaults) {
    pushCheck(
      "readiness_wallet_defaults",
      "القيم الافتراضية للمحافظ",
      walletDefaults.status,
      walletDefaults.hasAnyWalletDoc
        ? "تم رصد القيم الافتراضية من مستندات المحافظ."
        : "لا توجد مستندات محافظ بعد.",
    );
  }

  const notifications = asRecord(diagnostics.notifications);
  if (notifications) {
    pushCheck(
      "readiness_notifications",
      "الإشعارات",
      notifications.status,
      notifications.hasAnyExpiryReminderEvent
        ? "تم رصد أحداث تذكير بالإشعارات."
        : "لم يتم رصد أحداث تذكير بالانتهاء بعد.",
    );
  }

  return checks;
}

function normalizeOverallStatus(
  value: unknown,
): WalletReadinessReport["overallStatus"] | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalized = value.trim().toUpperCase();
  if (normalized === "PASS") {
    return "ready";
  }

  if (normalized === "WARN") {
    return "warning";
  }

  if (normalized === "FAIL") {
    return "blocked";
  }

  return undefined;
}

function normalizeCheckStatus(
  value: unknown,
): WalletReadinessReport["checks"][number]["status"] | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalized = value.trim().toUpperCase();
  if (normalized === "PASS") {
    return "pass";
  }

  if (normalized === "WARN") {
    return "warn";
  }

  if (normalized === "FAIL") {
    return "fail";
  }

  return undefined;
}

function missingSurfaceFailure(
  source: FinanceReadSource,
  query: unknown,
): FinanceReadFailure {
  return {
    ok: false,
    source,
    state: "unavailable",
    message: `No backend read surface exists for source ${source}.`,
    retryable: false,
    details: {
      source,
      query: sanitizeQuery(query),
      requiredSurface: FINANCE_READ_CALLABLE_SURFACES[source],
    },
  };
}

function sanitizeQuery(query: unknown): Record<string, unknown> | undefined {
  const record = asRecord(query);
  if (!record) {
    return undefined;
  }

  const output: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(record)) {
    output[key] = value;
  }

  return output;
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => (typeof entry === "string" ? entry.trim() : ""))
    .filter((entry) => entry.length > 0);
}

function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }

  return value as Record<string, any>;
}

function isTopUpRequestRow(value: unknown): value is TopUpRequest {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const row = value as Record<string, unknown>;
  return (
    typeof row.id === "string" &&
    typeof row.userId === "string" &&
    typeof row.userName === "string" &&
    typeof row.amount === "number" &&
    (row.currency === "ILS" || row.currency === "USD") &&
    typeof row.providerReference === "string" &&
    typeof row.createdAt === "string" &&
    (row.status === "pending" ||
      row.status === "credited" ||
      row.status === "rejected")
  );
}

function parseTopUpRequestsPayload(value: unknown): TopUpRequest[] | null {
  if (!Array.isArray(value)) {
    return null;
  }
  const out: TopUpRequest[] = [];
  for (const item of value) {
    if (!isTopUpRequestRow(item)) {
      return null;
    }
    out.push(item);
  }
  return out;
}

function isWalletLedgerRow(value: unknown): value is WalletLedgerEntry {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const row = value as Record<string, unknown>;
  return (
    typeof row.id === "string" &&
    typeof row.userId === "string" &&
    typeof row.userName === "string" &&
    (row.type === "credit" || row.type === "debit" || row.type === "reversal") &&
    typeof row.amount === "number" &&
    (row.currency === "ILS" || row.currency === "USD") &&
    typeof row.description === "string" &&
    typeof row.reference === "string" &&
    typeof row.createdAt === "string"
  );
}

function parseWalletLedgerEntriesPayload(
  value: unknown,
): WalletLedgerEntry[] | null {
  if (!Array.isArray(value)) {
    return null;
  }
  const out: WalletLedgerEntry[] = [];
  for (const item of value) {
    if (!isWalletLedgerRow(item)) {
      return null;
    }
    out.push(item);
  }
  return out;
}
