import 'package:wain_app/features/merchant/domain/entities/merchant_action_item.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';

class MerchantActionFeedService {
  const MerchantActionFeedService();

  List<MerchantActionItem> buildFeed({
    required MerchantAnalytics analytics,
    required List<MerchantOffer> offers,
    required MerchantStats stats,
    required DateTime now,
  }) {
    final actions = <MerchantActionItem>[];

    if (analytics.isStaleAt(now)) {
      actions.add(RefreshAnalyticsAction(lastUpdated: analytics.updatedAt));
    }

    final parsedOffers = offers
        .where((offer) => offer.id.isNotEmpty)
        .toList(growable: false);

    final expiringOffers =
        parsedOffers
            .where(
              (offer) =>
                  offer.isCurrentlyActiveAt(now) &&
                  offer.endAt != null &&
                  offer.endAt!.isAfter(now) &&
                  offer.endAt!.difference(now) <= const Duration(hours: 48),
            )
            .toList()
          ..sort((left, right) => left.endAt!.compareTo(right.endAt!));

    for (final offer in expiringOffers.take(2)) {
      actions.add(
        ExpiringOfferAction(
          offerId: offer.id,
          offerTitle: offer.primaryTitle.isNotEmpty
              ? offer.primaryTitle
              : 'Offer',
          expiresAt: offer.endAt!,
        ),
      );
    }

    final expiredOffers =
        parsedOffers
            .where((offer) => offer.endAt != null && !offer.endAt!.isAfter(now))
            .toList()
          ..sort((left, right) => right.endAt!.compareTo(left.endAt!));

    if (expiredOffers.isNotEmpty) {
      final offer = expiredOffers.first;
      actions.add(
        ExpiredOfferAction(
          offerId: offer.id,
          offerTitle: offer.primaryTitle.isNotEmpty
              ? offer.primaryTitle
              : 'Offer',
          expiredAt: offer.endAt!,
        ),
      );
    }

    final unansweredReviews = stats.recentReviews
        .where(
          (review) =>
              !review.hasReply &&
              review.createdAt != null &&
              now.difference(review.createdAt!) >= const Duration(hours: 24),
        )
        .toList();

    if (unansweredReviews.isNotEmpty) {
      unansweredReviews.sort((left, right) {
        final leftTime = left.createdAt;
        final rightTime = right.createdAt;
        if (leftTime == null && rightTime == null) return 0;
        if (leftTime == null) return 1;
        if (rightTime == null) return -1;
        return leftTime.compareTo(rightTime);
      });
      actions.add(
        UnansweredReviewsAction(
          count: unansweredReviews.length,
          oldestPendingAt: unansweredReviews.first.createdAt,
        ),
      );
    }

    final hasActiveOffer = parsedOffers.any(
      (offer) => offer.isCurrentlyActiveAt(now),
    );
    if (!hasActiveOffer && analytics.viewsThisWeek > 0) {
      actions.add(NoActiveOffersAction(viewsThisWeek: analytics.viewsThisWeek));
    }

    actions.sort((left, right) {
      final priorityOrder = _priorityRank(
        left.priority,
      ).compareTo(_priorityRank(right.priority));
      if (priorityOrder != 0) {
        return priorityOrder;
      }
      return _tieBreak(left, right);
    });

    return actions.take(5).toList(growable: false);
  }

  int _priorityRank(MerchantActionPriority priority) {
    return switch (priority) {
      MerchantActionPriority.critical => 0,
      MerchantActionPriority.important => 1,
      MerchantActionPriority.suggested => 2,
    };
  }

  int _tieBreak(MerchantActionItem left, MerchantActionItem right) {
    final leftRank = switch (left) {
      RefreshAnalyticsAction _ => 0,
      ExpiringOfferAction _ => 1,
      ExpiredOfferAction _ => 2,
      UnansweredReviewsAction _ => 3,
      NoActiveOffersAction _ => 4,
    };
    final rightRank = switch (right) {
      RefreshAnalyticsAction _ => 0,
      ExpiringOfferAction _ => 1,
      ExpiredOfferAction _ => 2,
      UnansweredReviewsAction _ => 3,
      NoActiveOffersAction _ => 4,
    };
    if (leftRank != rightRank) {
      return leftRank.compareTo(rightRank);
    }

    return switch ((left, right)) {
      (ExpiringOfferAction l, ExpiringOfferAction r) => l.expiresAt.compareTo(
        r.expiresAt,
      ),
      (ExpiredOfferAction l, ExpiredOfferAction r) => r.expiredAt.compareTo(
        l.expiredAt,
      ),
      (UnansweredReviewsAction l, UnansweredReviewsAction r) =>
        (l.oldestPendingAt ?? DateTime.now()).compareTo(
          r.oldestPendingAt ?? DateTime.now(),
        ),
      (NoActiveOffersAction l, NoActiveOffersAction r) =>
        r.viewsThisWeek.compareTo(l.viewsThisWeek),
      _ => 0,
    };
  }
}
