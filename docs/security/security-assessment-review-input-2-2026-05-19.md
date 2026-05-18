# WAIN Security Assessment Review Input 2

Date: 2026-05-19

Source:

- Review pasted in chat by project owner on 2026-05-19.

Source plan:

- `docs/security/full-application-security-assessment-plan-2026-05-19.md`

## Review Summary

This second review agrees that the security plan is strong, especially around release gates, SLA/risk acceptance, Firestore/Storage denial matrices, financial integrity verifiers, QA/production APK separation, and evidence discipline.

It adds specific improvement requests that should be triaged as candidate findings or control gaps until verified:

- App Check enforcement coverage map per callable function.
- Numeric API rate limits and dedicated rate-limit test cases.
- Dedicated Android App Links / deep link hijacking test cases.
- Inventory for REST/HTTP endpoints outside Firebase callable functions.
- Certificate pinning decision plus test evidence.
- Automated DAST for the Admin Web Console.
- Firebase ID token expiry and token revocation behavior during active financial flows.
- Third-party shared responsibility model for Firebase/Google and other critical vendors.
- External penetration test requirement before public launch or a defined usage/transaction threshold.
- Privacy impact assessment and user-facing consent/retention/delete/export checks.
- Signed URL expiry policy for proof images.
- SSRF review if Functions perform outbound HTTP requests.
- License compliance and typosquatting checks for dependencies.

## Triage Note

The review uses P0/P1 language for several items. Under the current WAIN methodology, these remain `Candidate Finding` or `Control Gap` until backed by code, configuration, test, runtime, or cloud evidence.
