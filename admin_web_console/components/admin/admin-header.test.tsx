import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";

import { AdminHeader } from "./admin-header";

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: vi.fn(),
  }),
}));

vi.mock("firebase/auth", () => ({
  signOut: vi.fn(),
}));

vi.mock("@/lib/firebase/client", () => ({
  auth: {
    currentUser: null,
  },
}));

function session(overrides: Partial<AdminSession> = {}): AdminSession {
  return {
    uid: "admin-1",
    displayName: "Local Admin",
    primaryRole: "super_admin",
    roles: ["super_admin"],
    roleSource: "claims",
    ...overrides,
  };
}

describe("AdminHeader", () => {
  it("localizes the local development admin display name", () => {
    render(<AdminHeader session={session()} />);

    expect(screen.getByText(/مسؤول محلي/i)).toBeTruthy();
    expect(screen.queryByText(/Local Admin/i)).toBeNull();
  });

  it("keeps email visible when no display name is available", () => {
    render(
      <AdminHeader
        session={session({
          displayName: undefined,
          email: "admin@wain.app",
        })}
      />,
    );

    expect(screen.getByText(/admin@wain.app/i)).toBeTruthy();
  });
});
