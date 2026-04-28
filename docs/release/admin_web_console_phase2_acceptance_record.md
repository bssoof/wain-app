# Admin Web Console - Phase 2 Acceptance Record

Document ID: AWC-P2-AR
Round: AWC-P2-06
Decision date: 2026-04-10
Scope: Phase 2 closure for Finance Ops V1 only
Implementation status: accepted with follow-up

## 1. Final Phase 2 Verdict

Verdict: accepted with follow-up
Phase 2 state: closure accepted for Finance Ops V1 baseline, with explicit follow-up items that do not block opening Phase 3

Rationale:
- Phase 2 core finance surfaces are implemented and validated end-to-end:
  - Top-Up Review Queue
  - Wallet Audit
  - Reversal approval flow
  - Operational Readiness
- Finance command contracts, command policy, read adapters, server-authorized callable surfaces, and staging rehearsal evidence all exist and were validated.
- The strongest remaining gaps are operational UX/completeness gaps, not governance or financial integrity blockers:
  - dashboard finance widgets are still placeholder-only
  - queue aging is not yet surfaced explicitly in the admin UI
  - export governance is documented but CSV export is not yet implemented in the web console

## 2. Phase 2 Acceptance Checklist

Reference: `docs/release/admin_web_console_execution_plan.md` -> `Phase 2 - Finance Ops V1`

| Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| approve/reject آمنة ضد التكرار | accepted | `functions/src/index.ts`; web command contracts in `admin_web_console/lib/finance/command-contracts.ts`; staging evidence `flows.topupApprove` and `flows.topupReject`; emulator/web tests recorded in tracker entries `014`-`018` | idempotent command envelope and expected state propagation are in place |
| reversal آمنة ومؤرشفة | accepted | `reverseWalletEntry` + `approveWalletReversalRequest` in `functions/src/index.ts`; emulator tests `W27-W33`, `W47-W52`; staging evidence `flows.reversal` and `flows.reversalDualApproval` | dual approval, same-actor block, super-admin threshold, audit linkage all evidenced |
| queue aging ظاهر | accepted with follow-up | Top-Up Queue UI exists in `admin_web_console/app/(protected)/admin/topups/page.tsx` and `components/finance/topup-queue-table.tsx` | queue rows and command states are visible, but explicit aging/SLA indicators are not yet implemented |
| readiness panel صحيحة | accepted | `admin_web_console/app/(protected)/admin/readiness/page.tsx`; callable + adapters; staging evidence `readiness.before/after.overallStatus = PASS` | readiness panel is executable and backed by real callable reads |
| كل أمر مالي يستخدم command model الجديد | accepted | command contracts/client/policy/adapters under `admin_web_console/lib/finance/*`; callable transport mapping; tracker entries `005`-`016` | command layer is explicit and shared across finance surfaces |
| conflict handling واضح عند concurrent admin actions | accepted | runtime states and callouts in finance UI; `surface-affordances.ts`; `CommandRuntimeCallout`; reversal/top-up command tests | conflict/unavailable/pending states are rendered explicitly without silent failure |
| export المالي role-gated ولا يتاح لـ `ops_viewer` أو `support_admin` | accepted with follow-up | export governance is locked in Phase 0 docs only | policy exists, but no executable CSV export surface is implemented yet |
| الإشارات التشغيلية الأساسية تظهر ويمكن مراقبتها بدون Firebase Console | accepted with follow-up | staging evidence log `merchant_wallet_staging_evidence_log.json`; monitoring signals written by rehearsal; tracker entries `017`-`018` | signals exist and are observable through evidence/logging, but dashboard-level operator widgets are still missing |

## 3. Implemented Scope (Phase 2)

- Finance command layer:
  - `admin_web_console/lib/finance/command-contracts.ts`
  - `admin_web_console/lib/finance/command-policy.ts`
  - `admin_web_console/lib/finance/command-client.ts`
  - `admin_web_console/lib/finance/finance-command-transport.ts`
  - `admin_web_console/lib/finance/finance-command-adapters.ts`
- Finance read layer:
  - `admin_web_console/lib/finance/finance-read-transport.ts`
  - `admin_web_console/lib/finance/finance-read-adapters.ts`
  - `admin_web_console/lib/finance/finance-read-loader.ts`
  - `admin_web_console/lib/finance/finance-read-snapshot-transport.ts`
