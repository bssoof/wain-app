// Regression suite for the venue menu category navigator.
//
// Every expectation here encodes the *intended* behaviour of the category
// header, not the current one. On HEAD 9b69e1c2 these tests are expected to
// FAIL; they are the acceptance gate for the navigation fix task.
//
// Audit findings covered:
//   F-01  active-section predicate uses absolute screen coordinates
//   F-02  forced resync 120ms after a tap reverts the selection
//   F-05  REJECTED_BY_TEST — see the R5 guard below
//   F-06  the last section cannot reach the target offset (clamp)
//   F-07  horizontal chip auto-scroll math is LTR-only
//   F-09  no ScrollEndNotification synchronisation
//
// The suite is fully offline: no Firestore, no network, no asset bundle.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_tab.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/l10n/app_localizations.dart';

const String _venueCategory = 'cafe';

/// A fixture owned by this suite, deliberately *not* the shipping demo catalog.
///
/// These tests pin the navigator's mechanics — the active-section predicate,
/// the programmatic lock, the clamp at the end of the list. Those must not
/// start failing because marketing added a menu section, and the geometry
/// preconditions each test asserts (a reachable mid-list section, a clamped
/// last section) depend on the list's size. Demo *content* is covered
/// separately by the demo catalog tests.
///
/// Photo urls are empty so the suite never touches the asset bundle or the
/// network; `_MenuItemThumbnail` renders a fixed 92x92 box either way, so the
/// vertical geometry is unchanged.
const List<MenuSection> _sections = <MenuSection>[
  MenuSection(id: 'hot_drinks', nameAr: 'مشروبات ساخنة', sortOrder: 1),
  MenuSection(id: 'cold_drinks', nameAr: 'مشروبات باردة', sortOrder: 2),
  MenuSection(id: 'juices', nameAr: 'عصائر طازجة', sortOrder: 3),
  MenuSection(id: 'desserts', nameAr: 'حلويات', sortOrder: 4),
  MenuSection(id: 'snacks', nameAr: 'وجبات خفيفة', sortOrder: 5),
];

final List<MenuItem> _demoItems = _itemsPerSection(2);

/// Fixture with [perSection] items in every demo section.
///
/// The demo catalog only has 2 items per section, which is below
/// [kVenueMenuPreviewLimit] — there, expanding a section changes colours but not
/// a single pixel of height. Tests that need expansion to actually move the
/// list geometry must use this instead.
List<MenuItem> _itemsPerSection(int perSection) {
  return <MenuItem>[
    for (final section in _sections)
      for (var i = 0; i < perSection; i += 1)
        MenuItem(
          id: '${section.id}_$i',
          nameAr: '${section.nameAr} صنف $i',
          price: 10 + i.toDouble(),
          category: section.id,
          sortOrder: i,
        ),
  ];
}

int _itemCountFor(MenuSection section, List<MenuItem> items) =>
    items.where((item) => item.category == section.id).length;

String _chipLabel(MenuSection section, [List<MenuItem>? items]) =>
    section.nameAr;

Venue _demoVenue() {
  return Venue(
    id: DemoMode.venueId,
    nameAr: DemoMode.venueNameAr,
    nameEn: DemoMode.venueNameEn,
    lat: 31.9,
    lng: 35.2,
    city: 'Ramallah',
    categories: const [_venueCategory],
    tags: const VenueTags(),
    minPrice: 10,
    maxPrice: 40,
    rating: 4.8,
    phone: '0590000000',
    menuImages: const [],
  );
}

/// Surface: 1600 x 640 logical.
///
/// The width is deliberately generous so the whole chip strip fits without any
/// horizontal scrolling — that isolates the *vertical* navigation logic under
/// test here. The RTL horizontal auto-scroll (F-07) is covered separately by
/// the narrow, standalone `VenueMenuCategoryChips` group below.
///
/// The height is chosen so mid-list sections are reachable while the last
/// section is forced into a `maxScrollExtent` clamp. Both properties are
/// asserted at runtime as explicit preconditions — never assumed.
Future<void> _pumpMenu(
  WidgetTester tester, {
  List<MenuItem>? items,
  Stream<List<MenuItem>>? itemStream,
  Size physicalSize = const Size(3200, 1280),
}) async {
  final menuItems = items ?? _demoItems;
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final venue = _demoVenue();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        menuItemsProvider(
          venue.id,
        ).overrideWith((ref) => itemStream ?? Stream.value(menuItems)),
        menuSectionsProvider(_venueCategory).overrideWith((ref) => _sections),
        menuActiveSectionsProvider(
          MenuActiveSectionsQuery(
            venueId: venue.id,
            venueCategory: _venueCategory,
          ),
        ).overrideWith((ref) => Stream.value(_sections)),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(title: const Text('menu')),
          body: VenueMenuTab(venue: venue),
        ),
      ),
    ),
  );

  // Two plain pumps let the overridden streams emit before the shimmer
  // skeleton's repeating controller can deadlock `pumpAndSettle`.
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

