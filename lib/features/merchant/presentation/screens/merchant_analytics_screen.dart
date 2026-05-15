import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_refresh.dart';
import 'package:wain_app/features/merchant/presentation/widgets/analytics/merchant_analytics_page_sections.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_analytics_insights.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_shared.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_invalidation.dart';
import '../providers/merchant_dashboard_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantAnalyticsScreen extends ConsumerWidget {
  const MerchantAnalyticsScreen({super.key});

  Future<void> _refreshAnalyticsData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!ref.read(isOnlineProvider)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      final result = await ref
          .read(merchantDashboardRepositoryProvider)
          .refreshDashboard(debugMode: kDebugMode);

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.dashboardRefreshSuccess(
                '${result.views}',
                '${result.calls}',
                '${result.navs}',
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DashboardRefreshException catch (error) {
      debugPrint(
        'Analytics refresh failed: ${error.type} ${error.debugMessage}',
      );
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(_backfillErrorMessage(l10n, error)),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      debugPrint('Analytics refresh failed: $error');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.dashboardRefreshFailed(error.toString())),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.invalidateMerchantDashboardData();
    }
  }

  String _backfillErrorMessage(
    AppLocalizations l10n,
    DashboardRefreshException error,
  ) {
    switch (error.type) {
      case DashboardRefreshFailureType.appCheckFailed:
        return l10n.inviteAppCheckFailed;
      case DashboardRefreshFailureType.permissionDenied:
        return l10n.dashboardErrorPermission;
      case DashboardRefreshFailureType.missingIndex:
        return l10n.dashboardErrorIndex;
      case DashboardRefreshFailureType.noVenue:
        return l10n.dashboardErrorNoVenue;
      case DashboardRefreshFailureType.unauthenticated:
        return l10n.dashboardErrorUnauthenticated;
      case DashboardRefreshFailureType.unknown:
        return l10n.dashboardRefreshFailed(
          error.debugMessage ?? error.type.name,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final drilldownAsync = ref.watch(merchantAnalyticsDrilldownProvider);
    final drilldownSnapshotAsync = ref.watch(
      merchantAnalyticsDrilldownSnapshotProvider,
    );
    final insightsAsync = ref.watch(merchantAnalyticsPageInsightsProvider);
    final showOfflineEmpty = drilldownSnapshotAsync.maybeWhen(
      data: (snapshot) =>
          !snapshot.hasData &&
          snapshot.isFromCache &&
          snapshot.fetchedAt == null &&
          !ref.read(isOnlineProvider),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.merchantAnalyticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshAnalyticsData(context, ref),
          ),
        ],
      ),
      body: showOfflineEmpty
          ? const OfflineEmptyState(
              title: 'لا توجد نسخة محفوظة لتحليلات الأداء',
              subtitle:
                  'افتح صفحة التحليلات مرة واحدة أثناء الاتصال لحفظ نسخة محلية.',
            )
          : RefreshIndicator(
              onRefresh: () => _refreshAnalyticsData(context, ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding,
                children: [
                  drilldownSnapshotAsync.maybeWhen(
                    data: (snapshot) => OfflineBanner(
                      isVisible: snapshot.isFromCache,
                      fetchedAt: snapshot.fetchedAt,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const MerchantAnalyticsPageHeader(),
                  const SizedBox(height: AppSpacing.xxl),
                  drilldownAsync.when(
                    loading: () => const MerchantDashboardCardShell(
                      child: SizedBox(
                        height: 220,
                        child: Center(child: WainLoadingIndicator()),
                      ),
                    ),
                    error: (_, _) => MerchantDashboardFallbackCard(
                      message: l10n.merchantTrendLoadFailed,
                    ),
                    data: (payload) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MerchantAnalyticsOverviewSection(
                          summary: payload.summary,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        MerchantAnalyticsFunnelSection(funnel: payload.funnel),
                        const SizedBox(height: AppSpacing.xxl),
                        insightsAsync.when(
                          loading: () => const MerchantDashboardCardShell(
                            child: SizedBox(
                              height: 72,
                              child: Center(child: WainLoadingIndicator()),
                            ),
                          ),
                          error: (_, _) => MerchantDashboardFallbackCard(
                            message: l10n.merchantTrendLoadFailed,
                          ),
                          data: (insights) => MerchantAnalyticsInsightsCard(
                            insights: insights,
                            maxItems: 6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        MerchantAnalyticsDemandTrendsSection(
                          summary: payload.summary,
                          points: payload.currentPoints,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        MerchantAnalyticsConversionTrendsSection(
                          funnel: payload.funnel,
                          points: payload.currentPoints,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        MerchantAnalyticsTopOffersSection(
                          offers: payload.offers,
                          periodDays: payload.summary.periodDays,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        MerchantAnalyticsTimelineSection(
                          summary: payload.summary,
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
