import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_performance_summary.dart';

MerchantOffer _offer({
  required String id,
  required String titleAr,
  required bool isActive,
  MerchantOfferStatus? status,
  DateTime? endAt,
  int claimsCount = 0,
  int redeemedCount = 0,
  double? conversionRate,
}) {
  return MerchantOffer(
    id: id,
    venueId: 'venue-1',
    titleAr: titleAr,
    title: '',
    descriptionAr: '',
    description: '',
    termsAr: '',
    discountType: 'percent',
    discountValue: 0,
    singleUsePerCustomer: true,
    isActive: isActive,
    startAt: null,
    endAt: endAt,
    status: status,
    claimsCount: claimsCount,
    redeemedCount: redeemedCount,
    conversionRate: conversionRate,
    isFeatured: false,
    featuredUntil: null,
  );
}

void main() {
  group('buildOfferPerformanceSummary', () {
    test('aggregates totals and weighted conversion', () {
      final summary = buildOfferPerformanceSummary([
        _offer(
          id: 'a',
          titleAr: 'عرض أ',
          isActive: true,
          claimsCount: 10,
          redeemedCount: 5,
        ),
        _offer(
          id: 'b',
          titleAr: 'عرض ب',
          isActive: true,
          claimsCount: 2,
          redeemedCount: 2,
        ),
      ], DateTime(2026, 4, 5));

      expect(summary.totalClaims, 12);
      expect(summary.totalRedeemed, 7);
      expect(summary.overallConversionPercent, closeTo(58.33, 0.01));
    });

    test('prefers active top performer before paused one', () {
      final now = DateTime(2026, 4, 5);
      final summary = buildOfferPerformanceSummary([
        _offer(
          id: 'paused',
          titleAr: 'موقوف',
          isActive: false,
          status: MerchantOfferStatus.paused,
          claimsCount: 20,
          redeemedCount: 12,
        ),
        _offer(
          id: 'active',
          titleAr: 'نشط',
          isActive: true,
          status: MerchantOfferStatus.active,
          claimsCount: 5,
          redeemedCount: 4,
        ),
      ], now);

      expect(summary.topPerformer?.id, 'active');
    });

    test('ignores offers with no activity when selecting top performer', () {
      final summary = buildOfferPerformanceSummary([
        _offer(id: 'idle', titleAr: 'خامل', isActive: true),
      ], DateTime(2026, 4, 5));

      expect(summary.topPerformer, isNull);
      expect(summary.hasAnyActivity, isFalse);
      expect(summary.overallConversionPercent, 0);
    });

    test('expired offers are ranked after active ones', () {
      final now = DateTime(2026, 4, 5);
      final summary = buildOfferPerformanceSummary([
        _offer(
          id: 'expired',
          titleAr: 'منتهي',
          isActive: true,
          status: MerchantOfferStatus.active,
          endAt: DateTime(2026, 4, 1),
          claimsCount: 100,
          redeemedCount: 90,
        ),
        _offer(
          id: 'active',
          titleAr: 'فعّال',
          isActive: true,
          status: MerchantOfferStatus.active,
          claimsCount: 10,
          redeemedCount: 8,
        ),
      ], now);

      expect(summary.topPerformer?.id, 'active');
    });
  });
}
