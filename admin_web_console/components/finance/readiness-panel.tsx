"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import {
  canRenderAction,
  type AdminSession,
} from "@/lib/auth/guard-api";
import type { ReadinessReadData } from "@/lib/finance/finance-read-loader";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";
import type { AdminCapabilityKey } from "@/lib/navigation/admin-contract";
import {
  formatDate,
  formatStatus,
  getStatusColorClass,
} from "@/lib/finance/read-model-formatters";
import {
  buildVerifyWalletReadinessRequest,
  commandKey,
} from "@/lib/finance/build-command-requests";
import { getCommandRuntimeStateClass } from "@/lib/finance/command-ui";
import { buildReadinessCommandAffordance } from "@/lib/finance/surface-affordances";

import { CommandRuntimeCallout } from "./command-runtime-callout";
import { useFinanceCommands } from "./finance-command-provider";
import { StatusBadge } from "../shared/status-badge";

type ReadinessReport = ReadinessReadData["report"];
type ReadinessCheck = ReadinessReport["checks"][number];
type ReadinessCounts = Record<ReadinessCheck["status"], number>;
type ReadinessCheckAction = {
  href: string;
  label: string;
  requiredCapability: AdminCapabilityKey;
};

const readinessNumberFormatter = new Intl.NumberFormat("ar-PS-u-nu-latn");

const READINESS_CHECK_COPY: Record<
  string,
  Pick<ReadinessCheck, "label" | "details">
> = {
  readiness_ledger_stream: {
    label: "تدفق عمليات المحفظة",
    details: "تسجيل العمليات يصل ضمن الوقت المتوقع.",
  },
  readiness_reversal_workers: {
    label: "معالجة طلبات التصحيح",
    details: "طلبات التصحيح تراقب حتى لا تتراكم دون متابعة.",
  },
  readiness_settlement_export: {
    label: "تصدير التسويات",
    details: "ملفات التسوية الدورية تجهز للمتابعة المالية.",
  },
  readiness_pricing: {
    label: "أسعار المحفظة",
    details: "إعدادات الأسعار متاحة قبل تنفيذ عمليات جديدة.",
  },
  readiness_read_models: {
    label: "قراءات صفحات المالية",
    details: "مصادر القراءة جاهزة لعرض أحدث حالة ممكنة.",
  },
  readiness_wallet_defaults: {
    label: "إعدادات المحفظة الأساسية",
    details: "القيم الافتراضية موجودة قبل تشغيل أوامر المحفظة.",
  },
  readiness_notifications: {
    label: "تنبيهات العمليات",
    details: "تنبيهات المتابعة جاهزة عند وجود مشكلة تحتاج تدخلًا.",
  },
};

const READINESS_CHECK_ACTIONS: Record<string, ReadinessCheckAction> = {
  wallet_reports_coverage: {
    href: "/admin/venues",
    label: "عرض تقارير الجهات",
    requiredCapability: "view_venues",
  },
  wallet_low_balance_scan: {
    href: "/admin/venues",
    label: "مراجعة أرصدة الجهات",
    requiredCapability: "view_venues",
  },
};

function formatReadinessCount(value: number): string {
  return readinessNumberFormatter.format(value);
}

function summarizeReadinessChecks(checks: ReadinessReport["checks"]): ReadinessCounts {
  return checks.reduce<ReadinessCounts>(
    (counts, check) => {
      counts[check.status] += 1;
      return counts;
    },
    { pass: 0, warn: 0, fail: 0 },
  );
}

function containsLatinText(value: string): boolean {
  return /[A-Za-z]/.test(value);
}

function buildReportSummary(report: ReadinessReport, counts: ReadinessCounts): string {
  if (report.overallStatus === "blocked" || counts.fail > 0) {
    return "يوجد فحص يحتاج معالجة قبل اعتبار النظام جاهزًا.";
  }

  if (report.overallStatus === "warning" || counts.warn > 0) {
    return "النظام يعمل، مع وجود نقاط تحتاج متابعة.";
  }

  return "النظام جاهز ولا توجد فحوصات تحتاج متابعة.";
}

