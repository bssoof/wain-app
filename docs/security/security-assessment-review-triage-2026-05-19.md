# WAIN Security Assessment Review Triage

Date: 2026-05-19

Source review:

- `docs/security/security-assessment-review-input-2026-05-19.md`
- `docs/security/security-assessment-review-input-2-2026-05-19.md`
- `docs/security/security-assessment-review-input-3-2026-05-19.md`
- `docs/security/security-assessment-review-input-4-2026-05-19.md`

Source plan:

- `docs/security/full-application-security-assessment-plan-2026-05-19.md`

## Executive Triage

The pasted review is a strong defensive AppSec package and should be used as input for the assessment report, Findings backlog, and remediation roadmap.

However, the review currently labels several items as active `New` P0/P1 findings before evidence has been collected from code, configuration, tests, runtime behavior, or Firebase/GCP state. For release governance, those items must initially be tracked as `Candidate Finding` or `Control Gap` until verified.

Recommended release-decision wording:

- Current state: `Security assessment not yet fully executed`.
- Review package decision: `Accepted as assessment input`.
- Release decision: `Conditional Go pending execution of security assessment and closure of any confirmed P0/P1 findings`.

## Accepted Review Improvements

| Recommendation | Triage | Reason | Target artifact |
| --- | --- | --- | --- |
| Expand mobile mapping beyond MASVS-STORAGE/RESILIENCE | Accept | The plan should explicitly cover MASVS-AUTH, MASVS-CRYPTO, MASVS-NETWORK, MASVS-PLATFORM, MASVS-CODE, and MASVS-RESILIENCE. | Security plan / control matrix |
| Add formal STRIDE and lightweight LINDDUN threat model framing | Accept | Makes the threat model more auditable and privacy-aware. | Threat model artifact |
| Define App Check enforcement matrix | Accept | Sensitive callables need an explicit enforce/audit-only decision and evidence. | Security plan / Functions review |
| Add Play Integrity decision point | Accept | Useful Android financial-app hardening control, but must be documented as defense-in-depth and not a replacement for server authorization. | Mobile hardening / Functions review |
| Add explicit rate limiting and anti-abuse plan | Accept | Current plan mentions rate limiting but should require a concrete mechanism and evidence. | Functions security review |
| Require backup restore drill evidence | Accept | Recovery is not proven until restore is tested. | Operational security phase |
| Add privacy-by-design outputs | Accept | PII, location, proof images, and financial records require retention/export/delete decisions even without formal compliance. | Privacy phase / DPIA |
| Add crash/log redaction and retention checks | Accept | Log sinks can leak PII or tokens if not governed. | Logs/privacy phase |
| Add Android App Links verification checks | Accept | Deep links should be verified with Digital Asset Links where applicable. | Mobile review |
| Add WebView security check if WebView exists | Accept | Conditional control: only applies if the app uses WebView. | Mobile review |
| Add responsible disclosure/security.txt | Accept as P3 hardening | Good post-release security operations practice. | Operational security |
| Add optional third-party penetration test recommendation | Accept as recommendation | Useful before production, but release-blocking status depends on business/security owner policy. | Final sign-off |

## Accepted Review 2 Improvements

| Recommendation | Triage | Reason | Target artifact |
| --- | --- | --- | --- |
| Add App Check coverage map per callable | Accept | The phrase `where required` is too vague for financial callables. | Functions review / App Check phase |
| Add numeric rate-limit matrix and FIN-013 | Accept | Rate limiting must be testable and not only conceptual. | Functions review / Financial abuse tests |
| Add token expiry or revocation during active financial flow as FIN-014 | Accept | Session failure behavior must not create partial financial state. | Financial abuse tests |
| Add deep link/App Link hijacking scenario | Accept | Existing route checks should explicitly cover external link entry points. | Manual penetration scenarios |
| Add REST/HTTP endpoint and outbound request inventory | Accept | Any non-callable HTTP surface or server-side fetch needs separate review, including SSRF risk. | Functions review / Network scenarios |
| Add certificate pinning test evidence or documented rationale | Accept | The hardening decision should be backed by test evidence or explicit acceptance. | Network/transport phase |
| Add Admin Web DAST baseline | Accept | Complements SAST and manual review for XSS/CSRF/misconfiguration classes. | Admin web / CI gates |
| Add privacy impact, retention UI, export/delete checks | Accept | PII, location, proof images, and financial records need explicit privacy handling. | Privacy phase |
| Add signed URL or download token expiry policy for proof images | Accept | Proof image access needs a documented lifetime and access path. | Storage/privacy phase |
| Add vendor shared responsibility model | Accept | Clarifies what WAIN owns versus Firebase/Google/vendor controls. | Operational security |
| Add external penetration test checkpoint | Accept as release recommendation | Valuable before public production launch, with release-blocking status set by the security lead. | Final sign-off |

