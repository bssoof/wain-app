import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_dashboard_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_hours_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_invite_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_offers_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_photos_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_reviews_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_venue_profile_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_wallet_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_refresh.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_invite_result.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_upsert_input.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_validation_result.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_report.dart';

/// Demo stand-ins for every merchant repository.
///
/// These sit *in front of* the production repositories, exactly as the
/// customer-side adapters do: no production repository, query, callable or
/// security rule is changed to accommodate the walkthrough. Installed only
/// while `demoMerchantSessionProvider` is on, which itself is debug-only.
///
/// ## Writes
///
/// Every write here completes without doing anything. That is the whole point:
/// a walkthrough must not create an offer, promote a story, charge a wallet,
/// redeem a claim or upload a photo. They resolve rather than throw so the
/// presenter does not hit an error dialog mid-demo — the flow is shown, the
/// effect is not persisted, and the next run starts identical. Reads keep
/// returning the catalog, so nothing on screen pretends the write landed.
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
  @override
  Future<String?> getLinkedVenueId(String userId, {Source? source}) async =>
      DemoMode.venueId;

  @override
  Future<bool> venueExists(String venueId, {Source? source}) async => true;

  @override
  Future<MerchantVenue?> getVenue(String venueId, {Source? source}) async =>
      buildDemoMerchantVenue();

  @override
  Future<MerchantStats> getStats(String venueId, {Source? source}) async =>
      buildDemoMerchantStats();

  @override
  Future<List<MerchantReview>> getReviews(
    String venueId, {
    int limit = 100,
    Source? source,
  }) async => buildDemoMerchantReviews().take(limit).toList();

  @override
  Future<List<MerchantOffer>> getOffers(
    String venueId, {
    Source? source,
  }) async => buildDemoMerchantOffers();

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
  @override
  Future<void> setOfferStatus({
    required String offerId,
    required MerchantOfferStatus status,
  }) async {}

  @override
  Future<void> deleteOffer(String offerId) async {}

  @override
  Future<void> saveOffer(MerchantOfferUpsertInput input) async {}

  @override
  Future<Map<int, double>> fetchOfferPinPricing() async =>
      demoMerchantOfferPinPricing;

  @override
  Future<void> pinOffer({
    required String offerId,
    required int durationDays,
    required String requestId,
  }) async {}
}

class DemoMerchantReviewsRepository implements MerchantReviewsRepository {
  @override
  Future<void> submitReply({
    required String venueId,
    required String reviewId,
    required String replyText,
    required String authorIdentifier,
  }) async {}

  @override
  Future<void> deleteReply({
    required String venueId,
    required String reviewId,
  }) async {}
}

class DemoMerchantStoriesRepository implements MerchantStoriesRepository {
  @override
  Stream<List<MerchantStory>> watchStories({
    required String venueId,
    int limit = 20,
  }) => Stream<List<MerchantStory>>.value(
    buildDemoMerchantStories().take(limit).toList(),
  );

  @override
  Future<StoryPromotionPricing> getStoryPromotionPricing() async =>
      demoMerchantStoryPromotionPricing;

  @override
  Future<void> promoteStory({
    required String storyId,
    required int durationDays,
    required String requestId,
  }) async {}

  @override
  Future<void> deleteStory({
    required String storyId,
    String? imageUrl,
    String? videoUrl,
  }) async {}

  @override
  Future<void> createStory({
    required String venueId,
    required String text,
    required int expiryHours,
    required String? createdBy,
    XFile? image,
    XFile? video,
  }) async {}

  @override
  Future<bool> hasActiveStory({
    required String venueId,
    DateTime? now,
  }) async => true;
}

class DemoMerchantPhotosRepository implements MerchantPhotosRepository {
  /// Returns the paths already in the catalog rather than the picked files:
  /// nothing is uploaded, so there is no URL to hand back.
  @override
  Future<List<String>> uploadPhotos({
    required String venueId,
    required List<XFile> files,
  }) async => buildDemoMerchantVenue().photos;

  @override
  Future<void> deletePhoto({
    required String venueId,
    required String photoUrl,
  }) async {}

  @override
  Future<void> setPrimaryPhoto({
    required String venueId,
    required List<String> currentPhotos,
    required String targetUrl,
  }) async {}
}

class DemoMerchantHoursRepository implements MerchantHoursRepository {
  @override
  Future<void> saveHours({
    required String venueId,
    required bool is24Hours,
    required Map<String, List<Map<String, String>>> hours,
  }) async {}
}

class DemoMerchantVenueProfileRepository
    implements MerchantVenueProfileRepository {
  @override
  Future<void> updateVenueProfile({
    required String venueId,
    required String nameAr,
    required String nameEn,
    required String phone,
    required String city,
  }) async {}
}

class DemoMerchantWalletRepository implements MerchantWalletRepository {
  @override
  Stream<MerchantWallet?> streamWallet(String venueId) =>
      Stream<MerchantWallet?>.value(buildDemoMerchantWallet());

  @override
  Stream<List<MerchantTopUpRequest>> streamTopUpRequests(String venueId) =>
      Stream<List<MerchantTopUpRequest>>.value(
        buildDemoMerchantTopUpRequests(),
      );

  @override
  Stream<List<MerchantWalletEntry>> streamWalletEntries(String venueId) =>
      Stream<List<MerchantWalletEntry>>.value(
        buildDemoMerchantWalletEntries(),
      );

  @override
  Stream<MerchantWalletReport?> streamWalletReport(String venueId) =>
      Stream<MerchantWalletReport?>.value(buildDemoMerchantWalletReport());

  @override
  Future<void> createTopUpRequest({
    required double amount,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async {}

  /// No Storage bucket is touched; the caller only needs a non-empty string.
  @override
  Future<String> uploadTopUpProof({
    required String venueId,
    required File file,
    required String fileName,
  }) async => 'asset://demo/topup-proof';
}

class DemoMerchantInviteRepository implements MerchantInviteRepository {
  /// The walkthrough enters through `/demo/merchant`, never through an invite
  /// code, so this exists to keep the screen renderable rather than to be used.
  @override
  Future<MerchantInviteResult> redeemInviteCode(String code) async =>
      const MerchantInviteResult(
        type: MerchantInviteResultType.success,
        venueId: DemoMode.venueId,
      );
}

/// Claim validation and redemption for the QR scanner.
///
/// [validateToken] answers from the offer catalog so the scanner has something
/// to render; [redeemToken] reports success without marking anything redeemed,
/// because there is no claim to mark.
class DemoMerchantRepository extends MerchantRepository {
  @override
  Future<MerchantValidationResult> validateToken(String token) async =>
      buildDemoMerchantValidation(token);

  @override
  Future<bool> redeemToken(String token, {double? billAmount}) async =>
      buildDemoMerchantValidation(token).canRedeem;
}
