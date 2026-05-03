"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import {
  buildApproveReversalRequest,
  commandKey,
} from "@/lib/finance/build-command-requests";
import { getCommandRuntimeStateClass } from "@/lib/finance/command-ui";
import { buildApproveReversalCommandAffordance } from "@/lib/finance/surface-affordances";

import { CommandRuntimeCallout } from "./command-runtime-callout";
import { useFinanceCommands } from "./finance-command-provider";
import { StatusBadge } from "../shared/status-badge";
import { ReviewAffordanceDialog } from "../admin/review-affordance/review-affordance-dialog";
import { useStepUp } from "@/lib/auth/use-step-up";

type ApprovalOutcome = {
  reversalRequestId: string;
  executedReversalEntryId: string;
  approvedAt: string;
};

export function ReversalApprovalPanel() {
  const router = useRouter();
  const { runCommand, getRuntimeState, getLastErrorMessage, session } =
    useFinanceCommands();
  const stepUp = useStepUp({ scope: "finance" });

  const [reversalRequestId, setReversalRequestId] = useState("");
  const [inputError, setInputError] = useState<string | null>(null);
  const [outcome, setOutcome] = useState<ApprovalOutcome | null>(null);
  const [isReviewOpen, setIsReviewOpen] = useState(false);

  const runtimeKey = useMemo(
    () =>
      commandKey(
        "approve_reversal",
        reversalRequestId.trim().length > 0
          ? reversalRequestId.trim()
          : "reversal-approval",
      ),
    [reversalRequestId],
  );

  const affordance = buildApproveReversalCommandAffordance(
    session,
    getRuntimeState(runtimeKey),
  );

  const handlePreCheck = () => {
    const normalizedRequestId = reversalRequestId.trim();
    if (normalizedRequestId.length === 0) {
      setInputError("رقم طلب التصحيح مطلوب قبل الاعتماد.");
      setOutcome(null);
      return;
    }
    setInputError(null);
    setOutcome(null);
    setIsReviewOpen(true);
  };

  const onApprove = async () => {
    const normalizedRequestId = reversalRequestId.trim();
    
    // 1. Step-Up Hand-off
    const ensureResult = await stepUp.ensureStepUp("approve_reversal");
    if (!ensureResult.ok) {
       throw new Error(ensureResult.message || "مطلوب مصادقة إضافية.");
    }

    // 2. Command Execution
    const result = await runCommand(
      runtimeKey,
      "approve_reversal",
      buildApproveReversalRequest(normalizedRequestId),
    );

    if (!result.ok) {
      throw new Error(getLastErrorMessage(runtimeKey) || "حدث خطأ أثناء التنفيذ.");
    }

    setOutcome({
      reversalRequestId: result.data.reversalRequestId,
      executedReversalEntryId: result.data.executedReversalEntryId,
      approvedAt: result.data.approvedAt,
    });
  };

  return (
    <section className="card finance-action-shell" dir="rtl" lang="ar">
      <div className="finance-section-header">
        <div className="finance-section-heading">
          <h3>اعتماد تصحيح عملية</h3>
          <p className="muted-text">
            أدخل رقم طلب التصحيح ثم اعتمده إذا كان جاهزًا للموافقة الثانية.
          </p>
        </div>
        <StatusBadge className={getCommandRuntimeStateClass(affordance.runtimeState)}>
          {affordance.statusText}
        </StatusBadge>
      </div>

      <div className="finance-action-summary" data-testid="finance-reversal-summary">
        <div className="finance-action-summary__item">
          <span className="muted-text">الإجراء</span>
          <strong>اعتماد تصحيح</strong>
        </div>
        <div className="finance-action-summary__item">
          <span className="muted-text">الصلاحية المطلوبة</span>
          <strong>{localizeAdminLabel(affordance.requiredCapability)}</strong>
        </div>
        <div className="finance-action-summary__item">
          <span className="muted-text">حالة الطلب</span>
          <strong>{affordance.statusText}</strong>
        </div>
      </div>

      {affordance.visible ? (
        <div className="finance-action-form">
          <label className="finance-action-field" htmlFor="reversal-request-id-input">
            <span className="muted-text">رقم طلب التصحيح</span>
            <input
              id="reversal-request-id-input"
              className="finance-reversal-input"
              type="text"
              value={reversalRequestId}
              onChange={(event) => setReversalRequestId(event.target.value)}
              placeholder="مثال: طلب-تصحيح-001"
            />
          </label>
          {inputError ? (
            <p className="finance-read-inline-unavailable" role="alert" data-testid="finance-reversal-input-error">
              {inputError}
            </p>
          ) : null}

          <div className="command-actions__row">
            <button
              type="button"
              className="action-button"
              disabled={!affordance.enabled}
              aria-busy={
                getRuntimeState(runtimeKey) === "pending" ? "true" : "false"
              }
              onClick={handlePreCheck}
            >
              {affordance.label}
            </button>
          </div>

          <ReviewAffordanceDialog
            isOpen={isReviewOpen}
            onOpenChange={setIsReviewOpen}
            title="تأكيد طلب التصحيح"
            summaryContent={
              <div className="finance-action-summary__item">
                <span className="muted-text">معرف الطلب:</span>
                <strong>{reversalRequestId.trim()}</strong>
              </div>
            }
            onConfirm={onApprove}
            confirmLabel="تأكيد الموافقة"
            cancelLabel="تراجع"
            requiresStepUp={true}
          />

          <CommandRuntimeCallout
            state={affordance.runtimeState}
            message={getLastErrorMessage(runtimeKey)}
            onRetry={() => void onApprove()}
            onRefresh={() => router.refresh()}
          />
          {outcome ? (
            <div className="finance-action-outcome" data-testid="finance-reversal-approved-status">
              <strong>تم الاعتماد والتنفيذ.</strong>
              <span>رقم الطلب: {outcome.reversalRequestId}</span>
              <span>رقم العملية الجديدة: {outcome.executedReversalEntryId}</span>
              <span>وقت الاعتماد: {outcome.approvedAt}</span>
            </div>
          ) : null}
        </div>
      ) : (
        <span className="muted-text">لا يملك هذا الدور صلاحية اعتماد تصحيح العمليات.</span>
      )}
    </section>
  );
}
