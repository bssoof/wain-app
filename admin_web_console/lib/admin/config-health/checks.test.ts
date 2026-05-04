import { describe, it, expect, vi, afterEach } from "vitest";
import type { CheckResult } from "./types";

vi.mock("@/lib/firebase/server", () => ({
  getAdminApp: vi.fn().mockReturnValue({}),
}));

vi.mock("@/lib/auth/step-up-token", () => ({
  resolveStepUpSigningKey: vi.fn().mockResolvedValue(Buffer.from("mock-key")),
}));

vi.mock("@/lib/auth/step-up-config", () => ({
  getStepUpEnforcementMode: vi.fn().mockResolvedValue("enabled"),
}));

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
import { getAdminApp } from "@/lib/firebase/server";
import { resolveStepUpSigningKey } from "@/lib/auth/step-up-token";
import { getStepUpEnforcementMode } from "@/lib/auth/step-up-config";

afterEach(() => {
  vi.unstubAllEnvs();
  vi.clearAllMocks();
});

// ─── Tier 1: checkFinanceFunctionsBaseUrl ────────────────────────────────────
describe("checkFinanceFunctionsBaseUrl", () => {
  it("returns ok when a valid URL is set", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL", "https://finance.example.com");
    const r: CheckResult = await checkFinanceFunctionsBaseUrl();
    expect(r.id).toBe("finance_functions_base_url");
    expect(r.tier).toBe(1);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.value).toBe("https://finance.example.com");
    expect(r.message).toBeNull();
  });

  it("returns error when env is missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL", "");
    const r = await checkFinanceFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(false);
    expect(r.value).toBeUndefined();
    expect(r.message).toBeTruthy();
  });

  it("returns error when env is not a valid URL", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL", "not-a-url");
    const r = await checkFinanceFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(true);
    expect(r.message).toBeTruthy();
  });
});

// ─── Tier 1: checkVenueFunctionsBaseUrl ──────────────────────────────────────
describe("checkVenueFunctionsBaseUrl", () => {
  it("returns ok when a valid URL is set", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL", "https://venue.example.com");
    const r = await checkVenueFunctionsBaseUrl();
    expect(r.id).toBe("venue_functions_base_url");
    expect(r.tier).toBe(1);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.message).toBeNull();
  });

  it("returns error when env is missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL", "");
    const r = await checkVenueFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(false);
  });

  it("returns error when env is an invalid URL", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL", "://bad");
    const r = await checkVenueFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(true);
  });
});

// ─── Tier 1: checkContentFunctionsBaseUrl ────────────────────────────────────
describe("checkContentFunctionsBaseUrl", () => {
  it("returns ok when a valid URL is set", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL", "https://content.example.com");
    const r = await checkContentFunctionsBaseUrl();
    expect(r.id).toBe("content_functions_base_url");
    expect(r.tier).toBe(1);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.message).toBeNull();
  });

  it("returns error when env is missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL", "");
    const r = await checkContentFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(false);
  });
});

// ─── Tier 1: checkConfigFunctionsBaseUrl ─────────────────────────────────────
describe("checkConfigFunctionsBaseUrl", () => {
  it("returns ok when a valid URL is set", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL", "https://config.example.com");
    const r = await checkConfigFunctionsBaseUrl();
    expect(r.id).toBe("config_functions_base_url");
    expect(r.tier).toBe(1);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.message).toBeNull();
  });

  it("returns error when env is missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL", "");
    const r = await checkConfigFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(false);
  });

  it("returns error when env is an invalid URL", async () => {
    vi.stubEnv("NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL", "just words");
    const r = await checkConfigFunctionsBaseUrl();
    expect(r.status).toBe("error");
    expect(r.present).toBe(true);
  });
});