- Finance UI surfaces:
  - `admin_web_console/app/(protected)/admin/topups/page.tsx`
  - `admin_web_console/app/(protected)/admin/wallet-audit/page.tsx`
  - `admin_web_console/app/(protected)/admin/readiness/page.tsx`
  - `admin_web_console/app/(protected)/admin/reversals/page.tsx`
  - `admin_web_console/components/finance/*`
- Backend callable/read/mutation surfaces:
  - `functions/src/index.ts`
  - `listMerchantTopUpRequestsForAdmin`
  - `listMerchantWalletLedgerEntriesForAdmin`
  - `verifyWalletOperationalReadiness`
  - `reverseWalletEntry`
  - `approveWalletReversalRequest`
- Staging rollout and rehearsal:
  - `functions/scripts/verify_wallet_env.js`
  - `functions/scripts/run_wallet_staging_rehearsal.js`
  - `docs/release/merchant_wallet_staging_evidence_log.json`

## 4. Verified Evidence

### Backend verification

- `cd wain_app/functions && npm run build`
  - Result: passed
- Emulator subset verification:
  - `W27-W33`
  - `W45/W45b/W46`
  - `W47-W52`
  - Result: `16/16` passed

### Admin web verification

- `cd wain_app/admin_web_console && npm test`
  - Result: passed
  - Latest verified count in tracker: `85/85`
- `cd wain_app/admin_web_console && npm run build`
  - Result: passed

### Staging rollout verification

- deploy:
  - `firebase deploy --only "functions,firestore" --project wain-d2e28`
  - later `firebase deploy --only "functions" --project wain-d2e28`
  - Result: passed
- environment verification:
  - `cd wain_app/functions && npm run wallet:verify-env`
  - Result: `PASS`
- staging rehearsal:
  - `cd wain_app/functions && npm run wallet:staging-rehearsal`
  - Result: passed after ADC-safe local auth path and storage bucket resolution fix
- evidence log:
  - `docs/release/merchant_wallet_staging_evidence_log.json`
  - key results:
    - `bucketName = wain-d2e28.firebasestorage.app`
    - `readiness.before.overallStatus = PASS`
    - `readiness.after.overallStatus = PASS`
    - `flows.reversalDualApproval.checks.pendingSecondApprovalReturned = true`
    - `flows.reversalDualApproval.checks.sameActorBlocked = true`
    - `flows.reversalDualApproval.checks.secondActorApprovalSucceeded = true`
    - `goNoGoChecklist.stagingChecklistReproducible = true`
    - `goNoGoChecklist.overallRecommendation = CONDITIONAL_GO_SOFT_LAUNCH`

## 5. Explicit Gaps Still Not Closed

The following are real gaps and are intentionally not hidden:

- Finance dashboard widgets are not implemented yet.
  - `admin_web_console/app/(protected)/admin/dashboard/page.tsx` is still placeholder-only.
- Top-Up Queue does not yet expose explicit aging/SLA indicators in the UI.
- CSV/export surfaces are not implemented yet, even though the governance policy is documented.
- Operator-facing observability is available through logs/evidence, but not yet surfaced as dedicated admin dashboard widgets.

## 6. Follow-up Items Before/Alongside Phase 3

| Item ID | Follow-up | Owner role | Target phase | Status |
| --- | --- | --- | --- | --- |
| P2-F01 | Add finance dashboard widgets (`pending top-ups`, `aged pending`, `reversals today`, readiness summary) | Web Engineering Lead | Phase 2 follow-up / early Phase 3 | open |
| P2-F02 | Add explicit queue aging/SLA indicator to Top-Up Queue UI | Web Engineering Lead | Phase 2 follow-up / early Phase 3 | open |
| P2-F03 | Implement governed CSV export for Top-Up Queue and Wallet Audit with role gating and audit trail | Web Engineering Lead + Backend Lead | Phase 2 follow-up / early Phase 3 | open |
| P2-F04 | Document or automate the temporary ADC-based staging smoke path for reproducibility on another machine | Platform Owner | Phase 2 follow-up | open |

## 7. Closure Statement

Phase 2 is formally closed as `accepted with follow-up`.

This closure confirms:
- Finance Ops V1 core read + command surfaces are implemented and auditable.
- Financial integrity, authorization, idempotency, dual approval, and staging rollout evidence are strong enough to move forward.
- Remaining work is visible and scoped; it is not hidden behind a false `done` state.
