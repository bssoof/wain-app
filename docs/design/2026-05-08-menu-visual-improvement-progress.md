# Menu Visual Improvement Progress Tracker - 2026-05-08

Purpose: single tracking file for the customer-facing venue menu visual improvement work. Update this file after each ticket or meaningful implementation step so the current state is clear without rereading the full plan or chat history.

Primary plan: `docs/design/2026-05-08-menu-visual-improvement-plan.md`

## Current Status

Overall status: `in_progress`

Completed through: `Ticket 9 + menu simplification/stabilization follow-ups`

Next planned ticket: `Manual Android smoke test for updated menu and Firebase DebugView verification`

Current implementation stance:

- Keep Phase 1 schema-free.
- Do not add dependencies unless explicitly approved.
- Preserve existing search, category navigation, details sheet behavior, and legacy image fallback.
- Keep normal item rows compact.
- Keep featured surfaces capped and client-only in Phase 1.

## Ticket Status

| Ticket | Status | Notes |
| --- | --- | --- |
| Ticket 0A - Product decisions and measurement baseline | `partially_done` | Plan updated with baseline analytics, featured governance, currency display, above-the-fold contract, and rollout/KPI assumptions. No analytics baseline implementation yet. |
| Ticket 0B - Technical prep and refactor | `done` | Details sheet extracted, currency helper added, section icon mapping added, image test helper added, RTL widget-test convention started. |
| Ticket 1 - Menu item visual refresh | `done` | `VenueMenuItemTile` refreshed with localized price, featured badge, improved image/no-image handling, category placeholders, and RTL/image/currency tests. |
| Ticket 2 - Header and section icon mapping | `done` | `VenueMenuHeader` refreshed as compact full-width surface. Section headers now render safe icons from `section.icon` or `section.id`. |
| Ticket 3 - Category chips redesign | `done` | Sticky category chips now render safe icons, improved selected/unselected styling, RTL coverage, and selection update coverage. |
| Ticket 4 - Section header refresh | `done` | Section headers now use clearer collapsed/expanded surfaces while preserving icon, chevron, and count-preview badge semantics. |
| Ticket 5 - Featured row integration | `done` | Featured preview and full-menu strip are wired. Full-menu strip stays search-hidden, thresholded at 3+, and capped at 8. |
| Ticket 6 - Details sheet visual refresh | `done` | Visual refresh complete with palette, featured badge, localized price, category-aware placeholder, and RTL tests. |
| Ticket 7 - Legacy image gallery and preview card | `done` | Legacy menu images now render as a named section, image-only menus use the gallery as primary content, and preview cards show image thumbnails. |
| Ticket 8 - Analytics wiring and pilot | `done` | Menu analytics events are wired for impressions, item opens, search, category selection, image opens, and no-interaction timeout. KPI claims still require baseline/pilot data. |
| Ticket 9 - QA, performance, and release | `partially_done` | Automated QA/analyze pass, 300-item stress coverage added, and Android release appbundle builds. Manual Android smoke test and Firebase DebugView verification remain. |

## Completed Work Log

### 2026-05-08 - Plan Hardening

Outcome:

- Updated the base menu visual improvement plan to V2.1.
- Incorporated evaluation feedback around baseline analytics, featured governance, currency display, RTL/golden readiness, above-the-fold measurement, and low-end Android performance risk.

Key files:

- `docs/design/2026-05-08-menu-visual-improvement-plan.md`
- `plans/menu-visual-improvement-plan-evaluation.md`

Notes:

- Featured governance defaults: preview-first, full-menu compact strip only with 3+ featured items, display cap 8, client-only enforcement in Phase 1.
- If no comparable analytics baseline exists, KPI evaluation requires a 7-14 day baseline period before claiming success or failure.

### 2026-05-08 - Ticket 0B Technical Prep

Outcome:

- Extracted item details bottom sheet from `VenueMenuTab` into a dedicated widget.
- Added reusable currency display helpers.
- Added safe menu section icon mapping.
- Added deterministic image HTTP override helper for `CachedNetworkImage` widget tests.
- Added baseline RTL and image-related widget coverage.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/helpers/test_image_http_overrides.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- Limited `flutter analyze` on affected files

Status: passed at time of execution.

### 2026-05-08 - Ticket 1 Menu Item Visual Refresh

Outcome:

- Refreshed `VenueMenuItemTile` only.
- Kept item row compact and preserved tap behavior.
- Replaced split price/currency display with `formatVenueMenuPriceWithCurrency(...)`.
- Added Arabic featured badge `مميز` when `item.isFeatured == true`.
- Improved no-image placeholder surface and category icon handling.
- Expanded icon mapping for common category ids such as `hot_drinks`, `desserts`, and `main_courses`.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- Limited `flutter analyze` on affected files

