# Merchant Wallet Staging Evidence Log

## 1. Run Metadata
- Run id: `phase16_1775693355141`
- Date: `2026-04-09`
- Project: `wain-d2e28`
- Storage bucket used by run: `wain-d2e28.firebasestorage.app`
- Operator mode: script-driven backend rehearsal with callable auth/app context
- Raw evidence artifact: `docs/release/merchant_wallet_staging_evidence_log.json`

## 2. Pre-Deploy / Deploy Evidence
Pre-deploy:
- `npm run build`: pass
- initial `npm run wallet:verify-env`: fail due missing `wallet_feature_pricing/default`
- guarded seed performed:
  - dry-run pass
  - write pass (`existed=false`)
  - post-seed verify status: `WARN`

Deploy order (completed in required order):
1. firestore rules: pass
2. storage rules: pass
3. firestore indexes: pass
4. functions: pass

Functions deploy log:
- `docs/release/phase16_functions_deploy_output.log`

## 3. Readiness Transition
- Before checklist: `WARN`
  - warnings: `read_models`, `wallet_defaults`, `notifications`
- After checklist: `PASS`
  - pricing/read-models/notifications/wallet-defaults all `PASS`

## 4. Flow Evidence
| Flow | requestId | entryId | venueId | Screenshot | Notification Result |
| --- | --- | --- | --- | --- | --- |
| Top-up approve | `plw7aiucfypmJexWO10T` | `i9iTTCdjUnKTJcgEyond` | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | merchant approved notifications: 1 |
| Top-up reject | `NX8oxGcvNLX1kSJoYNnN` | N/A | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | merchant rejected notifications: 1 |
| Story promotion debit | `phase16_1775693355141_story_debit` | `story_promotion_phase16_1775693355141_story_debit` | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | low balance notifications: 0 |
| Offer pin debit | `phase16_1775693355141_offer_debit` | `offer_pin_phase16_1775693355141_offer_debit` | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | low balance notifications: 0 |
| Insufficient balance | `phase16_1775693355141_story_insufficient` / `phase16_1775693355141_offer_insufficient` | N/A | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | no new debit entries: true |
| Reversal | `phase16_1775693355141_offer_debit` | `offer_pin_phase16_1775693355141_offer_debit` | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | reversal notifications: 1 |
| Expiry reminder | N/A | N/A | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | story reminder: 1, offer reminder: 1 |
| Lifecycle cleanup | `topup_cleanup_phase16_1775693355141` | N/A | `venue_phase16_1775693355141` | N/A (script-run backend rehearsal) | cleanup ran: true |

## 5. Monitoring Signal Counts (Run Scope)
- `topup_request_created`: 2
- `topup_request_approved`: 1
- `topup_request_rejected`: 1
- `story_promotion_debited`: 1
- `offer_pin_debited`: 1
- `wallet_entry_reversed`: 1
- `insufficient_wallet_balance`: 1
- `wallet_operational_readiness_failed`: 0
- `wallet_operational_readiness_warned`: 1
- `wallet_operational_readiness_passed`: 1

## 6. Checklist Verdict
- End-to-end checklist reproducible: `true`
- Duplicate charge detected: `false`
- Balance drift detected: `false`
- Final readiness callable status: `PASS`
- Recommendation from run: `CONDITIONAL_GO_SOFT_LAUNCH`
