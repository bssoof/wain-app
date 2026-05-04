import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// A thin banner displayed when the current data is served from local cache.
///
/// Shows a connectivity icon, a brief message, and optionally the
/// time since the last successful server fetch.
class OfflineBanner extends ConsumerWidget {
  /// Override text for the banner. If null, a localized default message is used.
  final String? message;

  /// The last time data was successfully fetched from the server.
  /// Kept for optional diagnostics, but not shown by default because the
  /// banner's primary job is to explain offline fallback, not data freshness.
  final DateTime? fetchedAt;

  /// Whether to show the exact cached-copy age. Defaults to false to avoid
  /// alarming users with old-but-usable offline data such as "منذ 8 ساعات".
  final bool showCacheAge;

  /// Explicit visibility override. If omitted, the banner only appears
  /// while the device is offline.
  final bool? isVisible;

  const OfflineBanner({
    super.key,
    this.message,
    this.fetchedAt,
    this.showCacheAge = false,
    this.isVisible,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final shouldShow = isVisible ?? !isOnline;
    if (!shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bannerText = _buildBannerText(l10n: l10n, isOnline: isOnline);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.95,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildBannerText({
    required AppLocalizations l10n,
    required bool isOnline,
  }) {
    final base =
        message ??
        (isOnline
            ? l10n.offlineBannerUpdateFailed
            : l10n.offlineBannerCachedCopy);
    if (!showCacheAge || fetchedAt == null) return base;

    final elapsed = DateTime.now().difference(fetchedAt!);
    final timeAgo = _formatElapsed(elapsed, l10n);
    return '$base ($timeAgo)';
  }

  static String _formatElapsed(Duration elapsed, AppLocalizations l10n) {
    if (elapsed.inMinutes < 1) return l10n.offlineAgeNow;
    if (elapsed.inMinutes < 60) {
      return l10n.offlineAgeMinutes(elapsed.inMinutes);
    }
    if (elapsed.inHours < 24) return l10n.offlineAgeHours(elapsed.inHours);
    return l10n.offlineAgeDays(elapsed.inDays);
  }
}

/// Wraps a CTA button to disable it when offline, showing a snackbar
/// explaining that connectivity is required when tapped.
class OnlineOnlyGuard extends ConsumerWidget {
  /// The child widget (typically a button) to guard.
  final Widget child;

  /// Builder for the disabled state. If null, the child is rendered
  /// with reduced opacity and a tap-to-explain gesture.
  final Widget Function(BuildContext context)? disabledBuilder;

  /// Optional custom message for the snackbar when tapped while offline.
  final String? offlineMessage;

  const OnlineOnlyGuard({
    super.key,
    required this.child,
    this.disabledBuilder,
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return child;

    if (disabledBuilder != null) {
      return disabledBuilder!(context);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                offlineMessage ??
                    AppLocalizations.of(
                      context,
                    )!.offlineActionRequiresConnection,
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Opacity(opacity: 0.45, child: AbsorbPointer(child: child)),
    );
  }
}

/// A placeholder screen shown when the user navigates to a screen
/// that has no cached data and no connectivity.
class OfflineEmptyState extends StatelessWidget {
  /// Optional icon override (defaults to cloud_off).
  final IconData icon;

  /// Title text shown below the icon.
  final String? title;

  /// Subtitle / explanation text.
  final String? subtitle;

  const OfflineEmptyState({
    super.key,
    this.icon = Icons.cloud_off_rounded,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle = title ?? l10n.offlineEmptyTitle;
    final resolvedSubtitle = subtitle ?? l10n.offlineEmptySubtitle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              resolvedTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              resolvedSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
