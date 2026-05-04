# AWC-P7-F01B - Browser HTTP Smoke (Media)

Date: 2026-04-11
Round: AWC-P7-F01B
Target: `/admin/media`
Project: `wain-d2e28`

## Verdict

`blocked`.

The browser HTTP transport path itself is functional, but the required media/admin callables are not deployed on staging. As a result, `/admin/media` remains unavailable and cannot provide action-level readiness evidence yet.

## Evidence Artifacts

- JSON evidence: `docs/release/admin_web_console_browser_smoke_awc_p7_f01b.json`
- Screenshot: `docs/release/admin_web_console_browser_smoke_awc_p7_f01b.png`

## What Was Verified

1. Browser route smoke:
   - Opened `http://127.0.0.1:3010/admin/media` with staging auth/app-check envs.
   - UI state was `Unavailable` with `callable:getAdminMediaInventoryReadBundle` as source note.

2. Browser callable transport probe:
   - `isCurrentUserAdmin` succeeded (`200`) from browser, proving browser transport and headers are wired.
   - `getAdminMediaInventoryReadBundle` failed from browser with `Failed to fetch` and CORS preflight error.

3. Node HTTP probes with same auth/app-check tokens:
   - `getAdminMediaInventoryReadBundle` -> `404`
   - `mediaReferenceCheckAsset` -> `404`
   - `mediaPurgeAsset` -> `404`
   - `mediaSoftDeleteAsset` -> `404`
   - `mediaQuarantineAsset` -> `404`

4. Staging deployment inventory check:
   - `firebase functions:list --project wain-d2e28 --json` parsed successfully.
   - Total deployed functions: `36`.
   - Required AWC admin callables found: `0/16`.

## Readiness Interpretation

- Unfiltered media inventory readiness: `blocked` (callable endpoint returns `404`).
- Venue-filtered media inventory readiness: `blocked by deployment`, not an index verdict yet.
- Reference-check and purge browser action readiness: `not testable` in this run because actionable media rows/buttons are absent while source is unavailable.

## Required Next Step

Deploy the missing admin callables to staging first, then re-run this same browser smoke round before any go-live claim.