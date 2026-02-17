import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/saved_offers_repository.dart';

/// Implementation of SavedOffersRepository
/// - Guest users: SharedPreferences (local storage)
/// - Logged-in users: Firestore sync + local cache
class SavedOffersRepositoryImpl implements SavedOffersRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const String _localKey = 'saved_offers_list';

  SavedOffersRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  // ============ LOCAL OPERATIONS ============

  @override
  Future<List<String>> getSavedOffers() async {
    final list = _prefs.getStringList(_localKey);
    return list ?? [];
  }

  @override
  Future<void> saveOffer(String offerId) async {
    final saved = await getSavedOffers();
    if (!saved.contains(offerId)) {
      saved.add(offerId);
      await _prefs.setStringList(_localKey, saved);
    }
  }

  @override
  Future<void> unsaveOffer(String offerId) async {
    final saved = await getSavedOffers();
    saved.remove(offerId);
    await _prefs.setStringList(_localKey, saved);
  }

  @override
  Future<bool> isSaved(String offerId) async {
    final saved = await getSavedOffers();
    return saved.contains(offerId);
  }

  @override
  Future<bool> toggleSaved(String offerId) async {
    final isSav = await isSaved(offerId);
    if (isSav) {
      await unsaveOffer(offerId);
      return false;
    } else {
      await saveOffer(offerId);
      return true;
    }
  }

  @override
  Future<void> clearLocal() async {
    await _prefs.remove(_localKey);
  }

  // ============ CLOUD SYNC OPERATIONS ============

  /// Get Firestore document reference for user
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  @override
  Future<void> syncToCloud(String userId) async {
    final localSaved = await getSavedOffers();
    
    await _userDoc(userId).set({
      'saved_offers': localSaved,
      'saved_offers_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> syncFromCloud(String userId) async {
    final doc = await _userDoc(userId).get();
    
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['saved_offers'] != null) {
        final cloudSaved = List<String>.from(data['saved_offers']);
        
        // Merge: cloud takes priority
        await _prefs.setStringList(_localKey, cloudSaved);
      }
    }
  }

  @override
  Future<void> mergeOnLogin(String userId) async {
    final localSaved = await getSavedOffers();
    
    final doc = await _userDoc(userId).get();
    final cloudSaved = <String>[];
    
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['saved_offers'] != null) {
        cloudSaved.addAll(List<String>.from(data['saved_offers']));
      }
    }

    // Union of local and cloud
    final merged = {...localSaved, ...cloudSaved}.toList();
    
    // Save merged to cloud
    await _userDoc(userId).set({
      'saved_offers': merged,
      'saved_offers_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update local with merged
    await _prefs.setStringList(_localKey, merged);
  }
}
