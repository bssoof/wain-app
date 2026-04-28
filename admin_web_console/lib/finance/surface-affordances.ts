import type { AdminSession } from "@/lib/auth/guard-api";

import {
  FINANCE_COMMAND_METADATA,
  type FinanceCommandErrorCode,
  type FinanceCommandType,
} from "./command-contracts";
import { authorizeFinanceCommand } from "./command-policy";
import type { WalletLedgerEntry } from "./read-models";

export type CommandRuntimeState = "idle" | "pending" | "unavailable" | "conflict";

export type CommandAvailability = "allowed" | "unauthorized" | "forbidden";

export type FinanceCommandAffordance = {
  command: FinanceCommandType;
  label: string;
  visible: boolean;
  enabled: boolean;
  availability: CommandAvailability;
  runtimeState: CommandRuntimeState;
  statusText: string;
  requiredCapability: (typeof FINANCE_COMMAND_METADATA)[FinanceCommandType]["requiredCapability"];
  idempotencyKeyField: "commandId";
};

const COMMAND_LABELS: Record<FinanceCommandType, string> = {
  approve_topup: "اعتماد",
  reject_topup: "رفض",
  reverse_wallet_entry: "طلب تصحيح",
  approve_reversal: "اعتماد التصحيح",
  verify_wallet_readiness: "تحديث حالة النظام",
};

export function buildFinanceCommandAffordance(
  session: AdminSession | null,
  command: FinanceCommandType,
  runtimeState: CommandRuntimeState = "idle",
): FinanceCommandAffordance {
  const metadata = FINANCE_COMMAND_METADATA[command];
  const auth = authorizeFinanceCommand(session, command);

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
          ? "يلزم تسجيل الدخول قبل تنفيذ هذا الإجراء"
          : "هذا الإجراء غير متاح لهذا الدور",
      requiredCapability: metadata.requiredCapability,
      idempotencyKeyField: metadata.idempotency.keyField,
    };
  }

  return {
    command,
    label: COMMAND_LABELS[command],
    visible: true,
    enabled: runtimeState === "idle",
    availability: "allowed",
    runtimeState,
    statusText: getRuntimeStateLabel(runtimeState),
    requiredCapability: metadata.requiredCapability,
    idempotencyKeyField: metadata.idempotency.keyField,
  };
}

export function mapErrorCodeToRuntimeState(
  code: FinanceCommandErrorCode,
): CommandRuntimeState {
  if (code === "conflict") {
    return "conflict";
  }

  if (code === "unavailable") {
    return "unavailable";
  }

  // validation_error and transport-side forbidden/unauthorized: surface explicitly (no silent idle)
  if (code === "validation_error") {
    return "unavailable";
  }

  return "unavailable";
}

export function buildTopUpActionAffordances(
  session: AdminSession | null,
  runtime: Partial<Record<"approve_topup" | "reject_topup", CommandRuntimeState>> = {},
) {
  return {
    approve: buildFinanceCommandAffordance(
      session,
      "approve_topup",
      runtime.approve_topup ?? "idle",
    ),
    reject: buildFinanceCommandAffordance(
      session,
      "reject_topup",
      runtime.reject_topup ?? "idle",
    ),
  };
}

export function buildWalletEntryReversalAffordance(
  session: AdminSession | null,
  entry: WalletLedgerEntry,
  runtimeState: CommandRuntimeState = "idle",
): FinanceCommandAffordance | null {
  if (entry.type !== "debit") {
    return null;
  }

  return buildFinanceCommandAffordance(session, "reverse_wallet_entry", runtimeState);
}

export function buildReadinessCommandAffordance(
  session: AdminSession | null,
  runtimeState: CommandRuntimeState = "idle",
): FinanceCommandAffordance {
  return buildFinanceCommandAffordance(
    session,
    "verify_wallet_readiness",
    runtimeState,
  );
}

export function buildApproveReversalCommandAffordance(
  session: AdminSession | null,
  runtimeState: CommandRuntimeState = "idle",
): FinanceCommandAffordance {
  return buildFinanceCommandAffordance(session, "approve_reversal", runtimeState);
}

function getRuntimeStateLabel(runtimeState: CommandRuntimeState): string {
  switch (runtimeState) {
    case "pending":
      return "قيد التنفيذ...";
    case "unavailable":
      return "الإجراء غير متاح حاليًا. أعد المحاولة لاحقًا.";
    case "conflict":
      return "تم اكتشاف تعارض. حدّث البيانات قبل إعادة المحاولة.";
    default:
      return "جاهز";
  }
}
