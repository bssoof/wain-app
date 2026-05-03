import { getCurrentAdminSession } from "@/lib/auth/session-server";
import { adminDb } from "@/lib/firebase/server";
import {
  checkRateLimit,
  buildRateLimitKey,
} from "@/lib/admin/config-health/rate-limit";

export type AdminReadinessPolicy = {
  endpoint: string;
  allowedRoles: string[];
  hideWhenForbidden?: boolean;
};

export async function verifyReadinessRbac(
  request: Request,
  policy: AdminReadinessPolicy,
): Promise<
  | { ok: true; user: unknown; role: string }
  | { ok: false; status: 401 | 403 | 404 | 429; body: unknown }
> {
  const session = await getCurrentAdminSession();

  if (!session) {
    return {
      ok: false,
      status: 401,
      body: { ok: false, reason: "unauthenticated" },
    };
  }

  const configDoc = await adminDb
    .collection("app_config")
    .doc("admin_console")
    .get();
  
  const rbacEnabled =
    configDoc.exists && configDoc.data()?.readinessRbacEnabled === true;

  const userRoles = session.roles || [];
  let isAllowed = false;

  if (rbacEnabled) {
    isAllowed = policy.allowedRoles.some((role) => userRoles.includes(role as any));
  } else {
    // Default fallback if feature flag is disabled
    isAllowed = userRoles.includes("super_admin");
  }

  if (!isAllowed) {
    if (rbacEnabled) {
      writeAuditLog({
        eventType: policy.hideWhenForbidden
          ? "admin_readiness_rbac_hidden"
          : "admin_readiness_rbac_forbidden",
        endpoint: policy.endpoint,
        method: request.method,
        userId: session.uid || null,
        role: userRoles[0] || "unknown",
        requiredRoles: policy.allowedRoles,
        status: policy.hideWhenForbidden ? 404 : 403,
      });
    }

    if (policy.hideWhenForbidden && rbacEnabled) {
      return {
        ok: false,
        status: 404,
        body: { ok: false, reason: "not_found" },
      };
    }

    return {
      ok: false,
      status: 403,
      body: { ok: false, reason: "forbidden" },
    };
  }

  const ip = request.headers.get("x-forwarded-for") || "unknown";
  const rateLimitKey = buildRateLimitKey
    ? buildRateLimitKey(policy.endpoint, ip)
    : ip;
  const rateLimit = checkRateLimit(rateLimitKey);

  if (!rateLimit.allowed) {
    return {
      ok: false,
      status: 429,
      body: { ok: false, status: "rate_limited", retryAt: rateLimit.retryAt },
    };
  }

  if (rbacEnabled) {
    writeAuditLog({
      eventType: "admin_readiness_rbac_allowed",
      endpoint: policy.endpoint,
      method: request.method,
      userId: session.uid || null,
      role: userRoles[0] || "unknown",
      requiredRoles: policy.allowedRoles,
      status: 200,
    });
  }

  return { ok: true, user: session, role: userRoles[0] || "unknown" };
}

function writeAuditLog(payload: Record<string, unknown>) {
  adminDb
    .collection("admin_step_up_audit_events")
    .add({
      ...payload,
      source: "readiness-rbac",
      createdAt: new Date().toISOString(),
    })
    .catch((err) => {
      console.error("Failed to write readiness RBAC audit log", err);
    });
}
