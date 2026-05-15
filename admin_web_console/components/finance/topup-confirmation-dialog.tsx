"use client";

import { useState } from "react";
import type { TopUpRequest } from "@/lib/finance/read-models";
import {
  buildApproveTopUpRequest,
  buildRejectTopUpRequest,
} from "@/lib/finance/build-command-requests";
import type { ApproveTopUpCommandRequest, RejectTopUpCommandRequest } from "@/lib/finance/command-contracts";
import { ReviewAffordanceDialog } from "../admin/review-affordance/review-affordance-dialog";
import { TopUpProofPreview } from "./topup-proof-preview";

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
  onConfirmExecute: (request: ApproveTopUpCommandRequest | RejectTopUpCommandRequest) => Promise<void> | void;
  submissionState: "idle" | "pending" | "success" | "error" | "unavailable" | "forbidden" | "conflict";
  submissionError?: string;
}) {
  const [reason, setReason] = useState("");
  const [adminNote, setAdminNote] = useState("");
  const [activeSubmittedRequest, setActiveSubmittedRequest] = useState<ApproveTopUpCommandRequest | RejectTopUpCommandRequest | null>(null);

  const hasSubmittedOnce = activeSubmittedRequest !== null;
  const isRetryable = hasSubmittedOnce && ["error", "unavailable", "forbidden", "conflict"].includes(submissionState);

  const handleConfirm = async () => {
    let builtRequest = activeSubmittedRequest;
    if (!builtRequest) {
      builtRequest =
        decision.action === "approve_topup"
          ? buildApproveTopUpRequest(decision.request, { reason, adminNote })
          : buildRejectTopUpRequest(decision.request, { reason, adminNote });
      setActiveSubmittedRequest(builtRequest);
    }

    try {
      const result = onConfirmExecute(builtRequest);
      if (result instanceof Promise) {
         await result;
      }
    } catch (err: any) {
      throw new Error(err.message || "حدث خطأ أثناء التنفيذ.");
    }
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

  const summaryContent = (
    <>
      <div className="topup-confirm-summary">
        <p><strong>رقم الطلب:</strong> {decision.request.id}</p>
        <p><strong>المستخدم:</strong> {decision.request.userName} ({decision.request.userId})</p>
        <p><strong>المنشأة:</strong> {decision.request.venueId || "الافتراضية"}</p>
        <p><strong>القيمة:</strong> {decision.request.amount} {decision.request.currency}</p>
        <p><strong>مرجع الدفع:</strong> {decision.request.providerReference}</p>
        <div className="topup-confirm-proof">
          <strong>صورة الوصل:</strong>
          <TopUpProofPreview request={decision.request} variant="dialog" />
        </div>
        <p className="expected-state"><strong>النتيجة:</strong> {formatExpectedState()}</p>
      </div>

      {hasSubmittedOnce && (
        <p className="submission-note">
          إعادة المحاولة تستخدم نفس البيانات. إلغاء وفتح مرة ثانية لتغيير السبب.
        </p>
      )}

      <div className="topup-confirm-field">
        <label htmlFor="reason-select">السبب (مطلوب)</label>
        <select
          id="reason-select"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          disabled={hasSubmittedOnce}
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
          disabled={hasSubmittedOnce}
          rows={3}
        />
      </div>
    </>
  );

  return (
    <ReviewAffordanceDialog
      isOpen={true}
      onOpenChange={(open) => {
        if (!open) onCancel();
      }}
      title={decision.action === "approve_topup" ? "تأكيد اعتماد الرصيد" : "تأكيد رفض الرصيد"}
      summaryContent={summaryContent}
      onConfirm={handleConfirm}
      isConfirmDisabled={!isValid}
      requiresStepUp={true}
      confirmLabel={isRetryable ? "إعادة المحاولة" : "تأكيد الإجراء"}
      cancelLabel="إلغاء"
    />
  );
}
