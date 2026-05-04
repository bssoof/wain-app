import { canRenderAction, type AdminSession } from "@/lib/auth/guard-api";
import { localizeAdminLabel } from "@/lib/admin/admin-localization";

import type {
  ContentModerationAction,
  ContentModerationErrorCode,
} from "./content-command-contracts";
import type { OfferAdminItem, StoryAdminItem } from "./content-models";

// -- Surface affordances (page-level) --

export interface ContentSurfaceAffordances {
  canModerateOffers: boolean;
  canModerateStories: boolean;
  canReviewPromotions: boolean;
}

export function computeContentAffordances(
  session: AdminSession | null
): ContentSurfaceAffordances {
  if (!session) return { canModerateOffers: false, canModerateStories: false, canReviewPromotions: false };
  const isContentAdminOrSuper =
    canRenderAction(session, "offer_approve") ||
    canRenderAction(session, "story_approve");

  return {
    canModerateOffers: isContentAdminOrSuper,
    canModerateStories: isContentAdminOrSuper,
    canReviewPromotions: isContentAdminOrSuper,
  };
}

// -- Runtime state types --

export type ContentActionRuntimeState =
  | "idle"
  | "pending"
  | "success"
  | "conflict"
  | "unavailable";

export type ContentCommandAffordance = {
  action: ContentModerationAction;
  label: string;
  visible: boolean;
  enabled: boolean;
  runtimeState: ContentActionRuntimeState;
  statusText: string;
  message?: string;
};

const ACTION_LABELS: Record<ContentModerationAction, string> = {
  approve: "اعتماد",
  reject: "رفض",
  flag: "وضع علامة",
  pause: "إيقاف",
};

export function mapContentErrorCodeToRuntimeState(
  code: ContentModerationErrorCode,
): ContentActionRuntimeState {
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

// -- Per-item affordances (offer) --

export function buildOfferItemActionAffordances(
  session: AdminSession | null,
  item: OfferAdminItem,
  runtimeByAction: Partial<Record<ContentModerationAction, ContentActionRuntimeState>> = {},
): ContentCommandAffordance[] {
  return buildItemActionAffordances(session, item.adminState, runtimeByAction, "offer");
}

// -- Per-item affordances (story) --

export function buildStoryItemActionAffordances(
  session: AdminSession | null,
  item: StoryAdminItem,
  runtimeByAction: Partial<Record<ContentModerationAction, ContentActionRuntimeState>> = {},
): ContentCommandAffordance[] {
  return buildItemActionAffordances(session, item.adminState, runtimeByAction, "story");
}

// -- Shared builder --

type ContentEntityType = "offer" | "story";

const ENTITY_CAPABILITY_MAP: Record<
  ContentEntityType,
  Record<ContentModerationAction, string>
> = {
  offer: {
    approve: "offer_approve",
    reject: "offer_reject",
    flag: "offer_flag",
    pause: "offer_pause",
  },
  story: {
    approve: "story_approve",
    reject: "story_reject",
    flag: "story_flag",
    pause: "story_pause",
  },
};

const ACTION_TARGET_STATES: Record<ContentModerationAction, string> = {
  approve: "approved",
  reject: "rejected",
  flag: "flagged",
  pause: "paused",
};

function buildItemActionAffordances(
  session: AdminSession | null,
  currentState: string,
  runtimeByAction: Partial<Record<ContentModerationAction, ContentActionRuntimeState>>,
  entityType: ContentEntityType,
): ContentCommandAffordance[] {
  const actions: ContentModerationAction[] = ["approve", "reject", "flag", "pause"];
  const capabilityMap = ENTITY_CAPABILITY_MAP[entityType];

  return actions.map((action) => {
    const capabilityKey = capabilityMap[action];
    const visible = Boolean(
      session && canRenderAction(session, capabilityKey as any),
    );
    const targetState = ACTION_TARGET_STATES[action];
    const localizedTargetState = localizeAdminLabel(targetState);
    const alreadyInTargetState = currentState === targetState;
    const runtimeState = runtimeByAction[action] ?? "idle";
    const enabled = !alreadyInTargetState && runtimeState !== "pending";

    return {
      action,
      label: ACTION_LABELS[action],
      visible,
      enabled,
      runtimeState,
      statusText: alreadyInTargetState
        ? `بالحالة المطلوبة بالفعل: ${localizedTargetState}`
        : getRuntimeStateLabel(runtimeState),
      message: alreadyInTargetState
        ? `${entityType === "offer" ? "العرض" : "القصة"} بالحالة ${localizedTargetState} بالفعل.`
        : undefined,
    };
  });
}

export function getContentActionStateClass(
  state: ContentActionRuntimeState,
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

function getRuntimeStateLabel(state: ContentActionRuntimeState): string {
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
