import { describe, expect, it, vi } from "vitest";

import { emitAdminSecurityAudit } from "@/lib/auth/admin-security-audit";

describe("admin security audit emitter", () => {
  it("emits a structured [SECURITY_AUDIT] log record", () => {
    const logger = vi.fn();
    const now = () => new Date("2026-04-19T18:00:00.000Z");

    const record = emitAdminSecurityAudit(
      {
        source: "admin-command-proxy",
        eventType: "proxy_authorization_denied",
        reason: "Role ops_viewer is not authorized for config_publish.",
        status: 403,
        path: "/api/admin/command/config",
        command: "config_publish",
        correlationId: "corr_123",
        serviceLabel: "Config command",
        sessionUid: "uid_123",
        sessionRole: "ops_viewer",
      },
      { logger, now },
    );

    expect(record).toEqual({
      timestamp: "2026-04-19T18:00:00.000Z",
      source: "admin-command-proxy",
      eventType: "proxy_authorization_denied",
      reason: "Role ops_viewer is not authorized for config_publish.",
      status: 403,
      path: "/api/admin/command/config",
      command: "config_publish",
      correlationId: "corr_123",
      serviceLabel: "Config command",
      sessionUid: "uid_123",
      sessionRole: "ops_viewer",
    });

    expect(logger).toHaveBeenCalledTimes(1);
    const message = logger.mock.calls[0]?.[0];
    expect(typeof message).toBe("string");
    expect((message as string).startsWith("[SECURITY_AUDIT] ")).toBe(true);

    const payload = JSON.parse((message as string).slice("[SECURITY_AUDIT] ".length));
    expect(payload).toEqual(record);
  });

  it("drops undefined optional fields", () => {
    const logger = vi.fn();

    const record = emitAdminSecurityAudit(
      {
        source: "route-guards",
        eventType: "admin_route_access_denied",
        reason: "unauthenticated",
        status: 401,
        routeKey: "dashboard",
        path: " /admin/dashboard ",
        correlationId: "   ",
      },
      { logger, now: () => new Date("2026-04-19T18:00:01.000Z") },
    );

    expect(record).toEqual({
      timestamp: "2026-04-19T18:00:01.000Z",
      source: "route-guards",
      eventType: "admin_route_access_denied",
      reason: "unauthenticated",
      status: 401,
      routeKey: "dashboard",
      path: "/admin/dashboard",
    });
  });
});