Status: passed at time of execution.

Implementation note:

- A temporary test compile issue caused by a `const` wrapper around a dynamic `for` collection was fixed during implementation.

### 2026-05-08 - Ticket 2 Menu Header and Section Icons

Outcome:

- Refreshed `VenueMenuHeader` into a compact full-width surface with icon badge, title, and count badge.
- Preserved the existing `VenueMenuHeader` public API: `itemCount` and `counterLabel`.
- Added section icon rendering inside `VenueMenuSectionBlock`.
- Icon source rule: use `section.icon` when explicitly set; if empty or default `restaurant_menu`, use `section.id`; unknown values fall back to `Icons.restaurant_menu_rounded`.
- Preserved expand/collapse behavior, show all/show less behavior, and progress/count badge meaning.
- Did not redesign category chips.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_section.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart`

Status: passed at time of execution.

### 2026-05-09 - Ticket 3 Category Chips Redesign

Outcome:

- Refreshed `VenueMenuCategoryChips` without changing its public API.
- Added icons inside chips: `Icons.apps_rounded` for `all`, and safe mapped section icons for real sections.
- Reused the Ticket 2 icon source rule for section chips: explicit `section.icon`, otherwise `section.id`, with safe fallback to `Icons.restaurant_menu_rounded`.
- Improved selected/unselected chip styling while keeping the existing pinned header height and chip height stable.
- Preserved chip selection callback behavior and selected-section auto-scroll update behavior.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_section.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Status: passed at time of execution.

Implementation note:

- `kVenueMenuChipHeight` stayed `36` because the pinned header provides limited vertical room. The redesign is contained inside the existing height to avoid sticky header layout drift.

### 2026-05-09 - Ticket 4 Section Header Refresh

Outcome:

- Refreshed the `VenueMenuSectionBlock` header surface without changing its public API.
- Collapsed headers now use a clearer surface and light border instead of a mostly transparent row.
- Expanded headers keep the existing primary-tinted treatment with a slightly stronger border and subtle elevation.
- Preserved the section icon badge from Ticket 2 and the chevron rotation behavior.
- Preserved the count-preview badge semantics exactly: collapsed hidden sections show `visible/total`, expanded sections show total count only.
- Added coverage for count-preview behavior, show all/show less behavior, header tap expansion, and collapse.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_section.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart`

Status: passed at time of execution.

Implementation note:

- `venue_menu_widgets_test.dart` was rerun separately after a parallel test command timed out; the isolated run passed.

### 2026-05-09 - Ticket 5 Featured Row Integration

Outcome:

- Added shared featured item selection for menu widgets.
- `VenueMenuPreviewSection` now shows up to 3 available featured items inside the existing CTA card.
- Preview featured item taps now open the existing menu item details sheet.
- `VenueMenuTab` now inserts `VenueFeaturedItemsRow` after search/category controls when there are at least 3 available featured items.
- Full-menu featured strip is hidden while searching and capped at 8 items.
- `VenueMenuFeaturedCard` now uses localized currency formatting and category-based no-photo placeholders.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_preview_section.dart lib/features/venue/presentation/widgets/venue_menu_section.dart lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_ui_constants.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`

Status: passed at time of execution.

Implementation note:

- Initial validation caught a 6px vertical overflow in `VenueMenuFeaturedCard` after localized price formatting; the card spacing was tightened while keeping the row height fixed.

## Current Known Scope Boundaries

- Do not revisit the details sheet before final QA unless a defect is found.
- Do not expand featured governance beyond client display caps in Phase 1.
- Do not change Firestore schema, providers, `MenuItem`, or `MenuSection`.
- Do not add Remote Config in Phase 1 unless product explicitly chooses that infrastructure work.
- Do not add new dependencies for image tests unless the repo-local helper proves brittle.

### 2026-05-09 - Ticket 6 Details Sheet Visual Refresh

Outcome:

- Visually refreshed `VenueMenuItemDetailsSheet` without changing behavior.
- Added `_DetailsSheetPalette` for proper dark mode support using the same pattern as `_VenueMenuPalette` in `venue_menu_section.dart`.
- Replaced hardcoded `'${formatVenueMenuPrice(item.price)} ${item.currency}'` with `formatVenueMenuPriceWithCurrency(...)` for localized currency display.
- Added featured badge (star icon + "مميز") when `item.isFeatured == true`.
- Improved no-image placeholder: uses category-aware icon via `venueMenuSectionIcon(item.category)`.
- Improved image area: larger height (220px), loading spinner placeholder, category-aware error fallback.
- Improved price row: added border, increased padding, uses localized currency formatting.
- Improved typography hierarchy: title 22px w800, subtitle 14px, description 15px h1.5, price 19px w800.
- Added constants to `venue_ui_constants.dart` for sheet dimensions and font sizes.
- Sheet remains draggable and scrollable via `DraggableScrollableSheet`.
- RTL/Arabic layout preserved; no overflow on long Arabic text.
- No new ARB strings added (reused existing "مميز" pattern from item tiles).
- No new dependencies.
- No model/provider/schema changes.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart`
- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `flutter analyze lib\features\venue\presentation\widgets\venue_menu_item_details_sheet.dart lib\features\venue\presentation\widgets\venue_menu_section.dart lib\features\venue\presentation\widgets\venue_menu_tab.dart lib\features\venue\presentation\widgets\venue_ui_constants.dart test\features\venue\presentation\widgets\venue_menu_widgets_test.dart test\features\venue\presentation\widgets\venue_menu_tab_featured_test.dart` — No issues found.
- `flutter test test\features\venue\presentation\widgets\venue_menu_widgets_test.dart test\features\venue\presentation\widgets\venue_menu_section_test.dart test\features\venue\presentation\widgets\venue_menu_tab_featured_test.dart test\features\venue\presentation\widgets\venue_menu_preview_section_test.dart` — All 42 tests passed.

