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

- Any confirmed P0 or P1 finding is open.
- Any candidate P0 or P1 finding has enough evidence to be plausible and has not yet been triaged by the security lead.
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

Candidate findings from reviews, AI analysis, penetration-test notes, or threat-model workshops are not treated as confirmed vulnerabilities until evidence is collected from code, configuration, tests, runtime behavior, Firebase/GCP state, or artifact inspection. They must still be triaged promptly. The security lead may temporarily block release on a high-risk candidate while verification is pending.

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
- Admin web DAST baseline scan or documented accepted exception,
- secrets scan,
- dependency audit or SCA result,
- dependency license and typosquatting review for newly added direct dependencies,
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
security:dast
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
- new direct dependencies are reviewed for license compatibility and typosquatting risk,
- Firebase, Google Sign-In, image/media, QR/scanner, and notification dependencies are treated as high-impact vendors,
- Firebase/Google and other high-impact vendors have a documented shared responsibility model,
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

### Additional Mandatory Technical Controls

These controls are required before the assessment can be treated as production-complete.

#### Security Architecture Review

Before release, perform a dedicated architecture security review covering:

- trust boundaries,
- privileged flows,
- Firebase service account usage,
- client/server responsibility split,
- financial state machines,
- admin privilege model,
- data ownership model,
- failure modes and compensating controls.

Pass criteria:

- every privileged operation has one authoritative server-side path,
- no financial state can be changed by direct client writes,
- every state transition is explicitly documented and tested,
- there is no duplicated wallet-balance authority outside the ledger and approved financial functions.

#### Financial State Machine Security

Document allowed transitions for every financial workflow:

- top-up request,
- reversal request,
- wallet credit,
- wallet debit,
- story promotion debit,
- offer pin debit.

Minimum examples:

```text
Top-up: created -> pending_review -> approved -> credited
Top-up: created -> rejected
Top-up: approved must not return to pending_review
Top-up: credited must not be credited again

Reversal: created -> finance_reviewed -> super_admin_approved -> executed
Reversal: created -> rejected
Reversal: executed must not be executed again
```

Pass criteria:

- invalid transitions are denied server-side,
- stale approvals are denied,
- duplicate execution is idempotent or rejected,
- every valid transition emits one audit event.

#### Git History Secret Scan

Current files and full Git history must be scanned for secrets.

Required tools:

```powershell
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified
```

Pass criteria:

- no verified production secret exists in current files or Git history,
- any exposed secret is revoked, rotated, and documented,
- build and deploy logs do not contain replacement credentials.

#### Admin Browser Security

Admin web release must verify:

- Content-Security-Policy,
- frame protection through `frame-ancestors` or equivalent,
- restricted CORS,
- CSRF protection where cookies or session endpoints are used,
- secure cookie flags: `HttpOnly`, `Secure`, `SameSite`,
- OAuth redirect URI allow-list,
- no wildcard or origin-unsafe `postMessage` listener,
- no privileged token in browser storage or generated bundles.

#### Upload Security

All upload paths must enforce or explicitly document:

- authentication,
- ownership,
- file size limits,
- allowed content type and extension,
- blocked executable formats,
- private access for top-up proof images,
- EXIF/metadata privacy review,
- malware/content scanning decision for files downloadable by admins or users.

#### Backup, Restore, And Disaster Recovery

Before production release:

- Firestore backup policy must exist,
- restore drill must be tested,
- wallet ledger recovery procedure must be documented,
- accidental delete recovery must be tested where applicable,
- audit logs must be protected from unauthorized modification or deletion.

#### Vendor Risk Register

Maintain a practical register for high-impact vendors and integrations:

