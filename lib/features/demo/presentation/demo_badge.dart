import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/demo_mode.dart';

/// Below this content width the message and the reset button stop sharing a
/// row. Measured against the narrowest supported surface (320 logical px),
/// which leaves the badge roughly 252px of content width.
const double _kStackBelowWidth = 280;

/// The banner that must accompany every demo surface.
///
/// Rendered inline in the content flow rather than as an overlay, so it can
/// never sit on top of the information it is describing.
class DemoModeBadge extends StatelessWidget {
  const DemoModeBadge({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (!DemoMode.isEnabled || !DemoMode.showDemoLabels) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.30),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final message = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.science_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(child: _label(scheme)),
            ],
          );

          // Side by side, the reset button leaves the message so little width
          // on a narrow screen that the Arabic text wraps into dozens of lines
          // — measured at 1012px tall on a 320px surface at textScale 1.3,
          // taller than the viewport itself. Below the threshold the two stack
          // instead, so each gets the full width.
          if (constraints.maxWidth < _kStackBelowWidth) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _DemoResetButton(),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 8),
              const _DemoResetButton(),
            ],
          );
        },
      ),
    );
  }

  /// Capped at three lines: the badge is a warning strip, and an unbounded
  /// warning that pushes the page it is warning about off screen defeats its
  /// own purpose.
  Widget _label(ColorScheme scheme) {
    return Text(
      DemoMode.badgeLabelAr,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: scheme.onSurface,
      ),
    );
  }
}

/// Returns every mutable demo surface to its starting state.
///
/// Sits on the badge so it travels with it: any screen that shows the warning
/// automatically offers the reset, and there is no screen where a presenter can
/// get stuck with dirty state before the next walkthrough.
class _DemoResetButton extends ConsumerWidget {
  const _DemoResetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPristine = ref.watch(
      demoSessionStoreProvider.select((state) => state.isPristine),
    );
    return TextButton.icon(
      key: const Key('demo_reset_button'),
      onPressed: isPristine
          ? null
          : () {
              ref.read(demoSessionStoreProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تمت إعادة ضبط وضع العرض'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.primaryColor,
      ),
      icon: const Icon(Icons.restart_alt_rounded, size: 18),
      label: const Text(
        'إعادة ضبط',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