## Accepted Review 3 Improvements

| Recommendation | Triage | Reason | Target artifact |
| --- | --- | --- | --- |
| Add dedicated security architecture review | Accept | Tests can pass while architecture still has duplicated authority or weak privilege boundaries. | Main plan / architecture phase |
| Add financial state machine documentation and invalid transition tests | Accept | Financial workflows need explicit allowed transitions and rejected stale/duplicate transitions. | Financial phase / architecture review |
| Add full Git history secret scan | Accept | Deleted secrets can remain exploitable if present in old commits. | Secrets phase / command suite |
| Add Firestore query and collection-group authorization tests | Accept | Firebase rules must prove query shape and document access compatibility, not only direct document access. | Firestore rules phase |
| Add Admin browser controls for CSP/CORS/CSRF/clickjacking/cookies/OAuth/postMessage | Accept | Admin web has browser-specific risk beyond Firebase auth and route guards. | Admin web phase |
| Add malicious upload, metadata, private proof access, and signed URL expiry checks | Accept | Proof images and merchant media need content and privacy controls beyond basic MIME checks. | Storage/privacy phase |
| Add logging redaction tests | Accept | Log policy must be proven under failure paths, not only stated. | Privacy/logging phase |
| Add backup/restore/disaster recovery and wallet recovery procedure | Accept | Financial integrity requires recovery evidence, not only preventive controls. | Operational security |
| Add practical vendor risk register | Accept | Converts vendor risk from a concept into trackable operational evidence. | Supply chain / operational security |

## Accepted Review 4 Improvements

| Recommendation | Triage | Reason | Target artifact |
| --- | --- | --- | --- |
| Add compliance scoping for PCI-DSS/GDPR/local privacy law | Accept as scope question | Compliance applicability depends on payment-card handling, geography, user residency, and legal review. | Threat model / final report |
| Add explicit `@firebase/rules-unit-testing` rules tests | Accept | Fast rules-specific tests are useful in addition to emulator aggregate tests. | Firestore/Storage test phases |
| Add stale custom-claim and revoked-role tests | Accept | Firebase ID tokens can contain old role claims until refresh; sensitive functions need Firestore source-of-truth checks and revocation behavior. | Auth/session and Functions tests |
| Add Phone OTP brute-force/rate policy if Phone Auth is enabled | Accept conditionally | Applies only if phone OTP is part of the production auth flow. | Auth/session phase |
| Add Cloud Functions HTTP headers, CORS, and CSRF checks for `onRequest` or proxy routes | Accept | Non-callable HTTP routes need browser/API controls separate from callable auth. | Functions/Admin Web review |
| Add Push/FCM topic threat model | Accept conditionally | Applies if FCM, topics, or notification fan-out are used. | Threat model / mobile/backend review |
| Add Remote Config/A-B Testing review | Accept conditionally | Applies if flags can influence financial, admin, auth, or authorization behavior. | Configuration phase |
| Add Firestore listener abuse and cost/DoS review | Accept | Excessive listeners can create cost and availability risk even without data exposure. | Firestore/privacy/ops review |
| Add Anonymous Auth authorization matrix | Accept | Anonymous Firebase users need explicit allow/deny tests if enabled. | Auth/rules phases |
| Add native Flutter plugin SCA review | Accept | Mobile plugins can introduce native Android security risk not captured by simple pub version review. | Dependency phase |
| Add wallet anomaly threshold alerts | Accept | Financial abuse detection needs operational monitoring, not only preventive tests. | Operational security |
| Add cross-instance race-condition tests | Accept | Financial functions should remain correct under concurrent Cloud Functions instances. | Concurrency phase |
| Add backup integrity / ledger tamper-evidence decision | Accept as architecture decision | Hash-chain or equivalent tamper-evidence may be appropriate, but should be chosen after architecture review. | Architecture / backup phase |

