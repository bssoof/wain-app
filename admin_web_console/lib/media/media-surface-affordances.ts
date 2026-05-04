import type { AdminSession } from "@/lib/auth/guard-api";

import {
  MEDIA_COMMAND_METADATA,
  type MediaCommandErrorCode,
  type MediaCommandType,
} from "./media-command-contracts";
import { authorizeMediaCommand } from "./media-command-policy";
import type {
  MediaCenterItem,
  MediaCenterSection,
} from "./media-center-models";

export type MediaActionRuntimeState =
  | "idle"
  | "pending"
  | "success"
  | "conflict"
  | "unavailable"
  | "blocked";

export type MediaActionAvailability =
  | "allowed"
  | "unauthorized"
  | "forbidden"
  | "blocked";

export type MediaCommandAffordance = {
  command: MediaCommandType;
  label: string;
  visible: boolean;
  enabled: boolean;
  availability: MediaActionAvailability;
  runtimeState: MediaActionRuntimeState;
  statusText: string;
  requiredCapability: (typeof MEDIA_COMMAND_METADATA)[MediaCommandType]["requiredCapability"];
  message?: string;
};

const COMMAND_LABELS: Record<MediaCommandType, string> = {
  media_soft_delete: "إخفاء من القائمة",
  media_quarantine: "عزل الملف",
  media_reference_check: "فحص الارتباط",
  media_purge: "حذف نهائي",
};

export function buildMediaCommandAffordance(
  session: AdminSession | null,
  command: MediaCommandType,
  runtimeState: MediaActionRuntimeState = "idle",
  blockedReason?: string,
): MediaCommandAffordance {
  const metadata = MEDIA_COMMAND_METADATA[command];
  const auth = authorizeMediaCommand(session, command);

  if (!auth.allowed) {
    return {
      command,
      label: COMMAND_LABELS[command],
      visible: false,
      enabled: false,
      availability: auth.reason,
      runtimeState,
      statusText:
        auth.reason === "unauthorized"
          ? "يجب تسجيل الدخول قبل تنفيذ هذا الإجراء"
          : "غير متاح لهذا الدور",
      requiredCapability: metadata.requiredCapability,
      message: auth.error.message,
    };
  }

  if (blockedReason) {
    return {
      command,
      label: COMMAND_LABELS[command],
      visible: true,
      enabled: false,
      availability: "blocked",
      runtimeState: "blocked",
      statusText: "محظور",
      requiredCapability: metadata.requiredCapability,
      message: blockedReason,
    };
  }

  return {
    command,
    label: COMMAND_LABELS[command],
    visible: true,
    enabled: runtimeState !== "pending",
    availability: "allowed",
    runtimeState,
    statusText: getRuntimeStateLabel(runtimeState),
    requiredCapability: metadata.requiredCapability,
  };
}

export function buildMediaItemActionAffordances(
  session: AdminSession | null,
  item: MediaCenterItem,
  section: MediaCenterSection,
  runtimeByCommand: Partial<Record<MediaCommandType, MediaActionRuntimeState>> = {},
) {
  const purgeBlockedReason = getPurgeBlockedReason(item, section);

  return {
    referenceCheck: buildMediaCommandAffordance(
      session,
      "media_reference_check",
      runtimeByCommand.media_reference_check ?? "idle",
    ),
    softDelete: buildMediaCommandAffordance(
      session,
      "media_soft_delete",
      runtimeByCommand.media_soft_delete ?? "idle",
    ),
    quarantine: buildMediaCommandAffordance(
      session,
      "media_quarantine",
      runtimeByCommand.media_quarantine ?? "idle",
    ),
    purge: buildMediaCommandAffordance(
      session,
      "media_purge",
      runtimeByCommand.media_purge ?? "idle",
      purgeBlockedReason,
    ),
  };
}

export function mapMediaErrorCodeToRuntimeState(
  code: MediaCommandErrorCode,
): MediaActionRuntimeState {
  if (code === "conflict") {
    return "conflict";
  }

  if (code === "unavailable" || code === "validation_error") {
    return "unavailable";
  }

  return "unavailable";
}

export function getMediaActionStateClass(state: MediaActionRuntimeState): string {
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

function getRuntimeStateLabel(state: MediaActionRuntimeState): string {
  switch (state) {
    case "pending":
      return "قيد التنفيذ...";
    case "success":
      return "مكتمل";
    case "conflict":
      return "تعارض";
    case "unavailable":
      return "غير متاح";
    case "blocked":
      return "محظور";
    default:
      return "جاهز";
  }
}

function getPurgeBlockedReason(
  item: MediaCenterItem,
  section: MediaCenterSection,
): string | undefined {
  if (section.purgeBlocked) {
    return "الحذف النهائي محظور لأن ارتباط الملفات يحتاج مراجعة.";
  }

  if (item.purgeBlocked || item.referenceSafety !== "safe") {
    return "الحذف النهائي محظور حتى يصبح ارتباط الملف واضحًا وآمنًا.";
  }

  return undefined;
}
