import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/notifications_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  static const Set<String> _merchantWalletNotificationTypes = {
    'wallet_topup_request_approved',
    'wallet_topup_request_rejected',
    'wallet_entry_reversed',
    'wallet_low_balance',
    'wallet_story_promotion_expiring',
    'wallet_offer_pin_expiring',
  };

  static const Set<String> _adminWalletNotificationTypes = {
    'wallet_topup_request_created',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: l10n.notificationsMarkAllRead,
            onPressed: () =>
                ref.read(notificationActionsProvider).markAllAsRead(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.notificationsError(err.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_off_outlined,
              message: l10n.notificationsEmpty,
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] as bool? ?? false;
              final timestamp = notification['created_at'] != null
                  ? (notification['created_at'] as dynamic).toDate() as DateTime
                  : DateTime.now();

              return _NotificationTile(
                tileKey: Key(
                  notification['id'] as String? ?? 'notification_$index',
                ),
                notification: notification,
                title: _getDisplayTitle(context, notification),
                body: _getDisplayBody(context, notification),
                isRead: isRead,
                timestamp: timestamp,
                actionHint: _getActionHint(
                  context,
                  notification['type'] as String?,
                ),
                icon: _getIconForType(notification['type'] as String?),
                onTap: () {
                  if (!isRead) {
                    ref
                        .read(notificationActionsProvider)
                        .markAsRead(notification['id']);
                  }
                  _handleTap(context, notification);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    if (_merchantWalletNotificationTypes.contains(type)) {
      if (type == 'wallet_story_promotion_expiring' ||
          type == 'wallet_offer_pin_expiring') {
        return Icons.schedule_rounded;
      }
      if (type == 'wallet_low_balance') {
        return Icons.account_balance_wallet_outlined;
      }
      if (type == 'wallet_entry_reversed') {
        return Icons.swap_horiz_rounded;
      }
      return Icons.account_balance_wallet_rounded;
    }
    if (_adminWalletNotificationTypes.contains(type)) {
      return Icons.receipt_long_rounded;
    }
    switch (type) {
      case 'review':
        return Icons.star_rate_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      case 'offer_redeemed':
        return Icons.redeem_rounded;
      case 'welcome':
        return Icons.storefront_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String? _getActionHint(BuildContext context, String? type) {
    if (type == 'wallet_story_promotion_expiring') {
      return AppLocalizations.of(context)!.notificationsHintWalletStoryExpiry;
    }
    if (type == 'wallet_offer_pin_expiring') {
      return AppLocalizations.of(context)!.notificationsHintWalletOfferExpiry;
    }
    if (_merchantWalletNotificationTypes.contains(type)) {
      return AppLocalizations.of(context)!.notificationsHintWallet;
    }
    if (_adminWalletNotificationTypes.contains(type)) {
      return AppLocalizations.of(context)!.notificationsHintAdminTopup;
    }
    switch (type) {
      case 'review':
        return AppLocalizations.of(context)!.notificationsHintReview;
      case 'offer':
      case 'offer_redeemed':
        return AppLocalizations.of(context)!.notificationsHintOffer;
      case 'welcome':
        return AppLocalizations.of(context)!.notificationsHintWelcome;
      default:
        return null;
    }
  }

  void _handleTap(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'];
    final rawData = notification['data'];
    final data = rawData is Map ? rawData.cast<String, dynamic>() : null;

    if (type == 'wallet_story_promotion_expiring') {
      final storyId = data?['story_id'] as String?;
      context.push(
        '/merchant/stories',
        extra: storyId == null ? null : {'highlight': storyId},
      );
    } else if (type == 'wallet_offer_pin_expiring') {
      final offerId = data?['offer_id'] as String?;
      context.push(
        '/merchant/offers',
        extra: offerId == null ? null : {'highlight': offerId},
      );
    } else if (_merchantWalletNotificationTypes.contains(type)) {
      context.push('/merchant/wallet');
    } else if (_adminWalletNotificationTypes.contains(type)) {
      context.push('/admin/topups');
    } else if (type == 'review' && data != null && data['venue_id'] != null) {
      context.push('/merchant/reviews');
    } else if (type == 'offer' || type == 'offer_redeemed') {
      context.push('/merchant/offers');
    } else if (type == 'welcome') {
      context.push('/merchant/dashboard');
    }
  }

  String _getDisplayTitle(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    if (notification['type'] == 'welcome') {
      return _localizedCopy(
        context,
        ar: 'مرحباً بك كتاجر!',
        en: 'Welcome as a merchant!',
      );
    }

    final title = notification['title'] as String?;
    if (title == null || title.trim().isEmpty) {
      return AppLocalizations.of(context)!.notificationsNewNotif;
    }
    return title.trim();
  }

  String _getDisplayBody(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    if (notification['type'] == 'welcome') {
      return _localizedCopy(
        context,
        ar: 'تم ربط محلك بنجاح. يمكنك الآن إدارة العروض والتقييمات من لوحة التحكم.',
        en: 'Your venue was linked successfully. You can now manage offers and reviews from the dashboard.',
      );
    }

    return (notification['body'] as String?)?.trim() ?? '';
  }

  String _localizedCopy(
    BuildContext context, {
    required String ar,
    required String en,
  }) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }
}

class _NotificationTile extends StatelessWidget {
  final Key? tileKey;
  final Map<String, dynamic> notification;
  final String title;
  final String body;
  final bool isRead;
  final DateTime timestamp;
  final String? actionHint;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationTile({
    this.tileKey,
    required this.notification,
    required this.title,
    required this.body,
    required this.isRead,
    required this.timestamp,
    required this.actionHint,
    required this.icon,
    required this.onTap,
  }) : super(key: tileKey);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final backgroundColor = isRead
        ? colorScheme.surface
        : colorScheme.primaryContainer.withAlpha(120);
    final avatarColor = isRead
        ? colorScheme.surfaceContainerHighest
        : colorScheme.primaryContainer;
    final iconColor = isRead
        ? colorScheme.onSurfaceVariant
        : colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusLg,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: colorScheme.outline),
            boxShadow: AppShadows.elevated,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: AppSpacing.radiusMd,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (actionHint != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        actionHint!,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      DateFormat('dd/MM/yyyy hh:mm a').format(timestamp),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
