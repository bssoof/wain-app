import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
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
  static AppEmptyState noResults(BuildContext context, {VoidCallback? onClearFilters}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      message: l10n.emptyNoResults,
      actionLabel: l10n.emptyNoResultsAction,
      onAction: onClearFilters,
    );
  }

  /// Empty favorites list
  static AppEmptyState noFavorites(BuildContext context, {VoidCallback? onExplore}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.favorite_border_rounded,
      message: l10n.emptyNoFavorites,
      actionLabel: l10n.emptyNoFavoritesAction,
      onAction: onExplore,
    );
  }

  /// Empty reviews
  static AppEmptyState noReviews(BuildContext context, {VoidCallback? onAddReview}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.rate_review_outlined,
      message: l10n.emptyNoReviews,
      actionLabel: l10n.emptyNoReviewsAction,
      onAction: onAddReview,
    );
  }

  /// Empty saved offers
  static AppEmptyState noSavedOffers(BuildContext context, {VoidCallback? onBrowse}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.local_offer_outlined,
      message: l10n.emptyNoSavedOffers,
      actionLabel: l10n.emptyNoSavedOffersAction,
      onAction: onBrowse,
    );
  }

  /// Offline fallback
  static AppEmptyState offline(BuildContext context, {VoidCallback? onRefresh}) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.signal_wifi_off_rounded,
      message: l10n.emptyOffline,
      actionLabel: l10n.emptyOfflineAction,
      onAction: onRefresh,
    );
  }

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