| Vendor / service | Data shared | Outage impact | WAIN responsibility | Vendor responsibility | Fallback plan | API key restrictions |
| --- | --- | --- | --- | --- | --- | --- |
| Firebase / Google Cloud | TBD | TBD | TBD | TBD | TBD | TBD |
| Google Play | TBD | TBD | TBD | TBD | TBD | TBD |
| Notification provider | TBD | TBD | TBD | TBD | TBD | TBD |
| Maps/media/QR/scanner providers | TBD | TBD | TBD | TBD | TBD | TBD |

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
- Search full Git history for previously committed secrets, not only current files.
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
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified
```

Pass criteria:

- no privileged secret in tracked files,
- no verified production secret in Git history,
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
- Android App Links use `android:autoVerify="true"` and Digital Asset Links where external HTTPS links are supported.
- Deep link tampering to wallet, merchant, admin, or redirect targets is denied before sensitive route rendering.
- WebView usage, if present, has JavaScript, file access, navigation allow-lists, and bridge exposure reviewed.
- Screenshots/cache do not expose sensitive admin or wallet proof content where preventable.

Manual review targets:

```powershell
rg -n "debugPrint|print\\(|PlatformLogger|log\\(|logger|Firebase emulators enabled|WAIN_USE_FIREBASE_EMULATORS|WAIN_FIREBASE_EMULATOR_HOST" lib android
rg -n "context\\.go|context\\.push|redirectTo|deepLink|AppLinks|route|merchant/dashboard|admin|WebView|JavascriptChannel|setJavaScriptMode" lib
rg -n "SharedPreferences|prefs\\.|secure|token|password|otp|claim|role" lib
rg -n "android:autoVerify|intent-filter|scheme|host" android/app/src/main
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

Firestore query denial matrix:

| Test ID | Actor | Query attempt | Expected |
| --- | --- | --- | --- |
| FS-Q-001 | merchant QA 01 | query all venues without owner filter | denied |
| FS-Q-002 | user QA 01 | query all users or private profiles | denied |
| FS-Q-003 | finance admin | query audit logs outside allowed scope | denied |
| FS-Q-004 | merchant QA 01 | collection group query over another merchant private subcollections | denied |
| FS-Q-005 | non-admin | collection group query over admin/private subcollections | denied |
| FS-Q-006 | valid scoped actor | query with required ownership/role filters | allowed only for scoped result set |

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
| ST-009 | valid merchant | upload executable or HTML content disguised as image | denied |
| ST-010 | valid merchant | upload image with privacy-sensitive EXIF metadata where stripping is required | stripped or rejected according to policy |
| ST-011 | user or merchant | public-read top-up proof image | denied unless explicitly approved |
| ST-012 | valid actor | download proof via signed/download URL after expiry | denied |

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
- App Check enforcement level recorded in a function-by-function matrix.
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
- numeric rate limits or replay resistance for sensitive callables, with test IDs.
- inventory of any `onRequest` HTTP endpoints or outbound `fetch`/HTTP calls outside callable functions.
- SSRF protections for any server-side outbound request: URL allow-list, private IP blocking, timeout, size limit, and no credential forwarding.

Required App Check and rate-limit matrix:

| Function or endpoint | Type | App Check mode | Auth/role required | Rate limit | Test ID | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `createTopUpRequest` | Callable | Enforce/Audit/None | Merchant owner | TBD | FIN-013 |  |
| `createReversalRequest` | Callable | Enforce/Audit/None | Merchant owner | TBD | FIN-013 |  |
| `approveTopUp` | Callable | Enforce/Audit/None | Finance/admin | TBD | FIN-013 |  |
| `finalApproveReversal` | Callable | Enforce/Audit/None | Super admin | TBD | FIN-013 |  |

Commands:

