# Final Local QA Handoff - 2026-05-16

## Current Local Release Point

- Branch: `main`
- Handoff tag: `qa-final-2026-05-15-p7`
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

## Latest Wallet Summary Smoke

Run date: `2026-05-18`

Build:

```text
build/app/outputs/flutter-apk/wain-qa-29ba9dac-release.apk
```

Seed:

```text
qa_seed_2026-05-18T17-44-27-080Z
```

Wallet screen evidence:

```text
.tmp/screen-p7-wallet-02-wallet-screen.png
```

Verified visible summary for `venue_qa_01`:

```text
الرصيد المتوفر: 500.00 ILS
إجمالي الرصيد المضاف: 1599.00 ILS
منه شحن معتمد: 0.00 ILS
قيد المراجعة: 120.00 ILS
إجمالي الصرف: 1099.00 ILS
```

Verifier results after the visual wallet summary smoke:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=26 fail=0 warn=0
```

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
- `qa-final-2026-05-15-p7` clarifies wallet summary totals by separating total balance added, approved top-ups, and pending review top-ups.
