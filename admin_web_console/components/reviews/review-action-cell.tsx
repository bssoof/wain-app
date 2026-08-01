"use client";

import { useState } from "react";

import { formatAdminDate, localizeAdminLabel } from "@/lib/admin/admin-localization";
import {
  REVIEW_MODERATION_REASONS,
  buildReviewItemActionAffordances,
  buildReviewModerationCommandRequest,
  commandKey,
  getReviewActionStateClass,
  type ReviewModerationAction,
  type ReviewModerationItem,
  type ReviewModerationReason,
} from "@/lib/reviews";

import { useOptionalReviewCommands } from "./review-command-provider";
import { StatusBadge } from "../shared/status-badge";
import { ConfirmDialog } from "../shared/ui/confirm-dialog";

export function ReviewActionCell({
  item,
  canModerate,
}: {
  item: ReviewModerationItem;
  canModerate: boolean;
}) {
  const reviewCommands = useOptionalReviewCommands();
  const [selectedAction, setSelectedAction] = useState<ReviewModerationAction | "">("");
  const [pendingDecision, setPendingDecision] = useState<{
    action: ReviewModerationAction;
  } | null>(null);
  const [reason, setReason] = useState<ReviewModerationReason>("manual_review");
  const [note, setNote] = useState("");

  if (!canModerate || !reviewCommands) {
    return <span className="muted-text">عرض للقراءة فقط.</span>;
  }

  const runtimeByAction = {
    review_publish: reviewCommands.getRuntimeState(
      commandKey("review_publish", item.id),
    ),
    review_hide: reviewCommands.getRuntimeState(commandKey("review_hide", item.id)),
    review_escalate: reviewCommands.getRuntimeState(
      commandKey("review_escalate", item.id),
    ),
  } as const;

  const affordances = buildReviewItemActionAffordances(
    reviewCommands.session,
    item,
    runtimeByAction,
  ).filter((affordance) => affordance.visible);

  if (affordances.length === 0) {
    return <span className="muted-text">عرض للقراءة فقط.</span>;
  }

  const execute = async (action: ReviewModerationAction) => {
    const runtimeKey = commandKey(action, item.id);
    const result = await reviewCommands.runCommand(
      runtimeKey,
      action,
      buildReviewModerationCommandRequest({
        action,
        item,
        reason,
        note: note.trim() || undefined,
      }),
    );

    if (result.ok) {
      setPendingDecision(null);
      setNote("");
    }
  };

  const getDialogTitle = (action: ReviewModerationAction): string => {
    switch (action) {
      case "review_publish":
        return "تأكيد نشر المراجعة";
      case "review_hide":
        return "تأكيد إخفاء المراجعة";
      case "review_escalate":
        return "تأكيد إرسال للمراجعة";
      default:
        return "تأكيد الإجراء";
    }
  };

  const getDialogDescription = (action: ReviewModerationAction): string => {
    switch (action) {
      case "review_publish":
        return "ستظهر المراجعة للمستخدمين بعد النشر";
      case "review_hide":
        return "سيتم إخفاء المراجعة ولن تظهر للمستخدمين";
      case "review_escalate":
        return "سيتم إرسال المراجعة للمراجعة اليدوية";
      default:
        return "";
    }
  };

  const getConfirmLabel = (action: ReviewModerationAction): string => {
    switch (action) {
      case "review_publish":
        return "نشر";
      case "review_hide":
        return "إخفاء";
      case "review_escalate":
        return "إرسال للمراجعة";
      default:
        return "تأكيد";
    }
  };

  const selectedAffordance =
    affordances.find((affordance) => affordance.action === selectedAction) ??
    affordances[0];

  const selectedRuntimeKey = commandKey(selectedAffordance.action, item.id);
  const selectedRuntimeMessage =
    reviewCommands.getLastMessage(selectedRuntimeKey) ?? selectedAffordance.message;

  return (
    <div className="action-dropdown" data-testid={`review-actions-${item.id}`}>
      <label className="action-dropdown__field">
        <span className="muted-text">اختر الإجراء</span>
        <select
          className="action-dropdown__select"
          value={selectedAffordance.action}
          onChange={(event) =>
            setSelectedAction(event.target.value as ReviewModerationAction)
          }
          data-testid={`review-action-select-${item.id}`}
        >
          {affordances.map((affordance) => (
            <option key={affordance.action} value={affordance.action}>
              {affordance.label}
            </option>
          ))}
        </select>
      </label>

      <div className="action-dropdown__footer">
        <button
          type="button"
          className="action-button action-button-secondary"
          disabled={!selectedAffordance.enabled}
          aria-busy={selectedAffordance.runtimeState === "pending" ? "true" : "false"}
          onClick={() => setPendingDecision({ action: selectedAffordance.action })}
          data-testid={`review-action-run-${item.id}`}
        >
          {selectedAffordance.label}
        </button>
        <StatusBadge className={getReviewActionStateClass(selectedAffordance.runtimeState)}>
          {selectedAffordance.statusText}
        </StatusBadge>
      </div>

      {selectedRuntimeMessage ? (
        <p className="media-action-message muted-text">{selectedRuntimeMessage}</p>
      ) : null}

      <ConfirmDialog
        open={pendingDecision !== null}
        onClose={() => setPendingDecision(null)}
        onConfirm={async () => {
          if (!pendingDecision) return;
          await execute(pendingDecision.action);
        }}
        title={pendingDecision ? getDialogTitle(pendingDecision.action) : ""}
        description={pendingDecision ? getDialogDescription(pendingDecision.action) : ""}
        variant={pendingDecision?.action === "review_hide" ? "danger" : "default"}
        confirmLabel={pendingDecision ? getConfirmLabel(pendingDecision.action) : "تأكيد"}
      >
        {pendingDecision && (
          <div className="content-decision-preview">
            <div className="preview-section">
              <label className="media-center-filter-field">
                <span>سبب القرار</span>
                <select
                  value={reason}
                  onChange={(event) =>
                    setReason(event.target.value as ReviewModerationReason)
                  }
                  className="media-center-filter-select"
                >
                  {REVIEW_MODERATION_REASONS.map((key) => (
                    <option key={key} value={key}>
                      {localizeAdminLabel(key)}
                    </option>
                  ))}
                </select>
              </label>

              <label className="media-center-filter-field">
                <span>ملاحظة إضافية</span>
                <input
                  type="text"
                  className="media-center-filter-input"
                  value={note}
                  onChange={(event) => setNote(event.target.value)}
                  placeholder="ملاحظة اختيارية للفريق"
                />
              </label>
            </div>

            <div className="preview-section">
              <strong>نص المراجعة:</strong>
              <p style={{ marginTop: "0.5rem", whiteSpace: "pre-wrap" }}>{item.snippet}</p>
            </div>

            <div className="preview-meta" style={{ display: "flex", flexDirection: "column", gap: "0.25rem", fontSize: "0.875rem", color: "var(--color-text-muted, #666)" }}>
              <span>الكاتب: {item.authorName}</span>
              <span>التقييم: {item.rating} من 5</span>
              <span>الجهة: {item.venueName}</span>
              <span>التاريخ: {formatAdminDate(item.createdAt)}</span>
            </div>
          </div>
        )}
      </ConfirmDialog>
    </div>
  );
}
