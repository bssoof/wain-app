"use client";

import { useEffect, useMemo, useState } from "react";

import { formatCurrency } from "@/lib/finance/read-model-formatters";
import type { MerchantReversalRequest } from "@/lib/finance/read-models";
import { predictReversalPath } from "@/lib/finance/merchant-reversal-review";

import { DataTable } from "../shared/data-table";

type MerchantReversalReviewPanelProps = {
  requests: MerchantReversalRequest[];
  isLoading: boolean;
  error: string | null;
  canReview: boolean;
  onApprove: (requestId: string, adminNote?: string) => Promise<void>;
  onReject: (
    requestId: string,
    rejectionReason: string,
    adminNote?: string,
  ) => Promise<void>;
  onRefresh: () => void;
};

type ActiveReview =
  | {
      type: "approve";
      request: MerchantReversalRequest;
    }
  | {
      type: "reject";
      request: MerchantReversalRequest;
    };

export function MerchantReversalReviewPanel({
  requests,
  isLoading,
  error,
  canReview,
  onApprove,
  onReject,
  onRefresh,
}: MerchantReversalReviewPanelProps) {
  const [activeReview, setActiveReview] = useState<ActiveReview | null>(null);

  const sortedRequests = useMemo(
    () =>
      [...requests].sort(
        (a, b) => b.createdAt.toMillis() - a.createdAt.toMillis(),
      ),
    [requests],
  );

  if (isLoading) {
    return (
      <section className="card finance-queue-shell" dir="rtl" lang="ar">
        <div className="finance-section-header">
          <div className="finance-section-heading">
            <h3 className="dashboard-kpi__title">طلبات مراجعة التجار</h3>
          </div>
        </div>
        <div
          className="finance-read-inline-unavailable"
          data-testid="merchant-reversal-loading"
          role="status"
        >
          جارٍ تحميل الطلبات...
        </div>
      </section>
    );
  }

  if (error) {
    return (
      <section className="card finance-queue-shell" dir="rtl" lang="ar">
        <div className="finance-section-header">
          <div className="finance-section-heading">
            <h3 className="dashboard-kpi__title">طلبات مراجعة التجار</h3>
          </div>
          <button
            className="action-button action-button-secondary"
            onClick={onRefresh}
            type="button"
          >
            إعادة المحاولة
          </button>
        </div>
        <p className="finance-read-inline-unavailable" role="alert">
          تعذر تحميل طلبات مراجعة التجار: {error}
        </p>
      </section>
    );
  }

  if (sortedRequests.length === 0) {
    return (
      <section className="card finance-queue-shell" dir="rtl" lang="ar">
        <div className="finance-section-header">
          <div className="finance-section-heading">
            <h3 className="dashboard-kpi__title">طلبات مراجعة التجار</h3>
            <p className="muted-text">لا توجد طلبات مراجعة بانتظار النظر.</p>
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="card finance-queue-shell" dir="rtl" lang="ar">
      <div className="finance-section-header">
        <div className="finance-section-heading">
          <h3 className="dashboard-kpi__title">طلبات مراجعة التجار</h3>
          <p className="muted-text">
            راجع سبب التاجر وتفاصيل الخصم قبل اعتماد التصحيح أو رفضه.
          </p>
        </div>
        <button
          className="action-button action-button-secondary"
          onClick={onRefresh}
          type="button"
        >
          تحديث
        </button>
      </div>

      {!canReview ? (
        <p
          className="finance-read-inline-unavailable"
          data-testid="merchant-reversal-readonly-banner"
          role="status"
        >
          ليس لديك صلاحية مراجعة طلبات التجار. يمكنك قراءة الطلبات فقط.
        </p>
      ) : null}

      <DataTable<MerchantReversalRequest>
        density="compact"
        rows={sortedRequests}
        stickyHeader
        testId="merchant-reversal-review-table"
      >
        <thead>
          <tr>
            <th>التاريخ</th>
            <th>Venue</th>
            <th>الميزة</th>
            <th>المبلغ</th>
            <th>سبب التاجر</th>
            <th>ملاحظة التاجر</th>
            <th>إجراء</th>
          </tr>
        </thead>
        <tbody>
          {sortedRequests.map((request) => (
            <tr key={request.requestId}>
              <td>{formatRequestDate(request.createdAt)}</td>
              <td>
                <a href={`/admin/venues/${encodeURIComponent(request.venueId)}`}>
                  {request.venueId}
                </a>
              </td>
              <td>{formatFeatureLabel(request.originalFeatureKey)}</td>
              <td>
                <strong>{formatCurrency(request.originalAmount, request.currency)}</strong>
              </td>
              <td>
                <TruncatedText value={request.reason} />
              </td>
              <td>
                {request.merchantNote ? (
                  <TruncatedText value={request.merchantNote} />
                ) : (
                  <span className="muted-text">—</span>
                )}
              </td>
              <td>
                {canReview ? (
                  <div className="command-actions__row">
                    <button
                      aria-label={`اعتماد طلب مراجعة ${request.requestId}`}
                      className="action-button"
                      onClick={() => setActiveReview({ type: "approve", request })}
                      type="button"
                    >
                      اعتماد
                    </button>
                    <button
                      aria-label={`رفض طلب مراجعة ${request.requestId}`}
                      className="action-button action-button-secondary"
                      onClick={() => setActiveReview({ type: "reject", request })}
                      type="button"
                    >
                      رفض
                    </button>
                  </div>
                ) : (
                  <span className="muted-text">قراءة فقط</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </DataTable>

      {activeReview ? (
        <MerchantReversalReviewDialog
          activeReview={activeReview}
          onClose={() => setActiveReview(null)}
          onApprove={onApprove}
          onReject={onReject}
          onSuccess={() => {
            setActiveReview(null);
          }}
        />
      ) : null}
    </section>
  );
}

function MerchantReversalReviewDialog({
  activeReview,
  onClose,
  onApprove,
  onReject,
  onSuccess,
}: {
  activeReview: ActiveReview;
  onClose: () => void;
  onApprove: (requestId: string, adminNote?: string) => Promise<void>;
  onReject: (
    requestId: string,
    rejectionReason: string,
    adminNote?: string,
  ) => Promise<void>;
  onSuccess: () => void;
}) {
  const [adminNote, setAdminNote] = useState("");
  const [rejectionReason, setRejectionReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);
  const isApprove = activeReview.type === "approve";
  const path = predictReversalPath(activeReview.request.originalAmount);
  const canSubmitReject = rejectionReason.trim().length >= 10;
  const confirmDisabled = isSubmitting || (!isApprove && !canSubmitReject);

  useEffect(() => {
    setAdminNote("");
    setRejectionReason("");
    setModalError(null);
    setIsSubmitting(false);
  }, [activeReview.request.requestId, activeReview.type]);

  const handleSubmit = async () => {
    if (confirmDisabled) {
      return;
    }

    setIsSubmitting(true);
    setModalError(null);
    try {
      const note = adminNote.trim() || undefined;
      if (isApprove) {
        await onApprove(activeReview.request.requestId, note);
      } else {
        await onReject(
          activeReview.request.requestId,
          rejectionReason.trim(),
          note,
        );
      }
      onSuccess();
    } catch (error) {
      setModalError(
        error instanceof Error ? error.message : "تعذر تنفيذ الإجراء حاليًا.",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="review-dialog-overlay">
      <div
        aria-labelledby="merchant-reversal-review-dialog-title"
        aria-modal="true"
        className="review-dialog"
        role="dialog"
      >
        <div className="review-dialog__header">
          <h2
            className="review-dialog__title"
            id="merchant-reversal-review-dialog-title"
          >
            {isApprove ? "اعتماد طلب مراجعة" : "رفض طلب مراجعة"}
          </h2>
        </div>

        <div className="review-dialog__content">
          <div className="review-dialog__summary">
            <div className="finance-action-summary">
              <div className="finance-action-summary__item">
                <span className="muted-text">رقم الطلب</span>
                <strong>{activeReview.request.requestId}</strong>
              </div>
              <div className="finance-action-summary__item">
                <span className="muted-text">المبلغ</span>
                <strong>
                  {formatCurrency(
                    activeReview.request.originalAmount,
                    activeReview.request.currency,
                  )}
                </strong>
              </div>
              {isApprove ? (
                <div className="finance-action-summary__item">
                  <span className="muted-text">المسار المتوقع</span>
                  <strong>{path.label}</strong>
                </div>
              ) : null}
            </div>
          </div>

          {isApprove ? (
            <label className="topup-confirm-field" htmlFor="merchant-review-admin-note">
              <span>ملاحظة الأدمن (اختياري)</span>
              <textarea
                id="merchant-review-admin-note"
                onChange={(event) => setAdminNote(event.target.value)}
                rows={3}
                value={adminNote}
              />
            </label>
          ) : (
            <>
              <label
                className="topup-confirm-field"
                htmlFor="merchant-review-rejection-reason"
              >
                <span>سبب الرفض (مطلوب)</span>
                <textarea
                  id="merchant-review-rejection-reason"
                  minLength={10}
                  onChange={(event) => setRejectionReason(event.target.value)}
                  rows={3}
                  value={rejectionReason}
                />
              </label>
              <label
                className="topup-confirm-field"
                htmlFor="merchant-review-reject-admin-note"
              >
                <span>ملاحظة داخلية للأدمن (اختياري)</span>
                <textarea
                  id="merchant-review-reject-admin-note"
                  onChange={(event) => setAdminNote(event.target.value)}
                  rows={3}
                  value={adminNote}
                />
              </label>
            </>
          )}

          {modalError ? (
            <div
              aria-live="assertive"
              className="review-dialog__error"
              data-testid="merchant-reversal-modal-error"
              role="alert"
            >
              {modalError}
            </div>
          ) : null}
        </div>

        <div className="review-dialog__footer">
          <button
            aria-label="إلغاء مراجعة طلب التاجر"
            className="review-dialog__btn review-dialog__btn--cancel"
            disabled={isSubmitting}
            onClick={onClose}
            type="button"
          >
            إلغاء
          </button>
          <button
            aria-busy={isSubmitting ? "true" : "false"}
            aria-label={isApprove ? "تأكيد اعتماد طلب التاجر" : "تأكيد رفض طلب التاجر"}
            className="review-dialog__btn review-dialog__btn--confirm"
            disabled={confirmDisabled}
            onClick={() => void handleSubmit()}
            type="button"
          >
            {isSubmitting
              ? "جارٍ التنفيذ..."
              : isApprove
                ? "تأكيد الاعتماد"
                : "تأكيد الرفض"}
          </button>
        </div>
      </div>
    </div>
  );
}

function TruncatedText({ value }: { value: string }) {
  const trimmed = value.trim();
  const display = trimmed.length > 80 ? `${trimmed.slice(0, 77)}...` : trimmed;
  return <span title={trimmed}>{display}</span>;
}

function formatRequestDate(timestamp: MerchantReversalRequest["createdAt"]): string {
  const date = timestamp.toDate();
  return new Intl.DateTimeFormat("ar-PS-u-nu-latn", {
    day: "numeric",
    hour: "numeric",
    hour12: true,
    minute: "2-digit",
    month: "short",
    timeZone: "Asia/Hebron",
    year: "numeric",
  }).format(date);
}

function formatFeatureLabel(featureKey: string): string {
  switch (featureKey) {
    case "story_promotion":
      return "ترويج قصة";
    case "offer_pin":
      return "تثبيت عرض";
    default:
      return "غير معروف";
  }
}
