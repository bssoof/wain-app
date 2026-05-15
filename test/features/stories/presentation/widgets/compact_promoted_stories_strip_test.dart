import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';
import 'package:wain_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:wain_app/features/stories/presentation/widgets/stories_bar.dart';
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
  group('CompactPromotedStoriesStrip', () {
    testWidgets('groups promoted stories by venue and renders compact labels', (
      tester,
    ) async {
      final now = DateTime.now();
      final stories = [
        Story(
          id: 'story-1',
          venueId: 'venue-1',
          venueName: 'ستونز',
          type: 'text',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
          promotedUntil: now.add(const Duration(hours: 1)),
        ),
        Story(
          id: 'story-2',
          venueId: 'venue-1',
          venueName: 'ستونز',
          type: 'text',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
          promotedUntil: now.add(const Duration(hours: 1)),
        ),
        Story(
          id: 'story-3',
          venueId: 'venue-2',
          venueName: 'روز',
          type: 'text',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
          promotedUntil: now.add(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            promotedStoriesProvider.overrideWith(
              (ref) => Stream.value(stories),
            ),
          ],
          child: _app(const CompactPromotedStoriesStrip()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ستونز'), findsOneWidget);
      expect(find.text('روز'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsNWidgets(2));
    });

    testWidgets('renders nothing when there are no promoted stories', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            promotedStoriesProvider.overrideWith(
              (ref) => Stream.value(const <Story>[]),
            ),
          ],
          child: _app(const CompactPromotedStoriesStrip()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
    });
  });
}
