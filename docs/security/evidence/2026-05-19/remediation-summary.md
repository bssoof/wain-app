# Security Remediation Summary

Date: 2026-05-19

This summary records the sanitized remediation results after the initial baseline report.
Raw Firebase CLI debug output is intentionally not retained here because earlier emulator
runs showed that debug mode can print process environment values.

## Service Account Key

- Local ignored `service-account-key.json` was removed from the assessment workspace.
- Git tracking check remains clean for that path.
- Interim all-ref Git history scan covered 233 commits. The high-confidence object-path scan for service account keys, `.env`, signing material, PEM/P12/JKS/keystore files, and `key.json` paths returned `NO_OBJECT_PATH_MATCHES`.
- Dedicated `gitleaks`/`trufflehog` evidence was generated locally after downloading official GitHub release binaries to `.tmp/security-tools`.
- Tracked current tree and all-ref Git scan pass after removing tracked raw log/probe/evidence artifacts and adding a narrow Firebase public client API-key allowlist.
- `trufflehog --only-verified` reported one verified historical OpenAI API key in commit `04be0317ddec0a0e26babfed2a6067d9529ba7ed`, file `scripts/multi_agent/.env.example`, line 4. The current file contains placeholders only. The repository owner attested on 2026-05-20 that the historical key was revoked/rotated; dashboard evidence is still recommended for external audit.
- Evidence: `docs/security/evidence/2026-05-19/service-account-remediation/`
- Interim Git history evidence: `docs/security/evidence/2026-05-19/git-history-secret-scan/`
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
- Release Android network security config now disables cleartext in the main APK config; emulator cleartext remains debug-only.
- Firebase emulator setup now runs only when `WAIN_USE_FIREBASE_EMULATORS=true`.
- WAIN-owned emulator host literals were removed from release source and user-facing localization.

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
- `flutter analyze --no-pub`: Pass, no issues, using `C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat`.
- `flutter test --no-pub`: Pass, 368 tests.
- Clean release APK build: Pass.
  - Artifact: `build/app/outputs/flutter-apk/app-release.apk`
  - SHA256: `17982C20D4285427F000433D3E8DD8546B5D901804211288A737D1B026569A63`
  - APK signing verification: Pass.
  - Source/config emulator scan: active release sources no longer contain `10.0.2.2`, `127.0.0.1`, or `localhost`; remaining matches are dart-define names and debug-only cleartext manifest.
  - Raw APK binary scan still sees FlutterFire/Flutter SDK helper literals for emulator/debug strings; documented as false-positive context in `docs/security/evidence/2026-05-19/apk-inspection/apk-inspection-summary.md`.
  - Runtime emulator install/launch/logcat scan on 2026-05-20: Pass.
  - Sensitive logcat scan found zero matches for ID tokens, refresh tokens, Bearer tokens, Authorization headers, emulator hosts, fatal crashes, Flutter errors, proof URLs, passwords, secrets, or OTP terms.
