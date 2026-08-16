part of 'demo_merchant_store.dart';

extension DemoMerchantWalletMutations on DemoMerchantStore {
  void createTopUpRequest({
    required double amount,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) {
    _localTopUpSerial += 1;
    final now = demoMerchantNow();
    _topUpRequests.insert(
      0,
      MerchantTopUpRequest(
        id: 'demo_topup_local_$_localTopUpSerial',
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
