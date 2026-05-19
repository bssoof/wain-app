# WAIN Security Assessment Review Input 4

Date: 2026-05-19

Source:

- Review pasted in chat by project owner on 2026-05-19.

Source plan:

- `docs/security/full-application-security-assessment-plan-2026-05-19.md`

## Review Summary

This fourth review agrees that the plan is enterprise-grade and validates the core emphasis on Firebase Rules, Cloud Functions, evidence capture, and wallet/ledger/audit integrity.

It adds or emphasizes the following candidate findings and control gaps:

- Compliance scoping questions for PCI-DSS, GDPR, and local privacy law.
- Explicit Firebase Security Rules unit tests with `@firebase/rules-unit-testing`.
- Firestore query/index behavior and collection-group authorization coverage.
- Firebase Auth Phone OTP brute-force/rate-limit and SIM-swap related controls.
- Stale custom-claim and revoked-token tests after role changes.
- Security headers and CORS/CSRF handling for any `onRequest` Cloud Functions or Admin Web proxy routes.
- Push notification / FCM topic threat model.
- Firebase Remote Config and A/B Testing threat model where feature flags affect financial or privileged behavior.
- Firestore listener abuse and cost/DoS review.
- Anonymous Auth capability and authorization matrix.
- Native Flutter plugin SCA review beyond standard pub dependency inventory.
- Wallet anomaly threshold alerts.
- Cross-instance race-condition testing for wallet writes.
- Backup integrity verification, including a decision on ledger hash-chain or equivalent tamper-evidence.

## Triage Note

The review proposes several critical findings. Under the WAIN methodology, these are accepted as candidate findings or control gaps until verified with code, rules, tests, runtime evidence, or Firebase/GCP state.

Compliance language should be handled as scope determination. PCI-DSS is only applicable if WAIN stores, processes, or transmits cardholder data or integrates payment flows in a way that brings the application into scope. Wallet balances or top-up proofs alone do not prove PCI scope without payment-card handling evidence.
