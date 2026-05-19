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

Release remains blocked. The first execution pass found release-blocking dependency audit failures, a failing Functions emulator aggregate gate, an ignored local service account key that needs ownership and revocation/rotation triage, and incomplete mandatory gates such as DAST, APK inspection, full Git-history secret tooling, and cloud IAM/App Check evidence.

## 3. Command Results

| Gate | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | Pass | `flutter-analyze.*` |
| `flutter test` | Pass, 368 tests | `flutter-test.*` |
| `npm --prefix functions run build` | Pass | `functions-build.*` |
| `npm --prefix functions test` | Pass, 63 tests | `functions-test.*` |
| Functions emulator aggregate | Fail, 208 pass / 9 fail | `functions-test-emulator-aggregate-local-firebase.*` |
| `npm --prefix admin_web_console run test:security` | Pass, 45 tests | `admin-web-test-security.*` |
| Admin extra security tests | Pass from `admin_web_console` cwd, 8 tests | `admin-web-extra-security-tests-workdir.*` |
| `npm --prefix admin_web_console run build:secure` | Pass | `admin-web-build-secure.*` |
| QA seed + finance verifier + audit verifier | Pass | `qa-seed-finance-audit-emulators-exec.*` |
| Functions runtime dependency audit | Fail | `functions-npm-audit-omit-dev.*` |
| Admin web runtime dependency audit | Fail | `admin-web-npm-audit-omit-dev.*` |
| Flutter dependency inventory | Pass | `flutter-pub-deps.json` |
| Functions dependency inventory | Pass | `functions-npm-ls.json` |
| Admin web dependency inventory | Pass | `admin-web-npm-ls.json` |

Finance verifier result:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=26 fail=0 warn=0
```

## 4. Findings And Blockers

### WAIN-SEC-001: Ignored local service account key exists

Finding type: Candidate Finding / Control Gap
Proposed severity: P0 if production or privileged; otherwise P1 control gap until classified
Status: Needs Verification
Evidence strength: Code/config evidence
Release blocking: Temporary pending verification

Evidence shows `service-account-key.json` exists in the workspace root, is ignored and untracked, and contains a service account private key for project `wain-d2e28`. This is not proven to be committed to Git history, but production release should not proceed until the key is classified, owner/purpose are documented, and revocation/rotation evidence exists if it is real or production-capable.

Evidence:

- `service-account-current-check.txt`
- `service-account-key-classification.txt`
- `git-history-service-account-paths.txt`

### WAIN-SEC-002: Functions runtime dependency audit reports Critical/High vulnerabilities

Finding type: Confirmed Finding
Proposed severity: P1 High
Status: Needs Remediation
Evidence strength: Test evidence
Release blocking: Yes

`npm --prefix functions audit --omit=dev` exits non-zero and reports 16 vulnerabilities: 9 low, 3 moderate, 3 high, and 1 critical. Reported high/critical packages include `protobufjs`, `node-forge`, and `path-to-regexp`, via the Firebase Functions/Admin dependency tree.

Evidence:

- `functions-npm-audit-omit-dev.stdout.txt`
- `functions-npm-audit-omit-dev.exit.txt`

### WAIN-SEC-003: Admin web runtime dependency audit reports High vulnerabilities

Finding type: Confirmed Finding
Proposed severity: P1 High
Status: Needs Remediation
Evidence strength: Test evidence
Release blocking: Yes

`npm --prefix admin_web_console audit --omit=dev` exits non-zero and reports 10 vulnerabilities: 8 low, 1 moderate, and 1 high. The high advisory group is against `next@14.2.35`; npm suggests `next@16.2.6` with breaking-change risk, so this needs a controlled upgrade path and regression pass rather than a blind forced fix.

Evidence:

- `admin-web-npm-audit-omit-dev.stdout.txt`
- `admin-web-npm-audit-omit-dev.exit.txt`

### WAIN-SEC-004: Functions emulator aggregate gate fails content moderation flows

Finding type: Candidate Finding / Setup Blocker
Proposed severity: P1 if authorization regression; P2 if emulator seed/setup only
Status: Needs Triage
Evidence strength: Test evidence
Release blocking: Yes

The local Firebase emulator aggregate gate ran with local Firebase CLI and failed the content moderation suite. The common failure is `Requires admin privileges` from `requireAdminAccessWithDb`, including failures for content-admin approve/list/replay/expected-state tests. This may be a real content-admin authorization regression or a test seeding/auth context issue, but it is a failed security gate either way.

Evidence:

- `functions-test-emulator-aggregate-local-firebase.stdout.txt`
- `functions-test-emulator-aggregate-local-firebase.exit.txt`

### WAIN-SEC-005: Merchant-owned top-up proof files are deletable by the merchant in Storage rules

Finding type: Candidate Finding / Control Gap
Proposed severity: P1 if top-up proofs are required audit evidence; otherwise P2 retention gap
Status: Needs Product/Security Decision
Evidence strength: Code evidence
Release blocking: Temporary pending verification

`storage.rules` allows `delete` on `venues/{venueId}/wallet_topups/{fileName}` when the caller is the venue owner. Top-up proof images are financial evidence, and the plan requires proof retention policy and auditability. If these files are used for financial approval evidence, direct merchant deletion should be denied and handled only by an audited retention/lifecycle function.

Evidence:

- `storage-rules-numbered.txt`
- lines 86-94 in `storage.rules`

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
- Admin web security test suite and secure build pass.
- Admin web security headers and top-up proof proxy tests pass when run from `admin_web_console`.
- Finance and audit verifiers pass on seeded emulator data with `fail=0 warn=0`.
- Firestore rules show wallet and ledger writes denied to clients in key wallet paths.
- Storage rules enforce image/video content-type and size limits for configured upload paths.
- Admin web production bundle token sentinel scan passes.

## 6. Incomplete Gates

The following gates are not yet complete in this execution pass:

- Release APK build, SHA256, emulator-config inspection, and logcat sensitive-data scan.
- Firestore query authorization tests, including collection and collection group negative tests.
- Full Storage negative tests for delete/retention behavior and malicious upload handling.
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

1. Classify `service-account-key.json`: confirm whether it is production-capable, revoke/rotate if needed, and remove it from local release workspaces.
2. Triage and remediate Functions/Admin Web dependency audits with controlled package upgrades and full regression tests.
3. Debug the Functions emulator aggregate failures in `contentModerationCallableFlows.test.js` and determine whether the cause is role seeding, callable auth context, or real content-admin authorization regression.
4. Decide and enforce top-up proof deletion policy. If proofs are audit evidence, deny direct merchant deletion in Storage rules and move deletion to an audited retention function.
5. Run full Git-history secret scanning with approved tooling and store sanitized reports.
6. Run release APK inspection and logcat checks.
7. Run DAST against a controlled local/staging admin web URL or file an approved time-boxed exception.
8. Validate the Review 4 additions, especially stale-claims behavior, Phone Auth applicability, FCM/Remote Config applicability, listener abuse, and wallet anomaly alerting.

## 9. Current Recommendation

No-Go. The plan is final enough to use as the official release security reference, but this execution pass has confirmed release-blocking gates. The next milestone is not more planning; it is triage and remediation of WAIN-SEC-001 through WAIN-SEC-007, followed by a clean rerun of the required gates.
