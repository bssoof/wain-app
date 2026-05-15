# WAIN Final QA Readiness Check

Date: 2026-05-15  
Timezone: Asia/Hebron  
QA plan: `docs/qa/final-release-qa-plan-2026-05-15.md`

## Baseline

Application baseline tag:

```text
qa-final-2026-05-15 -> 6a8ba322
```

QA plan commit:

```text
bd4a6474 docs: add final release QA plan
```

Workspace status before this readiness pass:

```text
Clean after stashing local-only files:
  .firebase/hosting.cHVibGlj.cache
  .vscode/settings.json
```

Stash used:

```powershell
git stash push -m "local qa workspace files" -- .firebase/hosting.cHVibGlj.cache .vscode/settings.json
```

Rule for all QA agents/testers:

```text
Do not test "latest local code".
Use qa-final-2026-05-15 or an explicitly named patch tag only.
Any patch must produce a new build artifact and SHA256.
```

## Commands Run

### Functions Build

```powershell
cd functions
npm run build
```

Result:

```text
PASS
```

### Firestore Security Rules

```powershell
npx firebase --config firebase.json emulators:exec `
  --project demo-wain-security-rules `
  --only firestore `
  "node --test --test-concurrency=1 functions/test/rules/firestoreSecurityRules.test.js"
```

Result:

```text
PASS: 35/35
```

### Storage Security Rules

Important: this suite starts its own Storage emulator. Start only Firestore through
`firebase emulators:exec`; otherwise port 9199 conflicts.

```powershell
npx firebase --config firebase.json emulators:exec `
  --project demo-wain-security-storage `
  --only firestore `
  "node --test --test-concurrency=1 functions/test/rules/storageSecurityRules.test.js"
```

Result:

```text
PASS: 18/18
```

## Findings

### 1. QA Firebase Environment Is Not Wired In Repo

Current `.firebaserc`:

```json
{
  "projects": {
    "default": "wain-d2e28"
  }
}
```

Flutter initializes Firebase via:

```text
DefaultFirebaseOptions.currentPlatform
```

The app has emulator support through:

```text
WAIN_USE_FIREBASE_EMULATORS
WAIN_FIREBASE_EMULATOR_HOST
```

But no verified `wain-qa-staging` project binding was found in repo, and the
documented `--dart-define=FIREBASE_PROJECT=...` switch is not currently wired to
Firebase initialization.

Readiness status:

```text
BLOCKER before Day 0 if QA is intended to run on a Firebase project instead of emulator.
```

Required decision:

```text
Either:
  A. Configure a real QA Firebase project and matching google-services/firebase_options.
  B. Declare emulator-only QA for Day 0 and do not run wallet tests on production.
```

### 2. Feature-Level Rollback Flags Are Not Present

No matches were found for:

```text
feature_merchant_reversal_enabled
feature_story_attribution_enabled
feature_promote_story_enabled
FirebaseRemoteConfig / remote_config
```

Readiness status:

```text
Feature-level rollback is not available from the current app code.
Rollback is build/deploy-level unless flags are added before launch.
```

### 3. Full QA Seed Script Is Missing

Existing partial scripts:

```text
admin_web_console/scripts/seed-local-emulator.mjs
admin_web_console/scripts/seed-merchant-reversal-e2e.mjs
functions/scripts/seed_transport_mvp.js
functions/scripts/seed_wallet_config.js
```

Missing plan-required script:

```text
scripts/qa-seed.mjs
```

Readiness status:

```text
BLOCKER for repeatable multi-tester QA.
```

Reason:

```text
Wallet, top-up, reversal, stories, admin roles, and analytics need stable data
for every tester and every patch.
```

### 4. Security Rules Coverage Exists And Passes

Firestore rules include negative tests for:

```text
- merchant wallet read boundaries
- wallet ledger write denial
- top-up direct client-write denial
- wallet_reversal_requests read/write boundaries
- admin document active-state checks
- wallet audit events admin-only reads
```

Storage rules include tests for:

```text
- merchant uploads to own venue paths only
- story/media file type and size constraints
- wallet_topups receipt upload path
- admin receipt reads
- user/other merchant receipt read denial
```

Readiness status:

```text
PASS for current rules suites.
```

### 5. Client Financial Writes Are Mostly Callable-Bound

Flutter merchant wallet flows:

```text
createMerchantTopUpRequest -> callable
createMerchantWalletReversalRequest -> callable
promoteStory -> callable
```

Admin wallet reversal:

```text
reverseWalletEntry -> callable
approveWalletReversalRequest -> callable
```

Direct client write exception:

