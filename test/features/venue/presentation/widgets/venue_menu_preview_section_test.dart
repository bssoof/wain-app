import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_preview_section.dart';
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

void main() {
  group('VenueMenuPreviewSection', () {
    testWidgets('shows simplified featured preview and opens full menu card', (
      tester,
    ) async {
      final venue = _makeVenue();
      var opened = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuItemsProvider(venue.id).overrideWith(
              (ref) => Stream.value(const [
                MenuItem(
                  id: 'item-1',
                  nameAr: 'Latte',
                  price: 18,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: true,
                  isFeatured: true,
                ),
              ]),
            ),
          ],
          child: _app(
            VenueMenuPreviewSection(
              venue: venue,
              onOpenMenu: () => opened = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

      expect(find.text(l10n.menuTitle), findsOneWidget);
      expect(find.text(l10n.menuViewFull), findsNothing);
      expect(find.text(l10n.menuResultsSummary(1, 1)), findsOneWidget);
      expect(find.text(l10n.featuredItems), findsOneWidget);
      expect(find.text('Latte'), findsOneWidget);
      expect(find.text('18 ₪'), findsOneWidget);
      final horizontalStrip = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(horizontalStrip.scrollDirection, Axis.horizontal);

      await tester.tap(find.text(l10n.menuTitle));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('filters sorts and caps featured preview items', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuItemsProvider(venue.id).overrideWith(
              (ref) => Stream.value(const [
                MenuItem(
                  id: 'featured-c',
                  nameAr: 'Featured C',
                  price: 13,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: true,
                  isFeatured: true,
                  sortOrder: 3,
                ),
                MenuItem(
                  id: 'featured-a',
                  nameAr: 'Featured A',
                  price: 11,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: true,
                  isFeatured: true,
                  sortOrder: 1,
                ),
                MenuItem(
                  id: 'featured-b',
                  nameAr: 'Featured B',
                  price: 12,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: true,
                  isFeatured: true,
                  sortOrder: 2,
                ),
                MenuItem(
                  id: 'featured-d',
                  nameAr: 'Featured D',
                  price: 14,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: true,
                  isFeatured: true,
                  sortOrder: 4,
                ),
                MenuItem(
                  id: 'unavailable-featured',
                  nameAr: 'Unavailable Featured',
                  price: 15,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: false,
                  isFeatured: true,
                ),
                MenuItem(
                  id: 'normal',
                  nameAr: 'Normal Item',
                  price: 16,
                  currency: 'ILS',
                  category: 'coffee',
                ),
              ]),
            ),
          ],
          child: _app(VenueMenuPreviewSection(venue: venue, onOpenMenu: () {})),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Featured A'), findsOneWidget);
      expect(find.text('Featured B'), findsOneWidget);
      expect(find.text('Featured C'), findsOneWidget);
      expect(find.text('Featured D'), findsNothing);
      expect(find.text('Unavailable Featured'), findsNothing);
      expect(find.text('Normal Item'), findsNothing);
    });

    testWidgets('opens details sheet from featured preview item', (
      tester,
    ) async {
      final venue = _makeVenue();
      final analytics = RecordingAnalyticsService();
      var opened = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWithValue(analytics),
            menuItemsProvider(venue.id).overrideWith(
              (ref) => Stream.value(const [
                MenuItem(
                  id: 'item-1',
                  nameAr: 'Latte',
                  price: 18,
                  currency: 'ILS',
                  category: 'coffee',
                  isAvailable: true,
                  isFeatured: true,
                ),
              ]),
            ),
          ],
          child: _app(
            VenueMenuPreviewSection(
              venue: venue,
              onOpenMenu: () => opened = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Latte'));
      await tester.pumpAndSettle();

      expect(find.byType(VenueMenuItemDetailsSheet), findsOneWidget);
      expect(opened, isFalse);
      final itemOpenEvent = analytics.eventNamed('venue_menu_item_open');
      expect(itemOpenEvent, isNotNull);
      expect(itemOpenEvent!.parameters?['venue_id'], venue.id);
      expect(itemOpenEvent.parameters?['item_id'], 'item-1');
      expect(itemOpenEvent.parameters?['section_id'], 'coffee');
      expect(itemOpenEvent.parameters?['surface'], 'preview_featured');
      expect(itemOpenEvent.parameters?['is_featured'], isTrue);
    });

    testWidgets('shows unavailable state when venue has no menu content', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuItemsProvider(
              venue.id,
            ).overrideWith((ref) => Stream.value(const <MenuItem>[])),
          ],
          child: _app(VenueMenuPreviewSection(venue: venue, onOpenMenu: () {})),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

      expect(find.text(l10n.noMenuAvailable), findsOneWidget);
      expect(find.text(l10n.menuViewFull), findsNothing);
    });

    testWidgets('shows image-only menu preview instead of unavailable state', (
      tester,
    ) async {
      final venue = _makeVenue(
        menuImages: const [
          'https://example.test/menu-image-1.png',
          'https://example.test/menu-image-2.png',
          'https://example.test/menu-image-3.png',
          'https://example.test/menu-image-4.png',
        ],
      );
      var opened = false;

      await runWithTestImageHttpOverrides(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              menuItemsProvider(
                venue.id,
              ).overrideWith((ref) => Stream.value(const <MenuItem>[])),
            ],
            child: _app(
              VenueMenuPreviewSection(
                venue: venue,
                onOpenMenu: () => opened = true,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.noMenuAvailable), findsNothing);
      expect(find.text(l10n.menuPhotosTitle), findsOneWidget);
      expect(find.text('4 ${l10n.photoPlural}'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);

      await tester.tap(find.text(l10n.menuTitle));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
