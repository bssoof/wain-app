# WAIN Full Application Security Assessment Plan

Date: 2026-05-19

## 1. Purpose

This document defines a complete security assessment plan for the WAIN application and its supporting codebase before any production release decision.

The goal is to verify that the app is secure across:

- Flutter mobile client.
- Firebase Auth, custom claims, and user profile documents.
- Firestore security rules and data model authorization.
- Cloud Storage security rules and upload/download paths.
- Cloud Functions callable and background financial operations.
- Admin web console.
- Release APK configuration.
- Secrets, logs, dependency, and deployment hygiene.
- Financial integrity and auditability.

This is not a UI-only QA checklist. A test passes only when the server-side state, rules, logs, and audit evidence match the expected security outcome.

## 2. Release Gate

Security approval is blocked if any of the following are true:

- Any P0 or P1 finding is open.
- Any user can read or write another user's private data.
- Any merchant can access or mutate another merchant's venue, wallet, offers, stories, menu, reviews, or analytics.
- Any client can directly create, update, or delete wallet ledger entries.
- Any top-up, reversal, wallet credit, wallet debit, or audit event can be forged from the client.
- Any financial action can execute without authenticated actor, role check, ownership check, idempotency protection, and audit trail.
- Any admin-only path can be reached by a non-admin user.
- Any production secret, service account key, privileged token, or private key is committed, bundled, logged, or exposed.
- Release APK contains emulator-only configuration unless it is explicitly a QA emulator build.
- Firestore or Storage rules have a known allow-by-default path.
- Required CI/CD security gates are absent, bypassed, or failing without an approved time-boxed exception.
- Any Critical/High runtime dependency vulnerability is present without accepted risk.
- Key rotation, revocation, and access-review evidence is missing for production secrets or service accounts.
- Required mobile release hardening decisions are undocumented.

## 3. Safety Rules

Run destructive or abuse tests only on:

- Firebase Emulator Suite, or
- a dedicated staging Firebase project with disposable test data.

Do not run destructive tests on production unless all are true:

- scope is approved in writing,
- exact accounts and documents are listed,
- rollback or compensation plan exists,
- logs and timestamps are captured,
- test is supervised by the QA/security owner.

Never use `--allow-live` for seed/verifier tests unless the owner explicitly approves the target project.

## 4. Security Owners

Recommended ownership:

- Security lead: owns final sign-off and severity decisions.
- Mobile owner: Flutter client, release APK, local storage, logs, route guards.
- Backend owner: Cloud Functions, transactions, idempotency, audit logs.
- Rules owner: Firestore and Storage rules.
- Admin owner: Admin web console, RBAC, headers, token exposure.
- QA owner: emulator setup, evidence capture, test matrix execution.
- DevSecOps owner: CI/CD gates, SAST/SCA/SBOM, artifact provenance, security reports.
- Infra/SRE owner: IAM, KMS/secret rotation, monitoring, incident response metrics.

## 5. Evidence Requirements

Every security test record must include:

- test id,
- git commit/tag,
- build artifact path and SHA256 where applicable,
- Firebase project namespace,
- emulator or staging target,
- account used,
- exact command or UI path,
- expected result,
- actual result,
- Firestore/Storage before-after state when relevant,
- function or log evidence when relevant,
- screenshot or logcat evidence for mobile flows,
- pass/fail verdict,
- linked bug if failed.

Evidence output directory:

```text
docs/security/evidence/<YYYY-MM-DD>/<test-id>/
```

Suggested files per test:

```text
commands.ps1
stdout.txt
stderr.txt
firestore-before.json
firestore-after.json
storage-before.txt
storage-after.txt
logcat.txt
function-logs.txt
screenshot.png
verdict.md
```

## Governance Addendum - Mandatory Enterprise Controls

The operational test plan above is not sufficient by itself for a formal release security program. The following governance controls are mandatory before this plan is treated as the official release security reference.

### Vulnerability SLA And Risk Acceptance

Required remediation SLA:

| Severity | Default SLA | Release impact |
| --- | ---: | --- |
| P0 Critical | 24 hours triage, 72 hours fix or rollback | Blocks release |
| P1 High | 48 hours triage, 7 days fix | Blocks release unless formally accepted |
| P2 Medium | 5 business days triage, 30 days fix | May release with accepted risk |
| P3 Low | 10 business days triage, backlog SLA | Does not block unless cumulative risk is high |

Risk acceptance rules:

