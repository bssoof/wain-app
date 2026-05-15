# Menu Visual Improvement Plan V2.1 - 2026-05-08

Scope: visual and UX improvement plan for the customer-facing venue menu in the Flutter app. This plan is based on the current implementation and is written to be executable as small Flutter UI tickets.

V2.1 update: incorporates the plan evaluation decisions around baseline analytics, featured governance, currency localization, RTL/golden test readiness, measurable above-the-fold behavior, and low-end Android performance risk.

Non-goals for Phase 1:

- No Firestore schema changes.
- No backend deploy.
- No ordering/cart flow.
- No merchant tooling changes.
- No full rewrite of venue details.
- No Firestore Rules enforcement for featured governance in Phase 1.

## 1. Current Implementation Audit

Primary files:

- Full menu screen: `lib/features/venue/presentation/screens/venue_menu_screen.dart`
- Menu orchestration: `lib/features/venue/presentation/widgets/venue_menu_tab.dart`
- Menu widgets: `lib/features/venue/presentation/widgets/venue_menu_section.dart`
- Venue details preview: `lib/features/venue/presentation/widgets/venue_menu_preview_section.dart`
- Menu UI constants: `lib/features/venue/presentation/widgets/venue_ui_constants.dart`
- Menu item model: `lib/features/menu/domain/entities/menu_item.dart`
- Menu section model: `lib/features/menu/domain/entities/menu_section.dart`
- Menu providers: `lib/features/menu/presentation/providers/menu_providers.dart`

What already works:

- Structured active menu stream with legacy fallback.
- Available-item filtering via `isAvailable`.
- Debounced menu search.
- Sticky category chips.
- Section expand/collapse.
- Item details bottom sheet.
- Legacy menu image gallery fallback.
- Loading, empty, error, and no-results states.
- Existing widget tests for menu widgets.

Unused or underused assets:

- `MenuItem.isFeatured` exists but is not used in the full menu view.
- `MenuSection.icon` exists but is not shown in category chips or section headers.
- `VenueFeaturedItemsRow` exists but is not wired into `VenueMenuTab`.

Related plan review constraint:

- `docs/plan_review/venue_menu_redesign_plan.md` previously decided that featured items belong primarily in the venue details menu preview, not as a standalone row at the top of the full menu screen.
- This plan should not reintroduce a large featured block above the full menu's search/category controls.
- Recommended compromise: venue details preview uses featured items prominently; full menu may show featured items only as a compact, height-bounded discovery strip after search/category controls and only when there is enough data to make the row feel complete.

Runtime capability check:

- Firebase Analytics is available through `firebase_analytics` and `lib/core/services/analytics_service.dart`.
- No Firebase Remote Config dependency or clear feature-flag pattern was found in `pubspec.yaml` or `lib/`.
- `intl` is already available, so currency/number formatting can be improved without adding a runtime dependency.
- No golden-test image mocking helper was found. Ticket 0B should add a repo-local `HttpOverrides` image mock helper for deterministic `CachedNetworkImage` tests before adding a new dev dependency.
- Therefore, Phase 1 should assume atomic mobile release/closed testing unless product explicitly approves adding Remote Config as new infrastructure work.

Current visual diagnosis:

- Header is functional but not memorable.
- Item rows feel like admin/list UI rather than food discovery.
- Category chips are useful but plain.
- Details sheet lacks premium hierarchy.
- Legacy image gallery is useful but visually detached.
- Venue details preview card is not strong enough as an entry point.

## 2. Design Standard

Target: premium local food guide.

The menu should feel:

- Food-first.
- Arabic-first.
- Fast to scan.
- Rich where photos exist.
- Clean and stable where photos are missing.
- Practical for long menus.

The menu should not feel:

- Like a spreadsheet/list.
- Like a marketing landing page.
- Over-decorated.
- Slow on large menus.
- Dependent on perfect photo coverage.

Visual constraints:

- Keep cards at moderate radius; avoid overly pillowy UI.
- Avoid nested cards.
- Avoid a one-color theme.
- Do not scale text with viewport width.
- Text must not overflow in Arabic.
- Large menus must remain scrollable without jank.

Accessibility constraints:

