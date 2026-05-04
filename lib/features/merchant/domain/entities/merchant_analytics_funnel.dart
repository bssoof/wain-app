import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';

enum MerchantAnalyticsFunnelStepType {
  views,
  offerDetailViews,
  claimClicks,
  claimsCreated,
  redemptions,
}

class MerchantAnalyticsFunnelStep {
  final MerchantAnalyticsFunnelStepType type;
  final int value;

  const MerchantAnalyticsFunnelStep({required this.type, required this.value});
}

class MerchantAnalyticsFunnel {
  final int views;
  final int offerDetailViews;
  final int claimClicks;
  final int claimsCreated;
  final int redemptions;
  final double detailToClaimClickRate;
  final double viewToClaimRate;
  final double claimToRedemptionRate;

  const MerchantAnalyticsFunnel({
    required this.views,
    required this.offerDetailViews,
    required this.claimClicks,
    required this.claimsCreated,
    required this.redemptions,
    required this.detailToClaimClickRate,
    required this.viewToClaimRate,
    required this.claimToRedemptionRate,
  });

  const MerchantAnalyticsFunnel.empty()
    : views = 0,
      offerDetailViews = 0,
      claimClicks = 0,
      claimsCreated = 0,
      redemptions = 0,
      detailToClaimClickRate = 0,
      viewToClaimRate = 0,
      claimToRedemptionRate = 0;

  bool get hasAnyActivity =>
      views > 0 ||
      offerDetailViews > 0 ||
      claimClicks > 0 ||
      claimsCreated > 0 ||
      redemptions > 0;

  List<MerchantAnalyticsFunnelStep> get steps => [
    MerchantAnalyticsFunnelStep(
      type: MerchantAnalyticsFunnelStepType.views,
      value: views,
    ),
    MerchantAnalyticsFunnelStep(
      type: MerchantAnalyticsFunnelStepType.offerDetailViews,
      value: offerDetailViews,
    ),
    MerchantAnalyticsFunnelStep(
      type: MerchantAnalyticsFunnelStepType.claimClicks,
      value: claimClicks,
    ),
    MerchantAnalyticsFunnelStep(
      type: MerchantAnalyticsFunnelStepType.claimsCreated,
      value: claimsCreated,
    ),
    MerchantAnalyticsFunnelStep(
      type: MerchantAnalyticsFunnelStepType.redemptions,
      value: redemptions,
    ),
  ];
}

class MerchantOfferAnalyticsSummary {
  final String offerId;
  final String offerTitleAr;
  final MerchantOfferStatus? status;
  final int detailViews7d;
  final int detailViews30d;
  final int claimClicks7d;
  final int claimClicks30d;
  final int claimsCreated7d;
  final int claimsCreated30d;
  final int redemptions7d;
  final int redemptions30d;
  final double claimToRedemptionRate7d;
  final double claimToRedemptionRate30d;
  final DateTime? updatedAt;

  const MerchantOfferAnalyticsSummary({
    required this.offerId,
    required this.offerTitleAr,
    required this.status,
    required this.detailViews7d,
    this.detailViews30d = 0,
    required this.claimClicks7d,
    this.claimClicks30d = 0,
    required this.claimsCreated7d,
    this.claimsCreated30d = 0,
    required this.redemptions7d,
    this.redemptions30d = 0,
    required this.claimToRedemptionRate7d,
    this.claimToRedemptionRate30d = 0,
    required this.updatedAt,
  });

  const MerchantOfferAnalyticsSummary.empty({
    required this.offerId,
    required this.offerTitleAr,
  }) : status = null,
       detailViews7d = 0,
       detailViews30d = 0,
       claimClicks7d = 0,
       claimClicks30d = 0,
       claimsCreated7d = 0,
       claimsCreated30d = 0,
       redemptions7d = 0,
       redemptions30d = 0,
       claimToRedemptionRate7d = 0,
       claimToRedemptionRate30d = 0,
       updatedAt = null;

