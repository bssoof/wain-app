# Admin Web Console Incident Drill Review

## 1. Drill Snapshot
- Date: `2026-04-11`
- Scope: `AWC-P7-01 - Hardening and release gate baseline`
- Evidence type: emulator drills + source audit + web regression/build verification
- Verdict: `baseline ready for staging rehearsal`

## 2. Drill Scenarios Reviewed

### Drill A - Duplicate processing under contention
Evidence:
- `securityConcurrencyFlows.test.js` -> `4/4`
- `securityCallableFlows.test.js` includes idempotent replay and expected-state coverage for finance/config/reviews/media/content

Observed result:
- concurrent claim/redeem/invite flows converge to one valid final outcome
- duplicate processing is blocked by transaction/idempotency behavior
- emulator lock-timeout warnings appeared during contention and are expected side effects of the concurrency test design, not failures

Verdict:
- pass

### Drill B - Role escalation and actor separation
Evidence:
- `securityCallableFlows.test.js` -> `97/97`
- notable checks:
  - reversal second-approver and same-actor blocking (`W47-W52`)
  - media action denial for non-admin (`W56`, `W58`)
  - reviews moderation denial and escalation behavior (`W61-W65`)
  - config publish/rollback role enforcement (`W66-W70`)
  - content moderation denial for non-content roles (`CM03`, `CM07`)

Observed result:
- no broken role escalation path was detected in the verified emulator suites

Verdict:
- pass

### Drill C - Hidden direct write audit
Evidence:
- source audit over `admin_web_console` application code returned no direct Firestore write API usage outside dependencies

Observed result:
- privileged writes are routed through loaders and command transports, not browser-side Firestore mutation APIs

Verdict:
- pass

### Drill D - Config misconfiguration and rollback
Evidence:
- `securityCallableFlows.test.js` checks `W66-W70`

Observed result:
- invalid config payloads are rejected
- publish requires review + expected-state alignment
- rollback restores historical config through governed server-side flow

Verdict:
- pass

### Drill E - Content and media safety workflows
Evidence:
- `contentModerationCallableFlows.test.js` -> `10/10`
- `securityCallableFlows.test.js` checks `W55-W60` and `W61-W65`

Observed result:
- content moderation reasons normalize correctly
- media destructive actions remain server-authorized
- purge is blocked when reference-index health is not acceptable

Verdict:
- pass

## 3. What This Drill Review Proves
- Duplicate processing is covered explicitly, not assumed.
- The most sensitive escalation paths are tested on the server-authorized path.
- Admin web is not secretly mutating protected state directly.
- The operator now has checklist/runbook documents to use instead of relying on tribal knowledge.

## 4. What This Drill Review Does Not Yet Prove
- It does not prove live staging transport health for:
  - `/admin/config`
  - `/admin/media`
  - `/admin/content/*`
- It does not replace a human-operated staging rehearsal under real env configuration.

## 5. Recommendation
- Proceed to `P7-02` as a staging/operator rehearsal and final Phase 7 acceptance step.
- Do not claim go-live readiness before the pending staging callable transport rehearsal is recorded.
