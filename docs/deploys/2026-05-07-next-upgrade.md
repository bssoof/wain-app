# Next.js Upgrade Deploy 2026-05-07

## Summary
- Next: 14.2.5 -> 14.2.35
- Pre-deploy tag: pre-deploy-2026-05-07-next-upgrade
- Deploy command: npx firebase deploy --only hosting
- Project: wain-d2e28
- Duration: 295.8154834 seconds
- Result: SUCCESS

## Audit deltas
- Before: 3 critical, 0 high, 7 moderate, 8 low.
- After: 2 critical, 1 high, 7 moderate, 8 low.
- `next` critical advisories were reduced by staying on the latest available
  14.2.x patch. Residual `next` audit entries require a semver-major upgrade
  outside the allowed 14.2.x line.
- See docs/security/audit-before-2026-05-07.json.
- See docs/security/audit-after-2026-05-07.json.

## Test counts
- Web: 696 passed across 118 files.
- TSC: 0 errors.
- Build: passed on Next 14.2.35.
- Build warning inspection: no warn/deprecation matches in the requested pass.

## Post-deploy reachability
- /admin/sign-in -> 200 (6999 bytes)
- /admin/access-denied?route=dashboard -> 200 (6602 bytes)

## Rollback plan

    git checkout pre-deploy-2026-05-07-next-upgrade
    cd admin_web_console
    npx firebase deploy --only hosting

## Refs
- docs/security/2026-05-07-full-scan.md (Pre-existing: next@14.2.5)
- Upgrade commit: af2f8daa
- Merge commit: ff19a2af

## Notes
- The deploy log was sanitized before commit to redact transient signed upload
  URLs, source tokens, Firebase defaults cookies, and user image URLs.
