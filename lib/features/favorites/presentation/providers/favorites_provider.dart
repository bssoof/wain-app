import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/favorites_repository.dart';
import '../../data/repositories/favorites_repository_impl.dart';

part 'favorites_provider.g.dart';

// ============ SHARED PREFERENCES PROVIDER ============

/// Provides SharedPreferences instance
/// Must be overridden in main.dart with actual instance
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with actual SharedPreferences instance',
  );
}

// ============ REPOSITORY PROVIDER ============

/// Provides FavoritesRepository instance
@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) {
  return FavoritesRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    prefs: ref.watch(sharedPreferencesProvider),
  );
}

// ============ FAVORITES STATE ============

/// Holds the current list of favorite venue IDs
@riverpod
class FavoritesList extends _$FavoritesList {
  @override
  Future<List<String>> build() async {
    return ref.watch(favoritesRepositoryProvider).getFavorites();
  }

  /// Add a venue to favorites
  Future<void> add(String venueId) async {
    await ref.read(favoritesRepositoryProvider).addFavorite(venueId);
    ref.invalidateSelf();
  }

  /// Remove a venue from favorites
  Future<void> remove(String venueId) async {
    await ref.read(favoritesRepositoryProvider).removeFavorite(venueId);
    ref.invalidateSelf();
  }

  /// Toggle favorite status
  Future<bool> toggle(String venueId) async {
    final result = await ref.read(favoritesRepositoryProvider).toggleFavorite(venueId);
    ref.invalidateSelf();
    return result;
  }

  /// Sync favorites to cloud (for logged-in users)
  Future<void> syncToCloud(String userId) async {
    await ref.read(favoritesRepositoryProvider).syncToCloud(userId);
  }

  /// Sync favorites from cloud (for logged-in users)
  Future<void> syncFromCloud(String userId) async {
    await ref.read(favoritesRepositoryProvider).syncFromCloud(userId);
    ref.invalidateSelf();
  }
}

// ============ UTILITY PROVIDERS ============

/// Check if a specific venue is in favorites
@riverpod
Future<bool> isFavorite(Ref ref, String venueId) async {
  final favorites = await ref.watch(favoritesListProvider.future);
  return favorites.contains(venueId);
}

/// Get count of favorites
@riverpod
Future<int> favoritesCount(Ref ref) async {
  final favorites = await ref.watch(favoritesListProvider.future);
  return favorites.length;
}
