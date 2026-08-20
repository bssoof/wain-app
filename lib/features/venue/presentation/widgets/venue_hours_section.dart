import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueWorkingHoursSection extends StatelessWidget {
  final Venue venue;

  const VenueWorkingHoursSection({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final todayText = venue.todayHoursText;
    final todayLabel = todayText == 'open_24h' ? l10n.open24Hours : todayText;

    if (todayText == null && venue.hours.isEmpty) {
      return const SizedBox.shrink();
    }

    final separator = l10n.localeName.startsWith('ar') ? '، ' : ', ';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withAlpha(18),
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l10n.hoursTitle, style: theme.textTheme.titleLarge),
              ),
              // Flexible: a day with two slots produces a long label, which
              // overflowed this row by 112px next to the title.
              if (todayLabel != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurfaceColor,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Text(
                      todayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (venue.hours.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...venue.hours.entries.map((entry) {
              final slots = entry.value;
              final isClosed = slots.isEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        _localizedDayName(l10n, entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        isClosed
                            ? l10n.closed
                            : slots
                                  .map((slot) => '${slot.open} - ${slot.close}')
                                  .join(separator),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isClosed
                              ? AppTheme.errorColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _localizedDayName(AppLocalizations l10n, String key) {
    switch (key.toLowerCase()) {
      case 'monday':
        return l10n.dayMonday;
      case 'tuesday':
        return l10n.dayTuesday;
      case 'wednesday':
        return l10n.dayWednesday;
      case 'thursday':
        return l10n.dayThursday;
      case 'friday':
        return l10n.dayFriday;
      case 'saturday':
        return l10n.daySaturday;
      case 'sunday':
        return l10n.daySunday;
      default:
        return key;
    }
  }
}
