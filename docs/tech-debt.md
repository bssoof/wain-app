# Tech Debt Backlog

---

## Pentest Residuals (2026-05-01)

### P1 — CDN path-encoding bypass (Firebase/Fastly)
- **Surface**: Firebase Hosting CDN + Fastly edge
- **Issue**: Certain encoded path traversal sequences (`%c0%af`, `%00`, double-encoding) may bypass CDN-level path matching before reaching Cloud Run origin. Firebase Hosting does not expose middleware hooks to normalize these paths at the edge.
- **Mitigation applied**: `middleware.ts` rejects `%00` and `%c0%af` patterns before they reach route handlers.
- **Residual risk**: The CDN layer itself does not strip or reject these patterns; mitigation relies on the SSR runtime middleware.
- **Acceptance**: Firebase Support ticket needed to confirm CDN-level normalization behavior or request edge-level rejection.
- **Owner**: Platform Owner → Firebase Support
- **Created**: 2026-05-01
- **Status**: Waiting on Firebase Support

### P1 — Cloud Run direct URL leak
- **Surface**: `fh-0d492fa2b30328db---ssrwainadmin-wvn5fhzfsq-uc.a.run.app`
- **Issue**: The direct Cloud Run URL for the admin SSR service is discoverable and bypasses Firebase Hosting CDN, including any CDN-level security headers and path restrictions set in `firebase.json`.
- **Desired state**: Restrict Cloud Run ingress to `internal-and-cloud-load-balancing` so only Firebase Hosting (via its load balancer) can reach the service.
- **Blocker**: Firebase manages the Cloud Run service for App Hosting; direct ingress updates are rejected. Requires Firebase Support intervention.
- **Owner**: Platform Owner → Firebase Support
- **Created**: 2026-05-01
- **Status**: Waiting on Firebase Support

### P2 — RSC/Next-Action middleware bypass at older layers
- **Surface**: `middleware.ts` Next.js RSC probes
- **Issue**: `Next-Action` header and RSC probes without valid `Next-Router-State-Tree` are rejected at middleware level, but older Next.js internal layers may still process partial RSC payloads before middleware runs.
- **Mitigation applied**: `middleware.ts` explicitly rejects `Next-Action` requests, RSC probes without router state, and malformed `Next-Router-State-Tree` headers.
- **Residual risk**: Deep RSC internals may evolve across Next.js versions; current guards are version-specific.
- **Acceptance**: Next.js upgrade + audit of page-level auth to ensure no server action bypasses route guards.
- **Estimated**: 4–8 hours (Next.js upgrade) + 2 hours (page-level audit)
- **Owner**: Frontend/Security Owner
- **Created**: 2026-05-01
- **Status**: Open

### P2 — 500 → 400 generic error handler with Security Headers
- **Surface**: SSR runtime pre-app error responses
- **Issue**: Malformed JSON body (non-`{}`), malformed `Next-Router-State-Tree`, null-byte payloads, and overlong UTF-8 sequences trigger uncaught 500 responses that leak `build ID` in the default Next.js error page. Security headers (CSP Report-Only, X-Frame-Options, X-Content-Type-Options) are not applied to these pre-app 500 responses.
- **Mitigation applied**: `/api/admin/session` returns `400` for malformed JSON instead of crashing. `middleware.ts` blocks the most common attack vectors before they reach route handlers.
- **Residual risk**: Functions Framework / Next.js built-in error handler still emits bare 500 for edge cases that bypass middleware. Build ID disclosure is low-value but violates defense-in-depth principle.
- **Acceptance**: Either implement a custom error handler in Functions Framework that returns generic 400 with security headers, or formally accept as limited information disclosure (build ID only).
- **Estimated**: 3–4 hours (custom error handler) or 0 hours (accept risk)
- **Owner**: Backend/Security Owner
- **Created**: 2026-05-01
- **Status**: Open — pending decision

### P3 — BREACH mitigation
- **Surface**: Admin panel HTTP responses over TLS with compression
- **Issue**: BREACH attack exploits HTTP compression + TLS to extract secrets from response bodies. Admin panel serves compressed responses containing CSRF tokens and session identifiers.
- **Practical risk**: Low. BREACH requires attacker-controlled input reflected in the same response as the secret, repeated oracle queries, and measurable compression ratio differences. The admin panel has no user-controlled reflection in sensitive response bodies.
- **Acceptance**: Accept as low practical risk for admin-only panel. Re-evaluate if the panel gains user-controlled content reflection.
- **Owner**: Security Owner
- **Created**: 2026-05-01
- **Status**: Accepted (low risk)

