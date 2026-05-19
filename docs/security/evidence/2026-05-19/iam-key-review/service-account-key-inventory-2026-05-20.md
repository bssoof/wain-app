# Service Account Key Inventory Evidence

Date: 2026-05-20
Source: Owner-provided Google Cloud Console observation.
Project: `wain-d2e28`

## Scope

This evidence records a manual review of Google Cloud IAM service account keys. No key material was shared or recorded.

## Observed Service Accounts

| Service account | Console area | Observation |
| --- | --- | --- |
| `firebase-adminsdk-fbsvc@wain-d2e28.iam.gserviceaccount.com` | IAM & Admin > Service Accounts > Keys | Two active user-managed keys are present |
| `wain-d2e28@appspot.gserviceaccount.com` | IAM & Admin > Service Accounts > Keys | Owner reported no user-managed keys visible |
| `620614484841-compute@developer.gserviceaccount.com` | IAM & Admin > Service Accounts > Keys | Owner reported no user-managed keys visible |

## Key Rows Observed

| Type | Status | Creation date | Expiration date |
| --- | --- | --- | --- |
| Not captured | Active | 2026-02-04 | 10000-01-01 |
| Not captured | Active | 2026-02-11 | 10000-01-01 |

The key IDs and secret values are intentionally not recorded in repository evidence.

## Assessment

Two active non-expiring user-managed service account keys remain on the Firebase Admin SDK service account. The App Engine default service account and Compute Engine default service account were reported as having no visible user-managed keys.

The active Firebase Admin SDK keys are a release-blocking IAM governance gap until their purpose and usage are classified.

Do not delete these keys blindly. Required safe path:

1. Identify every consumer of each key: CI secrets, local `.env`, deploy scripts, Cloud Build/GitHub Actions, admin tooling, and emergency runbooks.
2. Replace long-lived key usage with Workload Identity Federation or platform-managed credentials where possible.
3. If a key is still required, rotate it safely: create replacement, update secret manager/CI, verify deploy and admin workflows, then delete the old key.
4. If a key is unused or unknown, delete it after owner approval and record the deletion timestamp.
5. Record final key inventory evidence showing no unmanaged or ownerless production-capable keys.

Additional local usage evidence is recorded in `service-account-key-local-usage-search-2026-05-20.md`.

## Current Verdict

Status: Needs classification and rotation/deletion plan.
Release blocking: Yes.
