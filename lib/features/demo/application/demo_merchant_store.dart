import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:wain_app/features/demo/data/demo_merchant_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
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

part 'demo_merchant_store_content.dart';
part 'demo_merchant_store_copies.dart';
part 'demo_merchant_store_wallet.dart';

/// Process-local state behind the merchant walkthrough.
///
/// Mutations are intentionally real from the UI's point of view, but nothing
/// leaves the process. Disposing or resetting this store restores the catalog.
class DemoMerchantStore {
  DemoMerchantStore() {
    reset(notify: false);
  }

  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );

  late MerchantVenue _venue;
  late List<MerchantOffer> _offers;
  late List<MerchantReview> _reviews;
  late List<MerchantStory> _stories;
  late MerchantWallet _wallet;
  late List<MerchantWalletEntry> _walletEntries;
  late MerchantWalletReport _walletReport;
  late List<MerchantTopUpRequest> _topUpRequests;
  final Set<String> _redeemedTokens = <String>{};
  var _localOfferSerial = 0;
  var _localStorySerial = 0;
  var _localTopUpSerial = 0;
  var _localWalletEntrySerial = 0;

  MerchantVenue get venue => _venue;
  List<MerchantOffer> get offers => List.unmodifiable(_offers);
  List<MerchantReview> get reviews => List.unmodifiable(_reviews);
  MerchantStats get stats => MerchantStats(
    rating: _reviews.isEmpty
        ? 0
        : _reviews.fold<double>(0, (sum, review) => sum + review.rating) /
              _reviews.length,
    reviewCount: _reviews.length,
    recentReviews: _reviews.take(3).toList(),
  );

  Stream<List<MerchantStory>> watchStories() =>
      _watch(() => List<MerchantStory>.unmodifiable(_stories));
  Stream<MerchantWallet?> watchWallet() => _watch(() => _wallet);
  Stream<List<MerchantWalletEntry>> watchWalletEntries() =>
      _watch(() => List<MerchantWalletEntry>.unmodifiable(_walletEntries));
  Stream<MerchantWalletReport?> watchWalletReport() =>
      _watch(() => _walletReport);
  Stream<List<MerchantTopUpRequest>> watchTopUpRequests() =>
      _watch(() => List<MerchantTopUpRequest>.unmodifiable(_topUpRequests));

  Stream<T> _watch<T>(T Function() value) async* {
    yield value();
    await for (final _ in _changes.stream) {
      yield value();
    }
  }

  void reset({bool notify = true}) {
    _venue = buildDemoMerchantVenue();
    _offers = buildDemoMerchantOffers();
    _reviews = buildDemoMerchantReviews();
    _stories = buildDemoMerchantStories();
    _wallet = buildDemoMerchantWallet();
    _walletEntries = buildDemoMerchantWalletEntries();
    _walletReport = buildDemoMerchantWalletReport();
    _topUpRequests = buildDemoMerchantTopUpRequests();
    _redeemedTokens.clear();
    _localOfferSerial = 0;
    _localStorySerial = 0;
    _localTopUpSerial = 0;
    _localWalletEntrySerial = 0;
    if (notify) _notify();
  }

  void setOfferStatus(String offerId, MerchantOfferStatus status) {
    _replaceOffer(
      offerId,
      (offer) => _copyOffer(
        offer,
        status: status,
        isActive: status == MerchantOfferStatus.active,
      ),
    );
  }

  void deleteOffer(String offerId) {
    _offers.removeWhere((offer) => offer.id == offerId);
    _notify();
  }

  void saveOffer(MerchantOfferUpsertInput input) {
    final existingIndex = _offers.indexWhere(
      (offer) => offer.id == input.offerId,
    );
    if (existingIndex >= 0) {
      final existing = _offers[existingIndex];
      _offers[existingIndex] = MerchantOffer(
        id: existing.id,
        venueId: existing.venueId,
        titleAr: input.titleAr,
        title: input.titleAr,
        descriptionAr: input.descriptionAr,
        description: input.descriptionAr,
        termsAr: input.termsAr,
        discountType: input.discountType,
        discountValue: input.discountValue,
        singleUsePerCustomer: input.singleUsePerCustomer,
        isActive: input.isActive,
        startAt: input.clearStartAt ? null : input.startAt ?? existing.startAt,
        endAt: input.clearEndAt ? null : input.endAt ?? existing.endAt,
        status: input.isActive
            ? MerchantOfferStatus.active
            : MerchantOfferStatus.paused,
        claimsCount: existing.claimsCount,
        redeemedCount: existing.redeemedCount,
        conversionRate: existing.conversionRate,
        isFeatured: existing.isFeatured,
        featuredUntil: existing.featuredUntil,
      );
    } else {
      _localOfferSerial += 1;
      _offers.insert(
        0,
        MerchantOffer(
          id: 'demo_offer_local_$_localOfferSerial',
          venueId: input.venueId,
          titleAr: input.titleAr,
          title: input.titleAr,
          descriptionAr: input.descriptionAr,
          description: input.descriptionAr,
          termsAr: input.termsAr,
          discountType: input.discountType,
          discountValue: input.discountValue,
          singleUsePerCustomer: input.singleUsePerCustomer,
          isActive: input.isActive,
          startAt: input.startAt ?? demoMerchantNow(),
          endAt: input.endAt,
          status: input.isActive
              ? MerchantOfferStatus.active
              : MerchantOfferStatus.paused,
          claimsCount: 0,
          redeemedCount: 0,
          conversionRate: null,
          isFeatured: false,
          featuredUntil: null,
        ),
      );
    }
    _notify();
  }

  void pinOffer(String offerId, int durationDays) {
    if (!_offers.any((offer) => offer.id == offerId)) {
      throw StateError('offer_not_found');
    }
    final price = demoMerchantOfferPinPricing[durationDays] ?? 0;
    _debit(price, featureKey: 'offer_feature', referenceId: offerId);
    _replaceOffer(
      offerId,
      (offer) => _copyOffer(
        offer,
        isFeatured: true,
        featuredUntil: demoMerchantNow().add(Duration(days: durationDays)),
      ),
    );
  }

  void submitReply(String reviewId, String text, String author) {
    final index = _reviews.indexWhere((review) => review.id == reviewId);
    if (index < 0) throw StateError('review_not_found');
    _reviews[index] = _copyReview(
      _reviews[index],
      merchantReply: text,
      merchantReplyAt: demoMerchantNow(),
      merchantReplyBy: author,
    );
    _notify();
  }

  void deleteReply(String reviewId) {
    final index = _reviews.indexWhere((review) => review.id == reviewId);
    if (index < 0) throw StateError('review_not_found');
    _reviews[index] = _copyReview(_reviews[index], clearReply: true);
    _notify();
  }

  void _replaceOffer(
    String offerId,
    MerchantOffer Function(MerchantOffer) change,
  ) {
    final index = _offers.indexWhere((offer) => offer.id == offerId);
    if (index < 0) throw StateError('offer_not_found');
    _offers[index] = change(_offers[index]);
    _notify();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() => _changes.close();
}
