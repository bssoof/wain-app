import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_analytics_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  testWidgets('renders full analytics drilldown sections', (tester) async {
    final payload = buildMerchantAnalyticsDrilldownPayload(
      analytics: MerchantAnalytics(
        viewsTotal: 300,
        viewsThisWeek: 84,
        viewsLastWeek: 42,
        callsTotal: 60,
        callsThisWeek: 15,
        callsLastWeek: 5,
        navsTotal: 44,
        navsThisWeek: 7,
        navsLastWeek: 2,
        storyViewsTotal: 70,
        storyViewsThisWeek: 29,
        updatedAt: DateTime.now(),
      ),
      currentPoints: const <MerchantDailyPoint>[
        MerchantDailyPoint(
          dateKey: '2026-04-01',
          views: 12,
          calls: 2,
          navs: 1,
          storyViews: 3,
          offerDetailViews: 5,
          claimClicks: 3,
          claimsCreated: 2,
          redemptions: 1,
        ),
        MerchantDailyPoint(
          dateKey: '2026-04-02',
          views: 14,
          calls: 3,
          navs: 1,
          storyViews: 4,
          offerDetailViews: 6,
          claimClicks: 3,
          claimsCreated: 2,
          redemptions: 2,
        ),
      ],
      previousPoints: const <MerchantDailyPoint>[
        MerchantDailyPoint(
          dateKey: '2026-03-30',
          views: 10,
          calls: 1,
          navs: 1,
          storyViews: 2,
          offerDetailViews: 2,
          claimClicks: 1,
          claimsCreated: 0,
          redemptions: 0,
        ),
      ],
      periodDays: 7,
      offers: const <MerchantOfferAnalyticsSummary>[
        MerchantOfferAnalyticsSummary(
          offerId: 'offer-1',
          offerTitleAr: 'عرض القهوة',
          status: MerchantOfferStatus.active,
          detailViews7d: 18,
          claimClicks7d: 9,
          claimsCreated7d: 5,
          redemptions7d: 4,
          claimToRedemptionRate7d: 0.8,
          updatedAt: null,
        ),
      ],
    );
    final insights = <MerchantAnalyticsInsight>[
      ...buildMerchantAnalyticsInsights(payload.summary, maxItems: 0),
      ...buildMerchantFunnelInsights(
        summary: payload.summary,
        funnel: payload.funnel,
        offers: payload.offers,
      ),
    ]..sort((left, right) => right.priority.compareTo(left.priority));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantAnalyticsDrilldownProvider.overrideWith(
            (ref) async => payload,
          ),
          merchantAnalyticsPageInsightsProvider.overrideWith(
            (ref) async => insights,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MerchantAnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تحليلات تفصيلية'), findsOneWidget);
    expect(find.text('نظرة عامة'), findsOneWidget);
    expect(find.text('فَنِل التحويل'), findsOneWidget);
    expect(find.text('اتجاهات الطلب'), findsOneWidget);
    expect(find.text('اتجاهات التحويل'), findsOneWidget);
    expect(find.text('أفضل العروض'), findsOneWidget);
    expect(find.text('التسلسل الزمني'), findsOneWidget);
    expect(find.text('عرض القهوة'), findsOneWidget);
  });

  testWidgets('uses selected period values in top offers section', (
    tester,
  ) async {
    final payload = buildMerchantAnalyticsDrilldownPayload(
      analytics: MerchantAnalytics.empty(),
      currentPoints: const <MerchantDailyPoint>[
        MerchantDailyPoint(
          dateKey: '2026-04-01',
          views: 10,
          calls: 0,
          navs: 0,
          storyViews: 0,
          offerDetailViews: 2,
          claimsCreated: 1,
          redemptions: 1,
        ),
      ],
      previousPoints: const <MerchantDailyPoint>[
        MerchantDailyPoint(
          dateKey: '2026-03-31',
          views: 5,
          calls: 0,
          navs: 0,
          storyViews: 0,
        ),
      ],
      periodDays: 30,
      offers: const <MerchantOfferAnalyticsSummary>[
        MerchantOfferAnalyticsSummary(
          offerId: 'offer-1',
          offerTitleAr: 'عرض 30 يوم',
          status: MerchantOfferStatus.active,
          detailViews7d: 2,
          detailViews30d: 9,
          claimClicks7d: 1,
          claimClicks30d: 6,
          claimsCreated7d: 1,
          claimsCreated30d: 4,
          redemptions7d: 1,
          redemptions30d: 3,
          claimToRedemptionRate7d: 1,
          claimToRedemptionRate30d: 0.75,
          updatedAt: null,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantAnalyticsDrilldownProvider.overrideWith(
            (ref) async => payload,
          ),
          merchantAnalyticsPageInsightsProvider.overrideWith(
            (ref) async => const <MerchantAnalyticsInsight>[],
          ),
          merchantAnalyticsPageRangeDaysProvider.overrideWith(
            () => _FixedRangeNotifier(30),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MerchantAnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عرض 30 يوم'), findsOneWidget);
    expect(find.text('3 استفادة'), findsOneWidget);
    expect(find.text('4 مطالبة'), findsOneWidget);
    expect(find.text('75% معدل الاستفادة'), findsOneWidget);
  });
}

class _FixedRangeNotifier extends MerchantAnalyticsPageRangeDaysNotifier {
  final int _range;

  _FixedRangeNotifier(this._range);

  @override
  int build() => _range;
}
