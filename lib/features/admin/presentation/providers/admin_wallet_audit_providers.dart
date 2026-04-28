import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/admin/data/repositories/admin_wallet_audit_repository.dart';

class AdminWalletReversalController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> reverseEntry({
    required String entryId,
    required String venueId,
    required String reason,
    String? adminNote,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(adminWalletAuditRepositoryProvider);
      await repo.reverseWalletEntry(
        entryId: entryId,
        venueId: venueId,
        reason: reason,
        adminNote: adminNote,
      );
    });
  }
}

final adminWalletReversalControllerProvider =
    AsyncNotifierProvider<AdminWalletReversalController, void>(() {
      return AdminWalletReversalController();
    });