ScrollPosition _menuPosition(WidgetTester tester) {
  return tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .firstWhere((state) => state.position.axis == Axis.vertical)
      .position;
}

String _selectedChip(WidgetTester tester) {
  final labels = tester
      .widgetList<Semantics>(
        find.descendant(
          of: find.byType(VenueMenuCategoryChips),
          matching: find.byType(Semantics),
        ),
      )
      .where((semantics) => semantics.properties.selected == true)
      .map((semantics) => semantics.properties.label ?? '')
      .toList();
  if (labels.isEmpty) return '<no chip selected>';
  if (labels.length > 1) return '<multiple selected: ${labels.join(" | ")}>';
  return labels.single;
}

/// Taps a category chip and lets the whole programmatic-scroll pipeline drain:
/// the end-of-frame handoff, the 200ms animateTo, the estimate path's
/// correction pass, and the ScrollEnd synchronisation that follows.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final finder = find.descendant(
    of: find.byType(VenueMenuCategoryChips),
    matching: find.text(label),
  );
  expect(finder, findsOneWidget, reason: 'category chip "$label" must exist');

  // Precondition: the surface is wide enough that no horizontal scrolling is
  // needed, so the tap lands on the chip itself rather than silently missing.
  final stripRect = tester.getRect(find.byType(VenueMenuCategoryChips));
  final chipRect = tester.getRect(finder);
  expect(
    chipRect.left >= stripRect.left - 0.5 &&
        chipRect.right <= stripRect.right + 0.5,
    isTrue,
    reason:
        'precondition: chip "$label" ($chipRect) must be fully inside the '
        'strip ($stripRect); widen the test surface if this fails',
  );

  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

