import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/presentation/widgets/analytics/merchant_analytics_primitives.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_analytics_highlights.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_analytics_overview.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_shared.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../providers/merchant_dashboard_providers.dart';

class MerchantAnalyticsPageHeader extends ConsumerWidget {
  const MerchantAnalyticsPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rangeDays = ref.watch(merchantAnalyticsPageRangeDaysProvider);
    final drilldownAsync = ref.watch(merchantAnalyticsDrilldownProvider);
    final summary = drilldownAsync.asData?.value.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.merchantAnalyticsDetailTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (summary != null)
              // Its text grows with the age it reports, and it was squeezing
              // the title out of the row on a narrow screen.
              Flexible(
                child: MerchantDashboardFreshnessChip(
                  updatedAt: summary.updatedAt,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ToggleButtons(
          isSelected: [rangeDays == 7, rangeDays == 30],
          onPressed: (index) {
            ref
                .read(merchantAnalyticsPageRangeDaysProvider.notifier)
                .setRange(index == 0 ? 7 : 30);
          },
          borderRadius: AppSpacing.radiusSm,
          constraints: const BoxConstraints(minWidth: 54, minHeight: 36),
          textStyle: Theme.of(context).textTheme.labelMedium,
          selectedColor: Theme.of(context).colorScheme.primary,
          fillColor: Theme.of(context).colorScheme.primaryContainer,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          borderColor: Theme.of(context).colorScheme.outline,
          selectedBorderColor: Theme.of(context).colorScheme.primary,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(l10n.dashboard7Days),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(l10n.dashboard30Days),
            ),
          ],
        ),
      ],
    );
  }
}

class MerchantAnalyticsOverviewSection extends StatelessWidget {
  final MerchantAnalyticsSummary summary;

  const MerchantAnalyticsOverviewSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(
          title: l10n.merchantAnalyticsOverviewTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        MerchantDashboardCardShell(
          backgroundColor: colorScheme.primaryContainer.withAlpha(180),
          borderColor: colorScheme.primary.withAlpha(90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.merchantAnalyticsViewsThisPeriod,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatPeriodRange(
                  context,
                  summary.currentPeriodStart,
                  summary.currentPeriodEnd,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withAlpha(180),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${summary.views}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 34,
                      ),
                    ),
                  ),
                  MerchantAnalyticsDeltaBadge(
                    deltaPercent: summary.viewsDeltaPercent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  MerchantDashboardMetricChip(
                    icon: Icons.touch_app_rounded,
                    label:
                        '${l10n.merchantAnalyticsContactIntent}: ${summary.contactIntent}',
                    tone: colorScheme.onPrimaryContainer,
                  ),
                  MerchantDashboardMetricChip(
                    icon: Icons.percent_rounded,
                    label:
                        '${l10n.merchantAnalyticsContactRate}: ${_formatPercent(summary.contactRate)}',
                    tone: colorScheme.onPrimaryContainer,
                  ),
                  MerchantDashboardMetricChip(
                    icon: Icons.auto_stories_rounded,
                    label: '${l10n.merchantStoryViews}: ${summary.storyViews}',
                    tone: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MerchantAnalyticsFunnelSection extends StatelessWidget {
  final MerchantAnalyticsFunnel funnel;

  const MerchantAnalyticsFunnelSection({super.key, required this.funnel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(title: l10n.merchantAnalyticsFunnelTitle),
        const SizedBox(height: AppSpacing.md),
        if (!funnel.hasAnyActivity)
          MerchantDashboardFallbackCard(
            message: l10n.merchantAnalyticsFunnelEmpty,
            icon: Icons.filter_alt_outlined,
          )
        else
          MerchantDashboardCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in funnel.steps) ...[
                  _MerchantAnalyticsFunnelStepRow(step: step),
                  if (step != funnel.steps.last)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    MerchantDashboardMetricChip(
                      icon: Icons.touch_app_outlined,
                      label:
                          '${l10n.merchantAnalyticsDetailToClickRateShort}: ${_formatPercent(funnel.detailToClaimClickRate)}',
                      tone: AppTheme.infoColor,
                    ),
                    MerchantDashboardMetricChip(
                      icon: Icons.confirmation_number_outlined,
                      label:
                          '${l10n.merchantAnalyticsViewToClaimRateShort}: ${_formatPercent(funnel.viewToClaimRate)}',
                      tone: AppTheme.warningColor,
                    ),
                    MerchantDashboardMetricChip(
                      icon: Icons.verified_rounded,
                      label:
                          '${l10n.merchantAnalyticsClaimToRedemptionRateShort}: ${_formatPercent(funnel.claimToRedemptionRate)}',
                      tone: AppTheme.successColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class MerchantAnalyticsDemandTrendsSection extends StatelessWidget {
  final MerchantAnalyticsSummary summary;
  final List<MerchantDailyPoint> points;

  const MerchantAnalyticsDemandTrendsSection({
    super.key,
    required this.summary,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(
          title: l10n.merchantAnalyticsDemandTrendsTitle,
        ),
        const SizedBox(height: AppSpacing.md),
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
      ],
    );
  }
}

class MerchantAnalyticsConversionTrendsSection extends StatelessWidget {
  final MerchantAnalyticsFunnel funnel;
  final List<MerchantDailyPoint> points;

  const MerchantAnalyticsConversionTrendsSection({
    super.key,
    required this.funnel,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(
          title: l10n.merchantAnalyticsConversionTrendsTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        MerchantAnalyticsTrendCard(
          title: l10n.merchantAnalyticsOfferDetailViews,
          values: points.map((point) => point.offerDetailViews).toList(),
          total: funnel.offerDetailViews,
          averagePerDay: _average(funnel.offerDetailViews, points.length),
          deltaPercent: null,
          accent: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        MerchantAnalyticsTrendCard(
          title: l10n.merchantAnalyticsClaimsCreated,
          values: points.map((point) => point.claimsCreated).toList(),
          total: funnel.claimsCreated,
          averagePerDay: _average(funnel.claimsCreated, points.length),
          deltaPercent: null,
          accent: AppTheme.warningColor,
        ),
        const SizedBox(height: AppSpacing.md),
        MerchantAnalyticsTrendCard(
          title: l10n.merchantAnalyticsRedemptions,
          values: points.map((point) => point.redemptions).toList(),
          total: funnel.redemptions,
          averagePerDay: _average(funnel.redemptions, points.length),
          deltaPercent: null,
          accent: AppTheme.successColor,
        ),
      ],
    );
  }
}

class MerchantAnalyticsTopOffersSection extends StatelessWidget {
  final List<MerchantOfferAnalyticsSummary> offers;
  final int periodDays;

  const MerchantAnalyticsTopOffersSection({
    super.key,
    required this.offers,
    required this.periodDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleOffers = offers
        .where((offer) => offer.hasActivityForPeriod(periodDays))
        .take(10)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(
          title: l10n.merchantAnalyticsTopOffersTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        MerchantDashboardCardShell(
          child: visibleOffers.isEmpty
              ? Text(
                  l10n.merchantAnalyticsTopOffersEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < visibleOffers.length;
                      index++
                    ) ...[
                      _MerchantAnalyticsTopOfferListRow(
                        offer: visibleOffers[index],
                        periodDays: periodDays,
                      ),
                      if (index != visibleOffers.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Divider(height: 1),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class MerchantAnalyticsTimelineSection extends StatelessWidget {
  final MerchantAnalyticsSummary summary;

  const MerchantAnalyticsTimelineSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(
          title: l10n.merchantAnalyticsTimelineTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        if (summary.bestDay == null && summary.worstDay == null)
          MerchantDashboardFallbackCard(
            message: l10n.merchantNoTrendData,
            icon: Icons.timeline_rounded,
          )
        else
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
    );
  }
}

class _MerchantAnalyticsFunnelStepRow extends StatelessWidget {
  final MerchantAnalyticsFunnelStep step;

  const _MerchantAnalyticsFunnelStepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final label = switch (step.type) {
      MerchantAnalyticsFunnelStepType.views => AppLocalizations.of(
        context,
      )!.merchantViews,
      MerchantAnalyticsFunnelStepType.offerDetailViews => AppLocalizations.of(
        context,
      )!.merchantAnalyticsOfferDetailViews,
      MerchantAnalyticsFunnelStepType.claimClicks => AppLocalizations.of(
        context,
      )!.merchantAnalyticsClaimClicks,
      MerchantAnalyticsFunnelStepType.claimsCreated => AppLocalizations.of(
        context,
      )!.merchantAnalyticsClaimsCreated,
      MerchantAnalyticsFunnelStepType.redemptions => AppLocalizations.of(
        context,
      )!.merchantAnalyticsRedemptions,
    };

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          '${step.value}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MerchantAnalyticsTopOfferListRow extends StatelessWidget {
  final MerchantOfferAnalyticsSummary offer;
  final int periodDays;

  const _MerchantAnalyticsTopOfferListRow({
    required this.offer,
    required this.periodDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                offer.offerTitleAr.trim().isEmpty
                    ? l10n.merchantDefaultOfferTitle
                    : offer.offerTitleAr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            MerchantOfferStatusBadge(status: offer.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            MerchantDashboardMetricChip(
              icon: Icons.redeem_rounded,
              label: l10n.merchantAnalyticsTopOfferRedemptions(
                '${offer.redemptionsForPeriod(periodDays)}',
              ),
              tone: AppTheme.successColor,
            ),
            MerchantDashboardMetricChip(
              icon: Icons.confirmation_number_outlined,
              label: l10n.merchantAnalyticsTopOfferClaims(
                '${offer.claimsCreatedForPeriod(periodDays)}',
              ),
              tone: AppTheme.warningColor,
            ),
            MerchantDashboardMetricChip(
              icon: Icons.percent_rounded,
              label: l10n.merchantAnalyticsTopOfferConversion(
                _formatPercent(
                  offer.claimToRedemptionRateForPeriod(periodDays),
                ),
              ),
              tone: AppTheme.infoColor,
            ),
          ],
        ),
      ],
    );
  }
}

double _average(int total, int days) {
  if (days <= 0) {
    return 0;
  }
  return total / days;
}

String _formatPercent(double value) {
  final percentValue = value * 100;
  return '${percentValue.toStringAsFixed(percentValue >= 10 ? 0 : 1)}%';
}

String _formatPeriodRange(
  BuildContext context,
  DateTime? start,
  DateTime? end,
) {
  if (start == null || end == null) {
    return '';
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat('d MMM y', locale);
  return '${formatter.format(start)} - ${formatter.format(end)}';
}
