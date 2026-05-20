# App Check Code Review

Date: 2026-05-20

## Scope

Reviewed local code for:

- Flutter App Check initialization.
- Android release provider selection.
- Cloud Functions callable App Check enforcement.
- Admin web callable proxy App Check token handling.
- Existing test references for App Check failures.

## Commands

```powershell
rg -n "FirebaseAppCheck|firebase_app_check|AppCheck|activate\(|PlayIntegrity|AndroidProvider|AppleProvider|ReCaptcha|reCAPTCHA" pubspec.yaml pubspec.lock lib android admin_web_console functions/src functions/package.json
rg -n "onCall|onRequest|enforceAppCheck|requireAppCheck|wallet|topup|reversal|approve|finance|admin" functions/src
rg -n "functions\.https\.onRequest|onRequest\(" functions/src
```

Callable inventory script result:

```text
total_onCall=51
with_requireAppCheck=51
without_requireAppCheck=0
```

No `functions.https.onRequest` exports were found in `functions/src`.

## Flutter Client

| Control | Evidence |
| --- | --- |
| App Check dependency exists | `pubspec.yaml` includes `firebase_app_check`; `pubspec.lock` resolves the package. |
| App Check initialization runs after Firebase init | `lib/main.dart:92-93` calls `_initializeAppCheck()` when Firebase is ready and the platform is not Windows. |
| Android release provider | `lib/main.dart:189-197` uses `AndroidProvider.playIntegrity` in release and debug provider outside release. |
| Web provider | `lib/main.dart:170-181` uses `ReCaptchaV3Provider` only when `WAIN_WEB_RECAPTCHA_SITE_KEY` is set. |
| iOS provider in code | `lib/main.dart:194-196` uses `AppleProvider.deviceCheck` in release, but Firebase Console evidence shows the iOS app is not registered. |

Assessment: Android release code is configured to request Play Integrity App Check tokens. Web App Check can be skipped if `WAIN_WEB_RECAPTCHA_SITE_KEY` is missing. iOS code has a release provider, but the Firebase Console registration gap remains if iOS is in release scope.

## Cloud Functions Enforcement Pattern

Shared helper:

```text
functions/src/shared/app-check.ts:3-9
```

The helper fails closed when `context.app` is missing:

```text
if (!context.app) throw HttpsError("failed-precondition", ...)
```

The codebase uses Firebase Functions v1 callable exports and manual `requireAppCheck(context)` checks rather than only relying on product-level console enforcement.

## Financial And Admin Callable Coverage

The high-risk financial/admin surfaces reviewed include `requireAppCheck(context)`:

| Function | Evidence |
| --- | --- |
| `createMerchantTopUpRequest` | `functions/src/wallet_runtime_mutations.ts:247-249` |
| `reviewMerchantTopUpRequest` | `functions/src/wallet_runtime_mutations.ts:436-438` |
| `reverseWalletEntry` | `functions/src/wallet_runtime_mutations.ts:1047-1049` |
| `createMerchantWalletReversalRequest` | `functions/src/wallet_runtime_mutations.ts:1254-1260` |
| `reviewMerchantWalletReversalRequest` | `functions/src/wallet_runtime_mutations.ts:1358-1360` |
| `approveWalletReversalRequest` | `functions/src/wallet_runtime_mutations.ts:1534-1536` |
| `promoteStory` | `functions/src/wallet_runtime_mutations.ts:1801-1807` |
| `pinOffer` | `functions/src/wallet_runtime_mutations.ts:2072-2077` |
| `listMerchantTopUpRequestsForAdmin` | `functions/src/wallet_admin_reads.ts:30-33` |
| `listMerchantWalletLedgerEntriesForAdmin` | `functions/src/wallet_admin_reads.ts:172-175` |

Assessment: the primary wallet, top-up, reversal, paid promotion, paid pinning, and admin wallet read callables are code-enforced with App Check before sensitive work.

## Callable Gap Remediation

The prior review found seven operational callables without `requireAppCheck(context)`. They have been remediated:

| Function | Evidence |
| --- | --- |
| `backfillVenueBusyTimes` | `functions/src/busy_times/job.ts:350-351` |
| `createMenuImportJob` | `functions/src/menu_import.ts:2375-2376` |
| `runMenuOcr` | `functions/src/menu_import.ts:2497-2498` |
| `extractMenuCandidates` | `functions/src/menu_import.ts:2516-2517` |
| `mapExtractedMenu` | `functions/src/menu_import.ts:2535-2536` |
| `processMenuImport` | `functions/src/menu_import.ts:2590-2591` |
| `enqueueMenuImport` | `functions/src/menu_import.ts:2616-2617` |

All callable exports under `functions/src` now call `requireAppCheck(context)` in the reviewed source window.

## Admin Web Proxy

Admin web proxy code includes server-side App Check token handling:

- `admin_web_console/lib/firebase/server-app-check.ts:19-64` mints and caches server App Check tokens with Firebase Admin App Check.
- `admin_web_console/app/api/admin/command/shared/proxy-helpers.ts` resolves configured, minted, or request App Check tokens for live callable transport.
- Existing tests cover minted-token preference and missing-token rejection in `admin_web_console/lib/admin-command-proxy/proxy-helpers.test.ts`.

## Test Coverage Observations

Existing emulator/security tests include App Check failure checks for some surfaces:

- `functions/test/emulator/securityCallableFlows.test.js:507` invite flow missing App Check test.
- `functions/test/emulator/venueManagementCallableFlows.test.js:592` venue create missing App Check test.
- `functions/test/emulator/venueManagementCallableFlows.test.js:769` admin venue list missing App Check test.
- `functions/test/emulator/transportCallableFlows.test.js:195` transport quote missing App Check test.

New regression coverage added in this remediation pass:

- `functions/test/busy_times_app_check.test.js` proves `backfillVenueBusyTimes` rejects missing App Check before work.
- `functions/test/emulator/menuImportPipeline.test.js` proves the six menu import callables reject missing App Check and keeps the existing positive menu import flow coverage passing.

Focused validation:

```powershell
npm --prefix functions test
npx firebase-tools --config ../firebase.json emulators:exec --project demo-wain-analytics --only firestore "node --test --test-concurrency=1 test/emulator/menuImportPipeline.test.js"
```

Results:

- `npm --prefix functions test`: Pass, 64 tests.
- Menu import emulator test: Pass, 21 tests.

## Findings

### APPCHK-CODE-001: Financial callables enforce App Check in code

Type: Positive evidence
Status: Passed code review

The primary financial mutation/read callables have explicit `requireAppCheck(context)` checks.

### APPCHK-CODE-002: Menu import and busy-times callables lack App Check

Type: Control Gap / Candidate Finding
Proposed severity: P2 Medium; raise to P1 if menu OCR/import invokes paid external APIs or materially affects production cost/availability.
Status: Remediated in code and covered by tests
Release blocking: No for this code-level gap.

Implemented fix:

1. Added `requireAppCheck(context)` to the seven uncovered callables.
2. Added regression tests proving missing `context.app` is rejected.
3. Re-ran Functions unit tests and the focused menu import emulator test successfully.

Remaining note: Firebase Console metrics still show Storage, Firestore, and Authentication in Monitoring mode with unverified traffic. Product-level enforcement rollout remains a separate release gate.

## Current Verdict

Code-level App Check enforcement is now complete for the reviewed callable exports under `functions/src` (`51/51`). The remaining App Check gap is Firebase Console product-level Monitoring mode for direct Firebase APIs and cloud-side enforcement rollout evidence.
