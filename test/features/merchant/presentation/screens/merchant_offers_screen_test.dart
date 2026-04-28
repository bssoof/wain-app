import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_offers_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_upsert_input.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_offers_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class _FakeMerchantOffersRepository implements MerchantOffersRepository {
  String? toggledOfferId;
  MerchantOfferStatus? toggledStatus;
  String? deletedOfferId;
  MerchantOfferUpsertInput? savedInput;
  Object? pinError;
  String? pinnedOfferId;
  int? pinnedDurationDays;
  String? pinnedRequestId;

  @override
  Future<void> deleteOffer(String offerId) async {
    deletedOfferId = offerId;
  }

  @override
  Future<void> saveOffer(MerchantOfferUpsertInput input) async {
    savedInput = input;
  }

  @override
  Future<void> setOfferStatus({
    required String offerId,
    required MerchantOfferStatus status,
  }) async {
    toggledOfferId = offerId;
    toggledStatus = status;
  }

  @override
  Future<Map<int, double>> fetchOfferPinPricing() async {
    return {1: 4, 3: 9, 7: 16};
  }

  @override
  Future<void> pinOffer({
    required String offerId,
    required int durationDays,
    required String requestId,
  }) async {
    if (pinError != null) throw pinError!;
    pinnedOfferId = offerId;
    pinnedDurationDays = durationDays;
    pinnedRequestId = requestId;
  }
}

Widget _buildOffersApp(
  List<MerchantOffer> offers, {
  MerchantOffersRepository? repository,
  String? venueId,
}) {
  return ProviderScope(
    overrides: [
      merchantOffersProvider.overrideWith((ref) async => offers),
      if (repository != null)
        merchantOffersRepositoryProvider.overrideWithValue(repository),
      if (venueId != null)
        merchantVenueIdProvider.overrideWith((ref) async => venueId),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MerchantOffersScreen(),
    ),
  );
}

MerchantOffer _offer({
  required String id,
  required String titleAr,
  String descriptionAr = '',
  bool isActive = true,
  MerchantOfferStatus? status,
  DateTime? startAt,
  DateTime? endAt,
  int claimsCount = 0,
  int redeemedCount = 0,
  double? conversionRate,
  bool isFeatured = false,
  DateTime? featuredUntil,
}) {
  return MerchantOffer(
    id: id,
    venueId: 'venue-1',
    titleAr: titleAr,
    title: '',
    descriptionAr: descriptionAr,
    description: '',
    termsAr: '',
    discountType: 'percent',
    discountValue: 0,
    singleUsePerCustomer: true,
    isActive: isActive,
    startAt: startAt,
    endAt: endAt,
    status: status,
    claimsCount: claimsCount,
    redeemedCount: redeemedCount,
    conversionRate: conversionRate,
    isFeatured: isFeatured,
    featuredUntil: featuredUntil,
  );
}

