import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue_place_photo.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';

Widget _buildCard({String? distance, String? googlePlaceId}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: VenueCard(
        id: 'venue-1',
        name: 'Venue',
        category: 'Cafe',
        rating: 4.5,
        distance: distance,
        googlePlaceId: googlePlaceId,
      ),
    ),
  );
}

void main() {
  group('VenueCard', () {
    testWidgets('does not render distance badge when distance is absent', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard());

      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('renders distance badge when distance is provided', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(distance: '1.2 km'));

      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
    });

    testWidgets('loads an attributed Google Places photo when configured', (
      tester,
    ) async {
      const photo = VenuePlacePhoto(
        photoUri: 'https://example.test/photo.jpg',
        googleMapsUri: 'https://maps.google.com/photo',
        authorName: 'Photo Owner',
        authorUri: 'https://maps.google.com/author',
        authorPhotoUri: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venuePrimaryPlacePhotoProvider(
              'venue-1',
            ).overrideWith((ref) async => photo),
          ],
          child: _buildCard(googlePlaceId: 'google-place-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Google Maps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
