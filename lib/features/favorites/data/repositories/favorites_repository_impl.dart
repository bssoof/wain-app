import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Implementation of FavoritesRepository
/// - Guest users: SharedPreferences (local storage)
/// - Logged-in users: Firestore sync + local cache
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const String _localKey = 'favorites_list';

  FavoritesRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  // ============ LOCAL OPERATIONS ============

  @override
  Future<List<String>> getFavorites() async {
    final list = _prefs.getStringList(_localKey);
    return list ?? [];
  }

  @override
  Future<void> addFavorite(String venueId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(venueId)) {
      favorites.add(venueId);
      await _prefs.setStringList(_localKey, favorites);
    }
  }

  @override
  Future<void> removeFavorite(String venueId) async {
    final favorites = await getFavorites();
    favorites.remove(venueId);
    await _prefs.setStringList(_localKey, favorites);
  }

  @override
  Future<bool> isFavorite(String venueId) async {
    final favorites = await getFavorites();
    return favorites.contains(venueId);
  }

  @override
  Future<bool> toggleFavorite(String venueId) async {
    final isFav = await isFavorite(venueId);
    if (isFav) {
      await removeFavorite(venueId);
      return false;
    } else {
      await addFavorite(venueId);
      return true;
    }
  }

  @override
  Future<void> clearLocal() async {
    await _prefs.remove(_localKey);
  }

  // ============ CLOUD SYNC OPERATIONS ============

  /// Get Firestore document reference for user favorites
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  @override
  Future<void> syncToCloud(String userId) async {
    final localFavorites = await getFavorites();
    
    await _userDoc(userId).set({
      'favorites': localFavorites,
      'favorites_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> syncFromCloud(String userId) async {
    final doc = await _userDoc(userId).get();
    
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['favorites'] != null) {
        final cloudFavorites = List<String>.from(data['favorites']);
        
        // Merge: cloud favorites take priority
        await _prefs.setStringList(_localKey, cloudFavorites);
      }
    }
  }

  @override
  Future<void> mergeOnLogin(String userId) async {
    final localFavorites = await getFavorites();
    
    final doc = await _userDoc(userId).get();
    final cloudFavorites = <String>[];
    
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['favorites'] != null) {
        cloudFavorites.addAll(List<String>.from(data['favorites']));
      }
    }

    // Union of local and cloud
    final merged = {...localFavorites, ...cloudFavorites}.toList();
    
    // Save merged to cloud
    await _userDoc(userId).set({
      'favorites': merged,
      'favorites_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Clear local storage after successful cloud sync
    await clearLocal();
  }
}
