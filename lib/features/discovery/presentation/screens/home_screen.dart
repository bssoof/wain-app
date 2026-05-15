import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/double_back_to_exit.dart';
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
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _ZigZagPinkPainter()),
                    ),
                    Positioned(
                      top: AppSpacing.xxxl + AppSpacing.md,
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
                                  'assets/images/home_hero_clean.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Image.asset(
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
                            SizedBox(
                              width: double.infinity,
                              child: AppButton.primary(
                                label: l10n.homeStart,
                                onPressed: () => context.push('/question-flow'),
                              ),
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

class _ZigZagPinkPainter extends CustomPainter {
  const _ZigZagPinkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final topBase = (height * 0.062).clamp(12.0, 30.0).toDouble();
    final waveAmplitude = (height * 0.016).clamp(4.0, 10.0).toDouble();
    const waveCount = 18;
    final waveWidth = width / waveCount;

    path.moveTo(0, topBase);
    for (var i = 0; i < waveCount; i++) {
      final startX = i * waveWidth;
      final midX = startX + (waveWidth * 0.5);
      final endX = startX + waveWidth;
      final crestY = i.isEven
          ? topBase - waveAmplitude
          : topBase + waveAmplitude;
      final troughY = i.isEven
          ? topBase + waveAmplitude
          : topBase - waveAmplitude;

      path.cubicTo(
        startX + (waveWidth * 0.20),
        crestY,
        startX + (waveWidth * 0.35),
        crestY,
        midX,
        topBase,
      );
      path.cubicTo(
        startX + (waveWidth * 0.65),
        troughY,
        startX + (waveWidth * 0.80),
        troughY,
        endX,
        topBase,
      );
    }
    path.lineTo(width, height * 0.77);
    path.cubicTo(
      width * 0.78,
      height * 0.86,
      width * 0.64,
      height * 0.72,
      width * 0.50,
      height * 0.79,
    );
    path.cubicTo(
      width * 0.36,
      height * 0.86,
      width * 0.22,
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
