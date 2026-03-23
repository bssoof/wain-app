import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/double_back_to_exit.dart';
import 'package:wain_app/features/stories/presentation/widgets/stories_bar.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Discovery entry screen that keeps the current branded hero structure
/// while moving the layout onto the shared theme system.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DoubleBackToExit(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/icons/logo.png',
                        height: 32,
                        alignment: AlignmentDirectional.centerStart,
                        errorBuilder: (_, _, _) => Text(
                          'Wain',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: l10n.profileTitle,
                      child: Material(
                        color: theme.colorScheme.surface,
                        borderRadius: AppSpacing.radiusFull,
                        child: InkWell(
                          borderRadius: AppSpacing.radiusFull,
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: AppSpacing.touchTargetMin,
                            height: AppSpacing.touchTargetMin,
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.radiusFull,
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                child: StoriesBar(),
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _WavyPinkPainter()),
                    ),
                    Positioned(
                      top: AppSpacing.xxl,
                      left: 0,
                      right: 0,
                      bottom: 184 + bottomPadding,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.homeHeading,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxl,
                                ),
                                child: Image.asset(
                                  'assets/images/Group 2.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.explore_rounded,
                                    size: 120,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                          AppSpacing.xxl + bottomPadding,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.xl),
                          ),
                          boxShadow: AppShadows.overlay,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.homeSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AppButton.primary(
                                    label: l10n.homeStart,
                                    onPressed: () =>
                                        context.push('/question-flow'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: AppButton.secondary(
                                    label: l10n.homeNoThanks,
                                    onPressed: () => context.push('/map'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavyPinkPainter extends CustomPainter {
  const _WavyPinkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height * 0.04);
    path.cubicTo(width * 0.25, 0, width * 0.75, 0, width, height * 0.04);
    path.lineTo(width, height * 0.78);
    path.cubicTo(
      width * 0.80,
      height * 0.85,
      width * 0.65,
      height * 0.72,
      width * 0.50,
      height * 0.78,
    );
    path.cubicTo(
      width * 0.35,
      height * 0.84,
      width * 0.20,
      height * 0.72,
      0,
      height * 0.78,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
