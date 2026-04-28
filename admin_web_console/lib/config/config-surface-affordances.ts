import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";

import type { ConfigCommandErrorCode } from "./config-command-contracts";

export type ConfigCommandRuntimeState =
  | "idle"
  | "pending"
  | "success"
  | "conflict"
  | "unavailable"
  | "blocked";

export type ConfigSurfaceAffordances = {
  canView: boolean;
  canDraft: boolean;
  canReview: boolean;
  canPublish: boolean;
  canRollback: boolean;
};

export function computeConfigAffordances(
  session: AdminSession | null,
): ConfigSurfaceAffordances {
  if (!session) {
    return {
      canView: false,
      canDraft: false,
      canReview: false,
      canPublish: false,
      canRollback: false,
    };
  }

  return {
    canView: canRenderAction(session, "view_config_governance"),
    canDraft: canRenderAction(session, "config_draft_write"),
    canReview: canRenderAction(session, "config_review"),
    canPublish: canRenderAction(session, "publish_config"),
    canRollback: canRenderAction(session, "rollback_config"),
  };
}

export function mapConfigErrorCodeToRuntimeState(
  code: ConfigCommandErrorCode,
): ConfigCommandRuntimeState {
  if (code === "conflict") {
    return "conflict";
  }

  if (code === "unauthorized" || code === "forbidden") {
    return "blocked";
  }

  return "unavailable";
}

export function getConfigActionStateClass(state: ConfigCommandRuntimeState): string {
  switch (state) {
    case "success":
      return "status-success";
    case "conflict":
      return "status-danger";
    case "pending":
    case "unavailable":
    case "blocked":
      return "status-warning";
    default:
      return "status-neutral";
  }
}
