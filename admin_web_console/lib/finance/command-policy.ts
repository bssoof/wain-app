import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  FINANCE_COMMAND_METADATA,
  createFinanceCommandError,
  type FinanceCommandError,
  type FinanceCommandMetadata,
  type FinanceCommandType,
} from "./command-contracts";

export type FinanceCommandAuthorizationResult =
  | {
      allowed: true;
      metadata: FinanceCommandMetadata;
    }
  | {
      allowed: false;
      reason: "unauthorized" | "forbidden";
      error: FinanceCommandError;
    };

export function isRoleAllowedForCommand(
  role: AdminRole,
  command: FinanceCommandType,
): boolean {
  return FINANCE_COMMAND_METADATA[command].allowedRoles.includes(role);
}

export function canExecuteFinanceCommand(
  session: AdminSession | null,
  command: FinanceCommandType,
): boolean {
  return authorizeFinanceCommand(session, command).allowed;
}

export function authorizeFinanceCommand(
  session: AdminSession | null,
  command: FinanceCommandType,
): FinanceCommandAuthorizationResult {
  const metadata = FINANCE_COMMAND_METADATA[command];

  if (!session) {
    return {
      allowed: false,
      reason: "unauthorized",
      error: createFinanceCommandError(
        "unauthorized",
        "Admin session is required before executing finance commands.",
      ),
    };
  }

  const hasAllowedRole = getSessionRoles(session).some((role) =>
    metadata.allowedRoles.includes(role),
  );

  if (!hasAllowedRole || !canRenderAction(session, metadata.requiredCapability)) {
    return {
      allowed: false,
      reason: "forbidden",
      error: createFinanceCommandError(
        "forbidden",
        `Command ${command} is not allowed for the current admin session.`,
      ),
    };
  }

  return {
    allowed: true,
    metadata,
  };
}

function getSessionRoles(session: AdminSession): AdminRole[] {
  const output: AdminRole[] = [];
  const candidates: AdminRole[] = [session.primaryRole, ...session.roles];

  for (const role of candidates) {
    if (!output.includes(role)) {
      output.push(role);
    }
  }

  return output;
}
