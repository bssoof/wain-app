import React from "react";
import Link from "next/link";
import { Activity, Gauge, Users, Wallet } from "lucide-react";
import type { LucideIcon } from "lucide-react";

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
import { EmptyState } from "@/components/shared/ui/empty-state";
import { PageHeader } from "@/components/shared/ui/page-header";
import { SkeletonBlock } from "@/components/shared/ui/skeleton-block";

import { KpiWidget } from "./kpi-widget";

export type OperationalDashboardShellProps = {
  summary: OpsDashboardSummary;
  loading?: boolean;
};

export function OperationalDashboardShell({
  summary,
  loading = false,
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
      <PageHeader
        title="لوحة التحكم"
        description="نظرة عامة على المنصة"
        badge={
          isOverallStale ? (
            <span className="dashboard-shell__stale-flag">
              بعض الأقسام تعتمد على بيانات قديمة.
            </span>
          ) : undefined
        }
      />

      <section className="dashboard-section" aria-label="ملخص سريع">
        <h2 className="dashboard-section__title">نظرة عامة</h2>
        <DashboardKpiGrid loading={loading} summary={summary} />
      </section>

      <section className="dashboard-section">
        <h2 className="dashboard-section__title">تفاصيل التشغيل</h2>
        <div className="dashboard-shell__grid" data-testid="dashboard-widget-grid">
          <KpiWidget
            title="طلبات الشحن"
            widget={summary.topUpQueue}
            renderData={(data) => renderTopUpQueue(data, loading)}
          />

          <KpiWidget
            title="محتوى ينتظر المراجعة"
            widget={summary.contentModeration}
            renderData={(data) => renderContentModeration(data, loading)}
          />

          <KpiWidget
            title="صحة المحفظة"
            widget={summary.walletReadiness}
            renderData={(data) => renderWalletReadiness(data, loading)}
          />

          <KpiWidget
            title="حالة الجهات"
            widget={summary.venueDirectory}
            renderData={(data) => renderVenueDirectory(data, loading)}
          />
        </div>
      </section>

      <div className="dashboard-shell__footer">
        تم إنشاء النظرة العامة: {formatAdminDate(summary.generatedAt)}
      </div>
    </div>
  );
}

function DashboardKpiGrid({
  summary,
  loading,
}: {
  summary: OpsDashboardSummary;
  loading: boolean;
}) {
  const contentTotal = getWidgetValue(
    summary.contentModeration,
    (data) => data.pendingOffers + data.pendingStories,
  );

  return (
    <div className="dashboard-kpi-grid">
      <DashboardKpiCard
        icon={Wallet}
        label="طلبات تحتاج قرار"
        value={getWidgetValue(summary.topUpQueue, (data) => data.pendingCount)}
        loading={loading}
        testId="dashboard-kpi-topups"
      />
      <DashboardKpiCard
        icon={Activity}
        label="محتوى للمراجعة"
        value={contentTotal}
        loading={loading}
        testId="dashboard-kpi-content"
      />
      <DashboardKpiCard
        icon={Users}
        label="جهات جاهزة"
        value={getWidgetValue(
          summary.venueDirectory,
          (data) => `${data.readyVenues} من ${data.totalVenues}`,
        )}
        loading={loading}
        testId="dashboard-kpi-venues"
      />
      <DashboardKpiCard
        icon={Gauge}
        label="حالة المحفظة"
        value={getWidgetValue(summary.walletReadiness, (data) =>
          formatStatus(data.overallStatus),
        )}
        loading={loading}
        testId="dashboard-kpi-wallet"
      />
    </div>
  );
}

function DashboardKpiCard({
  icon: Icon,
  label,
  value,
  loading,
  delta,
  testId,
}: {
  icon: LucideIcon;
  label: string;
  value: string | number;
  loading: boolean;
  delta?: number;
  testId: string;
}) {
  return (
    <article className="dashboard-kpi-card" data-testid={testId}>
      <header className="dashboard-kpi-card__header">
        <Icon
          aria-hidden="true"
          className="dashboard-kpi-card__icon"
          data-testid={`${testId}-icon`}
        />
        <span className="dashboard-kpi-card__label">{label}</span>
      </header>
      <div className="dashboard-kpi-card__value">
        {loading ? <SkeletonBlock height={28} variant="text" width="60%" /> : value}
      </div>
      {delta != null ? (
        <div
          className={`dashboard-kpi-card__delta dashboard-kpi-card__delta--${
            delta > 0 ? "positive" : "negative"
          }`}
        >
          {delta > 0 ? "+" : ""}
          {delta}%
        </div>
      ) : null}
    </article>
  );
}

