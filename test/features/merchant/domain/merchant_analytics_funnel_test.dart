import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';

MerchantDailyPoint _point({
  required String dateKey,
  int views = 0,
  int calls = 0,
  int navs = 0,
  int storyViews = 0,
  int offerDetailViews = 0,
  int claimClicks = 0,
  int claimsCreated = 0,
  int redemptions = 0,
}) {
  return MerchantDailyPoint(
    dateKey: dateKey,
    views: views,
    calls: calls,
    navs: navs,
    storyViews: storyViews,
    offerDetailViews: offerDetailViews,
    claimClicks: claimClicks,
    claimsCreated: claimsCreated,
    redemptions: redemptions,
  );
}

void main() {
  group('Merchant analytics funnel', () {
    test('builds funnel metrics from daily points', () {
      final payload = buildMerchantAnalyticsDrilldownPayload(
        analytics: MerchantAnalytics.empty(),
        currentPoints: [
          _point(
            dateKey: '2026-04-01',
            views: 20,
            calls: 2,
            navs: 1,
            storyViews: 4,
            offerDetailViews: 7,
            claimClicks: 4,
            claimsCreated: 2,
            redemptions: 1,
          ),
          _point(
            dateKey: '2026-04-02',
            views: 15,
            calls: 1,
            navs: 1,
            storyViews: 3,
            offerDetailViews: 5,
            claimClicks: 3,
            claimsCreated: 1,
            redemptions: 1,
          ),
        ],
        previousPoints: [
          _point(
            dateKey: '2026-03-31',
            views: 18,
            calls: 2,
            navs: 1,
            storyViews: 2,
            offerDetailViews: 3,
            claimClicks: 1,
            claimsCreated: 1,
            redemptions: 0,
          ),
        ],
        periodDays: 7,
        offers: const <MerchantOfferAnalyticsSummary>[],
      );

      expect(payload.funnel.views, 35);
      expect(payload.funnel.offerDetailViews, 12);
      expect(payload.funnel.claimClicks, 7);
      expect(payload.funnel.claimsCreated, 3);
      expect(payload.funnel.redemptions, 2);
      expect(payload.funnel.detailToClaimClickRate, closeTo(7 / 12, 0.0001));
      expect(payload.funnel.viewToClaimRate, closeTo(3 / 35, 0.0001));
      expect(payload.funnel.claimToRedemptionRate, closeTo(2 / 3, 0.0001));
    });

    test(
      'reconciles 7-day funnel totals from weekly summary when daily series undercounts',
      () {
        final payload = buildMerchantAnalyticsDrilldownPayload(
          analytics: MerchantAnalytics(
            viewsTotal: 224,
            viewsThisWeek: 17,
            viewsLastWeek: 12,
            callsTotal: 17,
            callsThisWeek: 4,
            callsLastWeek: 3,
            navsTotal: 10,
            navsThisWeek: 2,
            navsLastWeek: 1,
            storyViewsTotal: 54,
            storyViewsThisWeek: 2,
            offerDetailViewsTotal: 2,
            offerDetailViews7d: 2,
            claimClicksTotal: 1,
            claimClicks7d: 1,
            claimsCreatedTotal: 0,
            claimsCreated7d: 0,
            redemptionsTotal: 0,
            redemptions7d: 0,
            contactIntent7d: 6,
            contactIntentPrev7d: 4,
            contactRate7d: 0.3,
            detailToClaimClickRate7d: 0.5,
            viewToClaimRate7d: 0,
            claimToRedemptionRate7d: 0,
            updatedAt: DateTime(2026, 4, 6, 19, 35),
          ),
          currentPoints: [
            _point(
              dateKey: '2026-04-01',
              views: 4,
              calls: 1,
              navs: 0,
              storyViews: 0,
            ),
            _point(
              dateKey: '2026-04-02',
              views: 3,
              calls: 1,
              navs: 0,
              storyViews: 0,
            ),
            _point(
              dateKey: '2026-04-03',
              views: 2,
              calls: 0,
              navs: 1,
              storyViews: 0,
            ),
            _point(
              dateKey: '2026-04-04',
              views: 2,
              calls: 0,
              navs: 0,
              storyViews: 0,
            ),
            _point(
              dateKey: '2026-04-05',
              views: 3,
              calls: 1,
              navs: 0,
              storyViews: 0,
            ),
            _point(
              dateKey: '2026-04-06',
              views: 3,
              calls: 1,
              navs: 1,
              storyViews: 2,
            ),
          ],
          previousPoints: const <MerchantDailyPoint>[],
          periodDays: 7,
          offers: const <MerchantOfferAnalyticsSummary>[],
        );

        expect(payload.funnel.views, 17);
        expect(payload.funnel.offerDetailViews, 2);
        expect(payload.funnel.claimClicks, 1);
        expect(payload.funnel.claimsCreated, 0);
        expect(payload.funnel.redemptions, 0);
        expect(payload.currentPoints.last.offerDetailViews, 2);
        expect(payload.currentPoints.last.claimClicks, 1);
      },
    );

    test(
      'ranks top offers by redemptions then claims then rate then title',
      () {
        final ranked = rankMerchantOfferAnalytics([
          const MerchantOfferAnalyticsSummary(
            offerId: 'offer-b',
            offerTitleAr: 'ب',
            status: MerchantOfferStatus.active,
            detailViews7d: 10,
            claimClicks7d: 5,
            claimsCreated7d: 5,
            redemptions7d: 3,
            claimToRedemptionRate7d: 0.6,
            updatedAt: null,
          ),
          const MerchantOfferAnalyticsSummary(
            offerId: 'offer-a',
            offerTitleAr: 'أ',
            status: MerchantOfferStatus.active,
            detailViews7d: 9,
            claimClicks7d: 5,
            claimsCreated7d: 4,
            redemptions7d: 3,
            claimToRedemptionRate7d: 0.75,
            updatedAt: null,
          ),
          const MerchantOfferAnalyticsSummary(
            offerId: 'offer-c',
            offerTitleAr: 'ج',
            status: MerchantOfferStatus.active,
            detailViews7d: 8,
            claimClicks7d: 4,
            claimsCreated7d: 4,
            redemptions7d: 2,
            claimToRedemptionRate7d: 0.5,
            updatedAt: null,
          ),
        ]);

        expect(ranked.first.offerId, 'offer-b');
        expect(ranked[1].offerId, 'offer-a');
        expect(ranked.last.offerId, 'offer-c');
      },
    );

    test('ranks top offers by the selected period metrics', () {
      final ranked = rankMerchantOfferAnalytics([
        const MerchantOfferAnalyticsSummary(
          offerId: 'offer-a',
          offerTitleAr: 'أ',
          status: MerchantOfferStatus.active,
          detailViews7d: 4,
          detailViews30d: 20,
          claimClicks7d: 2,
          claimClicks30d: 10,
          claimsCreated7d: 1,
          claimsCreated30d: 8,
          redemptions7d: 1,
          redemptions30d: 6,
          claimToRedemptionRate7d: 1,
          claimToRedemptionRate30d: 0.75,
          updatedAt: null,
        ),
        const MerchantOfferAnalyticsSummary(
          offerId: 'offer-b',
          offerTitleAr: 'ب',
          status: MerchantOfferStatus.active,
          detailViews7d: 5,
          detailViews30d: 16,
          claimClicks7d: 3,
          claimClicks30d: 9,
          claimsCreated7d: 2,
          claimsCreated30d: 5,
          redemptions7d: 2,
          redemptions30d: 4,
          claimToRedemptionRate7d: 1,
          claimToRedemptionRate30d: 0.8,
          updatedAt: null,
        ),
      ], periodDays: 30);

      expect(ranked.first.offerId, 'offer-a');
      expect(ranked.last.offerId, 'offer-b');
    });

    test('adds traffic up no conversion insight using explicit thresholds', () {
      final payload = buildMerchantAnalyticsDrilldownPayload(
        analytics: MerchantAnalytics.empty(),
        currentPoints: [
          _point(
            dateKey: '2026-04-01',
            views: 20,
            calls: 1,
            navs: 1,
            storyViews: 2,
            offerDetailViews: 4,
            claimClicks: 2,
            claimsCreated: 1,
            redemptions: 0,
          ),
          _point(
            dateKey: '2026-04-02',
            views: 20,
            calls: 1,
            navs: 1,
            storyViews: 2,
            offerDetailViews: 4,
            claimClicks: 2,
            claimsCreated: 1,
            redemptions: 0,
          ),
        ],
        previousPoints: [
          _point(
            dateKey: '2026-03-30',
            views: 15,
            calls: 1,
            navs: 1,
            storyViews: 1,
            offerDetailViews: 2,
            claimClicks: 1,
            claimsCreated: 0,
            redemptions: 0,
          ),
          _point(
            dateKey: '2026-03-31',
            views: 15,
            calls: 1,
            navs: 1,
            storyViews: 1,
            offerDetailViews: 2,
            claimClicks: 1,
            claimsCreated: 0,
            redemptions: 0,
          ),
        ],
        periodDays: 7,
        offers: const <MerchantOfferAnalyticsSummary>[],
      );

      final insights = buildMerchantFunnelInsights(
        summary: payload.summary,
        funnel: payload.funnel,
        offers: payload.offers,
      );

      expect(
        insights.map((insight) => insight.type),
        contains(MerchantAnalyticsInsightType.trafficUpNoConversion),
      );
    });

    test(
      'adds top offer concentrated insight only when thresholds are met',
      () {
        final insights = buildMerchantFunnelInsights(
          summary: buildMerchantAnalyticsDrilldownPayload(
            analytics: MerchantAnalytics.empty(),
            currentPoints: [
              _point(
                dateKey: '2026-04-01',
                views: 40,
                calls: 2,
                navs: 2,
                storyViews: 5,
                offerDetailViews: 12,
                claimClicks: 6,
                claimsCreated: 5,
                redemptions: 5,
              ),
            ],
            previousPoints: const <MerchantDailyPoint>[],
            periodDays: 7,
            offers: const <MerchantOfferAnalyticsSummary>[
              MerchantOfferAnalyticsSummary(
                offerId: 'offer-1',
                offerTitleAr: 'عرض 1',
                status: MerchantOfferStatus.active,
                detailViews7d: 12,
                claimClicks7d: 6,
                claimsCreated7d: 5,
                redemptions7d: 4,
                claimToRedemptionRate7d: 0.8,
                updatedAt: null,
              ),
              MerchantOfferAnalyticsSummary(
                offerId: 'offer-2',
                offerTitleAr: 'عرض 2',
                status: MerchantOfferStatus.active,
                detailViews7d: 6,
                claimClicks7d: 2,
                claimsCreated7d: 1,
                redemptions7d: 1,
                claimToRedemptionRate7d: 1.0,
                updatedAt: null,
              ),
            ],
          ).summary,
          funnel: const MerchantAnalyticsFunnel(
            views: 40,
            offerDetailViews: 18,
            claimClicks: 8,
            claimsCreated: 6,
            redemptions: 5,
            detailToClaimClickRate: 8 / 18,
            viewToClaimRate: 6 / 40,
            claimToRedemptionRate: 5 / 6,
          ),
          offers: const <MerchantOfferAnalyticsSummary>[
            MerchantOfferAnalyticsSummary(
              offerId: 'offer-1',
              offerTitleAr: 'عرض 1',
              status: MerchantOfferStatus.active,
              detailViews7d: 12,
              claimClicks7d: 6,
              claimsCreated7d: 5,
              redemptions7d: 4,
              claimToRedemptionRate7d: 0.8,
              updatedAt: null,
            ),
            MerchantOfferAnalyticsSummary(
              offerId: 'offer-2',
              offerTitleAr: 'عرض 2',
              status: MerchantOfferStatus.active,
              detailViews7d: 6,
              claimClicks7d: 2,
              claimsCreated7d: 1,
              redemptions7d: 1,
              claimToRedemptionRate7d: 1.0,
              updatedAt: null,
            ),
          ],
        );

        expect(
          insights.map((insight) => insight.type),
          contains(MerchantAnalyticsInsightType.topOfferConcentrated),
        );
      },
    );
  });
}
