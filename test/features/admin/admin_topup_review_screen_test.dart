import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/admin/data/repositories/admin_topup_review_repository.dart';
import 'package:wain_app/features/admin/data/repositories/admin_wallet_audit_repository.dart';
import 'package:wain_app/features/admin/domain/entities/wallet_audit_event.dart';
import 'package:wain_app/features/admin/presentation/screens/admin_topup_review_screen.dart';
import 'package:wain_app/features/admin/presentation/screens/admin_wallet_audit_screen.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/presentation/widgets/wallet/merchant_topup_request_sheet.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class _FakeAdminRepo implements AdminTopUpReviewRepository {
  final List<MerchantTopUpRequest> pending;
  _FakeAdminRepo({this.pending = const []});

  @override
  Future<bool> isCurrentUserAdmin() async => true;

  @override
  Future<void> reviewRequest({
    required String requestId,
    required String decision,
    String? adminNote,
  }) async {}

  @override
  Stream<List<MerchantTopUpRequest>> streamPendingRequests() =>
      Stream.value(pending);
}

class _FakeAdminWalletAuditRepo implements AdminWalletAuditRepository {
  final List<WalletAuditEvent> events;
  final Duration reverseDelay;
  int reverseCalls = 0;

  _FakeAdminWalletAuditRepo({
    required this.events,
    this.reverseDelay = Duration.zero,
  });

  @override
  Stream<List<WalletAuditEvent>> streamAuditEvents({
    String? venueId,
    String? eventType,
  }) {
    final filtered = events.where((event) {
      if (eventType != null &&
          eventType.isNotEmpty &&
          event.eventType != eventType) {
        return false;
      }
      if (venueId != null && venueId.isNotEmpty && event.venueId != venueId) {
        return false;
      }
      return true;
    }).toList();
    return Stream.value(filtered);
  }

  @override
  Future<void> reverseWalletEntry({
    required String entryId,
    required String venueId,
    required String reason,
    String? adminNote,
  }) async {
    reverseCalls += 1;
    if (reverseDelay > Duration.zero) {
      await Future<void>.delayed(reverseDelay);
    }
  }
}

