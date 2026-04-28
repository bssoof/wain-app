import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';

import 'merchant_dashboard_providers.dart';

extension MerchantProvidersInvalidation on WidgetRef {
  void invalidateMerchantDashboardData() {
    invalidate(merchantVenueProvider);
    invalidate(merchantVenueSnapshotProvider);
    invalidate(merchantStatsProvider);
    invalidate(merchantStatsSnapshotProvider);
    invalidate(merchantOffersProvider);
    invalidate(merchantOffersSnapshotProvider);
    invalidate(merchantAnalyticsProvider);
    invalidate(merchantAnalyticsSnapshotProvider);
    invalidate(merchantAnalyticsDailyProvider(30));
    invalidate(merchantAnalyticsDailyProvider(7));
    invalidate(merchantAnalyticsDailySnapshotProvider(30));
    invalidate(merchantAnalyticsDailySnapshotProvider(7));
    invalidate(merchantOfferAnalyticsProvider);
    invalidate(merchantOfferAnalyticsSnapshotProvider);
    invalidate(merchantDashboardAnalyticsDrilldownProvider);
    invalidate(merchantDashboardAnalyticsDrilldownSnapshotProvider);
    invalidate(merchantAnalyticsDrilldownProvider);
    invalidate(merchantAnalyticsDrilldownSnapshotProvider);
    invalidate(merchantAnalyticsBaseInsightsProvider);
    invalidate(merchantAnalyticsFunnelInsightsProvider);
    invalidate(merchantAnalyticsInsightsProvider);
    invalidate(merchantAnalyticsPageInsightsProvider);
    invalidate(userNotificationsProvider);
    invalidate(unreadNotificationsCountProvider);
  }

  void invalidateMerchantAccessState() {
    invalidate(merchantRouteAccessProvider);
    invalidate(merchantRouteAccessSnapshotProvider);
    invalidate(merchantVenueIdProvider);
    invalidate(merchantVenueIdSnapshotProvider);
  }

  void invalidateMerchantContentData() {
    invalidate(merchantVenueProvider);
    invalidate(merchantActiveMenuSummaryProvider);
    invalidate(merchantHasActiveStoryProvider);
    invalidate(merchantContentHealthProvider);
  }

  void invalidateMerchantAllData() {
    invalidateMerchantAccessState();
    invalidateMerchantDashboardData();
    invalidateMerchantContentData();
  }
}
