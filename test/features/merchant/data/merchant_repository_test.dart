import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';

void main() {
  group('merchant validation payload mapping', () {
    test('maps nested offer and venue previews safely', () {
      final result = mapMerchantValidationResult({
        'valid': true,
        'reason': null,
        'claimId': 'claim-1',
        'canRedeem': true,
        'offer': {
          'title_ar': 'عرض رمضان',
          'discount_type': 'percent',
          'discount_value': 25,
          'currency': 'ILS',
        },
        'venue': {'name_ar': 'المحل'},
      });

      expect(result.valid, isTrue);
      expect(result.claimId, 'claim-1');
      expect(result.canRedeem, isTrue);
      expect(result.offer?.titleAr, 'عرض رمضان');
      expect(result.offer?.discountType, 'percent');
      expect(result.offer?.discountValue, 25);
      expect(result.offer?.currency, 'ILS');
      expect(result.venue?.nameAr, 'المحل');
    });

    test('handles missing nested payloads without crashing', () {
      final result = mapMerchantValidationResult({
        'valid': false,
        'reason': 'already_redeemed',
      });

      expect(result.valid, isFalse);
      expect(result.reason, 'already_redeemed');
      expect(result.offer, isNull);
      expect(result.venue, isNull);
      expect(result.canRedeem, isFalse);
    });
  });
}