function formatCheckLabel(check: ReadinessCheck): string {
  const knownCopy = READINESS_CHECK_COPY[check.id];
  if (knownCopy) {
    return knownCopy.label;
  }

  if (containsLatinText(check.label)) {
    return `فحص النظام - ${formatStatus(check.status)}`;
  }

  return check.label;
}

function formatCheckDetails(check: ReadinessCheck): string {
  const knownCopy = READINESS_CHECK_COPY[check.id];
  if (knownCopy) {
    return knownCopy.details;
  }

  if (!containsLatinText(check.details)) {
    return check.details;
  }

  if (check.status === "fail") {
    return "هذا الجزء يحتاج معالجة قبل الاعتماد.";
  }

  if (check.status === "warn") {
    return "هذا الجزء يعمل، لكنه يحتاج متابعة.";
  }

  return "هذا الجزء يعمل ضمن النطاق المطلوب.";
}

function resolveCheckAction(
  check: ReadinessCheck,
  session: AdminSession | null,
): ReadinessCheckAction | null {
  const action = READINESS_CHECK_ACTIONS[check.id];
  if (!action) {
    return null;
  }

  if (!session || !canRenderAction(session, action.requiredCapability)) {
    return null;
  }

  return action;
}

export function ReadinessReportCard({
  readResult,
}: {
  readResult: FinanceReadResult<ReadinessReadData>;
}) {
  if (readResult.kind === "unavailable") {
    return (
      <section className="card finance-health-card" role="alert" dir="rtl" lang="ar">
        <div className="finance-section-heading">
          <h3>ملخص حالة المحفظة</h3>
          <p className="muted-text">آخر قراءة لحالة النظام غير متاحة حاليًا.</p>
        </div>
        <p className="finance-read-inline-unavailable">
          تعذر عرض حالة المحفظة: {readResult.message}
        </p>
      </section>
    );
  }

  const { report } = readResult.data;
  const counts = summarizeReadinessChecks(report.checks);
  const reportSummary = buildReportSummary(report, counts);

  return (
    <section className="card finance-health-card" dir="rtl" lang="ar">
      <div className="finance-section-header">
        <div className="finance-section-heading">
          <h3>ملخص حالة المحفظة</h3>
          <p className="muted-text">
            آخر تحديث: {formatDate(report.generatedAt)}
          </p>
        </div>
        <StatusBadge className={getStatusColorClass(report.overallStatus)}>
          الحالة العامة: {formatStatus(report.overallStatus)}
        </StatusBadge>
      </div>

      <div className="finance-health-summary" data-testid="finance-readiness-summary">
        <div className="finance-health-summary__item">
          <span className="muted-text">فحوصات سليمة</span>
          <strong>{formatReadinessCount(counts.pass)}</strong>
        </div>
        <div className="finance-health-summary__item">
          <span className="muted-text">تحتاج متابعة</span>
          <strong>{formatReadinessCount(counts.warn)}</strong>
        </div>
        <div className="finance-health-summary__item">
          <span className="muted-text">تحتاج معالجة</span>
          <strong>{formatReadinessCount(counts.fail)}</strong>
        </div>
      </div>

      <div className="finance-health-note">
        <span className="muted-text">الخلاصة</span>
        <p>{reportSummary}</p>
      </div>
    </section>
  );
}