```powershell
npm --prefix functions run build
npm --prefix functions test
npm --prefix functions run test:emulator:aggregate
rg -n "onCall|onRequest|context\\.auth|request\\.auth|AppCheck|enforceAppCheck|idempot|client_request_id|transaction|audit|wallet|topup|top.?up|reversal|approve|role|claims|fetch\\(|axios|http\\.request|https\\.request" functions/src
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
| FIN-013 | exceed documented rate limit for a financial callable | request denied with no financial side effect and audit/log evidence |
| FIN-014 | Firebase ID token expires or is revoked during an active financial flow | server rejects or refreshes safely; no partial wallet mutation or orphan state |

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
- DAST baseline scan is run against a controlled local or staging admin web instance, or an accepted exception explains why it cannot run for this release.
- Content-Security-Policy blocks unsafe script execution where possible.
- Frame protection prevents clickjacking.
- CORS is restricted to approved origins.
- CSRF protection exists where cookies or session endpoints are used.
- OAuth redirect URIs are allow-listed.
- `postMessage` listeners validate exact trusted origins and message shape.

Commands:

```powershell
npm --prefix admin_web_console run test:security
npm --prefix admin_web_console run build:secure
# Example DAST gate; adapt target URL to the controlled local/staging admin instance.
# docker run --rm -t owasp/zap2docker-stable zap-baseline.py -t http://127.0.0.1:3000 -r zap-admin-baseline.html
```

Additional manual review:

```powershell
rg -n "admin|role|claims|finance|super_admin|token|Authorization|headers\\(|middleware|redirect|forged|fixture|fallback|Content-Security-Policy|frame-ancestors|CORS|csrf|SameSite|postMessage|redirect_uri" admin_web_console
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
- license compatibility review for direct runtime dependencies.
- typosquatting review for newly introduced direct dependencies.
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
git diff -- pubspec.yaml functions/package.json admin_web_console/package.json
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
- Top-up proof signed URL, download token, or access-token expiry policy is documented and tested where signed access is used.
- User consent, privacy notice, export/delete request, and retention UI paths are reviewed where applicable.
- A lightweight privacy impact assessment exists for PII, location, proof images, wallet records, and audit logs.
- Audit logs contain enough forensic data but do not include unnecessary secrets.

Logging redaction tests:

| Test ID | Scenario | Expected |
| --- | --- | --- |
| LOG-001 | force auth error | logs do not contain idToken, refreshToken, password, OTP, or Authorization header |
| LOG-002 | failed proof image upload | logs do not contain proof URL, download token, signed URL, or raw file metadata beyond policy |
| LOG-003 | failed admin action | logs contain actor/action/target/result but no secrets, tokens, or private payloads |
| LOG-004 | financial function validation error | logs contain request id and safe reason, not full sensitive request payload |

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
- App Check enforcement matrix exists for every sensitive callable, Storage path, and Firestore-sensitive operation where App Check is intended.
- Play Integrity decision is documented for Android financial flows, including whether it is enforce, audit-only, or deferred with rationale.
- Certificate pinning decision is documented with test evidence or an accepted rationale for not pinning.
- Failure behavior is user-readable and not a silent security bypass.
- Functions reject missing/invalid App Check where enabled.
- Firestore/Storage rules do not rely on App Check alone.

Tests:

- launch production candidate with no emulator defines,
- attempt sensitive callable with missing App Check token,
- attempt callable with valid auth but wrong role,
- attempt certificate pinning failure path if pinning is enabled,
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
- Shared responsibility model is documented for Firebase, Google Cloud, Play Console, and any payment/notification/media vendors.
- External penetration test is scheduled before first public production launch or before a security-owner-defined user/transaction threshold.
- Deploy commands are documented.
- Rollback and financial compensation runbooks are available.
- Production deploy requires human approval.
- App Check enforcement rollout plan exists.
- Monitoring and alerting cover financial function errors.
- WAF or Cloud Armor decision is documented for any public HTTP endpoint outside Firebase callable SDK paths.

Required docs:

- `docs/qa/financial-recovery-runbook.md`
- deployment rollback notes,
- owner/on-call list,
- incident template.

Pass criteria:

- no unmanaged production key,
- rollback and compensation path are clear,
- monitoring owner is assigned,
- external penetration test requirement is either complete or formally accepted as deferred with a date.

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
# Optional/required when admin web is reachable in a controlled local or staging environment
# Run OWASP ZAP baseline or equivalent DAST and store the report as evidence.

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
git diff -- pubspec.yaml pubspec.lock functions/package.json functions/package-lock.json admin_web_console/package.json admin_web_console/package-lock.json