function renderTopUpQueue(data: TopUpQueueSummary, loading: boolean) {
  return (
    <div className="dashboard-widget-stack">
      <MetricBlock value={data.pendingCount} label="طلبات بانتظار المراجعة" />

      <DashboardPreview
        empty={data.recentPending.length === 0}
        loading={loading}
        title="أحدث الطلبات"
      >
        <ul className="dashboard-preview-list">
          {data.recentPending.map((request) => (
            <li key={request.id}>
              <span>{request.userName}</span>
              <strong>{formatCurrency(request.amount, request.currency)}</strong>
            </li>
          ))}
        </ul>
      </DashboardPreview>

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

function renderContentModeration(
  data: ContentModerationBacklogSummary,
  loading: boolean,
) {
  const total = data.pendingOffers + data.pendingStories;

  return (
    <div className="dashboard-widget-stack">
      <MetricBlock value={total} label="عناصر بانتظار المراجعة" />

      <DashboardPreview
        empty={data.recentOffersPreview.length === 0}
        loading={loading}
        title="أحدث العروض"
      >
        <ul className="dashboard-preview-list">
          {data.recentOffersPreview.map((offer) => (
            <li key={offer.id}>
              <span>{offer.title}</span>
              <span className="muted-text">جهة: {offer.venueId}</span>
            </li>
          ))}
        </ul>
      </DashboardPreview>

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

function renderWalletReadiness(data: WalletReadinessSummary, loading: boolean) {
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

      {data.failingChecksPreview.length > 0 || loading ? (
        <DashboardPreview
          empty={data.failingChecksPreview.length === 0}
          loading={loading}
          tone="danger"
          title="أبرز الأعطال"
        >
          <ul className="dashboard-preview-list dashboard-preview-list--stacked">
            {data.failingChecksPreview.map((check) => (
              <li key={check.id}>
                <strong>{check.name}</strong>
                <span>{check.message}</span>
              </li>
            ))}
          </ul>
        </DashboardPreview>
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

function renderVenueDirectory(data: VenueDirectorySummary, loading: boolean) {
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

      <DashboardPreview
        empty={data.lowBalancePreview.length === 0}
        loading={loading}
        title="جهات تحتاج متابعة الرصيد"
      >
        <ul className="dashboard-preview-list">
          {data.lowBalancePreview.map((venue) => (
            <li key={venue.id}>
              <span>{venue.name}</span>
              <span className="muted-text">رقم الجهة: {venue.id}</span>
            </li>
          ))}
        </ul>
      </DashboardPreview>

      <div className="dashboard-widget-stack__action">
        <Link href="/admin/venues" className="dashboard-inline-link">
          فتح الجهات
        </Link>
      </div>
    </div>
  );
}

function DashboardPreview({
  title,
  loading,
  empty,
  tone,
  children,
}: {
  title: string;
  loading: boolean;
  empty: boolean;
  tone?: "danger";
  children: React.ReactNode;
}) {
  const toneClass = tone ? `dashboard-preview--${tone}` : "";

  return (
    <div className={["dashboard-preview", toneClass].filter(Boolean).join(" ")}>
      <h4>{title}</h4>
      {loading ? (
        <ul className="dashboard-preview-list dashboard-preview-list--stacked">
          {Array.from({ length: 5 }).map((_, index) => (
            <li key={index}>
              <SkeletonBlock height={14} variant="text" width="100%" />
            </li>
          ))}
        </ul>
      ) : empty ? (
        <EmptyState
          compact
          title="لا توجد سجلات حديثة"
          description="ستظهر هنا أحدث الأنشطة عند توفرها"
        />
      ) : (
        children
      )}
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
