import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/domain/entities/venue_busy_times.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_busy_times_chart.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueBusyTimesSection extends ConsumerStatefulWidget {
  final Venue venue;

  const VenueBusyTimesSection({super.key, required this.venue});

  @override
  ConsumerState<VenueBusyTimesSection> createState() =>
      _VenueBusyTimesSectionState();
}

class _VenueBusyTimesSectionState extends ConsumerState<VenueBusyTimesSection> {
  late String _selectedDayKey;

  @override
  void initState() {
    super.initState();
    _selectedDayKey = _todayDayKey();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final busyTimesAsync = ref.watch(venueBusyTimesProvider(widget.venue.id));

    return busyTimesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (busyTimes) {
        if (busyTimes == null ||
            !busyTimes.isUsable ||
            busyTimes.histogram == null) {
          return const SizedBox.shrink();
        }

        final displayDayKey = _resolveDisplayDayKey(busyTimes.histogram!);
        if (displayDayKey != _selectedDayKey) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedDayKey != displayDayKey) {
              setState(() => _selectedDayKey = displayDayKey);
            }
          });
        }

        final values = busyTimes.histogram![displayDayKey];
        if (values == null || values.length != 24) {
          return const SizedBox.shrink();
        }

        final currentDayKey = _todayDayKey();
        final highlightedHour = currentDayKey == displayDayKey
            ? DateTime.now().hour
            : null;
        final bestWindows =
            busyTimes.bestVisitWindowsByDay?[displayDayKey] ??
            const <BestVisitWindow>[];

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: theme.colorScheme.outline.withAlpha(72)),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.busyTimesTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        if (busyTimes.confidence ==
                            BusyTimesConfidence.low) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withAlpha(18),
                              borderRadius: AppSpacing.radiusFull,
                              border: Border.all(
                                color: AppTheme.warningColor.withAlpha(52),
                              ),
                            ),
                            child: Text(
                              l10n.busyTimesDataPreliminary,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurfaceColor,
                      borderRadius: AppSpacing.radiusMd,
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.busyTimesBasedOnUsage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (busyTimes.currentTypicalLabel != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(16),
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _currentLabelText(
                            l10n,
                            busyTimes.currentTypicalLabel!,
                          ),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    ListView.separated(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _dayKeys.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final dayKey = _dayKeys[index];
                        final isSelected = dayKey == displayDayKey;
                        return _BusyTimesDayChip(
                          label: _localizedDayLabel(l10n, dayKey),
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedDayKey = dayKey),
                        );
                      },
                    ),
                    _EdgeFade(
                      alignment: Alignment.centerLeft,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    _EdgeFade(
                      alignment: Alignment.centerRight,
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: AppSpacing.radiusLg,
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(46),
                  ),
                ),
                child: VenueBusyTimesChart(
                  values: values,
                  highlightedHour: highlightedHour,
                ),
              ),
              if (bestWindows.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withAlpha(14),
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.busyTimesBestVisitWindow(
                            _formatWindowRange(context, bestWindows.first),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _todayDayKey() {
    const mapping = <int, String>{
      DateTime.monday: 'day_0',
      DateTime.tuesday: 'day_1',
      DateTime.wednesday: 'day_2',
      DateTime.thursday: 'day_3',
      DateTime.friday: 'day_4',
      DateTime.saturday: 'day_5',
      DateTime.sunday: 'day_6',
    };
    return mapping[DateTime.now().weekday] ?? 'day_0';
  }

  String _resolveDisplayDayKey(Map<String, List<double>> histogram) {
    final selectedValues = histogram[_selectedDayKey];
    if (selectedValues != null && _hasMeaningfulValues(selectedValues)) {
      return _selectedDayKey;
    }

    if (_selectedDayKey != _todayDayKey()) {
      return _selectedDayKey;
    }

    String bestDayKey = _selectedDayKey;
    double bestScore = -1;
    for (final dayKey in _dayKeys) {
      final values = histogram[dayKey];
      if (values == null) continue;
      final score = values.fold<double>(0, (sum, value) => sum + value);
      if (score > bestScore) {
        bestScore = score;
        bestDayKey = dayKey;
      }
    }

    return bestScore > 0 ? bestDayKey : _selectedDayKey;
  }

  bool _hasMeaningfulValues(List<double> values) {
    return values.any((value) => value > 0.001);
  }

  String _currentLabelText(AppLocalizations l10n, BusyTimesCurrentLabel label) {
    switch (label) {
      case BusyTimesCurrentLabel.quiet:
        return l10n.busyTimesQuietNow;
      case BusyTimesCurrentLabel.medium:
        return l10n.busyTimesMediumNow;
      case BusyTimesCurrentLabel.busy:
        return l10n.busyTimesBusyNow;
    }
  }

  String _localizedDayLabel(AppLocalizations l10n, String dayKey) {
    switch (dayKey) {
      case 'day_0':
        return l10n.dayMonday;
      case 'day_1':
        return l10n.dayTuesday;
      case 'day_2':
        return l10n.dayWednesday;
      case 'day_3':
        return l10n.dayThursday;
      case 'day_4':
        return l10n.dayFriday;
      case 'day_5':
        return l10n.daySaturday;
      case 'day_6':
        return l10n.daySunday;
      default:
        return dayKey;
    }
  }

  String _formatWindowRange(BuildContext context, BestVisitWindow window) {
    return '${_formatHour(context, window.startHour)} - ${_formatHour(context, window.endHour)}';
  }

  String _formatHour(BuildContext context, int hour) {
    final l10n = AppLocalizations.of(context)!;
    final period = hour >= 12 ? l10n.hoursPeriodPm : l10n.hoursPeriodAm;
    final normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$normalizedHour $period';
  }
}

const _dayKeys = <String>[
  'day_0',
  'day_1',
  'day_2',
  'day_3',
  'day_4',
  'day_5',
  'day_6',
];

class _BusyTimesDayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BusyTimesDayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.radiusMd,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withAlpha(14)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: AppSpacing.radiusMd,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withAlpha(86)
                  : theme.colorScheme.outline.withAlpha(56),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  final Alignment alignment;
  final Alignment begin;
  final Alignment end;

  const _EdgeFade({
    required this.alignment,
    required this.begin,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [surface, surface.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }
}
