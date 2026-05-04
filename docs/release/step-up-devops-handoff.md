# Step-Up Auth Self-Managed Rollout

## Context
The admin web console now protects sensitive finance mutations with password step-up authentication. The browser reauthenticates the current Firebase user, the admin API issues a short-lived HTTP-only step-up JWT, and the finance command proxy rejects sensitive commands without a valid token.

This rollout is self-managed by the engineering owner. Do not deploy to production until smoke and key-rotation checks pass.

## Coordination
- Target branch for deploy validation: `feat/step-up-auth`.
- Current validated code commit: `adfdbc9`.
- Firebase project found in `.firebaserc`: `wain-d2e28`.
- Admin Hosting site: `wain-admin`.
- Admin SSR function: `ssrwainadmin` in `us-central1`.
- Runtime service account: `620614484841-compute@developer.gserviceaccount.com`.
- No separate staging Firebase project is currently configured in this repo. Treat preview-channel smoke as non-isolated unless a separate staging project is provisioned.

## Secret Manager Configuration
- Current secret name: `WAIN_ADMIN_STEP_UP_SIGNING_KEY`.
- The secret value must be 256-bit or stronger random material.
- Grant the admin web runtime service account `roles/secretmanager.secretAccessor` for this secret.
- The code fallback reads `projects/{GOOGLE_CLOUD_PROJECT}/secrets/WAIN_ADMIN_STEP_UP_SIGNING_KEY/versions/latest`, so no runtime env override is required for the current key.
- Use `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION` or `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_RESOURCE` only when pinning a specific current version is required.
- During rotation, configure `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION` or `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE` to the old version until the rotation window closes.

## Enforcement Toggle
Firestore document: `app_config/admin_step_up`.

```json
{
  "enforcementMode": "enabled | log_only | disabled",
  "bannerMessage": "optional admin-facing message",
  "bannerSeverity": "info | warning | critical",
  "updatedAt": "server timestamp",
  "updatedBy": "admin uid"
}
```

- `enabled`: enforce step-up and reject sensitive commands without a valid token.
- `log_only`: do not reject; log `step_up_log_only_would_reject` when enforcement would have blocked the command.
- `disabled`: bypass step-up entirely.
- Missing/invalid config or Firestore read failure defaults to `enabled`.
- Runtime cache TTL is 60 seconds per server instance.
- Firestore rules allow reads for active admins and writes only for `super_admin`.

## Audit Events
Step-up audit events are emitted to structured `[SECURITY_AUDIT]` logs and best-effort Firestore records in `admin_step_up_audit_events`.
Firestore write failures are logged but do not block admin commands.

- `step_up_required`: status endpoint would open the step-up modal for a sensitive command.
- `step_up_verified`: a sensitive command presented a valid step-up token.
- `step_up_rejected`: `enabled` mode rejected a sensitive command.
- `step_up_previous_key_verified`: dual-key rotation accepted a previous-key token.
- `step_up_log_only_would_reject`: `log_only` mode would have rejected but allowed the command.
- `step_up_rate_limited`: step-up issuance hit the password reauth lockout.

Required investigation fields: `userId`, `command`, `scope`, `reason` when applicable, `enforcementMode` when applicable, token age metadata for verified/rotation events, and no password or credential material.

## Health Endpoint
Endpoint: `GET /api/admin/step-up/health`.

- Public and unauthenticated for pre-deploy smoke checks.
- No PII and no secret values are returned.
- Rate limited to 60 requests per minute per IP per server instance.
- Returns `200` when `secret_manager`, `token_signing`, and `firestore_config` are healthy.
- Returns `503` with boolean/error-code checks when degraded.
- Returns `429` when the endpoint rate limit is exceeded.

## What Not To Do
- Do not commit signing keys or generated secret values to this repository.
- Do not send keys through Slack, email, tickets, screenshots, or logs.
- Do not configure direct `WAIN_ADMIN_STEP_UP_SIGNING_KEY` in production. Direct env signing keys are intentionally rejected in production.
- Do not share signing keys between staging and production.

## Key Generation
Generate the secret value outside the repo and add it directly to Secret Manager:

```bash
openssl rand -base64 64
```

## Verification
- Without admin auth, `POST /api/admin/step-up/issue` should fail closed.
- With a valid finance admin session and fresh Firebase reauth token, `POST /api/admin/step-up/issue` should return success and set the `wain_admin_step_up` HTTP-only cookie.
- `GET /api/admin/step-up/status?scope=finance&command=approve_topup` should report whether the finance step-up token is active or required.
- A sensitive finance command without the cookie should return explicit `STEP_UP_REQUIRED`.
- `verify_wallet_readiness` should not require step-up.

## Rotation Policy
1. Add a new Secret Manager version.
2. Deploy with the new version as current and the old version as previous.
3. Confirm old current-key tokens still verify through `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION`.
4. Confirm newly issued tokens verify after removing previous only if they were signed by the new current version.
5. Monitor `step_up_previous_key_verified` audit events. These events should go to zero after one full 15-minute token TTL plus deployment buffer.
6. Remove previous-key env/config after the observation window.
7. Disable or destroy the old secret version after rollback risk is closed.

## Staging Smoke Owner Checklist
- Login as `finance_admin`.
- Run a sensitive finance command and confirm the step-up modal appears.
- Enter wrong password three times and confirm `429` lockout countdown.
- After lockout expiry, enter the correct password and confirm command success.
- Run a second finance mutation within 15 minutes and confirm no modal appears.
- Wait at least 16 minutes and confirm the next sensitive command asks for step-up again.
- Logout and re-login, then confirm the old step-up cookie is not accepted.
- Confirm audit logs include command correlation ids and any previous-key verification events during rotation.

## Escalation
If step-up issuance returns `500`, check Secret Manager access first: secret resource name, IAM grant, and runtime project identity. If finance mutations return repeated `STEP_UP_REQUIRED` after successful issue, check cookie path/scope and signing-key version mismatch.
