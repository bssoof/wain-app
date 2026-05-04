"use client";

import type { CommandRuntimeState } from "@/lib/finance/surface-affordances";

type CommandRuntimeCalloutProps = {
  state: CommandRuntimeState;
  message?: string;
  onRetry: () => void;
  onRefresh: () => void;
};

export function CommandRuntimeCallout({
  state,
  message,
  onRetry,
  onRefresh,
}: CommandRuntimeCalloutProps) {
  if (state !== "conflict" && state !== "unavailable") {
    return null;
  }

  const isConflict = state === "conflict";

  return (
    <div
      className="command-runtime-callout"
      role="alert"
      data-testid="finance-command-runtime-callout"
      data-runtime-state={state}
    >
      <p className="command-runtime-callout__title">
        {isConflict ? "يوجد تعارض مع حالة البيانات الحالية" : "تعذر تنفيذ الإجراء"}
      </p>
      {message ? <p className="muted-text">{message}</p> : null}
      <p className="muted-text">
        {isConflict
          ? "حدّث الصفحة أولًا لتحميل أحدث البيانات، ثم أعد المحاولة."
          : "تحقق من الاتصال وحالة الخدمة ثم أعد المحاولة. إذا استمرت المشكلة فتواصل مع فريق التشغيل."}
      </p>
      <div className="command-runtime-callout__actions">
        <button type="button" className="action-button action-button-secondary" onClick={onRefresh}>
          تحديث
        </button>
        <button type="button" className="action-button" onClick={onRetry}>
          إعادة المحاولة
        </button>
      </div>
    </div>
  );
}