- Minimum tap target: 44x44 logical pixels for tappable controls.
- Category chips, search clear button, item rows, and gallery images must have meaningful semantic labels where needed.
- Text contrast must remain readable in light and dark mode.
- Important states must not rely on color alone.
- Screen readers should announce item name and price at minimum.
- Bottom sheet drag handle and close/dismiss behavior must remain accessible through standard platform semantics.

UX guardrails:

- Keep the first useful menu content visible above the fold on a measured phone viewport.
- Above-the-fold definition for Phase 1: on a 390x844 viewport after data load, search and category controls must be reachable without scrolling, and either the first featured card or the first normal item tile must be at least 50% visible without scrolling.
- When the full-menu featured strip is hidden, the first normal item tile must be at least 50% visible without scrolling on a 390x844 viewport.
- Do not let the featured row dominate the opening viewport.
- Treat photos as an enhancement, not a dependency.
- Menus with no item photos must still look intentional and complete.
- Name, price, and availability state must be quickly visible.
- Keep category and search controls familiar; the redesign should not make users relearn browsing.
- Avoid hiding core actions behind decorative surfaces.

Product guardrails:

- Phase 1 must not force merchants to update photos before the menu looks acceptable.
- Track whether the redesign improves discovery before rolling it to every user.
- Use a pilot or closed testing path if implementation risk is high.
- Do not assume a remote kill switch exists; adding one is a separate product/engineering decision.
- Merchant-facing communication should explain what "featured" means and how section icons are chosen.
- Featured governance must be defined before broad rollout so the featured strip does not become a second full menu.

## 3. Priority Model

### Must

- Use existing schema only.
- Preserve search behavior.
- Preserve category navigation.
- Preserve bottom sheet item detail behavior.
- Preserve legacy menu image fallback.
- Use `isFeatured` where available.
- Use `MenuSection.icon` where safe.
- Keep featured content height-bounded.
- Apply Phase 1 featured governance: preview-first, full-menu strip only with 3+ featured items, and display cap of 8 items.
- Keep no-photo menus visually strong.
- Keep list performance acceptable for 120+ items.
- Smoke-test layout stability for a 300-item synthetic menu.
- Meet the Phase 1 performance budget.
- Preserve accessible tap targets and screen-reader basics.
- Preserve Arabic RTL layout and horizontal scroll behavior.
- Add/update widget tests for each changed component.

### Should

- Improve first impression with a designed menu overview header.
- Improve item cards/rows to feel food-forward.
- Improve preview card on venue details.
- Add better no-photo placeholder treatment.
- Add clearer empty and no-results states.
- Support dark mode cleanly.
- Add analytics events or measurement hooks for menu interaction where existing analytics patterns allow it.
- Collect or confirm baseline metrics before evaluating KPI gates.
- Support closed testing or feature-flagged rollout if the app gains a feature-flag mechanism.
- Add golden tests for the highest-risk visual states if the test environment supports stable rendering.

### Could

- Add Canva moodboard before implementation.
- Add subtle animations for section expansion and selected chips.
- Add mini thumbnails to the venue details preview card if data access remains cheap.
- Add search highlight later.
- Add a quick "available only" control later if product decides to show unavailable items. The current customer view already filters unavailable items out.
- Add Remote Config later if product wants a runtime kill switch for mobile UI experiments.

### Will Not Do In Phase 1

- Add allergens, calories, spicy level, or dietary tags.
- Add a cart/order CTA.
- Add personalization.
- Require merchants to upload new photos.
- Change Firestore rules or Functions.
- Change merchant menu management.

## 3.1 Phase 0 Readiness Decisions

These decisions must be locked before Ticket 1 starts.

### Baseline Analytics

- KPI gates are only meaningful after a comparable baseline exists.
- If historical menu events already exist, use the last 7-14 days as baseline after confirming event definitions match this plan.
- If no comparable events exist, ship a measurement-only slice on the current UI first and collect 7-14 days before judging the redesign.
- The first pilot after adding analytics but before a baseline is collected is a baseline collection period, not a KPI graduation test.

### Featured Governance

Phase 1 display policy:

- Venue details preview may surface featured items prominently.
- Full menu may show a compact featured strip only after search/category controls.
- Full-menu featured strip appears only when there are 3+ available featured items.
- Full-menu featured strip displays at most 8 items, sorted by existing `sortOrder`.
- If more than 8 items are marked featured, the UI shows the first 8 only and normal sections still render all available items.

Recommended merchant/admin policy before broad rollout:

