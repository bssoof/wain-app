import React from "react";
import type { OpsWidgetState, OpsWidgetData } from "@/lib/dashboard/dashboard-models";
import {
  formatAdminDate,
  localizeAdminLabel,
  localizeAdminMessage,
} from "@/lib/admin/admin-localization";

export type KpiWidgetProps<T> = {
  title: string;
  widget: OpsWidgetData<T>;
  children?: React.ReactNode;
  renderData?: (data: T) => React.ReactNode;
};

export function KpiWidget<T>({ title, widget, children, renderData }: KpiWidgetProps<T>) {
  const isUnavailable = widget.state === "unavailable";
  const isStale = widget.state === "stale";
  const isEmpty = widget.state === "empty";
  const localizedSource = localizeAdminLabel(widget.source);
  const localizedMessage = localizeAdminMessage(widget.message) ?? widget.message;

  return (
    <div
      className={[
        "dashboard-kpi",
        isUnavailable
          ? "dashboard-kpi--unavailable"
          : isStale
            ? "dashboard-kpi--stale"
            : "dashboard-kpi--success",
      ].join(" ")}
    >
      <div className="dashboard-kpi__header">
        <h3 className="dashboard-kpi__title">{title}</h3>
        <WidgetStatusBadge state={widget.state} />
      </div>

      <div className="dashboard-kpi__body">
        {isUnavailable ? (
          <div className="dashboard-kpi__message dashboard-kpi__message--danger">
            <span className="dashboard-kpi__message-title">المعلومات غير متاحة</span>
            <span>{localizedMessage || "تعذر جلب هذه البيانات."}</span>
          </div>
        ) : isEmpty ? (
          <div className="dashboard-kpi__message dashboard-kpi__message--muted">
            {localizedMessage || "لا توجد سجلات للعرض حاليًا."}
          </div>
        ) : (
          <div>
            {widget.data && renderData && renderData(widget.data)}
            {children}
          </div>
        )}
      </div>

      <div className="dashboard-kpi__meta">
        <span className="dashboard-kpi__meta-text" title={`المصدر: ${localizedSource}`}>
          المصدر: {localizedSource}
        </span>
        <span className="dashboard-kpi__meta-text" title={`حتى: ${widget.asOf}`}>
          آخر تحديث: {formatAsOf(widget.asOf)}
        </span>
      </div>

      {isStale && !isUnavailable && (
        <div className="dashboard-kpi__stale-note">
          {localizedMessage || "قد تكون البيانات قديمة."}
        </div>
      )}
    </div>
  );
}

function WidgetStatusBadge({ state }: { state: OpsWidgetState }) {
  switch (state) {
    case "success":
      return (
        <span className="dashboard-status-badge dashboard-status-badge--success" title="البيانات محدثة">
          <span className="dashboard-status-badge__dot">●</span>
          محدث
        </span>
      );
    case "stale":
      return (
        <span className="dashboard-status-badge dashboard-status-badge--stale" title="البيانات قديمة مقارنة بالوقت المتوقع">
          <span className="dashboard-status-badge__dot">○</span>
          قديم
        </span>
      );
    case "unavailable":
      return (
        <span className="dashboard-status-badge dashboard-status-badge--danger" title="تعذر جلب البيانات">
          <span className="dashboard-status-badge__dot">!</span>
          خطأ
        </span>
      );
    case "empty":
      return (
        <span className="dashboard-status-badge dashboard-status-badge--muted" title="لا توجد بيانات مطابقة">
          <span className="dashboard-status-badge__dot">-</span>
          لا بيانات
        </span>
      );
  }
}

function formatAsOf(isoDate: string): string {
  return formatAdminDate(isoDate);
}