- P0 cannot be accepted for release.
- P1/P2 acceptance requires Security Lead plus Product/Engineering owner approval.
- Every accepted risk must include owner, expiry date, compensating controls, retest date, and business justification.
- Accepted risk expiry must be 90 days or less.
- Expired accepted risks become release blockers.

Risk acceptance record:

```markdown
Risk ID:
Severity:
Owner:
Accepted by:
Expiry date:
Affected control/test:
Business justification:
Compensating controls:
Retest date:
```

### Control Traceability Matrix

Every test must map to at least one internal WAIN control and, where applicable, an external reference.

Required output:

```text
docs/security/control-traceability-matrix-YYYY-MM-DD.md
```

Minimum columns:

| Column | Meaning |
| --- | --- |
| Control ID | Internal WAIN control id, for example `WAIN-FIN-001` |
| Requirement | What must be true |
| Standard mapping | OWASP/NIST/ISO reference |
| Test IDs | Automated/manual tests proving it |
| Evidence | File/path/log proving pass/fail |
| Owner | Accountable owner |
| Frequency | Per release, weekly, quarterly |
| Status | Pass/Fail/Accepted risk |

Baseline control families:

| WAIN family | Examples | External mapping target |
| --- | --- | --- |
| WAIN-AUTH | Auth, sessions, roles, custom claims | OWASP ASVS V2/V4, MASVS-AUTH |
| WAIN-AC | Firestore/Storage ownership, tenant isolation | OWASP ASVS V4, OWASP Top 10 A01 |
| WAIN-FIN | Wallet ledger, top-up, reversal, audit trail | OWASP ASVS V5/V10, NIST integrity controls |
| WAIN-LOG | Logging, audit, privacy-safe telemetry | OWASP ASVS V7, ISO logging/monitoring controls |
| WAIN-MOB | APK hardening, local storage, tamper assumptions | OWASP MASVS-STORAGE/RESILIENCE |
| WAIN-SC | Dependencies, SBOM, provenance | OWASP SCVS, NIST SSDF |
| WAIN-OPS | IAM, KMS, incident response, monitoring | NIST CSF, ISO 27001 operational controls |

Initial external standards to map:

- OWASP MASVS for mobile application controls.
- OWASP ASVS for backend/API/admin web controls.
- OWASP Top 10 for common web/API risk classes.
- NIST SSDF for secure development lifecycle and supply chain.
- NIST CSF for identify/protect/detect/respond/recover structure.
- ISO 27001 Annex A as an organizational control reference where required by stakeholders.

Pass criteria:

- every release-blocking test maps to a WAIN control id,
- every P0/P1 finding maps to a failed control,
- every accepted risk maps to the same control and evidence path.

### CI/CD Security Gates

Security checks must be release-blocking by default instead of relying on manual execution.

Required gates before production deploy:

- clean working tree or signed CI checkout,
- Flutter analyze and security-relevant tests,
- Functions build and tests,
- Functions emulator security tests,
- Admin web security test suite,
- Admin web secure build and bundle token scan,
- secrets scan,
- dependency audit or SCA result,
- Firestore/Storage rules negative tests,
- finance and audit verifiers for seeded QA data,
- APK production-config inspection,
- artifact SHA256 and provenance record.

Gate policy:

- any failed P0/P1 gate blocks deploy,
- bypass requires written risk acceptance and expiry,
- bypass cannot be self-approved by the author of the change,
- release report must include gate run id and artifact digest.

Suggested CI jobs:

```text
security:secrets
security:flutter
security:functions
security:rules-emulator
security:admin-web
security:dependency-audit
security:apk-inspection
security:finance-verifiers
```

### Key Management And Encryption Governance

Checks:

- production service account keys are avoided; workload identity or platform-managed credentials are preferred,
- any existing service account key has owner, purpose, creation date, rotation date, and revocation process,
- Firebase/Google Cloud IAM follows least privilege,
- CI secrets are stored in the CI secret manager, not in repo or build logs,
- Play signing material and upload keys are stored in an approved secure location,
- backup/escrow process is documented for signing keys,
- incident playbook includes immediate revocation and redeploy steps,
- Firestore/Storage data classification defines encryption expectations,
- access review for admins/service accounts is scheduled at least quarterly.

Required evidence:

- IAM export or reviewed screenshot,
- key inventory,
- last rotation date,
- revocation drill result or documented procedure,
- CI secret inventory without values.

Pass criteria:

- no unmanaged production key,
- no ownerless privileged service account,
- key rotation/revocation path is executable within the incident SLA.

### Mobile Runtime Hardening Baseline