- Max featured items per venue: `min(8, max(3, ceil(availableItems * 0.2)))`.
- Phase 1 enforcement layer: client display cap plus merchant/admin communication only.
- Firestore Rules, backend validation, or merchant tooling enforcement are out of scope for Phase 1 and should be tracked separately if abuse appears.

### Currency Display Contract

Use existing stored `price` and `currency`; do not change schema. For Arabic UI, display the number before the localized symbol/name to avoid RTL ambiguity.

| Currency | Arabic display | English/fallback display | Notes |
| --- | --- | --- | --- |
| `ILS` | `15 ₪` | `15 ILS` or `₪15` if English product copy chooses symbol-first later | Preferred Phase 1 Arabic form is amount then symbol. |
| `JOD` | `15 د.أ` | `15 JOD` | Support as a known future-safe mapping. |
| `USD` | `15 US$` | `$15` | Avoid bare `$` in Arabic where currency may be ambiguous. |
| Unknown | `15 XXX` | `15 XXX` | Use the raw currency code and clamp safely. |

Implementation guidance:

- Keep `formatVenueMenuPrice` for numeric cleanup.
- Add a small currency-label helper rather than scattering currency conditionals across widgets.
- Do not introduce a new runtime dependency; `intl` is already available if localized number formatting is needed.

### Golden And RTL Test Convention

- Create a repo-local test helper for deterministic network image responses using `HttpOverrides` and a tiny in-memory PNG.
- Do not add `network_image_mock` unless the local helper proves brittle in CI.
- Each new or visually changed menu widget must have at least one RTL widget test.
- Horizontal featured/category lists must be tested in Arabic/RTL so initial alignment and scroll direction are deliberate.

### Section Header Badge Definition

- The section header badge is a count-preview badge, not reading progress.
- Collapsed sections with hidden items show `visible/total`, for example `4/12`.
- Expanded sections show the total count only, for example `12`.
- This label must not imply that the app tracks which items the user has viewed.

## 4. Component Plan

### A. Menu Overview Header

Files:

- `venue_menu_tab.dart`
- `venue_menu_section.dart` if extracted into a widget
- `venue_ui_constants.dart`

Change:

- Replace the current simple menu header area with a designed overview block.
- Show menu title, item count, section count, and optional "متاح الآن" style status.
- Keep it compact enough that menu items are visible quickly.

Acceptance criteria:

- Header shows item count and section count.
- Header does not overflow in Arabic.
- Header remains readable in dark mode.
- Header does not push the first item too far below the fold.
- No backend data required beyond existing items/sections.

### B. Featured Items Row

Files:

- `venue_menu_tab.dart`
- `venue_menu_section.dart`
- `venue_menu_preview_section.dart`

Change:

- Filter `availableItems.where((item) => item.isFeatured)`.
- In the venue details preview, show featured items prominently as part of the preview content.
- In the full menu screen, do not show featured items above search/category controls.
- In the full menu screen, show a compact featured strip only after search/category controls and only when it improves discovery without hiding core browsing.
- Cap visible featured items at 8.
- Require at least 3 featured items before showing the full featured strip; with 1-2 featured items, prefer normal item badges or preview-only treatment.
- Use a fixed-height horizontal row so it cannot push too much content below the fold.
- Keep featured cards image-forward, but provide a polished no-photo state.
- Consider a compact "عرض المزيد" affordance instead of making the row taller.
- Item tap opens the same details bottom sheet.

Acceptance criteria:

- Venue details preview can show featured content when featured available items exist.
- Full-menu featured strip appears only when 3+ featured available items exist.
- Featured row/strip is hidden when no items are featured.
- Full featured strip is hidden when fewer than 3 featured items exist.
- Full featured strip never appears above search/category controls.
- Full featured strip displays at most 8 items even if more are marked featured.
- Featured cards show image, name, and price.
- Featured row has a stable maximum height.
- On the 390x844 viewport, header + featured row still satisfies the above-the-fold contract.
- Tap opens details sheet.
- Existing non-featured menus still render normally.

### C. Category Navigation

Files:

- `venue_menu_section.dart`
- `venue_ui_constants.dart`

Change:

- Improve `VenueMenuCategoryChips`.
- Add icon support from `MenuSection.icon` through a fixed safe mapping.
- Keep counts.
- Improve pinned background and selected state.
- Keep current performance guard for large menus unless proven safe.

