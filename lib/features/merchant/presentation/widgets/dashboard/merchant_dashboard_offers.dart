import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_performance_summary.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../../providers/merchant_dashboard_providers.dart';
import 'merchant_dashboard_shared.dart';

class MerchantDashboardOffersSection extends ConsumerWidget {
  const MerchantDashboardOffersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final offersAsync = ref.watch(merchantOffersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(title: l10n.merchantOffers),
        const SizedBox(height: AppSpacing.md),
        offersAsync.when(
          loading: () => const Center(child: WainLoadingIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (offers) {
            if (offers.isEmpty) {
              return MerchantDashboardFallbackCard(
                message: l10n.merchantNoOffersNow,
              );
            }

            final now = DateTime.now();
            final summary = buildOfferPerformanceSummary(offers, now);
            return Column(
              children: [
                MerchantDashboardOfferPerformanceSummaryCard(
                  summary: summary,
                  now: now,
                ),
                const SizedBox(height: AppSpacing.md),
                ...offers.map(
                  (offer) => MerchantDashboardOfferRow(offer: offer, now: now),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class MerchantDashboardOfferPerformanceSummaryCard extends StatelessWidget {
  final MerchantOfferPerformanceSummary summary;
  final DateTime now;

  const MerchantDashboardOfferPerformanceSummaryCard({
    super.key,
    required this.summary,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final topPerformer = summary.topPerformer;

    return MerchantDashboardCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MerchantDashboardMetricChip(
                icon: Icons.people_alt_rounded,
                label: l10n.merchantOffersClaims(summary.totalClaims),
                tone: AppTheme.warningColor,
              ),
              MerchantDashboardMetricChip(
                icon: Icons.check_circle_rounded,
                label: l10n.merchantOffersRedeemed(summary.totalRedeemed),
                tone: AppTheme.successColor,
              ),
              MerchantDashboardMetricChip(
                icon: Icons.percent_rounded,
                label: l10n.merchantOffersConversion(
                  summary.overallConversionPercent.toStringAsFixed(0),
                ),
                tone: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (topPerformer == null)
            Text(
              l10n.merchantOffersNoPerformanceData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                Text(
                  '${l10n.merchantOffersTopPerformerLabel}: ',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Expanded(
                  child: Text(
                    topPerformer.primaryTitle.isNotEmpty
                        ? topPerformer.primaryTitle
                        : l10n.merchantDefaultOfferTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                MerchantDashboardOfferStatusPill(
                  status: topPerformer.effectiveStatusAt(now),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class MerchantDashboardOfferRow extends StatelessWidget {
  final MerchantOffer offer;
  final DateTime now;

  const MerchantDashboardOfferRow({
    super.key,
    required this.offer,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = offer.effectiveStatusAt(now);
    final isActive = status == MerchantOfferStatus.active;
    final isExpired = status == MerchantOfferStatus.expired;
    final accent = isExpired
        ? AppTheme.errorColor
        : isActive
        ? AppTheme.successColor
        : colorScheme.onSurfaceVariant;
    final backgroundColor = isExpired
        ? AppTheme.errorColor.withAlpha(12)
        : isActive
        ? AppTheme.successColor.withAlpha(18)
        : colorScheme.surfaceContainerLowest;
    final borderColor = isExpired
        ? AppTheme.errorColor.withAlpha(48)
        : isActive
        ? AppTheme.successColor.withAlpha(60)
        : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MerchantDashboardCardShell(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withAlpha(18),
                borderRadius: AppSpacing.radiusMd,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.local_offer_rounded, color: accent),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.primaryTitle.isNotEmpty
                              ? offer.primaryTitle
                              : l10n.merchantDefaultOfferTitle,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      MerchantDashboardOfferStatusPill(status: status),
                    ],
                  ),
                  if (offer.hasDescription) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      offer.primaryDescription,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      MerchantDashboardMetricChip(
                        icon: Icons.people_alt_rounded,
                        label: l10n.merchantOffersClaims(offer.claimsCount),
                        tone: AppTheme.warningColor,
                      ),
                      MerchantDashboardMetricChip(
                        icon: Icons.check_circle_rounded,
                        label: l10n.merchantOffersRedeemed(offer.redeemedCount),
                        tone: AppTheme.successColor,
                      ),
                      MerchantDashboardMetricChip(
                        icon: Icons.percent_rounded,
                        label: l10n.merchantOffersConversion(
                          offer.conversionPercent.toStringAsFixed(0),
                        ),
                        tone: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantDashboardOfferStatusPill extends StatelessWidget {
  final MerchantOfferStatus status;

  const MerchantDashboardOfferStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final (label, color) = switch (status) {
      MerchantOfferStatus.active => (
        l10n.merchantOffersActive,
        AppTheme.successColor,
      ),
      MerchantOfferStatus.paused => (
        l10n.merchantOffersPaused,
        colorScheme.onSurfaceVariant,
      ),
      MerchantOfferStatus.expired => (
        l10n.merchantOffersExpired,
        AppTheme.errorColor,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(color: color.withAlpha(48)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
