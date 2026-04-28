import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_action_item.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/services/merchant_action_feed_service.dart';

MerchantOffer _offer({
  required String id,
  String titleAr = '',
  required bool isActive,
  DateTime? endAt,
}) {
  return MerchantOffer(
    id: id,
    venueId: 'venue-1',
    titleAr: titleAr,
    title: '',
    descriptionAr: '',
    description: '',
    termsAr: '',
    discountType: 'percent',
    discountValue: 0,
    singleUsePerCustomer: true,
    isActive: isActive,
    startAt: null,
    endAt: endAt,
    status: null,
    claimsCount: 0,
    redeemedCount: 0,
    conversionRate: null,
    isFeatured: false,
    featuredUntil: null,
  );
}

MerchantReview _review({
  required String id,
  DateTime? createdAt,
  String? merchantReply,
}) {
  return MerchantReview(
    id: id,
    userName: '',
    userPhotoUrl: null,
    rating: 0,
    text: '',
    createdAt: createdAt,
    merchantReply: merchantReply,
    merchantReplyAt: null,
    merchantReplyBy: null,
  );
}

void main() {
  group('MerchantActionFeedService', () {
    const service = MerchantActionFeedService();

    test('creates refresh action when analytics are stale', () {
      final actions = service.buildFeed(
        analytics: MerchantAnalytics(
          viewsTotal: 10,
          viewsThisWeek: 4,
          viewsLastWeek: 2,
          callsTotal: 1,
          callsThisWeek: 1,
          callsLastWeek: 0,
          navsTotal: 1,
          navsThisWeek: 1,
          navsLastWeek: 0,
          storyViewsTotal: 0,
          storyViewsThisWeek: 0,
          updatedAt: DateTime(2026, 4, 1),
        ),
        offers: const [],
        stats: MerchantStats.empty(),
        now: DateTime(2026, 4, 4),
      );

      expect(actions.first, isA<RefreshAnalyticsAction>());
    });

    test('creates expiring offer action from typed offers', () {
      final actions = service.buildFeed(
        analytics: MerchantAnalytics(
          viewsTotal: 50,
          viewsThisWeek: 12,
          viewsLastWeek: 9,
          callsTotal: 0,
          callsThisWeek: 0,
          callsLastWeek: 0,
          navsTotal: 0,
          navsThisWeek: 0,
          navsLastWeek: 0,
          storyViewsTotal: 0,
          storyViewsThisWeek: 0,
          updatedAt: DateTime(2026, 4, 4, 10),
        ),
        offers: [
          _offer(
            id: 'offer-1',
            titleAr: 'خصم 20%',
            isActive: true,
            endAt: DateTime(2026, 4, 5, 12),
          ),
        ],
        stats: MerchantStats.empty(),
        now: DateTime(2026, 4, 4, 8),
      );

      expect(actions.whereType<ExpiringOfferAction>(), isNotEmpty);
      expect(actions.whereType<NoActiveOffersAction>(), isEmpty);
    });

    test('creates no-active-offers action when venue has traffic only', () {
      final actions = service.buildFeed(
        analytics: MerchantAnalytics(
          viewsTotal: 50,
          viewsThisWeek: 18,
          viewsLastWeek: 9,
          callsTotal: 0,
          callsThisWeek: 0,
          callsLastWeek: 0,
          navsTotal: 0,
          navsThisWeek: 0,
          navsLastWeek: 0,
          storyViewsTotal: 0,
          storyViewsThisWeek: 0,
          updatedAt: DateTime(2026, 4, 4, 10),
        ),
        offers: const [],
        stats: MerchantStats.empty(),
        now: DateTime(2026, 4, 4, 12),
      );

      expect(
        actions.whereType<NoActiveOffersAction>().single.viewsThisWeek,
        18,
      );
    });

    test(
      'creates unanswered reviews action for pending replies older than a day',
      () {
        final actions = service.buildFeed(
          analytics: MerchantAnalytics(
            viewsTotal: 0,
            viewsThisWeek: 0,
            viewsLastWeek: 0,
            callsTotal: 0,
            callsThisWeek: 0,
            callsLastWeek: 0,
            navsTotal: 0,
            navsThisWeek: 0,
            navsLastWeek: 0,
            storyViewsTotal: 0,
            storyViewsThisWeek: 0,
            updatedAt: DateTime(2026, 4, 4, 10),
          ),
          offers: const [],
          stats: MerchantStats(
            rating: 3.8,
            reviewCount: 2,
            recentReviews: [
              _review(id: 'review-1', createdAt: DateTime(2026, 4, 2, 9)),
              _review(
                id: 'review-2',
                createdAt: DateTime(2026, 4, 4, 6),
                merchantReply: 'Thanks',
              ),
            ],
          ),
          now: DateTime(2026, 4, 4, 12),
        );

        expect(actions.whereType<UnansweredReviewsAction>().single.count, 1);
      },
    );
  });
}