Acceptance criteria:

- "All" chip still works.
- Section chips still call `onSelected` with the section id.
- Counts remain correct.
- Icons render only from known safe mappings.
- Unknown icon strings fall back to a neutral menu icon.
- Horizontal chip row does not overflow or wrap.

Initial safe icon mapping:

- `restaurant_menu` -> restaurant/menu icon
- `coffee` -> coffee icon
- `local_cafe` -> coffee icon
- `local_drink` -> drink icon
- `bakery_dining` -> bakery icon
- `cake` -> dessert icon
- `lunch_dining` -> main dish icon
- `fastfood` -> fast food icon
- Unknown values -> default menu icon

### D. Section Header

Files:

- `venue_menu_section.dart`

Change:

- Improve section header hierarchy.
- Surface section icon.
- Keep count-preview badge: collapsed hidden sections show `visible/total`, expanded sections show total count only.
- Make expanded/collapsed state clearer without making headers heavy.

Acceptance criteria:

- Section name, icon, and count-preview badge render.
- Badge copy matches the count-preview definition and does not imply item-view progress.
- Expand/collapse still works.
- Show all/show less still works.
- No layout jump that breaks scroll targeting.

### E. Menu Item Tile

Files:

- `venue_menu_section.dart`
- `venue_ui_constants.dart`

Change:

- Redesign `VenueMenuItemTile`.
- Make image treatment stronger.
- Improve no-image placeholder by category or section when possible.
- Make price more prominent.
- Display currency through the Phase 0 Currency Display Contract without changing the stored schema.
- Add a featured badge when `isFeatured == true`.
- Keep stable row height or predictable responsive height.
- Keep the compact row as the default for normal menu items.
- Avoid making every item an oversized card; reserve image-forward treatment for featured items or details.

Acceptance criteria:

- Name, description, price, and currency render correctly.
- No image state looks intentional.
- Long Arabic names clamp cleanly.
- Long currency values do not break layout.
- Known currencies use the approved display form; unknown currencies fall back to a clamped raw code.
- Featured badge appears only for featured items.
- The row shows name and price without requiring a tap.
- Menus with no item photos do not look empty or broken.
- Tap behavior is unchanged.

### F. Item Details Bottom Sheet

Files:

- `venue_menu_tab.dart`
- New dedicated widget: `venue_menu_item_details_sheet.dart`

Change:

- Extract `_showMenuItemDetailsSheet` into a dedicated widget first, then improve it.
- Make image/header area stronger.
- Add featured badge.
- Improve title, subtitle, description, and price hierarchy.
- Keep no ordering CTA for now.

Acceptance criteria:

- Sheet opens from featured cards and normal tiles.
- Image and no-image states both render cleanly.
- Arabic title and description do not overflow.
- Price row is clear and stable.
- Sheet remains draggable and scrollable.

### G. Legacy Menu Images

Files:

- `venue_menu_section.dart`
- `venue_menu_tab.dart`

Change:

- Present menu images as a named supporting section.
- Improve preview cards.
- Keep full-screen image preview.
- In image-only mode, make the gallery feel like primary content.

Acceptance criteria:

- Gallery still appears when `venue.menuImages` is not empty.
- Gallery works with structured menu and image-only fallback.
- Tapping an image still opens preview.
- Broken images still show a controlled fallback.

### H. Venue Details Preview

Files:

- `venue_menu_preview_section.dart`

Change:

- Make the preview card more visually persuasive.
- Show stronger summary and CTA.
- Keep it lightweight in the venue details tab.

Acceptance criteria:

- Preview still handles loading, error, empty, and data states.
- Tap still opens `venue-menu`.
- Summary remains correct.
- No added expensive stream beyond current provider usage.
- Featured items are represented here more strongly than in the full menu screen.

## 5. Implementation Tickets

Ticket 0A - Product decisions and measurement baseline:

- Resolve featured placement against `docs/plan_review/venue_menu_redesign_plan.md`.
- Adopt the recommended placement unless product overrides it: preview-first, compact full-menu strip only after search/category controls, and only with 3+ featured items.
- Lock featured governance: display cap 8, merchant/admin recommended max formula, and Phase 1 client-only enforcement.
- Confirm whether comparable menu interaction baseline data already exists.
- If no baseline exists, ship or prepare a measurement-only slice for the current UI and collect 7-14 days before evaluating KPI gates.
- Define numeric KPI targets before pilot or closed testing.
- Decide whether to add Remote Config as new infrastructure; default is no, because no existing dependency/pattern was found.

