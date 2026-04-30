# Admin Web Console Release Runbook

## 1. Purpose
- Provide a pressure-usable operator runbook for the Admin Web Console release path.
- Cover verification order, transport prerequisites, incident ownership, and rollback posture for the governed admin surfaces.

## 2. Scope
This runbook covers the current governed surfaces that already exist in the console:
- Finance Ops
- Venue Ops
- Media Ops
- Content Ops
- Dashboard
- Config Governance

It does not claim a production go-live by itself; it is the operational procedure to reach a safe release decision.

## 3. Transport Prerequisites

Policy update (Phase 1 containment):
- `NEXT_PUBLIC_*_AUTH_TOKEN` and `NEXT_PUBLIC_*_APP_CHECK_TOKEN` are diagnostics-only and are forbidden in production runtime.
- Production command execution must use a server-side admin command proxy path.
- Staging and production checklists must not require static browser tokens to proceed.
- `WAIN_ADMIN_SESSION_JSON` is development-only and must be ignored in production runtime.

Server proxy command paths (Phase 2 hardening completion):
- Browser commands now target:
   - `POST /api/admin/command/finance`
   - `POST /api/admin/command/config`
   - `POST /api/admin/command/content`
   - `POST /api/admin/command/media`
   - `POST /api/admin/command/reviews`
   - `POST /api/admin/command/venues`
- Live callable routing requires App Check at proxy level: static server tokens (`WAIN_*_SERVER_APP_CHECK_TOKEN`) are supported, and missing static tokens fall back to short-lived server-minted App Check tokens.
- Server auth tokens (`WAIN_*_SERVER_AUTH_TOKEN`) remain optional; if absent, proxy first attempts an exchange from `WAIN_SERVER_AUTH_REFRESH_TOKEN` (or domain-specific `WAIN_*_SERVER_AUTH_REFRESH_TOKEN`), then attempts to mint a short-lived server token from authenticated admin session claims, and finally falls back to forwarding the signed-in admin Firebase ID token.

Required browser-facing environment variables (base URL only):
- `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL`
- `NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL`
- `NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL`
- `NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL`

### Finance callable transport
- `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL`

### Content callable transport
- `NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL`

Behavior note:
- Content transport falls back to the finance callable env family only when the content-specific variables are absent.

### Media callable transport
- `NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL`

Behavior note:
- Media transport falls back to venue/finance callable base URL resolution when media-specific variables are absent.

### Config callable transport
- `NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL`

Behavior note:
- Config transport reuses the finance callable invoker factory and falls back to the finance env family if config-specific variables are absent.

Local diagnostics only (not part of release readiness, forbidden in staging/production):
- `NEXT_PUBLIC_*_AUTH_TOKEN`
- `NEXT_PUBLIC_*_APP_CHECK_TOKEN`

## 3.1 Console Warning Classification (Auth and CSP)

Observed browser warnings during `/admin/*` navigation can be split into non-blocking telemetry versus actionable defects.

Non-blocking (report-only telemetry):
- `The Content Security Policy directive 'upgrade-insecure-requests' is ignored when delivered in a report-only policy.`
- `Framing 'https://<project>.firebaseapp.com/' violates the following report-only Content Security Policy directive ...`

Meaning:
- The current policy is report-only and does not block runtime behavior.
- These messages are log noise unless a blocking (enforced) CSP policy is introduced.

Actionable only when OAuth popup/redirect flows are required:
- `The current domain is not authorized for OAuth operations ... Add your domain ... Authorized domains`

Meaning:
- This impacts `signInWithPopup`, `signInWithRedirect`, `linkWithPopup`, and `linkWithRedirect` only.
- It does not block email/password sign-in (`signInWithEmailAndPassword`).

Current admin-console posture:
- Admin auth is email/password-only.
- Client auth is initialized without popup/redirect resolver to avoid unnecessary OAuth iframe/domain checks.

If OAuth is later introduced, release owners must:
1. Add `wain-admin.web.app` to Firebase Auth Authorized domains.
2. Revisit CSP headers for `frame-src` and related auth iframe origins.
3. Re-run browser smoke for `/admin/sign-in` and at least one protected page (`/admin/venues`).

## 4. Mandatory Verification Order

### Step 1 - Source verification
Run:

```powershell
cd wain_app/admin_web_console
npm test
npx tsc --noEmit --pretty false
npm run build:secure
```

Then:

```powershell
cd ..\functions
npm run build
$env:GCLOUD_PROJECT="wain-d2e28"   # or target project id for the active environment
npm run admin-web:audit-admin-roles -- --output=../docs/release/admin_role_audit_report_latest.json
```

