import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';
import 'package:wain_app/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Story _story({
  String id = 'story-1',
  String venueId = 'venue-1',
  String venueName = 'Venue One',
}) {
  return Story(
    id: id,
    venueId: venueId,
    venueName: venueName,
    type: 'text',
    text: 'story body',
    createdAt: DateTime(2026, 5, 14, 12),
    expiresAt: DateTime(2026, 5, 15, 12),
    durationSeconds: 30,
  );
}

class _NoopAnalyticsService extends AnalyticsService {
  _NoopAnalyticsService() : super(_FakeFirebaseAnalytics(), _FakeFunctions());

  @override
  Future<void> trackVenueEvent({
    required String venueId,
    required String eventType,
    required String source,
    String? deviceId,
    String? offerId,
    String? navApp,
    String? storyId,
  }) async {}
}

class _FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {}

class _FakeFunctions extends Fake implements FirebaseFunctions {}

Widget _storyViewerApp({
  required Story story,
  required ValueChanged<Object?> onVenueExtra,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push('/story'),
              child: const Text('open story'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/story',
        builder: (context, state) => StoryViewerScreen.single(stories: [story]),
      ),
      GoRoute(
        path: '/venue/:id',
        builder: (context, state) {
          onVenueExtra(state.extra);
          return const Scaffold(body: Center(child: Text('venue destination')));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
    ],
    child: MaterialApp.router(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  group('StoryViewerScreen source attribution', () {
    test('builds story attribution for the first venue click', () {
      final attributed = <String>{};
      final extra = buildStoryVenueRouteExtra(
        story: _story(),
        attributedStoryIds: attributed,
      );

      expect(extra['source'], 'story_viewer');
      expect(extra['storyId'], 'story-1');
      expect(attributed, contains('story-1'));
    });

    test('builds regular venue attribution for repeated same-story click', () {
      final attributed = <String>{'story-1'};
      final extra = buildStoryVenueRouteExtra(
        story: _story(),
        attributedStoryIds: attributed,
      );

      expect(extra['source'], 'venue_details');
      expect(extra.containsKey('storyId'), isFalse);
      expect(attributed, contains('story-1'));
    });

    test('attributes a different story after another story was attributed', () {
      final attributed = <String>{'story-1'};
      final extra = buildStoryVenueRouteExtra(
        story: _story(id: 'story-2'),
        attributedStoryIds: attributed,
      );

      expect(extra['source'], 'story_viewer');
      expect(extra['storyId'], 'story-2');
      expect(attributed, containsAll(<String>['story-1', 'story-2']));
    });

    testWidgets('passes story source and storyId to the venue route', (
      tester,
    ) async {
      Object? venueExtra;
      await tester.pumpWidget(
        _storyViewerApp(
          story: _story(),
          onVenueExtra: (extra) => venueExtra = extra,
        ),
      );

      await tester.tap(find.text('open story'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Venue One'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('venue destination'), findsOneWidget);
      expect(venueExtra, isA<Map<String, Object>>());
      final extra = venueExtra as Map<String, Object>;
      expect(extra['source'], 'story_viewer');
      expect(extra['storyId'], 'story-1');
    });
  });
}
