import 'dart:io';

import 'package:wain_app/features/demo/application/demo_merchant_store.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_invite_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_wallet_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_invite_result.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_validation_result.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_entry.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_report.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet_reversal_request.dart';

class DemoMerchantWalletRepository implements MerchantWalletRepository {
  DemoMerchantWalletRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<String?> getCurrentMerchantVenueId() async => DemoMode.venueId;

  @override
  Stream<MerchantWallet?> streamWallet(String venueId) => _store.watchWallet();

  @override
  Stream<List<MerchantTopUpRequest>> streamTopUpRequests(String venueId) =>
      _store.watchTopUpRequests();

  @override
  Stream<List<MerchantWalletEntry>> streamWalletEntries(String venueId) =>
      _store.watchWalletEntries();

  @override
  Stream<MerchantWalletReport?> streamWalletReport(String venueId) =>
      _store.watchWalletReport();

  @override
  Stream<List<MerchantWalletReversalRequest>> watchReversalRequestsForVenue(
    String venueId,
  ) => _store.watchWalletReversalRequests();

  @override
  Future<void> createTopUpRequest({
    required double amount,
    String? requestId,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async => _store.createTopUpRequest(
    amount: amount,
    requestId: requestId,
    proofImageUrl: proofImageUrl,
    transferReference: transferReference,
    note: note,
  );

  @override
  Future<void> createReversalRequest({
    required String venueId,
    required String entryId,
    required String reason,
    String? note,
  }) async => _store.createWalletReversalRequest(
    venueId: venueId,
    entryId: entryId,
    reason: reason,
    note: note,
  );

  /// No Storage bucket is touched; the local URI only previews the proof.
  @override
  Future<String> uploadTopUpProof({
    required String venueId,
    required File file,
    required String fileName,
  }) async => Uri.file(file.path).toString();
}

class DemoMerchantInviteRepository implements MerchantInviteRepository {
  @override
  Future<MerchantInviteResult> redeemInviteCode(String code) async =>
      const MerchantInviteResult(
        type: MerchantInviteResultType.success,
        venueId: DemoMode.venueId,
      );
}

class DemoMerchantRepository extends MerchantRepository {
  DemoMerchantRepository(this._store);

  final DemoMerchantStore _store;

  @override
  Future<MerchantValidationResult> validateToken(String token) async =>
      _store.validateToken(token);

  @override
  Future<bool> redeemToken(String token, {double? billAmount}) async =>
      _store.redeemToken(token);
}
