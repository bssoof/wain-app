# WAIN Security Assessment Review Triage

Date: 2026-05-19

Source review:

- `docs/security/security-assessment-review-input-2026-05-19.md`

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

## Rejected Or Modified Assumptions

| Assumption | Triage decision | Reason |
| --- | --- | --- |
| Treat all WAIN-F-001 through WAIN-F-015 as confirmed findings immediately | Reject | Findings require evidence. Until then they are candidate findings or control gaps. |
| Use final CVSS scores before validation | Modify | Use `Proposed CVSS` until exploitability and impact are verified against the actual implementation. |
| Declare final `No-Go` based only on the review package | Modify | Correct state is `Conditional Go pending assessment execution`; confirmed P0/P1 findings would then become release blockers. |
| Require Play Integrity as the only proof of app trust | Reject | Play Integrity is defense-in-depth. Server-side auth, ownership, rules, transactions, idempotency, and audit remain mandatory controls. |
| Treat `service-account-key.json` as a production leak without inspection | Reject | It is a high-priority candidate, but production exposure must be proven by file tracking, content, and IAM state. |

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
