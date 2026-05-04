import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';

void main() {
  group('MerchantAnalytics WoW', () {
    test('returns 100% when previous week is zero and current is positive', () {
      const analytics = MerchantAnalytics(
        viewsTotal: 10,
        viewsThisWeek: 4,
        viewsLastWeek: 0,
        callsTotal: 7,
        callsThisWeek: 2,
        callsLastWeek: 0,
        navsTotal: 9,
        navsThisWeek: 3,
        navsLastWeek: 0,
        storyViewsTotal: 0,
        storyViewsThisWeek: 0,
        updatedAt: null,
      );

      expect(analytics.viewsWoW, 100.0);
      expect(analytics.callsWoW, 100.0);
      expect(analytics.navsWoW, 100.0);
    });

    test('returns null when current and previous are both zero', () {
      final analytics = MerchantAnalytics.empty();

      expect(analytics.viewsWoW, isNull);
      expect(analytics.callsWoW, isNull);
      expect(analytics.navsWoW, isNull);
    });

    test('returns signed percentage when previous week exists', () {
      const analytics = MerchantAnalytics(
        viewsTotal: 100,
        viewsThisWeek: 15,
        viewsLastWeek: 30,
        callsTotal: 50,
        callsThisWeek: 18,
        callsLastWeek: 12,
        navsTotal: 80,
        navsThisWeek: 20,
        navsLastWeek: 20,
        storyViewsTotal: 0,
        storyViewsThisWeek: 0,
        updatedAt: null,
      );

      expect(analytics.viewsWoW, -50.0);
      expect(analytics.callsWoW, 50.0);
      expect(analytics.navsWoW, 0.0);
    });

    test('parses updated_at into a typed DateTime', () {
      final updatedAt = DateTime(2026, 4, 3, 10, 30);
      final analytics = MerchantAnalytics(
        viewsTotal: 1,
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
        updatedAt: updatedAt,
      );

      expect(analytics.updatedAt, updatedAt);
    });
  });

  group('Daily analytics compatibility', () {
    test('buildZeroFilledSeries inserts zero points for missing days', () {
      final fetched = <String, MerchantDailyPoint>{
        '2026-02-15': MerchantDailyPoint(
          dateKey: '2026-02-15',
          views: 3,
          calls: 1,
          navs: 0,
          storyViews: 0,
        ),
        '2026-02-17': MerchantDailyPoint(
          dateKey: '2026-02-17',
          views: 8,
          calls: 2,
          navs: 4,
          storyViews: 1,
        ),
      };

      final series = buildZeroFilledSeries(
        rangeDays: 3,
        fetched: fetched,
        today: DateTime(2026, 2, 17),
      );

      expect(series.length, 3);
      expect(series[0].dateKey, '2026-02-15');
      expect(series[1].dateKey, '2026-02-16');
      expect(series[2].dateKey, '2026-02-17');

      expect(series[0].views, 3);
      expect(series[1].views, 0); // zero-filled missing day
      expect(series[2].views, 8);
    });

    test('summary delta handles previous zero safely', () {
      final summary = buildMerchantAnalyticsSummary(
        analytics: MerchantAnalytics.empty(),
        currentPoints: const <MerchantDailyPoint>[
          MerchantDailyPoint(
            dateKey: '2026-02-08',
            views: 7,
            calls: 1,
            navs: 0,
            storyViews: 0,
          ),
        ],
        previousPoints: const <MerchantDailyPoint>[
          MerchantDailyPoint(
            dateKey: '2026-02-01',
            views: 0,
            calls: 0,
            navs: 0,
            storyViews: 0,
          ),
        ],
        periodDays: 7,
      );

      expect(summary.viewsDeltaPercent, 100.0);
    });
  });
}
