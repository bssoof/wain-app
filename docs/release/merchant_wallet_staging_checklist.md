# Merchant Wallet Staging Checklist

Run this checklist in order with no shortcuts.

## 1. Evidence Header (fill before run)
- Run id:
- Environment / project id:
- Operator:
- Start time (UTC):
- Expected deploy revision:

## 2. Setup
1. From `functions/` run:
   - `npm run build`
   - `npm run wallet:verify-env`
2. If verify status is `FAIL`, stop and fix before proceeding.
3. If pricing is missing, use guarded seeding only:
   - `npm run wallet:seed-config -- --dry-run`
   - `npm run wallet:seed-config -- --fail-if-exists`
   - `npm run wallet:verify-env`

## 3. Deploy Sequence Validation
Verify deploy was executed in this exact order:
1. `firestore.rules`
2. `storage.rules`
3. `firestore.indexes.json`
4. `functions`

Record:
- Rules deploy log path:
- Storage deploy log path:
- Index deploy log path:
- Functions deploy log path:

## 4. Flow Evidence Format (required per flow)
For each flow below, capture:
- `requestId`
- `entryId` (if applicable)
- `venueId`
- Screenshot reference (UI or API evidence file)
- Notification result (count + type + target)

## 5. Top-Up Create / Approve / Reject
1. Merchant creates top-up request with proof.
2. Confirm request is `pending`.
3. Admin approves request.
4. Confirm:
   - request is `credited`,
   - `linked_entry_id` exists,
   - wallet balance increased,
   - credit entry exists.
5. Merchant creates second top-up request.
6. Admin rejects with note.
7. Confirm:
   - request is `rejected`,
   - `admin_note` exists,
   - no balance increase from rejected request.

## 6. Story Promotion Debit
1. Ensure sufficient wallet balance.
2. Call `promoteStory` with fresh `requestId`.
3. Confirm single debit entry (`feature_key=story_promotion`).
4. Retry with same `requestId`.
5. Confirm idempotency (no second debit).

## 7. Offer Pin Debit
1. Ensure sufficient wallet balance.
2. Call `pinOffer` with fresh `requestId`.
3. Confirm single debit entry (`feature_key=offer_pin`).
4. Retry with same `requestId`.
5. Confirm idempotency (no second debit).

## 8. Insufficient Balance
1. Lower wallet balance below required price.
2. Attempt `promoteStory` and `pinOffer`.
3. Confirm both fail with `insufficient_wallet_balance`.
4. Confirm no partial writes:
   - no new debit entries,
   - no unintended feature-state updates.

## 9. Reversal Flow
1. Choose one eligible debit entry.
2. Admin runs `reverseWalletEntry`.
3. Confirm:
   - `reversal_{entryId}` credit entry exists,
   - original entry has `reversal_entry_id`,
   - balance is restored,
   - related promoted/featured state is reverted.
4. Retry same reversal.
5. Confirm second attempt is blocked.

## 10. Expiry Reminder
1. Seed expiring promoted story and expiring featured offer within reminder window.
2. Run reminder maintenance.
3. Confirm notifications:
   - `wallet_story_promotion_expiring`
   - `wallet_offer_pin_expiring`

## 11. Lifecycle Cleanup
1. Seed expired promoted story, expired featured offer, and expired proof retention record.
2. Run lifecycle maintenance.
3. Confirm:
   - expired `is_promoted` and `is_featured` are cleared,
   - proof path removed from Firestore,
   - proof deletion audit fields are populated,
   - internal proof file deletion succeeded when applicable.

## 12. Final Sign-Off
1. Call `verifyWalletOperationalReadiness` from admin context.
2. Decision logic:
   - `FAIL`: no-go.
   - `WARN`: conditional go only with documented rationale.
   - `PASS`: proceed to soft launch gate.
3. Attach evidence artifacts to release ticket.

## 13. Phase 16 Recorded Execution
Reference completed evidence:
- `docs/release/merchant_wallet_staging_evidence_log.json`
- `docs/release/merchant_wallet_staging_evidence_log.md`
