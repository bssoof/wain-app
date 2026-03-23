import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Unified empty state widget.
/// Shows a clear message, icon, and optional CTA.
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

  static AppEmptyState noResults(
    BuildContext context, {
    VoidCallback? onClearFilters,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      message: l10n.emptyNoResults,
      actionLabel: l10n.emptyNoResultsAction,
      onAction: onClearFilters,
    );
  }

  static AppEmptyState noFavorites(
    BuildContext context, {
    VoidCallback? onExplore,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.favorite_border_rounded,
      message: l10n.emptyNoFavorites,
      actionLabel: l10n.emptyNoFavoritesAction,
      onAction: onExplore,
    );
  }

  static AppEmptyState noReviews(
    BuildContext context, {
    VoidCallback? onAddReview,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.rate_review_outlined,
      message: l10n.emptyNoReviews,
      actionLabel: l10n.emptyNoReviewsAction,
      onAction: onAddReview,
    );
  }

  static AppEmptyState noSavedOffers(
    BuildContext context, {
    VoidCallback? onBrowse,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.local_offer_outlined,
      message: l10n.emptyNoSavedOffers,
      actionLabel: l10n.emptyNoSavedOffersAction,
      onAction: onBrowse,
    );
  }

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
    final theme = Theme.of(context);
    final iconBackground = theme.brightness == Brightness.dark
        ? AppTheme.darkSurfaceTinted
        : AppTheme.primarySurfaceColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxxl + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.secondary(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
