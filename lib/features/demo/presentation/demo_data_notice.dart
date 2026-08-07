import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/demo/demo_mode.dart';

/// A small inline label marking one block of content as sample data.
///
/// Distinct from [DemoModeBadge], which announces the whole screen: this one
/// sits directly above the thing it describes, so a rating summary or a review
/// list can never be mistaken for real customer feedback at a glance.
class DemoDataNotice extends StatelessWidget {
  const DemoDataNotice({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (!DemoMode.isEnabled || !DemoMode.showDemoLabels) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
