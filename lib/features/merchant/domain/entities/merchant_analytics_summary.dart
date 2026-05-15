import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';

enum MerchantTrendDirection { rising, stable, declining, criticalDecline }

enum MerchantAnalyticsInsightSeverity { positive, neutral, warning, critical }

enum MerchantAnalyticsInsightType {
  viewsUp,
  viewsDown,
  highContactRate,
  lowContactRate,
  storyBoost,
  stableConsistentPerformance,
  dataStale,
  noRecentData,
  trafficUpNoConversion,
  contactDrop,
  offerInterestNoRedemption,
  quietPeriod,
  topOfferConcentrated,
  storyLift,
}

class MerchantAnalyticsInsight {
  final MerchantAnalyticsInsightType type;
  final MerchantAnalyticsInsightSeverity severity;
  final int priority;
  final double? deltaPercent;
  final double? ratePercent;
  final int? integerValue;

  const MerchantAnalyticsInsight({
    required this.type,
    required this.severity,
    required this.priority,
    this.deltaPercent,
    this.ratePercent,
    this.integerValue,
  });
}

class MerchantAnalyticsSummary {
  final int periodDays;
  final DateTime? updatedAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? previousPeriodStart;
  final DateTime? previousPeriodEnd;
  final int views;
  final int previousViews;
  final int calls;
  final int previousCalls;
  final int navs;
  final int previousNavs;
  final int storyViews;
  final int previousStoryViews;
  final int storyToVenueViews;
  final int previousStoryToVenueViews;
  final int contactIntent;
  final int previousContactIntent;
  final double contactRate;
  final double previousContactRate;
  final double callRate;
  final double navRate;
  final double storyViewShare;
  final double? storyToVenueConversionRate;
  final double avgDailyViews;
  final double avgDailyCalls;
  final double avgDailyNavs;
  final double avgDailyStoryViews;
  final double avgDailyStoryToVenueViews;
  final double avgDailyContactIntent;
  final MerchantDailyPoint? bestDay;
  final MerchantDailyPoint? worstDay;
  final MerchantTrendDirection viewsTrend;
  final MerchantTrendDirection callsTrend;
  final MerchantTrendDirection navsTrend;
  final MerchantTrendDirection storyViewsTrend;
  final MerchantTrendDirection contactIntentTrend;
  final bool hasRecentData;
  final bool isStale;

  const MerchantAnalyticsSummary({
    required this.periodDays,
    required this.updatedAt,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.previousPeriodStart,
    required this.previousPeriodEnd,
    required this.views,
    required this.previousViews,
    required this.calls,
    required this.previousCalls,
    required this.navs,
    required this.previousNavs,
    required this.storyViews,
    required this.previousStoryViews,
    this.storyToVenueViews = 0,
    this.previousStoryToVenueViews = 0,
    required this.contactIntent,
    required this.previousContactIntent,
    required this.contactRate,
    required this.previousContactRate,
    required this.callRate,
    required this.navRate,
    required this.storyViewShare,
    this.storyToVenueConversionRate,
    required this.avgDailyViews,
    required this.avgDailyCalls,
    required this.avgDailyNavs,
    required this.avgDailyStoryViews,
    this.avgDailyStoryToVenueViews = 0,
    required this.avgDailyContactIntent,
    required this.bestDay,
    required this.worstDay,
    required this.viewsTrend,
    required this.callsTrend,
    required this.navsTrend,
    required this.storyViewsTrend,
    required this.contactIntentTrend,
    required this.hasRecentData,
    required this.isStale,
  });

  double? get viewsDeltaPercent => _deltaPercent(views, previousViews);
  double? get callsDeltaPercent => _deltaPercent(calls, previousCalls);
  double? get navsDeltaPercent => _deltaPercent(navs, previousNavs);
  double? get storyViewsDeltaPercent =>
      _deltaPercent(storyViews, previousStoryViews);
  double? get storyToVenueViewsDeltaPercent =>
      _deltaPercent(storyToVenueViews, previousStoryToVenueViews);
  double? get contactIntentDeltaPercent =>
      _deltaPercent(contactIntent, previousContactIntent);

