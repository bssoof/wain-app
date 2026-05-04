# AWC-QA-002 Admin Config Validation Design

## Goal

Add a server-side admin-authed health endpoint that validates runtime
configuration the admin console depends on, and surface failures via the
existing admin banner. The endpoint must never leak secret values, must be
rate-limited and cached, and must degrade gracefully (no SSR crash if a config
check fails).

## Scope

- Server-side only: validate what SSR paths actually consume.
- New GET endpoint at `/api/admin/health/config`.
- Banner integration: merge config errors into the existing `AdminBanner`.
- Feature-flagged: `app_config/admin_console.healthCheckEnabled` (default false).

## Non-Goals

- No boot-time SSR validation that could crash the app shell.
- No logging of secret key values; only presence + metadata checks.
- No second banner slot; integrate with the existing `AdminBanner` polling.
- No client-side env var resolution changes.
- No Firestore rules, step-up audit, or finance command contract changes.
- No refactoring of env var consumers found during research.

---

## Endpoint Contract

### Method + Path

`GET /api/admin/health/config`

### Authentication

- Reuse `getCurrentAdminSession()` from `lib/auth/session-server.ts`.
- Reject unauthenticated: **401** `{ ok: false, reason: "unauthenticated" }`.
- Reject non-`super_admin`: **403** `{ ok: false, reason: "forbidden" }`.
- Role check: session must have `role === "super_admin"`.

### Rate Limit

- **30 requests / minute / IP**.
- Reuse the in-memory sliding window pattern from
  `lib/auth/step-up-health-rate-limit.ts`.
- New file: `lib/admin/config-health/rate-limit.ts` (same structure, different
  constants).
- Exceeded → **429** with `{ ok: false, status: "rate_limited", retryAt }`.

### Caching

- **60-second in-memory cache** per server instance.
- Cache key: `"config-health"` (single key; one cached report per server).
- Cache only successful aggregations (all checks ran, even if some returned
  `unknown` or `error`).
- Do NOT cache when the endpoint itself throws (500 path).

### Feature Flag

- Read `app_config/admin_console` document from Firestore once per request
  (cached by Firestore SDK or step-up config cache pattern).
- Field: `healthCheckEnabled` (boolean, default false).
- When disabled: return `{ ok: true, checks: [], disabled: true }` without
  running any check.
- This flag is the rollback mechanism: set to `false` in Firestore to disable
  without redeploy.

---

## Response Shape

```json
{
  "ok": true,
  "checkedAt": "2026-05-02T12:00:00.000Z",
  "cacheTtlSeconds": 60,
  "checks": [
    {
      "id": "finance_functions_base_url",
      "tier": 1,
      "label": "Finance Functions Base URL",
      "status": "ok",
      "present": true,
      "source": "env",
      "value": "https://us-central1-wain-d2e28.cloudfunctions.net",
      "message": null
    },
    {
      "id": "step_up_signing_key_present",
      "tier": 2,
      "label": "Step-Up Signing Key",
      "status": "ok",
      "present": true,
      "source": "secret_manager",
      "message": null
    }
  ],
  "summary": {
    "errorCount": 0,
    "warnCount": 0,
    "unknownCount": 0
  }
}
```

Rules:
- `ok` is `false` **only** if any Tier 1 check has `status: "error"`.
- `value` is included **only** for non-sensitive items (URLs, build ids, mode
  strings). **Never** for keys, tokens, or credentials.
- `lastRotatedAt` is reserved for future key rotation metadata (not
  implemented in Phase 2).
- `message` contains localized Arabic text for banner display when status is
  not `ok`.

---

## Checks List

### Tier 1 — Error if missing/invalid (affects callable transports)

| Check ID | Source | How Validated | Notes |
|---|---|---|---|
| `finance_functions_base_url` | `process.env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL` | Non-empty trimmed string, valid URL shape | Read same way `default-command-transport.ts` reads it |
| `venue_functions_base_url` | `process.env.NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL` | Same | Read same way `default-venue-command-transport.ts` reads it |
| `content_functions_base_url` | `process.env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL` | Same | Read same way `default-review-moderation-transport.ts` reads it |
| `config_functions_base_url` | `process.env.NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL` | Same | Used by config callable transport |
| `firebase_admin_initialized` | `firebase-admin` SDK | Call `getAdminApp()`, check it returns without throwing | Lazy singleton in `lib/firebase/server.ts` |

### Tier 2 — Warn if degraded (affects step-up)

| Check ID | Source | How Validated | Notes |
|---|---|---|---|
| `step_up_signing_key_present` | Secret Manager via `resolveStepUpSigningKey()` | Returns a Buffer without throwing; **do not log value or length** | Presence-only check; wraps in try/catch |
| `step_up_previous_key_present` | Secret Manager env vars | Check if `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION` or `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE` is set | Env presence check only; do not resolve the key |
| `step_up_enforcement_mode` | Firestore `app_config/admin_step_up` | Call `getStepUpEnforcementMode({ useCache: true })` | Report mode value (`enabled`/`log_only`/`disabled`), never error |

