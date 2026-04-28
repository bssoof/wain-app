# Merchant Release Readiness Checklist

This checklist is the go/no-go gate for the full merchant feature release after `P0a -> P4b`.

## RR0. Candidate And Freeze

### Current baseline
- Date: `2026-04-05`
- Branch: `main`
- Current candidate ref: `c6556cef5cd74115c31f5cbd4990f3e65f977a7f`
- Worktree state: `DIRTY`

### RR0 blockers to resolve before sign-off
- Exclude or separately manage unrelated transport changes before merchant sign-off.
- Remove or ignore local emulator screenshot artifacts from the release candidate.
- Confirm one build candidate only for the readiness round.
- Confirm real consumer account and QR/token for full scan/redeem smoke.

### RR0 checklist
- [x] Freeze merchant scope until readiness is complete.
- [x] Decide the exact build candidate to test.
- [x] Confirm Android physical device for smoke.
- [ ] Confirm iPhone device if available.
- [x] Confirm merchant test account.
- [ ] Confirm consumer test account.
- [x] Confirm one venue with known baseline data:
  - active offer
  - at least one unanswered review
  - known hours configuration
  - known menu state
  - known photos/profile/story state

Notes:
- Candidate validated from local branch `main` at `c6556cef5cd74115c31f5cbd4990f3e65f977a7f`.
- Worktree is still `DIRTY` and includes unrelated `transport` changes plus local emulator screenshot artifacts; this blocks clean release sign-off.
- Android physical-device smoke was completed.
- iPhone smoke was not part of this round.

## RR1. Automated Gate

Run from `wain_app`:

```bash
flutter analyze
```

```bash
flutter test test/core/utils/hours_calculator_test.dart test/features/merchant/data/merchant_dashboard_repository_test.dart test/features/merchant/data/merchant_repository_test.dart test/features/merchant/presentation/screens/merchant_scan_screen_test.dart test/features/merchant/presentation/screens/merchant_dashboard_screen_test.dart test/core/routing/app_router_merchant_guard_test.dart test/features/merchant/presentation/screens/merchant_menu_screen_test.dart test/features/merchant/presentation/screens/merchant_offers_screen_test.dart test/features/merchant/presentation/screens/merchant_reviews_screen_test.dart test/features/venue/domain/venue_helpers_test.dart
```

If functions/backend are part of the same candidate, also run the pre-existing backend checklist in [merchant_dashboard_release_checklist.md](/c:/Users/a-z/OneDrive/Desktop/googleAITest/WAIN%20APP/wain_app/docs/release/merchant_dashboard_release_checklist.md).

### RR1 result
- [x] PASS
- [ ] FAIL

Notes:
- Local `flutter analyze`: PASS on `2026-04-05`
- Merchant regression suite: PASS on `2026-04-05`
- Functions build: PASS on `2026-04-05`
- Targeted emulator regression for `venue_inactive` backend fix: PASS on `2026-04-05`

## RR2. Backend And Data Sanity

Verify on real data before device smoke:

### Venue doc
- [x] `active_menu_version_id` matches the expected menu state.
- [x] `last_story_at` exists and updates after publishing a story.
- [x] `hours` shape matches `Map<day, List<{open, close, spans_midnight?}>>`.
- [x] `photos`, `categories`, `name`, `city`, and `phone` are present or absent in expected ways.

### Menu and stories
- [x] `menu_versions` has `published_at` on the active or latest relevant version.
- [x] Active story check with `limit(1)` returns the expected result when a live story exists.

### Scan payload
- [x] `validateToken` returns the fields required by `MerchantValidationResult`.
- [x] Missing nested fields do not break the scan path.

### RR2 result
- [x] PASS
- [ ] FAIL

Notes:
- Verified against live project `wain-d2e28` on `2026-04-05`:
  - `venues/azure_01` contains `active_menu_version_id`, `last_story_at`, `hours`, `tags`, `photos`, `categories`, `name_ar`, `name_en`, `city`, and `phone`
  - `hours` shape matches `Map<day, List<{open, close, spans_midnight?}>>`
  - sample hours slot fields observed: `open`, `close`, `spans_midnight`
  - `tags.mood` exists as an array and maps cleanly to `moodLabels`
  - `venues/azure_01/menu_versions/draft_1773239866076` exists and contains `published_at`
  - active story `limit(1)` query returned no live story at the time of the check, which is a valid empty-state result for the health logic