## Items To Reframe Before Treating As Findings

| Review item | Current review wording | Correct triage status | Evidence needed |
| --- | --- | --- | --- |
| WAIN-F-001 | P0: App Check + Play Integrity missing | Candidate Finding / Control Gap | Functions code, Firebase App Check console state, callable config, test proving missing/invalid token behavior |
| WAIN-F-002 | P0: service-account-key.json in repo | Candidate Finding until proven | `git ls-files`, secret scan, file contents classification, GCP IAM key list, revocation evidence if real |
| WAIN-F-003 | P0: Two-Person Rule not proven | Candidate Finding | Reversal functions code, Firestore role source-of-truth checks, transaction/audit evidence, FIN-007 result |
| WAIN-F-004 | P1: PII/token logcat leakage | Candidate Finding | `rg` log search, release logcat run, Functions/admin log redaction review |
| WAIN-F-005 | P1: idempotency not enforced | Candidate Finding | Top-up/reversal callable code, transaction/idempotency docs, FIN-001/FIN-002/FIN-005/FIN-006 results |
| WAIN-F-006 | P1: App Links not verified | Candidate Finding | AndroidManifest intent filters, assetlinks.json, `pm get-app-links`, route guard tests |
| WAIN-F-007 | P1: Storage content-type/size controls missing | Candidate Finding | `storage.rules`, emulator tests ST-007/ST-008 |
| WAIN-F-008 | P1: cleartext exception may leak to release | Candidate Finding | APK manifest/resource inspection for production candidate |
| WAIN-F-009 | P2: missing rate limit | Candidate Finding / Control Gap | Functions code and monitoring configuration |
| WAIN-F-010 | P2: FLAG_SECURE missing | Candidate Finding / Hardening Gap | Route list, screenshot policy, runtime screenshot test |
| WAIN-F-011 | P2: Crashlytics PII risk | Candidate Finding | Crashlytics usage, redaction configuration, sample logs |
| WAIN-F-012 | P2: obfuscation/split debug info not enforced | Candidate Finding | CI build command and release artifact metadata |
| WAIN-F-013 | P3: security.txt missing | Control Gap | Public web/domain check and policy decision |
| WAIN-F-014 | P3: DPIA missing | Control Gap | Product/privacy decision and data classification |
| WAIN-F-015 | P3: restore drill missing | Control Gap | Backup configuration and restore drill record |
| Review 2: App Check map missing | P0: App Check map absent | Candidate Finding / Control Gap | Callable inventory, Firebase App Check state, function config, missing-token tests |
| Review 2: Rate limits unspecified | P1: rate limits missing | Candidate Finding / Control Gap | Function code, documented thresholds, FIN-013 result |
| Review 2: Deep link hijacking not tested | P1: deep link test gap | Candidate Finding / Test Gap | AndroidManifest, route guards, App Links verification, manual test result |
| Review 2: REST/HTTP endpoint inventory missing | P1/P2 depending on exposure | Candidate Finding / Control Gap | `onRequest` and outbound HTTP inventory, SSRF review |
| Review 2: DAST missing | P2: admin DAST gap | Control Gap | Admin web local/staging URL, ZAP or equivalent DAST output |
| Review 2: Token expiry mid-transaction not tested | P2: session edge-case gap | Candidate Finding / Test Gap | FIN-014 result and transaction state evidence |
| Review 3: Security architecture review missing | Governance/architecture gap | Control Gap | Architecture review artifact and sign-off |
| Review 3: State machines not documented | Financial design gap | Candidate Finding / Control Gap | State transition documentation and invalid-transition tests |
| Review 3: Git history not scanned | Secret hygiene gap | Candidate Finding / Control Gap | gitleaks/trufflehog history output |
| Review 3: Query authorization tests missing | Rules test gap | Candidate Finding / Test Gap | FS-Q test results |
| Review 3: Admin browser security controls need detail | Admin web hardening gap | Candidate Finding / Control Gap | Header/CORS/CSRF/OAuth/postMessage evidence |
| Review 3: Upload malware/metadata handling incomplete | Storage hardening gap | Candidate Finding / Control Gap | ST-009 through ST-012 evidence and policy |
| Review 3: Logging redaction tests missing | Logging test gap | Candidate Finding / Test Gap | LOG-001 through LOG-004 evidence |
| Review 3: Backup/restore drill missing | Recovery control gap | Control Gap | Restore drill and wallet recovery evidence |
| Review 3: Vendor risk register missing | Supply-chain governance gap | Control Gap | Vendor risk register |
| Review 4: PCI-DSS assumed from wallet language | Compliance risk | Control Gap / Scope Question | Payment-card data flow inventory and legal/security owner decision |
| Review 4: Custom claims may be stale | Candidate authz finding | Candidate Finding | Function-level role source-of-truth evidence and revoked-role tests |
| Review 4: Phone OTP brute force | Auth abuse gap | Candidate Finding / Conditional Control Gap | Proof Phone Auth is enabled, Firebase/Auth settings, rate-limit/reCAPTCHA evidence |
| Review 4: Cloud Functions headers/CORS/CSRF missing | HTTP/API hardening gap | Candidate Finding / Conditional Control Gap | `onRequest` inventory, Admin proxy route evidence, header/CORS/CSRF tests |
| Review 4: FCM topic abuse | Notification abuse gap | Conditional Control Gap | FCM usage inventory, topic naming/subscription controls, notification sender functions |
| Review 4: Remote Config financial flags | Configuration trust-boundary gap | Conditional Control Gap | Remote Config usage inventory and proof no financial privilege is client-authoritative |
| Review 4: Firestore listener DoS | Cost/availability risk | Candidate Finding / Control Gap | Listener inventory, query limits, pagination, abuse monitoring |
| Review 4: Hash-chain missing from ledger | Integrity hardening gap | Architecture Decision / Control Gap | Ledger architecture review and selected tamper-evidence design |

