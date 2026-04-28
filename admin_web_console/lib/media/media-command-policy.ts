import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";
import type { AdminRole } from "@/lib/navigation/admin-contract";

import {
  MEDIA_COMMAND_METADATA,
  createMediaCommandError,
  type MediaCommandError,
  type MediaCommandMetadata,
  type MediaCommandType,
} from "./media-command-contracts";

export type MediaCommandAuthorizationResult =
  | {
      allowed: true;
      metadata: MediaCommandMetadata;
    }
  | {
      allowed: false;
      reason: "unauthorized" | "forbidden";
      error: MediaCommandError;
    };

export function authorizeMediaCommand(
  session: AdminSession | null,
  command: MediaCommandType,
): MediaCommandAuthorizationResult {
  const metadata = MEDIA_COMMAND_METADATA[command];

  if (!session) {
    return {
      allowed: false,
      reason: "unauthorized",
      error: createMediaCommandError(
        "unauthorized",
        "Admin session is required before executing media actions.",
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
      error: createMediaCommandError(
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

export function canExecuteMediaCommand(
  session: AdminSession | null,
  command: MediaCommandType,
): boolean {
  return authorizeMediaCommand(session, command).allowed;
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