  bool get hasActivity =>
      detailViews7d > 0 ||
      detailViews30d > 0 ||
      claimClicks7d > 0 ||
      claimClicks30d > 0 ||
      claimsCreated7d > 0 ||
      claimsCreated30d > 0 ||
      redemptions7d > 0 ||
      redemptions30d > 0;

  String get sortTitle {
    final trimmed = offerTitleAr.trim();
    return trimmed.isEmpty ? offerId : trimmed;
  }

  int detailViewsForPeriod(int periodDays) =>
      periodDays == 30 ? detailViews30d : detailViews7d;

  int claimClicksForPeriod(int periodDays) =>
      periodDays == 30 ? claimClicks30d : claimClicks7d;

  int claimsCreatedForPeriod(int periodDays) =>
      periodDays == 30 ? claimsCreated30d : claimsCreated7d;

  int redemptionsForPeriod(int periodDays) =>
      periodDays == 30 ? redemptions30d : redemptions7d;

  double claimToRedemptionRateForPeriod(int periodDays) =>
      periodDays == 30 ? claimToRedemptionRate30d : claimToRedemptionRate7d;

  bool hasActivityForPeriod(int periodDays) =>
      detailViewsForPeriod(periodDays) > 0 ||
      claimClicksForPeriod(periodDays) > 0 ||
      claimsCreatedForPeriod(periodDays) > 0 ||
      redemptionsForPeriod(periodDays) > 0;
}

class MerchantAnalyticsDrilldownPayload {
  final MerchantAnalyticsSummary summary;
  final MerchantAnalyticsFunnel funnel;
  final List<MerchantDailyPoint> currentPoints;
  final List<MerchantOfferAnalyticsSummary> offers;

  const MerchantAnalyticsDrilldownPayload({
    required this.summary,
    required this.funnel,
    required this.currentPoints,
    required this.offers,
  });
}

MerchantAnalyticsFunnel buildMerchantAnalyticsFunnel({
  required MerchantAnalytics analytics,
  required MerchantAnalyticsSummary summary,
  required List<MerchantDailyPoint> currentPoints,
  required List<MerchantDailyPoint> previousPoints,
  required int periodDays,
}) {
  final normalizedPeriodDays = periodDays <= 0 ? 7 : periodDays;
  final pointOfferDetailViews = _sumMetric(
    currentPoints,
    (point) => point.offerDetailViews,
  );
  final pointClaimClicks = _sumMetric(
    currentPoints,
    (point) => point.claimClicks,
  );
  final pointClaimsCreated = _sumMetric(
    currentPoints,
    (point) => point.claimsCreated,
  );
  final pointRedemptions = _sumMetric(
    currentPoints,
    (point) => point.redemptions,
  );

  final useWeeklySummaryFallback =
      normalizedPeriodDays == 7 &&
      (analytics.offerDetailViews7d > pointOfferDetailViews ||
          analytics.claimClicks7d > pointClaimClicks ||
          analytics.claimsCreated7d > pointClaimsCreated ||
          analytics.redemptions7d > pointRedemptions);

  final offerDetailViews = useWeeklySummaryFallback
      ? analytics.offerDetailViews7d
      : pointOfferDetailViews;
  final claimClicks = useWeeklySummaryFallback
      ? analytics.claimClicks7d
      : pointClaimClicks;
  final claimsCreated = useWeeklySummaryFallback
      ? analytics.claimsCreated7d
      : pointClaimsCreated;
  final redemptions = useWeeklySummaryFallback
      ? analytics.redemptions7d
      : pointRedemptions;

  return MerchantAnalyticsFunnel(
    views: summary.views,
    offerDetailViews: offerDetailViews,
    claimClicks: claimClicks,
    claimsCreated: claimsCreated,
    redemptions: redemptions,
    detailToClaimClickRate: _safeRate(claimClicks, offerDetailViews),
    viewToClaimRate: _safeRate(claimsCreated, summary.views),
    claimToRedemptionRate: _safeRate(redemptions, claimsCreated),
  );
}