Status: passed at time of execution.

Implementation note:

- Initial implementation included item name text inside the no-image placeholder, which caused a duplicate text finder in tests. Simplified the placeholder to icon-only since the title is already rendered below the image area.

### 2026-05-09 - Ticket 7 Legacy Image Gallery and Preview Card

Outcome:

- Refreshed `VenueMenuImageGallery` as a named menu photos section with icon badge, localized title, count badge, bounded image cards, improved placeholders, and safer error states.
- Preserved the existing full-screen image preview behavior.
- `VenueMenuPreviewSection` now shows compact menu-image thumbnails for venues with legacy menu images but no structured menu items.
- Image-only full menu mode no longer shows the `noMenuAvailable` empty state before the gallery; the gallery becomes the primary content.
- Added `menuPhotosTitle` localization and generated getters for Arabic and English.
- No model/provider/schema changes and no new dependencies.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `lib/l10n/app_ar.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_ar.dart`
- `lib/l10n/app_localizations_en.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` — All 45 tests passed.
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_section.dart lib/features/venue/presentation/widgets/venue_menu_preview_section.dart lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_ui_constants.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations_en.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` — No issues found.

Status: passed at time of execution.

Implementation note:

- The gallery dialog test avoids `pumpAndSettle` after opening `CachedNetworkImage` inside `InteractiveViewer`; it pumps deterministic frames under the repo-local image HTTP override instead.

### 2026-05-09 - Ticket 8 Analytics Wiring and Pilot

Outcome:

- Added Firebase Analytics wrapper methods for menu impressions, menu item opens, search, category selection, no-interaction timeout, and legacy menu image opens.
- Wired `VenueMenuTab` to log one full-menu impression per rendered menu state.
- Added a 10-second no-interaction measurement for rendered full-menu sessions, cancelled by meaningful menu actions.
- Wired item open analytics from section tiles and featured strip with a `surface` parameter.
- Wired search analytics after the existing debounce without logging raw search query text.
- Wired category chip selection analytics with section id and visible item count.
- Wired legacy menu image open analytics without logging image URLs.
- Wired preview featured item opens with `surface: preview_featured`.
- No UI, ARB, dependency, model, provider, Firestore, or schema changes.

Key files:

- `lib/core/services/analytics_service.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/helpers/recording_analytics_service.dart`
- `test/core/services/analytics_service_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `flutter test test/core/services/analytics_service_test.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` — All 66 tests passed.
- `flutter analyze lib/core/services/analytics_service.dart lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_menu_preview_section.dart lib/features/venue/presentation/widgets/venue_menu_section.dart test/core/services/analytics_service_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/helpers/recording_analytics_service.dart` — No issues found.

Status: passed at time of execution.

Implementation note:

- Flutter/Dart were not on PATH in this shell. Validation used the local SDK at `C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat`.
- Added `C:/src/flutter_windows_3.38.9-stable/flutter` to Git `safe.directory` for this Windows user so the local Flutter SDK can run.
- KPI claims remain blocked until a 7-14 day comparable baseline/pilot window is collected.

