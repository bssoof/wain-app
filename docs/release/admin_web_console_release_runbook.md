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
- Live callable routing requires server-side App Check tokens per domain (`WAIN_*_SERVER_APP_CHECK_TOKEN`) with finance fallback.
- Server auth tokens (`WAIN_*_SERVER_AUTH_TOKEN`) remain optional; if absent, proxy forwards the signed-in admin Firebase ID token from the request.

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

## 8. Exit Gate To Go-Live Decision
Go-live can be considered only when all are true:
- the release checklist is fully green,
- staging smoke for config/media/content callable transport is recorded,
- no duplicate-processing or escalation break was observed,
- the operator can execute this runbook without searching through source files mid-incident.
