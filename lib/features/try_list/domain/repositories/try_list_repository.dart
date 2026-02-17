/// Abstract interface for Try List Repository
/// Handles venues the user wants to try later (wishlist/bucket list)
abstract class TryListRepository {
  /// Get all try list venue IDs
  Future<List<String>> getTryList();

  /// Add a venue to try list
  Future<void> addToTryList(String venueId);

  /// Remove a venue from try list
  Future<void> removeFromTryList(String venueId);

  /// Check if a venue is in try list
  Future<bool> isInTryList(String venueId);

  /// Toggle try list status
  Future<bool> toggleTryList(String venueId);

  /// Sync local try list to Firestore
  Future<void> syncToCloud(String userId);

  /// Sync try list from Firestore to local
  Future<void> syncFromCloud(String userId);

  /// Merge local and cloud on login
  Future<void> mergeOnLogin(String userId);

  /// Clear all local try list
  Future<void> clearLocal();
}
