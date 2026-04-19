import { describe, expect, it } from "vitest";

import { buildAdminSession } from "@/lib/auth/guard-api";

describe("security: missing or invalid role is denied", () => {
  it("denies session context when admin role is missing", () => {
    const session = buildAdminSession({
      uid: "admin-no-role",
      email: "admin@wain.app",
      claims: {
        admin: true,
        isAdmin: true,
      },
    });

    expect(session).toBeNull();
  });

  it("denies session context when role value is unknown", () => {
    const session = buildAdminSession({
      uid: "admin-unknown-role",
      claims: {
        admin: true,
        isAdmin: true,
        role: "root_admin",
      },
    });

    expect(session).toBeNull();
  });

  it("does not auto-upgrade to super_admin for cookie-like contexts without role", () => {
    const session = buildAdminSession({
      uid: "cookie-admin-without-role",
      claims: {
        admin: true,
        isAdmin: true,
        roles: [],
      },
    });

    expect(session).toBeNull();
  });

  it("denies fallback-only role contexts when claims role is absent", () => {
    const session = buildAdminSession({
      uid: "admin-fallback-only",
      fallback: {
        role: "super_admin",
      },
    });

    expect(session).toBeNull();
  });
});