void main() {
  group('MerchantOffersScreen', () {
    testWidgets(
      'shows conversion rate from conversion_rate field and ending soon badge',
      (tester) async {
        final now = DateTime.now();
        final offer = _offer(
          id: 'offer-1',
          titleAr: 'عرض تجريبي',
          descriptionAr: 'وصف العرض',
          startAt: now.subtract(const Duration(days: 1)),
          endAt: now.add(const Duration(hours: 24)),
          claimsCount: 10,
          redeemedCount: 1,
          conversionRate: 0.5,
        );

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
        final offer = _offer(
          id: 'offer-2',
          titleAr: 'عرض محسوب',
          descriptionAr: 'بدون conversion_rate',
          startAt: now.subtract(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 3)),
          claimsCount: 4,
          redeemedCount: 1,
        );

        await tester.pumpWidget(_buildOffersApp([offer]));
        await tester.pumpAndSettle();

        expect(find.textContaining('25%'), findsOneWidget);
      },
    );

    testWidgets('requires a discount value before publishing a new offer', (
      tester,
    ) async {
      await tester.pumpWidget(_buildOffersApp([]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'عرض جديد');
      final publishButton = find.widgetWithText(ElevatedButton, 'نشر العرض');
      await tester.ensureVisible(publishButton);
      await tester.pumpAndSettle();
      tester.widget<ElevatedButton>(publishButton).onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.text('أدخل قيمة الخصم'), findsOneWidget);
    });

    testWidgets('rejects percentage discounts above 100', (tester) async {
      await tester.pumpWidget(_buildOffersApp([]));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'عرض جديد');
      await tester.enterText(find.byType(TextFormField).at(2), '150');
      final publishButton = find.widgetWithText(ElevatedButton, 'نشر العرض');
      await tester.ensureVisible(publishButton);
      await tester.pumpAndSettle();
      tester.widget<ElevatedButton>(publishButton).onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.text('يجب أن تكون نسبة الخصم بين 1 و100'), findsOneWidget);
    });

    testWidgets('toggle switch routes status updates through repository', (
      tester,
    ) async {
      final repository = _FakeMerchantOffersRepository();
      final now = DateTime.now();
      final offer = _offer(
        id: 'offer-toggle',
        titleAr: 'عرض فعّال',
        descriptionAr: 'قابل للإيقاف',
        startAt: now.subtract(const Duration(days: 1)),
        endAt: now.add(const Duration(days: 3)),
      );

      await tester.pumpWidget(_buildOffersApp([offer], repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(repository.toggledOfferId, 'offer-toggle');
      expect(repository.toggledStatus, MerchantOfferStatus.paused);
    });

    testWidgets('delete action routes deletion through repository', (
      tester,
    ) async {
      final repository = _FakeMerchantOffersRepository();
      final offer = _offer(
        id: 'offer-delete',
        titleAr: 'عرض للحذف',
        descriptionAr: 'قابل للحذف',
      );

      await tester.pumpWidget(_buildOffersApp([offer], repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('نعم، احذف'));
      await tester.pumpAndSettle();

      expect(repository.deletedOfferId, 'offer-delete');
      expect(find.text('تم حذف العرض'), findsOneWidget);
    });

    testWidgets('feature dialog shows server-backed pricing options', (
      tester,
    ) async {
      final repository = _FakeMerchantOffersRepository();
      final offer = _offer(id: 'offer-feature', titleAr: 'عرض مميز');

      await tester.pumpWidget(_buildOffersApp([offer], repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تمييز العرض'));
      await tester.pumpAndSettle();

      expect(find.text('1 أيام - 4.00 شيكل'), findsOneWidget);
      expect(find.text('3 أيام - 9.00 شيكل'), findsOneWidget);
      expect(find.text('7 أيام - 16.00 شيكل'), findsOneWidget);
    });

    testWidgets('successful feature action routes pin call and shows success', (
      tester,
    ) async {
      final repository = _FakeMerchantOffersRepository();
      final offer = _offer(id: 'offer-feature-success', titleAr: 'عرض ناجح');

      await tester.pumpWidget(_buildOffersApp([offer], repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تمييز العرض'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 أيام - 9.00 شيكل'));
      await tester.pumpAndSettle();

      expect(repository.pinnedOfferId, 'offer-feature-success');
      expect(repository.pinnedDurationDays, 3);
      expect(
        repository.pinnedRequestId,
        startsWith('offer_pin_offer-feature-success_'),
      );
      expect(find.text('تم تمييز العرض بنجاح'), findsOneWidget);
    });

    testWidgets('insufficient balance shows wallet CTA message', (
      tester,
    ) async {
      final repository = _FakeMerchantOffersRepository();
      repository.pinError = Exception(
        'failed-precondition: insufficient_wallet_balance',
      );
      final offer = _offer(id: 'offer-feature-low', titleAr: 'عرض بدون رصيد');

      await tester.pumpWidget(_buildOffersApp([offer], repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تمييز العرض'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 أيام - 4.00 شيكل'));
      await tester.pumpAndSettle();

      expect(
        find.text('رصيد المحفظة غير كافٍ لتمييز هذا العرض'),
        findsOneWidget,
      );
      expect(find.text('فتح رصيد وين'), findsOneWidget);
    });

    testWidgets('renders featured badge and expiry label for featured offers', (
      tester,
    ) async {
      final featuredUntil = DateTime.now().add(const Duration(days: 10));
      final offer = _offer(
        id: 'offer-featured',
        titleAr: 'عرض مثبت',
        isFeatured: true,
        featuredUntil: featuredUntil,
      );

      await tester.pumpWidget(_buildOffersApp([offer]));
      await tester.pumpAndSettle();

      expect(find.text('مميز'), findsOneWidget);
      expect(
        find.text(
          'مميز حتى ${featuredUntil.day}/${featuredUntil.month}/${featuredUntil.year}',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.push_pin), findsWidgets);
    });

    testWidgets('shows renew feature CTA for expiring featured offer', (
      tester,
    ) async {
      final offer = _offer(
        id: 'offer-renew-expiring',
        titleAr: 'عرض يحتاج تجديد',
        isFeatured: true,
        featuredUntil: DateTime.now().add(const Duration(hours: 8)),
      );

      await tester.pumpWidget(_buildOffersApp([offer]));
      await tester.pumpAndSettle();

      expect(find.text('تجديد التمييز'), findsOneWidget);
      expect(find.text('التمييز سينتهي قريبًا'), findsOneWidget);
    });

    testWidgets(
      'expired featured offer shows explanation instead of silent renewal CTA removal',
      (tester) async {
        final offer = _offer(
          id: 'offer-expired-featured',
          titleAr: 'عرض منتهي',
          isFeatured: true,
          featuredUntil: DateTime.now().subtract(const Duration(hours: 3)),
          endAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        await tester.pumpWidget(_buildOffersApp([offer]));
        await tester.pumpAndSettle();

        expect(find.text('منتهي'), findsOneWidget);
        expect(
          find.text('انتهى هذا العرض، لذلك لا يمكن تجديد تمييزه.'),
          findsOneWidget,
        );
        expect(find.text('تجديد التمييز'), findsNothing);
      },
    );

    testWidgets('publishing a new offer routes save through repository', (
      tester,
    ) async {
      final repository = _FakeMerchantOffersRepository();

      await tester.pumpWidget(
        _buildOffersApp([], repository: repository, venueId: 'venue-123'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'عرض جديد');
      await tester.enterText(find.byType(TextFormField).at(2), '20');

      final publishButton = find.widgetWithText(ElevatedButton, 'نشر العرض');
      await tester.ensureVisible(publishButton);
      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(repository.savedInput, isNotNull);
      expect(repository.savedInput!.venueId, 'venue-123');
      expect(repository.savedInput!.titleAr, 'عرض جديد');
      expect(repository.savedInput!.discountType, 'percent');
      expect(repository.savedInput!.discountValue, 20);
      expect(repository.savedInput!.applyServerStartAtWhenMissing, isTrue);
    });
  });
}
