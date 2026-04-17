# Admin Web Console UI Improvement Master Plan

Last updated: 2026-04-17
Owner: Admin Web Console stream
Status: In progress

## 1. Purpose
This document is the single source of truth for the full UI improvement plan across the admin web console.
From this point onward, every UI action, decision, change, test, and validation step must be logged in this file.

## 2. Scope
Covered route groups:
- Public: `/admin/sign-in`, `/admin/access-denied`
- Protected shell: `/admin`, shared `admin-shell`, `admin-header`, `admin-sidebar`
- Protected pages:
  - `/admin/dashboard`
  - `/admin/topups`
  - `/admin/wallet-audit`
  - `/admin/reversals`
  - `/admin/readiness`
  - `/admin/venues`
  - `/admin/venues/[venueId]`
  - `/admin/media`
  - `/admin/content/offers`
  - `/admin/content/stories`
  - `/admin/content/reviews`
  - `/admin/config`

## 3. Working Rule (Mandatory)
For every UI-related task, update this file with:
- What was requested
- What was changed
- Files touched
- Validation performed
- Result and next step

No UI task is considered complete unless it is recorded in this file.

### 3.1 Document Model (Normative vs Execution Log)
To keep this file maintainable while remaining the single source of truth:
- Normative spec sections: 1 through 17.
- Execution logging section: 18 only.

Rule:
- Do not place daily execution notes inside normative sections.
- All daily updates must use section 18 template and append to section 7 Change Log.

## 4. Delivery Phases

### Phase A: Audit and Baseline
Objective: capture current UI quality and prioritize the biggest UX impact items.
Deliverables:
- Route-by-route UI audit matrix
- Baseline screenshots and notes
- Priority list (P0/P1/P2)

### Phase B: Foundation and Tokens
Objective: unify styling primitives and reusable visual language.
Deliverables:
- Color, spacing, typography, radius, border, shadow token review
- Shared state styles for loading, empty, stale, unavailable, error
- Updated global style conventions
- Missing token set implementation (explicit list in section 11)
- Next.js route-level loading and error UX contract (`loading.tsx`, `error.tsx`) for key admin routes

### Phase C: Shell and Navigation
Objective: improve clarity and consistency in cross-page navigation.
Deliverables:
- Sidebar hierarchy improvements
- Header information architecture cleanup
- Better active route and context cues
- Mobile/tablet responsive shell behavior
- Sidebar grouping spec implementation (explicit target groups in section 13)

### Phase D: Shared Pattern Unification
Objective: standardize repeated UI patterns across modules.
Deliverables:
- Unified data table pattern
- Unified filter toolbar pattern
- Unified read-state banners
- Unified command/action button semantics
- Unified dialogs and form layout pattern
- Shared React component contract implementation (explicit components in section 10)

### Phase E: Module-by-Module Upgrades
Objective: apply the shared system to each page group.
Target modules:
- Dashboard
- Finance (topups, wallet-audit, reversals, readiness)
- Venues and venue workspace
- Media center
- Content moderation (offers, stories, reviews)
- Config governance

### Phase F: Accessibility and Responsive Hardening
Objective: ensure practical usability and compliance readiness.
Deliverables:
- Keyboard navigation pass
- Focus-state and contrast pass
- RTL and responsive consistency pass

### Phase G: Final Validation and Release Readiness
Objective: verify no regressions and confirm deploy readiness.
Deliverables:
- Targeted UI and behavior validation
- Build and test verification
- Final release notes

### Cross-Stream Track: Warmup and Navigation Load Impact
Objective: ensure admin-shell warmup/prefetch improves UX without overloading SSR routes.
Deliverables:
- Warmup request profile audit (cold and warm)
- Route prefetch concurrency and order review
- Guardrails and acceptance thresholds (section 14)

### 4.1 Cross-Cutting Gates (Apply in Every Phase)
These are mandatory acceptance gates in all phases, not only in final hardening:
- Accessibility gate: keyboard operability, visible focus, no keyboard trap, semantic labels.
- Responsive gate: no layout break on narrow viewports; no control overlap.
- RTL gate: use logical properties and no left/right-only regressions.
- Route-state gate: loading, error, not-found, access-denied behavior is explicit.

### 4.2 Phase Exit Criteria (Mandatory)

| Phase | Exit Criteria |
|---|---|
| A | Audit matrix complete for all in-scope routes, baseline screenshots captured, top risks ranked |
| B | Token schema approved and implemented baseline, route state contract approved, loading/error skeleton baseline implemented |
| C | Shell IA and sidebar grouping implemented, cross-device navigation validated |
| D | Shared component contracts implemented and adopted in pilot routes |
| E | Module migrations completed with no contract bypasses |
| F | Accessibility/RTL/responsive gates pass for all migrated routes |
| G | Build/tests pass, KPI thresholds met, release checklist complete |

## 5. Priority Model
- P0: cross-cutting shell/navigation/state issues that affect all pages
- P1: module-level clarity and consistency issues
- P2: polish and micro-interaction improvements

## 6. Success Metrics

| Metric | Baseline | Target | Source |
|---|---|---|---|
| LCP p75 (critical admin routes) | To be captured in Phase A | <= 2.5s | Web vitals capture |
| INP p75 | To be captured in Phase A | <= 200ms | Web vitals capture |
| CLS p75 | To be captured in Phase A | <= 0.10 | Web vitals capture |
| Route transition blank-screen incidents | To be captured in Phase A | 0 on covered routes | Route state validation |
| Accessibility critical issues | To be captured in Phase A | 0 | A11y audit runs |
| UI consistency checklist score | To be captured in Phase A | >= 85% | Route audit matrix |

Instrumentation requirements:
- Use `useReportWebVitals` for client vitals stream.
- Use `instrumentation-client.js` for route-level telemetry hooks.
- Track route transition start/end and failure state events.

## 7. Change Log