Interpretation (SEC-2 gate):
- `missing_role` and `invalid_role` findings must be reviewed and resolved (deactivate or assign explicit minimal role) before claiming SEC-2 closure.

### Step 2 - Emulator hardening verification
Run:

```powershell
cd wain_app/functions
firebase --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/securityConcurrencyFlows.test.js"
firebase --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/securityCallableFlows.test.js"
firebase --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/contentModerationCallableFlows.test.js"
```

Interpretation:
- `securityConcurrencyFlows` validates duplicate-processing resistance.
- `securityCallableFlows` validates the governed callable surface across finance, venue, media, reviews, and config.
- `contentModerationCallableFlows` validates offer/story moderation specifics.

### Step 3 - Direct-write audit
Run a source audit over `admin_web_console` and confirm no direct Firestore write APIs exist in the app source.

Required result:
- no `setDoc`
- no `updateDoc`
- no `addDoc`
- no `deleteDoc`
- no `writeBatch`
- no `runTransaction`
- no `getFirestore`

### Step 4 - Service-account staging rehearsal
Run:

```powershell
cd wain_app/functions
$env:GOOGLE_APPLICATION_CREDENTIALS="..\\service-account-key.json"
$env:GCLOUD_PROJECT="wain-d2e28"
npm run admin-web:staging-rehearsal
```

This proves:
- config publish/rollback callable logic
- media governance callable logic
- content moderation callable logic
- reviews moderation callable logic

It does not prove browser HTTP callable transport.

### Step 5 - Browser transport smoke
Before go-live, execute a browser-side staging smoke for:
- `/admin/config`
- `/admin/media`
- `/admin/content/offers`
- `/admin/content/stories`
- `/admin/content/reviews`

If any of these still return explicit `unavailable`, auth failure, app-check failure, or index-building failure, stop at staging rehearsal and do not claim release readiness.

## 5. Incident Ownership Baseline

| Incident class | Primary owner role | Backup owner role | Kill switch / containment |
| --- | --- | --- | --- |
| `financial_integrity` | Finance Admin Lead | Backend Lead | freeze finance mutations, restrict top-up/reversal actions |
| `queue_backlog` | Finance Ops Lead | Product Ops Lead | suspend review batching, prioritize SLA triage |
| `config_misconfiguration` | Platform Owner | Finance Admin Lead | stop publish, rollback to last known-good config version |
| `media_access_issue` | Content Ops Lead | Platform Owner | disable destructive media workflows, keep read-only inventory visible |
| `admin_auth_issue` | Platform Owner | Web Engineering Lead | restrict privileged admin access, verify claim/doc conflict behavior |
| `readiness_failure` | Platform Owner | Finance Admin Lead | stop release progression, investigate callable/rules/env health |

Security denial observability baseline (OPS-3 slice):
- Admin web emits structured server logs tagged with `[SECURITY_AUDIT]` for denial-sensitive chokepoints:
   - route guard denials (`admin_route_access_denied`, `admin_session_required_missing`)
   - command proxy denials (`proxy_payload_invalid`, `proxy_authorization_denied`, `proxy_transport_rejected`)
- JSON fields include: `timestamp`, `source`, `eventType`, `reason`, `status`, `path`, optional `routeKey`, optional `command`, optional `correlationId`, optional `sessionUid`, optional `sessionRole`, optional `serviceLabel`.
- This runbook expects these logs to be queryable during incident triage before any manual rollback decision.

## 6. Pressure Mode Procedure
1. Open:
   - `docs/release/admin_web_console_release_checklist.md`
   - `docs/release/admin_web_console_incident_drill_review.md`
   - this runbook
2. Confirm the release owner and backup owner for the active incident class.
3. Reproduce only with the smallest governed path needed.
4. Prefer rollback or containment over improvising a direct data fix.
5. Never apply a manual Firestore mutation from the browser to recover a protected state.

## 7. Rollback Posture
- Config issues: use governed rollback, not document editing.
- Finance issues: use compensating reversal flow, never mutate historical ledger entries.
- Media/content issues: preserve audit trail, prefer disabling actions or rollback of callable-backed behavior over silent mutation.
- Auth/RBAC issues: fail closed and restore access deliberately after claim/doc policy review.

## 8. Step-up Rollout Procedure (Finance Mutations)

Applies when enabling password step-up protection for sensitive finance commands:
- `approve_topup`
- `reject_topup`
- `reverse_wallet_entry`
- `approve_reversal`

