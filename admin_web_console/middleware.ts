import { NextResponse, type NextRequest } from "next/server";

import { evaluateAdminRequestHardening } from "@/lib/auth/admin-request-hardening";

const SECURITY_HEADERS = [
  [
    "Content-Security-Policy-Report-Only",
    [
      "default-src 'self'",
      "base-uri 'self'",
      "object-src 'none'",
      "frame-ancestors 'none'",
      "form-action 'self'",
      "img-src 'self' data: blob: https:",
      "font-src 'self' data: https:",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https:",
      "style-src 'self' 'unsafe-inline' https:",
      "connect-src 'self' https: wss: ws:",
      "upgrade-insecure-requests",
    ].join("; "),
  ],
  [
    "Permissions-Policy",
    "camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()",
  ],
  ["X-Content-Type-Options", "nosniff"],
  ["X-Frame-Options", "DENY"],
  ["Referrer-Policy", "strict-origin-when-cross-origin"],
  ["Cross-Origin-Opener-Policy", "same-origin"],
] as const;

export function middleware(request: NextRequest) {
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
