part of 'demo_merchant_store.dart';

extension DemoMerchantWalletMutations on DemoMerchantStore {
  void createTopUpRequest({
    required double amount,
    String? requestId,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) {
    final normalizedRequestId = requestId?.trim();
    if (normalizedRequestId != null &&
        normalizedRequestId.isNotEmpty &&
        _topUpRequests.any((request) => request.id == normalizedRequestId)) {
      return;
    }
    _localTopUpSerial += 1;
    final now = demoMerchantNow();
    _topUpRequests.insert(
      0,
      MerchantTopUpRequest(
        id: normalizedRequestId?.isNotEmpty == true
            ? normalizedRequestId!
            : 'demo_topup_local_$_localTopUpSerial',
        venueId: DemoMode.venueId,
        requestedByUid: 'demo_merchant',
        amount: amount,
        currency: 'ILS',
        proofImageUrl: proofImageUrl,
        transferReference: transferReference,
        note: note,
        status: TopUpRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _notify();
  }

  void createWalletReversalRequest({
    required String venueId,
    required String entryId,
    required String reason,
    String? note,
  }) {
    if (venueId != DemoMode.venueId) {
      throw StateError('merchant_venue_mismatch');
    }
    if (_walletReversalRequests.any((request) => request.entryId == entryId)) {
      throw StateError('merchant_review_already_open');
    }
    final entry = _walletEntries.where((candidate) => candidate.id == entryId);
    if (entry.isEmpty) throw StateError('entry_not_found');

    _localWalletReversalSerial += 1;
    final now = demoMerchantNow();
    final walletEntry = entry.first;
    _walletReversalRequests.insert(
      0,
      MerchantWalletReversalRequest(
        requestId: 'demo_reversal_local_$_localWalletReversalSerial',
        source: ReversalRequestSource.merchant,
        status: ReversalRequestStatus.pendingReview,
        venueId: venueId,
        entryId: entryId,
        originalAmount: walletEntry.amount,
        currency: walletEntry.currency,
        originalFeatureKey: walletEntry.featureKey ?? '',
        requestedByUid: 'demo_merchant',
        reason: reason,
        merchantNote: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    _notify();
  }

  MerchantValidationResult validateToken(String token) {
    final result = buildDemoMerchantValidation(token);
    if (!result.valid || !_redeemedTokens.contains(token.trim())) return result;
    return MerchantValidationResult(
      valid: true,
      reason: 'already_redeemed',
      claimId: result.claimId,
      offer: result.offer,
      venue: result.venue,
      canRedeem: false,
    );
  }

  bool redeemToken(String token) {
    final normalized = token.trim();
    final result = validateToken(normalized);
    if (!result.canRedeem || !_redeemedTokens.add(normalized)) return false;
    final offerId = result.claimId?.replaceFirst('demo_claim_', '');
    if (offerId != null) {
      _replaceOffer(
        offerId,
        (offer) => _copyOffer(offer, redeemedCount: offer.redeemedCount + 1),
      );
    } else {
      _notify();
    }
    return true;
  }

  void _debit(
    double amount, {
    required String featureKey,
    required String referenceId,
  }) {
    if (amount <= 0) return;
    if (_wallet.availableBalance < amount) {
      throw StateError('insufficient_wallet_balance');
    }
    final now = demoMerchantNow();
    final balance = _wallet.availableBalance - amount;
    _localWalletEntrySerial += 1;
    _walletEntries.insert(
      0,
      MerchantWalletEntry(
        id: 'demo_wallet_local_$_localWalletEntrySerial',
        type: 'debit',
        amount: amount,
        currency: _wallet.currency,
        balanceAfter: balance,
        featureKey: featureKey,
        referenceType: featureKey,
        referenceId: referenceId,
        note: 'عملية تجريبية محلية',
        createdAt: now,
      ),
    );
    _wallet = MerchantWallet(
      venueId: _wallet.venueId,
      currency: _wallet.currency,
      status: _wallet.status,
      availableBalance: balance,
      lowBalanceThreshold: _wallet.lowBalanceThreshold,
      lastEntryAt: now,
      lastTopUpAt: _wallet.lastTopUpAt,
      createdAt: _wallet.createdAt,
      updatedAt: now,
    );
    final byFeature = Map<String, double>.of(_walletReport.debitByFeature);
    byFeature[featureKey] = (byFeature[featureKey] ?? 0) + amount;
    _walletReport = MerchantWalletReport(
      venueId: _walletReport.venueId,
      currency: _walletReport.currency,
      totalCredited: _walletReport.totalCredited,
      topupTotalCredited: _walletReport.topupTotalCredited,
      totalDebited: _walletReport.totalDebited + amount,
      last30dDebited: _walletReport.last30dDebited + amount,
      debitByFeature: byFeature,
      mostUsedDebitFeature: byFeature.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key,
      lastTopUpAmount: _walletReport.lastTopUpAmount,
      lastEntryAt: now,
      updatedAt: now,
    );
    _notify();
  }
}
