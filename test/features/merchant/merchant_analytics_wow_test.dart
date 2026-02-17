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
}
