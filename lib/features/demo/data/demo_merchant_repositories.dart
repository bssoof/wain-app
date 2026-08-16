import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/features/demo/application/demo_merchant_store.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_dashboard_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_offers_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_reviews_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_refresh.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_upsert_input.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';

export 'demo_merchant_content_repositories.dart';
export 'demo_merchant_wallet_repositories.dart';

/// Demo stand-ins for every merchant repository.
///
/// These sit *in front of* the production repositories, exactly as the
/// customer-side adapters do: no production repository, query, callable or
/// security rule is changed to accommodate the walkthrough. Installed only
/// while `demoMerchantSessionProvider` is on, which itself is debug-only.
///
/// ## Writes
///
/// Every write mutates an in-memory store. The presenter sees the effect during
/// the current walkthrough, while reset/dispose restores the original catalog.
/// No demo write is allowed to reach Firebase, Storage or a callable.
///
/// A demo repository that reached Firebase would be a silent leak, so none of
/// these classes holds a database, storage or callable handle at all — there is
/// nothing for them to call. The one Firebase import below is the `Source`
/// enum, needed only to match the signatures being overridden; it names a cache
/// preference and performs nothing. `demo_merchant_isolation_test` constructs
/// and drains every adapter here with Firebase uninitialised, which is what
/// actually proves the claim.

/// The dashboard repository is a concrete class rather than an interface, so
/// the demo subclasses it and overrides every method. Anything added to the
/// base class later fails the isolation audit rather than quietly reaching
/// Firestore.
class DemoMerchantDashboardRepository extends MerchantDashboardRepository {
  DemoMerchantDashboardRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<String?> getLinkedVenueId(String userId, {Source? source}) async =>
      DemoMode.venueId;

  @override
  Future<bool> venueExists(String venueId, {Source? source}) async => true;

  @override
  Future<MerchantVenue?> getVenue(String venueId, {Source? source}) async =>
      _store.venue;

  @override
  Future<MerchantStats> getStats(String venueId, {Source? source}) async =>
      _store.stats;

  @override
  Future<List<MerchantReview>> getReviews(
    String venueId, {
    int limit = 100,
    Source? source,
  }) async => _store.reviews.take(limit).toList();

  @override
  Future<List<MerchantOffer>> getOffers(
    String venueId, {
    Source? source,
  }) async => _store.offers;

  @override
  Future<MerchantAnalytics> getAnalytics(
    String venueId, {
    Source? source,
  }) async => buildDemoMerchantAnalytics();

  @override
  Future<List<MerchantDailyPoint>> getAnalyticsDaily({
    required String venueId,
    required int rangeDays,
    Source? source,
  }) async => buildDemoMerchantDailySeries(rangeDays);

  @override
  Future<List<MerchantOfferAnalyticsSummary>> getOfferAnalytics({
    required String venueId,
    int limit = 50,
    Source? source,
  }) async => buildDemoMerchantOfferAnalytics().take(limit).toList();

  /// Delegates to the inherited implementation, which composes the payload out
  /// of the three overrides above through the real
  /// `buildMerchantAnalyticsDrilldownPayload`. The demo shows the production
  /// funnel maths over demo numbers rather than a second copy of the maths.
  @override
  Future<MerchantAnalyticsDrilldownPayload> getAnalyticsDrilldown({
    required String venueId,
    required int periodDays,
    Source? source,
  }) => super.getAnalyticsDrilldown(
    venueId: venueId,
    periodDays: periodDays,
    source: source,
  );

  /// The real refresh calls `backfillMerchantAnalytics`. Here it reports a
  /// settled result without asking anything to recompute.
  @override
  Future<DashboardRefreshResult> refreshDashboard({
    required bool debugMode,
    int analyticsDays = 30,
  }) async {
    final analytics = buildDemoMerchantAnalytics();
    return DashboardRefreshResult(
      views: analytics.viewsTotal,
      calls: analytics.callsTotal,
      navs: analytics.navsTotal,
      busyTimesStatus: BusyTimesRefreshStatus.readyDemo,
    );
  }
}

class DemoMerchantOffersRepository implements MerchantOffersRepository {
  DemoMerchantOffersRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<void> setOfferStatus({
    required String offerId,
    required MerchantOfferStatus status,
  }) async => _store.setOfferStatus(offerId, status);

  @override
  Future<void> deleteOffer(String offerId) async => _store.deleteOffer(offerId);

  @override
  Future<void> saveOffer(MerchantOfferUpsertInput input) async =>
      _store.saveOffer(input);

  @override
  Future<Map<int, double>> fetchOfferPinPricing() async =>
      demoMerchantOfferPinPricing;

  @override
  Future<void> pinOffer({
    required String offerId,
    required int durationDays,
    required String requestId,
  }) async => _store.pinOffer(offerId, durationDays);
}

class DemoMerchantReviewsRepository implements MerchantReviewsRepository {
  DemoMerchantReviewsRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<void> submitReply({
    required String venueId,
    required String reviewId,
    required String replyText,
    required String authorIdentifier,
  }) async => _store.submitReply(reviewId, replyText, authorIdentifier);

  @override
  Future<void> deleteReply({
    required String venueId,
    required String reviewId,
  }) async => _store.deleteReply(reviewId);
}
