import { describe, expect, it } from "vitest";

import { evaluateAdminRequestHardening } from "./admin-request-hardening";

function decide(input: {
  pathname: string;
  rawUrl?: string;
  headers?: Record<string, string>;
}) {
  return evaluateAdminRequestHardening({
    pathname: input.pathname,
    rawUrl: input.rawUrl ?? `https://wain-admin.web.app${input.pathname}`,
    headers: new Headers(input.headers ?? {}),
  });
}

describe("admin request hardening", () => {
  it("rejects null-byte encoded paths before rendering", () => {
    expect(
      decide({
        pathname: "/admin/dashboard",
        rawUrl: "https://wain-admin.web.app/admin/%00",
      }),
    ).toEqual({
      kind: "reject",
      status: 400,
      reason: "malformed_path_encoding",
    });
  });

  it("rejects disabled server action entrypoints", () => {
    expect(
      decide({
        pathname: "/admin/media",
        headers: { "Next-Action": "uploadFile" },
      }),
    ).toEqual({
      kind: "reject",
      status: 400,
      reason: "server_actions_disabled",
    });
  });

  it("redirects direct protected RSC probes without router state", () => {
    expect(
      decide({
        pathname: "/admin/dashboard",
        headers: { RSC: "1" },
      }),
    ).toEqual({
      kind: "redirect",
      status: 307,
      location: "/admin/sign-in?next=%2Fadmin%2Fdashboard",
      reason: "anonymous_rsc_without_state_tree",
    });
  });

  it("rejects malformed router state tree probes", () => {
    expect(
      decide({
        pathname: "/admin/dashboard",
        headers: {
          RSC: "1",
          "Next-Router-State-Tree": "%5B%22%22%5D",
        },
      }),
    ).toEqual({
      kind: "reject",
      status: 400,
      reason: "malformed_router_state_tree",
    });
  });

  it("allows normal admin document requests", () => {
    expect(decide({ pathname: "/admin/dashboard" })).toEqual({ kind: "allow" });
  });

  it("allows public sign-in RSC requests", () => {
    expect(
      decide({
        pathname: "/admin/sign-in",
        headers: { RSC: "1" },
      }),
    ).toEqual({ kind: "allow" });
  });
});