## Rejected Or Modified Assumptions

| Assumption | Triage decision | Reason |
| --- | --- | --- |
| Treat all WAIN-F-001 through WAIN-F-015 as confirmed findings immediately | Reject | Findings require evidence. Until then they are candidate findings or control gaps. |
| Use final CVSS scores before validation | Modify | Use `Proposed CVSS` until exploitability and impact are verified against the actual implementation. |
| Declare final `No-Go` based only on the review package | Modify | Correct state is `Conditional Go pending assessment execution`; confirmed P0/P1 findings would then become release blockers. |
| Require Play Integrity as the only proof of app trust | Reject | Play Integrity is defense-in-depth. Server-side auth, ownership, rules, transactions, idempotency, and audit remain mandatory controls. |
| Treat `service-account-key.json` as a production leak without inspection | Reject | It is a high-priority candidate, but production exposure must be proven by file tracking, content, and IAM state. |
| Treat PCI-DSS as automatically applicable because the app has wallets | Modify | PCI scope requires payment-card data flow evidence. Keep as a compliance scoping question until data flows and payment providers are known. |
| Treat missing ledger hash-chain as a confirmed vulnerability | Modify | It is a tamper-evidence architecture decision. Current release blocking depends on ledger integrity, audit, backups, IAM, and verifier evidence. |
| Treat Firestore composite indexes as a data exposure path by themselves | Modify | Rules still authorize query results. Index/query tests should prove allowed query shapes and deny broad collection/collection-group reads; missing indexes are usually availability/setup evidence. |
| Assign CVSS to pure governance gaps like external pentest absence | Modify | Use priority and release policy. CVSS applies to technical vulnerabilities, not every process gap. |
| Treat query-test or logging-test gaps as confirmed exploitable issues before execution | Reject | Missing test coverage is a control gap until a failing test or vulnerable implementation is shown. |

## Required Plan Changes