Hardening controls to decide and document:

- Dart obfuscation and split debug info for production release builds,
- Android `debuggable=false` in release,
- no emulator flags in production APK,
- cleartext traffic disabled except approved QA/emulator scope,
- root/jailbreak detection decision and expected behavior,
- tamper/integrity checks decision and expected behavior,
- certificate pinning decision and rationale,
- screenshot prevention decision for sensitive admin/wallet proof screens,
- secure local storage policy,
- reverse-engineering assumptions and server-side compensating controls.

Mobile hardening is defense-in-depth. It must not replace server-side authorization, rules, Functions checks, idempotency, or audit trails.

### SBOM, Provenance, And Vendor Risk

Required outputs:

- Flutter dependency inventory from `pubspec.lock`,
- Functions dependency inventory from `functions/package-lock.json`,
- Admin web dependency inventory from `admin_web_console/package-lock.json`,
- runtime dependency audit results,
- list of critical vendors/services,
- artifact digest and build provenance record.

Checks:

- critical/high runtime CVEs are triaged,
- direct dependencies have owners,
- Firebase, Google Sign-In, image/media, QR/scanner, and notification dependencies are treated as high-impact vendors,
- no dependency is added without lockfile review,
- build artifact hash is recorded in release report.

Optional inventory commands:

```powershell
flutter pub deps --json > docs/security/evidence/<date>/flutter-deps.json
npm --prefix functions ls --json > docs/security/evidence/<date>/functions-deps.json
npm --prefix admin_web_console ls --json > docs/security/evidence/<date>/admin-web-deps.json
```

### Incident Response Metrics And Drills

Required drills:

- compromised Firebase user token,
- leaked service account key,
- unauthorized wallet mutation attempt,
- missing audit event for real financial action,
- admin account privilege misuse,
- top-up/reversal replay attempt,
- production logging of sensitive data.

Metrics to record:

- MTTD: mean time to detect,
- MTTR: mean time to contain/recover,
- time to revoke credential,
- time to freeze affected wallet/venue,
- time to run finance/audit verifiers,
- time to publish incident summary.

Pass criteria:

- incident owner and escalation channel are known,
- financial recovery runbook is executable,
- at least one tabletop or emulator drill is recorded before production release.

## 6. Assessment Phases

### Phase 0 - Freeze Target And Baseline

Objective: ensure every security test targets the same code and build.

Required checks:

```powershell
git status --short
git describe --tags --always --dirty
git log --oneline -5
```

Required output:

- clean working tree, except explicitly stashed local editor files,
- named security assessment tag or commit,
- APK/build artifact name,
- SHA256 for APK and admin build artifacts.

Pass criteria:

- no uncommitted product code,
- target tag/commit recorded,
- build artifact reproducible.

### Phase 1 - Asset Inventory And Threat Model

Create or update a concise threat model covering:

Assets:

- Firebase Auth accounts and custom claims.
- User profile documents.
- Merchant profile and venue ownership.
- Wallet balances and ledger entries.
- Top-up requests and proof images.
- Reversal requests and approval chain.
- Audit events.
- Admin console sessions and capabilities.
- Storage uploads and signed/readable assets.
- Analytics events and business reporting.
- Release APK and dart defines.

Trust boundaries:

- Flutter client to Firebase SDK.
- Flutter client to callable functions.
- Admin web browser to Firebase/Functions.
- Functions service account to Firestore/Storage.
- Firestore rules boundary.
- Storage rules boundary.
- Emulator/staging/production boundary.
- QA seed data boundary.

Attacker models:

- anonymous app user,
- authenticated normal user,
- guest/anonymous Firebase user,
- merchant for venue A attacking venue B,
- finance admin attempting super-admin actions,
- compromised client modifying requests,
- replay/double-submit attacker,
- malicious web user targeting admin console,
- attacker with APK and ability to inspect/decompile,
- accidental internal misuse.

Required artifact:

```text
docs/security/threat-model-2026-05-19.md
```

Pass criteria:

- all privileged assets and trust boundaries are represented,
- financial invariants are explicitly listed,
- attacker-controlled inputs are listed.

### Phase 2 - Secrets And Configuration Scan

Objective: prove no sensitive credentials are committed, bundled, or logged.

Checks:

- Search for private keys, service accounts, tokens, API secrets, signing material.
- Verify root-level `service-account-key.json` is not a real production key. If real: revoke immediately, remove from git history plan, rotate credentials.
- Verify `.env`, Firebase tokens, admin SDK keys, Play signing material are not committed.
- Verify `firebase_options.dart` contains only public Firebase client config.
- Verify `.firebaserc` points are documented and not used as a production safety mechanism.
- Verify `.tmp`, logs, and deploy logs are sanitized before commit.