MerchantTopUpRequest _pendingRequest() {
  return MerchantTopUpRequest(
    id: 'req-1',
    venueId: 'venue-1',
    requestedByUid: 'merchant-1',
    amount: 100,
    currency: 'ILS',
    proofImageUrl: null,
    transferReference: 'BANK-11',
    note: 'proof attached',
    status: TopUpRequestStatus.pending,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('admin queue renders pending requests', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(pending: [_pendingRequest()]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminTopUpReviewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('طابور مراجعة طلبات الشحن'), findsOneWidget);
    expect(find.text('100.00 ILS'), findsOneWidget);
    expect(find.textContaining('venue-1'), findsOneWidget);
    expect(find.text('اعتماد'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('topup request sheet shows receipt preview when image exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: MerchantTopUpRequestSheet(
            proofPreviewOverride: const SizedBox(
              key: Key('proof-preview'),
              height: 40,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('proof-preview')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('admin wallet audit screen renders filters and rows', (
    tester,
  ) async {
    final auditRepo = _FakeAdminWalletAuditRepo(
      events: [
        WalletAuditEvent(
          id: 'audit-1',
          eventType: 'wallet_entry',
          category: 'wallet_entry',
          venueId: 'venue-1',
          requestId: 'req-1',
          linkedEntryId: 'entry-1',
          entryId: 'entry-1',
          type: 'debit',
          featureKey: 'story_promotion',
          createdAt: DateTime(2026, 4, 8, 12),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(pending: [_pendingRequest()]),
          ),
          adminWalletAuditRepositoryProvider.overrideWithValue(auditRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminWalletAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تدقيق الرصيد'), findsOneWidget);
    expect(find.text('نوع الحدث'), findsOneWidget);
    expect(find.textContaining('req-1'), findsOneWidget);
    expect(find.text('عكس الحركة'), findsOneWidget);
  });

  testWidgets('admin wallet audit screen filter changes event type', (
    tester,
  ) async {
    final auditRepo = _FakeAdminWalletAuditRepo(
      events: [
        WalletAuditEvent(
          id: 'audit-1',
          eventType: 'wallet_entry',
          category: 'wallet_entry',
          venueId: 'venue-1',
          requestId: 'req-1',
          linkedEntryId: 'entry-1',
          entryId: 'entry-1',
          type: 'debit',
          featureKey: 'offer_pin',
          createdAt: DateTime(2026, 4, 8, 12),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(),
          ),
          adminWalletAuditRepositoryProvider.overrideWithValue(auditRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminWalletAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('offer_pin').last);
    await tester.pumpAndSettle();

    expect(find.text('offer_pin'), findsWidgets);
  });

  testWidgets('reversal dialog requires reason and submits on confirm', (
    tester,
  ) async {
    final auditRepo = _FakeAdminWalletAuditRepo(
      events: [
        WalletAuditEvent(
          id: 'audit-2',
          eventType: 'wallet_entry',
          category: 'wallet_entry',
          venueId: 'venue-1',
          entryId: 'entry-2',
          type: 'debit',
          featureKey: 'story_promotion',
          createdAt: DateTime(2026, 4, 8, 12),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(),
          ),
          adminWalletAuditRepositoryProvider.overrideWithValue(auditRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminWalletAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('عكس الحركة'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تأكيد العكس'));
    await tester.pumpAndSettle();
    expect(auditRepo.reverseCalls, 0);
    expect(find.text('السبب مطلوب'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'mistake');
    await tester.tap(find.text('تأكيد العكس'));
    await tester.pumpAndSettle();
    expect(auditRepo.reverseCalls, 1);
  });

  testWidgets('reversal confirm enters loading state while submit is running', (
    tester,
  ) async {
    final auditRepo = _FakeAdminWalletAuditRepo(
      events: [
        WalletAuditEvent(
          id: 'audit-4',
          eventType: 'wallet_entry',
          category: 'wallet_entry',
          venueId: 'venue-1',
          entryId: 'entry-4',
          type: 'debit',
          featureKey: 'story_promotion',
          createdAt: DateTime(2026, 4, 8, 12),
        ),
      ],
      reverseDelay: const Duration(milliseconds: 300),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(),
          ),
          adminWalletAuditRepositoryProvider.overrideWithValue(auditRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminWalletAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('عكس الحركة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'operator fix');
    await tester.tap(find.text('تأكيد العكس'));
    await tester.pump(const Duration(milliseconds: 50));

    final confirmButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(confirmButton.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  });

  testWidgets('already reversed row does not show reversal CTA', (
    tester,
  ) async {
    final auditRepo = _FakeAdminWalletAuditRepo(
      events: [
        WalletAuditEvent(
          id: 'audit-3',
          eventType: 'wallet_entry',
          category: 'wallet_entry',
          venueId: 'venue-1',
          entryId: 'entry-3',
          type: 'debit',
          featureKey: 'offer_pin',
          reversalEntryId: 'reversal_entry-3',
          createdAt: DateTime(2026, 4, 8, 12),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(),
          ),
          adminWalletAuditRepositoryProvider.overrideWithValue(auditRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminWalletAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عكس الحركة'), findsNothing);
    expect(find.text('تم العكس'), findsWidgets);
  });

  testWidgets('admin wallet audit empty state renders clearly', (tester) async {
    final auditRepo = _FakeAdminWalletAuditRepo(events: const []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminTopUpReviewRepositoryProvider.overrideWithValue(
            _FakeAdminRepo(),
          ),
          adminWalletAuditRepositoryProvider.overrideWithValue(auditRepo),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminWalletAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد أحداث تدقيق رصيد بعد.'), findsOneWidget);
    expect(
      find.text('سيظهر السجل هنا بعد حدوث أول حركة مالية.'),
      findsOneWidget,
    );
  });
}
