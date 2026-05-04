"use client";

import { useState } from "react";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import {
  buildOfferModerationCommandRequest,
  buildStoryModerationCommandRequest,
  offerCommandKey,
  storyCommandKey,
} from "@/lib/content/build-content-command-requests";
import {
  type ContentModerationAction,
} from "@/lib/content/content-command-contracts";
import {
  CONTENT_MODERATION_REASON_KEYS,
  CONTENT_MODERATION_REASONS,
  type ContentModerationReason,
  type OfferAdminItem,
  type StoryAdminItem,
} from "@/lib/content/content-models";
import {
  buildOfferItemActionAffordances,
  buildStoryItemActionAffordances,
  getContentActionStateClass,
} from "@/lib/content/content-surface-affordances";

import { useOptionalContentCommands } from "./content-command-provider";
import {
  ActionPanel,
  ActionPanelHeader,
  ActionPanelItem,
  ActionPanelMessage,
} from "../shared/action-panel";
import { StatusBadge } from "../shared/status-badge";

export function ContentActionCell({
  item,
  targetType,
  canModerate,
  mode = "buttons",
}: {
  item: OfferAdminItem | StoryAdminItem;
  targetType: "offer" | "story";
  canModerate: boolean;
  mode?: "buttons" | "dropdown";
}) {
  const contentCommands = useOptionalContentCommands();
  const [selectedAction, setSelectedAction] = useState<ContentModerationAction | "">("");
  const [activeAction, setActiveAction] = useState<ContentModerationAction | null>(null);
  const [reason, setReason] = useState<ContentModerationReason>("quality_standard");
  const [note, setNote] = useState("");

  if (!canModerate || !contentCommands) {
    return <span className="muted-text">عرض للقراءة فقط.</span>;
  }

  const runtimeByAction =
    targetType === "offer"
      ? {
          approve: contentCommands.getRuntimeState(
            offerCommandKey("approve", item.id),
          ),
          reject: contentCommands.getRuntimeState(
            offerCommandKey("reject", item.id),
          ),
          flag: contentCommands.getRuntimeState(offerCommandKey("flag", item.id)),
          pause: contentCommands.getRuntimeState(
            offerCommandKey("pause", item.id),
          ),
        }
      : {
          approve: contentCommands.getRuntimeState(
            storyCommandKey("approve", item.id),
          ),
          reject: contentCommands.getRuntimeState(
            storyCommandKey("reject", item.id),
          ),
          flag: contentCommands.getRuntimeState(storyCommandKey("flag", item.id)),
          pause: contentCommands.getRuntimeState(
            storyCommandKey("pause", item.id),
          ),
        };

  const affordances = (
    targetType === "offer"
      ? buildOfferItemActionAffordances(
          contentCommands.session,
          item as OfferAdminItem,
          runtimeByAction,
        )
      : buildStoryItemActionAffordances(
          contentCommands.session,
          item as StoryAdminItem,
          runtimeByAction,
        )
  ).filter((affordance) => affordance.visible);

  if (affordances.length === 0) {
    return <span className="muted-text">عرض للقراءة فقط.</span>;
  }

  const execute = async (action: ContentModerationAction) => {
    if (targetType === "offer") {
      const runtimeKey = offerCommandKey(action, item.id);
      const result = await contentCommands.runOfferCommand(
        runtimeKey,
        action,
        buildOfferModerationCommandRequest({
          action,
          item: item as OfferAdminItem,
          reason,
          note: note.trim() || undefined,
        }),
      );
      if (result.ok) {
        setActiveAction(null);
        setNote("");
      }
      return;
    }

    const runtimeKey = storyCommandKey(action, item.id);
    const result = await contentCommands.runStoryCommand(
      runtimeKey,
      action,
      buildStoryModerationCommandRequest({
        action,
        item: item as StoryAdminItem,
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
    const runtimeKey =
      targetType === "offer"
        ? offerCommandKey(activeAction, item.id)
        : storyCommandKey(activeAction, item.id);
    const runtimeState = contentCommands.getRuntimeState(runtimeKey);
    const runtimeMessage = contentCommands.getLastMessage(runtimeKey);
    const pending = runtimeState === "pending";

    return (
      <ActionPanel className="media-action-stack card">
        <strong>تأكيد الإجراء: {localizeAdminLabel(activeAction)}</strong>

        <label className="media-center-filter-field">
          <span>سبب القرار</span>
          <select
            value={reason}
            onChange={(event) =>
              setReason(event.target.value as ContentModerationReason)
            }
            className="media-center-filter-select"
            disabled={pending}
          >
            {CONTENT_MODERATION_REASON_KEYS.map((key) => (
              <option key={key} value={key}>
                {CONTENT_MODERATION_REASONS[key]}
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
          <ActionPanelMessage className="media-action-message muted-text" role="status">
            {runtimeMessage}
          </ActionPanelMessage>
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
          className={getContentActionStateClass(runtimeState)}
          testId={`content-action-state-${activeAction}-${item.id}`}
        >
          {localizeAdminLabel(runtimeState)}
        </StatusBadge>
      </ActionPanel>
    );
  }

  if (mode === "dropdown") {
    const selectedAffordance =
      affordances.find((affordance) => affordance.action === selectedAction) ??
      affordances[0];

    const selectedRuntimeKey =
      targetType === "offer"
        ? offerCommandKey(selectedAffordance.action, item.id)
        : storyCommandKey(selectedAffordance.action, item.id);

    const selectedRuntimeMessage =
      contentCommands.getLastMessage(selectedRuntimeKey) ??
      selectedAffordance.message;

    return (
      <div className="action-dropdown" data-testid={`content-actions-${item.id}`}>
        <label className="action-dropdown__field">
          <span className="muted-text">اختر الإجراء</span>
          <select
            className="action-dropdown__select"
            value={selectedAffordance.action}
            onChange={(event) =>
              setSelectedAction(event.target.value as ContentModerationAction)
            }
            data-testid={`content-action-select-${targetType}-${item.id}`}
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
            data-testid={`content-action-run-${targetType}-${item.id}`}
          >
            {selectedAffordance.label}
          </button>
          <StatusBadge
            className={getContentActionStateClass(selectedAffordance.runtimeState)}
          >
            {selectedAffordance.statusText}
          </StatusBadge>
        </div>

        {selectedRuntimeMessage ? (
          <p className="media-action-message muted-text">{selectedRuntimeMessage}</p>
        ) : null}
      </div>
    );
  }

  return (
    <ActionPanel className="media-action-stack" testId={`content-actions-${item.id}`}>
      {affordances.map((affordance) => {
        const runtimeKey =
          targetType === "offer"
            ? offerCommandKey(affordance.action, item.id)
            : storyCommandKey(affordance.action, item.id);
        const runtimeMessage =
          contentCommands.getLastMessage(runtimeKey) ?? affordance.message;

        return (
          <ActionPanelItem
            key={affordance.action}
            className="media-action-item"
            testId={`content-command-${targetType}-${affordance.action}-${item.id}`}
          >
            <ActionPanelHeader className="media-action-item__header">
              <button
                type="button"
                className="action-button action-button-secondary"
                disabled={!affordance.enabled}
                aria-busy={
                  affordance.runtimeState === "pending" ? "true" : "false"
                }
                onClick={() => setActiveAction(affordance.action)}
              >
                {affordance.label}
              </button>
              <StatusBadge
                className={getContentActionStateClass(
                  affordance.runtimeState,
                )}
              >
                {affordance.statusText}
              </StatusBadge>
            </ActionPanelHeader>
            {runtimeMessage ? (
              <ActionPanelMessage className="media-action-message muted-text">
                {runtimeMessage}
              </ActionPanelMessage>
            ) : null}
          </ActionPanelItem>
        );
      })}
    </ActionPanel>
  );
}
