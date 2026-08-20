import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueBusyTimesChart extends StatelessWidget {
  final List<double> values;
  final int? highlightedHour;

  const VenueBusyTimesChart({
    super.key,
    required this.values,
    required this.highlightedHour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideColor = theme.colorScheme.outline.withAlpha(42);
    final maxValue = values.isEmpty
        ? 1.0
        : values
              .reduce((left, right) => left > right ? left : right)
              .clamp(1.0, double.infinity);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 96,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      3,
                      (_) =>
                          Divider(height: 1, thickness: 1, color: guideColor),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(values.length, (index) {
                          final normalized = (values[index] / maxValue).clamp(
                            0.0,
                            1.0,
                          );
                          final isHighlighted = highlightedHour == index;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 6 + (normalized * 64),
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? AppTheme.primaryColor
                                        : AppTheme.primaryColor.withAlpha(110),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isHighlighted
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withAlpha(44),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Each tick takes an equal share rather than its intrinsic width: five
        // labels like "12 PM" stopped fitting the chart at a large text scale,
        // and a tick that cannot shrink pushes the row past the chart it
        // labels. Sharing the width keeps them aligned with the bars too.
        Row(
          children: [
            for (final hour in const <int>[0, 6, 12, 18, 23])
              Expanded(
                child: Align(
                  alignment: hour == 0
                      ? AlignmentDirectional.centerStart
                      : hour == 23
                      ? AlignmentDirectional.centerEnd
                      : Alignment.center,
                  child: _ChartTick(
                    label: _formatHourLabel(context, hour),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatHourLabel(BuildContext context, int hour) {
    final l10n = AppLocalizations.of(context)!;
    final period = hour >= 12 ? l10n.hoursPeriodPm : l10n.hoursPeriodAm;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour$period';
  }
}

class _ChartTick extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartTick({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    // Six ticks share the chart width. At a large text scale their labels
    // stopped fitting, so the tick scales itself down rather than pushing the
    // row past the chart it labels.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
