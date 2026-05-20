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
with_requireAppCheck=44
without_requireAppCheck=7
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

## Callable Gaps

Seven callable exports do not call `requireAppCheck(context)` in their first execution path:

| Function | File | Current controls observed |
| --- | --- | --- |
| `backfillVenueBusyTimes` | `functions/src/busy_times/job.ts:349` | Requires auth and resolves authorized merchant venue, but no App Check. |
| `createMenuImportJob` | `functions/src/menu_import.ts:2374` | Requires auth and merchant venue ownership, but no App Check. |
| `runMenuOcr` | `functions/src/menu_import.ts:2494` | Requires auth and merchant venue ownership, but no App Check. |
| `extractMenuCandidates` | `functions/src/menu_import.ts:2511` | Requires auth and merchant venue ownership, but no App Check. |
| `mapExtractedMenu` | `functions/src/menu_import.ts:2528` | Requires auth and merchant venue ownership, but no App Check. |
| `processMenuImport` | `functions/src/menu_import.ts:2581` | Requires auth and merchant venue ownership, but no App Check. |
| `enqueueMenuImport` | `functions/src/menu_import.ts:2605` | Requires auth and merchant venue ownership, but no App Check. |

These are not direct wallet mutation surfaces, but they are still callable operational surfaces. The menu import flow can create jobs and run OCR/extraction/mapping pipeline stages, so missing App Check can increase abuse, cost, and forged-client risk from authenticated but modified clients.

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

No App Check-specific missing-token tests were found for the seven uncovered `menu_import` / `busy_times` callables.

## Findings

### APPCHK-CODE-001: Financial callables enforce App Check in code

Type: Positive evidence
Status: Passed code review

The primary financial mutation/read callables have explicit `requireAppCheck(context)` checks.

### APPCHK-CODE-002: Menu import and busy-times callables lack App Check

Type: Control Gap / Candidate Finding
Proposed severity: P2 Medium; raise to P1 if menu OCR/import invokes paid external APIs or materially affects production cost/availability.
Status: Needs remediation or accepted risk
Release blocking: Yes if the release policy requires App Check on all sensitive/operational callables.

Recommended fix:

1. Add `requireAppCheck(context)` to the seven uncovered callables.
2. Add emulator tests proving each rejects missing `context.app`.
3. Validate Android/Web App Check token generation first, because current Firebase Console metrics show significant unverified traffic.
4. Roll out with staged QA after ensuring legitimate clients provide App Check tokens.

## Current Verdict

Code-level App Check enforcement is strong on wallet/financial callable paths. The remaining code gap is concentrated in menu import and busy-times operational callables, plus Firebase Console product-level Monitoring mode for direct Firebase APIs.
