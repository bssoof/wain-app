import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/offers/data/repositories/offers_repository.dart';

void main() {
  group('normalizeClaimError', () {
    test('maps App Check failures to app_check_failed', () {
      expect(
        normalizeClaimError(
          code: 'failed-precondition',
          message: 'App Check verification failed',
        ),
        'app_check_failed',
      );
    });

    test('maps known duplicate claim failures to offer_already_used', () {
      expect(
        normalizeClaimError(
          code: 'failed-precondition',
          message: 'offer_already_used',
        ),
        'offer_already_used',
      );
    });

    test('does not treat unknown failed-precondition as already used', () {
      expect(
        normalizeClaimError(
          code: 'failed-precondition',
          message: 'offer_missing_venue',
        ),
        'claim_save_failed',
      );
    });
  });
}
