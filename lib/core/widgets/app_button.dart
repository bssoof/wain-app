import 'package:flutter/material.dart';

import '../../shared/widgets/wain_loading_indicator.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, tertiary, danger }

/// Shared button widget that maps to the design system hierarchy.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final double height;
  final bool expanded;
  final AppButtonVariant variant;

  const AppButton._({
    super.key,
    required this.label,
    required this.onPressed,
    required this.variant,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.expanded = true,
  });

  const AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    double height = 52,
    bool expanded = true,
  }) : this._(
         key: key,
         label: label,
         onPressed: onPressed,
         variant: AppButtonVariant.primary,
         icon: icon,
         isLoading: isLoading,
         height: height,
         expanded: expanded,
       );

  const AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    double height = 52,
    bool expanded = true,
  }) : this._(
         key: key,
         label: label,
         onPressed: onPressed,
         variant: AppButtonVariant.secondary,
         icon: icon,
         isLoading: isLoading,
         height: height,
         expanded: expanded,
       );

  const AppButton.tertiary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    double height = 44,
    bool expanded = false,
  }) : this._(
         key: key,
         label: label,
         onPressed: onPressed,
         variant: AppButtonVariant.tertiary,
         icon: icon,
         isLoading: isLoading,
         height: height,
         expanded: expanded,
       );

  const AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    bool isLoading = false,
    double height = 52,
    bool expanded = true,
  }) : this._(
         key: key,
         label: label,
         onPressed: onPressed,
         variant: AppButtonVariant.danger,
         icon: icon,
         isLoading: isLoading,
         height: height,
         expanded: expanded,
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = _buildChild();
    final effectiveOnPressed = isLoading ? null : onPressed;

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.tertiary => TextButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.danger => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withAlpha(160)),
        ),
        child: child,
      ),
    };

    if (!expanded) {
      return SizedBox(height: height, child: button);
    }

    return SizedBox(width: double.infinity, height: height, child: button);
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox.square(
        dimension: 20,
        child: WainLoadingIndicator(size: 20),
      );
    }

    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        icon!,
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
