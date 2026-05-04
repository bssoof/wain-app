# AWC-QA-010 — Readiness Verify RBAC

## 1. Goal and scope

AWC-QA-010 standardizes RBAC enforcement for Admin Web Console readiness and health endpoints. The goal is to ensure that every admin readiness endpoint uses an explicit authorization policy, returns consistent denial responses, and records structured audit information when access is denied.

In scope:
- `/api/admin/health/config`
- `/api/admin/step-up/health`
- `/api/admin/step-up/banner`
- Any future `/api/admin/**/health` or readiness endpoint

Out of scope:
- Changing Firebase security rules
- Changing public user-facing APIs
- Changing non-admin dashboard routes
- Deploying or enabling new infrastructure

## 2. Current state

| Endpoint | File path | Current guard | Gaps |
|---|---|---|---|
| `/api/admin/health/config` | `admin_web_console/app/api/admin/health/config/route.ts` | Endpoint-local authentication and admin role checks | RBAC policy is implemented locally rather than through a shared readiness guard |
| `/api/admin/step-up/health` | `admin_web_console/app/api/admin/step-up/health/route.ts` | Endpoint-local health/auth logic if file exists | Needs confirmation and alignment with shared RBAC policy |
| `/api/admin/step-up/banner` | `admin_web_console/app/api/admin/step-up/banner/route.ts` | Endpoint-local banner/auth logic | Needs explicit documented role policy and consistent denial behavior |

## 3. Design

Introduce a shared readiness RBAC helper for admin health/readiness routes.

Proposed helper shape:

```ts
type AdminReadinessPolicy = {
  endpoint: string;
  allowedRoles: string[];
  hideWhenForbidden?: boolean;
};

async function requireAdminReadinessAccess(
  request: Request,
  policy: AdminReadinessPolicy,
): Promise<
  | { ok: true; user: unknown; role: string }
  | { ok: false; status: 401 | 403 | 404; body: unknown }
>;

Response shapes should be consistent:

Unauthenticated:

{ "ok": false, "reason": "unauthenticated" }

Forbidden:

{ "ok": false, "reason": "forbidden" }

Hidden/not found:

{ "ok": false, "reason": "not_found" }

The helper should allow each endpoint to define its own role policy, but the default policy for sensitive readiness endpoints should be super_admin only.

4. Audit logging

Every denial should emit a structured audit event. The log should avoid secrets, tokens, cookies, raw headers, or stack traces.

Suggested event types:

admin_readiness_rbac_unauthenticated
admin_readiness_rbac_forbidden
admin_readiness_rbac_hidden
admin_readiness_rbac_allowed

Suggested event keys:

{
  "eventType": "admin_readiness_rbac_forbidden",
  "endpoint": "/api/admin/health/config",
  "method": "GET",
  "userId": "firebase-uid-or-null",
  "role": "admin",
  "requiredRoles": ["super_admin"],
  "status": 403,
  "requestId": "request-id-if-available",
  "createdAt": "server timestamp"
}

If the codebase already has a Firestore audit collection, the implementation should reuse it. If no existing collection is found, the implementation should document the collection name before writing code.

5. Rate limiting

AWC-QA-010 should not bypass endpoint rate limits. RBAC should be evaluated in a predictable order with rate-limit behavior documented per endpoint.

Recommended order:

Parse request and basic method checks.
Authenticate caller.
Apply RBAC policy.
Apply endpoint-specific rate limits if the endpoint currently does so.
Run readiness checks.

For /api/admin/health/config, reuse the existing AWC-QA-002 config-health rate-limit behavior rather than creating a new independent limiter.

6. Backward compatibility

UI clients such as admin banners and dashboard readiness cards must handle:

401 unauthenticated
403 forbidden
404 not_found
429 rate_limited
500 internal_error

The banner UI should avoid showing raw server errors. It should show a safe admin-facing message and preserve existing behavior when the readiness endpoint is unavailable.

7. Test plan

Route-level tests:

Unauthenticated request returns 401 with { ok: false, reason: "unauthenticated" }.
Authenticated user without required role returns 403.
Optional hidden endpoint policy returns 404 instead of 403.
super_admin can access protected readiness endpoint.
Denial response does not include stack traces, tokens, or raw headers.
Rate-limited request returns 429 with retry metadata if the endpoint supports it.
Existing success response shape remains unchanged.

Helper unit tests:

Allows user with required role.
Rejects missing session.
Rejects unsupported role.
Supports per-endpoint role policy.
Supports hide-on-forbidden behavior.
Emits structured audit event on denial.
Does not log secrets.
8. Rollout

Preferred rollout:

Add shared helper and tests.
Migrate one readiness endpoint first, preferably /api/admin/health/config.
Verify admin dashboard and banner behavior.
Migrate remaining readiness endpoints.
Remove duplicate endpoint-local RBAC logic only after tests pass.

Kill-switch path:

Keep endpoint-specific policy local and reversible.
If shared helper causes production issues, revert route integration while keeping tests and design doc for follow-up.
9. Open questions
Confirm whether admin_web_console/app/api/admin/step-up/health/route.ts exists in the current branch.
Confirm the canonical admin auth helper under admin_web_console/lib/admin/auth/.
Confirm whether admin_web_console/lib/admin/route-guards/ exists or if route guards live elsewhere.
Confirm the existing Firestore audit collection name before implementation.
Decide whether forbidden readiness endpoints should return 403 or hidden 404 per endpoint.
10. Implementation file list

Expected implementation files to review or modify later:

Read-only references:

admin_web_console/app/api/admin/health/config/route.ts
admin_web_console/app/api/admin/step-up/health/route.ts
admin_web_console/app/api/admin/step-up/banner/route.ts
admin_web_console/lib/admin/auth/*
admin_web_console/lib/admin/route-guards/*
docs/design/admin-config-validation.md
docs/tech-debt.md

Likely new or modified implementation files:

admin_web_console/lib/admin/route-guards/readiness-rbac.ts
admin_web_console/lib/admin/route-guards/readiness-rbac.test.ts
Route tests for each protected readiness endpoint
docs/design/admin-readiness-rbac.md