// ─── Tier 1: checkFirebaseAdminInitialized ───────────────────────────────────
describe("checkFirebaseAdminInitialized", () => {
  it("returns ok when getAdminApp returns a truthy value", async () => {
    vi.mocked(getAdminApp).mockReturnValue({} as any);
    const r = await checkFirebaseAdminInitialized();
    expect(r.id).toBe("firebase_admin_initialized");
    expect(r.tier).toBe(1);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.message).toBeNull();
  });

  it("returns error when getAdminApp returns falsy", async () => {
    vi.mocked(getAdminApp).mockReturnValue(null as any);
    const r = await checkFirebaseAdminInitialized();
    expect(r.status).toBe("error");
    expect(r.present).toBe(false);
    expect(r.message).toBeTruthy();
  });

  it("returns error (not throw) when getAdminApp throws", async () => {
    vi.mocked(getAdminApp).mockImplementation(() => {
      throw new Error("init failed");
    });
    const r = await checkFirebaseAdminInitialized();
    expect(r.status).toBe("error");
    expect(r.present).toBe(false);
    expect(r.message).toBeTruthy();
  });
});

// ─── Tier 2: checkStepUpSigningKeyPresent ────────────────────────────────────
describe("checkStepUpSigningKeyPresent", () => {
  it("returns ok when resolveStepUpSigningKey returns a key", async () => {
    vi.mocked(resolveStepUpSigningKey).mockResolvedValue(Buffer.from("real-key") as any);
    const r = await checkStepUpSigningKeyPresent();
    expect(r.id).toBe("step_up_signing_key_present");
    expect(r.tier).toBe(2);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.message).toBeNull();
  });

  it("returns warn when resolveStepUpSigningKey returns falsy", async () => {
    vi.mocked(resolveStepUpSigningKey).mockResolvedValue(null as any);
    const r = await checkStepUpSigningKeyPresent();
    expect(r.status).toBe("warn");
    expect(r.present).toBe(false);
    expect(r.message).toBeTruthy();
  });

  it("returns unknown (not throw) when resolveStepUpSigningKey throws", async () => {
    vi.mocked(resolveStepUpSigningKey).mockRejectedValue(new Error("secret manager down"));
    const r = await checkStepUpSigningKeyPresent();
    expect(r.status).toBe("unknown");
    expect(r.present).toBe(false);
    expect(r.message).toBeTruthy();
  });
});

// ─── Tier 2: checkStepUpPreviousKeyPresent ───────────────────────────────────
describe("checkStepUpPreviousKeyPresent", () => {
  it("returns ok when secret version env is set", async () => {
    vi.stubEnv("WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION", "v2");
    const r = await checkStepUpPreviousKeyPresent();
    expect(r.id).toBe("step_up_previous_key_present");
    expect(r.tier).toBe(2);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.message).toBeNull();
  });

  it("returns ok when secret resource env is set instead", async () => {
    vi.stubEnv("WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION", "");
    vi.stubEnv("WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE", "projects/x/secrets/y/versions/1");
    const r = await checkStepUpPreviousKeyPresent();
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
  });

  it("returns warn when both envs are missing", async () => {
    vi.stubEnv("WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION", "");
    vi.stubEnv("WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE", "");
    const r = await checkStepUpPreviousKeyPresent();
    expect(r.status).toBe("warn");
    expect(r.present).toBe(false);
    expect(r.message).toBeTruthy();
  });
});

// ─── Tier 2: checkStepUpEnforcementMode ──────────────────────────────────────
describe("checkStepUpEnforcementMode", () => {
  it("returns ok with mode value when getStepUpEnforcementMode succeeds", async () => {
    vi.mocked(getStepUpEnforcementMode).mockResolvedValue("enabled" as any);
    const r = await checkStepUpEnforcementMode();
    expect(r.id).toBe("step_up_enforcement_mode");
    expect(r.tier).toBe(2);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.value).toBe("enabled");
    expect(r.message).toBeNull();
  });

  it("returns unknown (not throw) when getStepUpEnforcementMode throws", async () => {
    vi.mocked(getStepUpEnforcementMode).mockRejectedValue(new Error("firestore down"));
    const r = await checkStepUpEnforcementMode();
    expect(r.status).toBe("unknown");
    expect(r.present).toBe(false);
    expect(r.message).toBeTruthy();
  });

  it("returns ok with present=true when mode is a known value", async () => {
    vi.mocked(getStepUpEnforcementMode).mockResolvedValue("disabled" as any);
    const r = await checkStepUpEnforcementMode();
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.value).toBe("disabled");
  });
});

