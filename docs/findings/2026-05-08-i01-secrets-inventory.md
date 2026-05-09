# I-01 Secrets Inventory & Migration Plan

Scope: read-only inventory for `wain_app` at HEAD `f1b8a5ab`. This report lists key names and file paths only; no secret values are included.

## 1. Service Account JSON Files

| File path | Looks like SA key? | Gitignored? | Tracked now? | In history? | Role / use |
| --- | --- | --- | --- | --- | --- |
| `service-account-key.json` | Yes, contains a `private_key` field | Yes, `.gitignore:52` | No | No hits from filename add search; no `private_key` JSON hits in last 100 commits | Local Firebase Admin SDK credential used by scripts and admin-web fallback paths |

Notes:

- `git status --ignored --short` shows `!! service-account-key.json`.
- `.gitignore` also ignores `.tmp/`; several ignored temporary smoke/probe scripts reference the same root key path.
- I did not print or copy service account JSON contents. The exact service account email/role should be identified from GCP IAM before rotation or deletion.

## 2. Code References to SA Keys

Primary runtime code:

- `admin_web_console/lib/firebase/server.ts:10-38` checks `WAIN_FIREBASE_SERVICE_ACCOUNT_PATH`, `GOOGLE_APPLICATION_CREDENTIALS`, `../service-account-key.json`, `../serviceAccountKey.json`, `service-account-key.json`, and `serviceAccountKey.json`, then uses `cert(...)` if a file exists.
- `admin_web_console/lib/firebase/server.ts:78-83` falls back to `applicationDefault()`.
- `functions/src/index.ts:89-90`, `functions/src/shared/firestore-db.ts:3-4`, and `functions/src/shared/storage.ts:5-6` use `admin.initializeApp()` with default credentials.

Operational scripts using JSON key paths:

- `admin_web_console/scripts/mint-live-callable-tokens.mjs:18-23`, `:73-80`
- `functions/scripts/audit_admin_roles.js:68-85`, `:148-152`
- `functions/scripts/run_admin_web_staging_rehearsal.js:39-62`
- `functions/scripts/cleanup_menu_import_noise.js:151-158`
- `functions/scripts/cleanup_menu_versions_retention.js:141-148`
- `functions/scripts/migrate_legacy_menu_to_versioned.js:257-267`
- `functions/scripts/revoke_merchant_link.js:52-60`
- `functions/scripts/seed_transport_mvp.js:136-144`
- `scripts/create_invite.js:9-12`

Ignored temporary scripts:

- `.tmp/admin_login_dashboard_smoke.js`
- `.tmp/probe_config_transport_authenticated.js`
- `.tmp/probe_content_transport_authenticated.js`
- `.tmp/probe_media_transport_authenticated.js`

Documentation/runbook references:

- `docs/release/admin_web_console_release_runbook.md`
- `docs/release/admin_web_console_staging_evidence_log.md`
- `docs/release/admin_web_console_staging_evidence_log.json`
- `docs/plan_review/*`

Recommendation: migrate runtime and scripts away from file-based service-account JSON. Keep temporary docs as historical evidence, but update current runbooks after the migration.

## 3. Environment Variables

### `admin_web_console/.env.local`

Ignored by `admin_web_console/.gitignore`.

| Key | Category | Recommendation |
| --- | --- | --- |
| `NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN` | Public/test App Check token | `[ENV]` Local-only; do not commit. Prefer server-minted App Check for live proxy paths. |
| `NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Fine in ignored local env. |
| `NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN` | Public/test App Check token | `[ENV]` Local-only; do not commit. |
| `NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Fine in ignored local env. |
| `NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN` | Public/test App Check token | `[ENV]` Local-only; do not commit. |
| `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Fine in ignored local env. |
| `NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS` | Public config | `[ENV]` Fine in ignored local env. |
| `NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN` | Public/test App Check token | `[ENV]` Local-only; do not commit. |
| `NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Fine in ignored local env. |
| `WAIN_ADMIN_SESSION_VERIFY_REVOCATION` | Runtime feature flag | `[ENV]` Not a secret. Keep env-based. |

### `admin_web_console/.env.production`

