import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/features/stories/presentation/widgets/stories_bar.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Home Screen - "مش عارف وين تروح؟" with illustration
/// Entry point to question flow
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _brandPink = Color(0xFFC0006F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header (light background strip) ──
            Container(
              color: const Color(0xFFF2F2F7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Image.asset(
                    'assets/icons/logo.png',
                    height: 32,
                    errorBuilder: (_, _, _) => const Text(
                      'Wain',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _brandPink,
                      ),
                    ),
                  ),
                  // Profile & Settings
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.grey, size: 20),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 24),
                        onPressed: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Promoted Stories Bar (on light background) ──
            Container(
              color: const Color(0xFFF2F2F7),
              child: const StoriesBar(),
            ),

            // ── Pink Wavy Section + Bottom Card (stacked) ──
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Pink wavy background — fills most of area
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WavyPinkPainter(),
                    ),
                  ),

                  // Title + Illustration content (in the pink area)
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    bottom: 180 + bottomPadding,
                    child: Column(
                      children: [
                        // Title
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            l10n.homeHeading,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Mascot illustration
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Image.asset(
                              'assets/images/Group 2.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.explore,
                                size: 120,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom White Card (overlaps the wave) ──
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 32 + bottomPadding),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.homeSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Buttons row
                          Row(
                            children: [
                              // "يلا نبدأ" button (primary, larger)
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/question-flow'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandPink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    l10n.homeStart,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // "لا شكراً" button (secondary, smaller)
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/map'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    foregroundColor: Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    l10n.homeNoThanks,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
    );
  }
}

/// Painter for the wavy pink background section.
/// Draws an organic blob shape with wavy top and bottom edges.
class _WavyPinkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC0006F)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // ── Start at top-left, slightly below top ──
    path.moveTo(0, h * 0.04);

    // ── Top edge: smooth concave wave (dips in center, rises at sides) ──
    path.cubicTo(
      w * 0.25, h * 0.0,   // first control point
      w * 0.75, h * 0.0,   // second control point
      w, h * 0.04,          // end point (top-right)
    );

    // ── Right side straight down ──
    path.lineTo(w, h * 0.78);

    // ── Bottom edge: pronounced wavy curve ──
    path.cubicTo(
      w * 0.80, h * 0.85,
      w * 0.65, h * 0.72,
      w * 0.50, h * 0.78,
    );
    path.cubicTo(
      w * 0.35, h * 0.84,
      w * 0.20, h * 0.72,
      0, h * 0.78,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
