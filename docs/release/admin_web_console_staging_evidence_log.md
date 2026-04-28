# Admin Web Console Staging Evidence Log

## 1. Run Metadata
- Run id: `phase7_1775874725021`
- Date: `2026-04-11`
- Project: `wain-d2e28`
- Operator mode: `script-driven staging rehearsal with local callable modules against live Firestore`
- Auth mode: `service-account cert from repo-local key`
- Raw evidence artifact: `docs/release/admin_web_console_staging_evidence_log.json`

## 2. Commands Executed

```powershell
cd wain_app/functions
npm run build
$env:GOOGLE_APPLICATION_CREDENTIALS="..\service-account-key.json"
$env:GCLOUD_PROJECT="wain-d2e28"
npm run admin-web:staging-rehearsal
cd ..\
firebase deploy --only firestore:indexes --project wain-d2e28
cd wain_app/admin_web_console
npm test
npm run build
```

## 3. Config Governance Results
- Initial live version observed by the rehearsal: `5`
- Temporary publish executed: `liveVersion=6`
- Rollback executed: `rollbackToVersion=5`, resulting `liveVersion=7`
- Distinct reviewer/publisher enforcement:
  - same-actor publish attempt was rejected with `config_publish_requires_distinct_reviewer_and_publisher`
- Effective pricing restoration:
  - `pricingRestoredToBaseline = true`

## 4. Content / Reviews Results
- Offers moderation:
  - list count for the seeded venue: `1`
  - `contentModerateOffer` approve flow: `PASS`
- Stories moderation:
  - list count for the seeded venue: `1`
  - `contentModerateStory` flag flow: `PASS`
  - finance-role denial path: `content_role_not_authorized`
- Reviews moderation:
  - list count for the seeded venue: `1`
  - `moderateVenueReviewForAdmin` hide flow: `PASS`
  - finance-role denial path: `review_moderation_role_not_authorized`
  - expected-state conflict path: `review_moderation_expected_state_conflict`

## 5. Media Results
- Inventory read without venue filter: `PASS`
  - top-up proofs: `7`
  - venue photos: `6`
  - offer images: `3`
  - story images: `10`
- `mediaReferenceCheckAsset`: `PASS`
- `mediaSoftDeleteAsset`: `PASS`
- `mediaQuarantineAsset`: `PASS`
- `mediaPurgeAsset` blocked path: `PASS`
  - blocked with `media_purge_reference_index_unhealthy` after intentionally flipping index health to `stale`
- plain-user denial path: `Requires admin privileges`

## 6. Remaining Gaps Observed During Rehearsal
- This run validated callable logic against the live staging Firestore project, but it did **not** validate browser HTTP callable transport with end-user auth/app-check envs.
- Venue-filtered Media Inventory hit a real staging index gap during verification:
  - missing/deploying composite index for `offers(venue_id ASC, created_at DESC)`
  - the index definition was added to `firestore.indexes.json`
  - deployment was started successfully, but the filtered query still reported `index is currently building` at verification time

## 7. Verdict
- Rehearsal status: `PASS`
- Phase 7 recommendation: `ACCEPTED_WITH_FOLLOW_UP`
- Go-live recommendation: `NOT_READY`

Reason:
- The governed staging rehearsal passed for config/content/reviews/media callable logic on the live project.
- Go-live remains blocked until browser HTTP callable transport is evidenced and the venue-filtered media inventory index finishes building and is re-verified.
