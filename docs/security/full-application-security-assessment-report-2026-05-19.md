# WAIN Full Application Security Assessment Report

Date: 2026-05-19
Status: In progress
Release recommendation: No-Go

## 1. Tested Baseline

| Item | Value |
| --- | --- |
| Commit | `d880f1cc40410a1452e5ca085d578c6062c41795` |
| Git describe | `qa-final-2026-05-15-p11-5-gd880f1cc` |
| Evidence path | `docs/security/evidence/2026-05-19/phase-0-baseline/` |
| Assessment plan | `docs/security/full-application-security-assessment-plan-2026-05-19.md` |

The working tree was clean before evidence generation. The current untracked files are assessment evidence and this report.

## 2. Gate Verdict

Release remains blocked, but the first remediation pass cleared the main local technical blockers from the baseline run:

- Functions emulator aggregate now passes.
- Functions/Admin Web runtime audits no longer contain High or Critical advisories.
- Local ignored `service-account-key.json` was removed from the assessment workspace.
- Direct client deletion of wallet top-up proof files is now denied by Storage rules and covered by a rules test.
- Admin Web secure build passes after the controlled Next upgrade.

Remaining release blockers are evidence/governance gates that still need owner execution: cloud IAM key revocation/rotation proof, DAST or accepted exception, App Check product-level enforcement rollout or accepted risk, and any accepted risk records for residual Low/Moderate dependency advisories. The verified historical OpenAI key has owner-attested revocation evidence recorded on 2026-05-20; dashboard evidence is still recommended for external audit.

Update after the APK remediation pass: release APK build, SHA256, signing verification, manifest inspection, source/config emulator scan, runtime install/launch, screenshot, and logcat sensitive-data scan are now complete.

Update after the App Check code remediation pass: all reviewed callable exports under `functions/src` now call `requireAppCheck(context)`, and focused missing-App-Check regression tests pass for busy-times and menu import callables.

## 3. Command Results

| Gate | Result | Evidence |
| --- | --- | --- |
| `flutter analyze --no-pub` | Pass, no issues | `apk-inspection/flutter-analyze-after-host-obfuscation.*` |
| `flutter test --no-pub` | Pass, 368 tests | `apk-inspection/flutter-test-after-host-obfuscation.*` |
| `npm --prefix functions run build` | Pass | remediation summary |
| `npm --prefix functions test` | Pass, 64 tests | remediation summary |
| Functions emulator aggregate | Pass, 217 tests | remediation summary |
| Storage rules tests | Pass, 19 tests | remediation summary |
| `npm --prefix admin_web_console run test:security` | Pass, 45 tests | remediation summary |
| Admin extra security tests | Pass from `admin_web_console` cwd, 8 tests | `admin-web-extra-security-tests-workdir.*` |
| `npm --prefix admin_web_console run build:secure` | Pass | remediation summary |
| QA seed + finance verifier + audit verifier | Pass | remediation summary |
| Functions runtime dependency audit | Non-zero, 9 Low only; no High/Critical | remediation summary |
| Admin web runtime dependency audit | Non-zero, 8 Low / 2 Moderate only; no High/Critical | remediation summary |
| Flutter dependency inventory | Pass | `flutter-pub-deps.json` |
| Functions dependency inventory | Pass | `functions-npm-ls.json` |
| Admin web dependency inventory | Pass | `admin-web-npm-ls.json` |
| Release APK clean build | Pass | `apk-inspection/apk-inspection-summary.md` |
| Release APK SHA256 | Pass, `17982C20D4285427F000433D3E8DD8546B5D901804211288A737D1B026569A63` | `apk-inspection/app-release-sha256-after-clean-build.txt` |
| Release APK signing verification | Pass | `apk-inspection/apksigner-verify-print-certs-after-clean-build.txt` |
| Release APK source/config emulator scan | Pass for active release config; SDK raw-string false-positive context documented | `apk-inspection/source-emulator-config-scan-after-clean-build.txt`, `apk-inspection/apk-raw-string-scan-summary-after-clean-build.txt` |
| Release APK logcat sensitive scan | Pass, zero sensitive/crash/emulator matches | `apk-inspection/release-logcat-sensitive-scan-2026-05-20.txt` |
| Release APK runtime screenshot | Pass | `apk-inspection/screenshot-release-runtime-2026-05-20.png` |
| `gitleaks` current tracked tree | Pass, 0 findings after raw artifact cleanup and Firebase public-key allowlist | `git-history-secret-scan/gitleaks-current-tracked-after-redaction-summary-2026-05-20.md` |
| `gitleaks` Git all-ref scan | Pass, 0 findings after raw artifact cleanup and Firebase public-key allowlist | `git-history-secret-scan/gitleaks-git-all-after-redaction-summary-2026-05-20.md` |
| `trufflehog --only-verified` Git scan | Historical finding remediated by owner-attested revocation; raw secret value not retained | `git-history-secret-scan/trufflehog-verified-finding-summary-2026-05-20.md`, `git-history-secret-scan/openai-key-revocation-attestation-2026-05-20.md` |
| App Check app registration | Scoped pass for Android release: Android registered with Play Integrity, Web registered with reCAPTCHA, iOS explicitly out of scope for this Android release | `app-check/app-check-registration-evidence-2026-05-20.md` |
| App Check API enforcement | Not enforced for observed Firebase APIs: Storage/Firestore/Auth are Monitoring with significant unverified traffic; Functions product-level enforcement not proven | `app-check/app-check-api-enforcement-evidence-2026-05-20.md` |
| App Check code review/remediation | Pass for reviewed callable source: 51/51 callable exports under `functions/src` call `requireAppCheck`; focused missing-App-Check tests pass | `app-check/app-check-code-review-2026-05-20.md` |
| Play Console Internal Testing validation | Blocked: developer account setup/verification incomplete; AAB prepared for upload when account is ready | `app-check/play-console-internal-testing-blocker-2026-05-20.md` |