### Tier 3 — Info (operator visibility, never causes `ok: false`)

| Check ID | Source | How Validated | Notes |
|---|---|---|---|
| `session_verify_revocation` | `process.env.WAIN_ADMIN_SESSION_VERIFY_REVOCATION` | Report effective value; `"1"` (default) if unset | Informational |
| `build_id` | Next.js `__BUILD_ID__` or `process.env.NEXT_BUILD_ID` | Report string if available, `"unknown"` if not | Traceability |
| `deploy_channel` | Inferred from hostname or env | `"production"` if `wain-admin.web.app`, `"preview"` otherwise | Informational |

---

## Banner Integration

### Current State

`AdminBanner` (client component) polls `GET /api/admin/step-up/banner` every
60 seconds. It reads `bannerMessage` and `bannerSeverity` from the response.
The banner renders one message with dismiss capability.

### Proposed Change

Modify the **step-up banner route** (`app/api/admin/step-up/banner/route.ts`)
to **also** read config health status server-side and merge it into the banner
response. This avoids a second client-side poll.

Merged response:
```json
{
  "success": true,
  "bannerMessage": "جارٍ تجربة تحديث للأوامر المالية. لا يوجد تأثير على عملك.",
  "bannerSeverity": "info",
  "configHealth": {
    "ok": true,
    "summary": { "errorCount": 0, "warnCount": 0, "unknownCount": 0 }
  }
}
```

When config health has errors or warnings:
```json
{
  "success": true,
  "bannerMessage": "⚠ إعدادات ناقصة: عنوان خدمة المالية غير مُعرّف.",
  "bannerSeverity": "warning",
  "configHealth": {
    "ok": false,
    "summary": { "errorCount": 1, "warnCount": 0, "unknownCount": 0 }
  }
}
```

**Severity precedence**: `error > warning > info`.
- If step-up `log_only` notice is active (severity `info`) AND config has an
  `error`, the banner shows the config error message at `warning` severity.
  The step-up notice text is appended as a second line.
- If both are `info`, the step-up message takes priority (existing behavior).

### AdminBanner Component Changes

Minimal changes to `admin-banner.tsx`:
- Read new `configHealth` field from banner response.
- If `configHealth.ok === false`, override severity to `warning` or `critical`.
- No structural changes to `AdminShell` required (AdminBanner already renders
  with no props).

### AdminBanner Error Scenarios

| Scenario | Banner Shows | Severity |
|---|---|---|
| All config ok + no step-up notice | No banner | — |
| All config ok + step-up `log_only` notice | Step-up message | `info` |
| Config error + step-up `log_only` notice | Config error + step-up message | `warning` |
| Config error + no step-up notice | Config error | `warning` |
| Config unknown (timeout) | "تعذر التحقق من الإعدادات" | `warning` |
| Banner endpoint 500 | No change (existing: banner hidden) | — |

---

## Failure Modes

1. **Secret Manager unreachable** during signing key presence check:
   - Per-check: `status: "unknown"`, `message: "تعذر الوصول إلى مدير الأسرار"`.
   - Banner severity: `warn`.
   - `ok` stays `true` (Tier 2 unknown does not cause `ok: false`).

2. **Firestore unreachable** during enforcement mode read:
   - Per-check: `status: "unknown"`, `message: "تعذر قراءة إعدادات Firestore"`.
   - `getStepUpEnforcementMode` already handles this gracefully (defaults to
     `enabled` and calls `onReadError`).

3. **Endpoint itself throws** (uncaught):
   - Return **500** with `{ ok: false, reason: "internal_error" }`.
   - **No stack trace** in response body.
   - Banner shows: `"تعذر التحقق من الإعدادات"` at `warn` severity.

4. **Per-check timeout** (1500ms):
   - Timed-out check: `status: "unknown"`, `message: "انتهت مهلة الفحص"`.
   - Other checks still complete (Promise.allSettled).

---

## Implementation Files

### New Files

| File | Purpose |
|---|---|
| `lib/admin/config-health/types.ts` | `CheckResult`, `CheckId`, `HealthReport`, `CheckTier` types |
| `lib/admin/config-health/checks.ts` | One exported function per check, each returns `Promise<CheckResult>` |
| `lib/admin/config-health/run-checks.ts` | Orchestrator: runs all checks with `Promise.allSettled`, applies per-check timeout (1500ms), handles caching (60s), reads feature flag |
| `lib/admin/config-health/rate-limit.ts` | 30/min rate limiter (same pattern as `step-up-health-rate-limit.ts`) |
| `app/api/admin/health/config/route.ts` | Route handler: auth → rate limit → run checks → return response |

### Modified Files

