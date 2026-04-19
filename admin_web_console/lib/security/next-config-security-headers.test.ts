import { describe, expect, it } from "vitest";

describe("next config security headers", () => {
  it("builds CSP report-only and permissions policy headers", async () => {
    // @ts-expect-error next.config.mjs is an untyped ESM config module.
    const module = (await import("../../next.config.mjs")) as {
      buildSecurityHeaders: (env?: Record<string, string | undefined>) => Array<{
        key: string;
        value: string;
      }>;
    };

    const headers = module.buildSecurityHeaders({ NODE_ENV: "development" });

    const csp = headers.find(
      (header) => header.key === "Content-Security-Policy-Report-Only",
    );
    const permissionsPolicy = headers.find(
      (header) => header.key === "Permissions-Policy",
    );

    expect(csp).toBeTruthy();
    expect(csp?.value).toContain("default-src 'self'");
    expect(csp?.value).toContain("frame-ancestors 'none'");

    expect(permissionsPolicy).toBeTruthy();
    expect(permissionsPolicy?.value).toContain("camera=()");
    expect(permissionsPolicy?.value).toContain("microphone=()");
  });

  it("adds report-uri and upgrade-insecure-requests in production", async () => {
    // @ts-expect-error next.config.mjs is an untyped ESM config module.
    const module = (await import("../../next.config.mjs")) as {
      buildSecurityHeaders: (env?: Record<string, string | undefined>) => Array<{
        key: string;
        value: string;
      }>;
    };

    const headers = module.buildSecurityHeaders({
      NODE_ENV: "production",
      WAIN_ADMIN_CSP_REPORT_URI: "https://csp.example.com/report",
    });

    const csp = headers.find(
      (header) => header.key === "Content-Security-Policy-Report-Only",
    );

    expect(csp?.value).toContain("upgrade-insecure-requests");
    expect(csp?.value).toContain("report-uri https://csp.example.com/report");
  });
});