### P3 — TLS certificate expiry monitoring
- **Surface**: `*.web.app` / `*.firebaseapp.com` TLS certificate
- **Issue**: Current TLS certificate expires `2026-06-18`. Firebase manages certificate renewal automatically, but no alerting is configured to detect renewal failure.
- **Acceptance**: Set a calendar reminder for `2026-06-11` (7 days before expiry) to verify certificate renewal. If Firebase auto-renewal has not occurred by then, escalate to Firebase Support.
- **Owner**: Platform Owner
- **Created**: 2026-05-01
- **Status**: Open — reminder needed

### Pentest #2 — Scope definition
- **Surface**: Full admin console post-enforcement
- **Trigger**: After Firebase Support resolves ingress restriction + step-up enforcement is enabled.
- **Scope**:
  - `/api/admin/command/finance`, `/api/admin/command/*` (all command proxy routes)
  - `/api/admin/step-up/issue`, `/api/admin/step-up/status`
  - `/status`, `/health`
- **Test cases**:
  - CDN bypass on command endpoints
  - Step-up token replay/forgery
  - Rate limit bypass on step-up issuance
  - Key rotation behavior under load
  - Direct Cloud Run URL access (verify blocked after ingress fix)
- **Owner**: Security Owner
- **Created**: 2026-05-01
- **Status**: Blocked on Firebase Support + enforcement enablement

---

## Pre-existing Tech Debt

### P3 — Audit event enrichment (step-up)
- **Status**: Resolved in B2 rollout-safety work.
- **File**: `admin_web_console/lib/auth/step-up-token.ts`
- **Event**: `step_up_previous_key_verified`
- **Issue**: Event lacks full investigation context for key-rotation analysis.
- **Acceptance**: Add `tokenIssuedAt`, `tokenAge_ms`, `currentKeyVersion`, and `previousKeyVersion`.
- **Estimated**: 2 hours
- **Related**: AWC-QA-017
- **Created**: 2026-04-30
- **Resolved**: 2026-04-30

### P3 — Audit events retention policy
- **Collection**: `admin_step_up_audit_events`
- **Issue**: No TTL configured; collection can grow indefinitely after rollout.
- **Acceptance**: Configure Firestore TTL, for example 365 days, or add a scheduled cleanup job for old events.
- **Estimated**: 1 hour
- **Related**: AWC-QA-017 follow-up
- **Created**: 2026-04-30

### P3 — Preview channel root routing
- **Surface**: Firebase Hosting preview channels
- **Issue**: Preview channels can return `Site Not Found` on `/` while production redirects or loads correctly.
- **Current assessment**: Likely Firebase preview proxy behavior, not app code, because `/admin/sign-in` and production root load correctly.
- **Acceptance**: Investigate whether this affects future smoke-test reliability and document the preferred preview URL pattern.
- **Estimated**: 1 hour
- **Related**: AWC-QA-017 Phase A smoke testing
- **Created**: 2026-04-30

### P3 — Transport architecture documentation
- **Surface**: Admin web console transport layer
- **Issue**: The layered transport pattern (callable → snapshot → inline fallback) is undocumented beyond inline code comments.
- **Acceptance**: Create `docs/architecture/admin-transport.md` explaining the transport stack, fallback semantics, and source labeling contract.
- **Estimated**: 2 hours
- **Created**: 2026-05-01

### P3 — verify_wallet_readiness post-rollout verification
- **Surface**: Step-up auth scope
- **Issue**: `verify_wallet_readiness` is explicitly excluded from step-up requirements. After step-up enforcement, verify that this exclusion works correctly in production and that the command cannot be abused as a side-channel.
- **Acceptance**: Manual smoke test after enforcement enablement.
- **Estimated**: 30 minutes
- **Created**: 2026-05-01

### P3 — Duplicate error surface when TopUpConfirmationDialog is open
- **Surface**: `topup-queue-table.tsx` + `topup-confirmation-dialog.tsx`
- **Issue**: When the confirmation dialog is open and a command fails, the error message and "إعادة المحاولة" retry button appear in **both** the dialog's `.topup-confirm-error` area and the row-level `CommandRuntimeCallout`. The user sees the same message twice.
- **Suggested fix**: While `pendingDecision` is active, suppress the `CommandRuntimeCallout` for the matching `runtimeKey`. The dialog becomes the single source of truth for the active command's state. Implementation: pass `dimmedRuntimeKey={pendingDecision?.runtimeKey}` and hide the callout when it matches.
- **Impact**: Visual-only; no functional issue. Tests work around it via `getAllByRole` + class filter.
- **Estimated**: 30 minutes
- **Created**: 2026-05-02

