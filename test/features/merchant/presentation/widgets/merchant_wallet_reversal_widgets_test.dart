import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_reversal_request.dart';
import 'package:wain_app/features/merchant/presentation/widgets/wallet/merchant_wallet_reversal_badge.dart';
import 'package:wain_app/features/merchant/presentation/widgets/wallet/merchant_wallet_reversal_request_sheet.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _buildApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

MerchantWalletReversalRequest _request(ReversalRequestStatus status) {
  return MerchantWalletReversalRequest(
    requestId: 'request-1',
    source: ReversalRequestSource.merchant,
    status: status,
    venueId: 'venue-1',
    entryId: 'entry-1',
    originalAmount: 12,
    currency: 'ILS',
    originalFeatureKey: 'story_promotion',
    requestedByUid: 'merchant-1',
    reason: 'duplicate debit',
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
  );
}

MerchantWalletEntry _entry() {
  return MerchantWalletEntry(
    id: 'entry-1',
    type: 'debit',
    amount: 12,
    currency: 'ILS',
    balanceAfter: 20,
    featureKey: 'story_promotion',
    createdAt: DateTime(2026, 5, 12),
  );
}

void main() {
  testWidgets('shows pending review badge', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MerchantWalletReversalBadge(
          request: _request(ReversalRequestStatus.pendingReview),
        ),
      ),
    );

    expect(find.text('قيد المراجعة'), findsOneWidget);
  });

  testWidgets('shows approved reversal badge', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MerchantWalletReversalBadge(
          request: _request(ReversalRequestStatus.approvedAndExecuted),
        ),
      ),
    );

    expect(find.text('تم التصحيح'), findsOneWidget);
  });

  testWidgets('keeps submit disabled for empty reason', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      _buildApp(
        MerchantWalletReversalRequestSheet(
          venueId: 'venue-1',
          entry: _entry(),
          onSubmit: ({required reason, note}) async {
            submitted = true;
          },
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('wallet-reversal-submit-button')),
    );
    expect(button.onPressed, isNull);
    expect(submitted, isFalse);
    expect(find.text('اكتب 10 أحرف على الأقل لتفعيل الإرسال'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
  });

  testWidgets('enables submit once reason reaches minimum length', (
    tester,
  ) async {
    String? submittedReason;
    await tester.pumpWidget(
      _buildApp(
        MerchantWalletReversalRequestSheet(
          venueId: 'venue-1',
          entry: _entry(),
          onSubmit: ({required reason, note}) async {
            submittedReason = reason;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('wallet-reversal-reason-field')),
      'خصم متكرر مرة',
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('wallet-reversal-submit-button')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('10/10'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('wallet-reversal-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(submittedReason, 'خصم متكرر مرة');
  });
}