  bool get hasEnoughViewsForRateInsights => views >= 30;
  bool get hasEnoughContactIntentForInsights => contactIntent >= 5;
}

MerchantAnalyticsSummary buildMerchantAnalyticsSummary({
  required MerchantAnalytics analytics,
  required List<MerchantDailyPoint> currentPoints,
  required List<MerchantDailyPoint> previousPoints,
  required int periodDays,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final normalizedPeriodDays = periodDays <= 0 ? 7 : periodDays;

  final useWeeklyFallback =
      normalizedPeriodDays == 7 &&
      !_hasAnyActivity(currentPoints) &&
      !_hasAnyActivity(previousPoints) &&
      (analytics.viewsThisWeek > 0 ||
          analytics.callsThisWeek > 0 ||
          analytics.navsThisWeek > 0 ||
          analytics.storyViewsThisWeek > 0 ||
          analytics.storyToVenueViewsThisWeek > 0 ||
          analytics.viewsLastWeek > 0 ||
          analytics.callsLastWeek > 0 ||
          analytics.navsLastWeek > 0);

  final views = useWeeklyFallback
      ? analytics.viewsThisWeek
      : _sum(currentPoints, (point) => point.views);
  final previousViews = useWeeklyFallback
      ? analytics.viewsLastWeek
      : _sum(previousPoints, (point) => point.views);
  final calls = useWeeklyFallback
      ? analytics.callsThisWeek
      : _sum(currentPoints, (point) => point.calls);
  final previousCalls = useWeeklyFallback
      ? analytics.callsLastWeek
      : _sum(previousPoints, (point) => point.calls);
  final navs = useWeeklyFallback
      ? analytics.navsThisWeek
      : _sum(currentPoints, (point) => point.navs);
  final previousNavs = useWeeklyFallback
      ? analytics.navsLastWeek
      : _sum(previousPoints, (point) => point.navs);
  final storyViewsDaily = _sum(currentPoints, (point) => point.storyViews);
  final storyViews = useWeeklyFallback
      ? analytics.storyViewsThisWeek
      : _withSevenDayAggregateFallback(
          dailyValue: storyViewsDaily,
          periodDays: normalizedPeriodDays,
          aggregate7d: analytics.storyViewsThisWeek,
        );
  final previousStoryViews = useWeeklyFallback
      ? 0
      : _sum(previousPoints, (point) => point.storyViews);
  final storyToVenueViewsDaily = _sum(
    currentPoints,
    (point) => point.storyToVenueViews,
  );
  final storyToVenueViews = useWeeklyFallback
      ? analytics.storyToVenueViewsThisWeek
      : _withSevenDayAggregateFallback(
          dailyValue: storyToVenueViewsDaily,
          periodDays: normalizedPeriodDays,
          aggregate7d: analytics.storyToVenueViews7d > 0
              ? analytics.storyToVenueViews7d
              : analytics.storyToVenueViewsThisWeek,
        );
  final previousStoryToVenueViews = useWeeklyFallback
      ? 0
      : _sum(previousPoints, (point) => point.storyToVenueViews);
  final contactIntent = useWeeklyFallback
      ? analytics.contactIntent7d
      : _sum(currentPoints, (point) => point.contactIntent);
  final previousContactIntent = useWeeklyFallback
      ? analytics.contactIntentPrev7d
      : _sum(previousPoints, (point) => point.contactIntent);

  final bestDay = _selectBestDay(currentPoints);
  final worstDay = _selectWorstDay(currentPoints);

  return MerchantAnalyticsSummary(
    periodDays: normalizedPeriodDays,
    updatedAt: analytics.updatedAt,
    currentPeriodStart: _parseDateKey(
      currentPoints.isEmpty ? null : currentPoints.first.dateKey,
    ),
    currentPeriodEnd: _parseDateKey(
      currentPoints.isEmpty ? null : currentPoints.last.dateKey,
    ),
    previousPeriodStart: _parseDateKey(
      previousPoints.isEmpty ? null : previousPoints.first.dateKey,
    ),
    previousPeriodEnd: _parseDateKey(
      previousPoints.isEmpty ? null : previousPoints.last.dateKey,
    ),
    views: views,
    previousViews: previousViews,
    calls: calls,
    previousCalls: previousCalls,
    navs: navs,
    previousNavs: previousNavs,
    storyViews: storyViews,
    previousStoryViews: previousStoryViews,
    storyToVenueViews: storyToVenueViews,
    previousStoryToVenueViews: previousStoryToVenueViews,
    contactIntent: contactIntent,
    previousContactIntent: previousContactIntent,
    contactRate: _safeRate(contactIntent, views),
    previousContactRate: _safeRate(previousContactIntent, previousViews),
    callRate: _safeRate(calls, views),
    navRate: _safeRate(navs, views),
    storyViewShare: _safeRate(storyViews, views),
    storyToVenueConversionRate: _nullableRate(storyToVenueViews, storyViews),
    avgDailyViews: _average(views, normalizedPeriodDays),
    avgDailyCalls: _average(calls, normalizedPeriodDays),
    avgDailyNavs: _average(navs, normalizedPeriodDays),
    avgDailyStoryViews: _average(storyViews, normalizedPeriodDays),
    avgDailyStoryToVenueViews: _average(
      storyToVenueViews,
      normalizedPeriodDays,
    ),
    avgDailyContactIntent: _average(contactIntent, normalizedPeriodDays),
    bestDay: bestDay,
    worstDay: worstDay,
    viewsTrend: _classifyTrend(views, previousViews),
    callsTrend: _classifyTrend(calls, previousCalls),
    navsTrend: _classifyTrend(navs, previousNavs),
    storyViewsTrend: _classifyTrend(storyViews, previousStoryViews),
    contactIntentTrend: _classifyTrend(contactIntent, previousContactIntent),
    hasRecentData: useWeeklyFallback || _hasAnyActivity(currentPoints),
    isStale: analytics.isStaleAt(effectiveNow),
  );
}

List<MerchantAnalyticsInsight> buildMerchantAnalyticsInsights(
  MerchantAnalyticsSummary summary, {
  int maxItems = 3,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final insights = <MerchantAnalyticsInsight>[];

  if (!summary.hasRecentData) {
    insights.add(
      const MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.noRecentData,
        severity: MerchantAnalyticsInsightSeverity.warning,
        priority: 120,
      ),
    );
  }

  if (summary.isStale) {
    final staleHours = summary.updatedAt == null
        ? 0
        : effectiveNow.difference(summary.updatedAt!).inHours;
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.dataStale,
        severity: MerchantAnalyticsInsightSeverity.warning,
        priority: 110,
        integerValue: staleHours,
      ),
    );
  }

  final viewsDelta = summary.viewsDeltaPercent;
  if (_canEvaluateVolume(summary.views, summary.previousViews) &&
      viewsDelta != null) {
    if (summary.viewsTrend == MerchantTrendDirection.criticalDecline ||
        summary.viewsTrend == MerchantTrendDirection.declining) {
      insights.add(
        MerchantAnalyticsInsight(
          type: MerchantAnalyticsInsightType.viewsDown,
          severity: summary.viewsTrend == MerchantTrendDirection.criticalDecline
              ? MerchantAnalyticsInsightSeverity.critical
              : MerchantAnalyticsInsightSeverity.warning,
          priority: summary.viewsTrend == MerchantTrendDirection.criticalDecline
              ? 100
              : 80,
          deltaPercent: viewsDelta.abs(),
        ),
      );
    } else if (summary.viewsTrend == MerchantTrendDirection.rising) {
      insights.add(
        MerchantAnalyticsInsight(
          type: MerchantAnalyticsInsightType.viewsUp,
          severity: MerchantAnalyticsInsightSeverity.positive,
          priority: 70,
          deltaPercent: viewsDelta,
        ),
      );
    }
  }

  if (summary.hasEnoughViewsForRateInsights &&
      summary.hasEnoughContactIntentForInsights) {
    if (summary.contactRate >= 0.15) {
      insights.add(
        MerchantAnalyticsInsight(
          type: MerchantAnalyticsInsightType.highContactRate,
          severity: MerchantAnalyticsInsightSeverity.positive,
          priority: 65,
          ratePercent: summary.contactRate * 100,
        ),
      );
    } else if (summary.contactRate <= 0.05) {
      insights.add(
        MerchantAnalyticsInsight(
          type: MerchantAnalyticsInsightType.lowContactRate,
          severity: MerchantAnalyticsInsightSeverity.warning,
          priority: 75,
          ratePercent: summary.contactRate * 100,
        ),
      );
    }
  }

  if (summary.hasEnoughViewsForRateInsights &&
      summary.storyViews > 0 &&
      summary.storyViewShare >= 0.25) {
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.storyBoost,
        severity: MerchantAnalyticsInsightSeverity.positive,
        priority: 55,
        ratePercent: summary.storyViewShare * 100,
      ),
    );
  }

  if (summary.hasRecentData &&
      summary.viewsTrend == MerchantTrendDirection.stable &&
      summary.contactIntentTrend == MerchantTrendDirection.stable &&
      summary.contactIntent >= 5) {
    insights.add(
      MerchantAnalyticsInsight(
        type: MerchantAnalyticsInsightType.stableConsistentPerformance,
        severity: MerchantAnalyticsInsightSeverity.neutral,
        priority: 40,
        ratePercent: summary.contactRate * 100,
      ),
    );
  }

  insights.sort((left, right) => right.priority.compareTo(left.priority));
  if (maxItems <= 0 || insights.length <= maxItems) {
    return insights;
  }
  return insights.sublist(0, maxItems);
}

