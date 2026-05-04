import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_invite_result.dart';

void main() {
  group('classifyMerchantInviteFailure', () {
    test('maps not found to invalid code', () {
      expect(
        classifyMerchantInviteFailure(code: 'not-found', message: 'missing'),
        MerchantInviteResultType.invalidCode,
      );
    });

    test('maps failed precondition subtypes', () {
      expect(
        classifyMerchantInviteFailure(
          code: 'failed-precondition',
          message: 'App Check token missing',
        ),
        MerchantInviteResultType.appCheckFailed,
      );
      expect(
        classifyMerchantInviteFailure(
          code: 'failed-precondition',
          message: 'invite expired yesterday',
        ),
        MerchantInviteResultType.codeExpired,
      );
      expect(
        classifyMerchantInviteFailure(
          code: 'failed-precondition',
          message: 'invite already used',
        ),
        MerchantInviteResultType.codeUsed,
      );
      expect(
        classifyMerchantInviteFailure(
          code: 'failed-precondition',
          message: 'invite unavailable',
        ),
        MerchantInviteResultType.codeUnavailable,
      );
    });

    test('maps explicit function codes and fallback', () {
      expect(
        classifyMerchantInviteFailure(
          code: 'resource-exhausted',
          message: 'too many requests',
        ),
        MerchantInviteResultType.rateLimited,
      );
      expect(
        classifyMerchantInviteFailure(code: 'aborted', message: 'cancelled'),
        MerchantInviteResultType.aborted,
      );
      expect(
        classifyMerchantInviteFailure(
          code: 'unauthenticated',
          message: 'login required',
        ),
        MerchantInviteResultType.unauthenticated,
      );
      expect(
        classifyMerchantInviteFailure(code: 'internal', message: 'boom'),
        MerchantInviteResultType.connectionError,
      );
    });
  });
}
