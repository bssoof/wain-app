# Merchant Wallet Go/No-Go Checklist

## 1. Decision Snapshot
- Date: `2026-04-09`
- Run id: `phase16_1775693355141`
- Environment: `wain-d2e28`
- Evidence source: `docs/release/merchant_wallet_staging_evidence_log.json`

## 2. Exit Criteria
| Criterion | Required | Result | Status |
| --- | --- | --- | --- |
| No balance drift incidents | Yes | No drift found in run | PASS |
| No duplicate charge incidents | Yes | Idempotency checks passed for story and offer debits | PASS |
| Admin review path stable | Yes | approve + reject flows both passed | PASS |
| Staging checklist reproducible | Yes | all scripted checklist checks passed | PASS |
| Readiness callable not failing | Yes | after-run status `PASS` | PASS |
| Merchant support volume acceptable | Yes | requires live soft-launch support tracking | PENDING |

## 3. Current Recommendation
- `CONDITIONAL_GO_SOFT_LAUNCH`

Reason:
- Technical and operational checks passed in staging rehearsal.
- Live support-volume criterion is not measurable until merchant cohort is enabled.

## 4. Required Actions Before Full Rollout
1. Enable Wave 1 soft-launch cohort (3 to 10 merchants) and record actual merchant IDs.
2. Run daily monitoring thresholds from `merchant_wallet_monitoring_plan.md`.
3. Keep wallet feature freeze active during soft launch.
4. Complete dedicated maintenance release for Firebase Functions dependency warning (`firebase-functions` upgrade), then run focused wallet smoke checks.
5. Promote to wider rollout only after support-volume criterion moves from `PENDING` to `PASS`.

## 5. Immediate No-Go Triggers
- duplicate debit,
- balance drift,
- readiness status `FAIL`,
- admin review path failures,
- pricing misconfiguration,
- broken reminder/cleanup behavior.