export function ReadinessChecksPanel({
  readResult,
  session,
}: {
  readResult: FinanceReadResult<ReadinessReadData>;
  session?: AdminSession | null;
}) {
  if (readResult.kind === "unavailable") {
    return (
      <section className="card finance-health-card" dir="rtl" lang="ar">
        <div className="finance-section-heading">
          <h3>فحوصات النظام</h3>
          <p className="muted-text">تعذر تحميل تفاصيل الفحوصات في هذه القراءة.</p>
        </div>
        <p className="muted-text" data-testid="finance-readiness-checks-unavailable">
          الفحوصات غير متاحة حتى تنجح قراءة حالة النظام.
        </p>
      </section>
    );
  }

  const { report } = readResult.data;

  if (report.checks.length === 0) {
    return (
      <section className="card finance-health-card" dir="rtl" lang="ar">
        <div className="finance-section-heading">
          <h3>فحوصات النظام</h3>
          <p className="muted-text">لا توجد تفاصيل إضافية في هذه القراءة.</p>
        </div>
        <p data-testid="finance-read-empty">لا توجد فحوصات نظام في نسخة البيانات الحالية.</p>
      </section>
    );
  }

  return (
    <section className="card finance-health-card" dir="rtl" lang="ar">
      <div className="finance-section-heading">
        <h3>فحوصات النظام</h3>
        <p className="muted-text">كل فحص يوضح جزءًا من جاهزية المحفظة.</p>
      </div>
      <ul className="readiness-list">
        {report.checks.map((check) => {
          const action = resolveCheckAction(check, session ?? null);

          return (
            <li key={check.id}>
              <div className="readiness-list__content">
                <strong>{formatCheckLabel(check)}</strong>
                <p className="muted-text">{formatCheckDetails(check)}</p>
                {action ? (
                  <div className="readiness-list__actions">
                    <Link
                      href={action.href}
                      className="action-button action-button-secondary"
                      data-testid={`readiness-check-action-${check.id}`}
                    >
                      {action.label}
                    </Link>
                  </div>
                ) : null}
              </div>
              <StatusBadge className={getStatusColorClass(check.status)}>
                {formatStatus(check.status)}
              </StatusBadge>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

export function ReadinessCommandPanel() {
  const router = useRouter();
  const { runCommand, getRuntimeState, getLastErrorMessage, session } =
    useFinanceCommands();

  const runtimeKey = commandKey("verify_wallet_readiness", "readiness");
  const readinessCommand = buildReadinessCommandAffordance(
    session,
    getRuntimeState(runtimeKey),
  );

  const onRun = async () => {
    const result = await runCommand(
      runtimeKey,
      "verify_wallet_readiness",
      buildVerifyWalletReadinessRequest(),
    );
    if (result.ok) {
      router.refresh();
    }
  };

  return (
    <section className="card finance-action-shell" dir="rtl" lang="ar">
      <div className="finance-section-header">
        <div className="finance-section-heading">
          <h3>تحديث حالة النظام</h3>
          <p className="muted-text">
            شغّل فحصًا جديدًا عندما تحتاج تأكيدًا حديثًا قبل تنفيذ قرارات مالية.
          </p>
        </div>
        <StatusBadge
          className={getCommandRuntimeStateClass(
            readinessCommand.runtimeState,
          )}
        >
          {readinessCommand.statusText}
        </StatusBadge>
      </div>
      {readinessCommand.visible ? (
        <div className="finance-action-form">
          <p className="muted-text">
            التحديث لا يغير أرصدة المستخدمين، بل يعيد فحص حالة خدمات المحفظة.
          </p>
          <button
            type="button"
            className="action-button"
            disabled={!readinessCommand.enabled}
            aria-busy={
              getRuntimeState(runtimeKey) === "pending" ? "true" : "false"
            }
            onClick={() => void onRun()}
          >
            {readinessCommand.label}
          </button>
          <CommandRuntimeCallout
            state={readinessCommand.runtimeState}
            message={getLastErrorMessage(runtimeKey)}
            onRetry={() => void onRun()}
            onRefresh={() => router.refresh()}
          />
          <span className="muted-text">
            الصلاحية المطلوبة: {localizeAdminLabel(readinessCommand.requiredCapability)}
          </span>
        </div>
      ) : (
        <span className="muted-text">لا يملك هذا الدور صلاحية تحديث حالة النظام.</span>
      )}
    </section>
  );
}
