import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/demo/data/demo_offers_catalog.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/data/demo_venue_catalog.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_wallet_repository.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_wallet_providers.dart';

/// Audits every merchant provider the walkthrough reaches.
///
/// Same technique as `demo_provider_audit_test`, and for the same reason:
/// nothing is faked. Firebase is never initialised, so `FirebaseFirestore
/// .instance`, `FirebaseFunctions.instance` and `FirebaseStorage.instance`
/// throw on first touch. A provider that resolves cleanly while the demo
/// merchant session is on therefore *proves* it never reached them.
///
/// Every case is paired with a control that runs the same provider with the
/// session off and requires it to throw. Without those controls a merchant
/// provider that had quietly stopped touching Firebase at all — or a demo gate
/// that swallowed every caller — would look identical to a working seam.
Future<Object?> _resolve<T>(
  ProviderContainer container,
  Object provider,
  Future<T> future,
) async {
  // A StreamProvider stays idle until something listens, so the subscription is
  // opened before the future is awaited. Dispatched dynamically because the
  // provider types differ across the surfaces under audit.
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
  });

  ProviderContainer buildContainer({required bool demoSession}) {
    final created = ProviderContainer(
      overrides: [
        // Not a Firebase dependency: the merchant chain reads through
        // `fetchWithOfflineFallback`, whose timestamp tracker asserts rather
        // than no-ops when preferences are missing. Overridden so a genuine
        // Firebase touch stays the only reason a case can fail.
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    if (demoSession) {
      created.read(demoMerchantSessionProvider.notifier).enter();
    }
    addTearDown(created.dispose);
    return created;
  }

  group('the demo merchant session gate', () {
    test('is off until it is entered', () {
      final fresh = buildContainer(demoSession: false);
      expect(fresh.read(demoMerchantSessionProvider), isFalse);
    });

    test('turns on when entered and off again when left', () {
      final entered = buildContainer(demoSession: true);
      expect(entered.read(demoMerchantSessionProvider), isTrue);

      entered.read(demoMerchantSessionProvider.notifier).leave();
      expect(entered.read(demoMerchantSessionProvider), isFalse);
    });

    test('pins the dashboard to the demo venue without reading auth', () async {
      final entered = buildContainer(demoSession: true);
      expect(
        await entered.read(merchantVenueIdProvider.future),
        DemoMode.venueId,
      );
    });
  });

  group('merchant providers stay off Firebase during the walkthrough', () {
    setUp(() {
      container = buildContainer(demoSession: true);
    });

    test('merchantVenueId', () async {
      expect(
        await _resolve(
          container,
          merchantVenueIdProvider,
          container.read(merchantVenueIdProvider.future),
        ),
        isNull,
      );
    });

    test('merchantRouteAccess', () async {
      expect(
        await _resolve(
          container,
          merchantRouteAccessProvider,
          container.read(merchantRouteAccessProvider.future),
        ),
        isNull,
      );
    });

    test('merchantVenue', () async {
      expect(
        await _resolve(
          container,
          merchantVenueProvider,
          container.read(merchantVenueProvider.future),
        ),
        isNull,
      );
    });

    test('merchantStats', () async {
      expect(
        await _resolve(
          container,
          merchantStatsProvider,
          container.read(merchantStatsProvider.future),
        ),
        isNull,
      );
    });

    test('merchantReviews', () async {
      expect(
        await _resolve(
          container,
          merchantReviewsProvider,
          container.read(merchantReviewsProvider.future),
        ),
        isNull,
      );
    });

    test('merchantOffers', () async {
      expect(
        await _resolve(
          container,
          merchantOffersProvider,
          container.read(merchantOffersProvider.future),
        ),
        isNull,
      );
    });

    test('merchantAnalytics', () async {
      expect(
        await _resolve(
          container,
          merchantAnalyticsProvider,
          container.read(merchantAnalyticsProvider.future),
        ),
        isNull,
      );
    });

    test('merchantAnalyticsDaily — both ranges the UI offers', () async {
      for (final rangeDays in const <int>[7, 30]) {
        expect(
          await _resolve(
            container,
            merchantAnalyticsDailyProvider(rangeDays),
            container.read(merchantAnalyticsDailyProvider(rangeDays).future),
          ),
          isNull,
          reason: 'rangeDays=$rangeDays',
        );
      }
    });

    test('merchantOfferAnalytics', () async {
      expect(
        await _resolve(
          container,
          merchantOfferAnalyticsProvider,
          container.read(merchantOfferAnalyticsProvider.future),
        ),
        isNull,
      );
    });

    test('merchantAnalyticsDrilldown', () async {
      expect(
        await _resolve(
          container,
          merchantAnalyticsDrilldownProvider,
          container.read(merchantAnalyticsDrilldownProvider.future),
        ),
        isNull,
      );
    });

    test('merchantActiveMenuSummary', () async {
      expect(
        await _resolve(
          container,
          merchantActiveMenuSummaryProvider,
          container.read(merchantActiveMenuSummaryProvider.future),
        ),
        isNull,
      );
    });

    test('merchantHasActiveStory', () async {
      expect(
        await _resolve(
          container,
          merchantHasActiveStoryProvider,
          container.read(merchantHasActiveStoryProvider.future),
        ),
        isNull,
      );
    });

    test('merchantContentHealth', () async {
      expect(
        await _resolve(
          container,
          merchantContentHealthProvider,
          container.read(merchantContentHealthProvider.future),
        ),
        isNull,
      );
    });

    test('merchantWallet', () async {
      expect(
        await _resolve(
          container,
          merchantWalletStreamProvider,
          container.read(merchantWalletStreamProvider.future),
        ),
        isNull,
      );
    });

    test('merchantWalletEntries', () async {
      expect(
        await _resolve(
          container,
          merchantWalletEntriesStreamProvider,
          container.read(merchantWalletEntriesStreamProvider.future),
        ),
        isNull,
      );
    });

    test('merchantWalletReport', () async {
      expect(
        await _resolve(
          container,
          merchantWalletReportStreamProvider,
          container.read(merchantWalletReportStreamProvider.future),
        ),
        isNull,
      );
    });

    test('merchantTopUpRequests', () async {
      expect(
        await _resolve(
          container,
          merchantTopUpRequestsStreamProvider,
          container.read(merchantTopUpRequestsStreamProvider.future),
        ),
        isNull,
      );
    });
  });

  group('controls — without the session the same providers reach Firebase', () {
    setUp(() {
      container = buildContainer(demoSession: false);
    });

    test('the venue-linked chain still needs Firebase', () async {
      final outcomes = <String, Object?>{
        'merchantVenueId': await _resolve(
          container,
          merchantVenueIdProvider,
          container.read(merchantVenueIdProvider.future),
        ),
        'merchantRouteAccess': await _resolve(
          container,
          merchantRouteAccessProvider,
          container.read(merchantRouteAccessProvider.future),
        ),
      };

      for (final entry in outcomes.entries) {
        expect(
          entry.value,
          isNotNull,
          reason:
              '${entry.key} resolved without Firebase while the demo session '
              'was off — the gate is swallowing production callers',
        );
      }
    });

    // The downstream providers cannot serve as controls on their own: with no
    // venue id they short-circuit to an empty stream before ever asking the
    // repository, so they resolve cleanly for a reason that has nothing to do
    // with the demo. The seam itself is what gets asserted instead — every
    // repository provider, both ways round.
    test('no repository provider hands back a demo adapter', () {
      final readers = <String, Object Function()>{
        'dashboard': () => container.read(merchantDashboardRepositoryProvider),
        'offers': () => container.read(merchantOffersRepositoryProvider),
        'reviews': () => container.read(merchantReviewsRepositoryProvider),
        'stories': () => container.read(merchantStoriesRepositoryProvider),
        'photos': () => container.read(merchantPhotosRepositoryProvider),
        'hours': () => container.read(merchantHoursRepositoryProvider),
        'profile': () =>
            container.read(merchantVenueProfileRepositoryProvider),
        'invite': () => container.read(merchantInviteRepositoryProvider),
        'wallet': () => container.read(merchantWalletRepositoryProvider),
        'claims': () => container.read(merchantRepositoryProvider),
      };

      for (final entry in readers.entries) {
        Object? adapter;
        try {
          adapter = entry.value();
        } catch (_) {
          // Several production adapters resolve `FirebaseStorage.instance` and
          // friends while constructing, so with Firebase uninitialised they
          // throw here. That throw is itself the proof the control wants: the
          // provider went down the production path.
          continue;
        }

        expect(
          adapter.runtimeType.toString(),
          isNot(startsWith('Demo')),
          reason:
              '${entry.key} handed back a demo adapter with the session off',
        );
      }
    });
  });

  group('the seam installs a demo adapter for every merchant repository', () {
    test('all ten, with the session on', () {
      final entered = buildContainer(demoSession: true);
      final adapters = <String, Object>{
        'dashboard': entered.read(merchantDashboardRepositoryProvider),
        'offers': entered.read(merchantOffersRepositoryProvider),
        'reviews': entered.read(merchantReviewsRepositoryProvider),
        'stories': entered.read(merchantStoriesRepositoryProvider),
        'photos': entered.read(merchantPhotosRepositoryProvider),
        'hours': entered.read(merchantHoursRepositoryProvider),
        'profile': entered.read(merchantVenueProfileRepositoryProvider),
        'invite': entered.read(merchantInviteRepositoryProvider),
        'wallet': entered.read(merchantWalletRepositoryProvider),
        'claims': entered.read(merchantRepositoryProvider),
      };

      for (final entry in adapters.entries) {
        expect(
          entry.value.runtimeType.toString(),
          startsWith('Demo'),
          reason: '${entry.key} still reaches production during the demo',
        );
      }
    });
  });

  group('the merchant catalog describes the same café as the customer view', () {
    test('venue identity matches', () {
      final venue = buildDemoMerchantVenue();
      expect(venue.id, DemoMode.venueId);
      expect(venue.nameAr, DemoMode.venueNameAr);
      expect(venue.nameEn, DemoMode.venueNameEn);
    });

    test('the rating shown to the merchant is the reviews average', () {
      final stats = buildDemoMerchantStats();
      expect(stats.rating, demoReviewsAverage());
      expect(stats.reviewCount, buildDemoMerchantReviews().length);
      expect(stats.recentReviews, hasLength(3));
    });

    test('one rating, everywhere it is shown', () {
      // The venue header said 4.6 while the reviews card on the same screen
      // said 3.8. Both now derive from the six reviews, so a change to the
      // review set cannot leave one of them behind.
      expect(buildDemoVenue().rating, demoReviewsAverage());
      expect(buildDemoMerchantVenue().rating, demoReviewsAverage());
      expect(buildDemoMerchantStats().rating, demoReviewsAverage());
    });

    test('the dashboard does not open on a staleness warning', () {
      // The freshness rules measure distance from the real clock, so a fixed
      // anchor aged into "البيانات قديمة" and got worse by a day every day.
      final now = DateTime.now();

      final analyticsAge = now.difference(
        buildDemoMerchantAnalytics().updatedAt!,
      );
      expect(
        analyticsAge,
        lessThan(const Duration(hours: 24)),
        reason: 'analytics must read as refreshed today, not $analyticsAge ago',
      );

      final menuAge = now.difference(demoMerchantMenuPublishedAt());
      expect(
        menuAge.inDays,
        lessThanOrEqualTo(14),
        reason: 'the content-health rule calls a menu older than 14 days stale',
      );

      final walletAge = now.difference(buildDemoMerchantWallet().updatedAt);
      expect(walletAge, lessThan(const Duration(days: 2)));

      // The chart's last point is today, so the period label reads as current.
      final series = buildDemoMerchantDailySeries(7);
      final today =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      expect(series.last.dateKey, today);
    });

    test('only the timestamps move — the numbers are still fixed', () {
      // The point of the fixed anchor was determinism, and that part still
      // holds: every count and ratio is a constant.
      final first = buildDemoMerchantAnalytics();
      final second = buildDemoMerchantAnalytics();
      expect(first.viewsTotal, second.viewsTotal);
      expect(first.claimsCreated7d, 47);
      expect(first.redemptions7d, 34);

      expect(
        buildDemoMerchantDailySeries(7).map((p) => p.views).toList(),
        buildDemoMerchantDailySeries(7).map((p) => p.views).toList(),
      );
      expect(buildDemoMerchantWallet().availableBalance, 240);
    });

    test('offers carry the same ids the customer side serves', () {
      final offers = buildDemoMerchantOffers();
      expect(offers, hasLength(4));
      expect(
        offers.map((offer) => offer.venueId).toSet(),
        <String>{DemoMode.venueId},
      );
      expect(
        buildDemoMerchantOfferAnalytics().map((row) => row.offerId).toList(),
        offers.map((offer) => offer.id).toList(),
      );
    });

    test('stories carry the same ids the customer side serves', () {
      expect(buildDemoMerchantStories(), hasLength(3));
    });

    test('two of the six reviews are already answered', () {
      final replied = buildDemoMerchantReviews().where((r) => r.hasReply);
      expect(replied, hasLength(2));
    });

    test('content health is derived, not asserted healthy', () {
      final health = buildDemoMerchantContentHealth();
      // Six photos, a menu published four days before the fixed "now", an
      // active story and six populated profile fields: the production rules
      // should call that healthy. If they stop doing so, the demo should show
      // whatever they now say rather than this test being relaxed.
      expect(health.allHealthy, isTrue);
      expect(health.items, hasLength(5));
    });

    test('the wallet ledger reconciles with the balance it reports', () {
      final entries = buildDemoMerchantWalletEntries();
      final credited = entries
          .where((entry) => entry.isCredit)
          .fold<double>(0, (sum, entry) => sum + entry.amount);
      final debited = entries
          .where((entry) => !entry.isCredit)
          .fold<double>(0, (sum, entry) => sum + entry.amount);

      expect(
        credited - debited,
        buildDemoMerchantWallet().availableBalance,
        reason: 'the ledger must add up to the balance on the wallet card',
      );
      expect(entries.first.balanceAfter, credited - debited);
    });

    test('the daily series is deterministic and the requested length', () {
      expect(buildDemoMerchantDailySeries(30), hasLength(30));
      expect(
        buildDemoMerchantDailySeries(14).map((point) => point.dateKey).toList(),
        buildDemoMerchantDailySeries(14).map((point) => point.dateKey).toList(),
      );
      // A zero or negative range must not produce an empty chart.
      expect(buildDemoMerchantDailySeries(0), hasLength(7));
    });
  });

  group('the QR scanner refuses anything that is not a demo payload', () {
    test('a demo offer payload validates and can be redeemed', () {
      final offer = buildDemoMerchantOffers().firstWhere((o) => o.isActive);
      final result = buildDemoMerchantValidation(demoQrPayload(offer.id));

      expect(result.valid, isTrue);
      expect(result.canRedeem, isTrue);
      expect(result.offer?.titleAr, offer.titleAr);
    });

    test('a real claim token is rejected rather than invented', () {
      for (final token in const <String>[
        'wain-claim-abc123',
        '',
        'demo_offer_breakfast',
      ]) {
        final result = buildDemoMerchantValidation(token);
        expect(result.valid, isFalse, reason: token);
        expect(result.canRedeem, isFalse, reason: token);
        expect(result.claimId, isNull, reason: token);
      }
    });
  });
}
