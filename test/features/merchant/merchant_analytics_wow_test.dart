import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';

void main() {
  group('MerchantAnalytics WoW', () {
    test('returns 100% when previous week is zero and current is positive', () {
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 10,
        'views_this_week': 4,
        'views_last_week': 0,
        'calls_total': 7,
        'calls_this_week': 2,
        'calls_last_week': 0,
        'navs_total': 9,
        'navs_this_week': 3,
        'navs_last_week': 0,
        'story_views_total': 0,
        'story_views_this_week': 0,
      });

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
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 100,
        'views_this_week': 15,
        'views_last_week': 30, // -50%
        'calls_total': 50,
        'calls_this_week': 18,
        'calls_last_week': 12, // +50%
        'navs_total': 80,
        'navs_this_week': 20,
        'navs_last_week': 20, // 0%
        'story_views_total': 0,
        'story_views_this_week': 0,
      });

      expect(analytics.viewsWoW, -50.0);
      expect(analytics.callsWoW, 50.0);
      expect(analytics.navsWoW, 0.0);
    });
  });

  group('Daily analytics helpers', () {
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

    test('calculateWoWPercent handles previous=0 safely', () {
      expect(calculateWoWPercent(7, 0), 100.0);
      expect(calculateWoWPercent(0, 0), isNull);
    });

    test('calculateDailyWoW compares last 7 days vs previous 7 days', () {
      final points = <MerchantDailyPoint>[
        // Previous 7 days total views = 14
        for (var i = 0; i < 7; i++)
          MerchantDailyPoint(
            dateKey: '2026-02-${(i + 1).toString().padLeft(2, '0')}',
            views: 2,
            calls: 1,
            navs: 0,
            storyViews: 0,
          ),
        // Last 7 days total views = 28 => +100%
        for (var i = 0; i < 7; i++)
          MerchantDailyPoint(
            dateKey: '2026-02-${(i + 8).toString().padLeft(2, '0')}',
            views: 4,
            calls: 1,
            navs: 0,
            storyViews: 0,
          ),
      ];

      final wow = calculateDailyWoW(points, (p) => p.views);
      expect(wow, 100.0);
    });
  });
}
