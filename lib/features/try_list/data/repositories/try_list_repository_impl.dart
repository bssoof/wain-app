import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/repositories/try_list_repository.dart';

/// Implementation of TryListRepository
/// - Guest users: SharedPreferences (local storage)
/// - Logged-in users: Firestore sync + local cache
class TryListRepositoryImpl implements TryListRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const String _localKey = 'try_list_ids';

  TryListRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  }) : _firestore = firestore,
       _prefs = prefs;

  // ============ LOCAL OPERATIONS ============

  @override
  Future<List<String>> getTryList() async {
    final list = _prefs.getStringList(_localKey);
    return list ?? [];
  }

  @override
  Future<void> addToTryList(String venueId) async {
    final items = await getTryList();
    if (!items.contains(venueId)) {
      items.add(venueId);
      await _prefs.setStringList(_localKey, items);
    }
  }

  @override
  Future<void> removeFromTryList(String venueId) async {
    final items = await getTryList();
    items.remove(venueId);
    await _prefs.setStringList(_localKey, items);
  }

  @override
  Future<bool> isInTryList(String venueId) async {
    final items = await getTryList();
    return items.contains(venueId);
  }

  @override
  Future<bool> toggleTryList(String venueId) async {
    final isIn = await isInTryList(venueId);
    if (isIn) {
      await removeFromTryList(venueId);
      return false;
    } else {
      await addToTryList(venueId);
      return true;
    }
  }

  @override
  Future<void> clearLocal() async {
    await _prefs.remove(_localKey);
  }

  // ============ CLOUD SYNC OPERATIONS ============

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  @override
  Future<void> syncToCloud(String userId) async {
    try {
      final localList = await getTryList();
      await _userDoc(userId).set({
        'try_list': localList,
        'try_list_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('❌ TryList syncToCloud failed: $e');
      throw NetworkException(e.message);
    }
  }

  @override
  Future<void> syncFromCloud(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['try_list'] != null) {
          final cloudList = List<String>.from(data['try_list']);
          await _prefs.setStringList(_localKey, cloudList);
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ TryList syncFromCloud failed: $e');
      throw NetworkException(e.message);
    }
  }

  @override
  Future<void> mergeOnLogin(String userId) async {
    try {
      final localList = await getTryList();
      final doc = await _userDoc(userId).get();
      final cloudList = <String>[];

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['try_list'] != null) {
          cloudList.addAll(List<String>.from(data['try_list']));
        }
      }

      final merged = {...localList, ...cloudList}.toList();

      await _userDoc(userId).set({
        'try_list': merged,
        'try_list_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await clearLocal();
    } on FirebaseException catch (e) {
      debugPrint('❌ TryList mergeOnLogin failed: $e');
      throw NetworkException(e.message);
    }
  }
}
