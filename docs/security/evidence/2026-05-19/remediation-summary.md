# Security Remediation Summary

Date: 2026-05-19

This summary records the sanitized remediation results after the initial baseline report.
Raw Firebase CLI debug output is intentionally not retained here because earlier emulator
runs showed that debug mode can print process environment values.

## Service Account Key

- Local ignored `service-account-key.json` was removed from the assessment workspace.
- Git tracking check remains clean for that path.
- Evidence: `docs/security/evidence/2026-05-19/service-account-remediation/`
- Remaining owner action: confirm GCP IAM revocation/rotation status for the key outside this local repository.

## Dependency Audits

- Functions dependencies were upgraded to `firebase-admin@13.10.0`, `firebase-functions@7.2.5`, and `firebase@12.12.0`.
- Admin web dependencies were upgraded to `next@16.2.6`, `firebase-admin@13.10.0`, and `firebase@12.12.0`.
- `npm --prefix functions audit --omit=dev` no longer reports High or Critical advisories. It still exits non-zero with 9 Low advisories in the Firebase Admin transitive tree.
- `npm --prefix admin_web_console audit --omit=dev` no longer reports High or Critical advisories. It still exits non-zero with 8 Low and 2 Moderate advisories, including a Next/PostCSS advisory with no non-breaking npm audit fix.

## Code/Test Fixes

- `contentModerationCallableFlows.test.js` now seeds active `admins/{uid}` source-of-truth documents for content, finance, and super-admin test actors.
- `storage.rules` now denies direct client deletion for `venues/{venueId}/wallet_topups/{fileName}`.
- `storageSecurityRules.test.js` adds `W15b` to prove merchants and admins cannot directly delete wallet top-up receipts through Storage rules.
- Admin web auth/session code was updated for Next 16 async `headers()` / `cookies()` APIs.

## Verification

- `npm --prefix functions run build`: Pass.
- `npm --prefix functions test`: Pass, 63 tests.
- Functions emulator aggregate through Firebase emulator: Pass, 217 tests.
- `node --test test/rules/storageSecurityRules.test.js`: Pass, 19 tests.
- `npm --prefix admin_web_console run test:security`: Pass, 45 tests.
- `npm --prefix admin_web_console run build:secure`: Pass, bundle sentinel scan passed across 986 `.next` files.
- QA seed + finance verifier + audit verifier on emulator: Pass.
  - `QA finance verifier summary: wallets=2 fail=0 warn=0`
  - `QA audit verifier summary: audit_events=20 fail=0 warn=0`
- Current-session Flutter rerun was blocked because `flutter` is not available in PATH. The baseline Flutter analyze/test evidence remains the latest successful Flutter evidence.

