# Week 1 Auth Runbook - 2026-04-13

## 1. Purpose
- Provide a pressure-usable runbook for authentication and session issues across Admin Web, Flutter client auth, and callable guard boundaries.
- Standardize triage, containment, verification, and evidence capture.

## 2. Scope
This runbook covers:
- Admin sign-in and session lifecycle (`/admin/sign-in`, `/api/admin/session`, protected `/admin/*` routes).
- Session verification policy (`idToken` recency, admin profile activity, revoked session handling).
- Redirect and next-path handling for protected Admin pages.
- Flutter auth execution checklist for real-device validation (email, OTP, Google, sign-out).

This runbook does not replace the full release runbook. It is the Week 1 auth stabilization operator guide.

## 3. Ownership And Escalation
Incident class: `admin_auth_issue`

- Primary owner: Platform Owner
- Backup owner: Web Engineering Lead
- First response target: 15 minutes
- Mitigation target: 60 minutes
- Escalate when:
  - recurring auth failure across multiple operator accounts,
  - widespread session invalidation without an intentional policy change,
  - callable auth/app-check rejection blocks all admin surfaces.

## 4. Known Session Contract
Endpoint: `POST /api/admin/session`

- `400`: Missing `idToken`
- `401`: recent sign-in required or generic session creation failure
- `403`: admin is inactive or missing in `admins/{uid}`
- `200`: session cookie minted (`wain_admin_session`)

Endpoint: `DELETE /api/admin/session`

- Always returns success response for logout path.
- Revocation failure must not block cookie deletion (defensive logout behavior).

## 5. Quick Triage Procedure

### Step 1 - Reproduce with controlled local path
1. Start Admin web console:

```powershell
Push-Location "wain_app/admin_web_console"
npm run dev
```

2. Run smoke flow from workspace root:

```powershell
Push-Location "wain_app"
$env:ADMIN_SMOKE_CLEANUP="1"
node .tmp/admin_login_dashboard_smoke.js
Pop-Location
```

Expected smoke outcome:
- `ok: true`
- dashboard `status: 200`
- `hasDashboardMarker: true`
- `hasSignInMarker: false`

### Step 2 - Branch by symptom
1. Sign-in fails before session endpoint:
- Check Firebase Auth provider and account validity.
- Typical root causes: invalid credential, disabled provider, missing user.

2. Session endpoint returns `401` with recency message:
- Force fresh sign-in and retry.
- Confirm client is sending a fresh `idToken`.

3. Session endpoint returns `403`:
- Verify `admins/{uid}` exists.
- Verify `active` is not `false`.

4. Protected route loops back to sign-in:
- Confirm `wain_admin_session` cookie exists after POST.
- Confirm `next` path resolves to `/admin/*` only.
- Confirm no proxy/header override strips request path context.

5. Logout appears unstable:
- Confirm DELETE still clears cookie even if revocation call fails.

### Step 3 - Validate automated guards
Run in `wain_app/admin_web_console`:

```powershell
npx tsc --noEmit
npm test -- lib/auth/session-cookie.test.ts lib/auth/session-route.test.ts lib/auth/redirect-path.test.ts
```

Expected result:
- TypeScript compile passes
- Session-focused tests pass

## 6. Flutter Real-Device Checklist (Task 1.5)
Run on physical device and capture evidence per scenario:

1. Email/password sign-in and sign-out
2. OTP success path
3. OTP timeout/retry path
4. Google sign-in path and fallback error handling
5. Firestore `users/{uid}` create/update verification
6. Final sign-out and relaunch behavior

Evidence required per scenario:
- UTC timestamp
- account identifier used (masked email/phone)
- success/failure status
- screenshot/log reference
- notes for retries/timeouts

## 7. Containment And Safe Rollback
- If auth failures are systemic, fail closed for privileged flows.
- Do not bypass role checks in route/session guards.
- Prefer restoring known-good env/config over emergency code mutations.
- Keep auditability of any operational override decision.

## 8. Exit Criteria
Auth incident is considered stabilized only when all are true:
- Local smoke is green for login -> session -> dashboard.
- Session-focused automated tests are green.
- No unresolved `admin_inactive_or_missing` misconfiguration for active operators.
- Real-device Flutter checklist is completed or explicitly tracked as pending with owner and ETA.

## 9. Code Anchors
- `admin_web_console/app/api/admin/session/route.ts`
- `admin_web_console/lib/auth/session-cookie.ts`
- `admin_web_console/lib/auth/session-server.ts`
- `admin_web_console/lib/auth/route-guards.ts`
- `admin_web_console/lib/auth/redirect-path.ts`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/routing/app_router.dart`
- `functions/src/index.ts`
