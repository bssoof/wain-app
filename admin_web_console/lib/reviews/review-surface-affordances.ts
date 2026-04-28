import { canRenderAction, type AdminSession } from "@/lib/auth/guard-api";

import type {
  ReviewModerationAction,
  ReviewModerationErrorCode,
} from "./review-moderation-contracts";
import type { ReviewModerationItem } from "./review-moderation-models";

export type ReviewActionRuntimeState =
  | "idle"
  | "pending"
  | "success"
  | "conflict"
  | "unavailable";

export type ReviewCommandAffordance = {
  action: ReviewModerationAction;
  label: string;
  visible: boolean;
  enabled: boolean;
  runtimeState: ReviewActionRuntimeState;
  statusText: string;
  message?: string;
};

const ACTION_LABELS: Record<ReviewModerationAction, string> = {
  review_publish: "نشر",
  review_hide: "إخفاء",
  review_escalate: "إرسال للمراجعة",
};

export function mapReviewErrorCodeToRuntimeState(
  code: ReviewModerationErrorCode,
): ReviewActionRuntimeState {
  switch (code) {
    case "conflict":
      return "conflict";
    case "unauthorized":
    case "forbidden":
    case "validation_error":
    case "unavailable":
      return "unavailable";
  }
}

export function buildReviewItemActionAffordances(
  session: AdminSession | null,
  item: ReviewModerationItem,
  runtimeByAction: Partial<Record<ReviewModerationAction, ReviewActionRuntimeState>> = {},
): ReviewCommandAffordance[] {
  const affordances: ReviewCommandAffordance[] = [
    {
      action: "review_publish",
      label: ACTION_LABELS.review_publish,
      visible: Boolean(session && canRenderAction(session, "review_publish")),
      enabled:
        item.status !== "published" &&
        runtimeByAction.review_publish !== "pending",
      runtimeState: runtimeByAction.review_publish ?? "idle",
      statusText:
        item.status === "published"
          ? "منشور بالفعل"
          : getRuntimeStateLabel(runtimeByAction.review_publish ?? "idle"),
      message:
        item.status === "published"
          ? "هذه المراجعة منشورة بالفعل."
          : undefined,
    },
    {
      action: "review_hide",
      label: ACTION_LABELS.review_hide,
      visible: Boolean(session && canRenderAction(session, "review_hide")),
      enabled:
        item.status !== "hidden" &&
        runtimeByAction.review_hide !== "pending",
      runtimeState: runtimeByAction.review_hide ?? "idle",
      statusText:
        item.status === "hidden"
          ? "مخفية بالفعل"
          : getRuntimeStateLabel(runtimeByAction.review_hide ?? "idle"),
      message:
        item.status === "hidden"
          ? "هذه المراجعة مخفية بالفعل."
          : undefined,
    },
    {
      action: "review_escalate",
      label: ACTION_LABELS.review_escalate,
      visible: Boolean(session && canRenderAction(session, "review_escalate")),
      enabled:
        item.status !== "flagged" &&
        runtimeByAction.review_escalate !== "pending",
      runtimeState: runtimeByAction.review_escalate ?? "idle",
      statusText:
        item.status === "flagged"
          ? "مرسلة للمراجعة بالفعل"
          : getRuntimeStateLabel(runtimeByAction.review_escalate ?? "idle"),
      message:
        item.status === "flagged"
          ? "هذه المراجعة مرسلة للمراجعة بالفعل."
          : undefined,
    },
  ];

  return affordances;
}

export interface ReviewSurfaceAffordances {
  canReviewPublish: boolean;
  canReviewHide: boolean;
  canReviewEscalate: boolean;
}

export function computeReviewAffordances(
  session: AdminSession | null
): ReviewSurfaceAffordances {
  if (!session) {
    return {
      canReviewPublish: false,
      canReviewHide: false,
      canReviewEscalate: false,
    };
  }
  return {
    canReviewPublish: canRenderAction(session, "review_publish"),
    canReviewHide: canRenderAction(session, "review_hide"),
    canReviewEscalate: canRenderAction(session, "review_escalate"),
  };
}

export function getReviewActionStateClass(
  state: ReviewActionRuntimeState,
): string {
  switch (state) {
    case "success":
      return "status-success";
    case "conflict":
      return "status-danger";
    case "pending":
    case "unavailable":
      return "status-warning";
    default:
      return "status-neutral";
  }
}

function getRuntimeStateLabel(state: ReviewActionRuntimeState): string {
  switch (state) {
    case "pending":
      return "قيد التنفيذ...";
    case "success":
      return "مكتمل";
    case "conflict":
      return "تعارض";
    case "unavailable":
      return "غير متاح";
    default:
      return "جاهز";
  }
}
