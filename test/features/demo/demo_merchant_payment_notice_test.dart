import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_report.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_wallet_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_wallet_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  testWidgets('demo wallet explicitly says no real money moves', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoMerchantActiveProvider.overrideWithValue(true),
          merchantWalletStreamProvider.overrideWith(
            (ref) => Stream<MerchantWallet?>.value(null),
          ),
          merchantTopUpRequestsStreamProvider.overrideWith(
            (ref) => Stream<List<MerchantTopUpRequest>>.value(const []),
          ),
          merchantWalletEntriesStreamProvider.overrideWith(
            (ref) => Stream<List<MerchantWalletEntry>>.value(const []),
          ),
          merchantWalletReportStreamProvider.overrideWith(
            (ref) => Stream<MerchantWalletReport?>.value(null),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MerchantWalletScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('demo_wallet_local_notice')), findsOneWidget);
    expect(
      find.textContaining('لا يتم خصم أو تحويل أموال حقيقية'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
