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
- Remaining owner action: classify and rotate/delete active non-expiring user-managed service account keys observed for `firebase-adminsdk-fbsvc@wain-d2e28.iam.gserviceaccount.com`. Owner reported no visible user-managed keys for the App Engine default and Compute Engine default service accounts.

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
- `npm --prefix functions test`: Pass, 64 tests.
- Functions emulator aggregate through Firebase emulator: Pass, 217 tests.
- `node --test test/rules/storageSecurityRules.test.js`: Pass, 19 tests.
- `npm --prefix admin_web_console run test:security`: Pass, 45 tests.
- `npm --prefix admin_web_console run build:secure`: Pass, bundle sentinel scan passed across 986 `.next` files.
- Admin Web DAST remains blocked because Docker is not available locally. Fresh compensating checks on 2026-05-20: `test:security` passed 45 tests and `build:secure` passed the bundle sentinel scan.
- Admin Web secure-build NFT tracing warning was remediated on 2026-05-20 by scoping the Next/Turbopack root to `admin_web_console` and marking development-only service account file probes as `turbopackIgnore`; post-fix `build:secure` passed without the NFT tracing warning.
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

## App Check Evidence

- Owner-provided Firebase Console evidence shows `wain-android` / `com.wain.wain_app` is registered with Play Integrity.
- Owner-provided Firebase Console evidence shows `wain-web` is registered with reCAPTCHA.
- Owner-provided Firebase Console evidence shows `wain-ios` is not registered. Owner confirmed the current release is Android only, so iOS App Check registration is out of scope for this Android release and becomes mandatory before any iOS production candidate.
- API-level App Check evidence shows Cloud Storage is Monitoring with 60% verified / 40% unverified requests.
- API-level App Check evidence shows Cloud Firestore is Monitoring with 54% verified / 46% unverified requests.
- API-level App Check evidence shows Firebase Authentication is Monitoring with 9% verified / 91% unverified requests.
- Detailed metrics show Cloud Storage has 2 / 10 outdated-client and 2 / 10 invalid requests; Cloud Firestore has approximately 1.7K / 4.4K invalid requests; Firebase Authentication has 36 / 70 unknown-origin requests.
- After sideloading the current release APK and performing login plus image upload, Storage metrics moved to 6 / 13 verified and 5 / 13 invalid. The APK signing certificate SHA-256 matches a Firebase Android app fingerprint, so the invalid Storage traffic is not explained by a missing SHA fingerprint.
- Google Play Internal Testing validation is blocked because Play Console still requires completion of developer account setup. Prepared AAB: `build/app/outputs/bundle/release/app-release.aab`, SHA256 `E77D537F43756E1FE35D3DFE8BE79C2DF2038F5E244D1C83E32DFE43694FC0D8`.
- Cloud Functions product-level enforcement state is still not proven; code-level callable helper coverage is complete in `functions/src`.
- Local code review now finds 51 callable exports under `functions/src`: 51 call `requireAppCheck(context)`.
- The previous code-level gap for `backfillVenueBusyTimes` and six menu import callables was remediated with `requireAppCheck(context)`.
- New focused App Check tests pass:
  - `npm --prefix functions test`: Pass, 64 tests.
  - Menu import emulator test through Firebase emulator: Pass, 21 tests.
