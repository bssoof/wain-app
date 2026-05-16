import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_wallet_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_report.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_reversal_request.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_wallet_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_stories_screen.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_wallet_screen.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_wallet_card.dart';
import 'package:wain_app/features/merchant/presentation/widgets/wallet/merchant_topup_request_sheet.dart';
import 'package:wain_app/l10n/app_localizations.dart';

MerchantWallet _wallet({
  double availableBalance = 0,
  double lowBalanceThreshold = 10,
}) {
  return MerchantWallet(
    venueId: 'venue-1',
    currency: 'ILS',
    status: MerchantWalletStatus.active,
    availableBalance: availableBalance,
    lowBalanceThreshold: lowBalanceThreshold,
    createdAt: DateTime(2026, 4, 8),
    updatedAt: DateTime(2026, 4, 8),
  );
}

MerchantTopUpRequest _request({
  String id = 'request-1',
  TopUpRequestStatus status = TopUpRequestStatus.pending,
  double amount = 12.5,
  String? note = 'تحويل بنكي',
}) {
  return MerchantTopUpRequest(
    id: id,
    venueId: 'venue-1',
    requestedByUid: 'merchant-1',
    amount: amount,
    currency: 'ILS',
    note: note,
    status: status,
    createdAt: DateTime(2026, 4, 8, 10),
    updatedAt: DateTime(2026, 4, 8, 10),
  );
}

MerchantWalletEntry _entry({
  String id = 'entry-1',
  String type = 'debit',
  double amount = 3,
  String? featureKey = 'story_promotion',
  String? reversalEntryId,
  String? note = 'Story promotion (3d)',
  Map<String, dynamic> metadata = const {'duration_days': 3},
}) {
  return MerchantWalletEntry(
    id: id,
    type: type,
    amount: amount,
    currency: 'ILS',
    balanceAfter: 17,
    featureKey: featureKey,
    reversalEntryId: reversalEntryId,
    referenceType: featureKey == null ? 'topup_request' : 'story',
    referenceId: 'ref-1',
    note: note,
    metadata: metadata,
    createdAt: DateTime(2026, 4, 8, 10),
  );
}

MerchantWalletReport _report({
  double totalCredited = 100,
  double? topupTotalCredited,
  double totalDebited = 12,
  double last30dDebited = 12,
  String? mostUsedDebitFeature = 'story_promotion',
}) {
  return MerchantWalletReport(
    venueId: 'venue-1',
    currency: 'ILS',
    totalCredited: totalCredited,
    topupTotalCredited: topupTotalCredited ?? totalCredited,
    totalDebited: totalDebited,
    last30dDebited: last30dDebited,
    debitByFeature: const {'story_promotion': 3, 'offer_pin': 9},
    mostUsedDebitFeature: mostUsedDebitFeature,
    lastTopUpAmount: 100,
    lastEntryAt: DateTime(2026, 4, 8),
    updatedAt: DateTime(2026, 4, 8),
  );
}

Widget _buildApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

class _FakeStoriesRepository implements MerchantStoriesRepository {
  @override
  Future<void> createStory({
    required String venueId,
    required String text,
    required int expiryHours,
    required String? createdBy,
    image,
    video,
  }) async {}

  @override
  Future<void> deleteStory({
    required String storyId,
    String? imageUrl,
    String? videoUrl,
  }) async {}

  @override
  Future<StoryPromotionPricing> getStoryPromotionPricing() async {
    return const StoryPromotionPricing(
      currency: 'ILS',
      oneDayPrice: 1,
      threeDayPrice: 3,
      sevenDayPrice: 7,
    );
  }

  @override
  Future<bool> hasActiveStory({required String venueId, DateTime? now}) async =>
      false;

  @override
  Future<void> promoteStory({
    required String storyId,
    required int durationDays,
    required String requestId,
  }) async {}

  @override
  Stream<List<MerchantStory>> watchStories({
    required String venueId,
    int limit = 20,
  }) {
    return Stream.value(const <MerchantStory>[]);
  }
}

class _FakeMerchantWalletRepository implements MerchantWalletRepository {
  int topUpSubmitCount = 0;
  double? lastTopUpAmount;
  String? lastTopUpRequestId;
  String? lastTopUpTransferReference;

  @override
  Future<String?> getCurrentMerchantVenueId() async => 'venue-1';

  @override
  Stream<MerchantWallet?> streamWallet(String venueId) {
    return Stream.value(_wallet(availableBalance: 20));
  }

  @override
  Stream<List<MerchantTopUpRequest>> streamTopUpRequests(String venueId) {
    return Stream.value(const <MerchantTopUpRequest>[]);
  }

  @override
  Stream<List<MerchantWalletEntry>> streamWalletEntries(String venueId) {
    return Stream.value(const <MerchantWalletEntry>[]);
  }

  @override
  Stream<MerchantWalletReport?> streamWalletReport(String venueId) {
    return Stream.value(_report());
  }

  @override
  Stream<List<MerchantWalletReversalRequest>> watchReversalRequestsForVenue(
    String venueId,
  ) {
    return Stream.value(const <MerchantWalletReversalRequest>[]);
  }

