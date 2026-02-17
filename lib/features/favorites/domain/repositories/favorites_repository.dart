/// Abstract interface for Favorites Repository
/// Handles both local (SharedPreferences) and cloud (Firestore) storage
abstract class FavoritesRepository {
  /// Get all favorite venue IDs
  Future<List<String>> getFavorites();

  /// Add a venue to favorites
  Future<void> addFavorite(String venueId);

  /// Remove a venue from favorites
  Future<void> removeFavorite(String venueId);

  /// Check if a venue is in favorites
  Future<bool> isFavorite(String venueId);

  /// Toggle favorite status (add if not exists, remove if exists)
  Future<bool> toggleFavorite(String venueId);

  /// Sync local favorites to Firestore (for logged-in users)
  Future<void> syncToCloud(String userId);

  /// Sync favorites from Firestore to local (for logged-in users)
  Future<void> syncFromCloud(String userId);

  /// Merge local and cloud favorites on login (union of both, clears local after sync)
  Future<void> mergeOnLogin(String userId);

  /// Clear all local favorites
  Future<void> clearLocal();
}
