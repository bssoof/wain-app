import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/try_list/presentation/providers/try_list_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_hero_header.dart';

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
        photos: const ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isInTryListProvider(venue.id).overrideWith((ref) async => false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  VenueHeroHeader(venue: venue, isFavorite: false),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('shows fallback icon when venue has no photos', (tester) async {
      final venue = _makeVenue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isInTryListProvider(venue.id).overrideWith((ref) async => false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  VenueHeroHeader(venue: venue, isFavorite: true),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
