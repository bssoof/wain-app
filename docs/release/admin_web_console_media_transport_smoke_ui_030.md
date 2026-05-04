# UI-030 - Media Transport Staging Smoke (Authenticated Probe)

Date: 2026-04-17
Round: AWC-UI-030
Target route: `/admin/media`
Project: `wain-d2e28`

## Scope

Execute the remaining Phase 4 follow-up smoke for live media transport surfaces with authenticated callable probes:

- `listVenuesForAdmin`
- `getAdminMediaInventoryReadBundle`
- `mediaReferenceCheckAsset`
- `mediaSoftDeleteAsset`
- `mediaQuarantineAsset`
- `mediaPurgeAsset`

## Execution

Command run from `wain_app`:

- `$env:WAIN_STAGING_APP_CHECK_TOKEN=<minted-token>; node .tmp/probe_media_transport_authenticated.js > docs/release/admin_web_console_media_transport_smoke_ui_030.json`

Probe mode:

- Admin token: generated via Firebase Auth sign-in for seeded `super_admin` smoke user.
- App Check header: present with non-placeholder token (`present_non_placeholder`).

## Result Summary

- `probesTotal`: `6`
- `probesHttp200`: `6`
- `probesHttp404`: `0`
- `probesAppCheckFailed`: `0`
- Endpoint statuses: all six callable probes returned `HTTP 200`.

## Latest Re-run (Same Round)

- Re-run timestamp (JSON artifact): `2026-04-17T00:30:57.254Z`
- Re-run command: `$env:WAIN_STAGING_APP_CHECK_TOKEN=<minted-token>; node .tmp/probe_media_transport_authenticated.js > docs/release/admin_web_console_media_transport_smoke_ui_030.json`
- Re-run outcome: `6/6` `HTTP 200`, `0` `App Check verification failed`, `0` `404`.

## Interpretation

- No `404` signals were observed in this round.
- App Check validation is now passing for all media transport probes.
- Purge governance precondition passed after `media_reference_index/health` was refreshed to `healthy`.

## Follow-up Decision

- Decision: `FOLLOW_UP_CLOSED`
- No further transport follow-up action is required for UI-030.

## Evidence Files

- `docs/release/admin_web_console_media_transport_smoke_ui_030.json`
- `docs/release/admin_web_console_media_transport_smoke_ui_030.md`
