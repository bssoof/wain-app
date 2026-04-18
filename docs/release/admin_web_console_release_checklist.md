# Admin Web Console Release Checklist

## 1. Decision Snapshot
- Date: `2026-04-19`
- Scope: `Post Phase 1 + Phase 2 (REL-1/REL-2) checkpoint`
- Decision: `NO_GO`
- Go-live status: `BLOCKED`
- Decision source: `docs/release/admin_web_console_full_launch_readiness_report_2026-04-19.md`

Reason:
- Security containment and release-confidence fixes for `REL-1` and `REL-2` have been applied and validated.
- The checklist decision is now gated by the latest readiness report recommendation and CI validation instead of static manual status text.
- Release remains blocked until remaining mandatory streams are closed (including privileged-token production path redesign under `SEC-3 Phase B`).

## 2. Release Gate Status

| Gate | Required | Evidence | Status |
| --- | --- | --- | --- |
| Admin web regression suite | Yes | `cd wain_app/admin_web_console && npm test` (latest CI/local artifact, no static count in checklist) | PASS |
| Admin web production build | Yes | `cd wain_app/admin_web_console && npm run build` | PASS |
| Functions TypeScript build | Yes | `cd wain_app/functions && npm run build` | PASS |
| Sensitive callable hardening suite | Yes | `securityCallableFlows.test.js` (latest artifact) | PASS |
| Content moderation callable suite | Yes | `contentModerationCallableFlows.test.js` (latest artifact) | PASS |
| Concurrency coverage baseline | Yes | `securityConcurrencyFlows.test.js` (latest artifact) | PASS |
| No hidden direct writes from admin web source | Yes | source audit over `admin_web_console` found no `setDoc/updateDoc/addDoc/deleteDoc/writeBatch/runTransaction/getFirestore` usage outside dependencies | PASS |
| Operator release runbook exists | Yes | `docs/release/admin_web_console_release_runbook.md` | PASS |
| Incident drill review exists | Yes | `docs/release/admin_web_console_incident_drill_review.md` | PASS |
| Service-account staging rehearsal for config/content/reviews/media callable logic | Yes for Phase 7 closure | `docs/release/admin_web_console_staging_evidence_log.json` on project `wain-d2e28` | PASS |
| Browser HTTP callable transport smoke for config/media/content | Yes before go-live | Authenticated rerun completed in `AWC-P7-F01D` with valid admin auth + App Check token; probes `16/16` returned `HTTP 200`. | PASS |
| Venue-filtered media inventory query index ready in staging | Yes before go-live claim on scoped media inventory | Backend/data-layer readiness from `AWC-P7-F01C` is now aligned with authenticated browser evidence from `AWC-P7-F01D`. | PASS |
| Release decision consistency check | Yes | `node scripts/validate_admin_release_checklist.mjs` | PASS |

## 3. Immediate No-Go Triggers
- Any duplicate processing finding in finance/content/media/config command paths.
- Any direct browser write to protected Firestore state instead of server-authorized callable execution.
- Broken role escalation path:
  - same actor can approve their own reversal,
  - non-content role can moderate content,
  - non-finance role can publish config,
  - read-only role can execute destructive media actions.
- Staging callable transport for `content`, `media`, or `config` returning unexpected `unavailable` or auth failures.
- Operator runbook cannot be executed under pressure without repository spelunking.

## 4. Completed Actions Before Go-Live
1. Browser HTTP staging smoke was rerun over:
   - `/admin/config`
   - `/admin/media`
   - `/admin/content/offers`
   - `/admin/content/stories`
   - `/admin/content/reviews`
2. The rerun was executed with:
   - valid admin auth token sourced from authenticated browser context
   - valid App Check token (non-placeholder)
3. Operator evidence was recorded in:
   - `docs/release/admin_web_console_browser_smoke_awc_p7_f01d.md`
   - `docs/release/admin_web_console_browser_smoke_awc_p7_f01d.json`
4. Venue-filtered media readiness was re-verified and aligned with backend-layer evidence from `AWC-P7-F01C`.
5. Final go/no-go decision is now validated against the latest readiness report via script gate.

## 5. Operator Acknowledgment Checklist
- The release operator has the runbook open before touching staging or production.
- The on-call owner for finance/config/content/media is known for the release window.
- Rollback authority is identified before release begins.
- Staging smoke is completed on the same artifact family intended for release.
- Any warning observed during rehearsal is documented before widening scope.

## 6. Current Recommendation
- `NO_GO`

Interpretation:
- This checklist is no longer allowed to self-declare go-live via static pass-count text snapshots.
- The recommendation remains blocked until all mandatory blocker streams are explicitly closed in readiness evidence.
- Rollout must stay frozen while any active blocker is open.
