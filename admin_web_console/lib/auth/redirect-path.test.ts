import { describe, expect, it } from "vitest";

import {
  normalizeAdminNextPath,
  resolveAdminNextPath,
  resolveAdminNextPathFromCandidates,
} from "./redirect-path";

describe("redirect-path", () => {
  it("accepts admin relative paths", () => {
    expect(normalizeAdminNextPath("/admin/dashboard")).toBe("/admin/dashboard");
    expect(normalizeAdminNextPath("/admin/media?tab=quarantine")).toBe(
      "/admin/media?tab=quarantine",
    );
  });

  it("rejects unsafe or non-admin paths", () => {
    expect(normalizeAdminNextPath("//evil.example/path")).toBeNull();
    expect(normalizeAdminNextPath("/profile")).toBeNull();
    expect(normalizeAdminNextPath("javascript:alert(1)")).toBeNull();
  });

  it("normalizes absolute URLs into local admin paths", () => {
    expect(
      normalizeAdminNextPath("https://wain.app/admin/config?tab=versions"),
    ).toBe("/admin/config?tab=versions");
  });

  it("returns fallback when value is invalid", () => {
    expect(resolveAdminNextPath("/not-admin", "/admin/dashboard")).toBe(
      "/admin/dashboard",
    );
  });

  it("selects first valid admin candidate", () => {
    const resolved = resolveAdminNextPathFromCandidates(
      [null, "", "/login", "/admin/venues?city=ramallah", "/admin/media"],
      "/admin",
    );

    expect(resolved).toBe("/admin/venues?city=ramallah");
  });
});