List<MerchantOfferAnalyticsSummary> rankMerchantOfferAnalytics(
  List<MerchantOfferAnalyticsSummary> offers, {
  int periodDays = 7,
}) {
  final normalizedPeriodDays = periodDays == 30 ? 30 : 7;
  final sorted = List<MerchantOfferAnalyticsSummary>.from(offers);
  sorted.sort((left, right) {
    final redemptionOrder = right
        .redemptionsForPeriod(normalizedPeriodDays)
        .compareTo(left.redemptionsForPeriod(normalizedPeriodDays));
    if (redemptionOrder != 0) {
      return redemptionOrder;
    }
    final claimsOrder = right
        .claimsCreatedForPeriod(normalizedPeriodDays)
        .compareTo(left.claimsCreatedForPeriod(normalizedPeriodDays));
    if (claimsOrder != 0) {
      return claimsOrder;
    }
    final rateOrder = right
        .claimToRedemptionRateForPeriod(normalizedPeriodDays)
        .compareTo(left.claimToRedemptionRateForPeriod(normalizedPeriodDays));
    if (rateOrder != 0) {
      return rateOrder;
    }
    return left.sortTitle.toLowerCase().compareTo(
      right.sortTitle.toLowerCase(),
    );
  });
  return sorted;
}

MerchantAnalyticsDrilldownPayload buildMerchantAnalyticsDrilldownPayload({
  required MerchantAnalytics analytics,
  required List<MerchantDailyPoint> currentPoints,
  required List<MerchantDailyPoint> previousPoints,
  required int periodDays,
  required List<MerchantOfferAnalyticsSummary> offers,
  DateTime? now,
}) {
  final normalizedCurrentPoints = _reconcileCurrentPointsWithWeeklySummary(
    analytics: analytics,
    currentPoints: currentPoints,
    periodDays: periodDays,
  );
  final summary = buildMerchantAnalyticsSummary(
    analytics: analytics,
    currentPoints: normalizedCurrentPoints,
    previousPoints: previousPoints,
    periodDays: periodDays,
    now: now,
  );
  final rankedOffers = rankMerchantOfferAnalytics(
    offers,
    periodDays: periodDays,
  );
  final funnel = buildMerchantAnalyticsFunnel(
    analytics: analytics,
    summary: summary,
    currentPoints: normalizedCurrentPoints,
    previousPoints: previousPoints,
    periodDays: periodDays,
  );

  return MerchantAnalyticsDrilldownPayload(
    summary: summary,
    funnel: funnel,
    currentPoints: normalizedCurrentPoints,
    offers: rankedOffers,
  );
}

