import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_action_item.dart';
import 'package:wain_app/features/merchant/domain/services/merchant_action_feed_service.dart';

import 'merchant_dashboard_providers.dart';

final merchantActionFeedProvider = Provider<List<MerchantActionItem>>((ref) {
  final analyticsAsync = ref.watch(merchantAnalyticsProvider);
  final offersAsync = ref.watch(merchantOffersProvider);
  final statsAsync = ref.watch(merchantStatsProvider);

  final waitingForInitialData =
      (analyticsAsync.isLoading && !analyticsAsync.hasValue) ||
      (offersAsync.isLoading && !offersAsync.hasValue) ||
      (statsAsync.isLoading && !statsAsync.hasValue);

  if (waitingForInitialData) {
    return const [];
  }

  final analytics = analyticsAsync.asData?.value ?? MerchantAnalytics.empty();
  final offers = offersAsync.asData?.value ?? const [];
  final stats = statsAsync.asData?.value ?? MerchantStats.empty();

  return const MerchantActionFeedService().buildFeed(
    analytics: analytics,
    offers: offers,
    stats: stats,
    now: DateTime.now(),
  );
});
