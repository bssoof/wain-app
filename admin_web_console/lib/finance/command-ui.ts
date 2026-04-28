import type { CommandRuntimeState } from "./surface-affordances";

export function getCommandRuntimeStateClass(state: CommandRuntimeState): string {
  if (state === "conflict") {
    return "status-danger";
  }
  if (state === "pending" || state === "unavailable") {
    return "status-warning";
  }
  return "status-neutral";
}
