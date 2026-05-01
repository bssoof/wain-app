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
