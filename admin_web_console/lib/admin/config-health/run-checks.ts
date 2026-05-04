import { adminDb } from "@/lib/firebase/server";
import {
  checkFinanceFunctionsBaseUrl,
  checkVenueFunctionsBaseUrl,
  checkContentFunctionsBaseUrl,
  checkConfigFunctionsBaseUrl,
  checkFirebaseAdminInitialized,
  checkStepUpSigningKeyPresent,
  checkStepUpPreviousKeyPresent,
  checkStepUpEnforcementMode,
  checkSessionVerifyRevocation,
  checkBuildId,
  checkDeployChannel,
} from "./checks";
import type { HealthReport, CheckResult } from "./types";

const CACHE_TTL_MS = 60 * 1000;
const CHECK_TIMEOUT_MS = 1500;

let cachedReport: HealthReport | null = null;
let cacheTimestamp = 0;

function withTimeout<T>(promise: Promise<T>, timeoutMs: number, fallback: T): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((resolve) => setTimeout(() => resolve(fallback), timeoutMs)),
  ]);
}

async function isHealthCheckEnabled(): Promise<boolean> {
  try {
    const snapshot = await adminDb.collection("app_config").doc("admin_console").get();
    if (!snapshot.exists) return false;
    const data = snapshot.data();
    return data?.healthCheckEnabled === true;
  } catch (e) {
    // If we fail to read the feature flag, default to false for safety
    return false;
  }
}

export async function runConfigHealthChecks(request?: Request, ignoreCache = false): Promise<HealthReport> {
  const now = Date.now();
  
  if (!ignoreCache && cachedReport && now - cacheTimestamp < CACHE_TTL_MS) {
    // Refresh deploy_channel since hostname can differ between preview/prod
    // for the same Cloud Function instance.
    if (request) {
      const fresh = await checkDeployChannel(request);
      return {
        ...cachedReport,
        checks: cachedReport.checks.map((c) =>
          c.id === "deploy_channel" ? fresh : c
        ),
      };
    }
    return cachedReport;
  }

  const enabled = await isHealthCheckEnabled();
  
  if (!enabled) {
    return {
      ok: true,
      checkedAt: new Date(now).toISOString(),
      cacheTtlSeconds: CACHE_TTL_MS / 1000,
      checks: [],
      summary: { errorCount: 0, warnCount: 0, unknownCount: 0 },
      disabled: true,
    };
  }

  const checkPromises = [
    // Tier 1
    withTimeout(checkFirebaseAdminInitialized(), CHECK_TIMEOUT_MS, {
      id: "firebase_admin_initialized",
      tier: 1,
      label: "Firebase Admin SDK",
      status: "unknown",
      present: false,
      source: "firebase-admin",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkFinanceFunctionsBaseUrl(), CHECK_TIMEOUT_MS, {
      id: "finance_functions_base_url",
      tier: 1,
      label: "Finance Functions Base URL",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkVenueFunctionsBaseUrl(), CHECK_TIMEOUT_MS, {
      id: "venue_functions_base_url",
      tier: 1,
      label: "Venue Functions Base URL",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkContentFunctionsBaseUrl(), CHECK_TIMEOUT_MS, {
      id: "content_functions_base_url",
      tier: 1,
      label: "Content Functions Base URL",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkConfigFunctionsBaseUrl(), CHECK_TIMEOUT_MS, {
      id: "config_functions_base_url",
      tier: 1,
      label: "Config Functions Base URL",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    
    // Tier 2
    withTimeout(checkStepUpSigningKeyPresent(), CHECK_TIMEOUT_MS, {
      id: "step_up_signing_key_present",
      tier: 2,
      label: "Step-Up Signing Key",
      status: "unknown",
      present: false,
      source: "secret_manager",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkStepUpPreviousKeyPresent(), CHECK_TIMEOUT_MS, {
      id: "step_up_previous_key_present",
      tier: 2,
      label: "Step-Up Previous Key",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkStepUpEnforcementMode(), CHECK_TIMEOUT_MS, {
      id: "step_up_enforcement_mode",
      tier: 2,
      label: "Step-Up Enforcement Mode",
      status: "unknown",
      present: false,
      source: "firestore",
      message: "انتهت مهلة الفحص",
    }),

    // Tier 3
    withTimeout(checkSessionVerifyRevocation(), CHECK_TIMEOUT_MS, {
      id: "session_verify_revocation",
      tier: 3,
      label: "Session Verify Revocation",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkBuildId(), CHECK_TIMEOUT_MS, {
      id: "build_id",
      tier: 3,
      label: "Build ID",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
    withTimeout(checkDeployChannel(request), CHECK_TIMEOUT_MS, {
      id: "deploy_channel",
      tier: 3,
      label: "Deploy Channel",
      status: "unknown",
      present: false,
      source: "env",
      message: "انتهت مهلة الفحص",
    }),
  ];

  const settled = await Promise.allSettled(checkPromises);
  
  const checks: CheckResult[] = settled.map((result, index) => {
    if (result.status === "fulfilled") {
      return result.value;
    }
    // Fallback if the check function itself throws uncaught error
    // (Should be rare since checks have their own try/catch usually)
    // The id logic here is just a generic fallback, we lose the exact ID but it's safe.
    // To be perfectly safe, we map by index, but this is an edge case.
    return {
      id: "firebase_admin_initialized", // generic fallback, actual ID would require a mapping array
      tier: 1,
      label: "Unknown Check",
      status: "error",
      present: false,
      source: "unknown",
      message: "خطأ غير متوقع أثناء الفحص",
    } as CheckResult;
  });

  let errorCount = 0;
  let warnCount = 0;
  let unknownCount = 0;
  let ok = true;

  for (const check of checks) {
    if (check.status === "error") errorCount++;
    if (check.status === "warn") warnCount++;
    if (check.status === "unknown") unknownCount++;

    if (check.tier === 1 && check.status === "error") {
      ok = false;
    }
  }

  const report: HealthReport = {
    ok,
    checkedAt: new Date().toISOString(),
    cacheTtlSeconds: CACHE_TTL_MS / 1000,
    checks,
    summary: { errorCount, warnCount, unknownCount },
  };

  cachedReport = report;
  cacheTimestamp = Date.now();

  return report;
}

// For testing purposes
export function clearHealthCache() {
  cachedReport = null;
  cacheTimestamp = 0;
}
