import { beforeEach, describe, expect, it, vi } from "vitest";

import {
  FIXTURE_FALLBACK_DISABLED_MESSAGE_AR,
  resolveFixtureFallbackPolicy,
} from "./fixture-fallback-policy";
import {
  __resetContentModerationSnapshotCacheForTests,
  loadStoryModerationSnapshot,
} from "@/lib/content/content-read-loader";
import { loadTopUpQueueRead } from "@/lib/finance/finance-read-loader";

describe("fixture fallback policy", () => {
  beforeEach(() => {
    __resetContentModerationSnapshotCacheForTests();
  });

  it("allows fixture fallback by default in local runtime", () => {
    const policy = resolveFixtureFallbackPolicy({
      NODE_ENV: "development",
    });

    expect(policy.tier).toBe("local");
    expect(policy.allowed).toBe(true);
  });

  it("requires explicit fixture fallback flag in staging runtime", () => {
    const denied = resolveFixtureFallbackPolicy({
      NODE_ENV: "production",
      VERCEL_ENV: "preview",
    });
    const allowed = resolveFixtureFallbackPolicy({
      NODE_ENV: "production",
      VERCEL_ENV: "preview",
      WAIN_ALLOW_FIXTURE_FALLBACK: "1",
    });

    expect(denied.tier).toBe("staging");
    expect(denied.allowed).toBe(false);
    expect(allowed.allowed).toBe(true);
  });

  it("blocks fixture fallback in production even when override flag is enabled", () => {
    const policy = resolveFixtureFallbackPolicy({
      NODE_ENV: "production",
      VERCEL_ENV: "production",
      WAIN_ALLOW_FIXTURE_FALLBACK: "1",
    });

    expect(policy.tier).toBe("production");
    expect(policy.allowed).toBe(false);
  });

  it("returns unavailable content snapshot when fixture fallback is blocked in production", async () => {
    const snapshot = await loadStoryModerationSnapshot({
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      },
      now: () => new Date("2026-04-19T18:00:00.000Z"),
      invokeCallable: vi.fn().mockRejectedValue({
        status: 503,
        message: "transport unavailable",
      }),
    });

    expect(snapshot.state).toBe("unavailable");
    expect(snapshot.source).toContain("fixture_fallback_disabled");
    expect(snapshot.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
    expect(snapshot.items).toHaveLength(0);
  });

  it("returns unavailable finance read with the same fixture-fallback blocked message in production", async () => {
    vi.stubGlobal("window", {});
    const result = await loadTopUpQueueRead({
      env: {
        NODE_ENV: "production",
        VERCEL_ENV: "production",
      },
      fetchImpl: vi.fn() as unknown as typeof fetch,
    });
    vi.unstubAllGlobals();

    expect(result.kind).toBe("unavailable");
    if (result.kind === "unavailable") {
      expect(result.message).toBe(FIXTURE_FALLBACK_DISABLED_MESSAGE_AR);
      expect(result.attemptedSource).toContain("fixture_fallback_disabled");
    }
  });
});
