import 'package:flutter/material.dart';
import '../errors/app_exceptions.dart';
import '../theme/app_theme.dart';

/// Unified error display widget.
/// Shows the user-facing Arabic message from [AppException],
/// an appropriate icon, and a retry button when the error is retryable.
class AppErrorWidget extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.exception, this.onRetry});

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
                color: _iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 36, color: _iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              exception.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            if (exception.isRetryable && onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('حاول مرة ثانية'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
    AuthException() => Icons.lock_outline_rounded,
    ReviewException() => Icons.rate_review_outlined,
    OfferException() => Icons.local_offer_outlined,
    CacheException() => Icons.save_outlined,
  };

  Color get _iconColor => switch (exception) {
    NetworkException() || AppTimeoutException() => Colors.orange.shade700,
    ServerException() => Colors.red.shade600,
    LocationPermissionException() => Colors.blue.shade600,
    NoResultsException() || VenueNotFoundException() => Colors.grey.shade600,
    _ => AppTheme.primaryColor,
  };
}
