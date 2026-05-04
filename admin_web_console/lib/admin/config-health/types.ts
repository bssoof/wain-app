export type CheckTier = 1 | 2 | 3;

export type CheckId =
  // Tier 1
  | "finance_functions_base_url"
  | "venue_functions_base_url"
  | "content_functions_base_url"
  | "config_functions_base_url"
  | "firebase_admin_initialized"
  // Tier 2
  | "step_up_signing_key_present"
  | "step_up_previous_key_present"
  | "step_up_enforcement_mode"
  // Tier 3
  | "session_verify_revocation"
  | "build_id"
  | "deploy_channel";

export interface CheckResult {
  id: CheckId;
  tier: CheckTier;
  label: string;
  status: "ok" | "warn" | "error" | "unknown";
  present: boolean;
  source: string;
  value?: string;
  message: string | null;
}

export interface HealthSummary {
  errorCount: number;
  warnCount: number;
  unknownCount: number;
}

export interface HealthReport {
  ok: boolean;
  checkedAt: string;
  cacheTtlSeconds: number;
  checks: CheckResult[];
  summary: HealthSummary;
  disabled?: boolean;
}
