import { getAdminApp } from "@/lib/firebase/server";
import { resolveStepUpSigningKey } from "@/lib/auth/step-up-token";
import { getStepUpEnforcementMode } from "@/lib/auth/step-up-config";
import type { CheckResult } from "./types";

function isValidUrl(urlString: string | undefined): boolean {
  if (!urlString) return false;
  try {
    new URL(urlString.trim());
    return true;
  } catch {
    return false;
  }
}

// Tier 1
export async function checkFinanceFunctionsBaseUrl(): Promise<CheckResult> {
  const value = process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL;
  const present = !!value && value.trim().length > 0;
  const isValid = isValidUrl(value);

  return {
    id: "finance_functions_base_url",
    tier: 1,
    label: "Finance Functions Base URL",
    status: isValid ? "ok" : "error",
    present,
    source: "env",
    value: present ? value : undefined,
    message: isValid ? null : "عنوان خدمة المالية غير مُعرّف أو غير صالح",
  };
}

export async function checkVenueFunctionsBaseUrl(): Promise<CheckResult> {
  const value = process.env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL;
  const present = !!value && value.trim().length > 0;
  const isValid = isValidUrl(value);

  return {
    id: "venue_functions_base_url",
    tier: 1,
    label: "Venue Functions Base URL",
    status: isValid ? "ok" : "error",
    present,
    source: "env",
    value: present ? value : undefined,
    message: isValid ? null : "عنوان خدمة الأماكن غير مُعرّف أو غير صالح",
  };
}

export async function checkContentFunctionsBaseUrl(): Promise<CheckResult> {
  const value = process.env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL;
  const present = !!value && value.trim().length > 0;
  const isValid = isValidUrl(value);

  return {
    id: "content_functions_base_url",
    tier: 1,
    label: "Content Functions Base URL",
    status: isValid ? "ok" : "error",
    present,
    source: "env",
    value: present ? value : undefined,
    message: isValid ? null : "عنوان خدمة المحتوى غير مُعرّف أو غير صالح",
  };
}

export async function checkConfigFunctionsBaseUrl(): Promise<CheckResult> {
  const value = process.env.NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL;
  const present = !!value && value.trim().length > 0;
  const isValid = isValidUrl(value);

  return {
    id: "config_functions_base_url",
    tier: 1,
    label: "Config Functions Base URL",
    status: isValid ? "ok" : "error",
    present,
    source: "env",
    value: present ? value : undefined,
    message: isValid ? null : "عنوان خدمة الإعدادات غير مُعرّف أو غير صالح",
  };
}

export async function checkFirebaseAdminInitialized(): Promise<CheckResult> {
  let present = false;
  let status: "ok" | "error" | "unknown" = "unknown";
  
  try {
    const app = getAdminApp();
    present = !!app;
    status = present ? "ok" : "error";
  } catch (e) {
    present = false;
    status = "error";
  }

  return {
    id: "firebase_admin_initialized",
    tier: 1,
    label: "Firebase Admin SDK",
    status,
    present,
    source: "firebase-admin",
    message: status === "ok" ? null : "تعذر تهيئة Firebase Admin",
  };
}

// Tier 2
export async function checkStepUpSigningKeyPresent(): Promise<CheckResult> {
  let present = false;
  let status: "ok" | "warn" | "unknown" = "unknown";
  let message: string | null = null;

  try {
    const key = await resolveStepUpSigningKey();
    present = !!key;
    status = present ? "ok" : "warn";
    message = present ? null : "مفتاح التوقيع غير موجود";
  } catch (e) {
    status = "unknown";
    message = "تعذر الوصول إلى مدير الأسرار";
  }

  return {
    id: "step_up_signing_key_present",
    tier: 2,
    label: "Step-Up Signing Key",
    status,
    present,
    source: "secret_manager",
    message,
  };
}

export async function checkStepUpPreviousKeyPresent(): Promise<CheckResult> {
  const secretVersion = process.env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION;
  const secretResource = process.env.WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE;
  
  const present = !!(secretVersion || secretResource);

  return {
    id: "step_up_previous_key_present",
    tier: 2,
    label: "Step-Up Previous Key",
    status: present ? "ok" : "warn",
    present,
    source: "env",
    message: present ? null : "المفتاح السابق غير مُعرّف",
  };
}

export async function checkStepUpEnforcementMode(): Promise<CheckResult> {
  let mode = "unknown";
  let status: "ok" | "unknown" = "unknown";
  let message: string | null = "تعذر قراءة إعدادات Firestore";

  try {
    mode = await getStepUpEnforcementMode({ useCache: true });
    status = "ok";
    message = null;
  } catch (e) {
    // getStepUpEnforcementMode falls back, but just in case
    status = "unknown";
  }

  return {
    id: "step_up_enforcement_mode",
    tier: 2,
    label: "Step-Up Enforcement Mode",
    status,
    present: mode !== "unknown",
    source: "firestore",
    value: mode,
    message,
  };
}

// Tier 3
export async function checkSessionVerifyRevocation(): Promise<CheckResult> {
  const value = process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION || "1";
  
  return {
    id: "session_verify_revocation",
    tier: 3,
    label: "Session Verify Revocation",
    status: "ok",
    present: true,
    source: "env",
    value,
    message: null,
  };
}

export async function checkBuildId(): Promise<CheckResult> {
  const value = process.env.NEXT_BUILD_ID || process.env.__BUILD_ID__ || "unknown";
  const present = value !== "unknown";

  return {
    id: "build_id",
    tier: 3,
    label: "Build ID",
    status: "ok",
    present,
    source: "env",
    value,
    message: null,
  };
}

export async function checkDeployChannel(request?: Request): Promise<CheckResult> {
  // Prefer runtime hostname detection. Build-time env vars leak across channel
  // deploys (preview value persists into production), so hostname is more reliable.
  let value: string;
  if (request) {
    // Firebase Hosting forwards to Cloud Run via internal URLs containing "---".
    // Prefer x-forwarded-host (set by Hosting proxy) which preserves the original
    // public hostname (wain-admin.web.app or wain-admin--preview-xxx.web.app).
    const host =
      request.headers.get("x-forwarded-host") ||
      request.headers.get("host") ||
      "";
    if (host.includes("--") && !host.includes("---")) {
      // Preview channel hostname: wain-admin--preview-xxx.web.app (-- but not ---)
      value = "preview";
    } else if (host.startsWith("wain-admin.web.app") || host === "wain-admin.web.app") {
      // Production hostname: wain-admin.web.app
      value = "production";
    } else if (host.includes("---")) {
      // Internal Cloud Run forwarding URL (fh-xxx---ssrwainadmin-...). Treat as production.
      value = "production";
    } else {
      // Custom domain or unexpected; fall back to env hint
      const envChannel = process.env.WAIN_ADMIN_DEPLOY_CHANNEL;
      const isProdProject = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID === "wain-d2e28";
      value = (envChannel && envChannel !== "preview")
        ? envChannel
        : (isProdProject ? "production" : "preview");
    }
  } else {
    // No request context (background tasks, tests). Fall back to env vars.
    const envChannel = process.env.WAIN_ADMIN_DEPLOY_CHANNEL;
    const isProdProject = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID === "wain-d2e28";
    value = (envChannel && envChannel !== "preview")
      ? envChannel
      : (isProdProject ? "production" : "preview");
  }
  
  return {
    id: "deploy_channel",
    tier: 3,
    label: "Deploy Channel",
    status: "ok",
    present: true,
    source: "env",
    value,
    message: null,
  };
}
