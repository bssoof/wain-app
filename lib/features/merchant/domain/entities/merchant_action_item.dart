enum MerchantActionPriority { critical, important, suggested }

sealed class MerchantActionItem {
  const MerchantActionItem();

  MerchantActionPriority get priority;
}

class RefreshAnalyticsAction extends MerchantActionItem {
  final DateTime? lastUpdated;

  const RefreshAnalyticsAction({required this.lastUpdated});

  @override
  MerchantActionPriority get priority => MerchantActionPriority.critical;
}

class ExpiringOfferAction extends MerchantActionItem {
  final String offerId;
  final String offerTitle;
  final DateTime expiresAt;

  const ExpiringOfferAction({
    required this.offerId,
    required this.offerTitle,
    required this.expiresAt,
  });

  @override
  MerchantActionPriority get priority => MerchantActionPriority.important;
}

class ExpiredOfferAction extends MerchantActionItem {
  final String offerId;
  final String offerTitle;
  final DateTime expiredAt;

  const ExpiredOfferAction({
    required this.offerId,
    required this.offerTitle,
    required this.expiredAt,
  });

  @override
  MerchantActionPriority get priority => MerchantActionPriority.important;
}

class UnansweredReviewsAction extends MerchantActionItem {
  final int count;
  final DateTime? oldestPendingAt;

  const UnansweredReviewsAction({
    required this.count,
    required this.oldestPendingAt,
  });

  @override
  MerchantActionPriority get priority => MerchantActionPriority.important;
}

class NoActiveOffersAction extends MerchantActionItem {
  final int viewsThisWeek;

  const NoActiveOffersAction({required this.viewsThisWeek});

  @override
  MerchantActionPriority get priority => MerchantActionPriority.important;
}
