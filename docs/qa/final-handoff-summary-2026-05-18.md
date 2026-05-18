# Final Handoff Summary - 2026-05-18

## Release Point

- Branch: `main`
- Final local tag: `qa-final-2026-05-15-p9`
- Final local commit: documentation-only summary commit on top of `qa-final-2026-05-15-p8`
- Code-bearing wallet summary fix: `29ba9dac fix(merchant): clarify wallet summary totals`
- Remote push: not performed.

## APK

```text
build/app/outputs/flutter-apk/wain-qa-3e61b8b6-release.apk
```

- Build mode: release APK
- Dart defines:
  - `WAIN_USE_FIREBASE_EMULATORS=true`
  - `WAIN_FIREBASE_EMULATOR_HOST=10.0.2.2`
- Size: `93.90 MB`

## Emulator QA Seed

```text
Project: wain-d2e28
Mode: emulator
Seed run: qa_seed_2026-05-18T17-44-27-080Z
Accounts: 7 QA accounts
Venues: venue_qa_01, venue_qa_02
```

Seed command:

```powershell
node scripts/qa-seed.mjs --project=wain-d2e28 --reset --out=.tmp/qa-seed-output.json
```

## QA Credentials

Stored in:

```text
.tmp/qa-seed-output.json
```

Key accounts:

```text
merchant.qa.01@wain.test / MerchantQA!2026 / venue_qa_01
merchant.qa.02@wain.test / MerchantQA!2026 / venue_qa_02
finance.admin.qa.01@wain.test / AdminQA!2026
super.admin.qa.01@wain.test / AdminQA!2026
```

These are QA seed credentials for emulator/staging workflows only.

## Completed Smoke Coverage

- Consumer discovery flow opened seeded QA venues.
- Merchant login succeeded through Firebase Auth emulator.
- Merchant login routed to merchant dashboard.
- Merchant wallet screen opened.
- Merchant top-up request was created from the Flutter app.
- Merchant reversal request was created from the Flutter app.
- Admin approved the app-created top-up request.
- Finance admin reviewed the app-created reversal request.
- Super admin completed second approval for the reversal.
- Merchant wallet summary was visually verified after the p7 UI fix.
- Finance verifier passed.
- Audit verifier passed.

## Latest Wallet Summary Verification

Screenshot:

```text
.tmp/screen-p7-wallet-02-wallet-screen.png
```

Observed wallet summary for `venue_qa_01`:

```text
الرصيد المتوفر: 500.00 ILS
إجمالي الرصيد المضاف: 1599.00 ILS
منه شحن معتمد: 0.00 ILS
قيد المراجعة: 120.00 ILS
إجمالي الصرف: 1099.00 ILS
```

This confirms the wallet UI no longer implies that `0.00` approved top-ups contradicts the available balance. The available balance is ledger-derived; pending top-ups are shown separately.

## Verifier Results

After latest wallet summary smoke on fresh seed:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=26 fail=0 warn=0
```

After previous full financial flow:

```text
QA finance verifier summary: wallets=2 fail=0 warn=0
QA audit verifier summary: audit_events=34 fail=0 warn=0
```

The audit event count differs because the latest smoke used a fresh seed, while the full financial flow included app-created top-up/reversal and approval events.

## Local Workspace Notes

- `.vscode/settings.json` personal `cmake.sourceDirectory` change was stashed, not committed:

```text
stash@{0}: On main: local vscode cmake sourceDirectory 2026-05-18
```

- Keep this work local unless an explicit push/release instruction is given.
- No production Firebase project was touched; QA data was seeded and verified through local Firebase emulators.
