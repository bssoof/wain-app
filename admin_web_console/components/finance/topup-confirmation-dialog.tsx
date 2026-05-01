"use client";

import { useEffect, useRef, useState } from "react";
import type { TopUpRequest } from "@/lib/finance/read-models";
import type { FinanceCommandType } from "@/lib/finance/command-contracts";
import {
  buildApproveTopUpRequest,
  buildRejectTopUpRequest,
} from "@/lib/finance/build-command-requests";
import type { ApproveTopUpCommandRequest, RejectTopUpCommandRequest } from "@/lib/finance/command-contracts";

export type TopUpDecisionAction = "approve_topup" | "reject_topup";

export type TopUpPendingDecision = {
  action: TopUpDecisionAction;
  request: TopUpRequest;
  runtimeKey: string;
};

const APPROVE_REASONS = [
  { value: "payment_verified", label: "تم التحقق من الدفع" },
  { value: "manual_finance_review", label: "مراجعة مالية يدوية" },
  { value: "provider_reference_matched", label: "تطابق المرجع مع مزود الدفع" },
  { value: "other", label: "أخرى (يجب كتابة ملاحظة)" },
] as const;

const REJECT_REASONS = [
  { value: "payment_not_verified", label: "لم يتم التحقق من الدفع" },
  { value: "duplicate_request", label: "طلب متكرر" },
  { value: "incorrect_amount", label: "قيمة غير صحيحة" },
  { value: "provider_reference_invalid", label: "المرجع غير صحيح" },
  { value: "manual_review_failed", label: "فشل المراجعة اليدوية" },
  { value: "other", label: "أخرى (يجب كتابة ملاحظة)" },
] as const;

export function TopUpConfirmationDialog({
  decision,
  onCancel,
  onConfirmExecute,
  submissionState,
  submissionError,
}: {
  decision: TopUpPendingDecision;
  onCancel: () => void;
  onConfirmExecute: (request: ApproveTopUpCommandRequest | RejectTopUpCommandRequest) => void;
  submissionState: "idle" | "pending" | "success" | "error" | "unavailable" | "forbidden" | "conflict";
  submissionError?: string;
}) {
  const [reason, setReason] = useState("");
  const [adminNote, setAdminNote] = useState("");
  const [activeSubmittedRequest, setActiveSubmittedRequest] = useState<ApproveTopUpCommandRequest | RejectTopUpCommandRequest | null>(null);
  const [pendingStartTime, setPendingStartTime] = useState<number | null>(null);
  const [canCancelPending, setCanCancelPending] = useState(false);

  const dialogRef = useRef<HTMLDialogElement>(null);
  const isPending = submissionState === "pending";
  const isError = submissionState === "error" || submissionState === "unavailable" || submissionState === "forbidden" || submissionState === "conflict";
  const hasSubmittedOnce = activeSubmittedRequest !== null;

  // ESC to close (unless pending)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        if (!isPending) {
          onCancel();
        }
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isPending, onCancel]);

  // Trap focus (simple version for now)
  useEffect(() => {
    if (dialogRef.current) {
      dialogRef.current.focus();
    }
  }, []);

  // 10 second cancel timer
  useEffect(() => {
    if (isPending) {
      setPendingStartTime(Date.now());
      const timer = setTimeout(() => setCanCancelPending(true), 10000);
      return () => clearTimeout(timer);
    } else {
      setPendingStartTime(null);
      setCanCancelPending(false);
    }
  }, [isPending]);

  const handleConfirm = () => {
    if (activeSubmittedRequest) {
      // Retry with exactly the same payload
      onConfirmExecute(activeSubmittedRequest);
      return;
    }

    const builtRequest =
      decision.action === "approve_topup"
        ? buildApproveTopUpRequest(decision.request, { reason, adminNote })
        : buildRejectTopUpRequest(decision.request, { reason, adminNote });

    setActiveSubmittedRequest(builtRequest);
    onConfirmExecute(builtRequest);
  };

  const reasons = decision.action === "approve_topup" ? APPROVE_REASONS : REJECT_REASONS;
  const requireNote = reason === "other";
  const isValid = reason !== "" && (!requireNote || adminNote.trim().length > 0);

  const formatExpectedState = () => {
    if (decision.action === "approve_topup") {
      return `بعد التأكيد: محفظة المستخدم +${decision.request.amount} ${decision.request.currency}، حالة الطلب → مكتمل`;
    }
    return `بعد التأكيد: حالة الطلب → مرفوض، لا تغيير على المحفظة`;
  };

  return (
    <div className="topup-confirm-backdrop">
      <dialog
        ref={dialogRef}
        open
        className="topup-confirm-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="dialog-title"
        dir="rtl"
        tabIndex={-1}
      >
        <h2 id="dialog-title">
          {decision.action === "approve_topup" ? "تأكيد اعتماد الرصيد" : "تأكيد رفض الرصيد"}
        </h2>

        <div className="topup-confirm-summary">
          <p><strong>رقم الطلب:</strong> {decision.request.id}</p>
          <p><strong>المستخدم:</strong> {decision.request.userName} ({decision.request.userId})</p>
          <p><strong>المنشأة:</strong> {decision.request.venueId || "الافتراضية"}</p>
          <p><strong>القيمة:</strong> {decision.request.amount} {decision.request.currency}</p>
          <p><strong>مرجع الدفع:</strong> {decision.request.providerReference}</p>
          <p className="expected-state"><strong>النتيجة:</strong> {formatExpectedState()}</p>
        </div>

        {hasSubmittedOnce && (
          <p className="submission-note">إعادة المحاولة تستخدم نفس البيانات. إلغاء وفتح مرة ثانية لتغيير السبب.</p>
        )}

        <div className="topup-confirm-field">
          <label htmlFor="reason-select">السبب (مطلوب)</label>
          <select
            id="reason-select"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            disabled={hasSubmittedOnce || isPending}
          >
            <option value="" disabled>اختر السبب...</option>
            {reasons.map((r) => (
              <option key={r.value} value={r.value}>{r.label}</option>
            ))}
          </select>
        </div>

        <div className="topup-confirm-field">
          <label htmlFor="admin-note">ملاحظة إدارية {requireNote ? "(مطلوب)" : "(اختياري)"}</label>
          <textarea
            id="admin-note"
            value={adminNote}
            onChange={(e) => setAdminNote(e.target.value)}
            disabled={hasSubmittedOnce || isPending}
            rows={3}
          />
        </div>

        {isError && submissionError && (
          <div className="topup-confirm-error" role="alert">
            {submissionError}
          </div>
        )}

        <div className="topup-confirm-actions">
          <button
            type="button"
            className="btn-cancel"
            onClick={onCancel}
            disabled={isPending && !canCancelPending}
          >
            إلغاء {isPending && canCancelPending && "(إجهاض)"}
          </button>
          <button
            type="button"
            className="btn-confirm"
            onClick={handleConfirm}
            disabled={!isValid || isPending}
            aria-busy={isPending}
          >
            {hasSubmittedOnce && isError ? "إعادة المحاولة" : "تأكيد الإجراء"}
          </button>
        </div>
      </dialog>
    </div>
  );
}