### 2026-05-09 - Ticket 9 QA, Performance, and Release Candidate

Outcome:

- Added a large-menu performance guard: category-driven auto-expand no longer expands sections above `kVenueMenuAutoExpandItemLimit` items. The user can still manually tap show all.
- Added widget coverage proving oversized sections stay collapsed from category sync and still expose the show-all affordance.
- Added full-menu 300-item stress coverage on a `390x844` phone viewport.
- Added legacy menu image-open analytics coverage proving image URLs are not logged.
- Re-ran the targeted menu, analytics, RTL, image, featured, preview, and section widget test set.
- Attempted Android app bundle release build.

Key files:

- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `flutter test test/core/services/analytics_service_test.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` — All 69 tests passed.
- `flutter analyze lib/core/services/analytics_service.dart lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_menu_preview_section.dart lib/features/venue/presentation/widgets/venue_menu_section.dart lib/features/venue/presentation/widgets/venue_ui_constants.dart lib/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations_en.dart test/core/services/analytics_service_test.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart test/helpers/recording_analytics_service.dart test/helpers/test_image_http_overrides.dart` — No issues found.
- `flutter build appbundle --release` — blocked before Gradle because no Android SDK was found and `ANDROID_HOME` is not set.

Status: automated QA passed; release build initially blocked on local Android build environment.

Implementation note:

- Automated code-side QA for Ticket 9 passed.
- Release candidate cannot be called complete until Android SDK is installed/configured and the appbundle build plus manual device smoke test pass.
- KPI claims remain blocked until comparable 7-14 day baseline/pilot data exists.

### 2026-05-09 - Android Release Build Environment Resolution

Outcome:

- Found an existing Android SDK at `C:\Users\a-z\AppData\Local\Android\Sdk`.
- Configured Flutter to use that SDK with `flutter config --android-sdk`.
- Re-ran `flutter build appbundle --release --no-pub`.
- Diagnosed a Windows Arabic-locale build failure from Android bundle packaging: `Invalid dex file indices, expecting file 'classes٢.dex' but found 'classes2.dex'`.
- Fixed the locale-sensitive Gradle packaging failure by pinning Gradle JVM locale to English in `android/gradle.properties`.
- Re-ran the Android appbundle release build successfully.

Key files:

- `android/gradle.properties`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `flutter config --android-sdk C:\Users\a-z\AppData\Local\Android\Sdk` — completed.
- `flutter build appbundle --release --no-pub` — passed.
- Output artifact: `build\app\outputs\bundle\release\app-release.aab` (`67.2MB`).

Status: release appbundle build passed.

Implementation note:

- The Gradle locale setting is build-only and does not affect app runtime language.
- Gradle daemons were stopped after the build attempt.
- Manual Android smoke test and Firebase DebugView verification are still required before calling the full release candidate complete.

### 2026-05-09 - Legacy UI Recovery Audit and Results Dropdown Restore

Outcome:

- Confirmed the installed build was coming from the current working repo, but this repo was missing UI work that still exists in `C:\Users\a-z\OneDrive\backups\wain_app_2026-05-07_pre-deploy`.
- Restored the main bottom navigation shell from backup in a previous recovery step.
- Found additional UI differences in:
  - `lib/features/discovery/presentation/screens/results_screen.dart`
  - `lib/features/map/presentation/screens/map_screen.dart`
  - `lib/shared/widgets/venue_card.dart`
  - `lib/shared/widgets/nearby_venues_section.dart`
- Restored the Results/Suggestions dropdown filter bar by merging the backup implementation into the current `results_screen.dart` instead of overwriting the file, preserving newer benefits/search/action code.
- Restored the missing localization keys used by that dropdown: `filterDestination`, `filterCompanion`, and `filterMood`.

Key files:

- `lib/core/routing/app_router.dart`
- `lib/core/routing/main_navigation_shell.dart`
- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/l10n/app_ar.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_ar.dart`
- `lib/l10n/app_localizations_en.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `dart format lib/features/discovery/presentation/screens/results_screen.dart`
- `flutter gen-l10n --arb-dir=lib/l10n --template-arb-file=app_en.arb --output-localization-file=app_localizations.dart --output-dir=lib/l10n`
- `dart format lib/l10n/app_localizations.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations_en.dart`
- `flutter analyze lib/features/discovery/presentation/screens/results_screen.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations_en.dart` — No issues found.

Status: navbar and Results dropdown are restored; remaining backup UI diffs still need targeted review before merge.

Implementation note:

