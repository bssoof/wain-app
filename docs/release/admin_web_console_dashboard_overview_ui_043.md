# UI-043 - Dashboard Overview UI Refresh

Date: 2026-04-18
Scope: `/admin/dashboard`
Decision impact: improves the overview page UI without changing RBAC, loaders, route contracts, or dashboard data models.

## Request

Start with the overview page and raise the UI quality without negatively affecting existing stability or behavior.

## Decision

Treat the dashboard improvement as a presentation-only pass:

- Keep `loadDashboardSummary` unchanged.
- Keep route guard behavior unchanged.
- Keep existing widget states (`success`, `stale`, `empty`, `unavailable`) unchanged.
- Improve visual hierarchy, scan speed, and Arabic wording using the same data already provided by the loader.

## Changes

- Added a fast summary strip above the widget grid:
  - requests needing a decision
  - content waiting for review
  - ready venues
  - wallet status
- Reorganized dashboard widget rendering into module-level render helpers to reduce inline JSX density.
- Improved Arabic wording:
  - `محتوى ينتظر المراجعة`
  - `صحة المحفظة`
  - `فحوصات فاشلة`
  - `فحوصات تحتاج متابعة`
  - `عرض تقرير الحالة الكامل`
- Formatted top-up amounts with the shared currency formatter instead of raw amount/currency text.
- Added dashboard-specific CSS for the overview strip, preview lists, metric blocks, and responsive behavior.
- Updated dashboard tests to assert the new summary strip instead of assuming repeated numeric values appear only once.

## Files Updated

- `admin_web_console/components/dashboard/operational-dashboard-shell.tsx`
- `admin_web_console/components/dashboard/operational-dashboard-shell.test.tsx`
- `admin_web_console/app/globals.css`
- `docs/release/admin_web_console_dashboard_overview_ui_043.md`
- `docs/release/admin_web_console_ui_improvement_master_plan.md`
- `docs/release/admin_web_console_progress_tracker.md`

## Validation

- `npx vitest run components/dashboard/operational-dashboard-shell.test.tsx lib/dashboard/dashboard-loader.test.ts`
  - `2` files passed
  - `8` tests passed
- `npx tsc --noEmit --pretty false`
  - passed
- `npm run build`
  - passed
- Localhost restarted on port `3010`.
- HTTP check:
  - `/admin/dashboard` returned `200`.
- Playwright browser check:
  - no Next.js error overlay
  - no console errors
  - no page errors
  - dashboard widget grid rendered
  - screenshot: `.tmp/admin-dashboard-ui-043.png`

## Outcome

UI-043 is closed as a dashboard-only UI refresh. The page now has stronger hierarchy and faster scanning while preserving loader behavior, RBAC, command contracts, and route stability.

## Next Step

Continue the same page-by-page UI quality pass with `/admin/wallet-audit`, because it is the next finance-heavy page after the dashboard and top-up queue.