| Priority | Change | Target section |
| --- | --- | --- |
| P1 | Add `Finding Lifecycle And Evidence Strength` section. | Finding Severity / Finding Template |
| P1 | Add fields: `Finding Type`, `Evidence Strength`, `Verification Status`, `Proposed CVSS`, `Final CVSS`, `Release Blocking`. | Finding Template |
| P1 | Clarify that candidate findings do not block release until verified, except when security lead marks them as temporary blockers pending urgent verification. | Release Gate |
| P1 | Expand MASVS coverage mapping. | Control Traceability Matrix |
| P1 | Add App Check / Play Integrity enforcement matrix. | Network, Transport, And App Check |
| P1 | Add Android App Links and WebView controls. | Flutter Client Security Review |
| P2 | Add privacy/DPIA/retention/DSAR lightweight artifacts. | Privacy And Data Minimization |
| P2 | Add backup restore drill evidence. | IAM, Deployment, And Operational Security |
| P2 | Add responsible disclosure/security.txt as post-release security ops control. | Incident Response / Operational Security |
| P1 | Add App Check enforcement and rate-limit matrix. | Cloud Functions / App Check |
| P1 | Add FIN-013 and FIN-014 for rate-limit and token-expiry behavior. | Financial abuse tests |
| P1 | Add REST/onRequest/outbound HTTP and SSRF inventory. | Cloud Functions / Manual scenarios |
| P1 | Add deep link/App Link hijacking scenario. | Flutter client / Manual scenarios |
| P2 | Add Admin Web DAST baseline or accepted exception. | Admin web / CI gates |
| P2 | Add signed URL expiry, PIA, consent, retention, export/delete checks. | Privacy and Storage |
| P2 | Add vendor shared responsibility and external pentest checkpoint. | Operational security |
| P1 | Add dedicated security architecture review and financial state-machine security. | Additional mandatory technical controls |
| P1 | Add Git history secret scan. | Secrets phase / command suite |
| P1 | Add Firestore query and collection-group authorization tests. | Firestore rules phase |
| P1 | Add Admin browser security controls. | Admin web phase |
| P2 | Add malicious upload, metadata, private proof access, and signed URL expiry checks. | Storage/privacy phase |
| P2 | Add logging redaction tests. | Privacy/logging phase |
| P2 | Add backup/restore/disaster recovery and vendor risk register. | Operational security / SBOM |
| P1 | Add stale-claims, revoked-role, and Phone Auth/OTP controls where applicable. | Authentication and Functions phases |
| P1 | Add Cloud Functions HTTP headers/CORS/CSRF review for `onRequest` and Admin proxy routes. | Functions/Admin Web phases |
| P2 | Add FCM, Remote Config, anonymous auth, listener abuse, wallet anomaly alerts, and native plugin SCA checks. | Threat model / Auth / Dependency / Ops phases |
| P2 | Add backup integrity and ledger tamper-evidence decision. | Architecture / Backup phase |

## Verification Sweep For Candidate P0/P1 Items

Run these before promoting any candidate to a confirmed finding.

```powershell
# Baseline target
git status --short
git describe --tags --always --dirty
git log --oneline -5

# Candidate WAIN-F-002: secret/service account exposure
rg -n --hidden --glob '!build/**' --glob '!node_modules/**' --glob '!.git/**' "BEGIN PRIVATE KEY|PRIVATE KEY|client_email|service_account|refresh_token|FIREBASE_TOKEN|Bearer "
git ls-files | Select-String -Pattern "service-account|\.env|keystore|jks|p12|pem|key\.json"

# Candidate WAIN-F-001 / F-003 / F-005 / F-009: Functions financial controls
rg -n "onCall|onRequest|enforceAppCheck|appCheck|PlayIntegrity|idempot|client_request_id|runTransaction|reversal|top.?up|wallet|audit|role|claims" functions/src
npm --prefix functions run build
npm --prefix functions test
npm --prefix functions run test:emulator:aggregate

# Candidate WAIN-F-004: client/server logging
rg -n "debugPrint\(|print\(|log\(|logger|idToken|refreshToken|Bearer|otp|password|secret|wallet|proof" lib functions/src admin_web_console

# Candidate WAIN-F-006 / F-008 / F-010 / F-012: Android hardening
rg -n "intent-filter|android:autoVerify|assetlinks|usesCleartextTraffic|networkSecurityConfig|FLAG_SECURE|WindowManager|debuggable" android lib

# Candidate WAIN-F-007: Storage rules
rg -n "contentType|request\.resource\.size|request\.auth|storage|top.?up|proof|venue" storage.rules firebase.json test functions
```

## Recommended Next Step

1. Patch the main security plan to add the finding lifecycle fields and candidate-vs-confirmed wording.
2. Execute the verification sweep for WAIN-F-001 through WAIN-F-008 first.
3. Promote only evidence-backed items to confirmed findings.
4. Produce `docs/security/full-application-security-assessment-report-2026-05-19.md` after the command suite and manual checks have evidence.

## Triage Verdict

Accepted as a high-value review package.

Do not treat it as a final security report yet. It is a strong input for the final report and backlog, but the next engineering step is verification against the actual WAIN codebase and Firebase/GCP configuration.