- Do not overwrite full files from backup blindly. The current repo has newer menu, analytics, benefits, and app-shell work that must be preserved.
- Remaining candidate recovery items are Map screen error/family-filter behavior, VenueCard favorite/best-match styling, and NearbyVenuesSection header/card sizing.

### 2026-05-09 - Targeted Recovery Merge Completion

Outcome:

- Compared remaining backup UI diffs against the current repo.
- Kept `VenueCard` and `NearbyVenuesSection` as-is because the current versions already contain newer visual improvements than the backup.
- Restored the missing Results search behavior from backup:
  - Search now uses cached city-wide venues instead of filtering only the recommendation subset.
  - Search hides nearby/best-match/benefit/change-choice sections so results stay focused.
  - Empty-state clear behavior no longer resets discovery filters while the user is only clearing a search query.
- Restored the missing Map behavior from backup:
  - Shows a full-screen retryable error overlay when cached venue loading fails and there are no venues.
  - Family map filter is again tied to `occasionTags.family_kids`, matching the discovery filter model.

Key files:

- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/map/presentation/screens/map_screen.dart`
- `docs/design/2026-05-08-menu-visual-improvement-progress.md`

Validation:

- `dart format lib/features/discovery/presentation/screens/results_screen.dart lib/features/map/presentation/screens/map_screen.dart`
- `flutter analyze lib/features/discovery/presentation/screens/results_screen.dart lib/features/map/presentation/screens/map_screen.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations_en.dart` — No issues found.
- `flutter test test/features/map/presentation/providers/map_providers_test.dart` — All tests passed.
- `flutter build apk --profile --no-pub` — passed; output `build\app\outputs\flutter-apk\app-profile.apk` (`120.0MB`).
- `android\gradlew.bat --stop` — stopped 1 Gradle daemon.

Status: targeted UI recovery merge is complete; next step is building and manually smoke-testing the restored app shell/results/map flow.

Implementation note:

- Kotlin daemon printed a post-build connection warning after the APK was already produced and the command returned success. Gradle daemons were stopped afterward.

### 2026-05-09 - Recovery Phase 2 Visual Parity Merge

Outcome:

- Restored the discovery question flow companion selection so `selectedCompanion` is included in `occasionTags` with the selected occasion.
- Restored `VenueCard` visual styling from the 2026-05-07 backup:
  - Best-match badge returns to text-only styling.
  - Favorite action returns to the white overlay icon with shadow on media.
- Restored `NearbyVenuesSection` layout from the 2026-05-07 backup:
  - Simple section title.
  - Compact horizontal venue cards.
  - Previous compact height/width behavior.
- Restored the profile/settings UI patterns from the 2026-05-07 backup:
  - Language choice boxes instead of a single switch.
  - City picker with venue count/loading/error indicators.
  - City fallback behavior when a selected city has no venues.
- Preserved current app-shell behavior where appropriate:
  - Profile back action still uses `popOrGo('/home')`.
  - Merchant scanner CTA remains available.

Key files:

- `lib/features/discovery/presentation/screens/question_flow_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/shared/widgets/venue_card.dart`
- `lib/shared/widgets/nearby_venues_section.dart`

Validation:

- `dart format lib/features/discovery/presentation/screens/question_flow_screen.dart lib/features/profile/presentation/screens/profile_screen.dart lib/shared/widgets/venue_card.dart lib/shared/widgets/nearby_venues_section.dart`
- `flutter analyze lib/features/discovery/presentation/screens/question_flow_screen.dart lib/features/profile/presentation/screens/profile_screen.dart lib/shared/widgets/venue_card.dart lib/shared/widgets/nearby_venues_section.dart` — No issues found.
- `flutter test test/features/discovery/presentation/providers/search_state_test.dart test/features/profile/presentation/providers/settings_providers_test.dart test/shared/widgets/venue_card_test.dart` — All tests passed.
- `flutter build apk --profile --no-pub` — passed; output `build\app\outputs\flutter-apk\app-profile.apk` (`120.1MB`).

Status: Recovery Phase 2 is complete and a fresh profile APK is available for manual device verification.

### 2026-05-09 - Suggestions Header Cleanup + Google/Auth/Admin Data Check

Outcome:

- Cleaned the root suggestions screen app bar:
  - Removed the top profile/account action from the root suggestions view because profile is already reachable from the bottom navigation shell.
  - Removed the top map action because map is already reachable from the bottom navigation shell.
  - Removed the top filter action/badge from the app bar so the root suggestions view no longer duplicates navbar-level entry points.
- Simplified the "Best suggestions" section header:
  - Removed the boxed/card surface.
  - Removed the decorative icon.
  - Kept title and subtitle as plain section text.
- Checked Google Sign-In configuration:
  - Android app package is `com.wain.wain_app`.
  - Firebase project is `wain-d2e28`.
  - Current `android/app/google-services.json` only includes SHA-1 `AD:2D:0C:06:98:14:7C:38:85:4D:E6:D5:B5:D3:79:0B:C8:9D:EA:AB`.
  - The `a-z` Windows debug keystore matches that SHA-1.
  - The `CodexSecond` Windows debug keystore SHA-1 is `7A:9B:94:87:7E:FA:DF:29:C7:8C:A6:21:81:46:3E:6B:33:3C:4C:21` and is not currently in `google-services.json`.
  - The generated profile APK is signed with the `CodexSecond` debug SHA-1 `7A:9B:94:87:7E:FA:DF:29:C7:8C:A6:21:81:46:3E:6B:33:3C:4C:21`.
  - The upload keystore SHA-1 is `C3:23:1A:4A:3A:73:B6:61:F9:44:FE:F5:44:26:1B:A0:19:CD:B9:E1` and is not currently in `google-services.json`.
  - Likely root cause for Google Sign-In failure on builds produced from `CodexSecond`: Android OAuth SHA mismatch, not a Flutter UI bug.
- Checked mobile/admin data linkage:
  - Mobile app Firebase options and Android `google-services.json` both target `wain-d2e28`.
  - Admin console client/server defaults also target `wain-d2e28`.
  - Admin console venue functions are configured for `https://us-central1-wain-d2e28.cloudfunctions.net`.
  - Mobile venue reads use Firestore collection `venues` and function `searchVenuesInBounds`.
  - Admin venue directory reads use callable `listVenuesForAdmin` with Firestore fallback to collection `venues`.
  - Admin venue commands call `adminCreateVenue`, `adminUpdateVenueProfile`, `adminUpdateVenueVisibility`, `adminUpdateVenueOperationalStatus`, and `adminUpdateVenueSubscriptionStatus`.

