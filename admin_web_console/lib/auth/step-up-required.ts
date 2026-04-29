export const STEP_UP_COOKIE_NAME = "wain_admin_step_up";
export const STEP_UP_TTL_MS = 15 * 60 * 1000;
export const STEP_UP_ISSUE_MAX_AUTH_AGE_SECONDS = 60;

export const STEP_UP_SCOPES = {
  finance: [
    "approve_topup",
    "reject_topup",
    "reverse_wallet_entry",
    "approve_reversal",
  ],
  config: ["publish_config", "rollback_config"],
} as const;

export type StepUpScope = keyof typeof STEP_UP_SCOPES;

export function isStepUpScope(value: unknown): value is StepUpScope {
  return value === "finance" || value === "config";
}

export function isStepUpRequiredForCommand(
  scope: StepUpScope,
  command: string,
): boolean {
  return (STEP_UP_SCOPES[scope] as readonly string[]).includes(command);
}
