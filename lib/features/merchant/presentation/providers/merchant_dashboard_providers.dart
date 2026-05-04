import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/offline/offline_snapshot.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_content_health.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_route_access.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';

export '../../data/repositories/merchant_dashboard_repository.dart'
    show buildZeroFilledSeries;
export '../../domain/entities/merchant_dashboard_metrics.dart';

/// Check if current user is a merchant (has merchant_venue_id).
/// Falls back to Firestore cache offline so the full merchant
/// access chain doesn't break.
final merchantVenueIdSnapshotProvider =
    FutureProvider<OfflineSnapshot<String?>>((ref) async {
      final user = await ref.watch(authStateProvider.future);
      if (user == null) {
        return const OfflineSnapshot<String?>(
          data: null,
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantDashboard,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<String?>(
        cacheKey: 'merchant_venue_id:${user.uid}',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getLinkedVenueId(user.uid, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantDashboard,
      );
    });

final merchantVenueIdProvider = FutureProvider<String?>((ref) async {
  final snapshot = await ref.watch(merchantVenueIdSnapshotProvider.future);
  return snapshot.data;
});

final merchantRouteAccessSnapshotProvider =
    FutureProvider<OfflineSnapshot<MerchantRouteAccess>>((ref) async {
      final user = await ref.watch(authStateProvider.future);
      if (user == null) {
        return const OfflineSnapshot<MerchantRouteAccess>(
          data: MerchantRouteAccess.unauthenticated(),
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantDashboard,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      final repository = ref.read(merchantDashboardRepositoryProvider);

      final venueIdSnapshot = await fetchWithOfflineFallback<String?>(
        cacheKey: 'merchant_venue_id:${user.uid}',
        fetcher: (source) =>
            repository.getLinkedVenueId(user.uid, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantDashboard,
      );
      final venueId = venueIdSnapshot.data?.trim();
      if (venueId == null || venueId.isEmpty) {
        return OfflineSnapshot<MerchantRouteAccess>(
          data: const MerchantRouteAccess.needsInvite(),
          source: venueIdSnapshot.source,
          fetchedAt: venueIdSnapshot.fetchedAt,
          staleDuration: venueIdSnapshot.staleDuration,
        );
      }

      final existsSnapshot = await fetchWithOfflineFallback<bool>(
        cacheKey: 'merchant_venue_exists:$venueId',
        fetcher: (source) => repository.venueExists(venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantDashboard,
      );
      if (existsSnapshot.data != true) {
        return OfflineSnapshot<MerchantRouteAccess>(
          data: MerchantRouteAccess.brokenVenueLink(venueId: venueId),
          source: existsSnapshot.source,
          fetchedAt: existsSnapshot.fetchedAt,
          staleDuration: existsSnapshot.staleDuration,
        );
      }

      return OfflineSnapshot<MerchantRouteAccess>(
        data: MerchantRouteAccess.ready(venueId),
        source: existsSnapshot.source,
        fetchedAt: existsSnapshot.fetchedAt,
        staleDuration: existsSnapshot.staleDuration,
      );
    });

/// Merchant route access status derived from auth state and venue linkage.
/// Uses Source parameter for offline-safe reads.
final merchantRouteAccessProvider = FutureProvider<MerchantRouteAccess>((
  ref,
) async {
  final snapshot = await ref.watch(merchantRouteAccessSnapshotProvider.future);
  return snapshot.data ?? const MerchantRouteAccess.unauthenticated();
});

/// Get the merchant's venue data
final merchantVenueSnapshotProvider =
    FutureProvider<OfflineSnapshot<MerchantVenue?>>((ref) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return const OfflineSnapshot<MerchantVenue?>(
          data: null,
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantDashboard,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<MerchantVenue?>(
        cacheKey: 'merchant_venue:$venueId',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getVenue(venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantDashboard,
      );
    });

final merchantVenueProvider = FutureProvider<MerchantVenue?>((ref) async {
  final snapshot = await ref.watch(merchantVenueSnapshotProvider.future);
  return snapshot.data;
});

/// Get merchant venue stats (reviews, rating)
final merchantStatsSnapshotProvider =
    FutureProvider<OfflineSnapshot<MerchantStats>>((ref) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return OfflineSnapshot<MerchantStats>(
          data: MerchantStats.empty(),
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantDashboard,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<MerchantStats>(
        cacheKey: 'merchant_stats:$venueId',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getStats(venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantDashboard,
      );
    });

final merchantStatsProvider = FutureProvider<MerchantStats>((ref) async {
  final snapshot = await ref.watch(merchantStatsSnapshotProvider.future);
  return snapshot.data ?? MerchantStats.empty();
});

/// Get all merchant reviews (for management screen)
final merchantReviewsSnapshotProvider =
    FutureProvider<OfflineSnapshot<List<MerchantReview>>>((ref) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return const OfflineSnapshot<List<MerchantReview>>(
          data: <MerchantReview>[],
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantData,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<List<MerchantReview>>(
        cacheKey: 'merchant_reviews:$venueId',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getReviews(venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantData,
      );
    });

final merchantReviewsProvider = FutureProvider<List<MerchantReview>>((
  ref,
) async {
  final snapshot = await ref.watch(merchantReviewsSnapshotProvider.future);
  return snapshot.data ?? [];
});

/// Get merchant's offers
final merchantOffersSnapshotProvider =
    FutureProvider<OfflineSnapshot<List<MerchantOffer>>>((ref) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return const OfflineSnapshot<List<MerchantOffer>>(
          data: <MerchantOffer>[],
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantData,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<List<MerchantOffer>>(
        cacheKey: 'merchant_offers:$venueId',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getOffers(venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantData,
      );
    });

final merchantOffersProvider = FutureProvider<List<MerchantOffer>>((ref) async {
  final snapshot = await ref.watch(merchantOffersSnapshotProvider.future);
  return snapshot.data ?? [];
});

/// Analytics data from server-aggregated venue_analytics collection
final merchantAnalyticsSnapshotProvider =
    FutureProvider<OfflineSnapshot<MerchantAnalytics>>((ref) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return OfflineSnapshot<MerchantAnalytics>(
          data: MerchantAnalytics.empty(),
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantAnalytics,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<MerchantAnalytics>(
        cacheKey: 'merchant_analytics:$venueId',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getAnalytics(venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantAnalytics,
      );
    });

final merchantAnalyticsProvider = FutureProvider<MerchantAnalytics>((
  ref,
) async {
  final snapshot = await ref.watch(merchantAnalyticsSnapshotProvider.future);
  return snapshot.data ?? MerchantAnalytics.empty();
});

/// Selected range for the dashboard analytics (7 or 30 days).
final dashboardTrendRangeDaysProvider =
    NotifierProvider<DashboardTrendRangeDaysNotifier, int>(
      DashboardTrendRangeDaysNotifier.new,
    );

/// Selected range for the analytics detail page (7 or 30 days).
final merchantAnalyticsPageRangeDaysProvider =
    NotifierProvider<MerchantAnalyticsPageRangeDaysNotifier, int>(
      MerchantAnalyticsPageRangeDaysNotifier.new,
    );

/// Backward-compatible alias for dashboard range state.
final trendRangeDaysProvider = dashboardTrendRangeDaysProvider;

class DashboardTrendRangeDaysNotifier extends Notifier<int> {
  @override
  int build() => 7;

  void setRange(int days) {
    state = days == 30 ? 30 : 7;
  }
}

class MerchantAnalyticsPageRangeDaysNotifier extends Notifier<int> {
  @override
  int build() => 7;

  void setRange(int days) {
    state = days == 30 ? 30 : 7;
  }
}

/// Daily analytics points for dashboard charts.
/// Reads from: venue_analytics_daily/{venueId}/days/{dateKey}
/// Returns a contiguous series with zero-filled gaps.
final merchantAnalyticsDailyProvider =
    FutureProvider.family<List<MerchantDailyPoint>, int>((
      ref,
      rangeDays,
    ) async {
      final snapshot = await ref.watch(
        merchantAnalyticsDailySnapshotProvider(rangeDays).future,
      );
      return snapshot.data ?? [];
    });

final merchantAnalyticsDailySnapshotProvider =
    FutureProvider.family<OfflineSnapshot<List<MerchantDailyPoint>>, int>((
      ref,
      rangeDays,
    ) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return const OfflineSnapshot<List<MerchantDailyPoint>>(
          data: <MerchantDailyPoint>[],
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantAnalytics,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<List<MerchantDailyPoint>>(
        cacheKey: 'merchant_daily:$venueId:$rangeDays',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getAnalyticsDaily(
              venueId: venueId,
              rangeDays: rangeDays,
              source: source,
            ),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantAnalytics,
      );
    });

final merchantOfferAnalyticsSnapshotProvider =
    FutureProvider<OfflineSnapshot<List<MerchantOfferAnalyticsSummary>>>((
      ref,
    ) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      if (venueId == null) {
        return const OfflineSnapshot<List<MerchantOfferAnalyticsSummary>>(
          data: <MerchantOfferAnalyticsSummary>[],
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantAnalytics,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<List<MerchantOfferAnalyticsSummary>>(
        cacheKey: 'merchant_offer_analytics:$venueId',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getOfferAnalytics(venueId: venueId, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantAnalytics,
      );
    });

final merchantOfferAnalyticsProvider =
    FutureProvider<List<MerchantOfferAnalyticsSummary>>((ref) async {
      final rangeDays = ref.watch(dashboardTrendRangeDaysProvider);
      final snapshot = await ref.watch(
        merchantOfferAnalyticsSnapshotProvider.future,
      );
      final offers = snapshot.data ?? const <MerchantOfferAnalyticsSummary>[];
      return rankMerchantOfferAnalytics(offers, periodDays: rangeDays);
    });

final _merchantAnalyticsSummaryByRangeProvider =
    FutureProvider.family<MerchantAnalyticsSummary, int>((
      ref,
      rangeDays,
    ) async {
      final analytics = await ref.watch(merchantAnalyticsProvider.future);
      final normalizedPeriodDays = rangeDays == 30 ? 30 : 7;
      final comparisonPoints = await ref.watch(
        merchantAnalyticsDailyProvider(normalizedPeriodDays * 2).future,
      );

      final currentPoints = comparisonPoints.length <= normalizedPeriodDays
          ? comparisonPoints
          : comparisonPoints.sublist(
              comparisonPoints.length - normalizedPeriodDays,
            );
      final previousPoints = comparisonPoints.length <= normalizedPeriodDays
          ? const <MerchantDailyPoint>[]
          : comparisonPoints.sublist(
              0,
              comparisonPoints.length - normalizedPeriodDays,
            );

      return buildMerchantAnalyticsSummary(
        analytics: analytics,
        currentPoints: currentPoints,
        previousPoints: previousPoints,
        periodDays: normalizedPeriodDays,
      );
    });

final _merchantAnalyticsDrilldownSnapshotByRangeProvider =
    FutureProvider.family<
      OfflineSnapshot<MerchantAnalyticsDrilldownPayload>,
      int
    >((ref, rangeDays) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      final normalizedPeriodDays = rangeDays == 30 ? 30 : 7;
      if (venueId == null) {
        return OfflineSnapshot<MerchantAnalyticsDrilldownPayload>(
          data: buildMerchantAnalyticsDrilldownPayload(
            analytics: MerchantAnalytics.empty(),
            currentPoints: const <MerchantDailyPoint>[],
            previousPoints: const <MerchantDailyPoint>[],
            periodDays: normalizedPeriodDays,
            offers: const <MerchantOfferAnalyticsSummary>[],
          ),
          source: OfflineDataSource.server,
          fetchedAt: null,
          staleDuration: OfflineStaleDurations.merchantAnalytics,
        );
      }

      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<MerchantAnalyticsDrilldownPayload>(
        cacheKey: 'merchant_drilldown:$venueId:$normalizedPeriodDays',
        fetcher: (source) => ref
            .read(merchantDashboardRepositoryProvider)
            .getAnalyticsDrilldown(
              venueId: venueId,
              periodDays: normalizedPeriodDays,
              source: source,
            ),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.merchantAnalytics,
      );
    });

final _merchantAnalyticsDrilldownByRangeProvider =
    FutureProvider.family<MerchantAnalyticsDrilldownPayload, int>((
      ref,
      rangeDays,
    ) async {
      final snapshot = await ref.watch(
        _merchantAnalyticsDrilldownSnapshotByRangeProvider(rangeDays).future,
      );
      final normalizedPeriodDays = rangeDays == 30 ? 30 : 7;
      return snapshot.data ??
          buildMerchantAnalyticsDrilldownPayload(
            analytics: MerchantAnalytics.empty(),
            currentPoints: const <MerchantDailyPoint>[],
            previousPoints: const <MerchantDailyPoint>[],
            periodDays: normalizedPeriodDays,
            offers: const <MerchantOfferAnalyticsSummary>[],
          );
    });

final _merchantAnalyticsBaseInsightsByRangeProvider =
    FutureProvider.family<List<MerchantAnalyticsInsight>, int>((
      ref,
      rangeDays,
    ) async {
      final summary = await ref.watch(
        _merchantAnalyticsSummaryByRangeProvider(rangeDays).future,
      );
      return buildMerchantAnalyticsInsights(summary, maxItems: 0);
    });

List<MerchantAnalyticsInsight> _mergeInsights(
  List<MerchantAnalyticsInsight> base,
  List<MerchantAnalyticsInsight> funnel,
) {
  final merged = <MerchantAnalyticsInsight>[...base, ...funnel];
  merged.sort((left, right) => right.priority.compareTo(left.priority));
  final deduped = <MerchantAnalyticsInsight>[];
  final seenTypes = <MerchantAnalyticsInsightType>{};

  for (final insight in merged) {
    if (seenTypes.add(insight.type)) {
      deduped.add(insight);
    }
  }

  return deduped;
}

final merchantActiveMenuSummaryProvider =
    FutureProvider<MerchantActiveMenuSummary>((ref) async {
      final venueId = await ref.watch(merchantVenueIdProvider.future);
      final venue = await ref.watch(merchantVenueProvider.future);
      if (venueId == null || venue == null) {
        return const MerchantActiveMenuSummary(
          hasActiveMenu: false,
          publishedAt: null,
        );
      }

      final activeVersionId = venue.activeMenuVersionId?.trim();
      if (activeVersionId == null || activeVersionId.isEmpty) {
        return const MerchantActiveMenuSummary(
          hasActiveMenu: false,
          publishedAt: null,
        );
      }

      try {
        final summary = await ref
            .read(menuRepositoryProvider)
            .getMenuVersionSummaryById(
              venueId: venueId,
              versionId: activeVersionId,
            );

        return MerchantActiveMenuSummary(
          hasActiveMenu: true,
          publishedAt: summary?.publishedAt?.toDate(),
        );
      } catch (e) {
        debugPrint('❌ Error fetching merchant active menu summary: $e');
        return const MerchantActiveMenuSummary(
          hasActiveMenu: true,
          publishedAt: null,
        );
      }
    });

final merchantAnalyticsSummaryProvider =
    FutureProvider<MerchantAnalyticsSummary>((ref) async {
      final periodDays = ref.watch(dashboardTrendRangeDaysProvider);
      return ref.watch(
        _merchantAnalyticsSummaryByRangeProvider(periodDays).future,
      );
    });

final merchantAnalyticsInsightsProvider =
    FutureProvider<List<MerchantAnalyticsInsight>>((ref) async {
      final base = await ref.watch(
        merchantAnalyticsBaseInsightsProvider.future,
      );
      final funnel = await ref.watch(
        merchantAnalyticsFunnelInsightsProvider.future,
      );
      return _mergeInsights(base, funnel);
    });

final merchantAnalyticsBaseInsightsProvider =
    FutureProvider<List<MerchantAnalyticsInsight>>((ref) async {
      final rangeDays = ref.watch(dashboardTrendRangeDaysProvider);
      return ref.watch(
        _merchantAnalyticsBaseInsightsByRangeProvider(rangeDays).future,
      );
    });

final merchantAnalyticsFunnelInsightsProvider =
    FutureProvider<List<MerchantAnalyticsInsight>>((ref) async {
      final drilldown = await ref.watch(
        merchantDashboardAnalyticsDrilldownProvider.future,
      );
      return buildMerchantFunnelInsights(
        summary: drilldown.summary,
        funnel: drilldown.funnel,
        offers: drilldown.offers,
      );
    });

final merchantDashboardAnalyticsDrilldownProvider =
    FutureProvider<MerchantAnalyticsDrilldownPayload>((ref) async {
      final rangeDays = ref.watch(dashboardTrendRangeDaysProvider);
      return ref.watch(
        _merchantAnalyticsDrilldownByRangeProvider(rangeDays).future,
      );
    });

final merchantDashboardAnalyticsDrilldownSnapshotProvider =
    FutureProvider<OfflineSnapshot<MerchantAnalyticsDrilldownPayload>>((
      ref,
    ) async {
      final rangeDays = ref.watch(dashboardTrendRangeDaysProvider);
      return ref.watch(
        _merchantAnalyticsDrilldownSnapshotByRangeProvider(rangeDays).future,
      );
    });

final merchantAnalyticsDrilldownProvider =
    FutureProvider<MerchantAnalyticsDrilldownPayload>((ref) async {
      final rangeDays = ref.watch(merchantAnalyticsPageRangeDaysProvider);
      return ref.watch(
        _merchantAnalyticsDrilldownByRangeProvider(rangeDays).future,
      );
    });

final merchantAnalyticsDrilldownSnapshotProvider =
    FutureProvider<OfflineSnapshot<MerchantAnalyticsDrilldownPayload>>((
      ref,
    ) async {
      final rangeDays = ref.watch(merchantAnalyticsPageRangeDaysProvider);
      return ref.watch(
        _merchantAnalyticsDrilldownSnapshotByRangeProvider(rangeDays).future,
      );
    });

final merchantAnalyticsPageInsightsProvider =
    FutureProvider<List<MerchantAnalyticsInsight>>((ref) async {
      final rangeDays = ref.watch(merchantAnalyticsPageRangeDaysProvider);
      final base = await ref.watch(
        _merchantAnalyticsBaseInsightsByRangeProvider(rangeDays).future,
      );
      final drilldown = await ref.watch(
        merchantAnalyticsDrilldownProvider.future,
      );
      final funnel = buildMerchantFunnelInsights(
        summary: drilldown.summary,
        funnel: drilldown.funnel,
        offers: drilldown.offers,
      );
      return _mergeInsights(base, funnel);
    });

final merchantHasActiveStoryProvider = FutureProvider<bool>((ref) async {
  final venueId = await ref.watch(merchantVenueIdProvider.future);
  if (venueId == null) {
    return false;
  }

  try {
    return await ref
        .read(merchantStoriesRepositoryProvider)
        .hasActiveStory(venueId: venueId);
  } catch (e) {
    debugPrint('❌ Error checking merchant active story: $e');
    return false;
  }
});

final merchantContentHealthProvider = FutureProvider<MerchantContentHealth>((
  ref,
) async {
  final venue = await ref.watch(merchantVenueProvider.future);
  if (venue == null) {
    return const MerchantContentHealth.empty();
  }

  final menuSummary = await ref.watch(merchantActiveMenuSummaryProvider.future);
  final hasActiveStory = await ref.watch(merchantHasActiveStoryProvider.future);

  return buildMerchantContentHealth(
    hasActiveMenu: menuSummary.hasActiveMenu,
    menuPublishedAt: menuSummary.publishedAt,
    photoCount: venue.photos.length,
    hasActiveStory: hasActiveStory,
    lastStoryAt: venue.lastStoryAt,
    is24Hours: venue.is24Hours,
    validHoursDays: _countValidHoursDays(venue.hours),
    hasName: venue.nameAr.trim().isNotEmpty || venue.nameEn.trim().isNotEmpty,
    hasCity: venue.city.trim().isNotEmpty,
    hasPhone: venue.phone.trim().isNotEmpty,
    hasCategory: venue.categories.isNotEmpty,
    hasPhoto: venue.photos.isNotEmpty,
  );
});

int _countValidHoursDays(Map<String, List<MerchantVenueHoursSlot>> rawHours) {
  var validDays = 0;
  for (final entry in rawHours.entries) {
    final hasValidShift = entry.value.any((shift) {
      return shift.open.trim().isNotEmpty && shift.close.trim().isNotEmpty;
    });
    if (hasValidShift) {
      validDays += 1;
    }
  }

  return validDays;
}
