import { describe, expect, it } from "vitest";

type SecurityHeader = {
  key: string;
  value: string;
};

async function loadNextConfigSecurityHeaders(
  env: Record<string, string | undefined>,
): Promise<SecurityHeader[]> {
  // @ts-expect-error next.config.mjs is an untyped ESM config module.
  const module = (await import("../../next.config.mjs")) as {
    buildSecurityHeaders: (
      env?: Record<string, string | undefined>,
    ) => SecurityHeader[];
  };

  return module.buildSecurityHeaders(env);
}

function byKey(headers: SecurityHeader[], key: string): string | undefined {
  return headers.find((header) => header.key === key)?.value;
}

describe("next config security headers", () => {
  it("builds an enforced CSP baseline and parallel report-only policy", async () => {
    const headers = await loadNextConfigSecurityHeaders({
      NODE_ENV: "production",
      WAIN_ADMIN_CSP_REPORT_URI: "https://csp.example.com/report",
    });

    const enforced = byKey(headers, "Content-Security-Policy");
    const reportOnly = byKey(headers, "Content-Security-Policy-Report-Only");

    expect(enforced).toContain("default-src 'self'");
    expect(enforced).toContain("frame-ancestors 'none'");
    expect(enforced).toContain("object-src 'none'");
    expect(enforced).toContain("script-src 'self' 'unsafe-inline' 'unsafe-eval' https:");
    expect(enforced).toContain("upgrade-insecure-requests");

    expect(reportOnly).toContain("default-src 'self'");
    expect(reportOnly).toContain("frame-ancestors 'none'");
    expect(reportOnly).toContain("object-src 'none'");
    expect(reportOnly).toContain("report-uri https://csp.example.com/report");
    expect(reportOnly).not.toContain("unsafe-eval");
    expect(reportOnly).not.toContain("style-src 'self' 'unsafe-inline'");
    expect(reportOnly).not.toContain("upgrade-insecure-requests");
  });

  it("adds production-only HSTS and omits HSTS in development", async () => {
    const productionHeaders = await loadNextConfigSecurityHeaders({
      NODE_ENV: "production",
    });
    const developmentHeaders = await loadNextConfigSecurityHeaders({
      NODE_ENV: "development",
    });

    expect(byKey(productionHeaders, "Strict-Transport-Security")).toBe(
      "max-age=31536000; includeSubDomains",
    );
    expect(byKey(developmentHeaders, "Strict-Transport-Security")).toBeUndefined();
  });

  it("allows localhost websocket/http connect sources only in development", async () => {
    const productionHeaders = await loadNextConfigSecurityHeaders({
      NODE_ENV: "production",
    });
    const developmentHeaders = await loadNextConfigSecurityHeaders({
      NODE_ENV: "development",
    });

    expect(byKey(productionHeaders, "Content-Security-Policy")).not.toContain(
      "http://localhost:*",
    );
    expect(byKey(developmentHeaders, "Content-Security-Policy")).toContain(
      "http://localhost:*",
    );
    expect(byKey(developmentHeaders, "Content-Security-Policy")).toContain(
      "ws://localhost:*",
    );
  });

  it("keeps proxy headers aligned with next config headers", async () => {
    const { buildProxySecurityHeaders } = await import("../../proxy");
    const env = {
      NODE_ENV: "production",
      WAIN_ADMIN_CSP_REPORT_URI: "https://csp.example.com/report",
    };

    const nextHeaders = await loadNextConfigSecurityHeaders(env);
    const proxyHeaders = buildProxySecurityHeaders(env).map(
      ([key, value]) => ({ key, value }),
    );

    expect(byKey(proxyHeaders, "Content-Security-Policy")).toBe(
      byKey(nextHeaders, "Content-Security-Policy"),
    );
    expect(byKey(proxyHeaders, "Content-Security-Policy-Report-Only")).toBe(
      byKey(nextHeaders, "Content-Security-Policy-Report-Only"),
    );
    expect(byKey(proxyHeaders, "Strict-Transport-Security")).toBe(
      byKey(nextHeaders, "Strict-Transport-Security"),
    );
  });

  it("keeps firebase hosting headers on the same production baseline", async () => {
    const { readFile } = await import("node:fs/promises");
    const { fileURLToPath } = await import("node:url");
    const { dirname, resolve } = await import("node:path");
    const testDir = dirname(fileURLToPath(import.meta.url));
    const firebaseConfig = JSON.parse(
      await readFile(resolve(testDir, "../../../firebase.json"), "utf8"),
    ) as {
      hosting?: Array<{
        site?: string;
        headers?: Array<{
          source: string;
          headers: SecurityHeader[];
        }>;
      }>;
    };

    const adminHosting = firebaseConfig.hosting?.find(
      (hosting) => hosting.site === "wain-admin",
    );
    const headers = adminHosting?.headers?.[0]?.headers ?? [];
    const enforced = byKey(headers, "Content-Security-Policy");
    const reportOnly = byKey(headers, "Content-Security-Policy-Report-Only");

    expect(enforced).toContain("upgrade-insecure-requests");
    expect(reportOnly).toBeTruthy();
    expect(reportOnly).not.toContain("upgrade-insecure-requests");
    expect(byKey(headers, "Strict-Transport-Security")).toBe(
      "max-age=31536000; includeSubDomains",
    );
  });
});
