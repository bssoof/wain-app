"use client";

import { useState } from "react";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";
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

export function ReviewActionCell({
  item,
  canModerate,
}: {
  item: ReviewModerationItem;
  canModerate: boolean;
}) {
  const reviewCommands = useOptionalReviewCommands();
  const [selectedAction, setSelectedAction] = useState<ReviewModerationAction | "">("");
  const [activeAction, setActiveAction] = useState<ReviewModerationAction | null>(null);
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
      setActiveAction(null);
      setNote("");
    }
  };

  if (activeAction) {
    const runtimeKey = commandKey(activeAction, item.id);
    const runtimeState = reviewCommands.getRuntimeState(runtimeKey);
    const runtimeMessage = reviewCommands.getLastMessage(runtimeKey);
    const pending = runtimeState === "pending";

    return (
      <div
        className="media-action-stack card"
        data-testid={`review-command-${activeAction}-${item.id}`}
      >
        <strong>تأكيد القرار: {localizeAdminLabel(activeAction)}</strong>

        <label className="media-center-filter-field">
          <span>سبب القرار</span>
          <select
            value={reason}
            onChange={(event) =>
              setReason(event.target.value as ReviewModerationReason)
            }
            className="media-center-filter-select"
            disabled={pending}
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
            disabled={pending}
            placeholder="ملاحظة اختيارية للفريق"
          />
        </label>

        {runtimeMessage ? (
          <p className="media-action-message muted-text" role="status">
            {runtimeMessage}
          </p>
        ) : null}

        <div className="media-center-filter-row">
          <button
            className="action-button"
            onClick={() => void execute(activeAction)}
            disabled={pending}
          >
            {pending ? "جارٍ الحفظ..." : "تأكيد القرار"}
          </button>
          <button
            className="action-button action-button-secondary"
            onClick={() => setActiveAction(null)}
            disabled={pending}
          >
            إلغاء
          </button>
        </div>
        <StatusBadge
          className={getReviewActionStateClass(runtimeState)}
          testId={`review-action-state-${activeAction}-${item.id}`}
        >
          {localizeAdminLabel(runtimeState)}
        </StatusBadge>
      </div>
    );
  }

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
          onClick={() => setActiveAction(selectedAffordance.action)}
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
    </div>
  );
}
