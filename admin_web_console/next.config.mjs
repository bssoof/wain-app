import bundleAnalyzer from "@next/bundle-analyzer";
import path from "node:path";
import { fileURLToPath } from "node:url";

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === "true",
});

const adminWebRoot = path.dirname(fileURLToPath(import.meta.url));

export function buildSecurityHeaders(env = process.env) {
  const isProduction = env.NODE_ENV === "production";
  const headers = [
    {
      key: "Content-Security-Policy",
      value: buildEnforcedCsp(env),
    },
    {
      key: "Content-Security-Policy-Report-Only",
      value: buildReportOnlyCsp(env),
    },
  ];

  if (isProduction) {
    headers.push({
      key: "Strict-Transport-Security",
      value: "max-age=31536000; includeSubDomains",
    });
  }

  return [
    ...headers,
    {
      key: "Permissions-Policy",
      value:
        "camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()",
    },
    {
      key: "X-Content-Type-Options",
      value: "nosniff",
    },
    {
      key: "X-Frame-Options",
      value: "DENY",
    },
    {
      key: "Referrer-Policy",
      value: "strict-origin-when-cross-origin",
    },
    {
      key: "Cross-Origin-Opener-Policy",
      value: "same-origin",
    },
  ];
}

function buildEnforcedCsp(env = process.env) {
  const isProduction = env.NODE_ENV === "production";
  return [
    "default-src 'self'",
    "base-uri 'self'",
    "object-src 'none'",
    "frame-ancestors 'none'",
    "form-action 'self'",
    "img-src 'self' data: blob: https:",
    "font-src 'self' data: https:",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https:",
    "style-src 'self' 'unsafe-inline' https:",
    buildConnectSrcDirective(isProduction),
    ...(isProduction ? ["upgrade-insecure-requests"] : []),
  ].join("; ");
}

function buildReportOnlyCsp(env = process.env) {
  const isProduction = env.NODE_ENV === "production";
  const cspReportUri = env.WAIN_ADMIN_CSP_REPORT_URI?.trim();
  return [
    "default-src 'self'",
    "base-uri 'self'",
    "object-src 'none'",
    "frame-ancestors 'none'",
    "form-action 'self'",
    "img-src 'self' data: blob: https:",
    "font-src 'self' data: https:",
    "script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.googletagmanager.com https://www.google-analytics.com",
    "style-src 'self' https:",
    buildConnectSrcDirective(isProduction),
    ...(cspReportUri ? [`report-uri ${cspReportUri}`] : []),
  ].join("; ");
}

function buildConnectSrcDirective(isProduction) {
  const sources = ["'self'", "https:", "wss:", "ws:"];
  if (!isProduction) {
    sources.push("http://localhost:*", "ws://localhost:*");
  }
  return `connect-src ${sources.join(" ")}`;
}

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  outputFileTracingRoot: adminWebRoot,
  turbopack: {
    root: adminWebRoot,
  },
  async headers() {
    return [
      {
        source: "/:path*",
        headers: buildSecurityHeaders(process.env),
      },
    ];
  },
};

export default withBundleAnalyzer(nextConfig);
