import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("server-only", () => ({}));

import {
  clearStepUpEnforcementModeCacheForTests,
  getStepUpEnforcementMode,
  normalizeStepUpEnforcementMode,
} from "./step-up-config";

function makeDb(data: Record<string, unknown> | undefined, exists = true) {
  const get = vi.fn().mockResolvedValue({
    exists,
    data: () => data,
  });
  return {
    db: {
      collection: vi.fn(() => ({
        doc: vi.fn(() => ({
          get,
        })),
      })),
    },
    get,
  };
}

describe("step-up config", () => {
  beforeEach(() => {
    clearStepUpEnforcementModeCacheForTests();
    vi.restoreAllMocks();
  });

  it("normalizes known enforcement modes", () => {
    expect(normalizeStepUpEnforcementMode("enabled")).toBe("enabled");
    expect(normalizeStepUpEnforcementMode("log_only")).toBe("log_only");
    expect(normalizeStepUpEnforcementMode("disabled")).toBe("disabled");
  });

  it("defaults unknown or missing values to enabled", () => {
    expect(normalizeStepUpEnforcementMode("off")).toBe("enabled");
    expect(normalizeStepUpEnforcementMode(undefined)).toBe("enabled");
  });

  it("reads the enforcement mode from app_config/admin_step_up", async () => {
    const { db } = makeDb({ enforcementMode: "log_only" });

    await expect(getStepUpEnforcementMode({ db, nowMs: 1_000 })).resolves.toBe(
      "log_only",
    );

    expect(db.collection).toHaveBeenCalledWith("app_config");
  });

  it("defaults to enabled when the config document is missing", async () => {
    const { db } = makeDb(undefined, false);

    await expect(getStepUpEnforcementMode({ db, nowMs: 1_000 })).resolves.toBe(
      "enabled",
    );
  });

  it("fails safe to enabled when Firestore cannot be read", async () => {
    const error = new Error("firestore unavailable");
    const onReadError = vi.fn();
    const consoleErrorSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => undefined);
    const db = {
      collection: vi.fn(() => ({
        doc: vi.fn(() => ({
          get: vi.fn().mockRejectedValue(error),
        })),
      })),
    };

    try {
      await expect(
        getStepUpEnforcementMode({ db, nowMs: 1_000, onReadError }),
      ).resolves.toBe("enabled");
      expect(onReadError).toHaveBeenCalledWith(error);
    } finally {
      consoleErrorSpy.mockRestore();
    }
  });

  it("caches the mode for the configured ttl", async () => {
    const { db, get } = makeDb({ enforcementMode: "disabled" });

    await expect(
      getStepUpEnforcementMode({ db, nowMs: 1_000, cacheTtlMs: 60_000 }),
    ).resolves.toBe("disabled");
    await expect(
      getStepUpEnforcementMode({ db, nowMs: 2_000, cacheTtlMs: 60_000 }),
    ).resolves.toBe("disabled");

    expect(get).toHaveBeenCalledTimes(1);
  });

  it("refreshes the cache after expiry", async () => {
    const get = vi
      .fn()
      .mockResolvedValueOnce({
        exists: true,
        data: () => ({ enforcementMode: "disabled" }),
      })
      .mockResolvedValueOnce({
        exists: true,
        data: () => ({ enforcementMode: "enabled" }),
      });
    const db = {
      collection: vi.fn(() => ({
        doc: vi.fn(() => ({ get })),
      })),
    };

    await expect(
      getStepUpEnforcementMode({ db, nowMs: 1_000, cacheTtlMs: 100 }),
    ).resolves.toBe("disabled");
    await expect(
      getStepUpEnforcementMode({ db, nowMs: 1_200, cacheTtlMs: 100 }),
    ).resolves.toBe("enabled");

    expect(get).toHaveBeenCalledTimes(2);
  });
});
