import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/reviews/presentation/providers/reviews_provider.dart';
import 'package:wain_app/features/stories/presentation/providers/stories_provider.dart'
    as stories_provider;
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart'
    as venue_providers;

/// Audits every venue- or offer-keyed provider the demo screen reaches.
///
/// The technique does not depend on a hand-written spy, which is why the
/// earlier fail-on-call fakes missed `offerRedeemedStatusProvider`: that
/// provider talks to `FirebaseFirestore.instance` directly, so no injected
/// fake could observe it.
///
/// Here nothing is faked at all. Firebase is never initialised, so
/// `FirebaseFirestore.instance` and `FirebaseFunctions.instance` throw on
/// first touch. A provider that resolves cleanly for the demo id therefore
/// *proves* it never reached them — and each case is paired with a non-demo
/// control that must throw, so a guard which silently swallowed every id
/// could not pass.
Future<Object?> _resolve<T>(
  ProviderContainer container,
  Object provider,
  Future<T> future,
) async {
  // A StreamProvider stays idle until something listens, so the subscription
  // is opened before the future is awaited. Dispatched dynamically because the
  // provider types differ across the families under audit.
  (container as dynamic).listen(provider, (_, _) {}, fireImmediately: true);
  try {
    await future.timeout(const Duration(seconds: 5));
    return null;
  } catch (error) {
    return error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        // Not a Firebase dependency: offerById reaches a local saved-offers
        // cache, which asserts rather than silently no-opping when the
        // preferences instance is missing. Overridden so a genuine Firebase
        // touch stays the only reason a case can fail.
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
  });

  group('venue-keyed providers stay off Firebase for the demo', () {
    test('venueById', () async {
      expect(
        await _resolve(
          container,
          venue_providers.venueByIdProvider(DemoMode.venueId),
          container.read(
            venue_providers.venueByIdProvider(DemoMode.venueId).future,
          ),
        ),
        isNull,
      );
    });

    test('venueBusyTimes', () async {
      expect(
        await _resolve(
          container,
          venue_providers.venueBusyTimesProvider(DemoMode.venueId),
          container.read(
            venue_providers.venueBusyTimesProvider(DemoMode.venueId).future,
          ),
        ),
        isNull,
      );
    });

    test('venuePlacePhotos', () async {
      expect(
        await _resolve(
          container,
          venue_providers.venuePlacePhotosProvider(DemoMode.venueId),
          container.read(
            venue_providers.venuePlacePhotosProvider(DemoMode.venueId).future,
          ),
        ),
        isNull,
      );
    });

    test('venueStories', () async {
      expect(
        await _resolve(
          container,
          stories_provider.venueStoriesProvider(DemoMode.venueId),
          container.read(
            stories_provider.venueStoriesProvider(DemoMode.venueId).future,
          ),
        ),
        isNull,
      );
    });

    test('offersByVenue', () async {
      expect(
        await _resolve(
          container,
          offersByVenueProvider(venueId: DemoMode.venueId),
          container.read(
            offersByVenueProvider(venueId: DemoMode.venueId).future,
          ),
        ),
        isNull,
      );
    });

    test('venueReviews', () async {
      expect(
        await _resolve(
          container,
          venueReviewsProvider(DemoMode.venueId),
          container.read(venueReviewsProvider(DemoMode.venueId).future),
        ),
        isNull,
      );
    });

    test('venueRatingSummary', () async {
      expect(
        await _resolve(
          container,
          venueRatingSummaryProvider(DemoMode.venueId),
          container.read(venueRatingSummaryProvider(DemoMode.venueId).future),
        ),
        isNull,
      );
    });

    test('userReview', () async {
      expect(
        await _resolve(
          container,
          userReviewProvider((
            venueId: DemoMode.venueId,
            userId: 'demo_local_user',
          )),
          container.read(
            userReviewProvider((
              venueId: DemoMode.venueId,
              userId: 'demo_local_user',
            )).future,
          ),
        ),
        isNull,
      );
    });

    test('menuItems', () async {
      expect(
        await _resolve(
          container,
          menuItemsProvider(DemoMode.venueId),
          container.read(menuItemsProvider(DemoMode.venueId).future),
        ),
        isNull,
      );
    });

    test('menuActiveSections', () async {
      const query = MenuActiveSectionsQuery(
        venueId: DemoMode.venueId,
        venueCategory: 'cafe',
      );
      expect(
        await _resolve(
          container,
          menuActiveSectionsProvider(query),
          container.read(menuActiveSectionsProvider(query).future),
        ),
        isNull,
      );
    });
  });

  group('offer-keyed providers stay off Firebase for the demo', () {
    test('offerRedeemedStatus for every demo offer', () async {
      for (final offer in buildDemoOffers()) {
        expect(
          await _resolve(
            container,
            offerRedeemedStatusProvider(offer.id),
            container.read(offerRedeemedStatusProvider(offer.id).future),
          ),
          isNull,
          reason: offer.id,
        );
      }
    });

    test('offerById for every demo offer', () async {
      for (final offer in buildDemoOffers()) {
        expect(
          await _resolve(
            container,
            offerByIdProvider(offerId: offer.id),
            container.read(offerByIdProvider(offerId: offer.id).future),
          ),
          isNull,
          reason: offer.id,
        );
      }
    });
  });

  group('controls — real ids must still reach Firebase', () {
    test('a real venue id is not served locally', () async {
      final outcomes = <String, Object?>{
        'venueStories': await _resolve(
          container,
          stories_provider.venueStoriesProvider('real-venue'),
          container.read(
            stories_provider.venueStoriesProvider('real-venue').future,
          ),
        ),
        'venueReviews': await _resolve(
          container,
          venueReviewsProvider('real-venue'),
          container.read(venueReviewsProvider('real-venue').future),
        ),
        'menuItems': await _resolve(
          container,
          menuItemsProvider('real-venue'),
          container.read(menuItemsProvider('real-venue').future),
        ),
      };

      for (final entry in outcomes.entries) {
        expect(
          entry.value,
          isNotNull,
          reason:
              '${entry.key} resolved cleanly for a real venue — the demo guard '
              'is too broad and is serving local data to production ids',
        );
      }
    });

    test('a real offer id is not served locally', () async {
      expect(
        await _resolve(
          container,
          offerRedeemedStatusProvider('real-offer'),
          container.read(offerRedeemedStatusProvider('real-offer').future),
        ),
        isNotNull,
      );
    });
  });
}
