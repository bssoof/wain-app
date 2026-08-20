import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_spacing.dart';

class VenuePhotoPageIndicator extends StatelessWidget {
  const VenuePhotoPageIndicator({
    super.key,
    required this.photoCount,
    required this.currentIndex,
  });

  static const int _maxVisibleDots = 7;

  final int photoCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (photoCount < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final visibleCount = photoCount > _maxVisibleDots
        ? _maxVisibleDots
        : photoCount;
    final maxStart = photoCount - visibleCount;
    final start = (currentIndex - (visibleCount ~/ 2)).clamp(0, maxStart);

    return Semantics(
      container: true,
      value: '${currentIndex + 1}/$photoCount',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(92),
          borderRadius: AppSpacing.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(visibleCount, (offset) {
            final index = start + offset;
            final isActive = index == currentIndex;
            return AnimatedContainer(
              key: ValueKey('venue-photo-dot-$index'),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: isActive ? 18 : 7,
              height: 7,
              margin: EdgeInsetsDirectional.only(
                end: offset == visibleCount - 1 ? 0 : AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surface.withAlpha(140),
                borderRadius: AppSpacing.radiusFull,
              ),
            );
          }),
        ),
      ),
    );
  }
}
