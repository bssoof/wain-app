# AWC-QA-007 Top-Up Confirmation Design

## Goal
Add an explicit confirmation step before sensitive top-up finance commands:
- `approve_topup`
- `reject_topup`

This is an intent-safety layer. It does not replace step-up auth. Step-up proves the admin identity; confirmation proves the admin intentionally reviewed the specific top-up request and chose the action.

## Current State
The current top-up queue executes commands directly from row buttons in `admin_web_console/components/finance/topup-queue-table.tsx`.

Current flow:
1. Admin clicks approve or reject.
2. `TopUpQueueTable` builds a command request with `buildApproveTopUpRequest()` or `buildRejectTopUpRequest()`.
3. `FinanceCommandProvider.runCommand()` enforces finance step-up when needed.
4. The proxy/callable receives the command.
5. On success, `router.refresh()` reloads the queue.

Existing strengths:
- `commandId` already acts as the idempotency key.
- `expectedState` already guards stale pending/unreviewed rows.
- Step-up is centralized in `FinanceCommandProvider`.
- Reject already maps `reason` into `adminNote` when no explicit note is passed.

Current weakness:
- A single click can submit a financial decision without a final summary.
- The reason is a default string, not an operator-visible decision.
- Runtime retry for top-ups can rebuild a new command request unless the implementation preserves the submitted request.

## Proposed UX
Clicking approve or reject opens a confirmation panel/dialog instead of executing immediately.

The confirmation surface must show:
- Action: approve or reject.
- Top-up request id.
- Owner/user name and user id.
- Venue id.
- Amount and currency.
- Provider reference.
- Created date.
- Expected resulting state.

Inputs:
- Decision reason: required.
- Admin note: optional for approve, required for reject when reason is `other`.

Suggested reason keys:
- Approve: `payment_verified`, `manual_finance_review`, `provider_reference_matched`, `other`.
- Reject: `payment_not_verified`, `duplicate_request`, `incorrect_amount`, `provider_reference_invalid`, `manual_review_failed`, `other`.

Arabic labels can live near the component at first. Avoid adding a new localization system for this PR unless the project already has a finance reason dictionary.

## Execution Flow
1. Row action button sets local pending decision state:
   - `{ action, topUpRequest, runtimeKey }`
2. Confirmation dialog renders the row snapshot and validation inputs.
3. On confirm, build exactly one command request:
   - `buildApproveTopUpRequest(request, { reason, adminNote })`
   - `buildRejectTopUpRequest(request, { reason, adminNote })`
4. Store that built request as the active submitted request for this dialog/runtime key.
5. Call `runCommand(runtimeKey, action, builtRequest)`.
6. While pending, disable confirm/cancel and set `aria-busy`.
7. On success, close dialog and call `router.refresh()`.
8. On failure, keep enough state to retry safely.

## Idempotency And Retry Rule
For the same confirmed submission, retries must reuse the same built command request and therefore the same `commandId`.

Do not call `buildApproveTopUpRequest()` or `buildRejectTopUpRequest()` again from a retry path for the same failed submission. Rebuilding creates a new idempotency key and weakens protection against timeout/unknown-result scenarios.

Recommended behavior:
- Retry inside the active confirmation dialog reuses `activeSubmittedRequest`.
- If the admin closes the dialog, any later action is a new intentional submission and may generate a new `commandId`.
- Existing row-level `CommandRuntimeCallout` retry should either reuse the last submitted request or reopen the confirmation dialog. It must not silently execute with a newly generated request.

## Server-Side Validation
Client confirmation is UX and intent capture, not a security boundary.

Minimum backend/proxy expectation for this PR:
- Top-up commands must have a non-empty `reason`.
- Reject with reason `other` must have a non-empty `adminNote`.
- Invalid/missing fields should return `422 validation_error`.

If callable validation already enforces this, keep the proxy unchanged and add tests proving the adapter carries the fields. If not, add lightweight proxy validation in `app/api/admin/command/finance/route.ts` before invoking the callable.

## Files For Implementation
Expected files:
- `admin_web_console/components/finance/topup-queue-table.tsx`
- `admin_web_console/lib/finance/build-command-requests.ts` only if reason/note typing needs tightening
- `admin_web_console/components/finance/finance-surfaces.test.tsx`

Optional file if the component gets too large:
- `admin_web_console/components/finance/topup-confirmation-dialog.tsx`

Avoid changing:
- `FinanceCommandProvider` unless retry reuse cannot be handled locally.
- Step-up auth code.
- Callable transport surfaces beyond reason/note validation.

## Test Plan
Widget/component tests:
- Approve click opens confirmation and does not call transport.
- Confirmation summary shows id, user, venue, amount, provider reference, and action.
- Confirm approve sends `reason`, optional `adminNote`, `expectedState`, and `idempotencyKey`.
- Reject requires a reason and requires note for `other`.
- Cancel closes without executing.
- Confirm button is disabled or busy while command is pending.
- Success closes the dialog and calls `router.refresh()`.
- Failed submission leaves a visible error and does not lose the submitted request.
- Retry reuses the same `commandId`.
- Non-finance roles still cannot see mutation controls.

Transport/adapter tests:
- Approve top-up carries `reason` and `adminNote` to `reviewMerchantTopUpRequest`.
- Reject top-up carries `reason`, `adminNote`, `idempotencyKey`, and `expectedState`.

Security/regression tests:
- Missing reason returns validation failure if proxy validation is added.
- Step-up still appears after confirmation, not before it.
- `verify_wallet_readiness` remains excluded from top-up confirmation.

## Acceptance Criteria
- No top-up approve/reject command executes from a single row-button click.
- Every approve/reject requires an explicit confirmation.
- Every submitted top-up decision has an operator-visible reason.
- Double-clicking cannot submit duplicate commands.
- Retry for the same confirmed submission reuses the same `commandId`.
- Existing step-up behavior remains unchanged.
- `npm test` and `npm run build` pass.

## Open Decisions Before Coding
- Whether confirmation is an inline row panel, a shared modal, or a table-local dialog. Recommendation: table-local dialog to avoid a broad shared modal refactor.
- Whether reason keys become part of a shared finance dictionary now or stay local to the component for this PR. Recommendation: local constants first.
- Whether proxy validation is required depends on callable validation. Verify before implementation.