| File | Change |
|---|---|
| `app/api/admin/step-up/banner/route.ts` | Import `runConfigHealthChecks` (cached), merge `configHealth` into banner response |
| `components/admin/admin-banner.tsx` | Read `configHealth` from banner response, adjust severity + message if needed |

### Not Modified

- `components/admin/admin-shell.tsx` — no prop changes needed; `AdminBanner`
  already renders independently.
- Step-up enforcement code, signing key flow, or Secret Manager bindings.
- Firestore rules, finance command contracts.

---

## Test Plan

### Unit Tests — `lib/admin/config-health/run-checks.test.ts`

1. All checks pass → `ok: true`, `errorCount: 0`.
2. Missing Tier 1 env var → `ok: false`, `errorCount >= 1`.
3. Missing Tier 2 secret → `ok: true` (warn only), `warnCount >= 1`.
4. Tier 3 informational → never affects `ok`.
5. Per-check timeout → `status: "unknown"` (not error).
6. One check throws → other checks still complete.
7. Cache hit returns same payload without re-running (assert spy call counts).
8. Feature flag disabled → returns `{ ok: true, checks: [], disabled: true }`.

### Route Tests — `app/api/admin/health/config/route.test.ts`

1. Unauthenticated → 401.
2. Authenticated non-`super_admin` → 403.
3. `super_admin` + flag on → 200 with full payload.
4. `super_admin` + flag off → 200 with disabled payload.
5. Rate limit exceeded → 429 with `retryAt`.
6. Internal throw → 500 with `{ ok: false, reason }` (no stack trace).

### Banner Integration Tests — `components/admin/admin-banner.test.tsx` (extend existing)

1. Step-up banner only → renders step-up notice unchanged.
2. Config error + step-up banner → error severity, both messages stacked.
3. Config warn only → banner severity `warning`.
4. Endpoint 500 → banner shows "تعذر التحقق من الإعدادات" at `warn`.

### Manual Smoke Checklist (Preview Deploy)

- [ ] Login as `super_admin` → dashboard shows banner matching prod state.
- [ ] `GET /api/admin/health/config` in DevTools → verify JSON shape, no
      secret values present, all Tier 1 ok.
- [ ] Hit endpoint twice within 60s → second response has same `checkedAt`.
- [ ] Hit endpoint as non-`super_admin` → 403.
- [ ] Toggle `healthCheckEnabled` in Firestore → endpoint returns disabled.
- [ ] Step-up `log_only` banner still works unchanged when config `ok: true`.

---

## Rollback Plan

1. **Immediate**: Set `app_config/admin_console.healthCheckEnabled = false` in
   Firestore. Endpoint returns disabled payload, banner merger produces no
   config messages. No redeploy needed.
2. **Code rollback**: Revert commits 2 and 3 from the commit chain.
   Commit 1 (design doc) is inert.

---

## Commit Strategy

1. `docs(admin): design AWC-QA-002 admin config validation`
   — This design doc only. Await review before code.
2. `feat(admin): admin config health endpoint (AWC-QA-002 phase 1)`
   — Endpoint + checks + run-checks + types + rate-limit + tests.
   Feature flag default OFF.
3. `feat(admin): integrate config health into admin banner (AWC-QA-002 phase 2)`
   — Banner route merge + `AdminBanner` component update + integration tests.
4. `chore(admin): enable AWC-QA-002 health check flag`
   — Post-deploy, separate commit (Firestore-only, revertable independently).

---

## Research Findings — Env Var Surface

During research, the following env var reading inconsistencies were observed.
These are **not** addressed in this PR but documented for future cleanup:

| Observation | Files | Severity |
|---|---|---|
| `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL` read via explicit object in `default-command-transport.ts` but via `process.env` fallback in `finance-read-loader.ts` | `default-command-transport.ts`, `finance-read-loader.ts` | Low — both resolve same value in production |
| `WAIN_ADMIN_SESSION_VERIFY_REVOCATION` read directly from `process.env` with no env-injection seam in `session-cookie.ts` | `session-cookie.ts` | Low — works in production, limits test isolation |
| Firebase Admin SDK init checks 6 file paths for service account key without logging which one was selected | `lib/firebase/server.ts` | Info — not a bug, but reduces traceability |

These will be added to `docs/tech-debt.md` during Phase 2 implementation.

---

## Open Questions (Resolved in Design)

1. **Why not a separate client poll for config health?**
   — Merging into the existing banner route avoids a second 60s poll, reduces
   client-side complexity, and reuses the existing dismiss UX.

2. **Why `super_admin` only for the endpoint?**
   — Config health reveals infrastructure topology (function URLs, key
   presence, enforcement mode). Non-admin roles have no operational need for
   this data. The banner merger is visible to all admins but only surfaces
   human-readable status messages, not raw check data.

3. **Why not crash on missing Tier 1 env vars at SSR boot?**
   — The admin console uses Firestore snapshot fallback for reads. A missing
   callable URL degrades writes, not reads. Crashing would prevent admins from
   accessing the dashboard to diagnose the issue.
