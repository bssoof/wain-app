# Service Account Key Local Usage Search

Date: 2026-05-20

## Command

```powershell
rg -n --hidden --glob '!build/**' --glob '!node_modules/**' --glob '!.git/**' --glob '!.tmp/**' "GOOGLE_APPLICATION_CREDENTIALS|service-account-key|firebase-adminsdk|client_email|private_key|SERVICE_ACCOUNT|service account" .
```

## Summary

The repository still contains local scripts, admin web fallback paths, and runbook references that can use `service-account-key.json` or `GOOGLE_APPLICATION_CREDENTIALS`.

Key implementation references:

| Path | Evidence summary |
| --- | --- |
| `admin_web_console/lib/firebase/server.ts` | Checks `WAIN_FIREBASE_SERVICE_ACCOUNT_PATH`, `GOOGLE_APPLICATION_CREDENTIALS`, and local `service-account-key.json` fallback paths before ADC fallback. |
| `admin_web_console/scripts/mint-live-callable-tokens.mjs` | Checks service account path environment variables and local `service-account-key.json` fallback paths. |
| `functions/scripts/audit_admin_roles.js` | Requires `GOOGLE_APPLICATION_CREDENTIALS` or local `service-account-key.json`, then sets `GOOGLE_APPLICATION_CREDENTIALS`. |
| `functions/scripts/run_admin_web_staging_rehearsal.js` | Requires `GOOGLE_APPLICATION_CREDENTIALS` or local `service-account-key.json`, then sets `GOOGLE_APPLICATION_CREDENTIALS`. |
| `scripts/create_invite.js` | Directly requires `../service-account-key.json`. |
| `functions/scripts/cleanup_menu_import_noise.js` | References root `service-account-key.json`. |
| `functions/scripts/cleanup_menu_versions_retention.js` | References root `service-account-key.json`. |
| `functions/scripts/migrate_legacy_menu_to_versioned.js` | References root `service-account-key.json`. |
| `functions/scripts/revoke_merchant_link.js` | References root `service-account-key.json`. |
| `functions/scripts/seed_transport_mvp.js` | References root `service-account-key.json`. |

Relevant documentation/runbook references also exist under `docs/findings`, `docs/release`, `docs/plan_review`, and `docs/security`.

## Assessment

The two active non-expiring `firebase-adminsdk` keys may still be supporting local or staging workflows. They should not be deleted until these paths are migrated to ADC, service account impersonation, Workload Identity Federation, Secret Manager, or an approved replacement workflow.

## Recommended Remediation

1. Replace direct `require("../service-account-key.json")` usage with ADC or explicit environment-based credentials that fail closed.
2. Remove local `service-account-key.json` fallback paths from production/admin web runtime paths.
3. Update runbooks to prefer ADC, service account impersonation, or Workload Identity Federation.
4. After replacement and test verification, rotate/delete the two active user-managed `firebase-adminsdk` keys.
