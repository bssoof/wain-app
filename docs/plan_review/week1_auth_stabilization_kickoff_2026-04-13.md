# Week 1 Auth Stabilization Kickoff - 2026-04-13

## Scope

This document captures the Week 1 auth kickoff execution for:
- Task 1.1: End-to-end auth flow mapping (Flutter -> Functions -> Admin)
- Task 1.2: Admin restart and login -> dashboard smoke test
- Task 1.3: Session verification unification
- Task 1.4: Redirect logic hardening
- Task 1.5: Flutter real-device auth test readiness
- Task 1.6: Automated session tests
- Task 1.7: Auth runbook

## Week 1 status snapshot

- [x] 1.1 - Auth flow map
- [x] 1.2 - Admin login -> dashboard smoke
- [x] 1.3 - Unify session verification
- [x] 1.4 - Fix redirect logic
- [/] 1.5 - Flutter auth device run pending
- [x] 1.6 - Automated session tests
- [x] 1.7 - Auth runbook

Progress checkpoint:
- Week 1 completion from ADM side is effectively closed (6 of 7 tasks complete).
- Remaining item is FLT-only execution for Task 1.5 on a physical device.
- Estimated progress: ~16h / 19h (about 84%).

Handoff status:
- ADM track: closed for Week 1 scope.
- FLT track: pending evidence capture for Task 1.5.

## Task 1.2 - Admin login -> dashboard smoke

Status: done

Execution summary:
- Admin web console started on local port 3010.
- A temporary admin test user was provisioned in Firebase Auth and admins collection.
- Real Firebase sign-in was executed using email/password.
- Admin session endpoint was called to mint wain_admin_session cookie.
- Protected dashboard was fetched with session cookie and validated.
- Temporary test user and admin doc were cleaned up after test.

Smoke script:
- .tmp/admin_login_dashboard_smoke.js

Observed result:
- ok: true
- dashboard status: 200
- dashboard marker found: true
- sign-in marker found on dashboard response: false
- checkedAt: 2026-04-13T20:17:17.755Z

## Task 1.3 - Unify session verification

Status: done

Execution summary:
- Added shared session policy in `admin_web_console/lib/auth/session-cookie.ts`.
- Centralized cookie constants and recency checks for admin session minting.
- Centralized admins collection active-check before minting session cookie.
- Reused the same helper in API route, server actions, and runtime session loading.

Implementation anchors:
- `admin_web_console/lib/auth/session-cookie.ts`
- `admin_web_console/app/api/admin/session/route.ts`
- `admin_web_console/lib/auth/session-actions.ts`
- `admin_web_console/lib/auth/session-server.ts`

## Task 1.4 - Redirect logic hardening

Status: done

Execution summary:
- Added shared next-path sanitizer with admin-scope restriction.
- Prevented unsafe redirect values (for example protocol-relative `//...`).
- Updated layout auth gate to preserve requested admin path via request-header candidates.
- Updated sign-in page to use same sanitizer for `next` parameter.

Implementation anchors:
- `admin_web_console/lib/auth/redirect-path.ts`
- `admin_web_console/lib/auth/route-guards.ts`
- `admin_web_console/app/(protected)/admin/layout.tsx`
- `admin_web_console/app/(public)/admin/sign-in/page.tsx`

Validation:
- `npx tsc --noEmit` (admin_web_console): pass
- `npm test -- lib/auth/guard-api.test.ts lib/auth/rbac-shell.integration.test.ts lib/auth/redirect-path.test.ts`: pass
- Post-refactor smoke (`node .tmp/admin_login_dashboard_smoke.js`, cleanup enabled):
  - ok: true
  - dashboard status: 200
  - hasDashboardMarker: true
  - hasSignInMarker: false
  - checkedAt: 2026-04-13T20:31:45.010Z

## Task 1.6 - Automated session tests

Status: done

Execution summary:
- Added policy tests for session helpers to verify idToken recency checks, admin activity enforcement, revocation flow, and session cookie policy.
- Added route tests for `/api/admin/session` covering POST success/error mapping and DELETE behavior (with/without cookie, revoke failure tolerance).

Implementation anchors:
- `admin_web_console/lib/auth/session-cookie.test.ts`
- `admin_web_console/lib/auth/session-route.test.ts`

Validation:
- `npm test -- lib/auth/session-cookie.test.ts lib/auth/session-route.test.ts`: pass (14/14)
- `npx tsc --noEmit` (admin_web_console): pass

## Task 1.7 - Auth runbook

Status: done

