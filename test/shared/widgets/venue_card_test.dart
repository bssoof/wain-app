import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';

Widget _buildCard({String? distance}) {
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
  });
}
