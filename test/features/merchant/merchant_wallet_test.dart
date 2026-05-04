import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_report.dart';
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
    referenceType: featureKey == null ? 'topup_request' : 'story',
    referenceId: 'ref-1',
    note: note,
    metadata: metadata,
    createdAt: DateTime(2026, 4, 8, 10),
  );
}

MerchantWalletReport _report({
  double totalCredited = 100,
  double totalDebited = 12,
  double last30dDebited = 12,
  String? mostUsedDebitFeature = 'story_promotion',
}) {
  return MerchantWalletReport(
    venueId: 'venue-1',
    currency: 'ILS',
    totalCredited: totalCredited,
    topupTotalCredited: totalCredited,
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

void main() {
  group('MerchantWalletScreen', () {
    testWidgets('renders zero state for new wallet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
              (ref) => Stream.value(_report()),
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
      expect(find.textContaining('إجمالي الشحن'), findsOneWidget);
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
  });
}