Ticket 0B - Technical prep and refactor:

- Extract the item details bottom sheet from `VenueMenuTab` into `venue_menu_item_details_sheet.dart` before visual expansion.
- Define the fixed safe `MenuSection.icon` mapping and fallback behavior.
- Add a small currency-label helper that follows the Currency Display Contract.
- Add repo-local deterministic network image test helper for `CachedNetworkImage` widget/golden tests.
- Define RTL widget-test convention for menu components.
- Do not change visible UI except where required by extraction.

Ticket 1 - Menu item visual refresh:

- Update `VenueMenuItemTile`.
- Add featured badge support.
- Improve image/no-image handling.
- Use the new currency-label helper.
- Add RTL tests and long mixed Arabic/English text coverage.
- Update tests.

Ticket 2 - Header and section icon mapping:

- Replace menu overview header.
- Add section icon rendering in section headers using the safe icon mapping.
- Keep category chip redesign out of this ticket except where required to avoid broken icons.
- Add tests.

Ticket 3 - Category chips redesign:

- Improve sticky category chips.
- Add safe icon rendering in chips.
- Preserve current chip selection and scroll-to-section behavior.
- Keep the performance guard for large menus unless measured safe.
- Add tests.

Ticket 4 - Section header refresh:

- Improve `VenueMenuSectionBlock` header.
- Preserve expand/collapse behavior.
- Implement count-preview badge exactly as defined in Phase 0.
- Add tests.

Ticket 5 - Featured row integration:

- Wire featured items into `VenueMenuPreviewSection`.
- Add optional compact full-menu featured strip only after search/category controls.
- Hide the full-menu strip when fewer than 3 featured items exist.
- Cap full-menu featured items at 8.
- Reuse details sheet tap.
- Add tests.

Ticket 6 - Details sheet visual refresh:

- Improve the extracted details sheet.
- Keep no ordering CTA.
- Add widget coverage where practical.

Ticket 7 - Legacy image gallery and preview card:

- Improve `VenueMenuImageGallery`.
- Improve `VenueMenuPreviewSection`.
- Add tests.

Ticket 8 - Analytics wiring and pilot readiness:

- Confirm whether an existing analytics wrapper is available.
- Add measurement events only if the app has a clean existing pattern.
- Do not evaluate KPI gates until baseline exists.
- Treat Remote Config as unavailable unless product approves adding it as new infrastructure.
- Define the event payload contract before adding analytics.
- Define the KPI gate for pilot graduation.
- Document pilot venue set for photo-rich and photo-poor cases.

Ticket 9 - Final QA and release candidate:

- Run targeted widget tests.
- Run golden tests if added.
- Run broader Flutter tests where practical.
- Run RTL widget-test subset.
- Build Android release candidate.
- Manual device smoke test.

## 6. Performance Budget

Phase 1 should improve presentation without making menu browsing feel slower.

Targets:

- Full menu initial render: no obvious blank/loading delay beyond existing provider fetch behavior.
- First useful content: meets the 390x844 above-the-fold definition in Section 2.
- Scroll: no visible jank while browsing a 120-item menu on a normal Android device.
- Large-menu stress: a 300-item menu should remain usable, with scroll-sync disabled if needed and no overflow or runaway rebuild behavior.
- Featured row: fixed maximum height and capped items, so it does not dominate the first viewport.
- Image loading: failed or slow images must show a stable placeholder without layout shift.
- Bottom sheet open: should feel immediate after tapping an item, with remote image loading handled asynchronously.

Engineering checks:

- Avoid expensive work inside item builders.
- Keep grouping/sorting outside repeated row builds where practical.
- Keep image cache dimensions bounded.
- Watch image caching memory pressure on low-end Android devices with 1-2GB RAM.
- Avoid per-frame layout measurement during normal scroll.
- Do not enable scroll-sync behavior for very large menus unless measured.

Optional measurement:

- Capture Flutter performance overlay or DevTools profile on a 120+ item test venue.
- Smoke-test a 300-item synthetic venue for layout stability and unacceptable jank.
- Record subjective pass/fail in the release notes if exact FPS tooling is not available.