int _sum(
  List<MerchantDailyPoint> points,
  int Function(MerchantDailyPoint point) selector,
) {
  var total = 0;
  for (final point in points) {
    total += selector(point);
  }
  return total;
}

int _withSevenDayAggregateFallback({
  required int dailyValue,
  required int periodDays,
  required int aggregate7d,
}) {
  if (dailyValue > 0 || periodDays != 7) {
    return dailyValue;
  }
  return aggregate7d;
}

bool _hasAnyActivity(List<MerchantDailyPoint> points) {
  for (final point in points) {
    if (point.views > 0 ||
        point.calls > 0 ||
        point.navs > 0 ||
        point.storyViews > 0 ||
        point.storyToVenueViews > 0) {
      return true;
    }
  }
  return false;
}

double _safeRate(int numerator, int denominator) {
  if (denominator <= 0) {
    return 0.0;
  }
  return numerator / denominator;
}

double? _nullableRate(int numerator, int denominator) {
  if (denominator <= 0) {
    return null;
  }
  return numerator / denominator;
}

double _average(int total, int days) {
  if (days <= 0) {
    return 0.0;
  }
  return total / days;
}

double? _deltaPercent(int current, int previous) {
  if (previous == 0) {
    return current > 0 ? 100.0 : null;
  }
  return ((current - previous) / previous) * 100;
}

