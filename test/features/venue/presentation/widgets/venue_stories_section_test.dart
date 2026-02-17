import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_stories_section.dart';

void main() {
  group('VenueStoriesSection', () {
    testWidgets('renders active story item from provider stream', (tester) async {
      final now = DateTime.now();
      const venueId = 'venue-1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueStoriesProvider(venueId).overrideWith(
              (ref) => Stream.value([
                {
                  'id': 'story-1',
                  'venue_id': venueId,
                  'venue_name': 'Cafe',
                  'type': 'text',
                  'text': 'Story A',
                  'view_count': 0,
                  'duration_seconds': 5,
                  'created_at': Timestamp.fromDate(
                    now.subtract(const Duration(minutes: 1)),
                  ),
                  'expires_at': Timestamp.fromDate(
                    now.add(const Duration(hours: 1)),
                  ),
                },
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VenueStoriesSection(venueId: venueId),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VenueStoriesSection), findsOneWidget);
      expect(find.text('Story A'), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders nothing when stream is empty', (tester) async {
      const venueId = 'venue-1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueStoriesProvider(venueId).overrideWith(
              (ref) => Stream.value(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VenueStoriesSection(venueId: venueId),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Story A'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });
  });
}
