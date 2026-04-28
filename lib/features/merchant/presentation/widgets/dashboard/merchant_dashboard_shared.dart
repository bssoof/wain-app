import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';

class MerchantDashboardSectionTitle extends StatelessWidget {
  final String title;

  const MerchantDashboardSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class MerchantDashboardCardShell extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const MerchantDashboardCardShell({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: borderColor ?? colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class MerchantDashboardMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tone;

  const MerchantDashboardMetricChip({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withAlpha(16),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: tone.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantDashboardFallbackCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const MerchantDashboardFallbackCard({
    super.key,
    required this.message,
    this.icon = Icons.show_chart_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MerchantDashboardCardShell(
      backgroundColor: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