# Full git-history secret scan
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified

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
- Tamper a deep link or App Link to open wallet, merchant, admin, top-up, or proof paths.
- Sign out then press back into protected route.
- Revoke auth token and continue using app.
- Let an ID token expire or revoke it during a financial operation.

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
- Invalid state transition such as approved to pending, credited to pending, rejected to approved, or executed reversal to executed again.
- Direct write attempting to skip a required top-up or reversal state.

Expected: denied or idempotent; verifier clean.

### Admin Boundary

- Non-admin visits admin console route.
- Finance admin attempts super-admin config publish.
- Forged admin headers.
- Missing role token.
- Production fixture fallback.
- Bundle token sentinel.
- DAST baseline scan against controlled local/staging admin URL.

Expected: denied; no privileged data exposed.

### Network And Server-Side Requests

- Inventory every `onRequest` HTTP endpoint outside callable functions.
- Inventory every server-side outbound `fetch` or HTTP client call.
- Verify outbound request targets use allow-lists and cannot access metadata, localhost, private RFC1918 ranges, or internal admin endpoints.

Expected: no SSRF path exists, or every outbound request path has allow-list, timeout, and response-size limits.

### Storage Boundary

- Anonymous upload/read sensitive file.
- User reads top-up proof.
- Merchant reads another merchant proof.
- Oversized or wrong content type upload.

Expected: denied.

## 9. Finding Severity

Severity is assigned only after evidence supports the finding. Before validation, use `Proposed severity` and `Proposed CVSS`.

Finding types:

| Type | Meaning | Release impact |
| --- | --- | --- |
| Candidate Finding | A plausible issue from review, scanning, threat modeling, or manual analysis, but not yet proven. | Requires triage; may temporarily block if high risk. |
| Confirmed Finding | Evidence proves the issue exists in code, configuration, artifact, runtime behavior, or cloud state. | P0/P1 blocks release unless policy allows acceptance. |
| Control Gap | A missing governance, process, hardening, or evidence control without a proven exploit path. | Blocks only if release gate marks the control mandatory. |
| Accepted Risk | A confirmed issue or control gap accepted by authorized owners with expiry and compensating controls. | Allowed only within the risk acceptance policy. |
| False Positive | Investigation shows the issue does not apply. | Does not block release. |

Evidence strength:

| Strength | Evidence examples |
| --- | --- |
| None | Review note only; no local evidence collected. |
| Code evidence | Source code, rules, manifest, config, or dependency files show the condition. |
| Test evidence | Unit, integration, emulator, security, or verifier test proves behavior. |
| Runtime evidence | Logcat, function logs, Firebase emulator/staging behavior, or APK inspection proves behavior. |
| Cloud evidence | Firebase/GCP console export, IAM state, App Check state, key inventory, or monitoring evidence proves behavior. |

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

Finding type: Candidate Finding / Confirmed Finding / Control Gap / Accepted Risk / False Positive
Proposed severity: P0/P1/P2/P3
Final severity:
Proposed CVSS 3.1:
Final CVSS 3.1:
CVSS vector:
Owner: Mobile/Backend/Rules/Admin/Infra
Status: Needs Verification/Triaged/In Progress/Ready for Retest/Closed/False Positive/Accepted Risk
Evidence strength: None/Code evidence/Test evidence/Runtime evidence/Cloud evidence
Verification status: Needs Verification/Verified/False Positive
Release blocking: Yes/No/Temporary pending verification
Affected commit/tag:
Affected surface:
Control ID:
Standard mapping:

### Summary

### Reproduction

### Expected

### Actual

### Impact

### Evidence

Evidence must identify exact file paths, commands, test outputs, logs, screenshots, or cloud exports. A finding with no evidence remains a candidate finding.

### Root Cause

### Fix Plan

### Verification Plan

