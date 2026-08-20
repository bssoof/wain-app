import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';
import 'package:wain_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_stories_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('VenueStoriesSection', () {
    testWidgets('renders active story item from provider stream', (
      tester,
    ) async {
      final now = DateTime.now();
      const venueId = 'venue-1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            venueStoriesProvider(venueId).overrideWith(
              (ref) => Stream.value([
                Story(
                  id: 'story-1',
                  venueId: venueId,
                  venueName: 'Cafe',
                  type: 'text',
                  text: 'Story A',
                  createdAt: now.subtract(const Duration(minutes: 1)),
                  expiresAt: now.add(const Duration(hours: 1)),
                ),
              ]),
            ),
          ],
          child: _app(const VenueStoriesSection(venueId: venueId)),
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
            venueStoriesProvider(
              venueId,
            ).overrideWith((ref) => Stream.value(<Story>[])),
          ],
          child: _app(const VenueStoriesSection(venueId: venueId)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Story A'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });
  });
}
