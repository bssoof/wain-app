# Production Deploy — 2026-05-04

## Time
- Start: ~19:30 Hebron
- End:   ~20:00 Hebron
- Tag:   `production-deploy-2026-05-04`
- Merge commit: `23d51ae9`

## Scope (60 commits merged from feat/step-up-auth)

### Live and enabled
- AWC-QA-001 admin console foundation
- AWC-QA-002 admin config validation (flag ON)
- AWC-QA-007 top-up confirmation dialog
- Step-up enforcement: `enforcementMode = enabled`
- Memory: 512 MiB SSR
- Pentest hardening (DELETE %2f bypass, SSRF block, etc.)

### Live with feature flag OFF (legacy fallback active)
- AWC-QA-010 readiness RBAC (`readinessRbacEnabled = false`)
- AWC-QA-012 review affordances (dialogs migrated, behavior unchanged)

## Verification at deploy time
- vitest: 549/549 green
- tsc --noEmit: clean
- production smoke (login + dashboard + 2 fetch calls): pass
- Cloud Logs (30-min window after deploy): 0 errors / 0 step-up rejections / 0 5xx

## Known cosmetic issue
- `deploy_channel: "preview"` reported in /api/admin/health/config response on production. Build env var leaks preview channel value. Fix tracked in tech-debt.

## Pending follow-ups
- 24h post-deploy observation (until 2026-05-05 ~20:00)
- Enable readinessRbacEnabled flag (after observation)
- Rotation test for step-up signing key
- Delete feat/step-up-auth branch (after 24h safety)
- Pentest #2 scheduling
- Cert renewal before 2026-06-18
- Setup git remote: completed in this session

## Follow-up patches (same night, 2026-05-04 -> 2026-05-05)

- ``979af2dd``: chore(scripts): cleanup .env.example placeholders + gitignore .env files.
- ``7a0d707c``: fix(admin): deploy_channel hostname detection (initial attempt - incomplete due to Cloud Run forwarding URL pattern).
- ``cf9d28e3``: fix(admin): deploy_channel uses x-forwarded-host through Firebase Hosting proxy. Verified on production: deploy_channel reports "production".
- ``readinessRbacEnabled`` flag enabled in Firestore at ~2026-05-05 02:05 Hebron after BEFORE/AFTER smoke verification (response shapes identical, no behavior change for super_admin role). Cloud Logs verification: 0 readiness_rbac_denied events, 0 5xx errors in observation window.
- Local backup created at OneDrive\backups\wain_app_2026-05-04_post-deploy (1.99 GB, .git included).
- ``feat/step-up-auth`` branch deleted after merge confirmed.

## Final state at session close

- Branch ``main`` HEAD: tagged ``production-deploy-2026-05-04`` + 4 follow-up commits.
- Production: ``wain-admin.web.app`` running latest code with all flags ON (healthCheck + readinessRbac).
- No git remote configured (local-only repo, deferred GitHub setup).
- Local backup available for disaster recovery.