MerchantTrendDirection _classifyTrend(int current, int previous) {
  final delta = _deltaPercent(current, previous);
  if (delta == null) {
    return MerchantTrendDirection.stable;
  }
  if (delta < -25) {
    return MerchantTrendDirection.criticalDecline;
  }
  if (delta < -10) {
    return MerchantTrendDirection.declining;
  }
  if (delta > 10) {
    return MerchantTrendDirection.rising;
  }
  return MerchantTrendDirection.stable;
}

bool _canEvaluateVolume(int current, int previous) {
  return current >= 30 || previous >= 30;
}

MerchantDailyPoint? _selectBestDay(List<MerchantDailyPoint> points) {
  if (!_hasAnyActivity(points)) {
    return null;
  }
  return points.reduce((left, right) {
    if (left.views != right.views) {
      return left.views >= right.views ? left : right;
    }
    final leftContact = left.contactIntent;
    final rightContact = right.contactIntent;
    return leftContact >= rightContact ? left : right;
  });
}

MerchantDailyPoint? _selectWorstDay(List<MerchantDailyPoint> points) {
  if (!_hasAnyActivity(points)) {
    return null;
  }
  return points.reduce((left, right) {
    if (left.views != right.views) {
      return left.views <= right.views ? left : right;
    }
    final leftContact = left.contactIntent;
    final rightContact = right.contactIntent;
    return leftContact <= rightContact ? left : right;
  });
}

DateTime? _parseDateKey(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