Future<void> _flingToBottom(WidgetTester tester) async {
  for (var attempt = 0; attempt < 6; attempt += 1) {
    final position = _menuPosition(tester);
    if (position.pixels >= position.maxScrollExtent - 0.5) return;
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -600),
      8000,
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  group('VenueMenuTab — category navigation regression', () {
    testWidgets(
      'R1 (case 1) forward sequence hot->cold->juices->desserts->snacks keeps '
      'the tapped section active',
      (tester) async {
        await _pumpMenu(tester);

        for (final section in _sections) {
          final label = _chipLabel(section);
          await _tapChip(tester, label);
          expect(
            _selectedChip(tester),
            label,
            reason:
                'after tapping "$label" the active chip must stay on it; a '
                'previous-section value proves F-01/F-02',
          );
        }
      },
    );

    testWidgets(
      'R2 (case 2) reverse jump snacks -> hot_drinks keeps each tapped section '
      'active',
      (tester) async {
        await _pumpMenu(tester);

        final snacks = _sections.last;
        final hotDrinks = _sections.first;

        await _tapChip(tester, _chipLabel(snacks));
        expect(
          _selectedChip(tester),
          _chipLabel(snacks),
          reason: 'jumping to the last section must select it (F-02/F-06)',
        );

        await _tapChip(tester, _chipLabel(hotDrinks));
        expect(
          _selectedChip(tester),
          _chipLabel(hotDrinks),
          reason: 'jumping back to the first section must select it',
        );
      },
    );

    testWidgets(
      'R3 (case 5) fling to the end of the menu selects the last section',
      (tester) async {
        await _pumpMenu(tester);
        await _flingToBottom(tester);

        final position = _menuPosition(tester);
        expect(
          position.pixels,
          closeTo(position.maxScrollExtent, 1.0),
          reason: 'precondition: the fling must land at maxScrollExtent',
        );
        expect(
          _selectedChip(tester),
          _chipLabel(_sections.last),
          reason:
              'at the bottom of the list the last section is the visible one; '
              'a stale chip proves F-01/F-09',
        );
      },
    );

    testWidgets(
      'R4 (case 14) tapping the last chip keeps it active even when the scroll '
      'clamps at maxScrollExtent',
      (tester) async {
        await _pumpMenu(tester);

        final snacks = _sections.last;
        await _tapChip(tester, _chipLabel(snacks));

        final position = _menuPosition(tester);
        expect(
          position.pixels,
          closeTo(position.maxScrollExtent, 1.0),
          reason:
              'precondition: the last section cannot reach the pinned-header '
              'line, so the jump must clamp at maxScrollExtent',
        );
        expect(
          _selectedChip(tester),
          _chipLabel(snacks),
          reason:
              'a clamped jump is still a successful jump; the chip must stay '
              'on the requested section (F-02/F-06)',
        );
      },
    );

    // GUARD TEST — this one already PASSED on HEAD 9b69e1c2, before the fix.
    //
    // F-05 = REJECTED_BY_TEST. Two measurements on Flutter 3.41.7:
    //   * `ensureVisible(alignment: 0.10)` landed the target 72.5px below the
    //     viewport top, i.e. 50 + 0.10 * (584 - 50 - 309).
    //   * `getOffsetToReveal(box, 0.0).offset` came back exactly 50.0 lower
    //     than the naive "top at viewport top" offset.
    // Both say the SDK already subtracts the pinned header's obstruction
    // extent, so audit hypothesis F is wrong and nothing may subtract
    // kVenueMenuPinnedHeaderHeight a second time. The fix therefore uses
    // `alignment: 0.0`, which lands the section top exactly on the line the
    // active-section predicate tests against. This guard pins that invariant.
    testWidgets(
      'R5 (guard) a reachable target section clears the pinned header',
      (tester) async {
        await _pumpMenu(tester);

        final juices = _sections[2];
        await _tapChip(tester, _chipLabel(juices));

        final position = _menuPosition(tester);
        expect(
          position.pixels,
          lessThan(position.maxScrollExtent - 1.0),
          reason:
              'precondition: this target must NOT be clamped, so any failure '
              'below is attributable to alignment, not to F-06',
        );

        final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
        final blockTop = tester
            .getTopLeft(
              find.ancestor(
                of: find.text(juices.nameAr),
                matching: find.byType(VenueMenuSectionBlock),
              ),
            )
            .dy;

        expect(
          blockTop - viewportTop,
          greaterThanOrEqualTo(kVenueMenuPinnedHeaderHeight),
          reason:
              'the section header must land below the pinned category header, '
              'not behind it (F-05)',
        );
      },
    );
  });

  group('VenueMenuTab — expansion intent', () {
    Finder blockOf(MenuSection section) => find.ancestor(
      of: find.text(section.nameAr),
      matching: find.byType(VenueMenuSectionBlock),
    );

    Finder headerOf(MenuSection section) => find.descendant(
      of: blockOf(section),
      matching: find.text(section.nameAr),
    );

    int tileCount(WidgetTester tester, MenuSection section) => tester
        .widgetList(
          find.descendant(
            of: blockOf(section),
            matching: find.byType(VenueMenuItemTile),
          ),
        )
        .length;

    testWidgets(
      'R8 re-tapping the same chip re-expands a manually collapsed section',
      (tester) async {
        const perSection = 6;
        final items = _itemsPerSection(perSection);
        await _pumpMenu(tester, items: items);

        final target = _sections[1];
        final label = _chipLabel(target, items);

        await _tapChip(tester, label);
        expect(
          tileCount(tester, target),
          perSection,
          reason: 'a chip tap must expand the section',
        );

        // Collapse it by hand, the way a user would.
        await tester.tap(headerOf(target));
        await tester.pumpAndSettle();
        expect(
          tileCount(tester, target),
          kVenueMenuPreviewLimit,
          reason: 'tapping the section header must collapse it',
        );

        await _tapChip(tester, label);
        expect(
          tileCount(tester, target),
          perSection,
          reason:
              'tapping the SAME chip again must expand it again; an expand '
              'request carrying only a section id cannot notify here because '
              'the id did not change',
        );
      },
    );

    testWidgets(
      'R9 jumping to an unbuilt section lands its header on the pinned-header '
      'line even when an earlier section is expanded',
      (tester) async {
        const perSection = 6;
        final items = _itemsPerSection(perSection);
        // Short viewport (400 logical tall) so later sections stay outside the
        // lazy build + cache extent.
        await _pumpMenu(
          tester,
          items: items,
          physicalSize: const Size(3200, 800),
        );

        final firstSection = _sections.first;
        final target = _sections[2];

        // Expand an earlier section by hand: every collapsed-height estimate
        // for it is now wrong by (perSection - previewLimit) rows.
        //
        // The header must be scrolled into the viewport first — on this short
        // surface its natural position is below the fold, and a tap dispatched
        // at an off-screen y never reaches it.
        final firstHeader = headerOf(firstSection);
        await tester.ensureVisible(firstHeader);
        await tester.pumpAndSettle();
        final headerCentre = tester.getCenter(firstHeader);
        final viewportSize =
            tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(
          headerCentre.dy >= 0 && headerCentre.dy <= viewportSize.height,
          isTrue,
          reason: 'precondition: the tap target must land inside the viewport',
        );
        await tester.tap(firstHeader);
        await tester.pumpAndSettle();
        expect(
          tileCount(tester, firstSection),
          perSection,
          reason: 'precondition: the earlier section must be expanded',
        );
        expect(
          blockOf(target),
          findsNothing,
          reason: 'precondition: the target section must still be unbuilt',
        );

        await _tapChip(tester, _chipLabel(target, items));

        final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
        final blockTop = tester.getTopLeft(blockOf(target)).dy;
        expect(
          blockTop - viewportTop,
          closeTo(kVenueMenuPinnedHeaderHeight, 2.0),
          reason:
              'the target header must actually land on the line, not merely '
              'leave the chip selected',
        );
      },
    );

    testWidgets(
      'R10 a menu-data rebuild does not replay a spent expand request',
      (tester) async {
        const perSection = 6;
        final items = _itemsPerSection(perSection);

        // Single-subscription controller: the seed event is buffered until the
        // StreamProvider subscribes.
        final controller = StreamController<List<MenuItem>>();
        addTearDown(controller.close);
        controller.add(items);

        await _pumpMenu(tester, items: items, itemStream: controller.stream);

        final target = _sections[1];
        await _tapChip(tester, _chipLabel(target, items));
        expect(
          tileCount(tester, target),
          perSection,
          reason: 'precondition: the chip tap must expand the section',
        );

        await tester.tap(headerOf(target));
        await tester.pumpAndSettle();
        expect(
          tileCount(tester, target),
          kVenueMenuPreviewLimit,
          reason: 'precondition: the user collapsed it by hand',
        );

        // A provider/menu update with no chip tap anywhere in sight.
        controller.add(List<MenuItem>.of(items));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          tileCount(tester, target),
          kVenueMenuPreviewLimit,
          reason:
              'an unrelated rebuild must not re-open a section the user '
              'closed; a spent expand request has to be retired, not kept',
        );
      },
    );
  });

  group('VenueMenuCategoryChips — horizontal auto-scroll (F-07)', () {
    Future<void> pumpChips(
      WidgetTester tester, {
      required TextDirection direction,
      required String selectedId,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: VenueMenuCategoryChips(
                    sections: _sections,
                    selectedSectionId: selectedId,
                    onSelected: (_) {},
                    totalCount: _demoItems.length,
                    sectionItemCounts: <String, int>{
                      for (final section in _sections)
                        section.id: _itemCountFor(section, _demoItems),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> expectLastChipRevealed(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await pumpChips(tester, direction: direction, selectedId: 'all');
      // Same tree shape, new selection -> didUpdateWidget -> _scrollToSelectedChip.
      await pumpChips(
        tester,
        direction: direction,
        selectedId: _sections.last.id,
      );

      final viewport = tester.getRect(find.byType(VenueMenuCategoryChips));
      final chip = tester.getRect(
        find.descendant(
          of: find.byType(VenueMenuCategoryChips),
          matching: find.text(_chipLabel(_sections.last)),
        ),
      );

      // The 0.3-alignment heuristic cannot guarantee 100% visibility for a chip
      // wider than 70% of the strip, so full containment is the wrong property
      // to assert. What must always hold is that the auto-scroll moves in the
      // correct direction: the selected chip's centre ends up inside the strip.
      expect(
        chip.center.dx,
        inInclusiveRange(viewport.left, viewport.right),
        reason:
            'auto-scroll must reveal the selected chip in $direction; a centre '
            'outside the strip means it scrolled the wrong way (F-07). '
            'chip=$chip strip=$viewport',
      );
    }

    testWidgets('R6 RTL reveals the selected chip', (tester) async {
      await expectLastChipRevealed(tester, TextDirection.rtl);
    });

    testWidgets('R7 LTR reveals the selected chip (control)', (tester) async {
      await expectLastChipRevealed(tester, TextDirection.ltr);
    });
  });
}