```text
Top-up proof image upload goes directly to Storage, guarded by storage.rules.
```

Readiness status:

```text
PASS with Storage rules gate above.
```

### 6. Idempotency / Replay Status

Observed protections:

```text
promoteStory:
  requestId -> deterministic wallet entry id story_promotion_<requestId>
  duplicate same request returns idempotent result.

pinOffer:
  requestId -> deterministic wallet entry id offer_pin_<requestId>
  duplicate same request returns idempotent result.

approveWalletReversalRequest:
  commandId required.
  duplicate approval command returns existing executed result.

reverseWalletEntry:
  commandId/idempotency key support exists.

reviewMerchantWalletReversalRequest:
  status guards pending_review and validates preconditions before execution.
```

Open risk:

```text
createMerchantTopUpRequest does not accept a client requestId and creates a new
merchant_topup_requests doc on each call.
```

Readiness status:

```text
P0/P1 QA gate: double-submit top-up must be tested explicitly.
Recommended code hardening: add a client requestId/idempotency key for top-up creation.
```

### 7. Audit Trail Exists For Financial Paths

Observed audit mechanisms:

```text
logSecurityAudit(...)
upsertWalletAuditEvent(...)
```

Observed audit categories/events include:

```text
topup_request_created
topup_request_approved
wallet_entry_reversed
merchant_review_rejected
merchant_review_approved_and_executed
wallet_reversal_approved_and_executed
story_promotion
offer_pin
```

Readiness status:

```text
PASS for presence.
QA still needs one audit readability check per financial action in staging/emulator.
```

## Added Tooling

Added:

```text
scripts/qa-verify-finance.mjs
```

Purpose:

```text
Read-only QA finance verifier for wallet invariants.
```

Checks:

```text
- wallet.available_balance matches final ledger balance_after
- each ledger entry balance_after matches previous balance + signed delta
- duplicate idempotency_key across wallet entries
- duplicate reversal entries for same original entry
- credited top-up requests link to existing credit entries
- approved reversal requests link to existing reversal entries
```

Usage:

```powershell
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
node scripts/qa-verify-finance.mjs --project=demo-wain --venue=venue_qa_01 --strict
```

Safety:

```text
The script refuses live Firestore unless --allow-live is provided.
Prefer emulator or QA/staging project.
```

## Blockers Before Day 0

1. Configure and document the QA Firebase environment.

```text
Do not run financial QA on production unless formally approved and all QA users
are isolated with is_qa_test_user=true.
```

2. Add the full QA seed script.

```text
scripts/qa-seed.mjs
```

It must create the users, merchants, venues, wallets, entries, stories, offers,
and admin roles listed in the QA plan.

3. Decide feature flag reality.

```text
Either wire Remote Config flags before launch, or mark feature-level rollback as unavailable.
```

4. Decide top-up creation idempotency.

```text
Either add requestId/idempotency to createMerchantTopUpRequest, or keep double-submit top-up
as a mandatory P0 QA scenario.
```

5. Define final agent baseline protocol.

```text
Every agent must start by printing:
  git rev-parse --short HEAD
  git status --short
  git describe --tags --exact-match 2>$null

If the tag is not qa-final-2026-05-15 or the approved patch tag, the agent must stop.
```

## Recommended Next Agent Prompt

Use this exact handoff for a QA automation or hardening agent:

```text
You are working on WAIN final-release QA readiness.

Required baseline:
  App code tag: qa-final-2026-05-15
  Baseline commit: 6a8ba322
  QA docs commit may be newer, but do not test or modify app code from any unapproved commit.

First commands:
  git status --short
  git rev-parse --short HEAD
  git show --no-patch --oneline qa-final-2026-05-15

If the working tree is dirty, or app code is not qa-final-2026-05-15 / approved patch tag,
stop and report. Do not continue on a random local version.

Read before coding:
  docs/qa/final-release-qa-plan-2026-05-15.md
  docs/qa/final-release-qa-readiness-2026-05-15.md

Task:
  Implement the missing Day 0 QA setup only:
    1. scripts/qa-seed.mjs for repeatable QA data.
    2. Confirm or wire QA Firebase project config.
    3. If Remote Config flags are not present, update rollback docs to say build/deploy rollback only.
    4. Add or verify top-up creation idempotency, or create a focused failing QA test that proves the current risk.

Constraints:
  - No production data.
  - No broad refactors.
  - Keep changes atomic.
  - Run targeted tests:
      npm run build in functions
      Firestore rules suite
      Storage rules suite
      Any new seed/verifier tests

Output:
  - Files changed
  - Commands run and results
  - Remaining P0/P1 blockers
```
