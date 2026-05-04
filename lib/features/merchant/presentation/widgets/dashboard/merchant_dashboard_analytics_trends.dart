import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/presentation/widgets/analytics/merchant_analytics_primitives.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../../providers/merchant_dashboard_providers.dart';
import 'merchant_dashboard_analytics_insights.dart';
import 'merchant_dashboard_shared.dart';

class MerchantDashboardTrendsSection extends ConsumerWidget {
  final bool showSectionTitle;

  const MerchantDashboardTrendsSection({
    super.key,
    this.showSectionTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rangeDays = ref.watch(dashboardTrendRangeDaysProvider);
    final summaryAsync = ref.watch(merchantAnalyticsSummaryProvider);
    final dailyAsync = ref.watch(merchantAnalyticsDailyProvider(rangeDays));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSectionTitle) ...[
          MerchantDashboardSectionTitle(title: l10n.merchantTrends),
          const SizedBox(height: AppSpacing.md),
        ],
        const MerchantDashboardAnalyticsInsightsCard(),
        const SizedBox(height: AppSpacing.md),
        dailyAsync.when(
          loading: () => const MerchantDashboardCardShell(
            child: SizedBox(
              height: 160,
              child: Center(child: WainLoadingIndicator()),
            ),
          ),
          error: (_, _) => MerchantDashboardFallbackCard(
            message: l10n.merchantTrendLoadFailed,
          ),
          data: (points) {
            final hasActivity = points.any(
              (point) =>
                  point.views > 0 ||
                  point.calls > 0 ||
                  point.navs > 0 ||
                  point.storyViews > 0,
            );
            if (!hasActivity) {
              return MerchantDashboardFallbackCard(
                message: l10n.merchantNoTrendData,
              );
            }

            return summaryAsync.when(
              loading: () => const MerchantDashboardCardShell(
                child: SizedBox(
                  height: 120,
                  child: Center(child: WainLoadingIndicator()),
                ),
              ),
              error: (_, _) => MerchantDashboardFallbackCard(
                message: l10n.merchantTrendLoadFailed,
              ),
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MerchantAnalyticsTrendCard(
                    title: l10n.merchantViews,
                    values: points.map((point) => point.views).toList(),
                    total: summary.views,
                    averagePerDay: summary.avgDailyViews,
                    deltaPercent: summary.viewsDeltaPercent,
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MerchantAnalyticsTrendCard(
                    title: l10n.merchantAnalyticsContactIntent,
                    values: points.map((point) => point.contactIntent).toList(),
                    total: summary.contactIntent,
                    averagePerDay: summary.avgDailyContactIntent,
                    deltaPercent: summary.contactIntentDeltaPercent,
                    accent: AppTheme.successColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MerchantAnalyticsTrendCard(
                    title: l10n.merchantStoryViews,
                    values: points.map((point) => point.storyViews).toList(),
                    total: summary.storyViews,
                    averagePerDay: summary.avgDailyStoryViews,
                    deltaPercent: summary.storyViewsDeltaPercent,
                    accent: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      MerchantAnalyticsDayBadge(
                        label: l10n.merchantAnalyticsBestDayLabel,
                        point: summary.bestDay,
                        accent: AppTheme.successColor,
                      ),
                      MerchantAnalyticsDayBadge(
                        label: l10n.merchantAnalyticsWorstDayLabel,
                        point: summary.worstDay,
                        accent: AppTheme.warningColor,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