Key files:

- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `admin_web_console/lib/firebase/client.ts`
- `admin_web_console/lib/firebase/server.ts`
- `admin_web_console/lib/venues/venue-directory-read-loader.ts`
- `admin_web_console/lib/venues/venue-command-adapters.ts`
- `admin_web_console/.env.local`
- `admin_web_console/.env.production`

Validation:

- `dart format lib/features/discovery/presentation/screens/results_screen.dart`
- `flutter analyze lib/features/discovery/presentation/screens/results_screen.dart` - No issues found.
- `flutter test test/features/discovery/presentation/providers/search_state_test.dart` - All tests passed.
- `flutter build apk --profile --no-pub` - passed; output `build\app\outputs\flutter-apk\app-profile.apk` (`120.0MB`).
- `apksigner verify --print-certs build\app\outputs\flutter-apk\app-profile.apk` - profile APK SHA-1 is `7A:9B:94:87:7E:FA:DF:29:C7:8C:A6:21:81:46:3E:6B:33:3C:4C:21`.

Status:

- Suggestions screen cleanup is implemented and profile build passes.
- Google Sign-In still needs Firebase Console configuration: add missing SHA fingerprints for every build signer, download the refreshed `google-services.json`, replace `android/app/google-services.json`, then rebuild and retest on device.

Follow-up verification:

- Rebuilt the profile APK with `JAVA_TOOL_OPTIONS=-Duser.home=C:\Users\a-z` so Android debug signing uses the already-registered `a-z` debug keystore.
- `apksigner verify --print-certs build\app\outputs\flutter-apk\app-profile.apk` now reports SHA-1 `AD:2D:0C:06:98:14:7C:38:85:4D:E6:D5:B5:D3:79:0B:C8:9D:EA:AB`, matching `google-services.json`.
- `adb install -r build\app\outputs\flutter-apk\app-profile.apk` failed with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` because the currently installed phone build is signed with a different certificate. A full uninstall/reinstall is required to test this matching-SHA APK.

### 2026-05-09 - Google Profile Name Visibility Fix

Outcome:

- Fixed the auth fallback path that could emit a user without Google profile fields before the Firestore user document was available.
- Preserved Firebase Auth `displayName`, `email`, and `photoUrl` when `authStateChanges` or `currentUser` fall back to Firebase Auth data.
- During Google sign-in, preserved `GoogleSignInAccount` profile values as a fallback if the Firebase `User` has not populated them yet.
- Invalidated `authStateProvider` and `currentUserProvider` after successful Google sign-in so profile consumers refresh from the saved user state.

Key files:

- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`

