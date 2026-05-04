# UI-025 - Post-Polish Browser Smoke Evidence Refresh

Date: 2026-04-17
Scope: Full in-scope admin route capture (15 routes)
Decision impact: closes pending post-polish browser evidence refresh after UI-P01

## Execution

- Admin web server was started in development mode with explicit admin session context:
  - `WAIN_ADMIN_UID`
  - `WAIN_ADMIN_EMAIL`
  - `WAIN_ADMIN_DISPLAY_NAME`
  - `WAIN_ADMIN_ROLE=super_admin`
  - `WAIN_ADMIN_ROLES=["super_admin"]`
  - `WAIN_ADMIN_ADMIN=1`
  - `WAIN_ADMIN_IS_ADMIN=1`
- Capture command executed from `admin_web_console`:
  - `npm run capture:ui-a02`

## Result Summary

- `ok: true`
- Total planned routes: `15`
- Successful captures: `15`
- Redirects to sign-in: `0`
- Failed captures: `0`

## Artifacts Refreshed

- `docs/release/admin_web_console_ui_a02_baseline_capture.json`
- `docs/release/admin_web_console_ui_a02_baseline_capture.md`
- `docs/release/ui_a02_baseline_screenshots/*.png`

## Outcome

- Post-polish route rendering remains stable across protected and public admin surfaces.
- No browser-level regression signal was observed for route guards after UI-P01.
- This round is evidence-only; no RBAC, loader, transport, or UI contract code changes were introduced.

## Addendum - Authenticated Transport Recheck (Options 2 and 3)

Date: 2026-04-17
Execution window (UTC): 12:48:52 -> 12:49:07
Scope: Re-ran authenticated transport probes with real App Check context to re-confirm smoke closure.

### Recheck Execution

- Executed from `wain_app` root with guard precheck:
  - `if (-not $env:WAIN_STAGING_APP_CHECK_TOKEN) { throw 'WAIN_STAGING_APP_CHECK_TOKEN is not set in this shell'; }`
- Probe commands:
  - `node .tmp/probe_content_transport_authenticated.js`
  - `node .tmp/probe_config_transport_authenticated.js`
  - `node .tmp/probe_media_transport_authenticated.js > docs/release/admin_web_console_media_transport_smoke_ui_030.json`
- Chained run exit code: `0`

### Recheck Result Summary

- Content transport (`AWC-UI-035`, `2026-04-17T12:48:52.793Z`)
  - `probesTotal: 6`
  - `probesHttp200: 6`
  - `probesHttp404: 0`
  - `probesAppCheckFailed: 0`
  - `probesTargetNotFound: 0`
  - `decisionHint: FOLLOW_UP_CLOSED`
- Config transport (`AWC-UI-036`, `2026-04-17T12:49:01.322Z`)
  - `probesTotal: 5`
  - `probesHttp200: 5`
  - `probesHttp404: 0`
  - `probesAppCheckFailed: 0`
  - `decisionHint: FOLLOW_UP_CLOSED`
- Media transport (`AWC-UI-030`, `2026-04-17T12:49:07.669Z`)
  - `probesTotal: 6`
  - `probesHttp200: 6`
  - `probesHttp404: 0`
  - `probesAppCheckFailed: 0`
  - `decisionHint: FOLLOW_UP_CLOSED`

### Recheck Artifacts

- `docs/release/admin_web_console_content_transport_smoke_ui_035.json`
- `docs/release/admin_web_console_config_transport_smoke_ui_036.json`
- `docs/release/admin_web_console_media_transport_smoke_ui_030.json`

### Recheck Outcome

- Transport smoke closure remains valid after the fresh rerun.
- No new endpoint loss, App Check rejection, or target-not-found regression was detected in this recheck pass.
