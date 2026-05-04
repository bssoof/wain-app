# AWC-P7-F01C - Staging Callable Deployment Recheck

Superseded status note: this round documents the intermediate state before authenticated rerun and is superseded by `AWC-P7-F01D` for current follow-up/decision status.

Date: 2026-04-13
Round: AWC-P7-F01C
Project: wain-d2e28
Scope: Post-blocker verification after AWC-P7-F01B and AWC-P7-F01M

## Verdict

follow_up_required.

The previous deployment blocker (missing admin callables) is no longer valid. Required callable endpoints are now deployed and reachable, but authenticated browser smoke is still pending because current probe tokens fail App Check.

## What Changed Since AWC-P7-F01B

- AWC-P7-F01B inventory result: required admin callables found `0/16`.
- Current inventory recheck: required admin callables found `16/16`.
- AWC-P7-F01B HTTP result: admin callable probes returned `404`.
- Current HTTP result: all 16 probes return `400` with `App Check verification failed`.

Interpretation:
- `404` -> endpoint missing.
- `400` with App Check failure -> endpoint exists and enforces protection.

## Verification Summary

1. Function inventory refresh
- Command: `firebase functions:list --project wain-d2e28 --json`
- Result: total deployed functions `59`, required AWC admin callables present `16/16`.

2. Endpoint reachability probe (16 required callables)
- Command: `node .tmp/probe_admin_callables.js`
- Result: each endpoint returned `HTTP 400` with body snippet containing `App Check verification failed`.

3. P7-F02 index recheck
- Live Firestore query with composite shape `where(venue_id == ...) + orderBy(created_at desc)` succeeded.
- Filtered media bundle callable logic (`getAdminMediaInventoryReadBundle`) succeeded for seeded venue and returned non-empty counts.

## P7 Follow-up Status After Recheck

- `P7-F01`: open
  - deployment blocker resolved.
  - still requires rerun of real browser HTTP smoke with valid admin auth token + valid App Check token (not placeholder/debug-invalid token).

- `P7-F02`: done at backend/data layer
  - composite index behavior is now queryable.
  - filtered media bundle path runs successfully against live Firestore.
  - browser-visible filtered evidence remains tied to closing `P7-F01`.

- `P7-F03`: open
  - final go-live decision remains blocked until authenticated browser smoke is rerun successfully.

## Evidence Artifact

- Machine-readable evidence: `docs/release/admin_web_console_browser_smoke_awc_p7_f01c.json`
