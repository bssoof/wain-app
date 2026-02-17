/// Abstract interface for Saved Offers Repository
/// Handles both local (SharedPreferences) and cloud (Firestore) storage
abstract class SavedOffersRepository {
  /// Get all saved offer IDs
  Future<List<String>> getSavedOffers();

  /// Add an offer to saved
  Future<void> saveOffer(String offerId);

  /// Remove an offer from saved
  Future<void> unsaveOffer(String offerId);

  /// Check if an offer is saved
  Future<bool> isSaved(String offerId);

  /// Toggle saved status (save if not exists, unsave if exists)
  Future<bool> toggleSaved(String offerId);

  /// Sync local saved offers to Firestore (for logged-in users)
  Future<void> syncToCloud(String userId);

  /// Sync saved offers from Firestore to local (for logged-in users)
  Future<void> syncFromCloud(String userId);

  /// Merge local and cloud saved offers on login
  Future<void> mergeOnLogin(String userId);

  /// Clear all local saved offers
  Future<void> clearLocal();
}
