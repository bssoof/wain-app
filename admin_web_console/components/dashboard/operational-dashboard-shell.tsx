import React from "react";
import Link from "next/link";

import { formatAdminDate } from "@/lib/admin/admin-localization";
import {
  formatCurrency,
  formatStatus,
} from "@/lib/finance/read-model-formatters";
import type {
  ContentModerationBacklogSummary,
  OpsDashboardSummary,
  OpsWidgetData,
  TopUpQueueSummary,
  VenueDirectorySummary,
  WalletReadinessSummary,
} from "@/lib/dashboard/dashboard-models";

import { KpiWidget } from "./kpi-widget";

export type OperationalDashboardShellProps = {
  summary: OpsDashboardSummary;
};

export function OperationalDashboardShell({
  summary,
}: OperationalDashboardShellProps) {
  const isOverallStale = Object.values(summary).some(
    (value) =>
      typeof value === "object" &&
      value !== null &&
      "state" in value &&
      value.state === "stale",
  );

  return (
    <div className="dashboard-shell" dir="rtl" lang="ar">
      <header className="dashboard-shell__header">
        <div className="dashboard-shell__intro">
          <h1 className="dashboard-shell__title">نظرة عامة</h1>
          <p className="dashboard-shell__description">
            متابعة سريعة لما يحتاج قرارًا أو انتباهًا داخل لوحة الأدمن.
          </p>
        </div>
        {isOverallStale ? (
          <div className="dashboard-shell__stale-flag">
            بعض الأقسام تعتمد على بيانات قديمة.
          </div>
        ) : null}
      </header>

      <DashboardOverviewStrip summary={summary} />

      <div className="dashboard-shell__grid" data-testid="dashboard-widget-grid">
        <KpiWidget
          title="طلبات الشحن"
          widget={summary.topUpQueue}
          renderData={renderTopUpQueue}
        />

        <KpiWidget
          title="محتوى ينتظر المراجعة"
          widget={summary.contentModeration}
          renderData={renderContentModeration}
        />

        <KpiWidget
          title="صحة المحفظة"
          widget={summary.walletReadiness}
          renderData={renderWalletReadiness}
        />

        <KpiWidget
          title="حالة الجهات"
          widget={summary.venueDirectory}
          renderData={renderVenueDirectory}
        />
      </div>

      <div className="dashboard-shell__footer">
        تم إنشاء النظرة العامة: {formatAdminDate(summary.generatedAt)}
      </div>
    </div>
  );
}

function DashboardOverviewStrip({ summary }: { summary: OpsDashboardSummary }) {
  const contentTotal = getWidgetValue(
    summary.contentModeration,
    (data) => data.pendingOffers + data.pendingStories,
  );

  return (
    <section className="dashboard-overview-strip" aria-label="ملخص سريع">
      <DashboardOverviewMetric
        label="طلبات تحتاج قرار"
        value={getWidgetValue(summary.topUpQueue, (data) => data.pendingCount)}
        hint="اعتماد أو رفض شحن"
        tone={getCountTone(summary.topUpQueue, (data) => data.pendingCount)}
      />
      <DashboardOverviewMetric
        label="محتوى للمراجعة"
        value={contentTotal}
        hint="عروض وقصص تنتظر"
        tone={getCountTone(
          summary.contentModeration,
          (data) => data.pendingOffers + data.pendingStories,
        )}
      />
      <DashboardOverviewMetric
        label="جهات جاهزة"
        value={getWidgetValue(
          summary.venueDirectory,
          (data) => `${data.readyVenues} من ${data.totalVenues}`,
        )}
        hint="من إجمالي الجهات"
        tone={getVenueTone(summary.venueDirectory)}
      />
      <DashboardOverviewMetric
        label="حالة المحفظة"
        value={getWidgetValue(summary.walletReadiness, (data) =>
          formatStatus(data.overallStatus),
        )}
        hint="آخر فحص للنظام"
        tone={getWalletTone(summary.walletReadiness)}
      />
    </section>
  );
}