  @override
  Future<void> createTopUpRequest({
    required double amount,
    String? requestId,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async {
    topUpSubmitCount += 1;
    lastTopUpAmount = amount;
    lastTopUpRequestId = requestId;
    lastTopUpTransferReference = transferReference;
  }

  @override
  Future<void> createReversalRequest({
    required String venueId,
    required String entryId,
    required String reason,
    String? note,
  }) async {}

  @override
  Future<String> uploadTopUpProof({
    required String venueId,
    required File file,
    required String fileName,
  }) async {
    return 'venues/$venueId/wallet_topups/$fileName';
  }
}

void main() {
  group('MerchantWalletScreen', () {
    testWidgets('renders zero state for new wallet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantWalletVenueIdProvider.overrideWith(
              (ref) async => 'venue-1',
            ),
            merchantWalletStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            merchantTopUpRequestsStreamProvider.overrideWith(
              (ref) => Stream.value(const <MerchantTopUpRequest>[]),
            ),
            merchantWalletEntriesStreamProvider.overrideWith(
              (ref) => Stream.value(const <MerchantWalletEntry>[]),
            ),
            merchantWalletReportStreamProvider.overrideWith(
              (ref) => Stream.value(
                _report(totalCredited: 1599, topupTotalCredited: 100),
              ),
            ),
            merchantWalletReversalRequestsStreamProvider.overrideWith(
              (ref) => Stream.value(const <MerchantWalletReversalRequest>[]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MerchantWalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('رصيد وين'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('ILS'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد طلبات شحن سابقة'), findsOneWidget);
      expect(find.text('لا توجد حركات بعد'), findsOneWidget);
    });

    testWidgets('renders wallet entries and top-up requests together', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantWalletVenueIdProvider.overrideWith(
              (ref) async => 'venue-1',
            ),
            merchantWalletStreamProvider.overrideWith(
              (ref) => Stream.value(_wallet(availableBalance: 5)),
            ),
            merchantTopUpRequestsStreamProvider.overrideWith(
              (ref) => Stream.value(<MerchantTopUpRequest>[_request()]),
            ),
            merchantWalletEntriesStreamProvider.overrideWith(
              (ref) => Stream.value(<MerchantWalletEntry>[
                _entry(),
                _entry(
                  id: 'entry-2',
                  type: 'credit',
                  amount: 100,
                  featureKey: null,
                  note: 'Approved top-up request',
                  metadata: const {},
                ),
              ]),
            ),
            merchantWalletReportStreamProvider.overrideWith(
              (ref) => Stream.value(_report()),
            ),
            merchantWalletReversalRequestsStreamProvider.overrideWith(
              (ref) => Stream.value(const <MerchantWalletReversalRequest>[]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MerchantWalletScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('انتبه! الرصيد منخفض، اشحن لتجنب توقف الميزات.'),
        findsOneWidget,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('طلبات الشحن'), findsOneWidget);
      expect(find.text('ملخص الرصيد'), findsOneWidget);
      expect(find.textContaining('إجمالي الرصيد المضاف'), findsOneWidget);
      expect(find.textContaining('منه شحن معتمد'), findsOneWidget);
      expect(find.textContaining('قيد المراجعة: 12.50 ILS'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('+100 شحن رصيد'), findsOneWidget);
      expect(find.text('-3 ترويج ستوري 3 أيام'), findsOneWidget);
    });
  });

  group('Wallet low-balance surfaces', () {
    testWidgets('dashboard wallet card shows warning state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantWalletStreamProvider.overrideWith(
              (ref) => Stream.value(_wallet(availableBalance: 4)),
            ),
          ],
          child: _buildApp(const MerchantDashboardWalletCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('انتبه! الرصيد منخفض، اشحن لتجنب توقف الميزات.'),
        findsOneWidget,
      );
    });

    testWidgets('stories screen shows low-balance reminder callout', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantStoriesRepositoryProvider.overrideWithValue(
              _FakeStoriesRepository(),
            ),
            merchantWalletStreamProvider.overrideWith(
              (ref) => Stream.value(_wallet(availableBalance: 0)),
            ),
          ],
          child: _buildApp(const MerchantStoriesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('انتبه! الرصيد منخفض، اشحن لتجنب توقف الميزات.'),
        findsOneWidget,
      );
      expect(find.text('فتح رصيد وين'), findsWidgets);
    });
  });

  group('MerchantTopUpRequestSheet', () {
    testWidgets('validates required amount before submitting', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Scaffold(body: MerchantTopUpRequestSheet())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إرسال الطلب'));
      await tester.pump();

      expect(find.text('المبلغ مطلوب'), findsOneWidget);
    });

    testWidgets('closes sheet and shows success after submit', (tester) async {
      final fakeRepo = _FakeMerchantWalletRepository();
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantWalletRepositoryProvider.overrideWithValue(fakeRepo),
            merchantWalletVenueIdProvider.overrideWith(
              (ref) async => 'venue-1',
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const MerchantTopUpRequestSheet(),
                    ),
                    child: const Text('open top-up'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open top-up'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '150');
      await tester.enterText(find.byType(TextFormField).at(1), 'QAUI001');
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pumpAndSettle();

      expect(fakeRepo.topUpSubmitCount, 1);
      expect(fakeRepo.lastTopUpAmount, 150);
      expect(fakeRepo.lastTopUpRequestId, isNotEmpty);
      expect(fakeRepo.lastTopUpTransferReference, 'QAUI001');
      expect(find.byType(MerchantTopUpRequestSheet), findsNothing);
      expect(
        find.text('✅ تم إرسال طلب الشحن بنجاح وستتم مراجعته'),
        findsOneWidget,
      );
    });
  });
}
