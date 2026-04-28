import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/try_list_repository.dart';
import '../../data/repositories/try_list_repository_impl.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

// ============ REPOSITORY PROVIDER ============

/// Provides TryListRepository instance
final tryListRepositoryProvider = Provider<TryListRepository>((ref) {
  return TryListRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

// ============ TRY LIST STATE ============

/// Holds the current list of "want to try" venue IDs
final tryListNotifierProvider =
    AsyncNotifierProvider<TryListNotifier, List<String>>(TryListNotifier.new);

class TryListNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return ref.watch(tryListRepositoryProvider).getTryList();
  }

  /// Add a venue to try list
  Future<void> add(String venueId) async {
    await ref.read(tryListRepositoryProvider).addToTryList(venueId);
    ref.invalidateSelf();
  }

  /// Remove a venue from try list
  Future<void> remove(String venueId) async {
    await ref.read(tryListRepositoryProvider).removeFromTryList(venueId);
    ref.invalidateSelf();
  }

  /// Toggle try list status
  Future<bool> toggle(String venueId) async {
    final result = await ref
        .read(tryListRepositoryProvider)
        .toggleTryList(venueId);
    ref.invalidateSelf();
    return result;
  }

  /// Sync try list to cloud
  Future<void> syncToCloud(String userId) async {
    await ref.read(tryListRepositoryProvider).syncToCloud(userId);
  }

  /// Sync try list from cloud
  Future<void> syncFromCloud(String userId) async {
    await ref.read(tryListRepositoryProvider).syncFromCloud(userId);
    ref.invalidateSelf();
  }
}

// ============ UTILITY PROVIDERS ============

/// Check if a specific venue is in try list
final isInTryListProvider = FutureProvider.family<bool, String>((
  ref,
  venueId,
) async {
  final tryList = await ref.watch(tryListNotifierProvider.future);
  return tryList.contains(venueId);
});

/// Get count of try list items
final tryListCountProvider = FutureProvider<int>((ref) async {
  final tryList = await ref.watch(tryListNotifierProvider.future);
  return tryList.length;
});
