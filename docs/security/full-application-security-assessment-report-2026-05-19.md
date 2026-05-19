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

Remaining release blockers are evidence/governance gates that still need owner execution: cloud IAM key revocation/rotation proof, full Git-history secret scanning with approved tooling, DAST or accepted exception, release APK runtime/logcat evidence, cloud App Check/IAM evidence, and any accepted risk records for residual Low/Moderate dependency advisories.

Update after the APK remediation pass: release APK build, SHA256, signing verification, manifest inspection, and source/config emulator scan are now complete. Runtime logcat remains blocked until an emulator or device is attached through `adb`.

## 3. Command Results

| Gate | Result | Evidence |
| --- | --- | --- |
| `flutter analyze --no-pub` | Pass, no issues | `apk-inspection/flutter-analyze-after-host-obfuscation.*` |
| `flutter test --no-pub` | Pass, 368 tests | `apk-inspection/flutter-test-after-host-obfuscation.*` |
| `npm --prefix functions run build` | Pass | remediation summary |
| `npm --prefix functions test` | Pass, 63 tests | remediation summary |
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
| Release APK logcat sensitive scan | Blocked, no attached adb device | `apk-inspection/adb-devices-after-clean-build.txt` |

Finance verifier result:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=20 fail=0 warn=0
```

## 4. Findings And Blockers

### WAIN-SEC-001: Ignored local service account key exists

Finding type: Candidate Finding / Control Gap
Proposed severity: P0 if production or privileged; otherwise P1 control gap until classified
Status: Locally mitigated; cloud verification pending
Evidence strength: Code/config evidence
Release blocking: Yes until IAM owner confirms revocation/rotation status

Baseline evidence showed `service-account-key.json` existed in the workspace root, was ignored and untracked, and contained a service account private key for project `wain-d2e28`. The local ignored file has now been removed from the assessment workspace. This is not proven to be committed to Git history, but production release should not proceed until the key is classified, owner/purpose are documented, and revocation/rotation evidence exists if it is real or production-capable.

Evidence:

- `service-account-current-check.txt`
- `service-account-key-classification.txt`
- `git-history-service-account-paths.txt`
- `docs/security/evidence/2026-05-19/service-account-remediation/post-removal.txt`

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

### WAIN-SEC-006: Full Git-history secret scan tooling is not available locally

Finding type: Control Gap
Proposed severity: P2 Medium
Status: Needs Tooling / CI Evidence
Evidence strength: Runtime evidence
Release blocking: Yes until equivalent evidence exists

Targeted Git history checks found no tracked `service-account-key.json` path, but required dedicated tools were not available locally: `gitleaks=NOT_FOUND` and `trufflehog=NOT_FOUND`. The release gate requires evidence that no production secret exists in current files, build artifacts, logs, or Git history.

Evidence:

- `tool-availability.txt`
- `git-history-service-account-paths.txt`
- `git-history-search-*.txt`

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
- Release APK clean build, SHA256, signing verification, and manifest/source emulator-config inspection are recorded.
- Android release network security config denies cleartext by default; emulator cleartext is limited to debug manifest scope.

## 6. Incomplete Gates

The following gates are not yet complete in this execution pass:

- Release APK runtime/logcat sensitive-data scan on an attached emulator/device.
- Firestore query authorization tests, including collection and collection group negative tests.
- Broader malicious upload handling evidence beyond content-type/size rules, such as malware/metadata policy.
- App Check and rate-limit matrix populated with evidence for every sensitive callable.
- DAST baseline for the admin web console.
- Full Git-history secret scan using `gitleaks`, `trufflehog`, or an approved equivalent.
- Cloud IAM, App Check console state, key inventory, rotation, and access-review evidence.
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

1. Confirm GCP IAM revocation/rotation status for the removed service account key and store owner-approved evidence.
2. Run full Git-history secret scanning with approved tooling and store sanitized reports.
3. Run release APK runtime/logcat checks on an attached emulator/device.
4. Run DAST against a controlled local/staging admin web URL or file an approved time-boxed exception.
5. File residual dependency advisories as accepted risk or backlog items with owner/expiry where required.
6. Populate the App Check and rate-limit matrix with evidence for every sensitive callable.
7. Validate the Review 4 additions, especially stale-claims behavior, Phone Auth applicability, FCM/Remote Config applicability, listener abuse, and wallet anomaly alerting.

## 9. Current Recommendation

No-Go until the remaining evidence/governance gates are complete. The local remediation pass cleared the dependency High/Critical blockers, Functions emulator aggregate failure, top-up proof direct-delete gap, and release APK build/config inspection. The next milestone is collecting the missing production-release evidence: IAM/key revocation proof, Git-history secret scan, APK runtime/logcat, DAST or accepted exception, and cloud App Check/IAM state.
