import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/utils/geo_utils.dart';
import 'package:wain_app/features/location/presentation/providers/location_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueSummaryStrip extends ConsumerWidget {
  final Venue venue;

  const VenueSummaryStrip({super.key, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isOpenNow = venue.isOpenNow();
    final statusValue = isOpenNow == null
        ? l10n.venueSummaryNotAvailable
        : (isOpenNow ? l10n.openNow : l10n.closed);
    final closeValue = _resolveCloseValue(l10n);
    final priceRange = _resolvePriceRange();
    final distanceAsync = ref.watch(userLocationProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.circle,
              label: l10n.venueSummaryStatus,
              value: statusValue,
              valueColor: isOpenNow == true
                  ? Colors.green.shade700
                  : (isOpenNow == false
                        ? Colors.red.shade700
                        : AppTheme.textPrimary),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.near_me_outlined,
              label: l10n.venueSummaryDistance,
              value: distanceAsync.when(
                data: (position) {
                  if (position == null) {
                    return l10n.venueSummaryNotAvailable;
                  }
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
          ),
          _buildDivider(),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.schedule_outlined,
              label: l10n.venueSummaryClosesAt,
              value: closeValue,
            ),
          ),
          if (priceRange != null) ...[
            _buildDivider(),
            Expanded(
              child: _SummaryMetric(
                icon: Icons.sell_outlined,
                label: l10n.venueSummaryPriceRange,
                value: priceRange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.shade200,
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

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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