function DashboardOverviewMetric({
  label,
  value,
  hint,
  tone,
}: {
  label: string;
  value: string | number;
  hint: string;
  tone: "success" | "warning" | "danger" | "muted";
}) {
  return (
    <div className={`dashboard-overview-metric dashboard-overview-metric--${tone}`}>
      <span className="dashboard-overview-metric__label">{label}</span>
      <strong className="dashboard-overview-metric__value">{value}</strong>
      <span className="dashboard-overview-metric__hint">{hint}</span>
    </div>
  );
}

function renderTopUpQueue(data: TopUpQueueSummary) {
  return (
    <div className="dashboard-widget-stack">
      <MetricBlock value={data.pendingCount} label="طلبات بانتظار المراجعة" />

      {data.recentPending.length > 0 ? (
        <div className="dashboard-preview">
          <h4>أحدث الطلبات</h4>
          <ul className="dashboard-preview-list">
            {data.recentPending.map((request) => (
              <li key={request.id}>
                <span>{request.userName}</span>
                <strong>{formatCurrency(request.amount, request.currency)}</strong>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      {data.pendingCount > 0 ? (
        <div className="dashboard-widget-stack__action">
          <Link href="/admin/topups" className="dashboard-inline-link">
            فتح طلبات الشحن
          </Link>
        </div>
      ) : null}
    </div>
  );
}

function renderContentModeration(data: ContentModerationBacklogSummary) {
  const total = data.pendingOffers + data.pendingStories;

  return (
    <div className="dashboard-widget-stack">
      <MetricBlock value={total} label="عناصر بانتظار المراجعة" />

      {data.recentOffersPreview.length > 0 ? (
        <div className="dashboard-preview">
          <h4>أحدث العروض</h4>
          <ul className="dashboard-preview-list">
            {data.recentOffersPreview.map((offer) => (
              <li key={offer.id}>
                <span>{offer.title}</span>
                <span className="muted-text">جهة: {offer.venueId}</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      <div className="dashboard-widget-stack__links">
        {data.pendingOffers > 0 ? (
          <Link href="/admin/content/offers" className="dashboard-inline-link">
            {data.pendingOffers} عروض
          </Link>
        ) : null}
        {data.pendingStories > 0 ? (
          <Link href="/admin/content/stories" className="dashboard-inline-link">
            {data.pendingStories} قصص
          </Link>
        ) : null}
        {total === 0 ? (
          <span className="dashboard-widget-stack__hint">
            لا توجد عناصر عالقة حاليًا.
          </span>
        ) : null}
      </div>
    </div>
  );
}

function renderWalletReadiness(data: WalletReadinessSummary) {
  const isHealthy =
    data.failingChecksCount === 0 && data.warningChecksCount === 0;

  return (
    <div className="dashboard-widget-stack">
      <MetricBlock value={formatStatus(data.overallStatus)} label="الحالة الحالية" />

      {data.failingChecksCount > 0 ? (
        <div className="dashboard-widget-stack__alert dashboard-widget-stack__alert--danger">
          {data.failingChecksCount} فحوصات فاشلة
        </div>
      ) : null}
      {data.warningChecksCount > 0 ? (
        <div className="dashboard-widget-stack__alert dashboard-widget-stack__alert--warning">
          {data.warningChecksCount} فحوصات تحتاج متابعة
        </div>
      ) : null}

      {data.failingChecksPreview.length > 0 ? (
        <div className="dashboard-preview dashboard-preview--danger">
          <h4>أبرز الأعطال</h4>
          <ul className="dashboard-preview-list dashboard-preview-list--stacked">
            {data.failingChecksPreview.map((check) => (
              <li key={check.id}>
                <strong>{check.name}</strong>
                <span>{check.message}</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      {isHealthy ? (
        <div className="dashboard-widget-stack__alert dashboard-widget-stack__alert--success">
          جميع الأنظمة تعمل بشكل طبيعي
        </div>
      ) : null}

      <div className="dashboard-widget-stack__action">
        <Link href="/admin/readiness" className="dashboard-inline-link">
          عرض تقرير الحالة الكامل
        </Link>
      </div>
    </div>
  );
}

function renderVenueDirectory(data: VenueDirectorySummary) {
  return (
    <div className="dashboard-widget-stack">
      <div className="dashboard-stats-grid">
        <DashboardStat value={data.totalVenues} label="الإجمالي" />
        <DashboardStat value={data.readyVenues} label="جاهزة" tone="success" />
        <DashboardStat
          value={data.lowBalanceVenues}
          label="رصيد منخفض"
          tone="warning"
        />
        <DashboardStat value={data.inactiveWallets} label="غير نشط" tone="muted" />
      </div>

      {data.lowBalancePreview.length > 0 ? (
        <div className="dashboard-preview">
          <h4>جهات تحتاج متابعة الرصيد</h4>
          <ul className="dashboard-preview-list">
            {data.lowBalancePreview.map((venue) => (
              <li key={venue.id}>
                <span>{venue.name}</span>
                <span className="muted-text">رقم الجهة: {venue.id}</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      <div className="dashboard-widget-stack__action">
        <Link href="/admin/venues" className="dashboard-inline-link">
          فتح الجهات
        </Link>
      </div>
    </div>
  );
}

function MetricBlock({ value, label }: { value: React.ReactNode; label: string }) {
  return (
    <div className="dashboard-metric-block">
      <div className="dashboard-widget-stack__value">{value}</div>
      <div className="dashboard-widget-stack__caption">{label}</div>
    </div>
  );
}

function DashboardStat({
  value,
  label,
  tone,
}: {
  value: number;
  label: string;
  tone?: "success" | "warning" | "muted";
}) {
  const toneClass = tone ? `dashboard-stat-card--${tone}` : "";

  return (
    <div className={["dashboard-stat-card", toneClass].filter(Boolean).join(" ")}>
      <div className="dashboard-stat-card__value">{value}</div>
      <div className="dashboard-stat-card__label">{label}</div>
    </div>
  );
}

function getWidgetValue<T>(
  widget: OpsWidgetData<T>,
  selector: (data: T) => string | number,
): string | number {
  if (widget.state === "unavailable") {
    return "غير متاح";
  }

  if (widget.state === "empty") {
    return "0";
  }

  return widget.data ? selector(widget.data) : "غير متاح";
}

function getCountTone<T>(
  widget: OpsWidgetData<T>,
  selector: (data: T) => number,
): "success" | "warning" | "danger" | "muted" {
  if (widget.state === "unavailable") {
    return "danger";
  }

  if (widget.state === "stale") {
    return "warning";
  }

  if (!widget.data) {
    return "muted";
  }

  return selector(widget.data) > 0 ? "warning" : "success";
}

function getVenueTone(
  widget: OpsWidgetData<VenueDirectorySummary>,
): "success" | "warning" | "danger" | "muted" {
  if (widget.state === "unavailable") {
    return "danger";
  }

  if (widget.state === "stale") {
    return "warning";
  }

  if (!widget.data) {
    return "muted";
  }

  return widget.data.lowBalanceVenues > 0 || widget.data.inactiveWallets > 0
    ? "warning"
    : "success";
}

function getWalletTone(
  widget: OpsWidgetData<WalletReadinessSummary>,
): "success" | "warning" | "danger" | "muted" {
  if (widget.state === "unavailable") {
    return "danger";
  }

  if (widget.state === "stale") {
    return "warning";
  }

  if (!widget.data) {
    return "muted";
  }

  if (widget.data.overallStatus === "blocked" || widget.data.failingChecksCount > 0) {
    return "danger";
  }

  return widget.data.overallStatus === "warning" || widget.data.warningChecksCount > 0
    ? "warning"
    : "success";
}
