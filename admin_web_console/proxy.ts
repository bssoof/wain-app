import { NextResponse, type NextRequest } from "next/server";

import { evaluateAdminRequestHardening } from "@/lib/auth/admin-request-hardening";

type HeaderEnv = Record<string, string | undefined>;
type SecurityHeader = readonly [string, string];

export function buildProxySecurityHeaders(
  env: HeaderEnv = process.env,
): SecurityHeader[] {
  const isProduction = env.NODE_ENV === "production";
  const headers: SecurityHeader[] = [
    ["Content-Security-Policy", buildEnforcedCsp(env)],
    ["Content-Security-Policy-Report-Only", buildReportOnlyCsp(env)],
  ];

  if (isProduction) {
    headers.push([
      "Strict-Transport-Security",
      "max-age=31536000; includeSubDomains",
    ]);
  }

  return [
    ...headers,
    [
      "Permissions-Policy",
      "camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()",
    ],
    ["X-Content-Type-Options", "nosniff"],
    ["X-Frame-Options", "DENY"],
    ["Referrer-Policy", "strict-origin-when-cross-origin"],
    ["Cross-Origin-Opener-Policy", "same-origin"],
  ];
}

function buildEnforcedCsp(env: HeaderEnv): string {
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

function buildReportOnlyCsp(env: HeaderEnv): string {
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

function buildConnectSrcDirective(isProduction: boolean): string {
  const sources = ["'self'", "https:", "wss:", "ws:"];
  if (!isProduction) {
    sources.push("http://localhost:*", "ws://localhost:*");
  }
  return `connect-src ${sources.join(" ")}`;
}

const SECURITY_HEADERS = buildProxySecurityHeaders();

export function proxy(request: NextRequest) {
  const decision = evaluateAdminRequestHardening({
    pathname: request.nextUrl.pathname,
    rawUrl: request.url,
    headers: request.headers,
  });

  if (decision.kind === "redirect") {
    const response = NextResponse.redirect(
      new URL(decision.location, request.url),
      decision.status,
    );
    applySecurityHeaders(response);
    return response;
  }

  if (decision.kind === "reject") {
    const response = new NextResponse("Bad Request", { status: decision.status });
    applySecurityHeaders(response);
    return response;
  }

  const response = NextResponse.next();
  applySecurityHeaders(response);
  return response;
}

function applySecurityHeaders(response: NextResponse): void {
  for (const [key, value] of SECURITY_HEADERS) {
    response.headers.set(key, value);
  }
}

export const config = {
  matcher: ["/:path*"],
};
