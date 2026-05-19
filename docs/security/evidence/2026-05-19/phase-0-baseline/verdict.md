# Phase 0 Baseline Verdict

Date: 2026-05-19
Target commit: `d880f1cc40410a1452e5ca085d578c6062c41795`
Git describe: `qa-final-2026-05-15-p11-5-gd880f1cc`

Verdict: No-Go / assessment in progress.

## Passed

- `flutter analyze`
- `flutter test`
- `npm --prefix functions run build`
- `npm --prefix functions test`
- `npm --prefix admin_web_console run test:security`
- `npm --prefix admin_web_console run build:secure`
- Admin web extra security tests from `admin_web_console` cwd
- QA seed + `qa-verify-finance` + `qa-verify-audit-trail`

## Blocking Or Needs Triage

- Local ignored `service-account-key.json` exists and contains a private key; classify and rotate/revoke if production-capable.
- Functions dependency audit reports Critical/High runtime vulnerabilities.
- Admin web dependency audit reports High runtime vulnerabilities.
- Functions emulator aggregate gate fails content moderation callable flows.
- Storage rules allow venue owners to delete wallet top-up proof files; decide whether this violates financial evidence retention.
- `gitleaks` and `trufflehog` are unavailable locally; full Git-history secret scan evidence is incomplete.
- Admin web DAST did not run because Docker/ZAP is not available locally.
- Review 4 additions are accepted as candidate/control-gap inputs and still require validation: stale claims, Phone Auth/OTP applicability, FCM/Remote Config applicability, listener abuse, compliance scope, and ledger tamper-evidence decision.

## Finance Verifier

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=26 fail=0 warn=0
```

See `docs/security/full-application-security-assessment-report-2026-05-19.md` for the living assessment report.