Commands:

```powershell
rg -n --hidden --glob '!build/**' --glob '!node_modules/**' --glob '!.git/**' `
  "BEGIN PRIVATE KEY|PRIVATE KEY|client_email|client_id|refresh_token|firebase_token|FIREBASE_TOKEN|service_account|password|secret|apiKey|AIza|Bearer "

git ls-files | Select-String -Pattern "service-account|\\.env|keystore|jks|p12|pem|key\\.json"
```

Pass criteria:

- no privileged secret in tracked files,
- any intentionally public Firebase web/mobile keys are documented as public,
- no production service account key remains in repo.

### Phase 3 - Flutter Client Security Review

Scope:

- `lib/features/auth/**`
- `lib/features/onboarding/**`
- `lib/features/discovery/**`
- `lib/features/merchant/**`
- `lib/features/admin/**` if present
- `lib/core/routing/**`
- `lib/main.dart`
- `android/app/src/main/**`

Checks:

- Auth state handling cannot bypass protected routes.
- Merchant routes require authenticated merchant access.
- Admin routes require admin access.
- Post-auth redirect cannot be abused to send users to privileged paths unless access checks pass.
- User-scoped local preferences do not leak across accounts.
- Local storage does not contain passwords, tokens, wallet secrets, or admin state.
- Log statements do not print tokens, passwords, OTPs, personal data, wallet proofs, or full auth payloads.
- Emulator wiring is enabled only through explicit dart defines.
- Production release does not point to `10.0.2.2`, localhost, emulator ports, or cleartext-only endpoints.
- Android network security allows cleartext only for QA/emulator builds or explicitly safe scoped domain rules.
- App permissions are minimal and justified.
- Deep links cannot open privileged screens without auth/role checks.
- Screenshots/cache do not expose sensitive admin or wallet proof content where preventable.

Manual review targets:

```powershell
rg -n "debugPrint|print\\(|PlatformLogger|log\\(|logger|Firebase emulators enabled|WAIN_USE_FIREBASE_EMULATORS|WAIN_FIREBASE_EMULATOR_HOST" lib android
rg -n "context\\.go|context\\.push|redirectTo|deepLink|AppLinks|route|merchant/dashboard|admin" lib
rg -n "SharedPreferences|prefs\\.|secure|token|password|otp|claim|role" lib
```

Pass criteria:

- no client-only authorization for sensitive actions,
- no sensitive data in logs/local storage,
- route guards pass widget/router tests.

### Phase 4 - Firestore Rules Negative Tests

Objective: prove Firestore denies unauthorized reads/writes regardless of client UI.

Required accounts:

- unauthenticated,
- user QA 01,
- user QA 02,
- merchant QA 01 linked to `venue_qa_01`,
- merchant QA 02 linked to `venue_qa_02`,
- finance admin,
- super admin.

Minimum denial matrix:

| Test ID | Actor | Attempt | Expected |
| --- | --- | --- | --- |
| FS-001 | unauthenticated | read user private profile | denied |
| FS-002 | user QA 01 | read user QA 02 private profile | denied |
| FS-003 | user QA 01 | read `merchant_wallets/venue_qa_01` | denied |
| FS-004 | user QA 01 | write any wallet entry | denied |
| FS-005 | merchant QA 01 | read `merchant_wallets/venue_qa_02` | denied |
| FS-006 | merchant QA 01 | write `merchant_wallets/venue_qa_01/entries/*` | denied |
| FS-007 | merchant QA 01 | approve top-up request | denied |
| FS-008 | merchant QA 01 | approve reversal request | denied |
| FS-009 | merchant QA 01 | read another merchant reversal request | denied |
| FS-010 | finance admin | perform super-admin-only action document write | denied |
| FS-011 | non-admin | read wallet audit/admin-only collections | denied |
| FS-012 | user QA 01 | create or update venue owned by merchant | denied |
| FS-013 | merchant QA 01 | mutate venue QA 02 offers/stories/menu | denied |
| FS-014 | user QA 01 | modify analytics/report documents | denied |

Existing test surfaces to run or extend:

```powershell
flutter test test\features\security\security_flows_test.dart
npm --prefix functions run test:emulator:aggregate
```

Pass criteria:

- every unauthorized path denies at rules layer,
- every authorized path is narrowly scoped to owner/role,
- no broad wildcard allow permits financial/admin writes.

### Phase 5 - Storage Rules Negative Tests

Scope:

- venue photos,
- menu images,
- story media,
- top-up proof images,
- user profile photos,
- admin-only evidence/proof paths if any.

Minimum matrix:

| Test ID | Actor | Attempt | Expected |
| --- | --- | --- | --- |
| ST-001 | unauthenticated | upload venue photo | denied |
| ST-002 | user QA 01 | upload top-up proof for merchant venue | denied |
| ST-003 | merchant QA 01 | upload into `venue_qa_02` path | denied |
| ST-004 | merchant QA 01 | read another merchant private top-up proof | denied |
| ST-005 | user QA 01 | overwrite story media owned by merchant | denied |
| ST-006 | admin without finance role | read finance proof path | denied |
| ST-007 | valid merchant | upload allowed file type/size to own path | allowed |
| ST-008 | valid merchant | upload disallowed extension/content type | denied |

Commands:

```powershell
firebase --config firebase.json emulators:exec --project wain-security-qa --only storage,firestore "npm --prefix functions run test:emulator:aggregate"
```

Pass criteria:

- ownership enforced in every path,
- proof images are not public unless explicitly intended,
- content type and size controls are enforced where rules support them.

### Phase 6 - Cloud Functions Security Review

Scope:

- `functions/src/**`
- generated `functions/lib/**` only for confirming build output when needed.

Review every callable/background financial function for:

- `context.auth` or equivalent authentication check.
- App Check enforcement where required.
- role/custom claims validation.
- Firestore source-of-truth role check where claims may be stale.
- ownership check for `venue_id`, `merchant_uid`, `request_id`, `entry_id`.
- input schema validation and type validation.
- amount/currency validation.
- idempotency key strategy.
- Firestore transaction usage for ledger updates.
- no client-provided `balance_after`, role, actor, status, or audit fields trusted.
- audit event written exactly once for financial/admin state transitions.
- error handling avoids leaking sensitive internal state.
- rate limiting or replay resistance for sensitive callables.

Commands:

```powershell
npm --prefix functions run build
npm --prefix functions test
npm --prefix functions run test:emulator:aggregate
rg -n "onCall|onRequest|context\\.auth|request\\.auth|AppCheck|idempot|transaction|audit|wallet|topup|reversal|approve|role|claims" functions/src
```

High-risk flows requiring manual inspection:

- merchant top-up request creation,
- admin top-up approval/rejection,
- merchant reversal request creation,
- finance first review,
- super-admin second approval,
- wallet credit/debit/reversal creation,
- wallet report aggregation,
- admin role/config governance,
- story promotion debit,
- offer pin debit,
- menu/photo/story media mutation.

Pass criteria:

- no sensitive function executes without auth + role + ownership,
- all financial state changes are transactional and audited,
- replay and double-submit do not create duplicate financial effects.

### Phase 7 - Financial Abuse And Integrity Tests

Run only on emulator/staging.

Required test cases:

| Test ID | Scenario | Expected |
| --- | --- | --- |
| FIN-001 | double tap top-up submit | one request or idempotent duplicate rejection |
| FIN-002 | replay same top-up client_request_id | no duplicate credit |
| FIN-003 | merchant changes amount in request payload after UI validation | server validates amount |
| FIN-004 | merchant attempts approve top-up | permission denied |
| FIN-005 | finance admin approves same top-up twice | no duplicate wallet credit |
| FIN-006 | create reversal for same entry twice | duplicate blocked or verifier fails before release |
| FIN-007 | finance admin final-approves without super admin where required | denied |
| FIN-008 | super admin approval after expired/rejected request | denied |
| FIN-009 | non-executed reversal has linked reversal entry | verifier reports fail |
| FIN-010 | ledger entry balance_after tampered | finance verifier reports fail |
| FIN-011 | audit event missing actor/action/target | audit verifier reports fail |
| FIN-012 | available_balance drift from ledger tail | finance verifier reports fail |

Verification commands:

```powershell
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
node scripts/qa-seed.mjs --project=wain-d2e28 --reset --out=.tmp/security-qa-seed-output.json
node scripts/qa-verify-finance.mjs --project=wain-d2e28 --venue=venue_qa_01,venue_qa_02 --strict
node scripts/qa-verify-audit-trail.mjs --project=wain-d2e28 --venue=venue_qa_01,venue_qa_02 --strict
```

Pass criteria:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=N fail=0 warn=0
```

Audit event count `N` depends on scenario volume and must be explained in the evidence.

### Phase 8 - Admin Web Console Security

Scope:

- `admin_web_console/**`

Checks:

- login/session route guard cannot be bypassed,
- forged headers are denied,
- missing role is denied,
- finance routes require finance/admin role,
- super-admin-only config governance cannot be used by finance admin,
- privileged public token leakage is blocked,
- Next.js security headers are present,
- no fixture fallback in production,
- no privileged token leaks in generated bundle,
- server-side loaders do not trust client route state,
- admin UI never exposes raw secrets or service account data.

Commands:

```powershell
npm --prefix admin_web_console run test:security
npm --prefix admin_web_console run build:secure
```

Additional manual review:

```powershell
rg -n "admin|role|claims|finance|super_admin|token|Authorization|headers\\(|middleware|redirect|forged|fixture|fallback" admin_web_console
```

Pass criteria:

- all security tests pass,
- production build passes bundle token sentinel scan,
- route guard behavior is server-backed, not UI-only.

### Phase 9 - Dependency And Supply Chain Security

Checks:

- Flutter dependency review.
- Functions npm audit.
- Admin web npm audit.
- Lockfile consistency.
- Outdated security-sensitive packages assessed.
- Firebase SDK major upgrades not mixed into release branch without retest.
- CI/build scripts do not download untrusted scripts.

Commands:

```powershell
flutter pub outdated
npm --prefix functions audit --omit=dev
npm --prefix admin_web_console audit --omit=dev
git diff -- pubspec.lock functions/package-lock.json admin_web_console/package-lock.json
```

Pass criteria:

- no known critical/high vulnerabilities in runtime dependencies without written exception,
- lockfiles match committed dependency intent,
- dependency upgrades are tested before release.

### Phase 10 - Release APK Security Assessment

Build two distinct artifacts:

1. QA emulator release APK.
2. Production candidate release APK.

QA APK requirements:

- explicit `WAIN_USE_FIREBASE_EMULATORS=true`,
- host `10.0.2.2`,
- not distributed to real users,
- artifact name clearly includes QA/emulator.

Production APK requirements:

- no emulator dart define,
- no `10.0.2.2`,
- no localhost,
- no debug banner,
- no debug signing for release,
- no sensitive logs,
- permissions minimal,
- App Check behavior verified.

Commands:

```powershell
flutter build apk --release
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
rg -n "10\\.0\\.2\\.2|127\\.0\\.0\\.1|localhost|WAIN_USE_FIREBASE_EMULATORS|allowCleartext|debuggable" android lib
```

Runtime checks:

```powershell
adb -s emulator-5554 logcat -c
adb -s emulator-5554 shell monkey -p com.wain.wain_app -c android.intent.category.LAUNCHER 1
adb -s emulator-5554 logcat -d > .tmp/security-release-logcat.txt
Select-String -Path .tmp\security-release-logcat.txt -Pattern "password|idToken|refreshToken|Bearer|Authorization|otp|secret|private|wallet|proof|FATAL|AndroidRuntime|E/flutter"
```

Pass criteria:

- production candidate does not connect to emulator,
- no sensitive data in logcat,
- no crash or fatal startup error,
- permissions are justified.

### Phase 11 - Privacy And Data Minimization

Checks:

- Analytics does not include password, phone OTP, id tokens, precise wallet proof URLs, or private admin data.
- QA users are excluded from production financial analytics where documented.
- User deletion/sign-out clears sensitive local scoped state where required.
- SharedPreferences stores preferences only, not credentials.
- Top-up proof retention policy is documented and enforced.
- Audit logs contain enough forensic data but do not include unnecessary secrets.

Manual search:

```powershell
rg -n "Analytics|logEvent|setUserProperty|Crashlytics|recordError|SharedPreferences|proof|phone|email|wallet|audit" lib functions/src admin_web_console
```

Pass criteria:

- no unnecessary PII in analytics/logging,
- retention and audit purposes are documented.

### Phase 12 - Network, Transport, And App Check

Checks:

- HTTPS enforced for production endpoints.
- Cleartext exception limited to emulator/QA host.
- App Check enforced on sensitive Firebase resources where intended.
- Failure behavior is user-readable and not a silent security bypass.
- Functions reject missing/invalid App Check where enabled.
- Firestore/Storage rules do not rely on App Check alone.

Tests:

- launch production candidate with no emulator defines,
- attempt sensitive callable with missing App Check token,
- attempt callable with valid auth but wrong role,
- attempt direct Firestore write bypassing Functions,
- verify all fail server-side.

Pass criteria:

- no sensitive operation relies on client UI or App Check alone,
- production transport is HTTPS-only except explicitly documented Firebase SDK transport.

### Phase 13 - Concurrency, Replay, And Rate Abuse

Checks:

- double submit on top-up/reversal,
- repeated callable invocation with same request id,
- simultaneous admin approvals from two sessions,
- stale approval after request state changes,
- expired request approval,
- offline/retry behavior,
- app restart during pending operation.

Evidence:

- request state before/after,
- wallet ledger before/after,
- audit events before/after,
- verifier output.

Pass criteria:

- financial result is idempotent,
- state machine cannot skip required statuses,
- verifier remains clean.

### Phase 14 - IAM, Deployment, And Operational Security

Checks:

- Firebase project roles are least privilege.
- Service account keys are avoided or rotated.
- CI/CD secrets are stored in platform secret manager, not repo.
- Deploy commands are documented.
- Rollback and financial compensation runbooks are available.
- Production deploy requires human approval.
- App Check enforcement rollout plan exists.
- Monitoring and alerting cover financial function errors.

Required docs:

- `docs/qa/financial-recovery-runbook.md`
- deployment rollback notes,
- owner/on-call list,
- incident template.

Pass criteria:

- no unmanaged production key,
- rollback and compensation path are clear,
- monitoring owner is assigned.

## 7. Required Command Suite

Run this suite for a full local security pass:

```powershell
# Flutter static/tests
flutter analyze
flutter test

# Functions
npm --prefix functions run build
npm --prefix functions test
npm --prefix functions run test:emulator:aggregate

# Admin web
npm --prefix admin_web_console run test:security
npm --prefix admin_web_console run build:secure

# QA seed and financial verifiers
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
node scripts/qa-seed.mjs --project=wain-d2e28 --reset --out=.tmp/security-qa-seed-output.json
node scripts/qa-verify-finance.mjs --project=wain-d2e28 --venue=venue_qa_01,venue_qa_02 --strict
node scripts/qa-verify-audit-trail.mjs --project=wain-d2e28 --venue=venue_qa_01,venue_qa_02 --strict

# Dependency audit
npm --prefix functions audit --omit=dev
npm --prefix admin_web_console audit --omit=dev
flutter pub outdated

# Dependency inventory / SBOM inputs
flutter pub deps --json > .tmp/security-flutter-deps.json
npm --prefix functions ls --json > .tmp/security-functions-deps.json
npm --prefix admin_web_console ls --json > .tmp/security-admin-web-deps.json
```

If any command fails, stop and file a security finding or setup blocker. Do not continue by rerunning blindly.

## 8. Manual Penetration Test Scenarios

### Auth And Routing

- Open merchant dashboard while unauthenticated.
- Open admin routes while unauthenticated.
- Open merchant route as normal user.
- Open admin route as merchant.
- Tamper `redirectTo` to point to merchant/admin paths.
- Sign out then press back into protected route.
- Revoke auth token and continue using app.

Expected: protected routes deny or redirect; no sensitive data remains visible.

### Merchant Boundary

- Merchant A reads Merchant B venue/wallet.
- Merchant A edits Merchant B offer/story/menu.
- Merchant A uploads media under Merchant B path.
- Merchant A creates reversal for Merchant B wallet entry.

Expected: denied at rules/functions layer.

### Financial Boundary

- User creates wallet ledger entry directly.
- Merchant changes top-up amount/status directly.
- Finance admin bypasses second approval.
- Super admin approves stale/expired request.
- Duplicate idempotency key.
- Duplicate reversal for same original entry.

Expected: denied or idempotent; verifier clean.

### Admin Boundary

- Non-admin visits admin console route.
- Finance admin attempts super-admin config publish.
- Forged admin headers.
- Missing role token.
- Production fixture fallback.
- Bundle token sentinel.

Expected: denied; no privileged data exposed.

### Storage Boundary

- Anonymous upload/read sensitive file.
- User reads top-up proof.
- Merchant reads another merchant proof.
- Oversized or wrong content type upload.

Expected: denied.

## 9. Finding Severity

P0 Critical:

- unauthorized financial mutation,
- wallet balance/ledger corruption,
- privilege escalation to admin/super admin,
- production secret exposure,
- data exfiltration across users/merchants,
- bypass of all server-side authorization.

P1 High:

- sensitive path readable by wrong authenticated role,
- audit trail missing for financial action,
- idempotency/replay bug with financial impact,
- App Check/route guard regression on sensitive flows,
- token/PII leakage in release logs.

P2 Medium:

- privacy minimization gap,
- weak error handling,
- missing rate limit on non-financial action,
- broad but non-sensitive read access,
- hardening issue with compensating control.

P3 Low:

- documentation gap,
- minor header hardening,
- test coverage gap without known exploit path.

## 10. Finding Template

Use this template for every issue:

```markdown
## <Finding ID>: <Title>

Severity: P0/P1/P2/P3
Owner: Mobile/Backend/Rules/Admin/Infra
Status: New/Triaged/In Progress/Ready for Retest/Closed
Affected commit/tag:
Affected surface:

### Summary

### Reproduction

### Expected

### Actual

### Impact

### Evidence

### Root Cause

### Fix Plan

### Verification Plan

### Regression Tests Added
```

## 11. Final Security Sign-off Checklist

Success metrics for release security:

- 0 open P0/P1 findings.
- 0 unaccepted critical/high runtime dependency vulnerabilities.
- 0 real secrets in repo, build artifacts, or logs.
- 100% pass on tenant isolation tests for users and merchants.
- 100% pass on required Firestore/Storage negative tests.
- 100% pass on required financial verifiers with `fail=0 warn=0`.
- 100% of release artifacts have SHA256 recorded.
- 100% of required CI/CD gates pass or have approved, unexpired risk acceptance.
- 95% or higher mapping coverage in the control traceability matrix.
- Critical remediation time within SLA.
- High remediation time within SLA.
- Incident drill MTTD/MTTR recorded and reviewed.

Before release, all must be true:

- [ ] Threat model is complete.
- [ ] Control traceability matrix exists and maps tests to WAIN/OWASP/NIST/ISO controls.
- [ ] CI/CD security gates are automated or tracked with owners and release-blocking policy.
- [ ] Vulnerability SLA and risk acceptance policy are approved.
- [ ] Secrets scan completed; no real secrets in repo/build/logs.
- [ ] Key inventory, rotation, revocation, and access review evidence exists.
- [ ] Flutter static analysis passed.
- [ ] Flutter security-relevant tests passed.
- [ ] Firestore negative tests passed.
- [ ] Storage negative tests passed.
- [ ] Functions build and tests passed.
- [ ] Functions emulator security tests passed.
- [ ] Admin web security tests passed.
- [ ] Admin web secure build passed.
- [ ] Dependency audit has no unaccepted critical/high runtime vulnerabilities.
- [ ] SBOM/dependency inventory exists for Flutter, Functions, and Admin Web.
- [ ] Release APK inspected for emulator/debug config.
- [ ] Mobile hardening decisions are documented and release APK matches them.
- [ ] Release APK logcat has no sensitive data.
- [ ] Financial abuse tests passed.
- [ ] `qa-verify-finance` passed with `fail=0 warn=0`.
- [ ] `qa-verify-audit-trail` passed with `fail=0 warn=0`.
- [ ] App Check failure behavior verified.
- [ ] Incident recovery runbook exists and is linked.
- [ ] Incident response tabletop or emulator drill is recorded.
- [ ] All P0/P1 findings closed.
- [ ] Any P2 accepted risk is documented with owner and expiry date.

## 12. Recommended Execution Order

1. Freeze tag/build target.
2. Run secrets/config scan.
3. Build threat model.
4. Create/update control traceability matrix.
5. Confirm SLA, risk acceptance, key management, and CI/CD gate policy.
6. Run static code review for Flutter, Functions, Admin Web.
7. Run automated Flutter/Functions/Admin tests.
8. Run Firestore and Storage negative tests on emulator.
9. Run financial abuse tests and verifiers.
10. Build and inspect release APK.
11. Generate dependency inventory/SBOM inputs and audit results.
12. Run App Check/Play Integrity smoke on controlled QA accounts if required.
13. File findings and retest fixes.
14. Run incident response tabletop or emulator drill.
15. Produce final security report.

## 13. Final Report Output

When the assessment is complete, write:

```text
docs/security/full-application-security-assessment-report-YYYY-MM-DD.md
```

The report must include:

- tested commit/tag,
- tested artifacts,
- command results,
- passed/failed matrix,
- control traceability matrix summary,
- CI/CD gate status,
- SBOM/dependency audit summary,
- findings list by severity,
- accepted risks,
- SLA exceptions or expired risks,
- key management and mobile hardening status,
- incident drill result if completed,
- release recommendation: Go / No-Go.
