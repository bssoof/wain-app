import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';

MerchantDailyPoint _point({
  required String dateKey,
  int views = 0,
  int calls = 0,
  int navs = 0,
  int storyViews = 0,
}) {
  return MerchantDailyPoint(
    dateKey: dateKey,
    views: views,
    calls: calls,
    navs: navs,
    storyViews: storyViews,
  );
}

void main() {
  group('Merchant analytics summary', () {
    test('builds period totals, rates, and day highlights', () {
      final summary = buildMerchantAnalyticsSummary(
        analytics: MerchantAnalytics(
          viewsTotal: 300,
          viewsThisWeek: 0,
          viewsLastWeek: 0,
          callsTotal: 40,
          callsThisWeek: 0,
          callsLastWeek: 0,
          navsTotal: 30,
          navsThisWeek: 0,
          navsLastWeek: 0,
          storyViewsTotal: 50,
          storyViewsThisWeek: 0,
          updatedAt: DateTime(2026, 4, 5, 12),
        ),
        currentPoints: [
          _point(
            dateKey: '2026-03-30',
            views: 40,
            calls: 6,
            navs: 4,
            storyViews: 12,
          ),
          _point(
            dateKey: '2026-03-31',
            views: 30,
            calls: 2,
            navs: 1,
            storyViews: 4,
          ),
        ],
        previousPoints: [
          _point(
            dateKey: '2026-03-28',
            views: 20,
            calls: 2,
            navs: 1,
            storyViews: 2,
          ),
          _point(
            dateKey: '2026-03-29',
            views: 25,
            calls: 1,
            navs: 1,
            storyViews: 1,
          ),
        ],
        periodDays: 7,
        now: DateTime(2026, 4, 5, 18),
      );

      expect(summary.views, 70);
      expect(summary.previousViews, 45);
      expect(summary.contactIntent, 13);
      expect(summary.previousContactIntent, 5);
      expect(summary.contactRate, closeTo(13 / 70, 0.0001));
      expect(summary.storyViewShare, closeTo(16 / 70, 0.0001));
      expect(summary.avgDailyStoryViews, closeTo(16 / 7, 0.0001));
      expect(summary.bestDay?.dateKey, '2026-03-30');
      expect(summary.worstDay?.dateKey, '2026-03-31');
      expect(summary.viewsTrend, MerchantTrendDirection.rising);
      expect(summary.isStale, isFalse);
      expect(summary.hasRecentData, isTrue);
    });

    test(
      'adds no recent data and stale insights when current period is empty',
      () {
        final summary = buildMerchantAnalyticsSummary(
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
            updatedAt: DateTime(2026, 4, 1),
          ),
          currentPoints: [
            _point(dateKey: '2026-03-30'),
            _point(dateKey: '2026-03-31'),
          ],
          previousPoints: [
            _point(dateKey: '2026-03-28'),
            _point(dateKey: '2026-03-29'),
          ],
          periodDays: 7,
          now: DateTime(2026, 4, 5),
        );

        final insights = buildMerchantAnalyticsInsights(summary);

        expect(
          insights.map((insight) => insight.type),
          contains(MerchantAnalyticsInsightType.noRecentData),
        );
        expect(
          insights.map((insight) => insight.type),
          contains(MerchantAnalyticsInsightType.dataStale),
        );
      },
    );

    test('suppresses contact rate insights when sample size is too low', () {
      final summary = buildMerchantAnalyticsSummary(
        analytics: MerchantAnalytics.empty(),
        currentPoints: [
          _point(
            dateKey: '2026-03-30',
            views: 20,
            calls: 4,
            navs: 2,
            storyViews: 0,
          ),
        ],
        previousPoints: [
          _point(dateKey: '2026-03-29', views: 18, calls: 3, navs: 1),
        ],
        periodDays: 7,
        now: DateTime(2026, 4, 5),
      );

      final insights = buildMerchantAnalyticsInsights(summary);

      expect(
        insights.where(
          (insight) =>
              insight.type == MerchantAnalyticsInsightType.highContactRate ||
              insight.type == MerchantAnalyticsInsightType.lowContactRate,
        ),
        isEmpty,
      );
    });

    test('marks critical decline when views drop beyond threshold', () {
      final summary = buildMerchantAnalyticsSummary(
        analytics: MerchantAnalytics.empty(),
        currentPoints: [
          _point(dateKey: '2026-03-30', views: 40, calls: 2, navs: 1),
        ],
        previousPoints: [
          _point(dateKey: '2026-03-29', views: 80, calls: 4, navs: 3),
        ],
        periodDays: 7,
        now: DateTime(2026, 4, 5),
      );

      final insights = buildMerchantAnalyticsInsights(summary);
      final declineInsight = insights.firstWhere(
        (insight) => insight.type == MerchantAnalyticsInsightType.viewsDown,
      );

      expect(summary.viewsTrend, MerchantTrendDirection.criticalDecline);
      expect(
        declineInsight.severity,
        MerchantAnalyticsInsightSeverity.critical,
      );
      expect(declineInsight.deltaPercent, closeTo(50, 0.001));
    });

    test('exposes contact intent as a typed daily point getter', () {
      const point = MerchantDailyPoint(
        dateKey: '2026-04-05',
        views: 10,
        calls: 3,
        navs: 2,
        storyViews: 1,
      );

      expect(point.contactIntent, 5);
    });

    test(
      'uses weekly fallback for contact intent when daily points are empty',
      () {
        final summary = buildMerchantAnalyticsSummary(
          analytics: MerchantAnalytics(
            viewsTotal: 100,
            viewsThisWeek: 20,
            viewsLastWeek: 10,
            callsTotal: 10,
            callsThisWeek: 3,
            callsLastWeek: 2,
            navsTotal: 8,
            navsThisWeek: 2,
            navsLastWeek: 1,
            storyViewsTotal: 30,
            storyViewsThisWeek: 6,
            contactIntent7d: 5,
            contactIntentPrev7d: 3,
            updatedAt: DateTime(2026, 4, 5, 10),
          ),
          currentPoints: const <MerchantDailyPoint>[],
          previousPoints: const <MerchantDailyPoint>[],
          periodDays: 7,
          now: DateTime(2026, 4, 5, 12),
        );

        expect(summary.views, 20);
        expect(summary.contactIntent, 5);
        expect(summary.previousContactIntent, 3);
        expect(summary.contactRate, closeTo(0.25, 0.0001));
      },
    );
  });
}
