# Final Local QA Handoff - 2026-05-16

## Current Local Release Point

- Branch: `main`
- Handoff tag: `qa-final-2026-05-15-p6`
- Previous verified tag: `qa-final-2026-05-15-p5`
- Remote push: not requested; no remote is configured for this local repository.

## Emulator Setup

Firebase namespace:

```text
wain-d2e28
```

Required emulator hosts:

```powershell
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
```

Seed command:

```powershell
node scripts/qa-seed.mjs --project=wain-d2e28 --reset --out=.tmp/qa-seed-output.json
```

Verifier commands:

```powershell
node scripts/qa-verify-finance.mjs --project=wain-d2e28 --venue=venue_qa_01,venue_qa_02 --strict
node scripts/qa-verify-audit-trail.mjs --project=wain-d2e28 --venue=venue_qa_01,venue_qa_02 --strict
```

## Completed Smoke Coverage

- Consumer discovery flow opened the seeded QA venue.
- Merchant login routed to merchant dashboard.
- Merchant wallet screen opened.
- Merchant top-up request was created from the Flutter app.
- Merchant reversal request was created from the Flutter app.
- Admin approved the app-created top-up request.
- Finance admin reviewed the app-created reversal request.
- Super admin completed the required second approval for the reversal.
- Finance verifier passed after the full financial flow.
- Audit verifier passed after the full financial flow.

## Final Verifier Results

Finance:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
FINANCE_EXIT=0
```

Audit:

```text
QA audit verifier summary: audit_events=34 fail=0 warn=0
AUDIT_EXIT=0
```

## Important Evidence

Detailed evidence is recorded in:

```text
docs/qa/day0-smoke-2026-05-16.md
```

Key request ids:

- Top-up: `topup_venue_qa_01_topup_hikr1g2wuc_1decfkv`
- Merchant reversal: `merchant_review_entry_qa_600`
- Executed reversal entry: `reversal_entry_qa_600`

## Local Notes

- Keep work local unless explicitly asked to configure a remote and push.
- The top-up sheet feedback issue found during smoke has been addressed locally by closing the modal with `Navigator.pop` after successful submission and showing the success snackbar after the close.
- `qa-verify-audit-trail.mjs` now covers the two-step merchant reversal approval path.