### P3 — No `@testing-library/jest-dom` in admin web console tests
- **Surface**: `admin_web_console` Vitest test suite
- **Issue**: The project does not include `@testing-library/jest-dom`, so matchers like `toBeDisabled()`, `toBeVisible()`, `toHaveAttribute()` are unavailable. Tests must use native DOM property checks like `(el as HTMLButtonElement).disabled`.
- **Convention**: All new tests should use `(el as HTMLElement).propertyName` instead of jest-dom matchers. If jest-dom is added in the future, existing tests can be migrated.
- **Estimated**: N/A (convention, not a task)
- **Created**: 2026-05-02

---

## Pentest Residuals (post AWC-QA-002 deploy, 2026-05-02)

### P1 — CDN path-encoding bypass via cookie clearing (Firebase/Fastly)
- **Surface**: Firebase Hosting CDN + Fastly normalization
- **Issue**: `DELETE /%2fapi%2fadmin%2fsession` returns `200` and clears `wain_admin_session` and `__session` cookies. The encoded path bypasses CDN-level path matching and reaches the origin, which processes the cookie-clearing logic.
- **Verified**: Still active on production as of 2026-05-02.
- **Tracked**: `firebase/firebase-tools` issue #10448
- **Owner**: Platform Owner → Firebase Support
- **Created**: 2026-05-02
- **Status**: Open

### P1 — Cloud Run direct URL leak (ssrwainadmin)
- **Surface**: `ssrwainadmin-wvn5fhzfsq-uc.a.run.app`
- **Issue**: The direct Cloud Run URL for the admin SSR service bypasses Firebase Hosting CDN. Current ingress setting is `INGRESS_TRAFFIC_ALL`, allowing unrestricted access.
- **Tracked**: `firebase/firebase-tools` issue #10448
- **Owner**: Platform Owner → Firebase Support
- **Created**: 2026-05-02
- **Status**: Open

### P2 — RSC and Next-Action middleware bypass with Build ID leak
- **Surface**: `middleware.ts` Next.js RSC probes, error pages
- **Issue**: RSC and `Next-Action` middleware bypass on older Next.js layers. Build ID `prrkRKdondl9vvQ2TZmC4` leaked in error pages.
- **Mitigation applied**: Server-side `redirect()` in pages prevents data exfiltration via RSC bypass.
- **Permanent fix**: Requires Next.js upgrade to version with fixed RSC layer ordering.
- **Owner**: Frontend/Security Owner
- **Created**: 2026-05-02
- **Status**: Open — mitigated, pending Next.js upgrade

### P2 — Pre-app 500 errors on malformed input (Functions Framework)
- **Surface**: SSR runtime, Functions Framework body-parser
- **Issue**: Malformed JSON, `Next-Router-State-Tree`, `%00` null-byte, and `%c0%af` overlong UTF-8 payloads trigger 500 errors in the Functions Framework body-parser before reaching the Next.js handler. Security headers are not applied to these responses.
- **Desired state**: Generic error handler that preserves security headers and returns sanitized `400` for all pre-app parse failures.
- **Owner**: Backend/Security Owner
- **Created**: 2026-05-02
- **Status**: Open

### P3 — BREACH (CVE-2013-3587) br/gzip over HTTPS
- **Surface**: Admin panel HTTP responses with `br`/`gzip` compression over TLS
- **Issue**: BREACH attack (CVE-2013-3587) exploits HTTP compression over TLS to extract secrets. Admin panel serves compressed responses.
- **Practical risk**: Low. No user-controlled reflection in sensitive response bodies on admin panel.
- **Acceptance**: Monitor. Re-evaluate if admin panel gains user-controlled content reflection.
- **Owner**: Security Owner
- **Created**: 2026-05-02
- **Status**: Accepted (low risk) — monitoring

### P3 — TLS cert expiry 2026-06-18 reminder
- **Surface**: `*.web.app` / `*.firebaseapp.com` TLS certificate
- **Issue**: TLS certificate expires 2026-06-18. Set calendar reminder for renewal verification 7 days before (2026-06-11).
- **Owner**: Platform Owner
- **Created**: 2026-05-02
- **Status**: Open — reminder needed

---

## AWC-QA-002 Follow-ups

