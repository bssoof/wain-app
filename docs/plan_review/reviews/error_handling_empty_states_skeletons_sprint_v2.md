# Error Handling + Empty States + Skeletons Sprint Plan (V2)

## 1) Decision
- Verdict: `Go with changes`
- Why: high UX impact, low product risk, but scope must be narrowed to avoid a 2-week spillover.

## 2) Goal
Ship a stable and consistent user experience for `loading`, `error`, and `empty` states on high-traffic screens, with unified exception handling from repositories to UI.

## 3) Scope
### Scope In (Sprint)
- Error handling standardization for:
  - `lib/features/reviews/data/repositories/reviews_repository_impl.dart`
  - `lib/features/favorites/data/repositories/favorites_repository_impl.dart`
  - `lib/features/offers/data/repositories/saved_offers_repository_impl.dart`
- Shared UI components:
  - `lib/core/widgets/app_error_widget.dart` (new)
  - `lib/core/widgets/app_empty_state.dart` (new)
  - `lib/core/widgets/app_skeleton.dart` (new)
- Screen integration:
  - `lib/features/venue/presentation/screens/venue_details_screen.dart`
  - `lib/features/discovery/presentation/screens/results_screen.dart`
  - `lib/features/favorites/presentation/screens/favorites_screen.dart`
  - `lib/features/offers/presentation/screens/saved_offers_screen.dart`

### Scope Out (This Sprint)
- OCR/Gemini/menu import quality work.
- Routing changes.
- Map/offers backend changes.
- Global redesign of all screens.

## 4) Constraints and Guardrails
- No raw exceptions shown to users.
- No English raw error text in user-facing UI.
- Retry action only for retryable failures.
- Keep behavior backward-compatible (no breaking auth/menu flows).
- Prefer l10n keys for UI strings; avoid hardcoded Arabic/English in new UI widgets.

## 5) Phase Plan (14 days)

### Phase 0 (Day 1): Baseline and safety gates
- Confirm current exception model in:
  - `lib/core/errors/app_exceptions.dart`
- Add/confirm repository-level exception mapping policy:
  - Repositories throw `AppException` only.
  - Unknown exceptions are wrapped to `ServerException` or `NetworkException`.
- Add test gate:
  - `flutter analyze` must stay clean.
  - Targeted tests for changed modules must pass.

Done when:
- A short checklist exists in PR description: "No raw throw to UI".

### Phase 1 (Days 2-6): Repository hardening (Must)
- Apply `try/catch + map to AppException` in 3 repositories:
  - reviews
  - favorites
  - saved offers
- Ensure no `rethrow` of raw platform exceptions to presentation layer.
- Add unit tests for each repository:
  - network failure -> `NetworkException`
  - server failure -> `ServerException`/feature-specific exception
  - local/cache failure (where relevant) -> `CacheException`

Done when:
- All 3 repositories only expose `AppException` on failure paths.
- Unit tests cover failure mapping.

### Phase 2 (Days 7-10): Shared UI states (Must)
- Build reusable widgets:
  - `AppErrorWidget(exception, onRetry?)`
  - `AppEmptyState(icon, title, subtitle, ctaText?, onCta?)`
  - `AppSkeleton` variants:
    - venue/details skeleton
    - list/card skeleton
    - menu item skeleton
- Add consistent visual contract:
  - icon + message + CTA pattern
  - compact spacing for mobile

Done when:
- Widgets are reusable and used by at least 3 screens.

### Phase 3 (Days 11-13): Integrate on priority screens (Must)
- Integrate on:
  - venue details
  - discovery results
  - favorites
  - saved offers
- Replace direct raw error text with `AppErrorWidget`.
- Replace blank states with `AppEmptyState`.
- Replace loading spinners on list/detail surfaces with skeletons (keep spinner where skeleton is not practical).

Done when:
- Priority screens have consistent loading/error/empty behavior.

### Phase 4 (Day 14): QA and release decision
- Manual QA script (Arabic locale first):
  - offline scenario
  - empty result scenario
  - deleted/missing entity scenario
  - retry flow
- Capture logs and verify no raw exception leaks to UI.

Done when:
- All acceptance criteria pass.

## 6) Acceptance Criteria
- `flutter analyze` passes with no new issues.
- Changed tests pass.
- No user-facing raw exception text in scoped screens.
- All scoped repositories map failures to `AppException`.
- Scoped screens render:
  - skeleton while loading
  - `AppErrorWidget` on errors
  - `AppEmptyState` on empty data

## 7) KPIs (Sprint-level)
- Crash-free sessions: no regression from current baseline.
- "Raw error visible to user" incidents: `0` in QA checklist.
- Empty screens without guidance CTA on scoped screens: `0`.
- Retry success rate for retryable errors: tracked and reviewed.

## 8) Risks and Mitigation
- Risk: scope creep across all repositories.
  - Mitigation: lock to 3 repositories only in this sprint.
- Risk: localization inconsistency.
  - Mitigation: all new user text goes through l10n workflow.
- Risk: visual regressions.
  - Mitigation: widget tests + focused manual QA script.

## 9) Next Sprint (Not in this scope)
- Extend pattern to:
  - `try_list_repository_impl.dart`
  - `navigation_repository_impl.dart`
  - remaining screens with inconsistent states.
- Add dashboard/report for error categories and retry outcomes.

