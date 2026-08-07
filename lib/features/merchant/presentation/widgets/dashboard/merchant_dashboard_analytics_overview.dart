import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/presentation/widgets/analytics/merchant_analytics_primitives.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../../providers/merchant_dashboard_providers.dart';
import 'merchant_dashboard_shared.dart';

class MerchantDashboardStatsSection extends ConsumerWidget {
  final bool showDetailCta;

  const MerchantDashboardStatsSection({super.key, this.showDetailCta = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rangeDays = ref.watch(dashboardTrendRangeDaysProvider);
    final summaryAsync = ref.watch(merchantAnalyticsSummaryProvider);
    final summary = summaryAsync.asData?.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: MerchantDashboardSectionTitle(
                title: l10n.merchantAnalyticsTitle,
              ),
            ),
            if (summary != null)
              MerchantDashboardFreshnessChip(updatedAt: summary.updatedAt),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            ToggleButtons(
              isSelected: [rangeDays == 7, rangeDays == 30],
              onPressed: (index) {
                ref
                    .read(dashboardTrendRangeDaysProvider.notifier)
                    .setRange(index == 0 ? 7 : 30);
              },
              borderRadius: AppSpacing.radiusSm,
              constraints: const BoxConstraints(minWidth: 54, minHeight: 36),
              textStyle: Theme.of(context).textTheme.labelMedium,
              selectedColor: colorScheme.primary,
              fillColor: colorScheme.primaryContainer,
              color: colorScheme.onSurfaceVariant,
              borderColor: colorScheme.outline,
              selectedBorderColor: colorScheme.primary,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(l10n.dashboard7Days),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(l10n.dashboard30Days),
                ),
              ],
            ),
            if (showDetailCta) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/merchant/analytics'),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l10n.merchantAnalyticsOpenDetails),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        summaryAsync.when(
          loading: () => const MerchantDashboardCardShell(
            child: SizedBox(
              height: 180,
              child: Center(child: WainLoadingIndicator()),
            ),
          ),
          error: (_, _) => MerchantDashboardFallbackCard(
            message: l10n.merchantTrendLoadFailed,
          ),
          data: (summary) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MerchantAnalyticsHeroCard(summary: summary),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                // 1.35 left the tile ~3 px short of its own content, and
                // Arabic labels lose their descenders before anything else.
                // The Flexible children below stop it overflowing at large text
                // scales; this is what stops it being cramped at the normal one.
                childAspectRatio: 1.15,
                children: [
                  _MerchantDashboardKpiCard(
                    label: l10n.merchantViews,
                    value: summary.views.toString(),
                    deltaPercent: summary.viewsDeltaPercent,
                    accent: colorScheme.primary,
                    icon: Icons.visibility_rounded,
                  ),
                  _MerchantDashboardKpiCard(
                    label: l10n.merchantCalls,
                    value: summary.calls.toString(),
                    deltaPercent: summary.callsDeltaPercent,
                    accent: AppTheme.successColor,
                    icon: Icons.phone_rounded,
                  ),
                  _MerchantDashboardKpiCard(
                    label: l10n.merchantNavs,
                    value: summary.navs.toString(),
                    deltaPercent: summary.navsDeltaPercent,
                    accent: AppTheme.warningColor,
                    icon: Icons.navigation_rounded,
                  ),
                  _MerchantDashboardKpiCard(
                    label: l10n.merchantStoryViews,
                    value: summary.storyViews.toString(),
                    deltaPercent: summary.storyViewsDeltaPercent,
                    accent: colorScheme.tertiary,
                    icon: Icons.auto_stories_rounded,
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

class MerchantDashboardFreshnessChip extends StatelessWidget {
  final DateTime? updatedAt;

  const MerchantDashboardFreshnessChip({super.key, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final Color tone;
    final String value;
    if (updatedAt == null) {
      tone = colorScheme.onSurfaceVariant;
      value = l10n.merchantFreshnessNeverUpdated;
    } else {
      final age = now.difference(updatedAt!);
      if (age <= const Duration(hours: 6)) {
        tone = AppTheme.successColor;
      } else if (age <= const Duration(hours: 24)) {
        tone = AppTheme.warningColor;
      } else {
        tone = AppTheme.errorColor;
      }

      if (age.inMinutes <= 0) {
        value = l10n.cacheJustNow;
      } else if (age.inMinutes < 60) {
        value = l10n.cacheMinsAgo(age.inMinutes);
      } else if (age.inHours < 24) {
        value = l10n.cacheHoursAgo(age.inHours);
      } else {
        value = l10n.cacheDaysAgo(age.inDays);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tone.withAlpha(12),
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: tone.withAlpha(60)),
      ),
      child: Text(
        '${l10n.merchantFreshnessLabel}: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MerchantAnalyticsHeroCard extends StatelessWidget {
  final MerchantAnalyticsSummary summary;

  const _MerchantAnalyticsHeroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MerchantDashboardCardShell(
      backgroundColor: colorScheme.primaryContainer.withAlpha(180),
      borderColor: colorScheme.primary.withAlpha(90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.merchantAnalyticsViewsThisPeriod,
            style: textTheme.titleMedium?.copyWith(
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
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${summary.views}',
                  style: textTheme.displayLarge?.copyWith(
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
                    '${l10n.merchantAnalyticsContactRate}: ${_formatPercent(summary.contactRate * 100)}',
                tone: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MerchantDashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final double? deltaPercent;
  final Color accent;
  final IconData icon;

  const _MerchantDashboardKpiCard({
    required this.label,
    required this.value,
    required this.deltaPercent,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return MerchantDashboardCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withAlpha(20),
                  borderRadius: AppSpacing.radiusMd,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              MerchantAnalyticsDeltaBadge(deltaPercent: deltaPercent),
            ],
          ),
          const Spacer(),
          // The grid fixes this tile's height through childAspectRatio, and
          // every child above was inflexible — so when the number and the label
          // together needed 3 px more than the tile had, the tile overflowed
          // rather than adapting. The Spacer cannot absorb that: it only gets
          // what is left *after* the inflexible children, which is nothing.
          // Letting these two shrink is what makes the tile fit at any text
          // scale instead of at one.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPercent(double value) {
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}%';
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
