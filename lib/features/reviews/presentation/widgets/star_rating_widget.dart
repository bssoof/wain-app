import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';

/// Interactive star rating picker widget
class StarRatingPicker extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;
  final bool interactive;

  const StarRatingPicker({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 36,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isFilled = starValue <= rating;
        final isHalf = starValue - 0.5 == rating;

        return GestureDetector(
          onTap: interactive ? () => onRatingChanged(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isHalf
                  ? Icons.star_half_rounded
                  : (isFilled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded),
              color: isFilled || isHalf ? Colors.amber : Colors.grey.shade300,
              size: starSize,
            ),
          ),
        );
      }),
    );
  }
}

/// Compact star rating display (for lists)
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1.0;
          return Icon(
            starValue <= rating
                ? Icons.star_rounded
                : (starValue - 0.5 <= rating
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            color: Colors.amber,
            size: starSize,
          );
        }),
        if (reviewCount != null) ...[
          const SizedBox(width: 6),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: starSize * 0.75,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
