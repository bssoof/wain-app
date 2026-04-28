# AWC-P7-F01D - Authenticated Browser HTTP Smoke (Staging)

Date: 2026-04-13
Project: wain-d2e28
Environment: browser-authenticated HTTP callable probes (admin auth + App Check token)
Decision impact: resolves P7-F01 and closes P7-F03

## Scope

Authenticated browser transport smoke rerun for:
- `/admin/config`
- `/admin/media`
- `/admin/content/offers`
- `/admin/content/stories`
- `/admin/content/reviews`

## Verified Preconditions

- Required admin callables are deployed on staging (`16/16`).
- Authenticated browser token and App Check token were supplied to the probe run.
- Previous blocker (`404` missing deployments) was already superseded in `AWC-P7-F01C`.

## Probe Summary

All required callable endpoints returned successful authenticated responses (`HTTP 200`) with no `404` or `App Check verification failed` errors.

Endpoints validated:

1. Config governance callables
   - `configUpsertDraft`
   - `configReviewDraft`
   - `configPublishDraft`
   - `configRollbackVersion`

2. Content moderation callables
   - `contentModerateOffer`
   - `contentModerateStory`
   - `listOffersForAdmin`
   - `listStoriesForAdmin`
   - `listVenueReviewsForAdmin`
   - `moderateVenueReviewForAdmin`

3. Media governance callables
   - `getAdminMediaInventoryReadBundle`
   - `mediaReferenceCheckAsset`
   - `mediaSoftDeleteAsset`
   - `mediaQuarantineAsset`
   - `mediaPurgeAsset`

4. Venue admin callables used by scoped media/readiness paths
   - `listVenuesForAdmin`

## Browser-Level Outcome

- Browser transport is now verified under valid auth + App Check context.
- No transport-level blocker remains for config/media/content routes.
- Media filtered inventory path remains consistent with `AWC-P7-F01C` backend-layer readiness.

## Follow-up Resolution Status

- `P7-F01`: resolved
- `P7-F02`: already resolved at backend layer in `AWC-P7-F01C`; browser evidence now aligned
- `P7-F03`: completed with final decision `GO_LIVE_READY`

## Evidence Files

- `docs/release/admin_web_console_browser_smoke_awc_p7_f01d.md`
- `docs/release/admin_web_console_browser_smoke_awc_p7_f01d.json`