Validation:

- `dart format lib/features/auth/data/repositories/auth_repository_impl.dart lib/features/auth/presentation/providers/auth_provider.dart`
- `flutter analyze lib/features/auth/data/repositories/auth_repository_impl.dart lib/features/auth/presentation/providers/auth_provider.dart lib/features/profile/presentation/screens/profile_screen.dart` - No issues found.
- `flutter test test/features/auth/domain/entities/app_user_test.dart test/features/auth/presentation/screens/login_screen_test.dart test/features/profile/presentation/providers/settings_providers_test.dart` - All tests passed.
- `JAVA_TOOL_OPTIONS=-Duser.home=C:\Users\a-z flutter build apk --profile --no-pub` - passed; output `build\app\outputs\flutter-apk\app-profile.apk` (`147.4MB`).
- `apksigner verify --print-certs build\app\outputs\flutter-apk\app-profile.apk` - profile APK SHA-1 is `AD:2D:0C:06:98:14:7C:38:85:4D:E6:D5:B5:D3:79:0B:C8:9D:EA:AB`.

Status:

- Google profile display name should now appear after Google sign-in.
- `@username` remains a separate explicit handle and only appears after the user sets it from Edit Profile.

### 2026-05-09 - Profile Navigation + Suggestions Stats Cleanup

Outcome:

- Removed the benefit/statistics strip from the suggestions screen.
- Kept the full statistics page available from the bottom navigation only.
- Removed top back arrows from bottom-navigation root pages:
  - Profile/settings.
  - User stats.
  - Favorites.
- Changed empty-state discovery actions to route to suggestions/results instead of the old home/map path:
  - Try list empty state and try-list back arrow now go to `/results`.
  - Favorites empty state now goes to `/results`.
  - Saved offers empty state now goes to `/results`.
  - My claims empty state now goes to `/results`.
- Enabled proximity notifications by default for users with no saved preference.
- Removed the merchant QR scan entry from the bottom of profile/settings.
- Limited wallet activity and paid-benefit expiry notification controls to accounts with merchant access.
- Improved user statistics used-offers visibility:
  - Benefit insights now merge claims by signed-in `user_id` and current `device_id`.
  - Duplicate claim docs are de-duplicated by document id.
  - Used-offer status recognition accepts `redeemed`, `used`, and `completed`.

Key files:

- `lib/features/discovery/presentation/screens/results_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/profile/presentation/screens/user_stats_screen.dart`
- `lib/features/profile/presentation/providers/settings_providers.dart`
- `lib/features/profile/presentation/providers/user_benefit_insights_provider.dart`
- `lib/features/favorites/presentation/screens/favorites_screen.dart`
- `lib/features/try_list/presentation/screens/try_list_screen.dart`
- `lib/features/offers/presentation/screens/my_claims_screen.dart`
- `lib/features/offers/presentation/screens/saved_offers_screen.dart`
- `test/features/profile/presentation/providers/settings_providers_test.dart`

Validation:

- `dart format` on affected Dart files.
- `flutter analyze` on affected screens/providers/tests - No issues found.
- `flutter test test/features/profile/presentation/providers/settings_providers_test.dart test/features/discovery/presentation/providers/search_state_test.dart test/features/auth/presentation/screens/login_screen_test.dart` - All tests passed.
- `JAVA_TOOL_OPTIONS=-Duser.home=C:\Users\a-z flutter build apk --profile --no-pub` - passed; output `build\app\outputs\flutter-apk\app-profile.apk` (`147.3MB`).
- `apksigner verify --print-certs build\app\outputs\flutter-apk\app-profile.apk` - profile APK SHA-1 is `AD:2D:0C:06:98:14:7C:38:85:4D:E6:D5:B5:D3:79:0B:C8:9D:EA:AB`.

Status:

- Requested navigation/settings/statistics cleanup is implemented and ready for device smoke testing.

### 2026-05-10 - Menu Simplification and Section Scroll Fix

Outcome:

