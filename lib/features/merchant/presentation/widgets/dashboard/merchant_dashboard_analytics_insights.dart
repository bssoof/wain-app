import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../../providers/merchant_dashboard_providers.dart';
import 'merchant_dashboard_shared.dart';

class MerchantDashboardAnalyticsInsightsCard extends ConsumerWidget {
  const MerchantDashboardAnalyticsInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final insightsAsync = ref.watch(merchantAnalyticsInsightsProvider);

    return insightsAsync.when(
      loading: () => const MerchantDashboardCardShell(
        child: SizedBox(
          height: 72,
          child: Center(child: WainLoadingIndicator()),
        ),
      ),
      error: (_, _) =>
          MerchantDashboardFallbackCard(message: l10n.merchantTrendLoadFailed),
      data: (insights) =>
          MerchantAnalyticsInsightsCard(insights: insights, maxItems: 3),
    );
  }
}

class MerchantAnalyticsInsightsCard extends StatelessWidget {
  final List<MerchantAnalyticsInsight> insights;
  final int maxItems;

  const MerchantAnalyticsInsightsCard({
    super.key,
    required this.insights,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleInsights = maxItems > 0 && insights.length > maxItems
        ? insights.sublist(0, maxItems)
        : insights;

    return MerchantDashboardCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.merchantAnalyticsInsights,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibleInsights.isEmpty)
            Text(
              l10n.merchantAnalyticsNoInsights,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: [
                for (
                  var index = 0;
                  index < visibleInsights.length;
                  index++
                ) ...[
                  MerchantAnalyticsInsightTile(insight: visibleInsights[index]),
                  if (index != visibleInsights.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class MerchantAnalyticsInsightTile extends StatelessWidget {
  final MerchantAnalyticsInsight insight;

  const MerchantAnalyticsInsightTile({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final copy = resolveMerchantAnalyticsInsightCopy(context, insight);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: copy.tone.withAlpha(14),
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: copy.tone.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(copy.icon, color: copy.tone),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: copy.tone),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(copy.body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResolvedMerchantAnalyticsInsightCopy {
  final String title;
  final String body;
  final IconData icon;
  final Color tone;

  const ResolvedMerchantAnalyticsInsightCopy({
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
  });
}

ResolvedMerchantAnalyticsInsightCopy resolveMerchantAnalyticsInsightCopy(
  BuildContext context,
  MerchantAnalyticsInsight insight,
) {
  final l10n = AppLocalizations.of(context)!;

  switch (insight.type) {
    case MerchantAnalyticsInsightType.viewsUp:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsViewsUpTitle,
        body: l10n.merchantAnalyticsViewsUpBody(
          _formatPercentValue(insight.deltaPercent),
        ),
        icon: Icons.trending_up_rounded,
        tone: AppTheme.successColor,
      );
    case MerchantAnalyticsInsightType.viewsDown:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsViewsDownTitle,
        body: l10n.merchantAnalyticsViewsDownBody(
          _formatPercentValue(insight.deltaPercent),
        ),
        icon: Icons.trending_down_rounded,
        tone: insight.severity == MerchantAnalyticsInsightSeverity.critical
            ? AppTheme.errorColor
            : AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.highContactRate:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsHighContactRateTitle,
        body: l10n.merchantAnalyticsHighContactRateBody(
          _formatPercentValue(insight.ratePercent),
        ),
        icon: Icons.phone_in_talk_rounded,
        tone: AppTheme.successColor,
      );
    case MerchantAnalyticsInsightType.lowContactRate:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsLowContactRateTitle,
        body: l10n.merchantAnalyticsLowContactRateBody(
          _formatPercentValue(insight.ratePercent),
        ),
        icon: Icons.phone_disabled_rounded,
        tone: AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.storyBoost:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsStoryBoostTitle,
        body: l10n.merchantAnalyticsStoryBoostBody(
          _formatPercentValue(insight.ratePercent),
        ),
        icon: Icons.auto_stories_rounded,
        tone: Theme.of(context).colorScheme.tertiary,
      );
    case MerchantAnalyticsInsightType.stableConsistentPerformance:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsStablePerformanceTitle,
        body: l10n.merchantAnalyticsStablePerformanceBody(
          _formatPercentValue(insight.ratePercent),
        ),
        icon: Icons.analytics_outlined,
        tone: AppTheme.infoColor,
      );
    case MerchantAnalyticsInsightType.dataStale:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsDataStaleTitle,
        body: l10n.merchantAnalyticsDataStaleBody(
          '${insight.integerValue ?? 0}',
        ),
        icon: Icons.schedule_rounded,
        tone: AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.noRecentData:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsNoRecentDataTitle,
        body: l10n.merchantAnalyticsNoRecentDataBody,
        icon: Icons.timeline_rounded,
        tone: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    case MerchantAnalyticsInsightType.trafficUpNoConversion:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsTrafficUpNoConversionTitle,
        body: l10n.merchantAnalyticsTrafficUpNoConversionBody(
          _formatPercentValue(insight.deltaPercent),
          '${insight.integerValue ?? 0}',
        ),
        icon: Icons.trending_up_rounded,
        tone: AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.contactDrop:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsContactDropTitle,
        body: l10n.merchantAnalyticsContactDropBody(
          _formatPercentValue(insight.deltaPercent),
        ),
        icon: Icons.phone_missed_rounded,
        tone: insight.severity == MerchantAnalyticsInsightSeverity.critical
            ? AppTheme.errorColor
            : AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.offerInterestNoRedemption:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsOfferInterestNoRedemptionTitle,
        body: l10n.merchantAnalyticsOfferInterestNoRedemptionBody(
          '${insight.integerValue ?? 0}',
          _formatPercentValue(insight.ratePercent),
        ),
        icon: Icons.local_offer_outlined,
        tone: AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.quietPeriod:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsQuietPeriodTitle,
        body: l10n.merchantAnalyticsQuietPeriodBody,
        icon: Icons.pause_circle_outline_rounded,
        tone: AppTheme.warningColor,
      );
    case MerchantAnalyticsInsightType.topOfferConcentrated:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsTopOfferConcentratedTitle,
        body: l10n.merchantAnalyticsTopOfferConcentratedBody(
          _formatPercentValue(insight.ratePercent),
          '${insight.integerValue ?? 0}',
        ),
        icon: Icons.workspace_premium_outlined,
        tone: AppTheme.infoColor,
      );
    case MerchantAnalyticsInsightType.storyLift:
      return ResolvedMerchantAnalyticsInsightCopy(
        title: l10n.merchantAnalyticsStoryLiftTitle,
        body: l10n.merchantAnalyticsStoryLiftBody(
          _formatPercentValue(insight.deltaPercent),
        ),
        icon: Icons.auto_stories_rounded,
        tone: Theme.of(context).colorScheme.tertiary,
      );
  }
}

String _formatPercentValue(double? value) {
  if (value == null) {
    return '0';
  }
  return value.toStringAsFixed(value >= 10 ? 0 : 1);
}
