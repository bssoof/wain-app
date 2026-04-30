# Step-up Auth IAM Requirements

## Service Account

The Admin SSR runtime for project `wain-d2e28` runs as the Compute Engine default service account:

```text
620614484841-compute@developer.gserviceaccount.com
```

Preview channels and production use the same Admin SSR runtime service account unless a separate staging Firebase project is provisioned.

## Required Self-Binding

The service account must have `roles/iam.serviceAccountTokenCreator` on itself.

Why this is required:
- Firebase Admin SDK custom token minting calls `signBlob`.
- Server-side App Check token minting for live callable transport also depends on service account signing.
- Without this binding, finance command transport can fail before the command handler with App Check/proxy errors.

Observed failure signatures:

```text
Permission 'iam.serviceAccounts.signBlob' denied on resource (or it may not exist).
Finance command proxy requires an App Check token for live callable transport.
```

## Verification

```bash
gcloud iam service-accounts get-iam-policy \
  620614484841-compute@developer.gserviceaccount.com \
  --project=wain-d2e28 \
  --format="table(bindings.role,bindings.members)"
```

Expected policy includes:

```text
roles/iam.serviceAccountTokenCreator    serviceAccount:620614484841-compute@developer.gserviceaccount.com
```

## Remediation

If the binding is missing, restore it before preview smoke or production deployment:

```bash
SA="620614484841-compute@developer.gserviceaccount.com"

gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --member="serviceAccount:$SA" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=wain-d2e28
```

## Smoke Evidence

This requirement was confirmed during AWC-QA-017 Phase A preview smoke:
- Before the binding, finance commands failed at transport with `signBlob` / App Check errors.
- After the binding, the same dummy `approve_reversal` request reached the finance handler and returned `422`, proving the step-up middleware and transport pipeline reached business validation.

## Related

- AWC-QA-017 step-up auth rollout.
- Admin SSR function: `ssrwainadmin` in `us-central1`.
- Admin Hosting site: `wain-admin`.
- Release runbook: `docs/release/admin_web_console_release_runbook.md`.
