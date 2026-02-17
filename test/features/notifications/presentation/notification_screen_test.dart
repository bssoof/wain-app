import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:wain_app/features/notifications/presentation/screens/notification_screen.dart';

class _NoopNotificationActions extends NotificationActions {
  _NoopNotificationActions(super.ref);

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}
}

Widget _buildNotificationApp({
  required List<Map<String, dynamic>> notifications,
}) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/merchant/offers',
        builder: (context, state) =>
            const Scaffold(body: Text('offers-target')),
      ),
      GoRoute(
        path: '/merchant/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('dashboard-target')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userNotificationsProvider.overrideWith(
        (ref) => Stream.value(notifications),
      ),
      notificationActionsProvider.overrideWith(
        (ref) => _NoopNotificationActions(ref),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('NotificationScreen', () {
    testWidgets('tapping offer_redeemed notification navigates to offers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildNotificationApp(
          notifications: [
            {
              'id': 'n1',
              'type': 'offer_redeemed',
              'title': 'Offer redeemed',
              'body': 'A user redeemed an offer',
              'is_read': true,
              'created_at': Timestamp.now(),
              'data': {'offer_id': 'offer-1'},
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Offer redeemed'));
      await tester.pumpAndSettle();

      expect(find.text('offers-target'), findsOneWidget);
    });

    testWidgets('tapping welcome notification navigates to dashboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildNotificationApp(
          notifications: [
            {
              'id': 'n2',
              'type': 'welcome',
              'title': 'Welcome',
              'body': 'Welcome to merchant dashboard',
              'is_read': true,
              'created_at': Timestamp.now(),
              'data': const {},
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Welcome'));
      await tester.pumpAndSettle();

      expect(find.text('dashboard-target'), findsOneWidget);
    });
  });
}
