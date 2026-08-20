import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/screens/venue_menu_screen.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_tab.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../../../helpers/test_image_http_overrides.dart';
import '../../../../helpers/recording_analytics_service.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Widget _screenApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Finder _menuScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

Venue _makeVenue({List<String> menuImages = const []}) {
  return Venue(
    id: 'venue-1',
    nameAr: 'Cafe',
    nameEn: 'Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'Hebron',
    categories: const ['cafe'],
    tags: const VenueTags(),
    minPrice: 20,
    maxPrice: 80,
    rating: 4.7,
    phone: '0590000000',
    menuImages: menuImages,
  );
}

MenuItem _item(
  String id, {
  String? nameAr,
  String category = 'hot_drinks',
  bool isFeatured = false,
  bool isAvailable = true,
  int sortOrder = 0,
}) {
  return MenuItem(
    id: id,
    nameAr: nameAr ?? id,
    price: 12,
    currency: 'ILS',
    category: category,
    isAvailable: isAvailable,
    isFeatured: isFeatured,
    sortOrder: sortOrder,
  );
}

Widget _menuTab({
  required Venue venue,
  required List<MenuItem> items,
  RecordingAnalyticsService? analytics,
}) {
  const sections = [
    MenuSection(id: 'hot_drinks', nameAr: 'مشروبات ساخنة', icon: 'coffee'),
    MenuSection(id: 'desserts', nameAr: 'حلويات', icon: 'desserts'),
    MenuSection(
      id: 'main_courses',
      nameAr: 'أطباق رئيسية',
      icon: 'main_courses',
    ),
  ];
  const venueCategory = 'cafe';
  const activeSectionsQuery = MenuActiveSectionsQuery(
    venueId: 'venue-1',
    venueCategory: venueCategory,
  );

  return ProviderScope(
    overrides: [
      analyticsServiceProvider.overrideWithValue(
        analytics ?? RecordingAnalyticsService(),
      ),
      menuItemsProvider(venue.id).overrideWith((ref) => Stream.value(items)),
      menuSectionsProvider(venueCategory).overrideWith((ref) => sections),
      menuActiveSectionsProvider(
        activeSectionsQuery,
      ).overrideWith((ref) => Stream.value(sections)),
    ],
    child: _app(VenueMenuTab(venue: venue)),
  );
}