- Simplified `VenueMenuPreviewSection` so the external menu preview is lighter and uses theme text styles instead of a heavy CTA/card treatment.
- Kept featured preview compact as plain item rows with name and localized price only.
- Removed the full-menu `VenueMenuHeader` from the top of `VenueMenuTab`; the search field is now the first visible element.
- Added `countLabel` to `VenueMenuSearchField` and wired the full-menu count into the search field, e.g. `64 صنف`.
- Removed the separate summary/count text under search.
- Converted `VenueMenuCategoryChips` from boxed icon/count chips into simple horizontal text tabs.
- Fixed programmatic category selection so tapping `الكل` stays selected after scrolling to the top.
- Fixed section selection so tapping a category tab scrolls only and does not auto-expand or re-sync to the first visible section.
- Kept section header tap as the only direct expand/collapse action.
- Made item rows more compact by reducing thumbnail/placeholder sizing and placing price beside the item name in the text row.
- Preserved details sheet behavior, models, providers, Firestore schema, and public constructors except the optional `VenueMenuSearchField.countLabel`.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` - All 53 tests passed.
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_menu_section.dart lib/features/venue/presentation/widgets/venue_menu_preview_section.dart lib/features/venue/presentation/widgets/venue_ui_constants.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` - No issues found.

Status:

- Requested menu simplification and category/section behavior fixes are implemented and ready for device smoke testing.

### 2026-05-10 - Menu Header, Category Sync, and Featured Polish

Outcome:

- Removed the venue name from the dedicated full-menu screen AppBar; the AppBar now shows only the localized menu title.
- Reworked full-menu category sync to use the vertical scroll controller plus a stable viewport reference line below the pinned category bar.
- Category selection now changes when a section header crosses the reference line, returns to previous sections when scrolling back up, and returns to `all` near the search/top area.
- Removed the 120-item limit from category sync so large menus keep the top bar synchronized.
- Preserved tap-to-category behavior as scroll-only; it does not expand/collapse sections.
- Made full-menu featured cards smaller, removed their heavy shadow, reduced image/placeholder height, and placed price next to the item name.
- Changed the external menu preview featured area from a vertical list into a simple horizontal strip with name and localized price only.
- Preserved details sheet behavior, schema, models, providers, and ARB strings.

Key files:

- `lib/features/venue/presentation/screens/venue_menu_screen.dart`
- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- `test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` - All 56 tests passed.
- `flutter analyze lib/features/venue/presentation/screens/venue_menu_screen.dart lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_menu_section.dart lib/features/venue/presentation/widgets/venue_menu_preview_section.dart lib/features/venue/presentation/widgets/venue_ui_constants.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` - No issues found.

Status:

- Menu header cleanup, category sync stabilization, and featured polish are implemented and ready for device smoke testing.

### 2026-05-10 - Hybrid Category Scroll Sync Fix

Outcome:

- Replaced full-menu category scroll sync that scanned `GlobalKey.currentContext` for every section with a hybrid offset model.
- The new model records offsets for currently built section blocks, infers the first section/list start from the nearest measured anchor, and estimates unbuilt sections from stable menu row/header extents.
- Category tab selection now uses `ScrollController.position.pixels` plus the pinned-header reference line, so distant lazy `SliverList` sections no longer make the selected category stick on stale values.
- Programmatic category taps scroll using the same computed offsets instead of `Scrollable.ensureVisible`, which keeps jumps deterministic for sections that are not built yet.
- Expanded/collapsed section state is now reported upward from `VenueMenuSectionBlock`, and offsets from the changed section onward are invalidated before the next sync.
- Increased top bounce tolerance from 2px to 24px and extended the programmatic-scroll guard to 200ms.

Key files:

- `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`

Validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` - All 56 tests passed.
- `flutter analyze lib/features/venue/presentation/widgets/venue_menu_tab.dart lib/features/venue/presentation/widgets/venue_menu_section.dart test/features/venue/presentation/widgets/venue_menu_widgets_test.dart test/features/venue/presentation/widgets/venue_menu_section_test.dart test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart` - No issues found.

Status:

- Hybrid category scroll sync is implemented and ready for profile-device smoke testing.

## Next Step Candidate

Manual Android smoke test and Firebase DebugView verification:

- Run manual Android smoke test for scroll, image loading, details sheet, search, featured strip, gallery dialog, and Firebase analytics debug output.
- Confirm analytics events are visible in Firebase DebugView or a staging analytics stream.
- Keep the baseline analytics caveat: if no comparable baseline exists, collect a 7-14 day baseline before claiming KPI success.

Recommended validation:

- `flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`
- `flutter test test/features/venue/presentation/widgets/venue_menu_tab_featured_test.dart`
- `flutter test test/core/services/analytics_service_test.dart`
- Limited `flutter analyze` on menu, analytics, localization, and affected test files
- Manual smoke test on Android/emulator for scroll, image loading, details sheet, search, featured strip, gallery dialog, and Firebase analytics debug output

## Update Rule

After each future ticket, append a new dated section under `Completed Work Log` with:

- Outcome
- Key files
- Validation commands
- Status
- Any implementation notes or blockers
