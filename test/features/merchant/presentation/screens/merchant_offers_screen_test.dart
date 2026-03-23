import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_offers_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _buildOffersApp(List<Map<String, dynamic>> offers) {
  return ProviderScope(
    overrides: [merchantOffersProvider.overrideWith((ref) async => offers)],
    child: const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MerchantOffersScreen(),
    ),
  );
}

void main() {
  group('MerchantOffersScreen', () {
    testWidgets(
      'shows conversion rate from conversion_rate field and ending soon badge',
      (tester) async {
        final now = DateTime.now();
        final offer = <String, dynamic>{
          'id': 'offer-1',
          'title_ar': 'عرض تجريبي',
          'description_ar': 'وصف العرض',
          'is_active': true,
          'start_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          'end_at': Timestamp.fromDate(now.add(const Duration(hours: 24))),
          // Intentionally inconsistent with redeemed/claims to verify DB conversion_rate is used.
          'claims_count': 10,
          'redeemed_count': 1,
          'conversion_rate': 0.5,
        };

        await tester.pumpWidget(_buildOffersApp([offer]));
        await tester.pumpAndSettle();

        expect(find.textContaining('50%'), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to computed conversion rate when conversion_rate is absent',
      (tester) async {
        final now = DateTime.now();
        final offer = <String, dynamic>{
          'id': 'offer-2',
          'title_ar': 'عرض محسوب',
          'description_ar': 'بدون conversion_rate',
          'is_active': true,
          'start_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          'end_at': Timestamp.fromDate(now.add(const Duration(days: 3))),
          'claims_count': 4,
          'redeemed_count': 1,
        };

        await tester.pumpWidget(_buildOffersApp([offer]));
        await tester.pumpAndSettle();

        expect(find.textContaining('25%'), findsOneWidget);
      },
    );
  });
}