void main() {
  group('VenueMenuScreen', () {
    testWidgets('shows menu title only in app bar without venue name', (
      tester,
    ) async {
      final venue = _makeVenue();
      const venueCategory = 'cafe';
      const activeSectionsQuery = MenuActiveSectionsQuery(
        venueId: 'venue-1',
        venueCategory: venueCategory,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWithValue(
              RecordingAnalyticsService(),
            ),
            venueByIdProvider(venue.id).overrideWith((ref) async => venue),
            menuItemsProvider(venue.id).overrideWith(
              (ref) => Stream.value([_item('coffee-1', nameAr: 'Coffee')]),
            ),
            menuSectionsProvider(venueCategory).overrideWith(
              (ref) => const [
                MenuSection(
                  id: 'hot_drinks',
                  nameAr: 'مشروبات ساخنة',
                  icon: 'coffee',
                ),
              ],
            ),
            menuActiveSectionsProvider(activeSectionsQuery).overrideWith(
              (ref) => Stream.value(const [
                MenuSection(
                  id: 'hot_drinks',
                  nameAr: 'مشروبات ساخنة',
                  icon: 'coffee',
                ),
              ]),
            ),
          ],
          child: _screenApp(VenueMenuScreen(venueId: venue.id)),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.menuTitle), findsOneWidget);
      expect(find.text(venue.nameAr), findsNothing);
    });
  });

  group('VenueMenuTab featured row', () {
    testWidgets('logs menu view once and no-interaction timeout', (
      tester,
    ) async {
      final venue = _makeVenue();
      final analytics = RecordingAnalyticsService();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          analytics: analytics,
          items: [
            _item('featured-1', nameAr: 'Featured 1', isFeatured: true),
            _item('featured-2', nameAr: 'Featured 2', isFeatured: true),
            _item('featured-3', nameAr: 'Featured 3', isFeatured: true),
            _item('normal', nameAr: 'Normal Item', category: 'desserts'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final viewEvents = analytics.eventsNamed('venue_menu_view').toList();
      expect(viewEvents, hasLength(1));
      expect(viewEvents.single.parameters?['venue_id'], venue.id);
      expect(viewEvents.single.parameters?['source'], 'full_menu');
      expect(viewEvents.single.parameters?['menu_mode'], 'structured');
      expect(viewEvents.single.parameters?['item_count'], 4);
      expect(viewEvents.single.parameters?['section_count'], 2);
      expect(viewEvents.single.parameters?['featured_count'], 3);

      await tester.pump(const Duration(seconds: 10));
      expect(analytics.eventsNamed('venue_menu_no_interaction'), hasLength(1));
      await tester.pump(const Duration(seconds: 10));
      expect(analytics.eventsNamed('venue_menu_no_interaction'), hasLength(1));
    });

    testWidgets('shows full-menu featured strip for three or more items', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          items: [
            _item(
              'featured-2',
              nameAr: 'Featured 2',
              isFeatured: true,
              sortOrder: 2,
            ),
            _item(
              'featured-1',
              nameAr: 'Featured 1',
              isFeatured: true,
              sortOrder: 1,
            ),
            _item(
              'featured-3',
              nameAr: 'Featured 3',
              isFeatured: true,
              sortOrder: 3,
            ),
            _item('normal', nameAr: 'Normal Item'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      final row = tester.widget<VenueFeaturedItemsRow>(
        find.byType(VenueFeaturedItemsRow),
      );

      expect(find.text(l10n.featuredItems), findsOneWidget);
      expect(row.items.map((item) => item.id), [
        'featured-1',
        'featured-2',
        'featured-3',
      ]);
      expect(find.text('Featured 1'), findsWidgets);
    });

    testWidgets('hides full-menu featured strip below threshold', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          items: [
            _item('featured-1', nameAr: 'Featured 1', isFeatured: true),
            _item('featured-2', nameAr: 'Featured 2', isFeatured: true),
            _item('normal', nameAr: 'Normal Item'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VenueFeaturedItemsRow), findsNothing);
      expect(find.text('Featured 1'), findsOneWidget);
    });

    testWidgets('caps full-menu featured strip at eight items', (tester) async {
      final venue = _makeVenue();
      final items = List<MenuItem>.generate(
        10,
        (index) => _item(
          'featured-$index',
          nameAr: 'Featured $index',
          isFeatured: true,
          sortOrder: index,
        ),
      );

      await tester.pumpWidget(_menuTab(venue: venue, items: items));
      await tester.pumpAndSettle();

      final row = tester.widget<VenueFeaturedItemsRow>(
        find.byType(VenueFeaturedItemsRow),
      );

      expect(row.items.length, 8);
      expect(row.items.map((item) => item.id), [
        'featured-0',
        'featured-1',
        'featured-2',
        'featured-3',
        'featured-4',
        'featured-5',
        'featured-6',
        'featured-7',
      ]);
    });

    testWidgets('hides full-menu featured strip while searching', (
      tester,
    ) async {
      final venue = _makeVenue();
      final analytics = RecordingAnalyticsService();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          analytics: analytics,
          items: [
            _item('featured-1', nameAr: 'Featured 1', isFeatured: true),
            _item('featured-2', nameAr: 'Featured 2', isFeatured: true),
            _item('featured-3', nameAr: 'Featured 3', isFeatured: true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VenueFeaturedItemsRow), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Featured 1');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(VenueFeaturedItemsRow), findsNothing);
      expect(find.text('Featured 1'), findsNWidgets(2));

      final searchEvent = analytics.eventNamed('venue_menu_search');
      expect(searchEvent, isNotNull);
      expect(searchEvent!.parameters?['venue_id'], venue.id);
      expect(searchEvent.parameters?['query_length'], 'featured 1'.length);
      expect(searchEvent.parameters?['result_count'], 1);
      expect(searchEvent.parameters?.containsKey('query'), isFalse);
      expect(searchEvent.parameters?.containsValue('Featured 1'), isFalse);
    });

    testWidgets('opens details sheet from full-menu featured card', (
      tester,
    ) async {
      final venue = _makeVenue();
      final analytics = RecordingAnalyticsService();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          analytics: analytics,
          items: [
            _item('featured-1', nameAr: 'Featured 1', isFeatured: true),
            _item('featured-2', nameAr: 'Featured 2', isFeatured: true),
            _item('featured-3', nameAr: 'Featured 3', isFeatured: true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(VenueMenuFeaturedCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(VenueMenuItemDetailsSheet), findsOneWidget);
      final itemOpenEvent = analytics.eventNamed('venue_menu_item_open');
      expect(itemOpenEvent, isNotNull);
      expect(itemOpenEvent!.parameters?['venue_id'], venue.id);
      expect(itemOpenEvent.parameters?['item_id'], 'featured-1');
      expect(itemOpenEvent.parameters?['section_id'], 'hot_drinks');
      expect(itemOpenEvent.parameters?['surface'], 'featured_strip');
      expect(itemOpenEvent.parameters?['is_featured'], isTrue);
      expect(analytics.eventsNamed('venue_menu_no_interaction'), isEmpty);
    });

    testWidgets('logs category chip selection', (tester) async {
      final venue = _makeVenue();
      final analytics = RecordingAnalyticsService();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          analytics: analytics,
          items: [
            _item('coffee-1', nameAr: 'Coffee'),
            _item('cake-1', nameAr: 'Cake', category: 'desserts'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('حلويات').first);
      await tester.pumpAndSettle();

      final categoryEvent = analytics.eventNamed('venue_menu_category_select');
      expect(categoryEvent, isNotNull);
      expect(categoryEvent!.parameters?['venue_id'], venue.id);
      expect(categoryEvent.parameters?['section_id'], 'desserts');
      expect(categoryEvent.parameters?['item_count'], 1);
    });

    testWidgets('shows search first with count and no full menu header', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          items: [
            _item('coffee-1', nameAr: 'Coffee'),
            _item('cake-1', nameAr: 'Cake', category: 'desserts'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('2 ${l10n.menuItemCounter}'), findsOneWidget);
      expect(find.text(l10n.menuTitle), findsNothing);
    });

    testWidgets('keeps all selected after all tab scrolls to menu top', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        _menuTab(
          venue: venue,
          items: [
            _item('coffee-1', nameAr: 'Coffee'),
            _item('cake-1', nameAr: 'Cake', category: 'desserts'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      await tester.tap(find.text('حلويات').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        'desserts',
      );

      await tester.tap(find.text(l10n.all));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        'all',
      );
    });

    testWidgets('syncs selected tab down and back up while scrolling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final venue = _makeVenue();
      final items = [
        for (var index = 0; index < 6; index++)
          _item(
            'coffee-$index',
            nameAr: 'Coffee $index',
            category: 'hot_drinks',
            sortOrder: index,
          ),
        for (var index = 0; index < 6; index++)
          _item(
            'dessert-$index',
            nameAr: 'Dessert $index',
            category: 'desserts',
            sortOrder: index,
          ),
        for (var index = 0; index < 6; index++)
          _item(
            'main-$index',
            nameAr: 'Main $index',
            category: 'main_courses',
            sortOrder: index,
          ),
      ];

      await tester.pumpWidget(_menuTab(venue: venue, items: items));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        'all',
      );

      await tester.scrollUntilVisible(
        find.text('Main 0'),
        600,
        scrollable: _menuScrollable(),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        isNot('all'),
      );

      await tester.dragUntilVisible(
        find.byType(TextField),
        _menuScrollable(),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        'all',
      );
    });

    testWidgets('keeps category scroll sync enabled for large menus', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final venue = _makeVenue();
      final items = [
        for (var index = 0; index < 130; index++)
          _item(
            'coffee-$index',
            nameAr: 'Coffee $index',
            category: 'hot_drinks',
            sortOrder: index,
          ),
        for (var index = 0; index < 6; index++)
          _item(
            'dessert-$index',
            nameAr: 'Dessert $index',
            category: 'desserts',
            sortOrder: index,
          ),
        for (var index = 0; index < 6; index++)
          _item(
            'main-$index',
            nameAr: 'Main $index',
            category: 'main_courses',
            sortOrder: index,
          ),
      ];

      await tester.pumpWidget(_menuTab(venue: venue, items: items));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Main 0'),
        600,
        scrollable: _menuScrollable(),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        isNot('all'),
      );
    });

    testWidgets('category selection scrolls and expands the tapped section', (
      tester,
    ) async {
      final venue = _makeVenue();
      final items = [
        for (var index = 0; index < 5; index++)
          _item(
            'dessert-$index',
            nameAr: 'Dessert $index',
            category: 'desserts',
            sortOrder: index,
          ),
        _item('coffee-1', nameAr: 'Coffee'),
      ];

      await tester.pumpWidget(_menuTab(venue: venue, items: items));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حلويات').first);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<VenueMenuCategoryChips>(find.byType(VenueMenuCategoryChips))
            .selectedSectionId,
        'desserts',
      );
      expect(find.text('Dessert 0'), findsOneWidget);
      expect(find.text('Dessert 3'), findsOneWidget);
      expect(find.text('Dessert 4'), findsOneWidget);
      final dessertBlock = find.byWidgetPredicate(
        (widget) =>
            widget is VenueMenuSectionBlock && widget.section.id == 'desserts',
      );
      expect(
        find.descendant(of: dessertBlock, matching: find.text('5')),
        findsOneWidget,
      );
    });
  });

  group('VenueMenuTab image gallery', () {
    testWidgets('uses gallery as primary content for image-only menus', (
      tester,
    ) async {
      final venue = _makeVenue(
        menuImages: const [
          'https://example.test/menu-image-1.png',
          'https://example.test/menu-image-2.png',
        ],
      );
      final analytics = RecordingAnalyticsService();

      await runWithTestImageHttpOverrides(() async {
        await tester.pumpWidget(
          _menuTab(venue: venue, analytics: analytics, items: const []),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.noMenuAvailable), findsNothing);
      expect(find.text(l10n.menuPhotosTitle), findsOneWidget);
      expect(find.text('2 ${l10n.photoPlural}'), findsAtLeastNWidgets(1));
      expect(find.byType(VenueMenuImageGallery), findsOneWidget);
      final viewEvent = analytics.eventNamed('venue_menu_view');
      expect(viewEvent, isNotNull);
      expect(viewEvent!.parameters?['menu_mode'], 'image_only');
      expect(viewEvent.parameters?['image_count'], 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('logs legacy menu image opens without image URLs', (
      tester,
    ) async {
      final venue = _makeVenue(
        menuImages: const [
          'https://example.test/menu-image-1.png',
          'https://example.test/menu-image-2.png',
        ],
      );
      final analytics = RecordingAnalyticsService();

      await runWithTestImageHttpOverrides(() async {
        await tester.pumpWidget(
          _menuTab(venue: venue, analytics: analytics, items: const []),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(CachedNetworkImage).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      final imageOpenEvent = analytics.eventNamed('venue_menu_image_open');
      expect(imageOpenEvent, isNotNull);
      expect(imageOpenEvent!.parameters?['venue_id'], venue.id);
      expect(imageOpenEvent.parameters?['image_index'], 0);
      expect(imageOpenEvent.parameters?['surface'], 'full_menu_gallery');
      expect(imageOpenEvent.parameters?.containsKey('url'), isFalse);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('VenueMenuTab release stress', () {
    testWidgets('keeps a 300 item structured menu stable on phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final venue = _makeVenue();
      final analytics = RecordingAnalyticsService();
      final items = List<MenuItem>.generate(
        300,
        (index) => _item(
          'large-$index',
          nameAr: 'Item $index صنف طويل عربي English',
          category: index.isEven ? 'hot_drinks' : 'desserts',
          sortOrder: index,
        ),
      );

      await tester.pumpWidget(
        _menuTab(venue: venue, analytics: analytics, items: items),
      );
      await tester.pumpAndSettle();

      final viewEvents = analytics.eventsNamed('venue_menu_view').toList();
      expect(viewEvents, hasLength(1));
      expect(viewEvents.single.parameters?['menu_mode'], 'structured');
      expect(viewEvents.single.parameters?['item_count'], 300);
      expect(viewEvents.single.parameters?['section_count'], 2);
      expect(find.byType(VenueMenuSectionBlock), findsWidgets);
      expect(find.text('4/150'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
