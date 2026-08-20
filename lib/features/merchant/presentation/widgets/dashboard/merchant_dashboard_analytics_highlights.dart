import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_analytics_insights.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../../providers/merchant_dashboard_providers.dart';
import 'merchant_dashboard_shared.dart';

class MerchantDashboardAnalyticsHighlightsSection extends ConsumerWidget {
  const MerchantDashboardAnalyticsHighlightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final drilldownAsync = ref.watch(
      merchantDashboardAnalyticsDrilldownProvider,
    );
    final insightsAsync = ref.watch(merchantAnalyticsInsightsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(
          title: l10n.merchantAnalyticsHighlightsTitle,
        ),
        const SizedBox(height: AppSpacing.md),
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
          data: (insights) =>
              MerchantAnalyticsInsightsCard(insights: insights, maxItems: 3),
        ),
        const SizedBox(height: AppSpacing.md),
        drilldownAsync.when(
          loading: () => const MerchantDashboardCardShell(
            child: SizedBox(
              height: 120,
              child: Center(child: WainLoadingIndicator()),
            ),
          ),
          error: (_, _) => MerchantDashboardFallbackCard(
            message: l10n.merchantTrendLoadFailed,
          ),
          data: (payload) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MerchantDashboardCompactFunnelCard(funnel: payload.funnel),
              const SizedBox(height: AppSpacing.md),
              _MerchantDashboardTopOffersPreviewCard(
                offers: payload.offers,
                periodDays: payload.summary.periodDays,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MerchantDashboardCompactFunnelCard extends StatelessWidget {
  final MerchantAnalyticsFunnel funnel;

  const _MerchantDashboardCompactFunnelCard({required this.funnel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!funnel.hasAnyActivity) {
      return MerchantDashboardFallbackCard(
        message: l10n.merchantAnalyticsFunnelEmpty,
        icon: Icons.filter_alt_outlined,
      );
    }

    return MerchantDashboardCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.merchantAnalyticsFunnelTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final step in funnel.steps) ...[
            _MerchantDashboardFunnelRow(step: step),
            if (step != funnel.steps.last)
              const SizedBox(height: AppSpacing.sm),
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
                icon: Icons.token_rounded,
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
    );
  }
}

class _MerchantDashboardFunnelRow extends StatelessWidget {
  final MerchantAnalyticsFunnelStep step;

  const _MerchantDashboardFunnelRow({required this.step});

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

class _MerchantDashboardTopOffersPreviewCard extends StatelessWidget {
  final List<MerchantOfferAnalyticsSummary> offers;
  final int periodDays;

  const _MerchantDashboardTopOffersPreviewCard({
    required this.offers,
    required this.periodDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeOffers = offers
        .where((offer) => offer.hasActivityForPeriod(periodDays))
        .take(3)
        .toList();

    return MerchantDashboardCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.merchantAnalyticsTopOffersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () => context.push('/merchant/analytics'),
                  child: Text(
                    l10n.merchantAnalyticsOpenDetails,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (activeOffers.isEmpty)
            Text(
              l10n.merchantAnalyticsTopOffersEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: [
                for (var index = 0; index < activeOffers.length; index++) ...[
                  _MerchantDashboardTopOfferRow(
                    offer: activeOffers[index],
                    periodDays: periodDays,
                  ),
                  if (index != activeOffers.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(height: 1),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MerchantDashboardTopOfferRow extends StatelessWidget {
  final MerchantOfferAnalyticsSummary offer;
  final int periodDays;

  const _MerchantDashboardTopOfferRow({
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

class MerchantOfferStatusBadge extends StatelessWidget {
  final MerchantOfferStatus? status;

  const MerchantOfferStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveStatus = status ?? MerchantOfferStatus.paused;
    final (label, tone) = switch (effectiveStatus) {
      MerchantOfferStatus.active => (
        l10n.merchantOffersActive,
        AppTheme.successColor,
      ),
      MerchantOfferStatus.paused => (
        l10n.merchantOffersPaused,
        AppTheme.warningColor,
      ),
      MerchantOfferStatus.expired => (
        l10n.merchantOffersExpired,
        AppTheme.errorColor,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withAlpha(14),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: tone.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatPercent(double value) {
  final percentValue = value * 100;
  return '${percentValue.toStringAsFixed(percentValue >= 10 ? 0 : 1)}%';
}