Finance verifier result:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=20 fail=0 warn=0
```

## 4. Findings And Blockers

### WAIN-SEC-001: Ignored local service account key exists

Finding type: Candidate Finding / Control Gap
Proposed severity: P0 if production or privileged; otherwise P1 control gap until classified
Status: Locally mitigated; cloud key inventory review found active non-expiring user-managed keys
Evidence strength: Code/config evidence plus owner-provided cloud console evidence
Release blocking: Yes until IAM owner classifies the active keys and records rotation/deletion or approved managed-credential plan

Baseline evidence showed `service-account-key.json` existed in the workspace root, was ignored and untracked, and contained a service account private key for project `wain-d2e28`. The local ignored file has now been removed from the assessment workspace. This is not proven to be committed to Git history.

Follow-up cloud-console review found two active user-managed keys for `firebase-adminsdk-fbsvc@wain-d2e28.iam.gserviceaccount.com`, created on 2026-02-04 and 2026-02-11, both with effective non-expiring expiration date `10000-01-01`. The owner reported no visible user-managed keys for `wain-d2e28@appspot.gserviceaccount.com` and `620614484841-compute@developer.gserviceaccount.com`.

Local usage search found multiple local scripts, admin web fallback paths, and runbook references that can use `service-account-key.json` or `GOOGLE_APPLICATION_CREDENTIALS`, including `admin_web_console/lib/firebase/server.ts`, `admin_web_console/scripts/mint-live-callable-tokens.mjs`, `functions/scripts/audit_admin_roles.js`, `functions/scripts/run_admin_web_staging_rehearsal.js`, and `scripts/create_invite.js`. The active Firebase Admin SDK keys must not be deleted blindly because they may still support local, staging, admin, or emergency workflows. Production release should not proceed until each key has an owner, purpose, usage inventory, and safe migration/rotation/deletion evidence, or a formally accepted managed-credential migration plan.

Evidence:

- `service-account-current-check.txt`
- `service-account-key-classification.txt`
- `git-history-service-account-paths.txt`
- `docs/security/evidence/2026-05-19/service-account-remediation/post-removal.txt`
- `docs/security/evidence/2026-05-19/iam-key-review/service-account-key-inventory-2026-05-20.md`
- `docs/security/evidence/2026-05-19/iam-key-review/service-account-key-local-usage-search-2026-05-20.md`

### WAIN-SEC-002: Functions runtime dependency audit reports Critical/High vulnerabilities

Finding type: Confirmed Finding
Proposed severity: P1 High baseline; residual P3 Low dependency backlog after remediation
Status: Remediated for release-blocking High/Critical policy; residual Low advisories remain
Evidence strength: Test evidence
Release blocking: No for High/Critical dependency policy; residual advisories need owner triage

Baseline `npm --prefix functions audit --omit=dev` reported 16 vulnerabilities including High and Critical advisories. Functions dependencies were upgraded to `firebase-admin@13.10.0`, `firebase-functions@7.2.5`, and `firebase@12.12.0`. The current runtime audit no longer reports High or Critical advisories; it still exits non-zero with 9 Low advisories in the Firebase Admin transitive tree where npm suggests a breaking downgrade.

Evidence:

- `functions-npm-audit-omit-dev.stdout.txt`
- `functions-npm-audit-omit-dev.exit.txt`
- `docs/security/evidence/2026-05-19/remediation-summary.md`

### WAIN-SEC-003: Admin web runtime dependency audit reports High vulnerabilities

Finding type: Confirmed Finding
Proposed severity: P1 High baseline; residual P2/P3 dependency backlog after remediation
Status: Remediated for release-blocking High/Critical policy; residual Moderate/Low advisories remain
Evidence strength: Test evidence
Release blocking: No for High/Critical dependency policy; residual advisories need risk/backlog decision

Baseline `npm --prefix admin_web_console audit --omit=dev` reported a High advisory against `next@14.2.35`. Admin Web was upgraded to `next@16.2.6`, and the auth/session code was updated for the async `headers()` / `cookies()` APIs. Security tests and secure build now pass. The current runtime audit no longer reports High or Critical advisories; it still exits non-zero with 8 Low and 2 Moderate advisories, including a Next/PostCSS advisory where npm's suggested fix is a breaking downgrade and should be tracked as residual risk/backlog.

Evidence:

- `admin-web-npm-audit-omit-dev.stdout.txt`
- `admin-web-npm-audit-omit-dev.exit.txt`
- `docs/security/evidence/2026-05-19/remediation-summary.md`

### WAIN-SEC-004: Functions emulator aggregate gate fails content moderation flows

Finding type: Candidate Finding / Setup Blocker
Proposed severity: P1 if authorization regression; P2 if emulator seed/setup only
Status: Closed as test fixture gap
Evidence strength: Test evidence
Release blocking: No

The local Firebase emulator aggregate gate initially failed the content moderation suite with `Requires admin privileges`. Root cause was a test fixture gap: the content moderation test supplied role claims but did not seed active `admins/{uid}` documents, while production code correctly requires the Firestore admin document as source-of-truth. The fixture now seeds active content, finance, and super-admin documents. The aggregate gate now passes 217 tests.

Evidence:

- `functions-test-emulator-aggregate-local-firebase.stdout.txt`
- `functions-test-emulator-aggregate-local-firebase.exit.txt`
- `functions/test/emulator/contentModerationCallableFlows.test.js`
- `docs/security/evidence/2026-05-19/remediation-summary.md`

### WAIN-SEC-005: Merchant-owned top-up proof files are deletable by the merchant in Storage rules

Finding type: Candidate Finding / Control Gap
Proposed severity: P1 if top-up proofs are required audit evidence; otherwise P2 retention gap
Status: Fixed as audit-evidence policy
Evidence strength: Code evidence
Release blocking: No

Baseline `storage.rules` allowed `delete` on `venues/{venueId}/wallet_topups/{fileName}` when the caller was the venue owner. Storage rules now deny all direct client deletes for wallet top-up proof files. Deletion must run through audited server-side maintenance or media governance paths that use trusted server credentials. A new `W15b` Storage rules test proves merchants and admins cannot directly delete wallet top-up receipts through client Storage rules.

Evidence:

- `storage-rules-numbered.txt`
- `storage.rules`
- `functions/test/rules/storageSecurityRules.test.js`
- `docs/security/evidence/2026-05-19/remediation-summary.md`

### WAIN-SEC-006: Full Git-history secret scan tooling and evidence

Finding type: Control Gap
Proposed severity: P2 Medium
Status: Remediated for active credential risk; verified historical OpenAI key revoked/rotated by owner attestation
Evidence strength: Runtime evidence plus owner attestation
Release blocking: No for the OpenAI key after owner-attested revocation; external audit should still attach dashboard/key-inventory evidence

`winget` source lookup failed locally, so official GitHub release binaries were downloaded to `.tmp/security-tools`: `gitleaks v8.30.1` and `trufflehog v3.95.3`. Raw tracked deployment logs, raw phase-0 secret grep outputs, and a tracked `.tmp` probe script were removed from the current repository tree. A narrow `.gitleaks.toml` allowlist now permits only public Firebase client API keys in known Firebase client config files. After those changes, `gitleaks` reports 0 findings for the current tracked tree and 0 findings for the all-ref Git scan. `trufflehog --only-verified` reports one verified historical OpenAI API key in commit `04be0317ddec0a0e26babfed2a6067d9529ba7ed`, file `scripts/multi_agent/.env.example`, line 4. The current file contains placeholders only. The repository owner attested on 2026-05-20 that the historical key was revoked/rotated.

Evidence:

- `tool-availability.txt`
- `git-history-service-account-paths.txt`
- `git-history-search-*.txt`
- `docs/security/evidence/2026-05-19/git-history-secret-scan/git-history-secret-scan-summary.md`
- `docs/security/evidence/2026-05-19/git-history-secret-scan/trufflehog-verified-finding-summary-2026-05-20.md`
- `docs/security/evidence/2026-05-19/git-history-secret-scan/openai-key-revocation-attestation-2026-05-20.md`

### WAIN-SEC-007: Admin web DAST gate did not run

Finding type: Control Gap
Proposed severity: P2 Medium
Status: Needs Execution or Accepted Exception
Evidence strength: Runtime evidence
Release blocking: Yes until completed or formally accepted

Admin web unit/security tests and secure build passed, and header/proof route tests passed when executed from `admin_web_console`. The DAST baseline scan did not run because Docker/ZAP is not available locally and no controlled admin URL was supplied for an equivalent scanner.

Evidence:

- `docker-version.*`
- `admin-web-extra-security-tests-workdir.*`

### WAIN-SEC-008: Firebase CLI debug output emitted full process environment during emulator runs

Finding type: Control Gap
Proposed severity: P2 Medium
Status: Mitigated in local evidence, needs command hardening
Evidence strength: Runtime evidence
Release blocking: No, unless repeated in committed CI logs

During emulator execution, Firebase CLI debug output emitted the process environment into stdout. The local evidence files were redacted, but future CI/security commands should avoid debug modes that print environment values and should route logs through redaction before retention.

Evidence:

- `evidence-redaction-note.md`

### WAIN-SEC-009: App Check is Monitoring for key Firebase APIs

Finding type: Control Gap
Proposed severity: P1 High for financial callables until enforcement state is proven; P2 Medium for non-financial Firebase products
Status: Confirmed control gap; Storage, Firestore, and Authentication are Monitoring, not Enforced
Evidence strength: Cloud console screenshot/owner evidence
Release blocking: Yes until sensitive product/function enforcement is remediated or formally accepted

Owner-provided Firebase Console evidence shows `wain-android` / `com.wain.wain_app` is registered with Play Integrity and `wain-web` is registered with reCAPTCHA. The same evidence shows `wain-ios` is not registered. Owner confirmed on 2026-05-20 that the current production release scope is Android only, so this is not a blocker for the Android release. iOS App Check registration becomes mandatory before any iOS production candidate.

Owner-provided App Check API evidence shows Cloud Storage is in Monitoring mode with 60% verified / 40% unverified requests, Cloud Firestore is in Monitoring mode with 54% verified / 46% unverified requests, and Firebase Authentication is in Monitoring mode with 9% verified / 91% unverified requests. Monitoring mode does not block unverified requests.

Detailed owner-provided metrics show Cloud Storage has 6 / 10 verified requests, 2 / 10 outdated-client requests, and 2 / 10 invalid requests. Cloud Firestore has approximately 2.3K / 4.4K verified requests, 297 / 4.4K outdated-client requests, and 1.7K / 4.4K invalid requests. Firebase Authentication has 6 / 70 verified requests, 16 / 70 outdated-client requests, 36 / 70 unknown-origin requests, and 12 / 70 invalid requests. These rates are not safe for immediate enforcement without traffic-source investigation.

After installing the current locally built release APK on a physical Android device and performing login plus image upload, owner-provided Storage metrics moved to 6 / 13 verified and 5 / 13 invalid. Local `apksigner` evidence shows the APK signing certificate SHA-256 matches one of the Firebase Android app fingerprints, so the invalid Storage traffic is not explained by a missing Firebase SHA fingerprint. The next controlled validation should install the same signed build through Google Play Internal Testing rather than direct `adb install`.

The Android App Bundle for Internal Testing is prepared at `build/app/outputs/bundle/release/app-release.aab` with SHA256 `E77D537F43756E1FE35D3DFE8BE79C2DF2038F5E244D1C83E32DFE43694FC0D8`. Owner-provided Play Console evidence shows Internal Testing is currently blocked because developer account setup is not complete. Identity verification has been submitted to Google, and contact phone verification remains required.

Cloud Functions product-level enforcement state is not proven by the captured table and must be verified separately. Code-level callable enforcement is now complete for the reviewed `functions/src` callable exports. Because the unverified percentages are high for other Firebase APIs, immediate enforcement could break legitimate traffic unless the traffic source is understood and remediated first. Do not click `Enforce` for Storage, Firestore, or Authentication until the unknown-origin and invalid request sources are explained or accepted under policy.

Evidence:

- `docs/security/evidence/2026-05-19/app-check/app-check-registration-evidence-2026-05-20.md`
- `docs/security/evidence/2026-05-19/app-check/app-check-api-enforcement-evidence-2026-05-20.md`
- `docs/security/evidence/2026-05-19/app-check/app-check-code-review-2026-05-20.md`
- `docs/security/evidence/2026-05-19/app-check/play-console-internal-testing-blocker-2026-05-20.md`

### WAIN-SEC-010: Operational callables missing App Check

Finding type: Control Gap / Candidate Finding
Proposed severity: P2 Medium; raise to P1 if menu OCR/import invokes paid external APIs or materially affects production cost/availability
Status: Remediated in code and covered by focused tests
Evidence strength: Code evidence and test evidence
Release blocking: No for this code-level gap

Local code review originally found 51 callable exports under `functions/src`; 44 called `requireAppCheck(context)`. The missing seven operational callables were `backfillVenueBusyTimes`, `createMenuImportJob`, `runMenuOcr`, `extractMenuCandidates`, `mapExtractedMenu`, `processMenuImport`, and `enqueueMenuImport`.

The remediation added `requireAppCheck(context)` to all seven. Current callable inventory result is `total_onCall=51`, `with_requireAppCheck=51`, `without_requireAppCheck=0`. New tests prove missing App Check is rejected for `backfillVenueBusyTimes` and the six menu import callables, while the positive menu import flow still passes through the Firestore emulator.

Evidence:

- `docs/security/evidence/2026-05-19/app-check/app-check-code-review-2026-05-20.md`
- `functions/test/busy_times_app_check.test.js`
- `functions/test/emulator/menuImportPipeline.test.js`

## 5. Positive Evidence

- Flutter static analysis passes with no issues.
- Flutter test suite passes.
- Functions TypeScript build and non-emulator unit tests pass.
- Functions emulator aggregate now passes with 217 tests.
- Admin web security test suite and secure build pass.
- Admin web security headers and top-up proof proxy tests pass when run from `admin_web_console`.
- Finance and audit verifiers pass on seeded emulator data with `fail=0 warn=0`.
- Firestore rules show wallet and ledger writes denied to clients in key wallet paths.
- Storage rules enforce image/video content-type and size limits for configured upload paths.
- Storage rules deny direct client deletion of wallet top-up proof files.
- Admin web production bundle token sentinel scan passes.
- Runtime dependency audits no longer contain High or Critical advisories after controlled package upgrades.
- Release APK clean build, SHA256, signing verification, manifest/source emulator-config inspection, runtime launch, screenshot, and logcat scan are recorded.
- Android release network security config denies cleartext by default; emulator cleartext is limited to debug manifest scope.
- Dedicated local `gitleaks` scans pass with zero findings after raw artifact cleanup and Firebase public-key allowlisting.
- App Check registration evidence confirms Android Play Integrity registration and Web reCAPTCHA registration; iOS is documented as out of scope for the current Android release.
- App Check code review confirms all reviewed callable exports under `functions/src` use `requireAppCheck(context)`.

## 6. Incomplete Gates

The following gates are not yet complete in this execution pass:

- Firestore query authorization tests, including collection and collection group negative tests.
- Broader malicious upload handling evidence beyond content-type/size rules, such as malware/metadata policy.
- App Check product-level enforcement rollout or accepted risk, including Play Console account verification, Google Play Internal Testing validation, investigation of unverified Storage/Firestore/Auth traffic, and completion of the rate-limit matrix for sensitive callables.
- DAST baseline for the admin web console.
- Optional stronger audit evidence for the verified historical OpenAI key revocation, such as a dashboard screenshot or key inventory export without secret values.
- Cloud IAM key usage classification, rotation/deletion evidence, and access-review evidence.
- Backup/restore drill evidence.
- External penetration-test completion or formally accepted deferral.

## 7. Review 4 Triage Additions

The fourth external review has been accepted as assessment input and saved as `docs/security/security-assessment-review-input-4-2026-05-19.md`. Its items are not automatically confirmed findings; they are queued for validation under the candidate/control-gap lifecycle.

New or emphasized validation items:

- Compliance scope: determine whether PCI-DSS, GDPR, or local privacy law applies based on payment-card data flow, user geography, and legal/security owner decision.
- Auth/session: test stale custom claims after role downgrade/deactivation and verify revoked-token behavior.
- Conditional Phone Auth controls: if Phone OTP is enabled, document and test brute-force, enumeration, and abuse protections.
- Conditional Firebase surfaces: inventory Anonymous Auth, FCM, Remote Config, and A/B Testing and mark each applicable or not applicable.
- HTTP/API hardening: review CORS, CSRF, cache, and security headers for any `onRequest` function or Admin Web proxy route.
- Availability/cost: review high-cardinality Firestore listeners and wallet anomaly alerting.
- Financial concurrency: add cross-instance wallet mutation race tests beyond same-request replay tests.
- Backup integrity: make an architecture decision on ledger tamper-evidence such as hash-chain, immutable export, signed daily tail hash, or an equivalent control.

## 8. Recommended Next Execution Steps

1. Classify the two active non-expiring Firebase Admin SDK service account keys, then rotate/delete them safely or document an approved managed-credential migration plan.
2. Run DAST against a controlled local/staging admin web URL or file an approved time-boxed exception.
3. File residual dependency advisories as accepted risk or backlog items with owner/expiry where required.
4. Complete Play Console developer account setup, then investigate App Check unverified traffic with a Google Play Internal Testing install retest and prepare a controlled move from Monitoring to Enforced or file an accepted risk.
5. Validate the Review 4 additions, especially stale-claims behavior, Phone Auth applicability, FCM/Remote Config applicability, listener abuse, and wallet anomaly alerting.
6. Attach optional stronger OpenAI key revocation evidence for external audit.

## 9. Current Recommendation

No-Go until the remaining evidence/governance gates are complete. The local remediation pass cleared the dependency High/Critical blockers, Functions emulator aggregate failure, top-up proof direct-delete gap, release APK build/config/runtime inspection, gitleaks current/all-ref findings, the active credential risk from the verified historical OpenAI key by owner-attested revocation, and the code-level App Check gap for operational callables. App Check registration evidence is captured for Android and Web, and all reviewed callable exports under `functions/src` now enforce App Check in code, but Storage, Firestore, and Authentication are currently in Monitoring mode with significant unverified traffic. Google Play Internal Testing validation is blocked on developer account setup. The next milestone is collecting IAM/key revocation proof, running DAST or filing an accepted exception, and completing Play Console verification so App Check product-level enforcement can be validated.
