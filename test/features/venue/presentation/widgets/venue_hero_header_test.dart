import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/try_list/presentation/providers/try_list_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_hero_header.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Venue _makeVenue({List<String> photos = const []}) {
  return Venue(
    id: 'venue-1',
    nameAr: 'Cafe',
    nameEn: 'Cafe',
    lat: 31.9,
    lng: 35.2,
    city: 'Amman',
    categories: const ['cafe'],
    tags: const VenueTags(),
    minPrice: 10,
    maxPrice: 50,
    rating: 4.5,
    phone: '+962790000000',
    photos: photos,
  );
}

void main() {
  group('VenueHeroHeader', () {
    testWidgets('renders sliver header with actions and photo counter', (
      tester,
    ) async {
      final venue = _makeVenue(
        photos: const [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isInTryListProvider(venue.id).overrideWith((ref) async => false),
          ],
          child: _app(
            Scaffold(
              body: CustomScrollView(
                slivers: [
                  VenueHeroHeader(
                    venue: venue,
                    isFavorite: false,
                    displayTags: const ['cozy', 'romantic'],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byKey(const ValueKey('venue-photo-dot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('venue-photo-dot-1')), findsOneWidget);
      expect(find.text('Cafe'), findsWidgets);
    });

    testWidgets('opens all venue features when the overflow chip is tapped', (
      tester,
    ) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isInTryListProvider(venue.id).overrideWith((ref) async => false),
          ],
          child: _app(
            Scaffold(
              body: CustomScrollView(
                slivers: [
                  VenueHeroHeader(
                    venue: venue,
                    isFavorite: false,
                    displayTags: const [
                      'هادئ',
                      'عائلي',
                      'رومانسي',
                      'خارجي',
                      'مناسب للعمل',
                      'مجموعات',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+4'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('venue-more-features')));
      await tester.pumpAndSettle();

      expect(find.text('صفات المكان'), findsOneWidget);
      expect(find.text('رومانسي'), findsOneWidget);
      expect(find.text('خارجي'), findsOneWidget);
      expect(find.text('مناسب للعمل'), findsOneWidget);
      expect(find.text('مجموعات'), findsOneWidget);
    });

    testWidgets('shows fallback icon when venue has no photos', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isInTryListProvider(venue.id).overrideWith((ref) async => false),
          ],
          child: _app(
            Scaffold(
              body: CustomScrollView(
                slivers: [
                  VenueHeroHeader(
                    venue: venue,
                    isFavorite: true,
                    displayTags: const [],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}
