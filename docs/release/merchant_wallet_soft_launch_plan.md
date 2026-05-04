# Merchant Wallet Soft Launch Plan

## 1. Objective
- Release wallet capabilities to a tightly controlled merchant cohort before wider rollout.
- Protect financial integrity while validating real operational behavior.

## 2. Soft Launch Scope
Enabled features for soft launch:
- top-up request create/review,
- story promotion debit,
- offer pin debit,
- reversal recovery path,
- reminder and lifecycle maintenance.

Out of scope during soft launch:
- new wallet feature development,
- pricing experiments,
- broad merchant onboarding.

## 3. Cohort Policy
- Cohort size: minimum 3, maximum 10 merchants.
- Cohort profile: internal or highly responsive merchants.
- Expansion policy: add at most 2 merchants per expansion wave.

## 4. Cohort Register (Wave 1)
Fill this table before enabling in production-facing workflows.

| Merchant UID | Venue ID | Owner | Added At (UTC) | Status |
| --- | --- | --- | --- | --- |
| nXjz8rD7xJWTUJ6DL1AL5vBRyLA3 | azure_01 | Vanilla Cafe | 2026-04-09T00:00:00Z | enabled |
| TBD_INTERNAL_02 | TBD | Ops | TBD | pending |
| TBD_INTERNAL_03 | TBD | Ops | TBD | pending |

Status values:
- `pending`: selected but not active.
- `enabled`: merchant can actively use wallet paid features.
- `paused`: temporarily blocked from new wallet actions.
- `removed`: removed from soft-launch cohort.

## 5. Enablement Checklist
Per merchant:
1. Confirm merchant support contact channel.
2. Confirm admin review SLA coverage.
3. Confirm wallet config and readiness are healthy (`verifyWalletOperationalReadiness` not `FAIL`).
4. Confirm merchant is added to Wave 1 register with `enabled` status.
5. Record activation time in release ticket.

## 6. Support and SLA
- Admin top-up review SLA target: less than 4 business hours.
- Critical wallet incident acknowledgement: less than 30 minutes.
- Critical wallet incident mitigation start: less than 60 minutes.
- Support channels:
  - Primary: internal ops channel + on-call owner.
  - Secondary: merchant success escalation channel.

## 7. Change Freeze
During soft launch:
- Freeze new wallet features and schema changes.
- Allow only:
  - bug fixes,
  - monitoring improvements,
  - rollback/hotfix actions.

## 8. Daily Operating Cadence
Daily at start of business window:
1. Review monitoring thresholds from `merchant_wallet_monitoring_plan.md`.
2. Review previous day incidents and reversal count.
3. Confirm readiness callable status (`FAIL` is immediate escalation).
4. Decide:
   - keep cohort size,
   - pause additions,
   - or roll back.

## 9. Rollback Trigger Linkage
Immediate pause of new cohort additions if any trigger occurs:
- duplicate debit,
- balance drift,
- admin review failure,
- pricing misconfiguration,
- reminder/cleanup malfunction.

Rollback action details are in `merchant_wallet_release_runbook.md`.

## 10. Exit Criteria To Wider Rollout
All must be true:
- no balance drift incidents,
- no duplicate charge incidents,
- stable admin review path,
- staging checklist reproducible,
- readiness callable not failing,
- merchant support volume acceptable,
- non-blocking maintenance debt for `firebase-functions` version warning is closed via a dedicated maintenance release.

If any item is not met, extend soft launch and fix root causes first.
