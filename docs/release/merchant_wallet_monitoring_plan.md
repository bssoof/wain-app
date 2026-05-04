# Merchant Wallet Monitoring Plan

## 1. Purpose
- Detect financial and operational risk early during soft launch.
- Define thresholds that convert raw logs into actionable incidents.

## 2. Signal Sources
Primary sources:
- Cloud Functions logs (`logSecurityAudit` events),
- Firestore wallet/audit collections,
- release evidence artifacts.

Key log events to monitor daily:
- `topup_request_created`
- `topup_request_approved`
- `topup_request_rejected`
- `story_promotion_debited`
- `offer_pin_debited`
- `wallet_entry_reversed`
- `insufficient_wallet_balance`
- `wallet_operational_readiness_failed`
- `wallet_operational_readiness_warned`

## 3. KPI Definitions
- Approval turnaround time:
  - median minutes from request creation to approval/rejection.
- Top-up approval rate:
  - `approved / (approved + rejected)`.
- Debit success rate:
  - successful debit events divided by debit attempts.
- Reversal rate:
  - `wallet_entry_reversed / (story_promotion_debited + offer_pin_debited)`.
- Low-balance pressure:
  - count of `insufficient_wallet_balance` events per day.
- Reminder effectiveness (if measurable):
  - reminder notifications that lead to successful renewal action within 24h.

## 4. Thresholds and Incident Levels
| Metric / Signal | Threshold | Severity | Action |
| --- | --- | --- | --- |
| `wallet_operational_readiness_failed` | >= 1 in any day | SEV-1 | stop new cohort additions, investigate immediately |
| duplicate debit evidence | >= 1 confirmed case | SEV-1 | initiate rollback protocol |
| balance drift evidence | >= 1 confirmed case | SEV-1 | initiate rollback protocol |
| reversal rate | > 5% daily | SEV-2 | incident review, pause cohort expansion |
| top-up rejection rate | > 30% daily | SEV-2 | review fraud/UX/admin handling |
| approval turnaround p95 | > 4 business hours | SEV-2 | scale reviewer coverage |
| `insufficient_wallet_balance` | > 15/day soft-launch cohort | SEV-3 | review pricing/top-up UX |
| repeated readiness WARN after proven usage | > 1 consecutive day | SEV-2 | investigate reporting/reminder data pipeline |

## 5. Alerting Policy
- SEV-1:
  - immediate on-call page,
  - launch freeze,
  - rollback decision within 60 minutes.
- SEV-2:
  - same-day investigation,
  - no cohort expansion until resolved.
- SEV-3:
  - track and resolve in next daily operations review.

## 6. Daily Monitoring Checklist
1. Check readiness signals (`failed`, `warned`, `passed`).
2. Compare top-up created vs approved vs rejected counts.
3. Compare debit counts vs reversal counts.
4. Review insufficient-balance spikes.
5. Confirm no duplicate-debit or balance-drift reports.
6. Record daily summary in release ticket.

## 7. Rollback Link
If SEV-1 threshold is hit, execute rollback actions from `merchant_wallet_release_runbook.md`.

## 8. Phase 16 Baseline Snapshot
From `merchant_wallet_staging_evidence_log.json` (run `phase16_1775693355141`):
- `topup_request_created`: 2
- `topup_request_approved`: 1
- `topup_request_rejected`: 1
- `story_promotion_debited`: 1
- `offer_pin_debited`: 1
- `wallet_entry_reversed`: 1
- `insufficient_wallet_balance`: 1
- `wallet_operational_readiness_failed`: 0
- `wallet_operational_readiness_warned`: 1 (before checklist)
- `wallet_operational_readiness_passed`: 1 (after checklist)
