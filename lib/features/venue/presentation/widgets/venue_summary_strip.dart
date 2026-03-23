import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/utils/geo_utils.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueSummaryStrip extends ConsumerWidget {
  final Venue venue;
  final bool isOverlay;
  final bool isEmbedded;

  const VenueSummaryStrip({
    super.key,
    required this.venue,
    this.isOverlay = false,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isOpenNow = venue.isOpenNow();
    final statusValue = isOpenNow == null
        ? l10n.venueSummaryNotAvailable
        : (isOpenNow ? l10n.openNow : l10n.closed);
    final closeValue = _resolveCloseValue(l10n);
    final priceRange = _resolvePriceRange();
    final distanceAsync = ref.watch(userLocationProvider);

    final metrics = <_SummaryMetricData>[
      _SummaryMetricData(
        icon: Icons.circle,
        label: l10n.venueSummaryStatus,
        value: statusValue,
        valueColor: isOpenNow == true
            ? AppTheme.successColor
            : (isOpenNow == false
                  ? AppTheme.errorColor
                  : theme.colorScheme.onSurface),
      ),
      _SummaryMetricData(
        icon: Icons.near_me_outlined,
        label: l10n.venueSummaryDistance,
        value: distanceAsync.when(
          data: (position) {
            final distanceKm = calculateDistanceKm(
              position.latitude,
              position.longitude,
              venue.lat,
              venue.lng,
            );
            if (distanceKm < 1) {
              return '${(distanceKm * 1000).toInt()} ${l10n.meterUnit}';
            }
            return '${distanceKm.toStringAsFixed(1)} ${l10n.kilometerUnit}';
          },
          loading: () => '...',
          error: (_, _) => l10n.venueSummaryNotAvailable,
        ),
      ),
      _SummaryMetricData(
        icon: Icons.schedule_outlined,
        label: l10n.venueSummaryClosesAt,
        value: closeValue,
      ),
      if (priceRange != null)
        _SummaryMetricData(
          icon: Icons.sell_outlined,
          label: l10n.venueSummaryPriceRange,
          value: priceRange,
        ),
    ];

    final useElevatedSurface = isOverlay || isEmbedded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 4,
      ),
      decoration: BoxDecoration(
        color: isEmbedded
            ? theme.colorScheme.surfaceContainerHighest.withAlpha(150)
            : theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
        boxShadow: const [],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldUseCompactGrid = isEmbedded && constraints.maxWidth < 470;

          if (shouldUseCompactGrid) {
            final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs + 4,
              children: [
                for (var index = 0; index < metrics.length; index++)
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      icon: metrics[index].icon,
                      label: metrics[index].label,
                      value: metrics[index].value,
                      valueColor: metrics[index].valueColor,
                      isOverlay: true,
                      allowLabelWrap: false,
                    ),
                  ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: _SummaryMetric(
                    icon: metrics[index].icon,
                    label: metrics[index].label,
                    value: metrics[index].value,
                    valueColor: metrics[index].valueColor,
                    isOverlay: useElevatedSurface,
                  ),
                ),
                if (index != metrics.length - 1) _buildDivider(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
    );
  }

  String _resolveCloseValue(AppLocalizations l10n) {
    if (venue.is24h) {
      return l10n.open24Hours;
    }

    final dayKey = _dayKeys[DateTime.now().weekday];
    if (dayKey == null) {
      return l10n.venueSummaryNotAvailable;
    }
    final slots = venue.hours[dayKey];
    if (slots == null) {
      return l10n.venueSummaryNotAvailable;
    }
    if (slots.isEmpty) {
      return l10n.venueSummaryClosedToday;
    }
    return slots.last.close;
  }

  String? _resolvePriceRange() {
    final min = venue.minPrice;
    final max = venue.maxPrice;
    if (min <= 0 || max <= 0 || max < min) {
      return null;
    }
    return '$min-$max ${venue.currency}';
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isOverlay;
  final bool allowLabelWrap;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isOverlay = false,
    this.allowLabelWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: isOverlay ? 12 : 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                maxLines: allowLabelWrap ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          value,
          maxLines: isOverlay ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryMetricData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

const Map<int, String> _dayKeys = <int, String>{
  1: 'monday',
  2: 'tuesday',
  3: 'wednesday',
  4: 'thursday',
  5: 'friday',
  6: 'saturday',
  7: 'sunday',
};