Ignored by `admin_web_console/.gitignore`.

| Key | Category | Recommendation |
| --- | --- | --- |
| `NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Safe to keep as deployment config. |
| `NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Safe to keep as deployment config. |
| `NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Safe to keep as deployment config. |
| `NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS` | Public config | `[ENV]` Production should be unset/false; not a secret. |
| `NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL` | Public config | `[ENV]` Safe to keep as deployment config. |

### `scripts/multi_agent/.env`

Ignored by root `.gitignore`.

| Key | Category | Recommendation |
| --- | --- | --- |
| `GEMINI_API_KEY` | Third-party API key | `[ENV]` Acceptable for local-only script use. Use Secret Manager or CI secret if automated. |
| `OPENAI_API_KEY` | Third-party API key | `[ENV]` Acceptable for local-only script use. Use Secret Manager or CI secret if automated. |

### `scripts/multi_agent/.env.example`

Tracked template. It contains key names only: `OPENAI_API_KEY`, `GEMINI_API_KEY`.

## 4. Multi-agent Scripts Auth

`scripts/multi_agent/discuss.py` loads `scripts/multi_agent/.env` via `python-dotenv` and reads:

- `GEMINI_API_KEY`
- `OPENAI_API_KEY`

It authenticates directly to Gemini and OpenAI SDK clients with those provider keys. It does not initialize Firebase Admin, does not use `GOOGLE_APPLICATION_CREDENTIALS`, and does not call Google Cloud ADC.

Recommendation: keep this isolated as local tooling. If it becomes CI/server automation, move the provider keys to the relevant CI secret store or Secret Manager.

## 5. Production Runtime Auth Status

Cloud Functions:

- Source uses `admin.initializeApp()` without explicit credential files in `functions/src/index.ts` and shared helpers.
- Deploy logs show functions are deployed with `serviceAccountEmail` populated by Firebase/GCP, for example `wain-d2e28@appspot.gserviceaccount.com` for `adminUpdateVenueVisibility`.
- Conclusion: Functions production runtime is using platform ADC/default service account, not a JSON key path.

Cloud Run SSR (`ssrwainadmin`):

- Deploy logs show a Cloud Run service template with `serviceAccountName: 620614484841-compute@developer.gserviceaccount.com`.
- `admin_web_console/lib/firebase/server.ts` prefers a local JSON key if present, then falls back to `applicationDefault()`.
- Deploy logs for SSR environment show `FIREBASE_CONFIG`, `GCLOUD_PROJECT`, and framework envs; no `GOOGLE_APPLICATION_CREDENTIALS` or service-account path was observed in the deploy log.
- `gcloud` is not installed in this local environment, so IAM role membership was not queried live. Basil should confirm the service account roles in GCP Console.

Firestore Admin SDK:

- Functions path: ADC/default service account.
- Admin Web SSR path: likely ADC in production; JSON key path only if a file or env path exists in the runtime filesystem.
- Recommendation: remove production JSON-key fallback after local scripts are migrated, or gate it to non-production only.

## 6. Third-party API Keys

| Key name | Current storage / reference | Runtime use | Recommendation |
| --- | --- | --- | --- |
| `GEMINI_API_KEY` | `scripts/multi_agent/.env`; `admin_web_console/scripts/gemini-ui-review.mjs:30`; `scripts/multi_agent/discuss.py:32` | Local tooling / UI review scripts | `[ENV]` local-only; `[SM]` or CI secret if automated. |
| `OPENAI_API_KEY` | `scripts/multi_agent/.env`; `scripts/multi_agent/discuss.py:33` | Optional multi-agent local script | `[ENV]` local-only; `[SM]` or CI secret if automated. |

No Twilio, SendGrid, Stripe, or separate Vision API key references were found in the scanned source. Google Vision-style work appears to rely on Google/Firebase platform credentials rather than a separate API key.

Related Google/Firebase tokens and secrets:

- `NEXT_PUBLIC_FIREBASE_API_KEY`: Firebase web config, public by design; `[ENV]`.
- `NEXT_PUBLIC_WAIN_*_APP_CHECK_TOKEN`: public/test-token style values; `[ENV]` for local only, avoid production reliance.
- `WAIN_*_SERVER_AUTH_TOKEN`, `WAIN_*_SERVER_APP_CHECK_TOKEN`: server-side proxy overrides; `[SM]` if still used in production, otherwise `[REMOVE]` after server minting is verified.
- `WAIN_SERVER_AUTH_REFRESH_TOKEN` and role-specific refresh token variants: refresh tokens; `[SM]` if needed, but prefer Admin SDK custom-token minting via ADC.
- `WAIN_ADMIN_STEP_UP_SIGNING_KEY_*SECRET*`: already designed for Secret Manager; keep `[SM]`.
- `WAIN_GOOGLE_OAUTH_ACCESS_TOKEN` / `GOOGLE_OAUTH_ACCESS_TOKEN`: explicit OAuth token fallback for Secret Manager access; `[REMOVE]` in production, prefer metadata-server ADC.

## 7. Migration Plan

Phase A - Low risk cleanup and documentation:

1. `[ADC]` Update runbooks to prefer `gcloud auth application-default login` or service-account impersonation over `service-account-key.json`.
2. `[REMOVE]` Delete ignored local `.tmp/*` probe scripts if no longer needed, especially files that reference service-account paths or smoke passwords.
3. `[ENV]` Keep `NEXT_PUBLIC_*FUNCTIONS_BASE_URL` and emulator flags in ignored env files.
4. `[ENV]` Keep `scripts/multi_agent/.env` local-only, or move provider keys to user-level environment variables.

Phase B - Medium risk developer workflow migration:

1. `[ADC]` Refactor local/admin scripts to try `admin.credential.applicationDefault()` first.
2. `[ADC]` Replace hard failures that demand `service-account-key.json` with clear ADC setup instructions.
3. `[REMOVE]` Remove `scripts/create_invite.js` direct `require("../service-account-key.json")` usage.
4. `[ADC]` Remove `process.env.GOOGLE_APPLICATION_CREDENTIALS = serviceAccountPath` assignments from staging rehearsal scripts after ADC is proven.

Phase C - Production hardening:

1. `[ADC]` Gate `admin_web_console/lib/firebase/server.ts` JSON credential loading to non-production, or remove it entirely after scripts no longer need JSON keys.
2. `[SM]` Move any live `WAIN_*_SERVER_AUTH_TOKEN`, `WAIN_*_SERVER_APP_CHECK_TOKEN`, or refresh-token overrides to Secret Manager if they remain necessary.
3. `[REMOVE]` Remove explicit `WAIN_GOOGLE_OAUTH_ACCESS_TOKEN` / `GOOGLE_OAUTH_ACCESS_TOKEN` use in production once metadata-server ADC works for Secret Manager.
4. `[REMOVE]` Rotate and delete the local `service-account-key.json` after all scripts and SSR startup work through ADC.

## 8. Risk Assessment

Low risk:

- Updating documentation and `.env.example`.
- Deleting stale ignored `.tmp` probe files.
- Keeping public Firebase config and base URLs in env files.
- Moving multi-agent provider keys to user-level environment variables.

Medium risk:

- Migrating local scripts from JSON key files to ADC, because every developer machine needs ADC setup.
- Removing `GOOGLE_APPLICATION_CREDENTIALS` assumptions from scripts and runbooks.
- Rotating the local service-account key, because any old script still depending on it will fail.

High risk:

- Changing `admin_web_console/lib/firebase/server.ts` production credential resolution without a staged deploy, because SSR Admin SDK calls depend on successful ADC initialization.
- Removing server auth/app-check override envs before confirming proxy token minting works for every admin command route.
- Changing Cloud Run or Functions runtime service account roles without a rollback plan.

## 9. Recommended Next Session

Start with Phase A and the lowest-risk Phase B item:

1. Update runbooks to document ADC-first setup.
2. Add a small shared script helper for Firebase Admin initialization that tries ADC first and only allows JSON key fallback in local/non-production scripts.
3. Migrate one non-critical script, such as `functions/scripts/seed_transport_mvp.js`, as the pilot.
4. Validate with ADC on Basil's machine before touching `admin_web_console/lib/firebase/server.ts`.
