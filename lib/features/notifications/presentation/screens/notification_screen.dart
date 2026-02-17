import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import '../providers/notifications_provider.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات 🔔'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: () {
              ref.read(notificationActionsProvider).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(child: Text('خطأ: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات حالياً',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] ?? false;
              final actionHint = _getActionHint(notification['type']);
              final timestamp = notification['created_at'] != null
                  ? (notification['created_at'] as dynamic).toDate()
                  : DateTime.now();

              return Dismissible(
                key: Key(notification['id']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  // Optional: Delete notification logic
                },
                child: Container(
                  color: isRead
                      ? null
                      : AppTheme.primaryColor.withValues(alpha: 0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey.shade200
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        _getIconForType(notification['type']),
                        color: isRead ? Colors.grey : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? 'إشعار جديد',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (actionHint != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            actionHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd/MM/yyyy hh:mm a').format(timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead) {
                        ref
                            .read(notificationActionsProvider)
                            .markAsRead(notification['id']);
                      }
                      _handleTap(context, notification);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'review':
        return Icons.star_rate_rounded;
      case 'offer':
        return Icons.local_offer;
      case 'offer_redeemed':
        return Icons.redeem_rounded;
      case 'welcome':
        return Icons.storefront_rounded;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  String? _getActionHint(String? type) {
    switch (type) {
      case 'review':
        return 'اضغط لفتح التقييمات والرد بسرعة';
      case 'offer':
      case 'offer_redeemed':
        return 'اضغط لفتح العروض ومتابعة الأداء';
      case 'welcome':
        return 'اضغط لفتح لوحة التاجر';
      default:
        return null;
    }
  }

  void _handleTap(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data']; // payload map

    if (type == 'review' && data != null && data['venue_id'] != null) {
      // Navigate to merchant reviews? Or just venue details?
      // Typically merchant wants to see reviews.
      context.push('/merchant/reviews');
      // Or specific review if implemented.
    } else if (type == 'offer' || type == 'offer_redeemed') {
      // Navigate to offers
      context.push('/merchant/offers');
    } else if (type == 'welcome') {
      context.push('/merchant/dashboard');
    }
  }
}