| Date | ID | Request | Action Taken | Files | Validation | Result | Next |
|---|---|---|---|---|---|---|---|
| 2026-04-16 | UI-000 | Create one master plan file and log all UI work in it | Created this master plan document and enabled mandatory logging workflow | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | File created successfully | Done | Start Phase A audit entries |
| 2026-04-16 | UI-001 | Refine plan with concrete technical specs from code review | Added explicit shared component names, missing token list, sidebar grouping spec, Next.js loading/error deliverables, and warmup evaluation track | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Manual review against current codebase findings | Done | Execute Phase A with new constraints |
| 2026-04-16 | UI-002 | Deep-research alignment to turn plan into operating document | Added cross-cutting gates, phase exits, measurable KPI contract, component behavior contracts, expanded route-state coverage, warmup policy, ownership and dependency mapping | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Manual reconciliation against code-driven recommendations | Done | Start Phase A with new gate model |
| 2026-04-16 | UI-003 | Execute first operational step from new gate model | Added Phase A route audit matrix baseline (all in-scope routes), quantified current route-state gaps, and linked dependencies for next implementation wave | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Manual verification against current route files, layouts, sidebar, and route map | Done | Start UI-A02 and UI-B04 from baseline |
| 2026-04-16 | UI-004 | Approve route-state contract as the next execution step after baseline audit | Added approved route-state matrix with state semantics, route coverage requirements, dependency mapping, and risk controls for safe rollout | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Manual verification against route guards, current route surfaces, and admin segment file coverage | Done | Start UI-B03 implementation and keep UI-A02 screenshot capture in parallel |
| 2026-04-16 | UI-005 | Execute first safe implementation slice for UI-B03 | Added protected admin segment `loading.tsx` and `error.tsx` baseline to establish route-level fallback behavior without changing RBAC/data contracts | `wain_app/admin_web_console/app/(protected)/admin/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/error.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Local build validation for admin web console | Done | Continue UI-B03 with route-specific overrides for high-latency pages |
| 2026-04-16 | UI-006 | Execute second safe implementation slice for UI-B03 | Added route-specific `loading.tsx` overrides for high-priority routes (`dashboard`, `media`, `content/offers`, `content/stories`) while preserving segment-level error boundary and RBAC behavior | `wain_app/admin_web_console/app/(protected)/admin/dashboard/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/media/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/content/offers/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/content/stories/loading.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Local build validation for admin web console | Done | Continue UI-B03 route-specific coverage for remaining routes |
| 2026-04-16 | UI-007 | Execute third safe implementation slice for UI-B03 | Added route-specific `loading.tsx` overrides for remaining critical protected routes (`topups`, `wallet-audit`, `readiness`, `reversals`, `venues`, `venues/[venueId]`, `content/reviews`, `config`) with no RBAC/data contract changes | `wain_app/admin_web_console/app/(protected)/admin/topups/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/wallet-audit/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/readiness/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/reversals/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/venues/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/content/reviews/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/config/loading.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Local build validation for admin web console | Done | Assess route-specific `error.tsx` need and close UI-B03 |
| 2026-04-16 | UI-008 | Execute fourth safe implementation slice for UI-B03 | Added targeted route-specific `error.tsx` boundaries for high-risk routes (`topups`, `config`, `venues/[venueId]`) while keeping segment-level error fallback as default | `wain_app/admin_web_console/app/(protected)/admin/topups/error.tsx`, `wain_app/admin_web_console/app/(protected)/admin/config/error.tsx`, `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/error.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Local build validation for admin web console | Done | Evaluate if remaining routes need custom `error.tsx` or keep segment-level fallback |
| 2026-04-16 | UI-009 | Close UI-B03 with explicit error-boundary decision pass | Documented route-by-route decision for remaining protected routes to keep segment-level `app/(protected)/admin/error.tsx` as default unless route-specific recovery need is proven; marked UI-B03 complete | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Decision pass verified against implemented loading/error coverage and prior green builds | Done | Move to UI-A02 evidence capture and UI-B05 table-mode decision |
| 2026-04-16 | UI-010 | Close UI-B05 with DataTable mode decision pass | Documented route-by-route DataTable mode decision and adoption gates; approved `display-table` as current baseline and deferred `interactive-grid` to explicit gated future cases | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Decision pass verified against current table implementations across finance, venues, media, content, reviews, and config | Done | Move to UI-A02 evidence capture and UI-B01 token alignment review |
| 2026-04-16 | UI-011 | Execute and close UI-B01 token alignment review | Audited current global token surface, quantified hardcoded style hotspots, identified missing token families, and defined a low-risk migration sequence for UI-B02 without visual behavior changes | `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Manual verification against current stylesheet plus search-based token/literal checks | Done | Start UI-B02 token introduction and first-pass alias migration |
| 2026-04-16 | UI-012 | Execute UI-B02 batch 1 token introduction and alias migration | Added missing token families in `:root` and migrated first high-repeat literals (status colors, radius, shadow, z-layer, selected line-height) to semantic token aliases in global admin styles | `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Admin web console production build passed (`npm run build`) | In progress | Continue UI-B02 batch 2 (spacing/focus/motion adoption and residual literal cleanup) |
| 2026-04-16 | UI-013 | Execute UI-B02 batch 2 spacing/focus/motion adoption and residual cleanup | Applied spacing and control-density token aliases across interactive admin controls, introduced unified low-noise `:focus-visible` treatment, and adopted motion-token transitions while preserving existing route and RBAC behavior | `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | CSS diagnostics clean; admin web console production build passed (`npm run build`) | In progress | Run final residual-literal sweep and evaluate UI-B02 closure readiness |
| 2026-04-16 | UI-014 | Execute UI-B02 residual literal sweep and closure assessment | Completed final spacing-literal sweep in global admin styles (tokenized remaining `margin`/`padding`/`gap` literals in shell/layout/control blocks), added missing spacing scale aliases for repeated values, and confirmed closure readiness | `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | CSS diagnostics clean; production build passed (`npm run build`); targeted spacing-literal grep returned no remaining matches | Done | Close UI-B02 and move to UI-A02 baseline screenshot evidence capture |
| 2026-04-16 | UI-015 | Execute UI-A02 baseline screenshot evidence capture | Captured baseline screenshots for all in-scope admin routes via automated browser run with protected-route admin session context; generated machine-readable manifest and human-readable summary | `wain_app/admin_web_console/scripts/capture-ui-a02-baseline.mjs`, `wain_app/admin_web_console/package.json`, `wain_app/admin_web_console/package-lock.json`, `wain_app/docs/release/ui_a02_baseline_screenshots/*.png`, `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.json`, `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Automated capture summary: 15/15 successful, 0 redirects to sign-in, 0 failures; production build passed (`npm run build`) | Done | Close UI-A02 and start UI-C01 shell navigation clarity improvements |
| 2026-04-16 | UI-016 | Execute UI-C01 shell navigation clarity and UI-C02 sidebar grouping | Implemented localized grouped sidebar navigation (`المالية`/`المحتوى`/`النظام`) from route map metadata, added active-item prefix matching with active-group highlighting, and introduced narrow-viewport collapsible group behavior without changing RBAC visibility contracts | `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`, `wain_app/admin_web_console/components/admin/admin-sidebar.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/admin_web_console/lib/navigation/admin-route-map.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npx vitest run lib/navigation/admin-route-map.test.ts lib/auth/rbac-shell.integration.test.ts` passed; production build passed (`npm run build`) | Done | Start UI-W01 warmup/prefetch load impact audit and guardrails |
| 2026-04-16 | UI-017 | Execute UI-W01 warmup/prefetch load impact audit and guardrails | Added route-level prefetch modes, bounded one-time shell prefetch policy, hover-intent sidebar prefetch for heavier routes, bounded server warmup route selection, and per-admin warmup dedupe guard | `wain_app/admin_web_console/lib/navigation/admin-contract.ts`, `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`, `wain_app/admin_web_console/lib/navigation/admin-warmup-policy.ts`, `wain_app/admin_web_console/components/admin/admin-shell.tsx`, `wain_app/admin_web_console/components/admin/admin-sidebar.tsx`, `wain_app/admin_web_console/app/api/admin/warmup/route.ts`, `wain_app/admin_web_console/lib/admin/admin-warmup-dedupe.ts`, `wain_app/admin_web_console/lib/navigation/admin-warmup-policy.test.ts`, `wain_app/admin_web_console/components/admin/admin-shell.test.tsx`, `wain_app/admin_web_console/lib/admin/warmup-route.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npx vitest run lib/navigation/admin-route-map.test.ts lib/navigation/admin-warmup-policy.test.ts lib/admin/warmup-route.test.ts components/admin/admin-shell.test.tsx` passed; `npx tsc --noEmit --pretty false` passed; full `npm test` passed (53 files, 279 tests); production build passed (`npm run build`) | Done | Start UI-D01 shared `ReadStateBanner` component |
| 2026-04-16 | UI-018 | Execute UI-D01 shared `ReadStateBanner` component | Added a reusable read-state banner for fresh/stale/empty/unavailable reads and migrated existing finance and venue read banners to wrap it without changing route loaders, RBAC, or page contracts | `wain_app/admin_web_console/components/shared/read-state-banner.tsx`, `wain_app/admin_web_console/components/shared/read-state-banner.test.tsx`, `wain_app/admin_web_console/components/finance/finance-read-banner.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-read-banner.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-read-banner.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npx vitest run components/shared/read-state-banner.test.tsx components/finance/finance-read-states.test.tsx components/venues/venue-directory-shell.test.tsx components/venue-workspace/venue-workspace-shell.test.tsx` passed; `npx tsc --noEmit --pretty false` passed | Done | Start UI-D02 shared `FilterToolbar` component |
| 2026-04-16 | UI-019 | Execute UI-D02 shared `FilterToolbar` component | Added reusable filter toolbar primitives for standard filter rows and migrated venue, media, content, and review filter surfaces without changing loader, RBAC, or command behavior | `wain_app/admin_web_console/components/shared/filter-toolbar.tsx`, `wain_app/admin_web_console/components/shared/filter-toolbar.test.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/offers-management-shell.tsx`, `wain_app/admin_web_console/components/content/stories-management-shell.tsx`, `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Targeted Vitest passed (5 files, 37 tests); `npx tsc --noEmit --pretty false` passed; full `npm test` passed (55 files, 285 tests); production build passed (`npm run build`) | Done | Start UI-D03 shared `DataTable` component |
| 2026-04-16 | UI-020 | Execute UI-D03 shared `DataTable` component | Added reusable display-table wrapper and migrated existing finance, config, venue, media, content, and review table wrappers while preserving table semantics, row actions, and existing test ids | `wain_app/admin_web_console/components/shared/data-table.tsx`, `wain_app/admin_web_console/components/shared/data-table.test.tsx`, `wain_app/admin_web_console/components/finance/topup-queue-table.tsx`, `wain_app/admin_web_console/components/finance/wallet-audit-table.tsx`, `wain_app/admin_web_console/components/config/config-governance-shell.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/offers-management-shell.tsx`, `wain_app/admin_web_console/components/content/stories-management-shell.tsx`, `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/admin_web_console/lib/finance/finance-read-snapshot-transport.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Targeted Vitest passed (9 files, 65 tests); `npx tsc --noEmit --pretty false` passed; full `npm test` passed (56 files, 287 tests) after a targeted timeout stabilization for one finance transport test; production build passed (`npm run build`) | Done | Start UI-D04 shared `StatusBadge` component |
| 2026-04-16 | UI-021 | Execute UI-D04 shared `StatusBadge` component | Added reusable status badge primitive and migrated finance, config, venue, media, content, reviews, and venue workspace status chips/runtime badges to use it while preserving status mapping, test ids, and command/read contracts | `wain_app/admin_web_console/components/shared/status-badge.tsx`, `wain_app/admin_web_console/components/shared/status-badge.test.tsx`, `wain_app/admin_web_console/components/finance/topup-queue-table.tsx`, `wain_app/admin_web_console/components/finance/wallet-audit-table.tsx`, `wain_app/admin_web_console/components/finance/readiness-panel.tsx`, `wain_app/admin_web_console/components/finance/reversal-approval-panel.tsx`, `wain_app/admin_web_console/components/config/config-governance-shell.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/offers-management-shell.tsx`, `wain_app/admin_web_console/components/content/stories-management-shell.tsx`, `wain_app/admin_web_console/components/content/content-action-cell.tsx`, `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`, `wain_app/admin_web_console/components/reviews/review-action-cell.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-header.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npx tsc --noEmit --pretty false` passed; full `npm test` passed (57 files, 289 tests); production build passed (`npm run build`) | Done | Start UI-D05 shared `ActionPanel` component |
| 2026-04-17 | UI-022 | Execute UI-D05 shared `ActionPanel` component | Added reusable action panel primitives and migrated media/content/review/config/venue command zones to shared stack/item/header/actions/message wrappers while preserving runtime flows, status semantics, and test ids | `wain_app/admin_web_console/components/shared/action-panel.tsx`, `wain_app/admin_web_console/components/shared/action-panel.test.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/content-action-cell.tsx`, `wain_app/admin_web_console/components/reviews/review-action-cell.tsx`, `wain_app/admin_web_console/components/config/config-governance-shell.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Targeted Vitest passed (6 files, 43 tests); `npx tsc --noEmit --pretty false` passed; full `npm test` passed (58 files, 291 tests); production build passed (`npm run build`) | Done | Start UI-E01 pilot rollout route pass |
| 2026-04-17 | UI-023 | Execute UI-E01 pilot rollout route pass | Ran pilot verification on representative routes (`/admin/dashboard`, `/admin/venues`, `/admin/config`) after Stream 3 closure to confirm shared-component adoption and route-state/RBAC stability without additional route code changes | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Pilot-focused Vitest passed (5 files, 22 tests); production build passed (`npm run build`) | Done | Start UI-P01 polish/micro-interaction pass |
| 2026-04-17 | UI-024 | Execute UI-P01 polish/micro-interaction pass | Applied a conservative micro-interaction polish sweep in global admin styles (hover/active/focus continuity for nav/buttons/tabs/action cards/table rows and reduced-motion safety) without changing RBAC, loader, transport, or route contracts | `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npx tsc --noEmit --pretty false` passed; full `npm test` passed (58 files, 291 tests); production build passed (`npm run build`) | Done | Prepare post-polish browser smoke evidence refresh |
| 2026-04-17 | UI-025 | Execute post-polish browser smoke evidence refresh | Re-ran automated browser route capture after UI-P01 with explicit development admin session context to confirm protected-route rendering and route-guard stability across all in-scope admin routes | `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.json`, `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.md`, `wain_app/docs/release/ui_a02_baseline_screenshots/*.png`, `wain_app/docs/release/admin_web_console_ui_post_polish_smoke_ui_025.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npm run capture:ui-a02` passed (15/15 successful, 0 redirects, 0 failures) with dev server running under admin session env | Done | Resume next UI stream candidate |
| 2026-04-17 | UI-026 | Execute UI-P03 post-polish visual diff triage | Added repeatable screenshot artifact triage tooling (`HEAD` vs current workspace) using hash/byte/dimension checks and generated a dedicated triage report for all captured admin routes | `wain_app/admin_web_console/scripts/triage-ui-a02-visual-diff.mjs`, `wain_app/admin_web_console/package.json`, `wain_app/docs/release/admin_web_console_ui_visual_diff_triage_ui_026.json`, `wain_app/docs/release/admin_web_console_ui_visual_diff_triage_ui_026.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | `npm run capture:ui-a02:triage` passed (15 entries; 0 critical findings; 15 review findings marked `new-file` because screenshot artifacts are not present in `HEAD`) | Done | Select next product-facing UI candidate after evidence triage |
| 2026-04-17 | UI-027 | Select next product-facing UI stream candidate | Chose `UI-M01` (Media visual preview/viewer baseline) as the next execution stream to close the highest-impact remaining product UI gap from Phase 4 follow-ups while staying within current read/governance contracts | `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`, `wain_app/docs/release/admin_web_console_progress_tracker.md` | Decision aligned with open follow-up inventory in tracker (`preview/viewer` gap under Phase 4) | Done | Start UI-M01 implementation slice 1 |
| 2026-04-17 | UI-028 | Execute UI-M01 slice 1 (Media preview/viewer baseline) | Added row-level media preview affordance and read-only viewer dialog in Media Center while preserving existing RBAC, command transport, and destructive-action contracts | `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/lib/media/media-center-models.ts`, `wain_app/admin_web_console/lib/media/media-center-baseline.ts`, `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`, `wain_app/admin_web_console/components/media/media-center-route.test.tsx`, `wain_app/admin_web_console/lib/media/media-center-baseline.test.ts`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Targeted Vitest passed (3 files, 21 tests); full `npm test` passed (58 files, 293 tests); production build passed (`npm run build`) | Done | Select UI-M01 slice 2 candidate (replace workflow or richer preview metadata) |
| 2026-04-17 | UI-029 | Execute UI-M01 slice 2 (Media replace draft workflow) | Added a replace draft workflow in Media Center with dialog UX, URL/reason validation, and copyable governance payload while keeping RBAC and media command contracts unchanged (no backend mutation path added) | `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md` | Targeted Vitest passed (3 files, 23 tests); full `npm test` passed (58 files, 295 tests); production build passed (`npm run build`) | Done | Close UI-M01 and move to remaining Phase 4 follow-up evidence (`media transport` staging smoke) |
| 2026-04-17 | UI-030 | Execute remaining Phase 4 media transport staging smoke | Completed authenticated staging callable probes for media transport surfaces with final machine-readable + narrative evidence showing full transport health | `wain_app/.tmp/probe_media_transport_authenticated.js`, `wain_app/docs/release/admin_web_console_media_transport_smoke_ui_030.json`, `wain_app/docs/release/admin_web_console_media_transport_smoke_ui_030.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`, `wain_app/docs/release/admin_web_console_progress_tracker.md` | Final probe completed (`6` endpoints): `6` HTTP 200, `0` App Check failed, `0` HTTP 404; latest artifact timestamp `2026-04-17T00:30:57.254Z`; decision `FOLLOW_UP_CLOSED` | Done | Move to the next product-facing UI candidate |

## 8. Active Backlog

| ID | Priority | Item | Status | Owner | Notes |
|---|---|---|---|---|---|
| UI-A01 | P0 | Build route-by-route UI audit matrix | Completed | AI + Team | Section 9 baseline captured |
| UI-A02 | P0 | Capture baseline screenshots for all admin routes | Completed | AI + Team | Section 9.1 evidence captured (15/15 routes) |
| UI-B01 | P0 | Token alignment review in global styles | Completed | AI | Section 11.1 token audit baseline approved |
| UI-B02 | P0 | Implement missing token set (`radius`, `spacing`, semantic status, shadow) | Completed | AI | Sections 11.2, 11.3, and 11.4 completed; residual sweep and closure assessment passed |
| UI-B03 | P0 | Define route-level `loading.tsx` and `error.tsx` coverage | Completed | AI | Hybrid strategy approved: full protected loading coverage + targeted route-specific error boundaries + shared segment fallback |
| UI-B04 | P0 | Approve route-state matrix (`loading`, `error`, `not-found`, access-denied, empty/no-results, stale/unavailable) | Completed | AI + Team | Section 12.2 approved baseline |
| UI-B05 | P0 | Decide `DataTable` mode contract (`display-table` vs `interactive-grid`) | Completed | AI + Team | Section 10.2 decision pass approved |
| UI-C01 | P0 | Shell navigation clarity improvements | Completed | AI | Implemented with active-route and active-group clarity in admin shell sidebar |
| UI-C02 | P0 | Implement sidebar grouping spec | Completed | AI | Section 13 delivered with localized groups and narrow-viewport collapse behavior |
| UI-D01 | P1 | Build shared `ReadStateBanner` component | Completed | AI | Section 10 shared component implemented and first wrappers migrated |
| UI-D02 | P1 | Build shared `FilterToolbar` component | Completed | AI | Section 10 shared component implemented and first filter surfaces migrated |
| UI-D03 | P1 | Build shared `DataTable` component | Completed | AI | Section 10 shared component implemented and table wrappers migrated |
| UI-D04 | P1 | Build shared `StatusBadge` component | Completed | AI | Section 10 shared component implemented and status/runtime badges migrated |
| UI-D05 | P1 | Build shared `ActionPanel` component | Completed | AI | Section 10 shared component implemented and command zones migrated |
| UI-W01 | P0 | Warmup/prefetch load impact audit and guardrails | Completed | AI | Section 14 policy implemented and verified |
| UI-E01 | P1 | Pilot rollout on dashboard + one table-heavy route + one command-heavy route | Completed | AI + Team | Pilot routes validated: `/admin/dashboard`, `/admin/venues`, `/admin/config` |
| UI-P01 | P2 | Polish/micro-interaction pass after contract adoption | Completed | AI | Post-pilot polish delivered with reduced-motion-safe micro-interactions |
| UI-P02 | P2 | Refresh browser smoke evidence after UI-P01 | Completed | AI | Re-ran route capture: 15/15 successful with zero sign-in redirects |
| UI-P03 | P2 | Run post-polish visual diff triage for route screenshots | Completed | AI | Artifact diff report generated for 15 routes with 0 critical findings |
| UI-M01 | P1 | Implement Media visual preview/viewer baseline | Completed | AI + Team | Slice 1 delivered read-only preview/viewer flow and Slice 2 delivered draft-only replace workflow with validation/payload generation, both without RBAC or command-contract changes; UI-030 then closed the pending media transport smoke follow-up (`FOLLOW_UP_CLOSED`, `6/6` HTTP 200). |

## 9. Phase A Route Audit Matrix (Baseline 2026-04-16)

Goal:
- Capture a route-by-route baseline before rollout of route-state contracts and shared component migration.

| Route | Group | Current Route Surface | Route-Level State Files | Severity | Dependency Stream | Next Required Action |
|---|---|---|---|---|---|---|
| `/admin` | Protected index | Redirect to `/admin/dashboard` only | `loading.tsx`: none, `error.tsx`: none, segment `not-found`: none | Medium | Stream 4 | Keep redirect behavior, add parent-level error boundary in protected admin segment |
| `/admin/dashboard` | Phase1 | `Suspense` fallback exists in page-level rendering | `loading.tsx`: none, `error.tsx`: none | High | Stream 4, Stream 5 | Introduce route-level loading/error contract and measure transition timing |
| `/admin/topups` | Phase1 | Finance read banner + table-level empty/unavailable + command runtime states | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Map current states to section 12.1 matrix and add route-level boundaries |
| `/admin/wallet-audit` | Phase1 | Finance read banner + table runtime callouts for command outcomes | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Align command/read states with unified route matrix and add route-level boundaries |
| `/admin/reversals` | Phase1 | Command panel with local input/runtime error surfacing | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Add explicit route read-state shell and route-level error/loading |
| `/admin/readiness` | Phase1 | Finance read banner + report/checks + command panel | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Normalize stale/unavailable semantics in unified route-state contract |
| `/admin/venues` | Phase1 | Venue directory banner + command provider + directory shell | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Adopt shared read banner contract and add route-level state boundaries |
| `/admin/venues/[venueId]` | Phase1 | Venue workspace shell (read bundle) with page-level framing only | `loading.tsx`: none, `error.tsx`: none, route-level `not-found`: none | High | Stream 4 | Define not-found and unavailable contract for invalid/missing venue IDs |
| `/admin/media` | Phase4 | Media center shell + command provider (snapshot-driven) | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Add route-level boundaries and map media read states to shared banner model |
| `/admin/content/offers` | Phase5 | Content shell + command provider + moderation affordances | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Add unified state matrix coverage and route-level boundaries |
| `/admin/content/stories` | Phase5 | Content shell + command provider + moderation affordances | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Add unified state matrix coverage and route-level boundaries |
| `/admin/content/reviews` | Phase5 | Review moderation shell + command provider | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Add unified state matrix coverage and route-level boundaries |
| `/admin/config` | Phase6 | Config governance shell + command provider | `loading.tsx`: none, `error.tsx`: none | High | Stream 3, Stream 4 | Add route-level boundaries and explicit mutation success/failure contract |
| `/admin/sign-in` | Public | Client-side auth form with local loading/error handling | `loading.tsx`: none, `error.tsx`: none | Medium | Stream 4 | Add public route error/loading fallback strategy (lightweight) |
| `/admin/access-denied` | Public | Static access-denied state page | `loading.tsx`: none, `error.tsx`: none | Low | Stream 4 | Keep as canonical denied surface; include in route-state matrix for completeness |

Baseline findings summary:
- In-scope routes audited: 15 (13 protected surfaces including index + 2 public surfaces).
- Route-level state files present under admin segments: 0 `loading.tsx`, 0 `error.tsx`, 0 segment-level `not-found.tsx`.
- Global fallback exists: `app/not-found.tsx` only.
- Current read-state handling exists but is domain-specific (finance and venues) and not yet normalized across all modules.
- Sidebar IA currently renders flat list from route visibility map; group labels are not yet rendered in sidebar UI.

Phase A closure status:
- UI-A01 complete.
- UI-A02 complete.
- Phase A is now closed (route audit baseline + screenshot evidence baseline captured for all in-scope routes).

### 9.1 UI-A02 Baseline Screenshot Evidence (UI-015)

Objective:
- Close the remaining Phase A gap by capturing a route-by-route baseline screenshot set for all in-scope admin routes.

Execution approach:
- Added deterministic capture command `npm run capture:ui-a02` backed by `scripts/capture-ui-a02-baseline.mjs`.
- Started the production server with runtime admin session context injected through `WAIN_ADMIN_SESSION_JSON` to preserve existing RBAC contracts while allowing protected-route rendering.
- Captured route baselines for all audited routes (public + protected), including dynamic venue workspace via resolver from `/admin/venues` links.
- Emitted two evidence artifacts plus image set under `docs/release`:
  - `admin_web_console_ui_a02_baseline_capture.json`
  - `admin_web_console_ui_a02_baseline_capture.md`
  - `ui_a02_baseline_screenshots/*.png` (15 files)

Validation evidence:
- Automated capture run summary:
  - total planned routes: `15`
  - successful captures: `15`
  - redirected to sign-in: `0`
  - failed captures: `0`
- Captured routes include:
  - `/admin`, `/admin/sign-in`, `/admin/access-denied`
  - `/admin/dashboard`, `/admin/topups`, `/admin/wallet-audit`, `/admin/reversals`, `/admin/readiness`
  - `/admin/venues`, `/admin/venues/[venueId]`
  - `/admin/media`, `/admin/content/offers`, `/admin/content/stories`, `/admin/content/reviews`, `/admin/config`

Closure decision:
- UI-A02 is closed.
- Phase A is closed.

Next step:
- Start UI-C01 shell navigation clarity improvements (Phase C) with a focused dependency/risk pass before implementation.

Post-baseline implementation delta (after UI-005 through UI-008):
- Protected segment-level fallbacks now exist: `app/(protected)/admin/loading.tsx` and `app/(protected)/admin/error.tsx`.
- Route-specific loading overrides now exist for:
  - `/admin/dashboard`
  - `/admin/topups`
  - `/admin/wallet-audit`
  - `/admin/reversals`
  - `/admin/readiness`
  - `/admin/venues`
  - `/admin/venues/[venueId]`
  - `/admin/media`
  - `/admin/content/offers`
  - `/admin/content/stories`
  - `/admin/content/reviews`
  - `/admin/config`
- Current remaining gap in UI-B03: evaluate and apply route-specific `error.tsx` only where segment-level error boundary is insufficient.
- Route-specific `error.tsx` overrides now exist for:
  - `/admin/topups`
  - `/admin/config`
  - `/admin/venues/[venueId]`
- UI-B03 closure decision: remaining protected routes use segment-level error boundary by default until a route-specific recovery requirement is demonstrated.

### 12.4 Error Boundary Decision Pass (UI-009)

Decision principle:
- Keep route-specific `error.tsx` only for routes needing context-specific recovery actions.
- Keep shared `app/(protected)/admin/error.tsx` as the default boundary for other protected routes.

Decision matrix for remaining protected routes:

| Route | Decision | Rationale | Revisit Trigger |
|---|---|---|---|
| `/admin/dashboard` | Keep segment-level error boundary | Read-heavy overview route; generic retry + return-to-dashboard action is sufficient | If dashboard introduces critical route-specific actions |
| `/admin/wallet-audit` | Keep segment-level error boundary | Mutation outcomes already surfaced at command layer; catastrophic route failure can use shared recoverable fallback | If route-level rollback/resume UX becomes required |
| `/admin/readiness` | Keep segment-level error boundary | Operational checks and refresh can recover via shared retry path | If readiness adds route-specific remediation workflow |
| `/admin/reversals` | Keep segment-level error boundary | Current workflow can recover through shared retry and navigation path | If multi-step approval flow needs route-context recovery |
| `/admin/venues` | Keep segment-level error boundary | Directory route has clear fallback navigation and retry semantics via shared boundary | If directory-specific recovery shortcuts are required |
| `/admin/media` | Keep segment-level error boundary | Shared fallback is sufficient for baseline media inventory load failures | If media introduces irreversible route-level actions needing custom recovery |
| `/admin/content/offers` | Keep segment-level error boundary | Moderation surface remains recoverable through shared retry behavior | If route-specific moderation recovery UX is introduced |
| `/admin/content/stories` | Keep segment-level error boundary | Same moderation recovery profile as offers | If route-specific moderation recovery UX is introduced |
| `/admin/content/reviews` | Keep segment-level error boundary | Shared retry behavior is sufficient for current moderation surface | If review escalation flow needs dedicated recovery entry points |

## 10. Shared React Component Contract (Mandatory)
These components are required in the unified UI layer and must be referenced by feature modules.

| Component | Purpose | Primary Targets |
|---|---|---|
| `FilterToolbar` | Standard filter row layout with input/select/actions and responsive wrapping | venues, media, content |
| `DataTable` | Standard table wrapper with scroll, header styling, empty state, and row density controls | venues, media, finance, content, reviews |
| `StatusBadge` | Single source for success/warning/danger/neutral visual statuses | all modules |
| `ReadStateBanner` | Unified stale/unavailable/empty/fresh read-state messaging | finance, venues, dashboard |
| `ActionPanel` | Unified actions stack for command buttons, runtime callouts, and disabled reasoning | venues, media, content/config command zones |

Implementation rule:
- No new module-specific variants should duplicate these patterns unless documented and approved in this file.

Implementation result (UI-018):
- `ReadStateBanner` now provides the shared fresh/stale/empty/unavailable read-state surface for Stream 3.
- Existing finance, venue directory, and venue workspace read banners now wrap the shared component while preserving current test ids, `data-read-kind`, and stale/unavailable semantics.
- The first slice intentionally avoids loader, RBAC, and page-flow changes; broader module migration remains gated by UI-D02 through UI-D05.
- Validation: shared component tests plus finance/venue wrapper tests passed, and TypeScript validation passed.

Implementation result (UI-019):
- `FilterToolbar`, `FilterField`, `FilterTextInput`, and `FilterSelect` now provide the shared filter row primitives for Stream 3.
- Venue directory, media center, offers, stories, and review moderation filter rows now use the shared primitives while preserving existing test ids, labels, values, `onChange` behavior, and legacy class hooks.
- The migration intentionally avoids filter logic, loader, RBAC, and command-flow changes; it only normalizes the rendered filter control structure and CSS hooks.
- Validation: targeted filter surface tests passed, TypeScript validation passed, full Vitest passed, and the production build passed.

Implementation result (UI-020):
- `DataTable` now provides the shared `display-table` wrapper, preserving native semantic table behavior while centralizing scroll frame, table mode, density, caption, and test-id hooks.
- Existing table wrappers in finance, config, venue directory, venue workspace tabs, media center, content offers/stories, and review moderation now use `DataTable`; row rendering, action buttons, links, empty states, and RBAC-driven affordances were not changed.
- CSS now keeps legacy `.table-scroll`/`.data-table` behavior while adding shared hooks for `data-table-scroll`, caption styling, and compact density.
- Full-suite validation exposed a finance transport test that could exceed Vitest's default 5s timeout only under parallel full-suite load; the timeout was stabilized locally for that specific test without changing production code.
- Validation: targeted table surface tests passed, TypeScript validation passed, full Vitest passed, and the production build passed.

Implementation result (UI-021):
- `StatusBadge` now provides the shared status-chip primitive for Stream 3, with `tone` support (`success`, `warning`, `danger`, `neutral`) and compatibility for existing class-based status maps.
- Existing status and runtime badges in finance, config, venue directory/workspace, media center, content moderation, and review moderation now use `StatusBadge`; status text, command flow, read behavior, and RBAC-driven affordances were not changed.
- Migration preserved existing testing hooks (`data-testid`), command/read state labels, and all route-level contracts while removing direct `status-pill` duplication from feature modules.
- Validation: TypeScript validation passed, full Vitest passed (57 files, 289 tests), and the production build passed.

Implementation result (UI-022):
- `ActionPanel` now provides shared Stream 3 primitives for action stacks (`ActionPanel`, `ActionPanelItem`, `ActionPanelHeader`, `ActionPanelActions`, `ActionPanelMessage`) with compatibility for legacy class hooks.
- Media, content, reviews, config, and venue command zones now render through shared action-panel primitives while preserving existing role-gated affordances, runtime states, status labels, and mutation/read contracts.
- Migration intentionally avoided RBAC, loader, and transport changes; it normalizes only presentation wrappers for command zones and disabled-reason messaging surfaces.
- Validation: targeted Vitest passed (6 files, 43 tests), TypeScript validation passed, full Vitest passed (58 files, 291 tests), and the production build passed.

Pilot result (UI-023):
- UI-E01 representative routes were validated as the Wave 3 pilot set:
  - overview route: `/admin/dashboard`
  - table-heavy route: `/admin/venues`
  - command-heavy route: `/admin/config`
- Pilot verification confirmed route-state and RBAC behavior remained stable after Stream 3 shared-component closures (`ReadStateBanner`, `FilterToolbar`, `DataTable`, `StatusBadge`, `ActionPanel`).
- No additional route implementation changes were required in this pass; the closure is evidence-driven.
- Validation: pilot-focused Vitest passed (5 files, 22 tests) and production build passed.

Implementation result (UI-024):
- UI-P01 delivered a post-pilot polish sweep in `app/globals.css` with bounded micro-interactions only (no route/business logic changes).
- Improved interaction continuity for already-adopted shared surfaces:
  - sidebar links and primary shell buttons now have subtle hover/active feedback
  - action buttons and tab controls now include consistent hover/press response
  - command cards and summary cards use lightweight hover elevation cues
  - table rows get readable hover highlighting for scan-heavy views
- Added explicit `@media (prefers-reduced-motion: reduce)` handling for interactive surfaces to keep motion accessible.
- Validation: TypeScript validation passed, full Vitest passed (58 files, 291 tests), and production build passed.

Implementation result (UI-025):
- Post-polish browser smoke evidence was refreshed via deterministic route capture (`npm run capture:ui-a02`) after UI-P01 closure.
- The capture run used explicit development admin session context on the server (`WAIN_ADMIN_UID`, `WAIN_ADMIN_EMAIL`, `WAIN_ADMIN_ROLE`, `WAIN_ADMIN_ROLES`, `WAIN_ADMIN_ADMIN`, `WAIN_ADMIN_IS_ADMIN`) to preserve protected-route rendering during smoke execution.
- Updated capture artifacts confirm stable route behavior after polish:
  - total planned routes: `15`
  - successful captures: `15`
  - redirects to sign-in: `0`
  - failed captures: `0`
- Artifacts refreshed: baseline capture JSON summary, markdown summary, and full screenshot set; an explicit run note was added for this round.
- Validation: `npm run capture:ui-a02` returned `ok: true` with clean aggregate counts.

Implementation result (UI-026):
- Added a deterministic triage command (`npm run capture:ui-a02:triage`) to compare current route screenshots with `HEAD` artifacts for drift detection.
- The new triage script consumes the capture manifest and reports per-route status using three checks:
  - SHA-256 hash
  - byte-size delta
  - PNG dimensions
- Triage artifacts are now generated in release docs:
  - `admin_web_console_ui_visual_diff_triage_ui_026.json`
  - `admin_web_console_ui_visual_diff_triage_ui_026.md`
- Current run summary:
  - total entries: `15`
  - critical findings: `0`
  - review findings: `15` (`new-file`, because screenshot artifacts were not found in `HEAD`)
- Validation: `npm run capture:ui-a02:triage` passed.

Selection result (UI-027):
- Next product-facing stream selected: `UI-M01` (Media visual preview/viewer baseline).
- Selection basis:
  - directly addresses the explicit Phase 4 follow-up gap (`preview/viewer بصري كامل`)
  - delivers immediate operator UX value without requiring new destructive contracts
  - can be staged safely as read-only viewer first, preserving existing RBAC and command governance boundaries
- Planned execution shape for UI-M01 slice 1:
  - add media row-level preview affordance and unified viewer shell
  - keep behavior read-only (no replace/delete contract expansion in the same slice)
  - include focused shell tests + route/build revalidation

Implementation result (UI-028):
- UI-M01 slice 1 delivered a read-only media preview/viewer baseline in `MediaCenterShell`.
- Operator-facing changes:
  - each media row now has a `معاينة` affordance
  - clicking the affordance opens a modal viewer with media metadata and close controls
  - when no browser-safe direct media URL is available, the viewer shows an explicit unavailable note instead of a broken image
- Contract safety:
  - no RBAC capability matrix changes
  - no command transport changes
  - no destructive action or replace-workflow expansion in this slice
- Data/model alignment:
  - `MediaCenterItem` now preserves optional `mediaUrl`
  - baseline normalization keeps `mediaUrl` for proof/venue/offer/story rows to support viewer rendering when available
- Validation: targeted media tests passed (3 files, 21 tests), full suite passed (58 files, 293 tests), and production build passed.

### 10.1 Behavior Contracts (Required Before Module Migration)

Data table contract:
- `display-table`: native semantic table for static/read-heavy views.
- `interactive-grid`: only when full keyboard-managed grid behavior is required.
- Sorting in `display-table` uses explicit controls and `aria-sort` semantics.

Filter toolbar contract:
- Do not use toolbar role unless implementing keyboard interaction model consistently.
- Keep filter controls operable as standard form controls by default.

Dialog contract:
- Focus moves into dialog on open.
- Focus stays trapped in dialog while open.
- Escape closes dialog where appropriate.
- Focus returns to opener on close.
- Destructive flows must default to least-destructive action focus.

### 10.2 DataTable Mode Decision Pass (UI-B05)

Decision principle:
- Current admin surfaces use semantic HTML tables with row actions and filter controls.
- Default mode for current and near-term rollout is `display-table`.
- `interactive-grid` is deferred and must only be adopted when a route needs full cell-level keyboard navigation and complex in-grid interaction.

Adoption gates for `interactive-grid` (all required):
- Explicit product requirement for cell-level focus navigation.
- Dedicated keyboard model (`Arrow` navigation, focus management, escape rules).
- Additional accessibility review for grid semantics and testing evidence.
- Route-specific implementation plan approved in this document before coding.

Route/module decision matrix:

| Surface | Current Implementation Signal | Approved Mode | Rationale |
|---|---|---|---|
| `/admin/topups` queue table | Semantic `<table>` with action buttons per row | `display-table` | Row-level actions, no cell-level keyboard workflow requirement |
| `/admin/wallet-audit` ledger table | Semantic `<table>` with action callouts per row | `display-table` | Read-heavy ledger + row actions; grid complexity not justified |
| `/admin/venues` directory table | Semantic `<table>` with row actions and workspace link | `display-table` | Directory filtering and row commands fit table model |
| `/admin/venues/[venueId]` workspace tab tables | Multiple semantic `<table>` sections | `display-table` | Read-focused tabular summaries with simple interactions |
| `/admin/media` inventory table | Semantic `<table>` + per-row moderation actions | `display-table` | Inventory moderation does not require cell-navigation grid behavior |
| `/admin/content/offers` table | Semantic `<table>` + per-row moderation actions | `display-table` | Filter + row actions model is table-first |
| `/admin/content/stories` table | Semantic `<table>` + per-row moderation actions | `display-table` | Same moderation interaction profile as offers |
| `/admin/content/reviews` table | Semantic `<table>` + per-row moderation actions | `display-table` | Review moderation remains row-action oriented |
| `/admin/config` history table | Semantic `<table>` read-history surface | `display-table` | Timeline/history read surface, no in-cell editing workflow |

Implementation note:
- Shared `DataTable` component in UI-D03 must start as a `display-table` abstraction and only expose `interactive-grid` mode behind an explicit gated prop introduced in a later approved change.

## 11. Missing Token Set (P0)
Current token surface is incomplete; add and migrate to these tokens first:

- Radius:
  - `--radius-sm`
  - `--radius-md`
  - `--radius-lg`
  - `--radius-pill`
- Spacing:
  - `--space-1`, `--space-2`, `--space-3`, `--space-4`, `--space-5`, `--space-6`
- Semantic colors:
  - `--success`, `--success-soft`, `--success-line`
  - `--warning`, `--warning-soft`, `--warning-line`
  - `--danger`, `--danger-soft`, `--danger-line`
  - `--info`, `--info-soft`, `--info-line`
- Elevation:
  - `--shadow-card`
  - `--shadow-elevated`
- Focus and borders:
  - `--focus-ring-color`
  - `--focus-ring-width`
  - `--border-width-sm`
  - `--border-width-md`
- Typography scale:
  - `--font-size-xs`, `--font-size-sm`, `--font-size-md`, `--font-size-lg`, `--font-size-xl`
  - `--line-height-tight`, `--line-height-normal`, `--line-height-relaxed`
- Layering:
  - `--z-base`, `--z-dropdown`, `--z-sticky`, `--z-modal`, `--z-toast`
- Motion:
  - `--motion-fast`, `--motion-normal`, `--motion-slow`
  - `--easing-standard`, `--easing-emphasis`
- Density and hit-area:
  - `--control-height-sm`, `--control-height-md`, `--control-height-lg`
  - `--hit-target-min`

Migration rule:
- Replace repeated hardcoded values in global and module styles before adding new visual variants.

### 11.1 Token Alignment Review Pass (UI-B01)

Objective:
- Establish an implementation-grade token alignment baseline before introducing new tokens in UI-B02.

Scope reviewed:
- `app/globals.css` (single current stylesheet surface for admin shell and module states).

Observed baseline:
- Existing root token families are limited to core surface/text/line, primary, danger, and sidebar colors.
- Missing from live token surface (compared with section 11 target set): semantic success/warning/info families, radius scale, spacing scale, typography scale, elevation tokens, focus tokens, motion tokens, z-layer scale, and control density tokens.

Evidence snapshot (from stylesheet scan):
- Hardcoded hex literals: 65 matches.
- Explicit `border-radius` literals: 23 matches (`10px`, `12px`, `16px`, `999px`).
- Explicit `box-shadow` literal: 1 match.
- Explicit `z-index` literal: 1 match (`30`).
- `:focus`/`:focus-visible` tokenized ring rules: no explicit global focus rule found.
- `transition`/`animation` tokenized motion rules: no explicit global transition/animation token usage found.

Hotspot groups for first migration wave (UI-B02):
- Status and feedback surfaces:
  - `.status-success`, `.status-warning`, `.status-danger`, `.status-neutral`
  - dashboard status and alert variants
- Shape and control geometry:
  - repeated control radius (`10px`) and pill radius (`999px`)
  - repeated card radius (`12px`) and elevated card radius (`16px`)
- Read-state and command containers:
  - `.finance-read-banner*`, `.command-runtime-callout`, `.media-action-item`, `.venue-action-item`
- Layering and dialog overlays:
  - `.venue-management-dialog-backdrop` (`z-index: 30`)

Dependencies and risks:
- Dependency: UI-B02 must consume this baseline and introduce tokens incrementally in `:root` before replacing component-level literals.
- Dependency: UI-D* shared components should reference only approved semantic tokens once introduced.
- Risk 1: unscoped global replacements may alter contrast/readability in Arabic admin flows.
- Risk 2: replacing status colors without semantic mapping can break stale/unavailable distinction.
- Risk 3: introducing focus ring broadly without gating can cause noisy visuals on mouse-first flows.

Mitigation strategy approved for UI-B02:
- Step 1: introduce missing tokens in `:root` as additive aliases (no behavior change).
- Step 2: migrate high-repeat literals to token references in small batches by concern (status -> radius -> spacing -> elevation).
- Step 3: verify each batch with build and spot-check key protected routes before next batch.

Exit criteria for UI-B01:
- Token coverage gaps are explicitly documented.
- Migration order and risk controls are approved.
- No runtime UI contract (RBAC, route-state, command behavior) changed during the review pass.

### 11.2 UI-B02 Batch 1 - Token Introduction + First Alias Migration (UI-012)

Objective:
- Execute the first low-risk implementation slice from the UI-B01 migration plan by introducing the missing token families and replacing the most repeated literals with semantic aliases.

Implemented in `app/globals.css`:
- Added missing token families in `:root`:
  - semantic colors (`success`, `warning`, `danger`, `info` + `soft`/`line` variants)
  - radius scale (`sm`, `md`, `lg`, `pill`)
  - spacing scale (`space-1` through `space-6`)
  - elevation (`shadow-card`, `shadow-elevated`)
  - focus/border tokens, typography scale, z-layer scale, motion curve/timing, and control density tokens
- Migrated first-pass high-repeat literals to token aliases:
  - status/read-state surfaces (dashboard badges/cards/alerts, generic `.status-*`, finance read-state accents)
  - geometry hotspots (`border-radius: 10/12/16/999` in targeted admin shell/module selectors)
  - elevation hotspot (`dashboard-kpi` shadow)
  - layering hotspot (`venue-management-dialog-backdrop` z-index)
  - selected typography hotspot (`line-height` aliases for title/note)

Validation evidence:
- `npm run build` under `wain_app/admin_web_console` passed after migration.
- No CSS diagnostics reported for `app/globals.css`.

Observed impact:
- Styling contracts remain behavior-preserving (no RBAC, data-loading, or route-state logic changes).
- UI-B02 moved from planning to active implementation with batch-wise migration control.

Next batch (UI-B02 batch 2):
- Adopt spacing and control-density tokens in component blocks where literals still dominate.
- Introduce tokenized focus-visible treatment in key interactive controls with low visual-noise defaults.
- Apply motion tokens to existing transitions where safe.
- Re-run build and targeted route spot-check before considering UI-B02 closure.

### 11.3 UI-B02 Batch 2 - Spacing/Focus/Motion Adoption + Residual Cleanup (UI-013)

Objective:
- Execute the next low-risk UI-B02 slice by expanding token adoption to interactive control density/spacing and keyboard focus/motion consistency without changing feature behavior.

Implemented in `app/globals.css`:
- Spacing/control-density token adoption:
  - migrated repeated control spacing literals in interactive UI blocks (`status-pill`, command stacks/callouts, action buttons, venue/media filter inputs, workspace/media tabs, action items, summary cards) to `--space-*` aliases
  - adopted `--control-height-*` on key controls to normalize minimum hit-area across admin interactions
- Focus consistency:
  - added unified low-noise `:focus-visible` treatment using `--focus-ring-width` and `--focus-ring-color` for core interactive controls and links
- Motion consistency:
  - applied tokenized transitions (`--motion-fast` + `--easing-standard`) to interactive controls where safe and behavior-preserving
- Residual cleanup:
  - replaced remaining alert-surface hardcoded soft backgrounds in command/read banners with semantic aliases (`--warning-soft`, `--danger-soft`)

Validation evidence:
- CSS diagnostics remained clean for `app/globals.css`.
- Admin web console production build passed after batch 2 (`npm run build`).

Observed impact:
- No RBAC, route-state, transport, or command contract changes were introduced.
- Batch 2 improves consistency and keyboard affordance while keeping the current visual language stable.

Next batch (UI-B02 residual sweep):
- Run targeted residual literal sweep for remaining non-tokenized spacing and edge hardcoded values.
- Revalidate build and perform focused route spot-check before deciding UI-B02 closure.

### 11.4 UI-B02 Residual Sweep + Closure Assessment (UI-014)

Objective:
- Complete the final UI-B02 residual cleanup pass and make a closure decision based on explicit verification gates.

Implemented in `app/globals.css`:
- Added missing spacing aliases for repeated values still present in shell/layout blocks (`--space-0`, `--space-7`, `--space-8`, `--space-9`, `--space-10`).
- Tokenized remaining repeated hardcoded spacing literals in key admin layout/control sections:
  - shell/header/sidebar/auth scaffolding spacing (`margin`/`padding`/`gap`)
  - dashboard layout cards/messages/meta spacing
  - table/card/preview/readiness/workspace spacing
  - venue/media shell and dialog spacing surfaces
- Preserved all non-spacing structural values (breakpoints, min/max widths, grid contracts, typography scale) to avoid unintended behavior changes.

Validation evidence:
- CSS diagnostics clean for `app/globals.css`.
- Production build passed after residual sweep (`npm run build`).
- Targeted spacing-literal grep pattern for `margin|padding|gap` hardcoded px values returned no matches in `app/globals.css`.

Closure decision:
- UI-B02 is closed.
- The planned token introduction + staged alias migration + residual sweep sequence is fully executed and validated.

Next step:
- Resume Phase A evidence track via UI-A02 baseline screenshot capture across admin routes.

## 12. Next.js Route UX Contract (`loading.tsx` / `error.tsx`)
Deliverables in Phase B/C:
- Add route-level `loading.tsx` for high-latency protected surfaces.
- Add route-level `error.tsx` with user-safe fallback and retry actions.
- Add `not-found` handling path for out-of-contract route/entity access.
- Define explicit access/permission state handling for protected routes.
- Define explicit empty vs no-results behavior.
- Define explicit mutation pending/success/failure UX contract.

Minimum route coverage (first pass):
- `/admin/dashboard`
- `/admin/topups`
- `/admin/wallet-audit`
- `/admin/reversals`
- `/admin/readiness`
- `/admin/venues`
- `/admin/media`
- `/admin/content/offers`
- `/admin/content/stories`
- `/admin/content/reviews`
- `/admin/config`

Acceptance rule:
- No route should hard-jump from blank to full content without skeleton/fallback state.

### 12.1 Route State Matrix Requirement
Each covered route must document and implement these states:
- loading
- error (recoverable)
- not-found
- access-denied/forbidden
- empty
- no-results
- stale
- unavailable
- mutation-pending
- mutation-success
- mutation-failure

### 12.2 Approved Route State Matrix (UI-B04)

State semantics (normative):

| State | Trigger | UI Contract | Required User Action | Telemetry Marker |
|---|---|---|---|---|
| loading | Route or segment data pending | Skeleton or stable placeholder, no blank screen | None | `route_state_loading` |
| error (recoverable) | Unexpected route-level failure | Error banner/panel with retry action | Retry | `route_state_error` |
| not-found | Invalid/missing entity or segment miss | Not-found message with safe navigation action | Navigate back to valid scope | `route_state_not_found` |
| access-denied/forbidden | RBAC blocks route or action | Redirect to denied surface or inline permission state | Return or switch scope | `route_state_access_denied` |
| empty | Valid read with zero baseline items | Informative empty copy with guidance | Optional create/add action | `route_state_empty` |
| no-results | Filter/search returned no match | Clear no-results copy + reset filter action | Reset filter/search | `route_state_no_results` |
| stale | Cached snapshot older than threshold | Stale indicator + data timestamp | Optional refresh | `route_state_stale` |
| unavailable | Upstream read transport unavailable | Unavailable copy + retry context | Retry/later | `route_state_unavailable` |
| mutation-pending | Command in-flight | Disable conflicting controls, show pending state | Wait or cancel (if supported) | `route_state_mutation_pending` |
| mutation-success | Command completed successfully | Success callout/toast + refreshed read surface | Continue workflow | `route_state_mutation_success` |
| mutation-failure | Command failed validation/transport/policy | Error callout with reason and next action | Correct input or retry | `route_state_mutation_failure` |

Route coverage requirements (first implementation pass):

| Route | loading | error | not-found | access-denied | empty/no-results | stale/unavailable | mutation states | Priority |
|---|---|---|---|---|---|---|---|---|
| `/admin/dashboard` | Required | Required | Optional | Required | Required | Required | N/A | P0 |
| `/admin/topups` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/wallet-audit` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/reversals` | Required | Required | Optional | Required | Optional | Optional | Required | P0 |
| `/admin/readiness` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/venues` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/venues/[venueId]` | Required | Required | Required | Required | Optional | Required | Required | P0 |
| `/admin/media` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/content/offers` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/content/stories` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/content/reviews` | Required | Required | Optional | Required | Required | Required | Required | P0 |
| `/admin/config` | Required | Required | Optional | Required | Optional | Optional | Required | P0 |
| `/admin/sign-in` | Optional | Required | Optional | N/A | N/A | N/A | Required | P1 |
| `/admin/access-denied` | Optional | Optional | Optional | Canonical | N/A | N/A | N/A | P1 |

### 12.3 Dependency and Risk Controls for Implementation

Dependencies:
- UI-B03 implementation follows this matrix and must not redefine state semantics.
- Stream 3 shared components must align to this matrix for read and mutation states.
- Stream 5 telemetry markers must map to section 12.2 state markers.

Primary risks:
- Risk 1: inconsistent inline state handling bypassing route-level contract.
- Risk 2: unauthorized/forbidden surfacing diverges between route redirects and command callouts.
- Risk 3: no-results vs empty state confusion in filter-heavy routes.

Mitigations:
- Keep route guard redirect behavior unchanged during UI-B03 rollout.
- Add route-level boundaries first (`loading.tsx`, `error.tsx`) before refactoring domain internals.
- Use one shared copy standard for empty/no-results distinction per module.
- Validate no regressions in access routing (`/admin/sign-in`, `/admin/access-denied`) after each batch.

## 13. Sidebar Grouping Specification (Phase C)
Target groups:
- المالية:
  - Dashboard
  - Topups
  - Wallet Audit
  - Reversals
  - Readiness
- المحتوى:
  - Venues
  - Media
  - Offers
  - Stories
  - Reviews
- النظام:
  - Config

Behavior requirements:
- Group titles visible and localized.
- Active item and active group must be visually distinct.
- Collapsed behavior for narrow viewports.

### 13.1 UI-C01 and UI-C02 Implementation Closure (UI-016)
Scope:
- Move the sidebar from a flat list into explicit localized groups while preserving RBAC-driven visibility.
- Improve navigation clarity by making route context easier to scan on desktop and mobile.

Changes delivered:
- Added `sidebarGroup` metadata to each admin route and introduced grouped route selector `getVisibleNavigationRouteGroups()`.
- Updated `AdminSidebar` to render grouped navigation sections (`المالية`/`المحتوى`/`النظام`) with active-group highlighting.
- Added route-active prefix matching (`/admin/venues/*` keeps `/admin/venues` active) to improve context continuity for nested admin paths.
- Implemented narrow-viewport collapsible group behavior with explicit `aria-expanded`/`aria-controls` semantics.
- Added focused unit coverage for grouped navigation mapping and ordering invariants.

Validation evidence:
- `npx vitest run lib/navigation/admin-route-map.test.ts lib/auth/rbac-shell.integration.test.ts`
- `npm run build`

Outcome:
- UI-C01 is closed.
- UI-C02 is closed.
- Phase C shell grouping baseline is now implemented and stable.

## 14. Warmup and Prefetch Evaluation Specification
Scope:
- Evaluate current one-time session warmup/prefetch behavior in `admin-shell`.

Checks:
- Number of prefetched routes per session
- Cold-start request burst profile
- SSR concurrency impact on first route and subsequent route transitions
- Any duplicate warmup calls or unnecessary work

Policy requirements:
- Define route-level prefetch mode: `auto`, `hover-intent`, or `disabled`.
- No warmup side-effects are allowed in layout/page render paths.
- Keep warmup calls idempotent and bounded per session.
- Preload order must prioritize currently likely navigation targets.

Acceptance thresholds:
- Warmup must improve first navigation experience without causing route instability or resource contention.
- Any regression in route availability, chunk/css serving, or SSR responsiveness blocks rollout.

Implementation result (UI-017):
- Route-level policy is explicit in the admin route map: `auto`, `hover-intent`, or `disabled`.
- Initial shell prefetch is bounded to 4 auto routes per browser session and excludes the active route.
- Sidebar links opt out of default viewport prefetch; heavier routes use hover/focus intent prefetch instead.
- Server warmup accepts requested route keys but re-filters through RBAC, route policy, and a 4-task default cap (`WAIN_ADMIN_WARMUP_MAX_TASKS`, hard-capped at 6).
- Server warmup is idempotent for repeated requests from the same admin UID using a short in-process dedupe TTL (`WAIN_ADMIN_WARMUP_DEDUPE_TTL_MS`, default 60000ms, capped at 300000ms).
- Validation: targeted warmup/policy/shell tests passed, full admin web Vitest suite passed (53 files, 279 tests), and production build passed.

## 15. Ownership Streams and Dependency Map

Streams:
- Stream 1: Shell and IA (header/sidebar/navigation)
- Stream 2: Foundations (tokens/global styles/RTL logical properties)
- Stream 3: Shared components (`FilterToolbar`, `DataTable`, `StatusBadge`, `ReadStateBanner`, `ActionPanel`)
- Stream 4: Route states (`loading`, `error`, `not-found`, access-denied)
- Stream 5: Performance and telemetry (warmup/prefetch/web vitals)

Critical dependencies:
- Stream 2 blocks Stream 3 styling completion.
- Stream 3 blocks large module migration in Phase E.
- Stream 4 baseline must exist before pilot routes finalize.
- Stream 5 baseline must exist before warmup policy rollout.

## 16. Execution Waves (Operational)

Wave 1:
- Audit matrix, baselines, KPI capture, architectural decisions (`DataTable` mode, route-state matrix).

Wave 2:
- Token schema, shell grouping, route-level loading/error foundation, shared component first implementation.

Wave 3:
- Pilot on 3 representative routes:
  - overview route: `/admin/dashboard`
  - table-heavy route: `/admin/venues` or `/admin/media`
  - command-heavy route: `/admin/config`

Wave 4:
- Scale migration to all in-scope routes, run final gates, and complete release readiness checklist.

## 17. Release Gates (Final)
- All covered routes satisfy section 12 matrix.
- Accessibility and responsive gates pass across covered routes.
- Token migration removes approved repeated hardcoded values in shared styles.
- Warmup/prefetch policy passes stability and performance thresholds.
- Build/test/validation evidence is attached to release notes.

## 18. Session Update Template
Copy this block for every new UI task update:

Date:
Request:
Decision:
Changes:
Files:
Validation:
Outcome:
Next step:

### 18.1 Session Update - UI-003
Date: 2026-04-16
Request: Analyze completed work precisely, identify the next logical step, plan with dependencies/risks, then execute with high precision.
Decision: Execute UI-A01 first to anchor all next implementation decisions to a route-by-route baseline before any broad UI migration.
Changes: Added section 9 route audit matrix for all in-scope admin routes, documented current route-state coverage gaps, and mapped dependencies to streams. Updated changelog and backlog state for UI-A01.
Files: `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Verified route/page files, layout/sidebar behavior, and route-map grouping against current code structure.
Outcome: Baseline audit is now concrete and actionable; phase-level execution can proceed without ambiguity.
Next step: Execute UI-A02 baseline screenshot capture, then use section 9 outputs to finalize UI-B04 route-state matrix approvals.

### 18.2 Session Update - UI-004
Date: 2026-04-16
Request: Analyze what was completed, define the next logical step, plan with dependencies/risks, then execute with high precision and no stability regression.
Decision: Execute UI-B04 as the immediate next step after UI-A01 to lock state semantics before route-level implementation.
Changes: Added section 12.2 approved route-state matrix with state semantics and route coverage; added section 12.3 dependency and risk controls; updated changelog and backlog status for UI-B04.
Files: `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Reconciled matrix decisions against current route guard redirects, route surfaces, and known absence of route-level loading/error files.
Outcome: Route-state contract is now approved and implementation-ready, reducing ambiguity for UI-B03 rollout.
Next step: Start UI-B03 by adding protected admin segment `loading.tsx` and `error.tsx` baselines, then route-specific overrides for high-latency surfaces.

### 18.3 Session Update - UI-005
Date: 2026-04-16
Request: Analyze progress, identify the next logical step, plan with dependencies/risks, then execute carefully without destabilizing existing work.
Decision: Start UI-B03 with a low-risk segment-level baseline (`app/(protected)/admin`) before route-by-route overrides.
Changes: Added protected segment `loading.tsx` and `error.tsx` to provide route-level loading and recoverable error fallback for all protected admin routes.
Files: `wain_app/admin_web_console/app/(protected)/admin/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/error.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Local admin web console build succeeded after adding both files.
Outcome: Route-state rollout moved from planning to implementation with minimal blast radius and preserved access-control behavior.
Next step: Continue UI-B03 with route-specific `loading.tsx` overrides for dashboard and finance/content/media high-latency surfaces.

### 18.4 Session Update - UI-006
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Continue UI-B03 with a second low-risk slice by adding route-specific loading overrides to selected high-priority routes while keeping error handling centralized at segment level.
Changes: Added route-level `loading.tsx` files for `/admin/dashboard`, `/admin/media`, `/admin/content/offers`, and `/admin/content/stories`. Updated changelog/backlog and baseline delta note.
Files: `wain_app/admin_web_console/app/(protected)/admin/dashboard/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/media/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/content/offers/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/content/stories/loading.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Local admin web console production build passed after these additions.
Outcome: UI-B03 progressed from segment-only baseline to mixed segment + route-specific loading coverage with no RBAC or runtime contract regression.
Next step: Continue route-specific coverage for remaining critical routes (`topups`, `wallet-audit`, `readiness`, `reversals`, `venues`, `content/reviews`, `config`) and then assess whether route-level `error.tsx` specialization is needed.

### 18.5 Session Update - UI-007
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Finish route-specific loading coverage for remaining protected routes before considering route-specific error specialization.
Changes: Added route-level `loading.tsx` files for `/admin/topups`, `/admin/wallet-audit`, `/admin/readiness`, `/admin/reversals`, `/admin/venues`, `/admin/venues/[venueId]`, `/admin/content/reviews`, and `/admin/config`. Updated changelog/backlog and delta status.
Files: `wain_app/admin_web_console/app/(protected)/admin/topups/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/wallet-audit/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/readiness/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/reversals/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/venues/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/content/reviews/loading.tsx`, `wain_app/admin_web_console/app/(protected)/admin/config/loading.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Local admin web console production build passed after these additions.
Outcome: Route-specific loading now covers all protected routes in current scope with no RBAC, loader, or transport regressions.
Next step: Evaluate if selected high-risk routes need dedicated route-level `error.tsx` files or if segment-level boundary remains sufficient.

### 18.6 Session Update - UI-008
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Add route-specific error boundaries only for high-risk routes that need context-aware recovery actions while keeping the shared segment boundary intact.
Changes: Added route-level `error.tsx` files for `/admin/topups`, `/admin/config`, and `/admin/venues/[venueId]` with retry plus route-appropriate fallback navigation.
Files: `wain_app/admin_web_console/app/(protected)/admin/topups/error.tsx`, `wain_app/admin_web_console/app/(protected)/admin/config/error.tsx`, `wain_app/admin_web_console/app/(protected)/admin/venues/[venueId]/error.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Local admin web console production build passed after these additions.
Outcome: UI-B03 now includes both full route-specific loading coverage and selective route-specific error specialization for high-risk flows, with no RBAC/data-contract regressions.
Next step: Complete UI-B03 decision pass for remaining routes (keep segment-level error or add custom route-level error only when justified by UX/recovery needs).

### 18.7 Session Update - UI-009
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Close UI-B03 by documenting explicit route-by-route decisions for remaining protected routes to keep segment-level error fallback unless custom recovery is required.
Changes: Added section 12.4 with error-boundary decision matrix; updated changelog/backlog state to mark UI-B03 complete.
Files: `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Decision pass aligned with implemented coverage and previously validated builds.
Outcome: UI-B03 is now formally closed with a stable hybrid error strategy and clear revisit triggers.
Next step: Move to UI-A02 evidence capture and UI-B05 (`display-table` vs `interactive-grid`) decision.

### 18.8 Session Update - UI-010
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Close UI-B05 by formalizing current table-mode architecture as `display-table` baseline, with `interactive-grid` deferred behind explicit adoption gates.
Changes: Added section 10.2 DataTable mode decision pass (criteria, route/module matrix, and implementation gate) and updated changelog/backlog status for UI-B05.
Files: `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Decision matrix reconciled against current table implementations in finance, venues, venue-workspace, media, content, reviews, and config modules.
Outcome: UI-B05 is now formally closed and UI-D03 shared `DataTable` implementation has a clear architectural direction.
Next step: Execute UI-A02 baseline screenshot evidence capture, then start UI-B01 token alignment review.

### 18.9 Session Update - UI-011
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Execute UI-B01 first as a non-invasive architectural review to de-risk UI-B02 token migration.
Changes: Added section 11.1 token alignment review baseline with quantified literal hotspots, dependency map, risk controls, and migration sequence. Updated changelog/backlog status to mark UI-B01 completed.
Files: `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Reviewed current stylesheet token surface and performed search-based checks for color/radius/shadow/layering/focus/motion literal usage.
Outcome: UI-B01 is formally closed, and UI-B02 now has a precise low-risk execution path.
Next step: Execute UI-B02 by introducing the missing token set in `:root` and migrating the highest-repeat literals in controlled batches.

### 18.10 Session Update - UI-012
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Execute UI-B02 batch 1 as the next safe implementation slice (token introduction plus first alias migration) before broader spacing/focus/motion adoption.
Changes: Updated `app/globals.css` to add the missing token families and replace first-wave high-repeat literals (status colors, radius, shadow, z-layer, selected line-height) with semantic token aliases. Updated changelog/backlog and added section 11.2 execution notes.
Files: `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Admin web console production build passed (`npm run build`), and stylesheet diagnostics reported no errors.
Outcome: UI-B02 is now in progress with batch 1 complete and no functional contract regressions observed.
Next step: Execute UI-B02 batch 2 (spacing/control density/focus/motion token adoption + residual literal cleanup), then revalidate and assess UI-B02 closure readiness.

### 18.11 Session Update - UI-013
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Execute UI-B02 batch 2 with a constrained, behavior-preserving scope focused on spacing/control density, focus-visible consistency, and motion-token adoption.
Changes: Updated interactive control groups in `app/globals.css` to use spacing/control-height tokens, added a unified `:focus-visible` rule-set for key controls, and applied tokenized transition timing/easing; logged UI-013 in changelog/backlog and added section 11.3 notes.
Files: `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: CSS diagnostics clean; admin web console production build passed (`npm run build`).
Outcome: UI-B02 remains in progress with batch 2 complete and no stability regressions observed in route/RBAC contracts.
Next step: Execute residual literal sweep and perform final closure readiness check for UI-B02.

### 18.12 Session Update - UI-014
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Execute final residual sweep for spacing literals and close UI-B02 only after passing explicit diagnostic/build/search gates.
Changes: Added missing spacing aliases for repeated residual values and replaced remaining hardcoded spacing literals across shell/layout/control sections in `app/globals.css`; updated changelog/backlog and added section 11.4 closure assessment notes.
Files: `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: CSS diagnostics clean, `npm run build` passed, and targeted spacing-literal grep returned no matches.
Outcome: UI-B02 is now formally closed without behavioral contract changes.
Next step: Start UI-A02 baseline screenshot evidence capture.

### 18.13 Session Update - UI-015
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Execute UI-A02 immediately using an automated browser evidence pass to close the remaining Phase A blocker with deterministic outputs.
Changes: Added the capture command and script (`capture:ui-a02`, `scripts/capture-ui-a02-baseline.mjs`), generated baseline evidence artifacts (`admin_web_console_ui_a02_baseline_capture.json` + `.md`), and saved 15 route screenshots in `docs/release/ui_a02_baseline_screenshots`.
Files: `wain_app/admin_web_console/package.json`, `wain_app/admin_web_console/package-lock.json`, `wain_app/admin_web_console/scripts/capture-ui-a02-baseline.mjs`, `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.json`, `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.md`, `wain_app/docs/release/ui_a02_baseline_screenshots/*.png`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Capture summary reported 15/15 successful routes, 0 guarded-route redirects, 0 failures; `npm run build` passed after changes.
Outcome: UI-A02 is formally closed and Phase A is now closed.
Next step: Start UI-C01 shell navigation clarity improvements.

### 18.14 Session Update - UI-016
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step, plan with dependencies/risks, then execute carefully without harming stability.
Decision: Execute UI-C01 and UI-C02 together in one controlled shell-only slice to deliver grouped navigation clarity without touching RBAC or route guard behavior.
Changes: Added sidebar grouping metadata and grouped selector in the route map, refactored `AdminSidebar` to render localized groups with active-group highlighting and narrow-viewport collapsible behavior, and added focused route-map grouping tests.
Files: `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`, `wain_app/admin_web_console/components/admin/admin-sidebar.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/admin_web_console/lib/navigation/admin-route-map.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run lib/navigation/admin-route-map.test.ts lib/auth/rbac-shell.integration.test.ts` passed and `npm run build` passed.
Outcome: UI-C01 and UI-C02 are formally closed with no RBAC visibility regressions.
Next step: Start UI-W01 warmup/prefetch load impact audit and guardrails.

### 18.15 Session Update - UI-017
Date: 2026-04-16
Request: Continue from the executive summary and close the remaining P0 UI-W01 warmup/prefetch guardrail gap.
Decision: Implement the policy in code rather than leaving UI-W01 as a documentation-only audit, because the existing shell/API behavior had no bounded route policy and could run all warmup loaders concurrently.
Root cause: Warmup was guarded once per browser session, but `AdminShell` prefetched every prioritized visible route, sidebar links still allowed default viewport prefetch, and `/api/admin/warmup` executed every accessible warmup task with `Promise.all` and no server-side duplicate guard.
Changes: Added route-level prefetch modes, introduced `admin-warmup-policy` for bounded auto prefetch and server warmup route selection, disabled default sidebar viewport prefetch while adding hover/focus intent for heavier routes, bounded the warmup API to requested auto routes, and added per-admin dedupe.
Files: `wain_app/admin_web_console/lib/navigation/admin-contract.ts`, `wain_app/admin_web_console/lib/navigation/admin-route-map.ts`, `wain_app/admin_web_console/lib/navigation/admin-warmup-policy.ts`, `wain_app/admin_web_console/components/admin/admin-shell.tsx`, `wain_app/admin_web_console/components/admin/admin-sidebar.tsx`, `wain_app/admin_web_console/app/api/admin/warmup/route.ts`, `wain_app/admin_web_console/lib/admin/admin-warmup-dedupe.ts`, `wain_app/admin_web_console/lib/navigation/admin-warmup-policy.test.ts`, `wain_app/admin_web_console/components/admin/admin-shell.test.tsx`, `wain_app/admin_web_console/lib/admin/warmup-route.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: Targeted warmup/policy/shell tests passed, `npx tsc --noEmit --pretty false` passed, full `npm test` passed (53 files, 279 tests), and `npm run build` passed.
Outcome: UI-W01 is formally closed with bounded warmup/prefetch guardrails and no RBAC visibility contract changes.
Next step: Start UI-D01 shared `ReadStateBanner` component.

### 18.16 Session Update - UI-018
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step with dependency/risk planning, then execute carefully without destabilizing previous UI work.
Decision: Start Stream 3 with UI-D01 because `ReadStateBanner` is the lowest-risk shared component and normalizes existing read-state surfaces before table/filter/action abstractions.
Root cause: Finance and venue modules already rendered stale/unavailable/fresh read-state banners with near-identical structure and copy conventions, but the pattern was duplicated and not anchored to the shared component contract.
Changes: Added `components/shared/read-state-banner.tsx` with explicit fresh/stale/empty/unavailable states, added focused component tests, and migrated finance, venue directory, and venue workspace read banners to wrap the shared component while preserving current page APIs and test ids.
Files: `wain_app/admin_web_console/components/shared/read-state-banner.tsx`, `wain_app/admin_web_console/components/shared/read-state-banner.test.tsx`, `wain_app/admin_web_console/components/finance/finance-read-banner.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-read-banner.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-read-banner.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/shared/read-state-banner.test.tsx components/finance/finance-read-states.test.tsx components/venues/venue-directory-shell.test.tsx components/venue-workspace/venue-workspace-shell.test.tsx` passed and `npx tsc --noEmit --pretty false` passed.
Outcome: UI-D01 is formally closed for the first shared-component slice without loader, RBAC, or route-flow changes.
Next step: Start UI-D02 shared `FilterToolbar` component.

### 18.17 Session Update - UI-019
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step with dependency/risk planning, then execute carefully without destabilizing previous UI work.
Decision: Continue Stream 3 with UI-D02 because filter rows are repeated across table-heavy admin routes and should be normalized before DataTable extraction.
Root cause: Venue, media, content, and review modules each carried near-identical filter row markup and control styling, which made spacing, focus behavior, and responsive wrapping easy to drift across routes.
Changes: Added shared filter toolbar primitives, migrated existing filter rows in venue directory, media center, offers, stories, and review moderation shells, and added general CSS aliases while preserving legacy class hooks and all existing test ids.
Files: `wain_app/admin_web_console/components/shared/filter-toolbar.tsx`, `wain_app/admin_web_console/components/shared/filter-toolbar.test.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/offers-management-shell.tsx`, `wain_app/admin_web_console/components/content/stories-management-shell.tsx`, `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/shared/filter-toolbar.test.tsx components/venues/venue-directory-shell.test.tsx components/media/media-center-shell.test.tsx components/content/content-management-shells.test.tsx components/reviews/review-moderation-shell.test.tsx` passed (5 files, 37 tests), `npx tsc --noEmit --pretty false` passed, full `npm test` passed (55 files, 285 tests), and `npm run build` passed.
Outcome: UI-D02 is formally closed without loader, RBAC, filtering semantics, or command-flow changes.
Next step: Start UI-D03 shared `DataTable` component.

### 18.18 Session Update - UI-020
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step with dependency/risk planning, then execute carefully without destabilizing previous UI work.
Decision: Continue Stream 3 with UI-D03 because `ReadStateBanner` and `FilterToolbar` are already stable, and all table-heavy routes share the same `table-scroll`/`data-table` structure approved by UI-B05 as `display-table`.
Root cause: Table wrappers were duplicated across finance, config, venues, media, content, and reviews even though all current routes use native semantic tables and do not need the deferred `interactive-grid` mode.
Changes: Added shared `DataTable`, migrated existing table wrappers only, preserved row/cell markup and test ids, added shared CSS hooks, and stabilized one finance transport test timeout that was flaky under full-suite parallel load.
Files: `wain_app/admin_web_console/components/shared/data-table.tsx`, `wain_app/admin_web_console/components/shared/data-table.test.tsx`, `wain_app/admin_web_console/components/finance/topup-queue-table.tsx`, `wain_app/admin_web_console/components/finance/wallet-audit-table.tsx`, `wain_app/admin_web_console/components/config/config-governance-shell.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/offers-management-shell.tsx`, `wain_app/admin_web_console/components/content/stories-management-shell.tsx`, `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/admin_web_console/lib/finance/finance-read-snapshot-transport.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/shared/data-table.test.tsx components/finance/finance-surfaces.test.tsx components/finance/finance-read-states.test.tsx components/config/config-governance-shell.test.tsx components/venues/venue-directory-shell.test.tsx components/venue-workspace/venue-workspace-shell.test.tsx components/media/media-center-shell.test.tsx components/content/content-management-shells.test.tsx components/reviews/review-moderation-shell.test.tsx` passed (9 files, 65 tests), `npx tsc --noEmit --pretty false` passed, full `npm test` passed (56 files, 287 tests), and `npm run build` passed.
Outcome: UI-D03 is formally closed without loader, RBAC, table semantics, row action, or route-flow changes.
Next step: Start UI-D04 shared `StatusBadge` component.

### 18.19 Session Update - UI-021
Date: 2026-04-16
Request: Analyze completed work, identify the next logical step with dependency/risk planning, then execute carefully without destabilizing previous UI work.
Decision: Continue Stream 3 with UI-D04 because all table/filter/read components are already shared and status chips were the highest remaining duplicated UI primitive across command and read surfaces.
Root cause: Status and runtime badges were duplicated in finance/config/venues/media/content/reviews/workspace modules using repeated `status-pill` markup, which increased drift risk for visual semantics and test hooks.
Changes: Added shared `StatusBadge` plus focused tests, migrated all direct `status-pill` usage in module components to `StatusBadge`, and preserved status text mapping, `data-testid` hooks, and RBAC/loader/command contracts.
Files: `wain_app/admin_web_console/components/shared/status-badge.tsx`, `wain_app/admin_web_console/components/shared/status-badge.test.tsx`, `wain_app/admin_web_console/components/finance/topup-queue-table.tsx`, `wain_app/admin_web_console/components/finance/wallet-audit-table.tsx`, `wain_app/admin_web_console/components/finance/readiness-panel.tsx`, `wain_app/admin_web_console/components/finance/reversal-approval-panel.tsx`, `wain_app/admin_web_console/components/config/config-governance-shell.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/offers-management-shell.tsx`, `wain_app/admin_web_console/components/content/stories-management-shell.tsx`, `wain_app/admin_web_console/components/content/content-action-cell.tsx`, `wain_app/admin_web_console/components/reviews/review-moderation-shell.tsx`, `wain_app/admin_web_console/components/reviews/review-action-cell.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-shell.tsx`, `wain_app/admin_web_console/components/venue-workspace/venue-workspace-header.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx tsc --noEmit --pretty false` passed, full `npm test` passed (57 files, 289 tests), and `npm run build` passed.
Outcome: UI-D04 is formally closed without behavior regressions in route-state, RBAC, command execution, or read-surface semantics.
Next step: Start UI-D05 shared `ActionPanel` component.

### 18.20 Session Update - UI-022
Date: 2026-04-17
Request: Continue to the next UI stream step at the same execution pace after closing UI-D04.
Decision: Execute UI-D05 now because command-zone wrappers remained the primary duplicated shared-UI pattern after `ReadStateBanner`, `FilterToolbar`, `DataTable`, and `StatusBadge` closures.
Root cause: Media/content/review/config/venue command zones repeated stack/item/header/message wrappers with module-specific markup, increasing drift risk in runtime status presentation and disabled-reason callouts.
Changes: Added shared action panel primitives and migrated command-zone wrappers to `ActionPanel` slots while preserving existing CSS hooks (`media-action-*`, `venue-action-*`), runtime labels, and test ids.
Files: `wain_app/admin_web_console/components/shared/action-panel.tsx`, `wain_app/admin_web_console/components/shared/action-panel.test.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/content/content-action-cell.tsx`, `wain_app/admin_web_console/components/reviews/review-action-cell.tsx`, `wain_app/admin_web_console/components/config/config-governance-shell.tsx`, `wain_app/admin_web_console/components/venues/venue-directory-shell.tsx`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/shared/action-panel.test.tsx components/media/media-center-shell.test.tsx components/content/content-management-shells.test.tsx components/reviews/review-moderation-shell.test.tsx components/config/config-governance-shell.test.tsx components/venues/venue-directory-shell.test.tsx` passed (6 files, 43 tests), `npx tsc --noEmit --pretty false` passed, full `npm test` passed (58 files, 291 tests), and `npm run build` passed.
Outcome: UI-D05 is formally closed without RBAC, loader, transport, or route-flow regressions.
Next step: Start UI-E01 pilot rollout on representative routes.

### 18.21 Session Update - UI-023
Date: 2026-04-17
Request: Continue to the next execution step after UI-D05 at the same delivery pace.
Decision: Close UI-E01 through evidence-first pilot verification on representative routes rather than introducing new route code, because Stream 3 shared-component rollout was already complete.
Root cause: The remaining gap after UI-D05 was not component duplication; it was unclosed pilot evidence for the approved Wave 3 routes (`/admin/dashboard`, `/admin/venues`, `/admin/config`).
Changes: Executed pilot-focused validation on dashboard/venues/config route surfaces and recorded closure evidence in the master plan backlog and change log.
Files: `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/dashboard/operational-dashboard-shell.test.tsx components/venues/venue-directory-route.test.tsx components/venues/venue-directory-shell.test.tsx components/config/config-governance-route.test.tsx components/config/config-governance-shell.test.tsx` passed (5 files, 22 tests), and `npm run build` passed.
Outcome: UI-E01 is formally closed with representative-route pilot evidence and no regressions observed in route-state, RBAC, or build stability.
Next step: Start UI-P01 polish/micro-interaction pass.

### 18.22 Session Update - UI-024
Date: 2026-04-17
Request: Continue immediately after UI-E01 and execute the post-pilot UI polish pass with the same pace and safety guarantees.
Decision: Execute UI-P01 as a CSS-only micro-interaction sweep because functional contracts were already stable and the remaining gap was visual/interaction refinement quality.
Root cause: After Stream 3 + pilot closure, interaction feedback across nav/actions/tabs/table scan surfaces was consistent functionally but still lacked a unified polish layer (subtle hover/active cues + reduced-motion explicitness).
Changes: Updated `app/globals.css` with conservative hover/active transitions for nav links, shell buttons, action buttons, tabs, command/summary cards, and table rows, plus a reduced-motion safeguard for interactive surfaces.
Files: `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx tsc --noEmit --pretty false` passed, full `npm test` passed (58 files, 291 tests), and `npm run build` passed.
Outcome: UI-P01 is formally closed with no RBAC/loader/transport/route regressions.
Next step: Prepare post-polish browser smoke evidence refresh.

### 18.23 Session Update - UI-025
Date: 2026-04-17
Request: Execute the next step immediately by refreshing browser smoke evidence after UI-P01 polish.
Decision: Re-run deterministic browser route capture across all in-scope admin routes and close the pending post-polish evidence refresh item.
Root cause: UI-P01 delivered CSS-only interaction refinements, so the remaining operational gap was evidence freshness confirming protected-route rendering and guard behavior post-polish.
Changes: Started admin web dev server with explicit development admin session env, executed `npm run capture:ui-a02`, refreshed route capture artifacts (`json`/`md`/screenshots), and added a dedicated run note for this post-polish smoke round.
Files: `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.json`, `wain_app/docs/release/admin_web_console_ui_a02_baseline_capture.md`, `wain_app/docs/release/ui_a02_baseline_screenshots/*.png`, `wain_app/docs/release/admin_web_console_ui_post_polish_smoke_ui_025.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npm run capture:ui-a02` passed with `ok: true` (`15/15` successful, `0` redirects, `0` failures).
Outcome: UI-P02 (post-polish evidence refresh) is formally closed with no regression signal in protected-route access behavior.
Next step: Resume the next UI stream candidate or run visual diff triage if required.

### 18.24 Session Update - UI-026
Date: 2026-04-17
Request: Continue after UI-P02 by selecting and executing the next safe UI backlog step.
Decision: Execute UI-P03 as an evidence-only visual diff triage pass before opening any new product-facing UI surface changes.
Root cause: After UI-P02 route-capture refresh, the remaining quality gap was artifact drift triage (what changed in screenshots) rather than route-state or RBAC behavior.
Changes: Added `scripts/triage-ui-a02-visual-diff.mjs`, wired `capture:ui-a02:triage` in `package.json`, and generated JSON/Markdown triage artifacts for 15 captured routes.
Files: `wain_app/admin_web_console/scripts/triage-ui-a02-visual-diff.mjs`, `wain_app/admin_web_console/package.json`, `wain_app/docs/release/admin_web_console_ui_visual_diff_triage_ui_026.json`, `wain_app/docs/release/admin_web_console_ui_visual_diff_triage_ui_026.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npm run capture:ui-a02:triage` passed (`15` entries, `0` critical, `15` review findings classified as `new-file` due missing `HEAD` screenshot artifacts).
Outcome: UI-P03 is formally closed with a repeatable visual triage workflow and no critical drift signal.
Next step: Select the next product-facing UI candidate for implementation.

### 18.25 Session Update - UI-027
Date: 2026-04-17
Request: Choose the next stream after closing UI-P03.
Decision: Select `UI-M01` (Media visual preview/viewer baseline) as the next product-facing implementation stream.
Root cause: The highest-impact unresolved product UI gap remains Phase 4 media preview/viewer completeness, while current transport/governance contracts are already stable enough to support a read-only viewer slice.
Changes: Updated the UI master plan changelog/backlog with the selected stream and aligned the execution handoff.
Files: `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`, `wain_app/docs/release/admin_web_console_progress_tracker.md`
Validation: Decision cross-checked against documented open follow-ups in the release progress tracker.
Outcome: Next stream is fixed and implementation-ready (`UI-M01`).
Next step: Start UI-M01 implementation slice 1 (read-only media preview/viewer flow).

### 18.26 Session Update - UI-028
Date: 2026-04-17
Request: Execute the 4-step UI-M01 slice 1 plan (preview affordance, viewer surface, contract safety, and full validation).
Decision: Implement `UI-M01` as a read-only viewer slice inside Media Center without introducing any new mutation contracts.
Root cause: Phase 4 follow-up still had a product-facing visual gap (`preview/viewer بصري كامل`) even though governed media actions and transport contracts were already stable.
Changes: Added row-level preview buttons and modal viewer in `components/media/media-center-shell.tsx`, added viewer styles in `app/globals.css`, preserved `mediaUrl` in media baseline/model (`lib/media/media-center-models.ts`, `lib/media/media-center-baseline.ts`), and extended media tests to cover preview behavior.
Files: `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/admin_web_console/lib/media/media-center-models.ts`, `wain_app/admin_web_console/lib/media/media-center-baseline.ts`, `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`, `wain_app/admin_web_console/components/media/media-center-route.test.tsx`, `wain_app/admin_web_console/lib/media/media-center-baseline.test.ts`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/media/media-center-shell.test.tsx components/media/media-center-route.test.tsx lib/media/media-center-baseline.test.ts` passed (3 files, 21 tests); full `npm test` passed (58 files, 293 tests); `npm run build` passed.
Outcome: UI-M01 slice 1 is formally closed with read-only preview/viewer functionality and no RBAC/command-regression signal.
Next step: Select next product-facing UI candidate (UI-M01 slice 2 or another follow-up stream).

### 18.27 Session Update - UI-029
Date: 2026-04-17
Request: Execute UI-M01 slice 2 immediately with the approved 3-step scope (replace workflow UX + validation, no RBAC/contract expansion, full validation/build).
Decision: Implement replace as a UI draft-only workflow in Media Center because no governed backend replace command exists in current media command contracts.
Root cause: Phase 4 follow-up still had a high-impact operator gap for replacement preparation, but contract-safe execution required avoiding any new backend mutation surface.
Changes: Added row-level `استبدال الأصل` launcher, modal replace dialog, URL/reason validation, draft payload generation, clipboard copy fallback messaging, and supporting styles/tests in Media Center shell.
Files: `wain_app/admin_web_console/components/media/media-center-shell.tsx`, `wain_app/admin_web_console/components/media/media-center-shell.test.tsx`, `wain_app/admin_web_console/app/globals.css`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`
Validation: `npx vitest run components/media/media-center-shell.test.tsx components/media/media-center-route.test.tsx lib/media/media-center-baseline.test.ts` passed (3 files, 23 tests); full `npm test` passed (58 files, 295 tests); `npm run build` passed.
Outcome: UI-M01 slice 2 is formally closed with contract-safe replace draft UX and explicit validation/copy guidance, with no RBAC/transport contract drift.
Next step: Move to remaining Phase 4 follow-up evidence (live staging smoke for media transport surfaces).

### 18.28 Session Update - UI-030
Date: 2026-04-17
Request: Close the remaining Phase 4 follow-up by rerunning live staging smoke for media transport surfaces with valid runtime authentication context.
Decision: Finalized UI-030 as closed after the authenticated callable probe sweep returned full `HTTP 200` coverage without App Check failures.
Root cause: Earlier UI-030 runs were blocked by placeholder App Check runtime token quality, not missing endpoints (`0` HTTP 404).
Changes: Updated the temporary authenticated probe runner in `.tmp` for governed media command payloads and stable auth claims, executed the final staging rerun, refreshed JSON evidence, and synchronized release tracker/master plan records.
Files: `wain_app/.tmp/probe_media_transport_authenticated.js`, `wain_app/docs/release/admin_web_console_media_transport_smoke_ui_030.json`, `wain_app/docs/release/admin_web_console_media_transport_smoke_ui_030.md`, `wain_app/docs/release/admin_web_console_ui_improvement_master_plan.md`, `wain_app/docs/release/admin_web_console_progress_tracker.md`
Validation: `node .tmp/probe_media_transport_authenticated.js > docs/release/admin_web_console_media_transport_smoke_ui_030.json` completed; summary = `6` probes, `6` HTTP 200, `0` `App Check verification failed`, `0` HTTP 404 (artifact timestamp `2026-04-17T00:30:57.254Z`).
Outcome: Follow-up is closed (`FOLLOW_UP_CLOSED`) for UI-030; media transport staging smoke no longer carries an operational blocker.
Next step: Continue with the next product-facing UI backlog candidate.
