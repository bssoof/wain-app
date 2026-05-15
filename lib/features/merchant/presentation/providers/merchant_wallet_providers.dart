import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/merchant_wallet_repository.dart';
import '../../domain/entities/merchant_wallet.dart';
import '../../domain/entities/merchant_wallet_entry.dart';
import '../../domain/entities/merchant_wallet_report.dart';
import '../../domain/entities/merchant_topup_request.dart';
import '../../domain/entities/merchant_wallet_reversal_request.dart';

final merchantWalletVenueIdProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final repo = ref.watch(merchantWalletRepositoryProvider);
  return repo.getCurrentMerchantVenueId();
});

final merchantWalletStreamProvider =
    StreamProvider.autoDispose<MerchantWallet?>((ref) {
      final venueId = ref.watch(merchantWalletVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value(null);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamWallet(venueId);
    });

final merchantTopUpRequestsStreamProvider =
    StreamProvider.autoDispose<List<MerchantTopUpRequest>>((ref) {
      final venueId = ref.watch(merchantWalletVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamTopUpRequests(venueId);
    });

final merchantWalletEntriesStreamProvider =
    StreamProvider.autoDispose<List<MerchantWalletEntry>>((ref) {
      final venueId = ref.watch(merchantWalletVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamWalletEntries(venueId);
    });

final merchantWalletReportStreamProvider =
    StreamProvider.autoDispose<MerchantWalletReport?>((ref) {
      final venueId = ref.watch(merchantWalletVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value(null);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamWalletReport(venueId);
    });

final merchantWalletReversalRequestsStreamProvider =
    StreamProvider.autoDispose<List<MerchantWalletReversalRequest>>((ref) {
      final venueId = ref.watch(merchantWalletVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.watchReversalRequestsForVenue(venueId);
    });

class TopUpRequestController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submitRequest({
    required double amount,
    required String requestId,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(merchantWalletRepositoryProvider);
      await repo.createTopUpRequest(
        amount: amount,
        requestId: requestId,
        proofImageUrl: proofImageUrl,
        transferReference: transferReference,
        note: note,
      );
    });
  }
}

String createTopUpRequestId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final randomPart = Random.secure().nextInt(1 << 32).toRadixString(36);
  return 'topup_${timestamp}_$randomPart';
}

final topUpRequestControllerProvider =
    AsyncNotifierProvider<TopUpRequestController, void>(() {
      return TopUpRequestController();
    });

class WalletReversalRequestController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submitRequest({
    required String venueId,
    required String entryId,
    required String reason,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(merchantWalletRepositoryProvider);
      await repo.createReversalRequest(
        venueId: venueId,
        entryId: entryId,
        reason: reason,
        note: note,
      );
    });
  }
}

final walletReversalRequestControllerProvider =
    AsyncNotifierProvider<WalletReversalRequestController, void>(() {
      return WalletReversalRequestController();
    });
