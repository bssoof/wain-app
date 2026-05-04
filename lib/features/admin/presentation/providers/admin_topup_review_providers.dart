import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/admin/data/repositories/admin_topup_review_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';

final adminPendingTopUpsProvider =
    StreamProvider.autoDispose<List<MerchantTopUpRequest>>((ref) {
      final repo = ref.watch(adminTopUpReviewRepositoryProvider);
      return repo.streamPendingRequests();
    });

final adminAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(adminTopUpReviewRepositoryProvider);
  return repo.isCurrentUserAdmin();
});

class AdminTopUpReviewController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> review({
    required String requestId,
    required String decision,
    String? adminNote,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(adminTopUpReviewRepositoryProvider);
      await repo.reviewRequest(
        requestId: requestId,
        decision: decision,
        adminNote: adminNote,
      );
    });
  }
}

final adminTopUpReviewControllerProvider =
    AsyncNotifierProvider<AdminTopUpReviewController, void>(() {
      return AdminTopUpReviewController();
    });