### P3 — admin-banner.tsx payload spread mutation
- **Surface**: `admin_web_console/components/admin-banner.tsx`
- **Issue**: The payload spread mutation pattern used to build banner payloads is verbose and duplicated across branches.
- **Suggested fix**: Extract a `buildBannerPayload` helper function. Becomes more valuable if the config-health UI grows additional banner types.
- **Estimated**: 30 minutes
- **Created**: 2026-05-02
- **Status**: Open

### P3 — config-health/checks.ts per-call timeout consolidation
- **Surface**: `admin_web_console/lib/config-health/checks.ts`
- **Issue**: Each health check has its own per-call timeout implementation. The pattern is repeated across all check functions.
- **Suggested fix**: Consolidate into a shared `withTimeout` helper that wraps any async check with a configurable deadline.
- **Estimated**: 1 hour
- **Created**: 2026-05-02
- **Status**: Open

### P3 — Firestore feature flag read on every banner request
- **Surface**: Firestore `admin_console.healthCheckEnabled` feature flag
- **Issue**: The feature flag is read from Firestore on every banner request when the user is `super_admin`. Acceptable for current admin volume but adds a Firestore read per request.
- **Suggested fix**: Consider request-scoped or short-TTL cache if admin volume increases.
- **Estimated**: 1 hour (if needed)
- **Created**: 2026-05-02
- **Status**: Accepted — revisit if admin traffic grows

### P3 deploy_channel reports preview on production

**File:** affects `/api/admin/health/config` response  
**Symptom:** After production deploy 2026-05-04, the `deploy_channel` field in the health config response returns `"preview"` even when accessed via `wain-admin.web.app` (production URL).  
**Root cause (suspected):** Build env vars from preview channel deploy carried over into production deploy because both used the same `.firebase/wain-admin/functions` packaged artifact.  
**Impact:** Cosmetic only. No functional impact. Real `step_up_enforcement_mode` is correctly reported as `enabled`.  
**Fix:** Investigate which env var sets `deploy_channel` in admin_web_console health config endpoint. Either:
- (a) Read from `NEXT_PUBLIC_DEPLOY_CHANNEL` and default to `"production"` when missing.
- (b) Detect via runtime hostname comparison in the API route.
**Priority:** P3 — fix before next deploy or any user-facing display of this field.

 # #   A W C - Q A - 0 1 2   P h a s e   2   f o l l o w - u p s 
 
 # # #   P 3   A W C - Q A - 0 1 2   c o n t e n t   r e v i e w   m i g r a t i o n 
 N o   s t a n d a l o n e   c o n t e n t   r e v i e w   d i a l o g   f o u n d   i n   a d m i n _ w e b _ c o n s o l e   a t   t i m e   o f   P h a s e   2   m i g r a t i o n .   W h e n   s u c h   a   s u r f a c e   i s   a d d e d   ( e . g . ,   f o r   m e d i a   m o d e r a t i o n   o r   c o n t e n t   a p p r o v a l   w o r k f l o w s ) ,   i t   s h o u l d   u s e   R e v i e w A f f o r d a n c e D i a l o g   f r o m   t h e   s t a r t .  
 

### P2 Step-up signing key rotation runbook

**Status:** Not yet documented or tested. Production currently runs with a single signing key (no previous key configured, intentional).

**Why this matters:**
- The ``step_up_previous_key_present`` health check warns by design until a rotation is performed.
- Rotation is needed periodically (90-day cadence recommended) for cryptographic hygiene.
- Without a tested procedure, an emergency rotation would be high-risk.

**Required runbook content:**
1. Generate next signing key (use ``crypto.randomBytes(32)`` or equivalent, stored in Secret Manager).
2. Update Firestore ``app_config/admin_step_up`` to add ``nextSigningKey`` and rotation timestamp.
3. Switch: ``currentSigningKey`` -> ``previousSigningKey``, ``nextSigningKey`` -> ``currentSigningKey``.
4. Verify both old and new tokens validate during grace period (e.g., 5 minutes).
5. After grace period, optionally remove ``previousSigningKey``.
6. Verify ``step_up_previous_key_present`` health check moves from warn to ok (then back to warn after grace).

**Rollback:**
- If new key fails to issue/verify, revert ``currentSigningKey`` immediately in Firestore.
- Sessions with new key tokens will need re-authentication.

**Suggested timing:**
- Plan during low-traffic window (e.g., 03:00-05:00 Hebron).
- Coordinate with all 3 admins.
- Have backup of all 3 keys (current/previous/next) before swapping.

**Priority:** P2 — important for security hygiene, not urgent for functionality.
