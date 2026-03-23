import 'package:flutter/material.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Unified error display widget with retry support when applicable.
class AppErrorWidget extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.exception, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                color: _iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 36, color: _iconColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              exception.localizedMessage(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
            ),
            if (exception.isRetryable && onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                onPressed: onRetry,
                label: l10n.retryButton,
                icon: const Icon(Icons.refresh, size: 18),
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (exception) {
    NetworkException() => Icons.wifi_off_rounded,
    AppTimeoutException() => Icons.hourglass_bottom_rounded,
    ServerException() => Icons.cloud_off_rounded,
    LocationPermissionException() => Icons.location_off_rounded,
    VenueNotFoundException() => Icons.storefront_outlined,
    NoResultsException() => Icons.search_off_rounded,
    AppAuthException() => Icons.lock_outline_rounded,
    ReviewException() => Icons.rate_review_outlined,
    OfferException() => Icons.local_offer_outlined,
    CacheException() => Icons.save_outlined,
  };

  Color get _iconColor => switch (exception) {
    NetworkException() || AppTimeoutException() => AppTheme.warningColor,
    ServerException() => AppTheme.errorColor,
    LocationPermissionException() => AppTheme.infoColor,
    NoResultsException() || VenueNotFoundException() => AppTheme.textSecondary,
    _ => AppTheme.primaryColor,
  };
}
