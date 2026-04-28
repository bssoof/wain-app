# Admin Web Console - Phase 3 Acceptance Record

Document ID: AWC-P3-AR
Round: AWC-P3-03
Decision date: 2026-04-10
Scope: Phase 3 closure for Venue Directory + Venue Workspace Core only
Implementation status: accepted with follow-up

## 1. Final Phase 3 Verdict

Verdict: accepted with follow-up
Phase 3 state: closure accepted for the read-only Venue Directory and Venue Workspace baseline, with explicit follow-up items that do not block opening Phase 4.

Rationale:
- The Venue Directory is no longer a placeholder. It supports operational search/filtering and exposes readiness, wallet, and merchant-link summaries with explicit `empty`, `stale`, and `unavailable` states.
- The Venue Workspace shell exists with read-only core tabs for:
  - wallet
  - offers
  - stories
  - reviews
- Phase 3 hardening is in place:
  - Venue Directory now surfaces bounded callable scan budget and truncation honesty.
  - Venue Workspace now uses a real admin callable where available and falls back with source labeling instead of pretending to be live data.
- Remaining gaps are real but non-blocking for Phase 3 closure:
  - Venue Directory still relies on bounded geo-search rather than a dedicated admin directory read model.
  - Cursor/load-more UI is not exposed yet, only scan-budget honesty.
  - Workspace remains intentionally read-only; no Phase 4/5 actions are implemented.

## 2. Phase 3 Acceptance Checklist

Reference: `docs/release/admin_web_console_execution_plan.md` -> `Phase 3 - Venue Lookup / Workspace Core`

| Criterion | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Venue Directory is operational and no longer placeholder-only | accepted | `admin_web_console/app/(protected)/admin/venues/page.tsx`; `components/venues/venue-directory-shell.tsx`; tracker entries `021`, `022`, `023` | real search/filter/read summaries are present |
| Search by venue name is available | accepted | `venue-directory-shell.tsx`; component tests | verified via filter test coverage |
| City/category filtering is available when data exists | accepted | `venue-directory-shell.tsx`; `venue-directory-shell.test.tsx` | filters are data-driven |
| Directory shows readiness / wallet / merchant-link summaries | accepted | `venue-directory-read-loader.ts`; `venue-directory-shell.tsx` | summaries are explicit per row and in aggregate cards |
| Workspace route exists and loads from directory navigation | accepted | `app/(protected)/admin/venues/[venueId]/page.tsx`; route tests | `Open workspace` links are verified |
| Workspace core tabs (`wallet`, `offers`, `stories`, `reviews`) are present and read-only | accepted | `components/venue-workspace/venue-workspace-shell.tsx`; shell tests | no mutation controls were added |
| Source/freshness/empty/unavailable states are explicit across directory and workspace | accepted | read banners, route tests, loader tests | no silent success fallback remains |
| Server-backed reads are used where available | accepted with follow-up | `functions/src/index.ts` callable `getAdminVenueWorkspaceReadBundle`; `venue-workspace-read-loader.ts`; `venue-directory-read-loader.ts` | workspace now uses a real admin callable; directory still uses bounded `searchVenuesInBounds` rather than a dedicated admin read-model surface |
| Pagination/cursor behavior is operationally honest | accepted with follow-up | `venue-directory-read-loader.ts`; `venue-directory-shell.tsx`; loader/shell tests | scan budget and truncation are surfaced, but operator-facing load-more/pagination controls are not implemented yet |

## 3. Implemented Scope (Phase 3)

- Venue Directory:
  - `admin_web_console/app/(protected)/admin/venues/page.tsx`
  - `admin_web_console/components/venues/*`
  - `admin_web_console/lib/venues/venue-directory-*`
- Venue Workspace shell:
  - `admin_web_console/app/(protected)/admin/venues/[venueId]/page.tsx`
  - `admin_web_console/components/venue-workspace/*`
  - `admin_web_console/lib/venues/venue-workspace-*`
- Phase 3 hardening:
  - bounded callable scan budget surfaced in `venue-directory-read-loader.ts`
  - real workspace callable in `functions/src/index.ts`
  - real workspace callable consumption in `venue-workspace-read-loader.ts`
  - targeted emulator coverage in `functions/test/emulator/securityCallableFlows.test.js`

## 4. Verified Evidence

### Backend verification

- `cd wain_app/functions && npm run build`
  - Result: passed
- Emulator subset verification:
  - `W45`
  - `W45b`
  - `W46`
  - `W53`
  - `W54`
  - Result: `5/5` passed

### Admin web verification

- `cd wain_app/admin_web_console && npm test`
  - Result: passed
  - Latest verified count in this round: `108/108`
- `cd wain_app/admin_web_console && npm run build`
  - Result: passed

## 5. Explicit Gaps Still Not Closed

The following gaps remain visible and intentionally are not hidden:

- Venue Directory does not yet use a dedicated admin directory callable/read-model with richer merchant-link and wallet summary semantics.
- Directory scan pagination is honest but not interactive yet; operators do not have explicit cursor/load-more controls.
- Workspace tabs are read-only by design in this phase; no media/moderation/write flows are included.
- `hours`, `menu`, and `analytics` tabs are not part of the implemented Phase 3 core shell.

## 6. Follow-up Items Before/Alongside Phase 4

| Item ID | Follow-up | Owner role | Target phase | Status |
| --- | --- | --- | --- | --- |
| P3-F01 | Add a dedicated admin venue directory read surface or read model to replace bounded geo-search as the primary admin source | Backend Lead | Phase 3 follow-up / Phase 4 prep | open |
| P3-F02 | Add operator-facing cursor/load-more pagination to Venue Directory while preserving the current scan budget honesty | Web Engineering Lead | Phase 3 follow-up / Phase 4 prep | open |
| P3-F03 | Expand workspace tabs beyond the read-only core only when Phase 4/5 surfaces are explicitly opened | Product + Web Lead | Future phases | open |

## 7. Closure Statement

Phase 3 is formally closed as `accepted with follow-up`.

This closure confirms:
- Venue lookup and workspace core surfaces are implemented and test-covered.
- Read-only boundaries are preserved.
- Source honesty and stale/unavailable handling are explicit enough to move forward.
- Remaining work is operational hardening and later-phase expansion, not a hidden implementation failure.