## 7. Test Plan

Existing tests to update:

- `test/features/venue/presentation/widgets/venue_menu_widgets_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_section_test.dart`
- `test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart`

Required coverage:

- Venue preview featured content visible when featured available items exist.
- Featured row hidden when there are no featured items.
- Full-menu featured strip hidden when fewer than 3 featured items exist.
- Full-menu featured strip appears after search/category controls, not above them.
- Full-menu featured strip caps displayed items at 8.
- Featured row remains height-bounded.
- Category chips render names, counts, and safe icons.
- Unknown section icon strings fall back safely.
- Section headers render icon and count-preview badge.
- Item tile renders image state.
- Item tile renders no-image state.
- Item tile renders featured badge.
- ILS/JOD/USD/unknown currency display follows the Currency Display Contract.
- Long Arabic text does not throw overflow in tests.
- Mixed Arabic + English names do not overflow or reorder incoherently.
- Each visually changed widget has at least one RTL test.
- Featured horizontal strip and category chips have RTL layout/scroll-direction coverage.
- 390x844 viewport test proves the above-the-fold contract.
- Details sheet opens from item tap.
- Search no-results state remains intact.
- No-results state exposes clear search affordance.
- Legacy menu image fallback remains intact.
- Accessibility basics: key controls have tappable size and semantic labels where practical.

Commands:

```powershell
flutter test test/features/venue/presentation/widgets/venue_menu_widgets_test.dart
flutter test test/features/venue/presentation/widgets/venue_menu_section_test.dart
flutter test test/features/venue/presentation/widgets/venue_menu_preview_section_test.dart
```

Before release candidate:

```powershell
flutter test
flutter build appbundle --release
```

Golden visual regression candidates:

- Structured menu with photos.
- Structured menu with no item photos.
- Long Arabic item names and long prices/currency.
- Featured row with many featured items.
- Empty/no-menu state.
- Search no-results state.
- Dark mode menu.

Notes:

- Golden tests are valuable but can be brittle across platforms. Add them for stable component states, not for remote images.
- Use the Ticket 0B deterministic network image helper for remote-image widgets.
- Do not add `network_image_mock` unless the repo-local helper proves brittle in CI.
- Golden candidates must not depend on live remote URLs.

## 8. Manual QA Checklist

Devices:

- Small Android screen.
- Normal Android screen.
- Low-end Android device or emulator profile, especially 1-2GB RAM class if available.
- Dark mode.
- Slow network if practical.

Scenarios:

- Venue with structured menu and photos.
- Venue with structured menu but no item photos.
- Venue where every item has no photo.
- Venue with featured items.
- Venue with only 1-2 featured items.
- Venue with no featured items.
- Venue with many featured items.
- Venue with many categories.
- Venue with 120+ menu items.
- Synthetic or test venue with 300 menu items.
- Venue with mixed Arabic + English item names.
- Venue with only legacy menu images.
- Venue with no menu.
- Search with matching results.
- Search with no results.
- Open item details repeatedly.
- Navigate from venue details preview to full menu and back.

Pass conditions:

- No visible Arabic overflow.
- First useful menu content is reachable quickly above the fold.
- Featured row does not dominate the opening viewport.
- Search and category controls are reachable before promotional featured content in the full menu.
- On a 390x844 viewport, the first useful item content satisfies the above-the-fold contract.
- No-results state provides a clear way to clear the search.
- No blank image areas without fallback.
- No broken sticky category behavior.
- No janky scroll on large menu.
- No obvious image memory pressure symptoms on low-end Android during repeated scrolling/opening details.
- No regression in route navigation.

## 9. Measurement Plan

Goal: confirm the redesign improves discovery rather than only looking better.

Baseline protocol:

- Before evaluating the redesign, confirm whether comparable menu interaction events already exist.
- If comparable events exist, use the last 7-14 days as baseline.
- If comparable events do not exist, ship a measurement-only slice on the current UI and collect 7-14 days before UI rollout.
- A first pilot without baseline data is only a baseline collection pilot; it cannot prove KPI graduation.
- Baseline and pilot must use the same event names, buckets, and privacy constraints.

Recommended events, using existing analytics patterns if available:

