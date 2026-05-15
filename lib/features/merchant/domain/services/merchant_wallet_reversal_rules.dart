import '../entities/merchant_wallet_entry.dart';
import '../entities/merchant_wallet_reversal_request.dart';

const reversibleWalletFeatureKeys = {'story_promotion', 'offer_pin'};

const blockingReversalRequestStatuses = {
  ReversalRequestStatus.pendingReview,
  ReversalRequestStatus.pendingSecondApproval,
  ReversalRequestStatus.approvedAndExecuted,
};

bool canRequestWalletEntryReview({
  required MerchantWalletEntry entry,
  required List<MerchantWalletReversalRequest> existingRequests,
}) {
  if (entry.type != 'debit') return false;
  if (!reversibleWalletFeatureKeys.contains(entry.featureKey)) return false;
  if (entry.reversalEntryId != null &&
      entry.reversalEntryId!.trim().isNotEmpty) {
    return false;
  }

  final hasBlockingRequest = existingRequests.any((request) {
    return request.entryId == entry.id &&
        blockingReversalRequestStatuses.contains(request.status);
  });
  return !hasBlockingRequest;
}

MerchantWalletReversalRequest? reversalRequestForEntry({
  required MerchantWalletEntry entry,
  required List<MerchantWalletReversalRequest> existingRequests,
}) {
  for (final request in existingRequests) {
    if (request.entryId == entry.id) return request;
  }
  return null;
}
