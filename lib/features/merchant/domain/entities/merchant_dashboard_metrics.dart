import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';

final DateTime merchantStoryAttributionStartDate = DateTime(2026, 5, 14);

class MerchantStats {
  final double rating;
  final int reviewCount;
  final List<MerchantReview> recentReviews;

  const MerchantStats({
    required this.rating,
    required this.reviewCount,
    required this.recentReviews,
  });

  factory MerchantStats.empty() =>
      const MerchantStats(rating: 0.0, reviewCount: 0, recentReviews: []);
}

/// Server-aggregated analytics summary — read-only from client.
class MerchantAnalytics {
  final int viewsTotal;
  final int viewsThisWeek;
  final int viewsLastWeek;
  final int callsTotal;
  final int callsThisWeek;
  final int callsLastWeek;
  final int navsTotal;
  final int navsThisWeek;
  final int navsLastWeek;
  final int storyViewsTotal;
  final int storyViewsThisWeek;
  final int storyToVenueViewsTotal;
  final int storyToVenueViewsThisWeek;
  final int storyToVenueViews7d;
  final int offerDetailViewsTotal;
  final int offerDetailViews7d;
  final int offerDetailViewsPrev7d;
  final int claimClicksTotal;
  final int claimClicks7d;
  final int claimClicksPrev7d;
  final int claimsCreatedTotal;
  final int claimsCreated7d;
  final int claimsCreatedPrev7d;
  final int redemptionsTotal;
  final int redemptions7d;
  final int redemptionsPrev7d;
  final int contactIntent7d;
  final int contactIntentPrev7d;
  final double contactRate7d;
  final double detailToClaimClickRate7d;
  final double viewToClaimRate7d;
  final double claimToRedemptionRate7d;
  final DateTime? updatedAt;

  const MerchantAnalytics({
    required this.viewsTotal,
    required this.viewsThisWeek,
    required this.viewsLastWeek,
    required this.callsTotal,
    required this.callsThisWeek,
    required this.callsLastWeek,
    required this.navsTotal,
    required this.navsThisWeek,
    required this.navsLastWeek,
    required this.storyViewsTotal,
    required this.storyViewsThisWeek,
    this.storyToVenueViewsTotal = 0,
    this.storyToVenueViewsThisWeek = 0,
    this.storyToVenueViews7d = 0,
    this.offerDetailViewsTotal = 0,
    this.offerDetailViews7d = 0,
    this.offerDetailViewsPrev7d = 0,
    this.claimClicksTotal = 0,
    this.claimClicks7d = 0,
    this.claimClicksPrev7d = 0,
    this.claimsCreatedTotal = 0,
    this.claimsCreated7d = 0,
    this.claimsCreatedPrev7d = 0,
    this.redemptionsTotal = 0,
    this.redemptions7d = 0,
    this.redemptionsPrev7d = 0,
    this.contactIntent7d = 0,
    this.contactIntentPrev7d = 0,
    this.contactRate7d = 0,
    this.detailToClaimClickRate7d = 0,
    this.viewToClaimRate7d = 0,
    this.claimToRedemptionRate7d = 0,
    required this.updatedAt,
  });

  factory MerchantAnalytics.empty() => const MerchantAnalytics(
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
    storyToVenueViewsTotal: 0,
    storyToVenueViewsThisWeek: 0,
    storyToVenueViews7d: 0,
    offerDetailViewsTotal: 0,
    offerDetailViews7d: 0,
    offerDetailViewsPrev7d: 0,
    claimClicksTotal: 0,
    claimClicks7d: 0,
    claimClicksPrev7d: 0,
    claimsCreatedTotal: 0,
    claimsCreated7d: 0,
    claimsCreatedPrev7d: 0,
    redemptionsTotal: 0,
    redemptions7d: 0,
    redemptionsPrev7d: 0,
    contactIntent7d: 0,
    contactIntentPrev7d: 0,
    contactRate7d: 0,
    detailToClaimClickRate7d: 0,
    viewToClaimRate7d: 0,
    claimToRedemptionRate7d: 0,
    updatedAt: null,
  );

  double? get viewsWoW => _wow(viewsThisWeek, viewsLastWeek);
  double? get callsWoW => _wow(callsThisWeek, callsLastWeek);
  double? get navsWoW => _wow(navsThisWeek, navsLastWeek);
  double? get storyToVenueConversionRate =>
      storyViewsTotal == 0 ? null : storyToVenueViewsTotal / storyViewsTotal;
  bool get isStale => isStaleAt(DateTime.now());

  bool isStaleAt(DateTime now) {
    if (updatedAt == null) {
      return true;
    }
    return now.difference(updatedAt!) > const Duration(hours: 24);
  }

  double? _wow(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : null;
    return ((current - previous) / previous) * 100;
  }
}

class MerchantDailyPoint {
  final String dateKey; // YYYY-MM-DD
  final int views;
  final int calls;
  final int navs;
  final int storyViews;
  final int storyToVenueViews;
  final int offerDetailViews;
  final int claimClicks;
  final int claimsCreated;
  final int redemptions;

  const MerchantDailyPoint({
    required this.dateKey,
    required this.views,
    required this.calls,
    required this.navs,
    required this.storyViews,
    this.storyToVenueViews = 0,
    this.offerDetailViews = 0,
    this.claimClicks = 0,
    this.claimsCreated = 0,
    this.redemptions = 0,
  });

  int get contactIntent => calls + navs;
}