List<MerchantAnalyticsInsight> buildMerchantFunnelInsights({
  required MerchantAnalyticsSummary summary,
  required MerchantAnalyticsFunnel funnel,
  required List<MerchantOfferAnalyticsSummary> offers,
}) {
  final insights = <MerchantAnalyticsInsight>[];
  final viewsDelta = summary.viewsDeltaPercent ?? 0;
  final contactIntentDelta = summary.contactIntentDeltaPercent ?? 0;
  final storyViewsDelta = summary.storyViewsDeltaPercent ?? 0;

  if (summary.views >= 30 && viewsDelta >= 20 && funnel.claimsCreated < 3) {
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.trafficUpNoConversion,
        severity: MerchantAnalyticsInsightSeverity.warning,
        priority: 130,
        deltaPercent: viewsDelta,
        integerValue: funnel.claimsCreated,
      ),
    );
  }

  if (summary.previousContactIntent >= 5 && contactIntentDelta <= -20) {
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.contactDrop,
        severity: contactIntentDelta <= -40
            ? MerchantAnalyticsInsightSeverity.critical
            : MerchantAnalyticsInsightSeverity.warning,
        priority: 120,
        deltaPercent: contactIntentDelta.abs(),
      ),
    );
  }

  if (funnel.claimsCreated >= 3 && funnel.claimToRedemptionRate < 0.40) {
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.offerInterestNoRedemption,
        severity: MerchantAnalyticsInsightSeverity.warning,
        priority: 110,
        ratePercent: funnel.claimToRedemptionRate * 100,
        integerValue: funnel.claimsCreated,
      ),
    );
  }

  if (summary.views < 5 &&
      summary.contactIntent < 5 &&
      funnel.offerDetailViews < 5 &&
      funnel.claimsCreated == 0 &&
      funnel.redemptions == 0) {
    insights.add(
      const MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.quietPeriod,
        severity: MerchantAnalyticsInsightSeverity.warning,
        priority: 90,
      ),
    );
  }

  final activeOffers = offers
      .where((offer) => offer.redemptionsForPeriod(summary.periodDays) > 0)
      .toList();
  final totalRedemptions = activeOffers.fold<int>(
    0,
    (total, offer) => total + offer.redemptionsForPeriod(summary.periodDays),
  );
  if (totalRedemptions >= 5 && activeOffers.isNotEmpty) {
    final topOffer = rankMerchantOfferAnalytics(
      activeOffers,
      periodDays: summary.periodDays,
    ).first;
    final topShare = _safeRate(
      topOffer.redemptionsForPeriod(summary.periodDays),
      totalRedemptions,
    );
    if (topShare > 0.60) {
      insights.add(
        MerchantAnalyticsInsight(
          type: MerchantAnalyticsInsightType.topOfferConcentrated,
          severity: MerchantAnalyticsInsightSeverity.neutral,
          priority: 80,
          ratePercent: topShare * 100,
          integerValue: topOffer.redemptionsForPeriod(summary.periodDays),
        ),
      );
    }
  }

  if (summary.storyViews >= 5 && storyViewsDelta >= 25 && viewsDelta >= 10) {
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.storyLift,
        severity: MerchantAnalyticsInsightSeverity.positive,
        priority: 70,
        deltaPercent: storyViewsDelta,
        ratePercent: summary.storyViewShare * 100,
      ),
    );
  }

  insights.sort((left, right) => right.priority.compareTo(left.priority));
  return insights;
}

int _sumMetric(
  List<MerchantDailyPoint> points,
  int Function(MerchantDailyPoint point) selector,
) {
  var total = 0;
  for (final point in points) {
    total += selector(point);
  }
  return total;
}

double _safeRate(int numerator, int denominator) {
  if (denominator <= 0) {
    return 0;
  }
  return numerator / denominator;
}

List<MerchantDailyPoint> _reconcileCurrentPointsWithWeeklySummary({
  required MerchantAnalytics analytics,
  required List<MerchantDailyPoint> currentPoints,
  required int periodDays,
}) {
  if (periodDays != 7 || currentPoints.isEmpty) {
    return currentPoints;
  }

  final detailViewsDelta =
      analytics.offerDetailViews7d -
      _sumMetric(currentPoints, (point) => point.offerDetailViews);
  final claimClicksDelta =
      analytics.claimClicks7d -
      _sumMetric(currentPoints, (point) => point.claimClicks);
  final claimsCreatedDelta =
      analytics.claimsCreated7d -
      _sumMetric(currentPoints, (point) => point.claimsCreated);
  final redemptionsDelta =
      analytics.redemptions7d -
      _sumMetric(currentPoints, (point) => point.redemptions);

  if (detailViewsDelta <= 0 &&
      claimClicksDelta <= 0 &&
      claimsCreatedDelta <= 0 &&
      redemptionsDelta <= 0) {
    return currentPoints;
  }

  final normalized = List<MerchantDailyPoint>.from(currentPoints);
  final latestPoint = normalized.removeLast();
  normalized.add(
    MerchantDailyPoint(
      dateKey: latestPoint.dateKey,
      views: latestPoint.views,
      calls: latestPoint.calls,
      navs: latestPoint.navs,
      storyViews: latestPoint.storyViews,
      offerDetailViews:
          latestPoint.offerDetailViews +
          (detailViewsDelta > 0 ? detailViewsDelta : 0),
      claimClicks:
          latestPoint.claimClicks +
          (claimClicksDelta > 0 ? claimClicksDelta : 0),
      claimsCreated:
          latestPoint.claimsCreated +
          (claimsCreatedDelta > 0 ? claimsCreatedDelta : 0),
      redemptions:
          latestPoint.redemptions +
          (redemptionsDelta > 0 ? redemptionsDelta : 0),
    ),
  );

  return normalized;
}
