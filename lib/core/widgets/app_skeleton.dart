import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';

/// Shimmer-style skeleton widgets that replace generic spinners.
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppTheme.darkSurfaceTinted
        : AppTheme.borderColor;
    final highlightColor = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceTintedColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

class VenueCardSkeleton extends StatelessWidget {
  const VenueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          const _ShimmerBox(width: 80, height: 80, borderRadius: 12),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ShimmerBox(width: 140, height: 16),
                SizedBox(height: AppSpacing.sm),
                _ShimmerBox(width: 100, height: 12),
                SizedBox(height: AppSpacing.sm),
                _ShimmerBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VenueDetailsSkeleton extends StatelessWidget {
  const VenueDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBox(
            width: double.infinity,
            height: 250,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShimmerBox(width: 200, height: 22),
                const SizedBox(height: AppSpacing.md),
                const _ShimmerBox(width: 140, height: 14),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: const [
                    _ShimmerBox(width: 70, height: 28, borderRadius: 14),
                    SizedBox(width: AppSpacing.sm),
                    _ShimmerBox(width: 70, height: 28, borderRadius: 14),
                    SizedBox(width: AppSpacing.sm),
                    _ShimmerBox(width: 70, height: 28, borderRadius: 14),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _ShimmerBox(
                  width: double.infinity,
                  height: 40,
                  borderRadius: 0,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _ShimmerBox(width: double.infinity, height: 60),
                const SizedBox(height: AppSpacing.md),
                const _ShimmerBox(width: double.infinity, height: 60),
                const SizedBox(height: AppSpacing.md),
                const _ShimmerBox(width: double.infinity, height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItemSkeleton extends StatelessWidget {
  const MenuItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          _ShimmerBox(width: 52, height: 52, borderRadius: 10),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 120, height: 14),
                SizedBox(height: 6),
                _ShimmerBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VenueListSkeleton extends StatelessWidget {
  final int count;

  const VenueListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => const VenueCardSkeleton(),
    );
  }
}
