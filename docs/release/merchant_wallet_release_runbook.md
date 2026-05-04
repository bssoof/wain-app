# Merchant Wallet Release Runbook

## 1. Purpose
- Move wallet backend from implemented to safely released with strict operational discipline.
- Cover deploy order, staged validation, soft-launch guardrails, monitoring, and rollback.

## 2. Financial Safety Guardrails
- Ledger is append-only: never mutate historical debit rows.
- Incident correction must use reversal (`reverseWalletEntry`), not manual balance edits.
- Treat readiness statuses differently:
  - `FAIL`: release blocker.
  - `WARN`: acceptable only with explicit operator sign-off and documented rationale.
- Do not seed pricing over an approved environment unless the document is missing or intentionally changing.

## 3. Release Inputs
- Deploy files:
  - `firestore.rules`
  - `storage.rules`
  - `firestore.indexes.json`
  - `functions/` build artifact set
- Operator docs:
  - `docs/release/merchant_wallet_staging_checklist.md`
  - `docs/release/merchant_wallet_soft_launch_plan.md`
  - `docs/release/merchant_wallet_monitoring_plan.md`
  - `docs/release/merchant_wallet_staging_evidence_log.md`
  - `docs/release/merchant_wallet_go_no_go_checklist.md`

## 4. Pre-Deploy Preparation
1. Confirm branch/worktree status and note unrelated in-flight changes.
2. Run required checks from `functions/`:
   - `npm run build`
   - `npm run wallet:verify-env`
3. If `wallet:verify-env` returns `FAIL`:
   - stop release,
   - resolve root cause,
   - re-run verification before deploying.

## 5. Mandatory Deploy Order
Run from project root (`wain_app/`) with explicit project id.

1. Firestore rules
   - `firebase deploy --project <project-id> --only firestore:rules`
2. Storage rules
   - `firebase deploy --project <project-id> --only storage`
3. Firestore indexes
   - `firebase deploy --project <project-id> --only firestore:indexes`
4. Functions
   - `firebase deploy --project <project-id> --only functions`

Deployment notes:
- Do not accept index deletions blindly. If deploy proposes deleting existing indexes/overrides, reconcile `firestore.indexes.json` first.
- Keep rules/index/function revision alignment in one release window to avoid runtime mismatches.

## 6. Post-Deploy Steps
1. Seed pricing only if missing:
   - `cd functions`
   - `npm run wallet:seed-config -- --dry-run`
   - `npm run wallet:seed-config -- --fail-if-exists`
2. Re-verify environment:
   - `npm run wallet:verify-env`
3. Run admin readiness callable:
   - `verifyWalletOperationalReadiness` from admin context.
4. Proceed only if:
   - no `FAIL`,
   - and any `WARN` has explicit operator acceptance.

## 7. Phase 16 Execution Evidence (2026-04-09)
Project: `wain-d2e28`

Executed results:
- `npm run build`: pass.
- Initial `npm run wallet:verify-env`: fail due missing `wallet_feature_pricing/default`.
- Guarded seed sequence:
  - dry-run pass,
  - write mode pass (`existed=false`),
  - post-seed `wallet:verify-env` status `WARN` (admin fallback doc missing).
- Ordered deploy completed:
  - firestore rules: pass,
  - storage rules: pass,
  - firestore indexes: pass,
  - functions: pass.
- Additional index alignment deploy completed after repository reconciliation to avoid deletion drift.
- `verifyWalletOperationalReadiness`:
  - before staging run: `WARN`,
  - after staging run: `PASS`.

Evidence artifacts:
- `docs/release/phase16_functions_deploy_output.log`
- `docs/release/merchant_wallet_staging_evidence_log.json`
- `docs/release/merchant_wallet_staging_evidence_log.md`
- `docs/release/merchant_wallet_go_no_go_checklist.md`

## 8. Rollback Triggers
Immediate rollback evaluation if any of the following occurs:
- duplicate debit,
- wrong balance update / balance drift,
- admin review path failure,
- pricing misconfiguration,
- reminder or lifecycle maintenance malfunction.

## 9. Rollback Actions
1. Stop adding new merchants to rollout cohort.
2. Roll back functions to last known-good revision if needed.
3. Preserve all ledger history.
4. Correct financial incidents via compensating reversal entries only.
5. Re-run:
   - `npm run wallet:verify-env`
   - `verifyWalletOperationalReadiness`
   - focused subset from staging checklist.

## 10. Exit Gate To Wider Rollout
Wider rollout is allowed only when all are true:
- no balance drift incidents,
- no duplicate charge incidents,
- admin review path stable,
- staging checklist reproducible,
- readiness callable not failing,
- support volume acceptable.

If any gate is unmet, extend soft launch and fix root causes first.
