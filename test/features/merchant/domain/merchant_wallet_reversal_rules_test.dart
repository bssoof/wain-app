import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_reversal_request.dart';
import 'package:wain_app/features/merchant/domain/services/merchant_wallet_reversal_rules.dart';

MerchantWalletEntry _entry({
  String id = 'entry-1',
  String type = 'debit',
  String? featureKey = 'story_promotion',
  String? reversalEntryId,
}) {
  return MerchantWalletEntry(
    id: id,
    type: type,
    amount: 12,
    currency: 'ILS',
    balanceAfter: 20,
    featureKey: featureKey,
    reversalEntryId: reversalEntryId,
    createdAt: DateTime(2026, 5, 12),
  );
}

MerchantWalletReversalRequest _request({
  String entryId = 'entry-1',
  ReversalRequestStatus status = ReversalRequestStatus.pendingReview,
}) {
  return MerchantWalletReversalRequest(
    requestId: 'request-1',
    source: ReversalRequestSource.merchant,
    status: status,
    venueId: 'venue-1',
    entryId: entryId,
    originalAmount: 12,
    currency: 'ILS',
    originalFeatureKey: 'story_promotion',
    requestedByUid: 'merchant-1',
    reason: 'duplicate debit',
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
  );
}

void main() {
  group('canRequestWalletEntryReview', () {
    test('returns true for reversible debit without active request', () {
      expect(
        canRequestWalletEntryReview(
          entry: _entry(),
          existingRequests: const [],
        ),
        isTrue,
      );
    });

    test('returns false for credit entries', () {
      expect(
        canRequestWalletEntryReview(
          entry: _entry(type: 'credit'),
          existingRequests: const [],
        ),
        isFalse,
      );
    });

    test('returns false for unsupported features', () {
      expect(
        canRequestWalletEntryReview(
          entry: _entry(featureKey: 'manual_adjustment'),
          existingRequests: const [],
        ),
        isFalse,
      );
    });

    test('returns false for already reversed entries', () {
      expect(
        canRequestWalletEntryReview(
          entry: _entry(reversalEntryId: 'reversal_entry-1'),
          existingRequests: const [],
        ),
        isFalse,
      );
    });

    test('returns false when a pending review exists', () {
      expect(
        canRequestWalletEntryReview(
          entry: _entry(),
          existingRequests: [_request()],
        ),
        isFalse,
      );
    });
  });
}
