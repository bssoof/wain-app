import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Unified empty state widget.
/// Shows a clear message + icon + optional CTA when a list/section has no data.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Empty search results
  factory AppEmptyState.noResults({VoidCallback? onClearFilters}) =>
      AppEmptyState(
        icon: Icons.search_off_rounded,
        message: 'لا توجد نتائج مطابقة، جرّب تعديل الفلاتر',
        actionLabel: 'تعديل الفلاتر',
        onAction: onClearFilters,
      );

  /// Empty favorites list
  factory AppEmptyState.noFavorites({VoidCallback? onExplore}) => AppEmptyState(
    icon: Icons.favorite_border_rounded,
    message: 'لا يوجد أماكن مفضلة بعد',
    actionLabel: 'استكشف أماكن',
    onAction: onExplore,
  );

  /// Empty reviews
  factory AppEmptyState.noReviews({VoidCallback? onAddReview}) => AppEmptyState(
    icon: Icons.rate_review_outlined,
    message: 'لا توجد تقييمات بعد',
    actionLabel: 'أضف تقييم',
    onAction: onAddReview,
  );

  /// Empty saved offers
  factory AppEmptyState.noSavedOffers({VoidCallback? onBrowse}) =>
      AppEmptyState(
        icon: Icons.local_offer_outlined,
        message: 'لا يوجد عروض محفوظة بعد',
        actionLabel: 'تصفح العروض',
        onAction: onBrowse,
      );

  /// Offline fallback
  factory AppEmptyState.offline({VoidCallback? onRefresh}) => AppEmptyState(
    icon: Icons.signal_wifi_off_rounded,
    message: 'تعذر تحميل بيانات جديدة، تعرض نسخة محفوظة',
    actionLabel: 'تحديث',
    onAction: onRefresh,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor.withAlpha(80)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
