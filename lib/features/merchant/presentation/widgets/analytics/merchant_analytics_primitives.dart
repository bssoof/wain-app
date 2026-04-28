import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_metrics.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../dashboard/merchant_dashboard_shared.dart';

class MerchantAnalyticsDeltaBadge extends StatelessWidget {
  final double? deltaPercent;

  const MerchantAnalyticsDeltaBadge({super.key, required this.deltaPercent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDelta = deltaPercent != null;
    final isPositive = (deltaPercent ?? 0) >= 0;
    final tone = !hasDelta
        ? colorScheme.onSurfaceVariant
        : isPositive
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final background = !hasDelta
        ? colorScheme.surfaceContainerLow
        : tone.withAlpha(18);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppSpacing.radiusSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          hasDelta
              ? '${isPositive ? '+' : ''}${deltaPercent!.toStringAsFixed(0)}%'
              : '-',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class MerchantAnalyticsTrendCard extends StatelessWidget {
  final String title;
  final List<int> values;
  final int total;
  final double averagePerDay;
  final double? deltaPercent;
  final Color accent;

  const MerchantAnalyticsTrendCard({
    super.key,
    required this.title,
    required this.values,
    required this.total,
    required this.averagePerDay,
    required this.deltaPercent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MerchantDashboardCardShell(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$total',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.merchantAnalyticsDailyAverage(
                    averagePerDay.toStringAsFixed(averagePerDay >= 10 ? 0 : 1),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                MerchantAnalyticsDeltaBadge(deltaPercent: deltaPercent),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 84,
              child: values.every((value) => value == 0)
                  ? Center(
                      child: Text(
                        l10n.merchantNoChartActivity,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : CustomPaint(
                      painter: MerchantAnalyticsSimpleLineChartPainter(
                        values: values,
                        lineColor: accent,
                        guideColor: Theme.of(context).colorScheme.outline,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class MerchantAnalyticsDayBadge extends StatelessWidget {
  final String label;
  final MerchantDailyPoint? point;
  final Color accent;
  final int Function(MerchantDailyPoint point) valueSelector;

  const MerchantAnalyticsDayBadge({
    super.key,
    required this.label,
    required this.point,
    required this.accent,
    this.valueSelector = _defaultValueSelector,
  });

  static int _defaultValueSelector(MerchantDailyPoint point) => point.views;

  @override
  Widget build(BuildContext context) {
    final text = point == null
        ? '-'
        : '${point!.dateKey} • ${valueSelector(point!)}';

    return MerchantDashboardCardShell(
      backgroundColor: accent.withAlpha(16),
      borderColor: accent.withAlpha(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class MerchantAnalyticsSimpleLineChartPainter extends CustomPainter {
  final List<int> values;
  final Color lineColor;
  final Color guideColor;

  MerchantAnalyticsSimpleLineChartPainter({
    required this.values,
    required this.lineColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final guidePaint = Paint()
      ..color = guideColor.withAlpha(90)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );

    final maxValue = values.reduce(math.max).toDouble();
    final minValue = values.reduce(math.min).toDouble();
    final valueRange = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : (maxValue - minValue);
    final usableHeight = math.max(1.0, size.height - 8);
    final stepX = values.length <= 1 ? 0.0 : size.width / (values.length - 1);

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final normalized = (values[index] - minValue) / valueRange;
      final x = stepX * index;
      final y = size.height - 4 - (normalized * usableHeight);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      linePath.lineTo(points[index].dx, points[index].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withAlpha(56), lineColor.withAlpha(8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(points.first, 2.8, dotPaint);
    if (points.length > 1) {
      canvas.drawCircle(points.last, 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(
    covariant MerchantAnalyticsSimpleLineChartPainter oldDelegate,
  ) {
    if (oldDelegate.lineColor != lineColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.values.length != values.length) {
      return true;
    }
    for (var index = 0; index < values.length; index++) {
      if (oldDelegate.values[index] != values[index]) {
        return true;
      }
    }
    return false;
  }
}
