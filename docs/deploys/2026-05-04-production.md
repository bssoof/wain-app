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
