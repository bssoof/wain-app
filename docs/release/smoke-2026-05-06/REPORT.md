# Admin Web Console Smoke 2026-05-06

## 1. Environment Summary

- Status: EXECUTED locally with Playwright against the Next dev server.
- Branch: main
- Expected HEAD: 79bd7be8
- Actual HEAD: 79bd7be8
- Base URL: http://localhost:3010 (`npm run dev` uses port 3010 in this repo).
- Node: v22.22.2
- Vitest baseline: PASS, 117 files / 691 tests. See [vitest-baseline.log](vitest-baseline.log).
- Production build: PASS. See [build.log](build.log).
- `.next` present: yes; size: 147.29 MB. See [build-artifacts.txt](build-artifacts.txt).
- Playwright: available and used. Browser MCP was available, but Playwright was used because this smoke needed persistent screenshot/log artifacts.
- Worktree caveat: dirty Flutter source files are present outside `admin_web_console`; the smoke run did not edit app source files and only produced artifacts under this report directory.
- Session injection: `x-wain-admin-session` header with `WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION=1`; session shape verified from `lib/auth/session-server.ts`.

## 2. Per-Route Results

- Normalized render/guard result: 134/134 route-role-viewport visits rendered correctly or reached the expected access-denied page.
- Strict smoke caveats: 180 CSP report-only console errors across 134 rows; 94 rows timed out waiting for `networkidle` on the dev server; network 4xx/5xx count: 0.
- Row statuses below use `WARN` when the route rendered correctly but strict console/`networkidle` criteria were not clean.

