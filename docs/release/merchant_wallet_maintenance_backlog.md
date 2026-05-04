# Merchant Wallet Maintenance Backlog

## Item MW-M01: Firebase Functions Dependency Upgrade

Status: planned
Priority: low (non-blocking for soft launch), required before wider rollout
Owner: backend operations

## Context
During Phase 16 deployment, functions deploy logs reported an outdated firebase-functions package warning.

This did not block soft launch, but it is technical debt and must be closed before broader rollout.

## Scope
- Upgrade firebase-functions to latest compatible version in functions runtime.
- Rebuild and redeploy functions.
- Run focused wallet smoke checks only (no feature changes):
  - top-up create/approve
  - story promote debit + idempotent retry
  - offer pin debit + idempotent retry
  - reversal
  - verifyWalletOperationalReadiness

## Safety Constraints
- No wallet product behavior changes in this maintenance release.
- If regressions appear, rollback functions revision and keep ledger append-only rules unchanged.

## Completion Criteria
- deploy log no longer reports firebase-functions outdated warning.
- wallet focused smoke checks pass.
- release notes updated with maintenance closure.
