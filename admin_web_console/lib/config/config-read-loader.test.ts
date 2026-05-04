import { beforeEach, describe, expect, it, vi } from "vitest";

import { createConfigCallableInvokerFromEnv } from "./config-callable-env";
import { FIXTURE_FALLBACK_DISABLED_MESSAGE_AR } from "@/lib/admin/fixture-fallback-policy";
import {
  __resetConfigGovernanceSnapshotCacheForTests,
  loadConfigGovernanceSnapshot,
} from "./config-read-loader";

vi.mock("./config-callable-env", () => ({
  createConfigCallableInvokerFromEnv: vi.fn(),
}));

const FIXED_NOW = new Date("2026-04-16T09:00:00.000Z");
const createConfigCallableInvokerFromEnvMock = vi.mocked(
  createConfigCallableInvokerFromEnv,
);

function buildCallablePayload() {
  return {
    generatedAt: FIXED_NOW.toISOString(),
    scope: "wallet_feature_pricing/default",
    live: {
      exists: true,
      version: 12,
      pricing: {
        story_promote_1d: 2,
        story_promote_3d: 5,
        story_promote_7d: 9,
        offer_pin_1d: 3,
        offer_pin_3d: 6,
        offer_pin_7d: 10,
        currency: "JOD",
      },
      updatedAt: FIXED_NOW.toISOString(),
      updatedByUid: "admin-uid",
      updatedByRole: "super_admin",
    },
    draft: {
      exists: false,
      status: "none",
      draftVersion: 0,
      pricing: null,
      validationIssues: [],
      reviewedByUid: null,
      reviewedAt: null,
      updatedAt: null,
    },
    history: [],
  };
}

describe("config-read-loader", () => {
  beforeEach(() => {
    __resetConfigGovernanceSnapshotCacheForTests();
    createConfigCallableInvokerFromEnvMock.mockReset();
  });

  it("reuses shared config snapshot when cache is explicitly enabled", async () => {
    const invokeCallable = vi.fn().mockResolvedValue(buildCallablePayload());
    createConfigCallableInvokerFromEnvMock.mockReturnValue({
      ok: true,
      invokeCallable,
    } as any);

    const env = {
      WAIN_CONFIG_SHARED_CACHE: "1",
      WAIN_CONFIG_SHARED_CACHE_TTL_MS: "60000",
    };

    const first = await loadConfigGovernanceSnapshot({
      env,
      now: () => new Date("2026-04-16T09:00:00.000Z"),
    });
    const second = await loadConfigGovernanceSnapshot({
      env,
      now: () => new Date("2026-04-16T09:10:00.000Z"),
    });

    expect(first.source).toBe("callable:getAdminConfigGovernanceBundle");
    expect(second.source).toBe("callable:getAdminConfigGovernanceBundle");
    expect(first.state).toBe("success");
    expect(second.state).toBe("success");
    expect(invokeCallable).toHaveBeenCalledTimes(1);
  });

  it("does not reuse shared config snapshot when cache is disabled", async () => {
    const invokeCallable = vi.fn().mockResolvedValue(buildCallablePayload());
    createConfigCallableInvokerFromEnvMock.mockReturnValue({
      ok: true,
      invokeCallable,
    } as any);

    const env = {
      WAIN_CONFIG_SHARED_CACHE: "0",
    };

    await loadConfigGovernanceSnapshot({
      env,
      now: () => new Date("2026-04-16T09:00:00.000Z"),
    });
    await loadConfigGovernanceSnapshot({
      env,
      now: () => new Date("2026-04-16T09:10:00.000Z"),
    });

    expect(invokeCallable).toHaveBeenCalledTimes(2);
  });

  it("returns unavailable state when fixture fallback is blocked in production", async () => {
    createConfigCallableInvokerFromEnvMock.mockReturnValue({
      ok: false,
    } as any);

    vi.stubGlobal("window", {});
    const snapshot = await loadConfigGovernanceSnapshot({
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      },
      now: () => FIXED_NOW,
    });
    vi.unstubAllGlobals();

    expect(snapshot.state).toBe("unavailable");
    expect(snapshot.source).toContain("fixture_fallback_disabled");
    expect(snapshot.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
  });
});