| Route | Role | Viewport | Status | Console errors | Network 4xx/5xx | Screenshot | Notes |
| --- | --- | --- | --- | ---: | ---: | --- | --- |
| /admin | super_admin | desktop | WARN | 2 | 0 | [shot](super_admin/admin-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | super_admin | mobile | WARN | 2 | 0 | [shot](super_admin/admin-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | finance_admin | desktop | WARN | 2 | 0 | [shot](finance_admin/admin-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | finance_admin | mobile | WARN | 2 | 0 | [shot](finance_admin/admin-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | content_admin | desktop | WARN | 2 | 0 | [shot](content_admin/admin-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | content_admin | mobile | WARN | 2 | 0 | [shot](content_admin/admin-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/admin-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/admin-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | ops_viewer | desktop | WARN | 2 | 0 | [shot](ops_viewer/admin-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin | ops_viewer | mobile | WARN | 2 | 0 | [shot](ops_viewer/admin-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/dashboard-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/dashboard-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/dashboard-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/dashboard-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/dashboard-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/dashboard-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | support_admin | desktop | WARN | 1 | 0 | [shot](support_admin/dashboard-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | support_admin | mobile | WARN | 1 | 0 | [shot](support_admin/dashboard-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/dashboard-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/dashboard | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/dashboard-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/topups | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/topups-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/topups | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/topups-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/topups | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/topups-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/topups | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/topups-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/topups | content_admin | desktop | WARN | 2 | 0 | [shot](content_admin/topups-desktop.png) | access-denied observed; CSP console error |
| /admin/topups | content_admin | mobile | WARN | 2 | 0 | [shot](content_admin/topups-mobile.png) | access-denied observed; CSP console error |
| /admin/topups | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/topups-desktop.png) | access-denied observed; CSP console error |
| /admin/topups | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/topups-mobile.png) | access-denied observed; CSP console error |
| /admin/topups | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/topups-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/topups | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/topups-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/venues-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/venues-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/venues-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/venues-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/venues-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/venues-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | support_admin | desktop | WARN | 1 | 0 | [shot](support_admin/venues-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | support_admin | mobile | WARN | 1 | 0 | [shot](support_admin/venues-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/venues-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/venues-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/reviews | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/reviews-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/reviews | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/reviews-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/reviews | finance_admin | desktop | WARN | 2 | 0 | [shot](finance_admin/reviews-desktop.png) | access-denied observed; CSP console error |
| /admin/content/reviews | finance_admin | mobile | WARN | 2 | 0 | [shot](finance_admin/reviews-mobile.png) | access-denied observed; CSP console error |
| /admin/content/reviews | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/reviews-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/reviews | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/reviews-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/reviews | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/reviews-desktop.png) | access-denied observed; CSP console error |
| /admin/content/reviews | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/reviews-mobile.png) | access-denied observed; CSP console error |
| /admin/content/reviews | ops_viewer | desktop | WARN | 2 | 0 | [shot](ops_viewer/reviews-desktop.png) | access-denied observed; CSP console error |
| /admin/content/reviews | ops_viewer | mobile | WARN | 2 | 0 | [shot](ops_viewer/reviews-mobile.png) | access-denied observed; CSP console error |
| /admin/config | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/config-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/config | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/config-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/config | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/config-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/config | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/config-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/config | content_admin | desktop | WARN | 2 | 0 | [shot](content_admin/config-desktop.png) | access-denied observed; CSP console error |
| /admin/config | content_admin | mobile | WARN | 2 | 0 | [shot](content_admin/config-mobile.png) | access-denied observed; CSP console error |
| /admin/config | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/config-desktop.png) | access-denied observed; CSP console error |
| /admin/config | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/config-mobile.png) | access-denied observed; CSP console error |
| /admin/config | ops_viewer | desktop | WARN | 2 | 0 | [shot](ops_viewer/config-desktop.png) | access-denied observed; CSP console error |
| /admin/config | ops_viewer | mobile | WARN | 2 | 0 | [shot](ops_viewer/config-mobile.png) | access-denied observed; CSP console error |
| /admin/sign-in | unauthenticated | desktop | WARN | 1 | 0 | [shot](unauthenticated/sign-in-desktop.png) | public route rendered; CSP console error |
| /admin/sign-in | unauthenticated | mobile | WARN | 1 | 0 | [shot](unauthenticated/sign-in-mobile.png) | public route rendered; CSP console error |
| /admin/access-denied?route=dashboard | unauthenticated | desktop | WARN | 1 | 0 | [shot](unauthenticated/access-denied-desktop.png) | public route rendered; CSP console error |
| /admin/access-denied?route=dashboard | unauthenticated | mobile | WARN | 1 | 0 | [shot](unauthenticated/access-denied-mobile.png) | public route rendered; CSP console error |
| /admin/wallet-audit | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/wallet-audit-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/wallet-audit-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/wallet-audit-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/wallet-audit-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | content_admin | desktop | WARN | 2 | 0 | [shot](content_admin/wallet-audit-desktop.png) | access-denied observed; CSP console error |
| /admin/wallet-audit | content_admin | mobile | WARN | 2 | 0 | [shot](content_admin/wallet-audit-mobile.png) | access-denied observed; CSP console error |
| /admin/wallet-audit | support_admin | desktop | WARN | 1 | 0 | [shot](support_admin/wallet-audit-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | support_admin | mobile | WARN | 1 | 0 | [shot](support_admin/wallet-audit-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/wallet-audit-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/wallet-audit | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/wallet-audit-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/reversals | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/reversals-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/reversals | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/reversals-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/reversals | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/reversals-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/reversals | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/reversals-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/reversals | content_admin | desktop | WARN | 2 | 0 | [shot](content_admin/reversals-desktop.png) | access-denied observed; CSP console error |
| /admin/reversals | content_admin | mobile | WARN | 2 | 0 | [shot](content_admin/reversals-mobile.png) | access-denied observed; CSP console error |
| /admin/reversals | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/reversals-desktop.png) | access-denied observed; CSP console error |
| /admin/reversals | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/reversals-mobile.png) | access-denied observed; CSP console error |
| /admin/reversals | ops_viewer | desktop | WARN | 2 | 0 | [shot](ops_viewer/reversals-desktop.png) | access-denied observed; CSP console error |
| /admin/reversals | ops_viewer | mobile | WARN | 2 | 0 | [shot](ops_viewer/reversals-mobile.png) | access-denied observed; CSP console error |
| /admin/readiness | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/readiness-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/readiness-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/readiness-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/readiness-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/readiness-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/readiness-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | support_admin | desktop | WARN | 1 | 0 | [shot](support_admin/readiness-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | support_admin | mobile | WARN | 1 | 0 | [shot](support_admin/readiness-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/readiness-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/readiness | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/readiness-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/venue-orjuwan-01-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/venue-orjuwan-01-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/venue-orjuwan-01-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/venue-orjuwan-01-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/venue-orjuwan-01-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/venue-orjuwan-01-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | support_admin | desktop | WARN | 1 | 0 | [shot](support_admin/venue-orjuwan-01-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | support_admin | mobile | WARN | 1 | 0 | [shot](support_admin/venue-orjuwan-01-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/venue-orjuwan-01-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/venues/orjuwan_01 | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/venue-orjuwan-01-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/media-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/media-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | finance_admin | desktop | WARN | 1 | 0 | [shot](finance_admin/media-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | finance_admin | mobile | WARN | 1 | 0 | [shot](finance_admin/media-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/media-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/media-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | support_admin | desktop | WARN | 1 | 0 | [shot](support_admin/media-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | support_admin | mobile | WARN | 1 | 0 | [shot](support_admin/media-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | ops_viewer | desktop | WARN | 1 | 0 | [shot](ops_viewer/media-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/media | ops_viewer | mobile | WARN | 1 | 0 | [shot](ops_viewer/media-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/offers | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/offers-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/offers | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/offers-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/offers | finance_admin | desktop | WARN | 2 | 0 | [shot](finance_admin/offers-desktop.png) | access-denied observed; CSP console error |
| /admin/content/offers | finance_admin | mobile | WARN | 2 | 0 | [shot](finance_admin/offers-mobile.png) | access-denied observed; CSP console error |
| /admin/content/offers | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/offers-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/offers | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/offers-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/offers | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/offers-desktop.png) | access-denied observed; CSP console error |
| /admin/content/offers | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/offers-mobile.png) | access-denied observed; CSP console error |
| /admin/content/offers | ops_viewer | desktop | WARN | 2 | 0 | [shot](ops_viewer/offers-desktop.png) | access-denied observed; CSP console error |
| /admin/content/offers | ops_viewer | mobile | WARN | 2 | 0 | [shot](ops_viewer/offers-mobile.png) | access-denied observed; CSP console error |
| /admin/content/stories | super_admin | desktop | WARN | 1 | 0 | [shot](super_admin/stories-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/stories | super_admin | mobile | WARN | 1 | 0 | [shot](super_admin/stories-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/stories | finance_admin | desktop | WARN | 2 | 0 | [shot](finance_admin/stories-desktop.png) | access-denied observed; CSP console error |
| /admin/content/stories | finance_admin | mobile | WARN | 2 | 0 | [shot](finance_admin/stories-mobile.png) | access-denied observed; CSP console error |
| /admin/content/stories | content_admin | desktop | WARN | 1 | 0 | [shot](content_admin/stories-desktop.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/stories | content_admin | mobile | WARN | 1 | 0 | [shot](content_admin/stories-mobile.png) | protected shell rendered; CSP console error; networkidle timeout |
| /admin/content/stories | support_admin | desktop | WARN | 2 | 0 | [shot](support_admin/stories-desktop.png) | access-denied observed; CSP console error |
| /admin/content/stories | support_admin | mobile | WARN | 2 | 0 | [shot](support_admin/stories-mobile.png) | access-denied observed; CSP console error |
| /admin/content/stories | ops_viewer | desktop | WARN | 2 | 0 | [shot](ops_viewer/stories-desktop.png) | access-denied observed; CSP console error |
| /admin/content/stories | ops_viewer | mobile | WARN | 2 | 0 | [shot](ops_viewer/stories-mobile.png) | access-denied observed; CSP console error |

## 3. Per-Component Verification

- PageHeader: present on 15/15 routes.
- FilterToolbar: present on 7 routes and functional on 23/23 allowed desktop checks: /admin/topups, /admin/venues, /admin/content/reviews, /admin/wallet-audit, /admin/media, /admin/content/offers, /admin/content/stories.
- DataTable enhancements / table or empty/unavailable state: observed on 11 routes across 37 allowed desktop checks: /admin/topups, /admin/venues, /admin/content/reviews, /admin/config, /admin/wallet-audit, /admin/reversals, /admin/readiness, /admin/venues/orjuwan_01, /admin/media, /admin/content/offers, /admin/content/stories.
- ConfirmDialog: opened with ARIA attrs on 5 allowed role-action checks across 3 routes: /admin/content/reviews, /admin/config, /admin/content/offers. Some fixture states had no enabled destructive action, so reversals/stories were not triggerable in this run.
- Toast aria-live: present on 47/47 allowed desktop checks and on all a11y spot-check routes.
- EmptyState: observed where fixture/filter state exposed it; forced zero-result EmptyState was not independently produced for every filtered route.
- SkeletonBlock: visible after settled navigation on 0/47 allowed desktop checks; most local fixture data resolved before screenshot time.

## 4. Mobile Viewport Results

- Mobile viewport checks: 67/67 rendered/guarded correctly at 375x812.
- Mobile rows with strict warnings: 67/67, caused by the same CSP console message and/or dev-server `networkidle` timeout.
- Sidebar drawer mode: protected mobile routes exposed the mobile menu trigger when access was allowed.
- DataTable horizontal scroll: 7/7 checked mobile data routes had horizontal overflow in a `data-table-scroll table-scroll` container. See [mobile-datatable-scroll.json](mobile-datatable-scroll.json).

## 5. A11y Spot-Check Findings

| Route | Focus-visible observed | Escape closed dialog | aria-live present | Focus order sample |
| --- | --- | --- | --- | --- |
| /admin/dashboard | True | n/a | True | الماليةإخفاء -> نظرة عامة -> طلبات الشحن -> سجل المحفظة -> طلبات عكس العمليات -> حالة النظام -> المحتوىإخفاء -> الجهات -> الصور والملفات -> العروض |
| /admin/topups | True | n/a | True | الماليةإخفاء -> نظرة عامة -> طلبات الشحن -> سجل المحفظة -> طلبات عكس العمليات -> حالة النظام -> المحتوىإخفاء -> الجهات -> الصور والملفات -> العروض |
| /admin/config | True | True | True | الماليةإخفاء -> نظرة عامة -> طلبات الشحن -> سجل المحفظة -> طلبات عكس العمليات -> حالة النظام -> المحتوىإخفاء -> الجهات -> الصور والملفات -> العروض |

Automated axe-core was skipped because it was not locally preinstalled and this smoke did not install or fetch network-side scripts.

## 6. Performance Numbers Vs Bundle Estimates

These numbers came from the local Next dev server, so transferred bytes include dev/HMR overhead and are not a production byte-for-byte comparison. The requested >2x flag is still reported.

| Route | DOMContentLoaded ms | Networkidle ms | Transferred | First Load JS estimate | FCP ms | Flag |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| /admin/dashboard | 172 | 15190 | 2383.3 kB | 94.2 kB | 184 | FLAG |
| /admin/topups | 1166 | 16171 | 3365.6 kB | 150 kB | 804 | FLAG |
| /admin/wallet-audit | 1527 | 16531 | 3274 kB | 149 kB | 2608 | FLAG |
| /admin/reversals | 872 | 15875 | 3225.9 kB | 143 kB | 876 | FLAG |
| /admin/venues | 1498 | 16504 | 3404.8 kB | 165 kB | 912 | FLAG |
| /admin/content/reviews | 1258 | 16264 | 2560.9 kB | 107 kB | 896 | FLAG |
| /admin/config | 1475 | 16482 | 2642.9 kB | 107 kB | 1140 | FLAG |

## 7. Visual Regression Pairs

Intentional redesign changes were not auto-judged by pixel diff. Side-by-side pairs are available for manual review:

- [01_admin_index_vs_current.png](visual-pairs/01_admin_index_vs_current.png)
- [02_sign_in_vs_current.png](visual-pairs/02_sign_in_vs_current.png)
- [03_access_denied_vs_current.png](visual-pairs/03_access_denied_vs_current.png)
- [04_dashboard_vs_current.png](visual-pairs/04_dashboard_vs_current.png)
- [05_topups_vs_current.png](visual-pairs/05_topups_vs_current.png)
- [06_wallet_audit_vs_current.png](visual-pairs/06_wallet_audit_vs_current.png)
- [07_reversals_vs_current.png](visual-pairs/07_reversals_vs_current.png)
- [08_readiness_vs_current.png](visual-pairs/08_readiness_vs_current.png)
- [09_venues_directory_vs_current.png](visual-pairs/09_venues_directory_vs_current.png)
- [10_venues_workspace_vs_current.png](visual-pairs/10_venues_workspace_vs_current.png)
- [11_media_vs_current.png](visual-pairs/11_media_vs_current.png)
- [12_content_offers_vs_current.png](visual-pairs/12_content_offers_vs_current.png)
- [13_content_stories_vs_current.png](visual-pairs/13_content_stories_vs_current.png)
- [14_content_reviews_vs_current.png](visual-pairs/14_content_reviews_vs_current.png)
- [15_config_vs_current.png](visual-pairs/15_config_vs_current.png)

## 8. Issues Found

- Blocker: none found in local render/build/test execution.
- Major: Browser console is not clean. Chrome logs `The Content Security Policy directive 'upgrade-insecure-requests' is ignored when delivered in a report-only policy.` on every route/viewport (180 occurrences).
- Major/caveat: `networkidle` did not settle on 94/134 visits. This is consistent with Next dev/HMR behavior, but it means the strict requested `networkidle` criterion was not clean.
- Major/caveat: RBAC behavior was validated against current `ROUTE_ROLE_PERMISSIONS`. Current code allows `finance_admin` on `/admin/config`; the prompt listed config as `super_admin only`, so confirm whether the code or release expectation is authoritative.
- Minor: All measured performance rows exceed 2x the First Load JS estimate under the dev server. Treat as local-dev overhead unless reproduced in a production-auth smoke.
- Cosmetic: no screenshot-only cosmetic blocker was auto-detected; visual pairs require manual review.

## 9. Deploy Recommendation

YELLOW: deploy with caveats only after accepting the CSP console warning and confirming the `/admin/config` finance-admin RBAC expectation. Tests, build, route rendering, mobile layout, and access-denied routing passed locally; strict console/networkidle/perf criteria were not fully clean.

## 10. Rollback Plan

```powershell
git revert 79bd7be8 9e889f00
firebase deploy --only hosting
```
