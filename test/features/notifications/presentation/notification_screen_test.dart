import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:wain_app/features/notifications/presentation/screens/notification_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Scaffold(
            body: Text('offers-target:${extra?['highlight'] ?? ''}'),
          );
        },
      ),
      GoRoute(
        path: '/merchant/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Text('dashboard-target')),
      ),
      GoRoute(
        path: '/merchant/wallet',
        builder: (context, state) =>
            const Scaffold(body: Text('wallet-target')),
      ),
      GoRoute(
        path: '/merchant/stories',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Scaffold(
            body: Text('stories-target:${extra?['highlight'] ?? ''}'),
          );
        },
      ),
      GoRoute(
        path: '/admin/topups',
        builder: (context, state) =>
            const Scaffold(body: Text('admin-topups-target')),
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
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
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

      expect(find.textContaining('offers-target:'), findsOneWidget);
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

    testWidgets(
      'wallet notifications show wallet hint and navigate to wallet',
      (tester) async {
        await tester.pumpWidget(
          _buildNotificationApp(
            notifications: [
              {
                'id': 'n3',
                'type': 'wallet_low_balance',
                'title': 'رصيد وين منخفض',
                'body': 'اشحن المحفظة',
                'is_read': false,
                'created_at': Timestamp.now(),
                'data': {'request_id': 'wallet-low-1'},
              },
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('اضغط لفتح تفاصيل الرصيد وسجل الحركات'),
          findsOneWidget,
        );

        await tester.tap(find.text('رصيد وين منخفض'));
        await tester.pumpAndSettle();

        expect(find.text('wallet-target'), findsOneWidget);
      },
    );

    testWidgets('admin top-up notifications navigate to admin review queue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildNotificationApp(
          notifications: [
            {
              'id': 'n4',
              'type': 'wallet_topup_request_created',
              'title': 'طلب شحن جديد',
              'body': 'يوجد طلب شحن جديد',
              'is_read': true,
              'created_at': Timestamp.now(),
              'data': {'request_id': 'topup-1'},
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اضغط لمراجعة طلبات الشحن المعلقة'), findsOneWidget);

      await tester.tap(find.text('طلب شحن جديد'));
      await tester.pumpAndSettle();

      expect(find.text('admin-topups-target'), findsOneWidget);
    });

    testWidgets('story expiry reminders navigate to merchant stories', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildNotificationApp(
          notifications: [
            {
              'id': 'n5',
              'type': 'wallet_story_promotion_expiring',
              'title': 'سينتهي ترويج الستوري قريبًا',
              'body': 'جدّد الترويج إذا لزم',
              'is_read': false,
              'created_at': Timestamp.now(),
              'data': {'story_id': 'story-1'},
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('اضغط لمراجعة الستوري المروجة قبل انتهاء صلاحيتها'),
        findsOneWidget,
      );

      await tester.tap(find.text('سينتهي ترويج الستوري قريبًا'));
      await tester.pumpAndSettle();

      expect(find.text('stories-target:story-1'), findsOneWidget);
    });

    testWidgets('offer expiry reminders navigate to merchant offers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildNotificationApp(
          notifications: [
            {
              'id': 'n6',
              'type': 'wallet_offer_pin_expiring',
              'title': 'سينتهي تمييز العرض قريبًا',
              'body': 'جدّد التمييز إذا لزم',
              'is_read': false,
              'created_at': Timestamp.now(),
              'data': {'offer_id': 'offer-1'},
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('اضغط لمراجعة العروض المميزة قبل انتهاء صلاحيتها'),
        findsOneWidget,
      );

      await tester.tap(find.text('سينتهي تمييز العرض قريبًا'));
      await tester.pumpAndSettle();

      expect(find.text('offers-target:offer-1'), findsOneWidget);
    });
  });
}
