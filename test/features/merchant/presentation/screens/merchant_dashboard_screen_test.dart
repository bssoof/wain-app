import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';

Widget _buildDashboardApp() {
  final venue = <String, dynamic>{
    'id': 'venue-1',
    'name_ar': 'Test Venue',
    'name_en': 'Test Venue',
    'lat': 31.9,
    'lng': 35.2,
    'city': 'Ramallah',
    'categories': ['Restaurant'],
    'tags': {
      'mood': ['Chill'],
      'occasion': <String>[],
      'time_of_day': <String>[],
      'meal': <String>[],
    },
    'min_price': 20,
    'max_price': 80,
    'rating': 4.2,
    'phone': '0591234567',
    'photos': <String>[],
    'hours': <String, dynamic>{},
    'is_24h': false,
  };

  return ProviderScope(
    overrides: [
      merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
      merchantVenueProvider.overrideWith((ref) async => venue),
      merchantStatsProvider.overrideWith((ref) async => MerchantStats.empty()),
      merchantOffersProvider.overrideWith((ref) async => []),
      merchantAnalyticsProvider.overrideWith(
        (ref) async => MerchantAnalytics.empty(),
      ),
      merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
      merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
      unreadNotificationsCountProvider.overrideWith((ref) => Stream.value(0)),
    ],
    child: const MaterialApp(home: MerchantDashboardScreen()),
  );
}

void main() {
  group('MerchantDashboardScreen', () {
    testWidgets('renders safely when daily analytics are empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDashboardApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
