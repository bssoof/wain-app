# Production Deploy 2026-05-07

## Summary
- Pre-deploy HEAD: 0b8f094945edbde8a8787efff075842b2eef1252
- Pre-deploy tag: pre-deploy-2026-05-07
- Deploy command: npx firebase deploy --only hosting (from admin_web_console/)
- Deploy duration: 300 seconds
- Project: wain-d2e28
- Result: SUCCESS

## What was deployed (since cf510a49)
- Phase 4 - Dashboard refresh
- Phase 5 - Finance pages refresh (topups, wallet-audit, reversals)
- Phase 6 - Venues + workspace refresh
- Phase 7 - Media + content surface refresh
- Phase 8 - Config governance refinement
- Phase 9 - Animation polish
- Phase 10 - Responsive + a11y audit
- Hydration fix: environment badge mismatch (79bd7be8)
- RBAC fix: /admin/config restricted to super_admin only (7fd34528)

## Test counts pre-deploy
- Vitest: 692 passed across 117 files
- TSC: 0 errors
- Build: 0 errors

## Production URLs
- https://wain-admin.web.app (custom hosting target)
- https://wain-d2e28.web.app (project default)
- https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app (SSR Cloud Run)

## Post-deploy reachability
- /admin/sign-in -> 200 (7030 bytes)
- /admin/access-denied?route=dashboard -> 200 (6637 bytes)

## Rollback plan

    git checkout pre-deploy-2026-05-07
    cd admin_web_console
    npx firebase deploy --only hosting

## Manual verification needed (basil)
- [ ] Login as super_admin -> dashboard banner reflects prod state
- [ ] Login as finance_admin -> /admin/config returns 403/access-denied
- [ ] Monitor Cloud Run error logs first 30 min

## Follow-ups (non-blocking)
- firebase-functions package outdated warning during deploy (upgrade later)
- 18 npm vulnerabilities (8 low, 7 moderate, 3 critical) - pre-existing
- Memory monitoring: verify 512 MiB sufficient by 2026-05-10
