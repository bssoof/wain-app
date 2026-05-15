import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_dashboard_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

void main() {
  group('MerchantDashboardRepository', () {
    test(
      'reads linked venue id from authoritative merchants document',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = MerchantDashboardRepository(
          firestore: firestore,
          functions: _FakeFirebaseFunctions(),
        );

        await firestore.collection('merchants').doc('merchant-1').set({
          'venue_id': 'venue-authoritative',
        });
        await firestore.collection('users').doc('merchant-1').set({
          'merchant_venue_id': 'venue-legacy',
        });

        final venueId = await repository.getLinkedVenueId('merchant-1');

        expect(venueId, 'venue-authoritative');
      },
    );

    test('falls back to legacy users merchant venue id', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = MerchantDashboardRepository(
        firestore: firestore,
        functions: _FakeFirebaseFunctions(),
      );

      await firestore.collection('users').doc('merchant-1').set({
        'merchant_venue_id': ' venue-legacy ',
      });

      final venueId = await repository.getLinkedVenueId('merchant-1');

      expect(venueId, 'venue-legacy');
    });
  });

  group('Merchant dashboard data mappers', () {
    test('maps offer docs into MerchantOffer', () {
      final offer = mapMerchantOfferData({
        'id': 'offer-1',
        'venue_id': 'venue-1',
        'title_ar': 'عرض',
        'description_ar': 'وصف',
        'terms_ar': 'شروط',
        'discount_type': 'percent',
        'discount_value': 25,
        'single_use_per_customer': false,
        'is_active': true,
        'status': 'paused',
        'start_at': Timestamp.fromDate(DateTime(2026, 4, 1)),
        'end_at': Timestamp.fromDate(DateTime(2026, 4, 10)),
        'claims_count': 8,
        'redeemed_count': 2,
        'conversion_rate': 0.25,
      });

      expect(offer.id, 'offer-1');
      expect(offer.venueId, 'venue-1');
      expect(offer.primaryTitle, 'عرض');
      expect(offer.primaryDescription, 'وصف');
      expect(offer.termsAr, 'شروط');
      expect(offer.discountType, 'percent');
      expect(offer.discountValue, 25);
      expect(offer.singleUsePerCustomer, isFalse);
      expect(offer.status, MerchantOfferStatus.paused);
      expect(offer.startAt, DateTime(2026, 4, 1));
      expect(offer.endAt, DateTime(2026, 4, 10));
      expect(offer.claimsCount, 8);
      expect(offer.redeemedCount, 2);
      expect(offer.conversionPercent, 25);
    });

    test('derives effective offer status for legacy and expired offers', () {
      final legacyOffer = mapMerchantOfferData({
        'id': 'offer-legacy',
        'venue_id': 'venue-1',
        'is_active': false,
      });
      final expiredOffer = mapMerchantOfferData({
        'id': 'offer-expired',
        'venue_id': 'venue-1',
        'is_active': true,
        'status': 'active',
        'end_at': Timestamp.fromDate(DateTime(2026, 4, 1)),
      });

      expect(
        legacyOffer.effectiveStatusAt(DateTime(2026, 4, 2)),
        MerchantOfferStatus.paused,
      );
      expect(
        expiredOffer.effectiveStatusAt(DateTime(2026, 4, 2)),
        MerchantOfferStatus.expired,
      );
    });

    test('maps review docs into MerchantReview', () {
      final review = mapMerchantReviewData({
        'id': 'review-1',
        'user_name': 'Ali',
        'user_photo_url': 'https://example.com/u.png',
        'rating': 4,
        'comment': 'رأي',
        'created_at': Timestamp.fromDate(DateTime(2026, 4, 1, 9)),
        'merchant_reply': 'شكراً',
        'merchant_reply_at': Timestamp.fromDate(DateTime(2026, 4, 1, 12)),
        'merchant_reply_by': 'merchant@wain.app',
      });

      expect(review.id, 'review-1');
      expect(review.trimmedUserName, 'Ali');
      expect(review.rating, 4);
      expect(review.trimmedText, 'رأي');
      expect(review.createdAt, DateTime(2026, 4, 1, 9));
      expect(review.hasReply, isTrue);
      expect(review.merchantReplyAt, DateTime(2026, 4, 1, 12));
      expect(review.merchantReplyBy, 'merchant@wain.app');
    });

    test('maps venue docs into MerchantVenue', () {
      final venue = mapMerchantVenueData({
        'id': 'venue-1',
        'name_ar': 'المحل',
        'name_en': 'Venue',
        'city': 'Ramallah',
        'phone': '0591234567',
        'photos': ['https://example.com/photo.jpg'],
        'categories': ['Restaurant'],
        'tags': {
          'mood': ['Chill', 'Family'],
        },
        'hours': {
          'monday': [
            {'open': '09:00', 'close': '18:00', 'spans_midnight': false},
          ],
        },
        'is_24h': false,
        'active_menu_version_id': 'menu-v1',
        'last_story_at': Timestamp.fromDate(DateTime(2026, 4, 4, 10)),
        'rating': 4.5,
        'min_price': 20,
        'max_price': 80,
        'lat': 31.9,
        'lng': 35.2,
      });

      expect(venue.id, 'venue-1');
      expect(venue.displayName, 'المحل');
      expect(venue.primaryPhoto, 'https://example.com/photo.jpg');
      expect(venue.categories, ['Restaurant']);
      expect(venue.moodLabels, ['Chill', 'Family']);
      expect(venue.activeMenuVersionId, 'menu-v1');
      expect(venue.lastStoryAt, DateTime(2026, 4, 4, 10));
      expect(venue.hours['monday'], hasLength(1));
      expect(venue.hours['monday']!.first, isA<MerchantVenueHoursSlot>());
    });

    test('maps analytics docs into MerchantAnalytics', () {
      final analytics = mapMerchantAnalyticsData({
        'views_total': 100,
        'views_this_week': 20,
        'views_last_week': 10,
        'calls_total': 8,
        'calls_this_week': 3,
        'calls_last_week': 2,
        'navs_total': 6,
        'navs_this_week': 2,
        'navs_last_week': 1,
        'story_views_total': 50,
        'story_views_this_week': 11,
        'story_to_venue_views_total': 12,
        'story_to_venue_views_this_week': 4,
        'story_to_venue_views_7d': 6,
        'offer_detail_views_total': 34,
        'offer_detail_views_7d': 12,
        'offer_detail_views_prev_7d': 6,
        'claim_clicks_total': 20,
        'claim_clicks_7d': 8,
        'claim_clicks_prev_7d': 3,
        'claims_created_total': 14,
        'claims_created_7d': 5,
        'claims_created_prev_7d': 2,
        'redemptions_total': 10,
        'redemptions_7d': 4,
        'redemptions_prev_7d': 1,
        'contact_intent_7d': 5,
        'contact_intent_prev_7d': 3,
        'contact_rate_7d': 0.25,
        'detail_to_claim_click_rate_7d': 0.5,
        'view_to_claim_rate_7d': 0.1,
        'claim_to_redemption_rate_7d': 0.8,
        'updated_at': Timestamp.fromDate(DateTime(2026, 4, 3, 10, 30)),
      });

      expect(analytics.viewsTotal, 100);
      expect(analytics.viewsThisWeek, 20);
      expect(analytics.callsTotal, 8);
      expect(analytics.navsTotal, 6);
      expect(analytics.storyViewsThisWeek, 11);
      expect(analytics.storyToVenueViewsTotal, 12);
      expect(analytics.storyToVenueViewsThisWeek, 4);
      expect(analytics.storyToVenueViews7d, 6);
      expect(analytics.storyToVenueConversionRate, 0.24);
      expect(analytics.offerDetailViews7d, 12);
      expect(analytics.claimClicks7d, 8);
      expect(analytics.claimsCreated7d, 5);
      expect(analytics.redemptions7d, 4);
      expect(analytics.detailToClaimClickRate7d, 0.5);
      expect(analytics.updatedAt, DateTime(2026, 4, 3, 10, 30));
    });

    test('defaults story attribution analytics fields for legacy docs', () {
      final analytics = mapMerchantAnalyticsData({
        'story_views_total': 50,
        'story_views_this_week': 11,
      });
      final point = mapMerchantDailyPointData({
        'date_key': '2026-04-03',
        'story_views': 5,
      });

      expect(analytics.storyToVenueViewsTotal, 0);
      expect(analytics.storyToVenueViewsThisWeek, 0);
      expect(analytics.storyToVenueViews7d, 0);
      expect(analytics.storyToVenueConversionRate, 0);
      expect(point.storyToVenueViews, 0);
    });

    test('maps daily analytics docs into MerchantDailyPoint', () {
      final point = mapMerchantDailyPointData({
        'date_key': '2026-04-03',
        'views': 12,
        'calls': 2,
        'navs': 1,
        'story_views': 5,
        'story_to_venue_views': 3,
        'offer_detail_views': 4,
        'claim_clicks': 2,
        'claims_created': 1,
        'redemptions': 1,
      });

      expect(point.dateKey, '2026-04-03');
      expect(point.views, 12);
      expect(point.calls, 2);
      expect(point.navs, 1);
      expect(point.storyViews, 5);
      expect(point.storyToVenueViews, 3);
      expect(point.offerDetailViews, 4);
      expect(point.claimClicks, 2);
      expect(point.claimsCreated, 1);
      expect(point.redemptions, 1);
    });

    test(
      'maps per-offer analytics docs into MerchantOfferAnalyticsSummary',
      () {
        final summary = mapMerchantOfferAnalyticsSummaryData({
          'id': 'offer-1',
          'offer_id': 'offer-1',
          'offer_title_ar': 'عرض قوي',
          'status': 'active',
          'detail_views_7d': 22,
          'detail_views_30d': 40,
          'claim_clicks_7d': 10,
          'claim_clicks_30d': 18,
          'claims_created_7d': 6,
          'claims_created_30d': 11,
          'redemptions_7d': 4,
          'redemptions_30d': 7,
          'claim_to_redemption_rate_7d': 0.6667,
          'claim_to_redemption_rate_30d': 0.6364,
          'updated_at': Timestamp.fromDate(DateTime(2026, 4, 5, 12)),
        });

        expect(summary.offerId, 'offer-1');
        expect(summary.offerTitleAr, 'عرض قوي');
        expect(summary.status, MerchantOfferStatus.active);
        expect(summary.detailViews7d, 22);
        expect(summary.detailViews30d, 40);
        expect(summary.claimsCreated7d, 6);
        expect(summary.claimsCreated30d, 11);
        expect(summary.redemptions7d, 4);
        expect(summary.redemptions30d, 7);
        expect(summary.claimToRedemptionRate7d, closeTo(0.6667, 0.0001));
        expect(summary.claimToRedemptionRate30d, closeTo(0.6364, 0.0001));
        expect(summary.updatedAt, DateTime(2026, 4, 5, 12));
      },
    );
  });
}
