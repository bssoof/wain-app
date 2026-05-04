import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";
import type { VenueCommandType } from "./venue-command-contracts";
import { VENUE_COMMAND_METADATA } from "./venue-command-contracts";

export function canExecuteVenueCommand(
  session: AdminSession,
  command: VenueCommandType,
): boolean {
  const metadata = VENUE_COMMAND_METADATA[command];
  return canRenderAction(session, metadata.requiredCapability);
}

export function getVenueCommandDenialReason(
  session: AdminSession,
  command: VenueCommandType,
): string | null {
  if (canExecuteVenueCommand(session, command)) {
    return null;
  }

  const metadata = VENUE_COMMAND_METADATA[command];
  return `Role "${session.primaryRole}" is not authorized for "${command}". Required capability: "${metadata.requiredCapability}".`;
}