### Regression Tests Added
```

## 11. Final Security Sign-off Checklist

Success metrics for release security:

- 0 open P0/P1 findings.
- 0 untriaged candidate P0/P1 findings.
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
- [ ] Security architecture review is complete.
- [ ] Financial state machines are documented and invalid transitions are tested.
- [ ] Control traceability matrix exists and maps tests to WAIN/OWASP/NIST/ISO controls.
- [ ] CI/CD security gates are automated or tracked with owners and release-blocking policy.
- [ ] Vulnerability SLA and risk acceptance policy are approved.
- [ ] Secrets scan completed; no real secrets in repo/build/logs.
- [ ] Git history secret scan completed; no verified production secret remains in history without revocation/rotation evidence.
- [ ] Key inventory, rotation, revocation, and access review evidence exists.
- [ ] Flutter static analysis passed.
- [ ] Flutter security-relevant tests passed.
- [ ] Firestore negative tests passed.
- [ ] Firestore query and collection-group authorization tests passed.
- [ ] Storage negative tests passed.
- [ ] Upload malware/content, metadata, private proof access, and signed URL expiry policy checks passed or have accepted rationale.
- [ ] Functions build and tests passed.
- [ ] Functions emulator security tests passed.
- [ ] Admin web security tests passed.
- [ ] Admin web secure build passed.
- [ ] Admin web DAST baseline passed or has approved exception.
- [ ] Dependency audit has no unaccepted critical/high runtime vulnerabilities.
- [ ] Direct dependency license and typosquatting review is complete.
- [ ] SBOM/dependency inventory exists for Flutter, Functions, and Admin Web.
- [ ] Release APK inspected for emulator/debug config.
- [ ] Mobile hardening decisions are documented and release APK matches them.
- [ ] Release APK logcat has no sensitive data.
- [ ] Logging redaction tests passed.
- [ ] Financial abuse tests passed.
- [ ] `qa-verify-finance` passed with `fail=0 warn=0`.
- [ ] `qa-verify-audit-trail` passed with `fail=0 warn=0`.
- [ ] App Check failure behavior verified.
- [ ] App Check enforcement matrix and rate-limit matrix are complete for sensitive callables.
- [ ] Deep link/App Link hijacking tests passed or are not applicable.
- [ ] Token expiry/revocation during financial flows is verified.
- [ ] Privacy impact assessment and retention/export/delete decisions are documented.
- [ ] Backup/restore drill and wallet recovery procedure are documented and tested.
- [ ] Shared responsibility model for high-impact vendors is documented.
- [ ] Vendor risk register exists for high-impact vendors and integrations.
- [ ] External penetration test is complete or formally scheduled/deferred by the security lead.
- [ ] Incident recovery runbook exists and is linked.
- [ ] Incident response tabletop or emulator drill is recorded.
- [ ] All P0/P1 findings closed.
- [ ] All candidate P0/P1 findings are verified, downgraded, accepted under policy, or closed as false positives.
- [ ] Any P2 accepted risk is documented with owner and expiry date.

## 12. Recommended Execution Order

1. Freeze tag/build target.
2. Run secrets/config scan.
3. Build threat model.
4. Run security architecture review and document financial state machines.
5. Create/update control traceability matrix.
6. Triage external/manual review notes into candidate findings, control gaps, accepted items, and rejected assumptions.
7. Confirm SLA, risk acceptance, key management, and CI/CD gate policy.
8. Run static code review for Flutter, Functions, Admin Web.
9. Run automated Flutter/Functions/Admin tests.
10. Run Firestore document, query, and collection-group negative tests on emulator.
11. Run Storage negative, upload security, and proof-access tests.
12. Run financial abuse tests and verifiers.
13. Build and inspect release APK.
14. Generate dependency inventory/SBOM inputs and audit results.
15. Run App Check/Play Integrity smoke on controlled QA accounts if required.
16. Promote only evidence-backed candidates to confirmed findings, then file bugs and retest fixes.
17. Run backup/restore and incident response tabletop or emulator drill.
18. Produce final security report.

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
- candidate findings triage summary,
- accepted risks,
- SLA exceptions or expired risks,
- key management and mobile hardening status,
- incident drill result if completed,
- release recommendation: Go / No-Go.
