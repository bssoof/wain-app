import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_validation_result.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_scan_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'MerchantRedemptionSheet renders typed offer and venue previews',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MerchantRedemptionSheet(
              result: const MerchantValidationResult(
                valid: true,
                canRedeem: true,
                offer: MerchantValidationOfferPreview(
                  titleAr: 'عرض خاص',
                  discountType: 'percent',
                  discountValue: 20,
                  currency: 'ILS',
                ),
                venue: MerchantValidationVenuePreview(nameAr: 'المحل'),
              ),
              onRedeem: _noopRedeem,
              onCancel: _noopCancel,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('عرض صحيح'), findsOneWidget);
      expect(find.text('عرض خاص'), findsOneWidget);
      expect(find.text('المحل'), findsOneWidget);
      expect(find.textContaining('20%'), findsOneWidget);
    },
  );
}

Future<void> _noopRedeem(double? _) async {}

void _noopCancel() {}