Pre-deployment checklist:
1. Confirm production signing key is available in Secret Manager and that the intended version is documented.
2. Confirm `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION` (or resource alias) points to the approved key version.
3. Keep production rollout frozen until UI + backend flow is end-to-end validated on staging.

Post-deployment staging smoke (mandatory before production):
1. Execute each command above once with a valid step-up challenge and confirm success path.
2. Trigger one command without a step-up cookie and confirm explicit `STEP_UP_REQUIRED`.
3. Re-authenticate and retry the blocked command; confirm command completes and audit logs retain correlation ids.
4. Record evidence in `docs/release/admin_web_console_staging_evidence_log.md`.

Final PR17.4 smoke checklist:
- [ ] Login as `finance_admin`.
- [ ] Approve one reversal and confirm the step-up modal appears before command execution.
- [ ] Enter a wrong password twice and confirm inline password errors without command execution.
- [ ] Enter a wrong password a third time and confirm `429` lockout with a visible countdown.
- [ ] Wait for the 5-minute lockout window to expire.
- [ ] Enter the correct password and confirm the command executes once.
- [ ] Execute a second finance mutation within 15 minutes and confirm no modal appears.
- [ ] Execute `reject_topup` within the same 15-minute finance scope and confirm no modal appears.
- [ ] Wait at least 16 minutes and confirm the next sensitive finance command asks for step-up again.
- [ ] Run `verify_wallet_readiness` during the same session and confirm it does not require step-up.
- [ ] Logout and re-login, then confirm the step-up cookie is no longer usable for finance mutations.
- [ ] Check audit logs for the related command/correlation id and `proxy_step_up_required` events.

Retry/idempotency contract:
- The UI may reopen step-up only when the normalized command result has `error.code === "step_up_required"`.
- Generic `403`, network failures, malformed responses, and upstream unavailable states must surface normally and must not trigger a forced retry.
- The forced retry must reuse the original command request object, including the same `commandId`; the backend receives `idempotencyKey = commandId`.
- There must be no retry loop. The UI performs one forced step-up challenge and one command retry after explicit `STEP_UP_REQUIRED`.

Production deployment checklist:
1. Confirm staging and production Firebase projects are separated before testing finance mutations.
2. Confirm `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION` or `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_RESOURCE` points to the approved Secret Manager version in the target project.
3. Confirm direct `WAIN_ADMIN_STEP_UP_SIGNING_KEY` is not configured in production.
4. Confirm the finance command proxy has server-side function/app-check credentials for the target environment.
5. Run the final PR17.4 smoke checklist on staging and attach evidence before production promotion.
6. During rollout, monitor `proxy_step_up_required`, finance command success/error rates, and duplicate idempotency-key replays for 48 hours.

Key rotation procedure:
1. Create a new Secret Manager version for `wain-admin-step-up-signing-key`.
2. Deploy with `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION` pointing to the new current version and `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION` pointing to the old version.
3. Confirm old tokens still verify and new tokens are issued by the current key only.
4. Monitor `step_up_previous_key_verified` audit events; these indicate still-active tokens signed by the previous key.
5. After at least one full step-up TTL window plus deployment buffer, remove `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION`.
6. Confirm old tokens are rejected with `STEP_UP_REQUIRED` and normal re-auth issues new current-key tokens.
7. Disable or destroy the old secret version only after production metrics show no previous-key verification events.

Rollback and containment:
1. If finance mutations are blocked unexpectedly, stop rollout and revert the step-up release branch.
2. If key compromise is suspected, rotate Secret Manager key version and invalidate the previous version before re-enabling rollout.
3. Re-run the four-command smoke suite after rollback or key rotation.

Admin communication template:
> تم تفعيل طبقة حماية إضافية للأوامر المالية الحساسة في لوحة الإدارة.  
> عند اعتماد/رفض الشحن أو طلبات التصحيح سيُطلب إدخال كلمة المرور للتأكيد قبل التنفيذ.  
> إذا ظهر `STEP_UP_REQUIRED` بشكل متكرر، أعد تسجيل الدخول ثم أعد المحاولة، وبلّغ فريق التشغيل إذا استمرت المشكلة.

## 9. Exit Gate To Go-Live Decision
Go-live can be considered only when all are true:
- the release checklist is fully green,
- staging smoke for config/media/content callable transport is recorded,
- no duplicate-processing or escalation break was observed,
- the operator can execute this runbook without searching through source files mid-incident.