- `menu_view`: user opens full venue menu.
- `menu_first_interaction`: first search, chip tap, item tap, or image tap.
- `menu_item_open`: user opens item details.
- `menu_featured_item_open`: user opens a featured item.
- `menu_search`: user searches inside menu.
- `menu_category_select`: user selects a category chip.
- `menu_legacy_image_open`: user opens an original menu image.

Event payload contract:

- Common fields:
  - `venue_id`
  - `source`: `venue_details_preview`, `venue_menu_screen`, or `deep_link`
  - `has_structured_menu`: boolean
  - `has_legacy_images`: boolean
  - `item_count_bucket`: `0`, `1_10`, `11_50`, `51_120`, `120_plus`
  - `section_count_bucket`: `0`, `1_5`, `6_10`, `10_plus`
- Item events:
  - `item_id`
  - `section_id`
  - `is_featured`: boolean
  - `has_photo`: boolean
- Search events:
  - `query_length_bucket`: `1_2`, `3_5`, `6_10`, `10_plus`
  - Do not send raw query text.
- Category events:
  - `section_id`
  - `section_index_bucket`: `0_2`, `3_6`, `7_plus`

Metrics:

- Time to first interaction.
- Item detail opens per menu view.
- Featured item opens per menu view.
- Search usage per menu view.
- Category chip usage per menu view.
- Exit rate from full menu without interaction.
- Crash-free sessions for venue menu flows.
- No meaningful degradation in menu screen load/render time.

Pilot KPI gate:

- Increase `menu_item_open / menu_view` by at least 10% versus baseline.
- Reduce menu sessions with no interaction by at least 10% versus baseline.
- Maintain or improve median time to first interaction; do not allow more than 5% regression.
- Maintain crash-free sessions; no measurable regression from the current baseline.
- Maintain menu screen render/load perception; no obvious manual QA regression on representative Android hardware.
- Manual QA passes on photo-rich and photo-poor venues.

Notes:

- Analytics should not block Phase 1 if the app has no clean event wrapper available.
- If analytics are added, keep event names stable and avoid sending item names or free-text search queries unless privacy review approves it.
- KPI targets need a pre-change baseline. If no baseline exists, collect one before claiming the redesign passed or failed.

## 10. Rollout Plan

Preferred rollout:

1. Confirm baseline data first. If missing, run the measurement-only baseline period before visual rollout.
2. Use closed testing or a small pilot first, because no existing Remote Config pattern was found.
3. Include at least one venue with strong photos and one venue with weak/no photos.
4. Include one venue with many featured flags to validate governance and caps.
5. Compare interaction metrics before broader rollout.
6. Ship to all users only after manual QA passes and KPI gates are met or product explicitly accepts the tradeoff.

Optional feature-flag rollout:

- If product approves adding Remote Config, add it as a separate infrastructure task before the UI rollout.
- Do not block the UI plan on Remote Config unless a runtime kill switch is a hard product requirement.

Fallback rollout:

- Ship in the next normal mobile release after closed testing.
- Keep commits atomic so rollback is easy.
- Avoid schema dependencies so rollback is only a mobile rebuild.

Merchant communication:

- Explain that featured items use the existing featured flag.
- Explain the recommended featured limit so merchants do not mark every item as featured.
- Explain that section icons are automatic or based on configured section ids.
- Make clear that new photos improve presentation but are not required.

## 11. Risk Register

High risk:

- Overdesigning item rows and making long menus slow.
- Text overflow in Arabic on small screens.
- Breaking scroll-to-section behavior.
- Featured content pushing core menu content below the fold.
- Featured losing commercial meaning if too many merchant items are marked featured.
- KPI gate being interpreted without a valid baseline.
- Shipping broad UI changes without closed testing, a pilot, or a feature flag.
- Creating a two-tier visual experience where photo-rich merchants look premium and photo-poor merchants look neglected.

Medium risk:

- Featured row taking too much vertical space.
- Over-reliance on item photos, making photo-poor menus feel worse.
- Icons from `MenuSection.icon` not mapping cleanly.
- Details sheet growing too complex inside `venue_menu_tab.dart`.
- Analytics changes becoming noisy or privacy-sensitive.
- Visual regressions slipping through without golden coverage.
- Accessibility regressions in custom chips, cards, or bottom sheet controls.
- Golden tests becoming flaky because of remote image rendering.
- Image caching memory pressure on low-end Android devices.

Low risk:

- Header visual refresh.
- Price styling.
- Empty/no-results visual improvements.
- Preview card styling.

