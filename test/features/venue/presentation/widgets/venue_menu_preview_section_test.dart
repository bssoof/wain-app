import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_preview_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';

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
    testWidgets('shows a single tappable CTA instead of preview items', (
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
      expect(find.text(l10n.menuViewFull), findsOneWidget);
      expect(find.text(l10n.menuResultsSummary(1, 1)), findsOneWidget);
      expect(find.text('Latte'), findsNothing);

      await tester.tap(find.text(l10n.menuViewFull));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
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
  });
}
