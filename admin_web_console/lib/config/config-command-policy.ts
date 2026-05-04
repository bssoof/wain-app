import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  CONFIG_COMMAND_METADATA,
  createConfigCommandError,
  type ConfigCommandError,
  type ConfigCommandMetadata,
  type ConfigCommandType,
} from "./config-command-contracts";

export type ConfigCommandAuthorizationResult =
  | {
      allowed: true;
      metadata: ConfigCommandMetadata;
    }
  | {
      allowed: false;
      reason: "unauthorized" | "forbidden";
      error: ConfigCommandError;
    };

export function authorizeConfigCommand(
  session: AdminSession | null,
  command: ConfigCommandType,
): ConfigCommandAuthorizationResult {
  const metadata = CONFIG_COMMAND_METADATA[command];

  if (!session) {
    return {
      allowed: false,
      reason: "unauthorized",
      error: createConfigCommandError(
        "unauthorized",
        "Admin session is required before executing config governance commands.",
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
      error: createConfigCommandError(
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
