import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/offline/offline_snapshot.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/screens/venue_details_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class _RecordingVenueAnalyticsService extends AnalyticsService {
  final List<Map<String, Object?>> venueViews = <Map<String, Object?>>[];
  final List<Map<String, Object?>> venueEvents = <Map<String, Object?>>[];

  _RecordingVenueAnalyticsService()
    : super(_FakeFirebaseAnalytics(), _FakeFirebaseFunctions());

  @override
  Future<void> logVenueViewFull({
    required String venueId,
    required String venueName,
    required String city,
    required String source,
  }) async {
    venueViews.add({
      'venueId': venueId,
      'venueName': venueName,
      'city': city,
      'source': source,
    });
  }

  @override
  Future<void> trackVenueEvent({
    required String venueId,
    required String eventType,
    required String source,
    String? deviceId,
    String? offerId,
    String? navApp,
    String? storyId,
  }) async {
    venueEvents.add({
      'venueId': venueId,
      'eventType': eventType,
      'source': source,
      'storyId': storyId,
    });
  }
}

class _FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {}

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<void> addFavorite(String venueId) async {}

  @override
  Future<void> clearLocal() async {}

  @override
  Future<List<String>> getFavorites() async => const <String>[];

  @override
  Future<bool> isFavorite(String venueId) async => false;

  @override
  Future<void> mergeOnLogin(String userId) async {}

  @override
  Future<void> removeFavorite(String venueId) async {}

  @override
  Future<void> syncFromCloud(String userId) async {}

  @override
  Future<void> syncToCloud(String userId) async {}

  @override
  Future<bool> toggleFavorite(String venueId) async => true;
}

Venue _venue() {
  return const Venue(
    id: 'venue-1',
    nameAr: 'مكان تجريبي',
    nameEn: 'Test Venue',
    lat: 31.9,
    lng: 35.2,
    city: 'رام الله',
    categories: <String>['restaurant'],
    tags: VenueTags(),
    minPrice: 10,
    maxPrice: 50,
    rating: 4.5,
    phone: '0591234567',
  );
}

Widget _venueDetailsApp({
  required Venue venue,
  required _RecordingVenueAnalyticsService analytics,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('launcher'))),
      ),
      GoRoute(
        path: '/venue/:id',
        builder: (context, state) =>
            VenueDetailsScreen(venueId: state.pathParameters['id']!),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith((ref) => true),
      analyticsServiceProvider.overrideWithValue(analytics),
      venueByIdSnapshotProvider(venue.id).overrideWith(
        (ref) async => OfflineSnapshot<Venue?>(
          data: venue,
          source: OfflineDataSource.server,
          fetchedAt: DateTime(2026, 5, 14),
        ),
      ),
      venueByIdProvider(venue.id).overrideWith((ref) async => venue),
      favoritesRepositoryProvider.overrideWith(
        (ref) => _FakeFavoritesRepository(),
      ),
      offersByVenueProvider(
        venueId: venue.id,
      ).overrideWith((ref) async => const <Offer>[]),
      menuItemsProvider(
        venue.id,
      ).overrideWith((ref) => Stream.value(const <MenuItem>[])),
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
  group('resolveVenueViewRouteAttribution', () {
    test('resolves story viewer source and story id from route extra', () {
      final attribution = resolveVenueViewRouteAttribution({
        'source': 'story_viewer',
        'storyId': 'story-1',
      });

      expect(attribution.source, 'story_viewer');
      expect(attribution.storyId, 'story-1');
    });

    test('defaults to venue details for missing route extra', () {
      final attribution = resolveVenueViewRouteAttribution(null);

      expect(attribution.source, 'venue_details');
      expect(attribution.storyId, isNull);
    });
  });

  group('VenueDetailsScreen route attribution', () {
    testWidgets('logs story viewer attribution from route extra', (
      tester,
    ) async {
      final venue = _venue();
      final analytics = _RecordingVenueAnalyticsService();
      final app = _venueDetailsApp(venue: venue, analytics: analytics);

      await tester.pumpWidget(app);
      final router = GoRouter.of(tester.element(find.text('launcher')));
      router.push(
        '/venue/${venue.id}',
        extra: {'source': 'story_viewer', 'storyId': 'story-1'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(analytics.venueViews.single['source'], 'story_viewer');
      expect(analytics.venueEvents.single['source'], 'story_viewer');
      expect(analytics.venueEvents.single['storyId'], 'story-1');
    });

    testWidgets('logs default venue details attribution without route extra', (
      tester,
    ) async {
      final venue = _venue();
      final analytics = _RecordingVenueAnalyticsService();
      final app = _venueDetailsApp(venue: venue, analytics: analytics);

      await tester.pumpWidget(app);
      final router = GoRouter.of(tester.element(find.text('launcher')));
      router.push('/venue/${venue.id}');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(analytics.venueViews.single['source'], 'venue_details');
      expect(analytics.venueEvents.single['source'], 'venue_details');
      expect(analytics.venueEvents.single['storyId'], isNull);
    });
  });
}
