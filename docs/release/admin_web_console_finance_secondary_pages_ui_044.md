# UI-044 - Finance Secondary Pages UI Refresh

Date: 2026-04-18
Scope: `/admin/readiness`, `/admin/reversals`, `/admin/wallet-audit`, shared admin header display
Decision impact: presentation-only UI improvement. RBAC, loaders, command keys, command payloads, route paths, and finance data contracts are unchanged.

## Request

Continue the page-by-page UI quality pass after the dashboard, keeping the admin console Arabic-first, easy to understand, organized, and modern without harming existing behavior.

## Decision

Use a small finance-secondary slice:

- Improve `/admin/readiness` because it still exposed backend-oriented readiness text and raw English fixture copy.
- Improve `/admin/reversals` because it is a command-only page and needed clearer hierarchy.
- Polish `/admin/wallet-audit` visible local/emulator wording so the page reads in Arabic while keeping internal identifiers available for command and export flows.
- Localize the shared development display name `Local Admin` in the header to `مسؤول محلي`.

## Changes

- Reworked the readiness report into a health summary:
  - Arabic status summary derived from the report status and check counts.
  - Count blocks for healthy checks, checks needing follow-up, and checks needing handling.
  - Known readiness checks now display Arabic labels/details instead of upstream English text.
- Reworked the readiness command panel:
  - Clearer action copy.
  - Runtime badge stays visible.
  - Removed visible idempotency wording from the operator surface.
- Refined the reversal approval panel:
  - Clearer instruction copy.
  - Arabic placeholder for the request id.
  - Success outcome is split into readable lines.
- Refined wallet audit visible text:
  - Local/emulator actor names and operation descriptions are rendered as Arabic operator copy.
  - Internal ids are still used by command payloads and CSV export.
- Added supporting CSS for finance action panels, finance health cards, Arabic inputs, responsive readiness rows, and reduced-motion safety.
- Added tests for Arabic readiness copy, wallet audit visible copy, and localized admin header display name.

## Files Updated

- `admin_web_console/components/finance/readiness-panel.tsx`
- `admin_web_console/components/finance/reversal-approval-panel.tsx`
- `admin_web_console/components/finance/wallet-audit-table.tsx`
- `admin_web_console/components/finance/finance-read-states.test.tsx`
- `admin_web_console/components/finance/finance-surfaces.test.tsx`
- `admin_web_console/components/admin/admin-header.tsx`
- `admin_web_console/components/admin/admin-header.test.tsx`
- `admin_web_console/lib/admin/admin-localization.ts`
- `admin_web_console/app/globals.css`
- `docs/release/admin_web_console_finance_secondary_pages_ui_044.md`
- `docs/release/admin_web_console_ui_improvement_master_plan.md`
- `docs/release/admin_web_console_progress_tracker.md`

## Validation

- `npx vitest run components/admin/admin-header.test.tsx components/finance/finance-surfaces.test.tsx components/finance/finance-read-states.test.tsx`
  - `3` files passed
  - `21` tests passed
- `npx tsc --noEmit --pretty false`
  - passed
- `npm run build`
  - passed
- Localhost restarted on port `3010`.
- HTTP/browser checks:
  - `/admin/readiness` returned `200`
  - `/admin/reversals` returned `200`
  - `/admin/wallet-audit` returned `200`
- Playwright browser check:
  - no Next.js error overlay
  - no console errors
  - no page errors
  - no visible `Local Admin`, `Admin operator`, `Core wallet services`, `Ledger stream health`, or `Approved top-up request` text on the checked pages
  - screenshots:
    - `.tmp/admin-readiness-ui-044.png`
    - `.tmp/admin-reversals-ui-044.png`
    - `.tmp/admin-wallet-audit-ui-044.png`

## Outcome

UI-044 is closed as a finance-secondary UI refresh. The affected pages are easier to scan in Arabic and keep their existing authorization, loader, route, command, and data contracts intact.

## Next Step

Continue the page-by-page UI quality pass with `/admin/config`, because it is the remaining dense command page after the finance secondary pages.
