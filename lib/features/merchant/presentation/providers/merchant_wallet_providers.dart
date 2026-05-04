import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/merchant_wallet_repository.dart';
import '../../domain/entities/merchant_wallet.dart';
import '../../domain/entities/merchant_wallet_entry.dart';
import '../../domain/entities/merchant_wallet_report.dart';
import '../../domain/entities/merchant_topup_request.dart';
import 'merchant_dashboard_providers.dart';

final merchantWalletStreamProvider =
    StreamProvider.autoDispose<MerchantWallet?>((ref) {
      final venueId = ref.watch(merchantVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value(null);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamWallet(venueId);
    });

final merchantTopUpRequestsStreamProvider =
    StreamProvider.autoDispose<List<MerchantTopUpRequest>>((ref) {
      final venueId = ref.watch(merchantVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamTopUpRequests(venueId);
    });

final merchantWalletEntriesStreamProvider =
    StreamProvider.autoDispose<List<MerchantWalletEntry>>((ref) {
      final venueId = ref.watch(merchantVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamWalletEntries(venueId);
    });

final merchantWalletReportStreamProvider =
    StreamProvider.autoDispose<MerchantWalletReport?>((ref) {
      final venueId = ref.watch(merchantVenueIdProvider).value;
      if (venueId == null) {
        return Stream.value(null);
      }
      final repo = ref.watch(merchantWalletRepositoryProvider);
      return repo.streamWalletReport(venueId);
    });

class TopUpRequestController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submitRequest({
    required double amount,
    String? proofImageUrl,
    String? transferReference,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(merchantWalletRepositoryProvider);
      await repo.createTopUpRequest(
        amount: amount,
        proofImageUrl: proofImageUrl,
        transferReference: transferReference,
        note: note,
      );
    });
  }
}

final topUpRequestControllerProvider =
    AsyncNotifierProvider<TopUpRequestController, void>(() {
      return TopUpRequestController();
    });