// ─── Tier 3: checkSessionVerifyRevocation ────────────────────────────────────
describe("checkSessionVerifyRevocation", () => {
  it("returns ok with default value '1' when env is not set", async () => {
    vi.stubEnv("WAIN_ADMIN_SESSION_VERIFY_REVOCATION", "");
    const r = await checkSessionVerifyRevocation();
    expect(r.id).toBe("session_verify_revocation");
    expect(r.tier).toBe(3);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    // empty string is falsy so fallback to "1"
    expect(r.value).toBe("1");
    expect(r.message).toBeNull();
  });

  it("returns ok with custom value when env is set", async () => {
    vi.stubEnv("WAIN_ADMIN_SESSION_VERIFY_REVOCATION", "0");
    const r = await checkSessionVerifyRevocation();
    expect(r.status).toBe("ok");
    expect(r.value).toBe("0");
  });
});

// ─── Tier 3: checkBuildId ────────────────────────────────────────────────────
describe("checkBuildId", () => {
  it("returns ok with present=true when NEXT_BUILD_ID is set", async () => {
    vi.stubEnv("NEXT_BUILD_ID", "abc123");
    const r = await checkBuildId();
    expect(r.id).toBe("build_id");
    expect(r.tier).toBe(3);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.value).toBe("abc123");
    expect(r.message).toBeNull();
  });

  it("returns ok with present=false and value 'unknown' when no build env is set", async () => {
    vi.stubEnv("NEXT_BUILD_ID", "");
    vi.stubEnv("__BUILD_ID__", "");
    const r = await checkBuildId();
    expect(r.status).toBe("ok");
    expect(r.present).toBe(false);
    expect(r.value).toBe("unknown");
  });

  it("falls back to __BUILD_ID__ when NEXT_BUILD_ID is missing", async () => {
    vi.stubEnv("NEXT_BUILD_ID", "");
    vi.stubEnv("__BUILD_ID__", "fallback-id");
    const r = await checkBuildId();
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.value).toBe("fallback-id");
  });
});

// ─── Tier 3: checkDeployChannel ──────────────────────────────────────────────
describe("checkDeployChannel", () => {
  it("returns 'production' when project ID matches production", async () => {
    vi.stubEnv("WAIN_ADMIN_DEPLOY_CHANNEL", "");
    vi.stubEnv("NEXT_PUBLIC_FIREBASE_PROJECT_ID", "wain-d2e28");
    const r = await checkDeployChannel();
    expect(r.id).toBe("deploy_channel");
    expect(r.tier).toBe(3);
    expect(r.status).toBe("ok");
    expect(r.present).toBe(true);
    expect(r.value).toBe("production");
    expect(r.message).toBeNull();
  });

  it("returns 'preview' when project ID does not match production", async () => {
    vi.stubEnv("WAIN_ADMIN_DEPLOY_CHANNEL", "");
    vi.stubEnv("NEXT_PUBLIC_FIREBASE_PROJECT_ID", "wain-staging");
    const r = await checkDeployChannel();
    expect(r.status).toBe("ok");
    expect(r.value).toBe("preview");
  });

  it("uses explicit WAIN_ADMIN_DEPLOY_CHANNEL when set", async () => {
    vi.stubEnv("WAIN_ADMIN_DEPLOY_CHANNEL", "canary");
    const r = await checkDeployChannel();
    expect(r.status).toBe("ok");
    expect(r.value).toBe("canary");
  });
});