Execution summary:
- Added a pressure-usable runbook for Admin session/auth incidents, including HTTP status decisioning, defensive logout behavior, and escalation posture.
- Added fast local repro steps (login -> session -> dashboard smoke), session test commands, and explicit containment guidance.
- Added Flutter real-device evidence checklist so Task 1.5 can be executed and recorded consistently.

Artifact:
- `docs/plan_review/week1_auth_runbook_2026-04-13.md`

## Task 1.1 - Full auth flow map (Flutter -> Functions -> Admin)

Status: done

```mermaid
flowchart TD
  A1[Flutter App]
  A2[Firebase Auth SDK]
  A3[Firestore users collection]
  A4[Firebase ID Token]
  A5[Cloud Functions onCall]
  A6[Functions auth gate]
  A7[Functions app-check gate]
  A8[Admin role resolution]
  A9[Protected function logic]

  B1[Admin Web Sign-In page]
  B2[Firebase Web Auth signInWithEmailAndPassword]
  B3[/api/admin/session]
  B4[firebase-admin verifyIdToken]
  B5[firebase-admin createSessionCookie]
  B6[wain_admin_session cookie]
  B7[Protected admin routes]
  B8[getCurrentAdminSession]
  B9[admins collection check]
  B10[RBAC route guard]
  B11[Dashboard or target admin page]

  A1 --> A2
  A2 -->|phone/email/google/guest| A4
  A2 -->|profile persistence| A3
  A4 --> A5
  A5 --> A6
  A5 --> A7
  A6 --> A8
  A8 --> A9

  B1 --> B2
  B2 -->|ID token| B3
  B3 --> B4
  B4 --> B5
  B5 --> B6
  B6 --> B7
  B7 --> B8
  B8 --> B9
  B9 --> B10
  B10 --> B11

  B11 -->|callable actions from admin web| A5
```

Implementation anchors used for this map:
- Flutter auth repository:
  - lib/features/auth/data/repositories/auth_repository_impl.dart
- Flutter admin-route claim/doc gate:
  - lib/core/routing/app_router.dart
- Admin sign-in and session creation:
  - admin_web_console/app/(public)/admin/sign-in/page.tsx
  - admin_web_console/app/api/admin/session/route.ts
- Admin session resolution and protected routing:
  - admin_web_console/lib/auth/session-server.ts
  - admin_web_console/lib/auth/route-guards.ts
- Callable transport and auth/app-check header propagation:
  - admin_web_console/lib/finance/finance-command-transport.ts
- Functions admin/auth/app-check guard baseline:
  - functions/src/index.ts

## Task 1.5 - Flutter auth on real device

Status: pending (device execution required)

Readiness status:
- Code path is available and already wired in Flutter auth repository.
- A real-device run is still required to validate OTP/email/google behavior in device conditions.

Suggested execution checklist:
1. Run Flutter app on physical device with production Firebase config.
2. Verify email/password sign-in and sign-out.
3. Verify OTP flow with valid phone and timeout behavior.
4. Verify Google sign-in behavior and fallback errors.
5. Confirm Firestore users doc creation/update.
6. Capture evidence logs/screenshots per scenario.

## ADM Closure Checkpoint — 2026-04-13

Week 1 progress: ~84% (6/7 tasks completed in a single day).

ADM-owned tasks completed:
- [x] 1.1 — Auth flow map (Mermaid diagram, Flutter → Functions → Admin)
- [x] 1.2 — Admin login → dashboard smoke (ok=true, status=200)
- [x] 1.3 — Unified session verification (session-cookie.ts, central policy)
- [x] 1.4 — Redirect logic hardening (redirect-path.ts, sanitizer + tests)
- [x] 1.6 — Automated session tests (14 tests green across 2 new test files)
- [x] 1.7 — Auth runbook (triage, contract, escalation, containment)

FLT-pending:
- [/] 1.5 — Flutter real-device auth test (requires physical device execution)

Handoff to FLT:
- Execution checklist is ready in this document under Task 1.5.
- Evidence format is defined in the auth runbook (`week1_auth_runbook_2026-04-13.md`).
- Once 1.5 is executed and evidence is appended, Week 1 is fully closed.

Delivered artifacts:
- `lib/auth/session-cookie.ts` — centralized session policy
- `lib/auth/redirect-path.ts` — safe next-path sanitizer
- `lib/auth/session-cookie.test.ts` — 6 policy unit tests
- `lib/auth/session-route.test.ts` — 8 route endpoint tests
- `lib/auth/redirect-path.test.ts` — 5 redirect sanitizer tests
- `.tmp/admin_login_dashboard_smoke.js` — E2E smoke script
- `docs/plan_review/week1_auth_runbook_2026-04-13.md` — operational runbook

## Next immediate action

FLT: Execute Task 1.5 on a physical device and append evidence to this document.
