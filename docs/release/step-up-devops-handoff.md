# Step-Up Auth DevOps Handoff

## Context
The admin web console now protects sensitive finance mutations with password step-up authentication. The browser reauthenticates the current Firebase user, the admin API issues a short-lived HTTP-only step-up JWT, and the finance command proxy rejects sensitive commands without a valid token.

This is a pre-production setup request. Do not deploy to production until staging smoke and key-rotation smoke pass.

## Coordination
- Target branch for staging deploy: `feat/step-up-auth`.
- Current validated commit: `54fb691`.
- Estimated DevOps work: 1-2 days.
- Primary coordination channel: `#admin-platform` or a tracked issue labeled `step-up-rollout`.
- Contact: replace `[owner handle/email]` with the admin web owner before sending.
- Please confirm receipt and provide an ETA for staging Secret Manager setup.
- Any Secret Manager blocker pauses Phase 1 admin QA remediation until resolved.

## What DevOps Needs To Configure
- Create a staging Secret Manager secret named `wain-admin-step-up-signing-key` with a 256-bit or stronger random value.
- Create a separate production Secret Manager secret with a different value. Do not reuse staging material.
- Grant the admin web runtime service account `roles/secretmanager.secretAccessor` for the required secret versions only.
- Configure `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_VERSION` or `WAIN_ADMIN_STEP_UP_SIGNING_KEY_SECRET_RESOURCE` in each target environment.
- During rotation, configure `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_VERSION` or `WAIN_ADMIN_STEP_UP_SIGNING_KEY_PREVIOUS_SECRET_RESOURCE` to the old version until the rotation window closes.

## What DevOps Should Not Do
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