- Backend callable contract verification:
  - emulator regression for `validateToken`, `redeemToken`, and `promoteStory`: PASS
  - fixed backend mismatch where missing `venues/{venueId}.is_active` incorrectly produced `venue_inactive`
  - functions deployed successfully to `wain-d2e28` on `2026-04-05`

## RR3. Real Device Smoke

### A. Access And Navigation
- [x] Merchant account opens `/merchant/dashboard`.
- [ ] Non-merchant account is routed to invite.
- [ ] Login return flow back to merchant route works.
- [x] Back navigation works for:
  - dashboard -> offers -> back
  - dashboard -> reviews -> back
  - dashboard -> photos/stories/menu/hours/edit venue -> back
- [x] CTA navigation works from:
  - action feed
  - content health
  - offers/reviews deep links

### B. Dashboard Visual
- [x] No overflow or clipped content.
- [x] RTL alignment is correct.
- [x] Section ordering is correct.
- [x] Loading and empty states are sane.
- [x] Refresh/backfill does not crash and does not leave stale UI behind.

### C. Offers Lifecycle
- [ ] Create/edit offer works.
- [x] Pause/activate offer works.
- [x] Status badge matches actual state.
- [x] Performance summary renders correctly.
- [ ] Consumer can claim.
- [ ] Merchant can scan/redeem.
- [ ] Post-redeem counters and dashboard state refresh correctly.

### D. Reviews
- [x] Open reviews from dashboard CTA.
- [ ] `No Reply` filter works.
- [ ] Submit reply works.
- [ ] Delete reply works.
- [ ] Review quality card updates correctly.

### E. Content Health
- [x] Menu state reflects correctly.
- [x] Photo count reflects correctly.
- [x] Story cadence reflects correctly.
- [x] Hours confidence reflects correctly.
- [x] Profile completeness reflects correctly.
- [x] Content health CTAs route correctly.
- [x] After content writes, dashboard reflects the change without requiring manual refresh:
  - upload/delete photo
  - save hours
  - publish/delete story
  - edit venue profile

### F. Hours Calculator
- [ ] Same-day shift venue shows correct open/closed state.
- [ ] Overnight shift venue shows correct open/closed state.
- [ ] 24h venue shows correct open/closed state.

### G. Scan Flow
- [ ] Valid QR/token shows correct offer and venue preview.
- [ ] Redeem success works.
- [ ] Invalid token path works.
- [ ] Used token path works.
- [ ] Bottom sheet has no overflow on device.

### RR3 result
- [ ] PASS
- [x] FAIL

Notes:
- Android physical-device smoke confirmed dashboard layout, content health visibility, CTA routing, offer deletion, and story promotion after backend fix.
- RR3 remains incomplete because non-merchant/login-return, full offers create-edit-consumer-claim path, full reviews mutation path, hours matrix on real venues, and real QR/token scan scenarios were not all executed in this round.

## Evidence

Minimum required artifacts:
- [ ] 3 dashboard screenshots
- [ ] 1 scan success screenshot
- [ ] 1 content health screenshot
- [ ] 1 offers status/performance screenshot
- [ ] 1 reviews quality screenshot

## Sign-Off

### Go
- [x] `RR1` PASS
- [x] `RR2` PASS
- [ ] `RR3` PASS

### No-Go blockers
- [ ] Crash
- [ ] Route guard regression
- [ ] Scan/redeem inconsistency
- [ ] Content health misclassification
- [ ] Wrong open/closed state on real data
- [ ] Layout overflow / RTL break

### Release note
- Build candidate: `main @ c6556cef5cd74115c31f5cbd4990f3e65f977a7f` + functions deployed to `wain-d2e28` on `2026-04-05`
- Devices tested: Android physical device
- Test accounts used: merchant account only in this round
- Result: `NO-GO`
- Known non-blockers:
  - Firebase CLI warns that `firebase-functions` dependency is outdated
  - `firebase.json` contains a top-level `flutter` key that Firebase CLI reports as unknown but non-blocking

### Decision rationale
- `RR1`: PASS
- `RR2`: PASS
- `RR3`: FAIL due to incomplete execution and missing evidence, not a currently known production blocker
- Final decision: `NO-GO` for formal release sign-off until the remaining RR3 scenarios and evidence capture are completed on real devices.