Mitigations:

- Keep Phase 1 schema-free.
- Keep item row dimensions predictable.
- Keep featured row height-bounded and item count capped.
- Show full-menu featured strip only with 3+ featured items.
- Enforce the Phase 1 display cap of 8 featured items.
- Design no-photo states as first-class, not fallbacks.
- Define featured governance for merchants/admins before broad rollout.
- Collect a comparable analytics baseline before evaluating KPI gates.
- Use deterministic image mocks for widget/golden tests.
- Add widget tests for overflow-prone layouts.
- Add explicit RTL tests for visually changed widgets.
- Add golden tests for stable high-risk states where feasible.
- Check tap target size and semantic labels for new interactive widgets.
- Do manual QA on real device before release.
- Pilot on photo-rich and photo-poor venues.
- Extract the item details sheet before visual expansion; avoid broad unrelated refactors.

## 12. Release Plan

Phase 1 does not require backend deploy.

Release steps:

1. Complete Ticket 0A/0B readiness work.
2. Confirm or collect baseline analytics before KPI evaluation.
3. Implement UI tickets.
4. Run targeted widget tests.
5. Run RTL and golden tests where added.
6. Run full Flutter tests if practical.
7. Capture before/after screenshots for review.
8. Build Android release artifact.
9. Test on a real device.
10. Pilot or ship with next mobile release depending on flag availability and product risk acceptance.

Rollback:

- Revert the Flutter UI commit.
- Rebuild and redistribute the previous mobile release if needed.

## 13. Open Decisions

Need approval before implementation:

- Use Canva first or go straight to Flutter implementation?
- Does product accept the Phase 1 featured governance defaults: preview-first, 3+ threshold, display cap 8, and client-only enforcement?
- Does product accept a 7-14 day baseline period before KPI evaluation if no comparable data exists?
- Should item rows be compact by default or more image-forward?
- Should the legacy menu image gallery appear above or below structured menu?
- Should details sheet include share/report actions now or later?
- Should product approve adding Remote Config as new infrastructure, or proceed with closed testing and atomic rollback?
- Do we add analytics in this sprint or keep it as a follow-up?
- Should unavailable items remain hidden, or should a future filter allow showing them?
- Do stakeholders accept the preliminary KPI gates, or do they need adjustment after baseline review?
- Which golden tests are stable enough to add without creating noisy CI failures?
- What exact accessibility labels should be used for Arabic screen readers?
- Should item details include a next action later, such as share/report/navigate, to improve business ROI without adding ordering?

Recommended decisions:

- Use one quick Canva board first.
- Honor the previous plan-review constraint: featured is preview-first.
- In the full menu, show featured only as a compact strip after search/category controls, and only with 3+ featured items.
- Use featured display cap 8 and recommended merchant/admin max `min(8, max(3, ceil(availableItems * 0.2)))`.
- If no comparable menu analytics exist, run baseline collection before KPI evaluation.
- Keep normal item rows compact, but make featured cards image-forward.
- Keep legacy images below structured menu.
- Defer share/report actions.
- Keep unavailable items hidden in Phase 1 because the current customer view already filters to available items.
- Add analytics through the existing `AnalyticsService` only if implementation stays small and privacy-safe.
- Do not add Remote Config in Phase 1 unless product explicitly wants the new infrastructure.
- Use preliminary KPI gates of +10% item-open rate, -10% no-interaction sessions, and no more than 5% time-to-first-interaction regression, then adjust only if the baseline proves those targets unrealistic.

## 14. Success Criteria

The refresh is successful when:

- The menu looks materially more premium on a real phone.
- Users can scan categories and prices faster.
- Featured items create a stronger first impression.
- Menus with poor photo coverage still look intentional.
- Large menus remain smooth.
- First useful content satisfies the 390x844 above-the-fold contract.
- Featured content increases discovery without reducing access to normal items.
- Featured governance prevents the strip from becoming a duplicate full menu.
- Existing search, category navigation, details sheet, and image fallback still work.
- Existing Firestore data continues to render without migration.
- Pilot or manual QA does not show a clear regression in menu interaction.
- Accessibility basics pass for touch targets, contrast, and screen-reader labels.
- Performance budget is met on a representative Android device.
- KPI gate is met before broad rollout, or product explicitly accepts the tradeoff.
