import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/app_exceptions.dart';
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
  }) : _firestore = firestore,
       _prefs = prefs;

  // ============ LOCAL OPERATIONS ============

  @override
  Future<List<String>> getSavedOffers() async {
    try {
      final list = _prefs.getStringList(_localKey);
      return list ?? <String>[];
    } catch (error) {
      _logError('getSavedOffers', error);
      throw _mapLocalException(error);
    }
  }

  @override
  Future<void> saveOffer(String offerId) async {
    try {
      final saved = await getSavedOffers();
      if (!saved.contains(offerId)) {
        saved.add(offerId);
        await _prefs.setStringList(_localKey, saved);
      }
    } catch (error) {
      _logError('saveOffer', error);
      throw _mapLocalException(error);
    }
  }

  @override
  Future<void> unsaveOffer(String offerId) async {
    try {
      final saved = await getSavedOffers();
      saved.remove(offerId);
      await _prefs.setStringList(_localKey, saved);
    } catch (error) {
      _logError('unsaveOffer', error);
      throw _mapLocalException(error);
    }
  }

  @override
  Future<bool> isSaved(String offerId) async {
    try {
      final saved = await getSavedOffers();
      return saved.contains(offerId);
    } catch (error) {
      _logError('isSaved', error);
      throw _mapLocalException(error);
    }
  }

  @override
  Future<bool> toggleSaved(String offerId) async {
    try {
      final isSav = await isSaved(offerId);
      if (isSav) {
        await unsaveOffer(offerId);
        return false;
      }

      await saveOffer(offerId);
      return true;
    } catch (error) {
      _logError('toggleSaved', error);
      throw _mapLocalException(error);
    }
  }

  @override
  Future<void> clearLocal() async {
    try {
      await _prefs.remove(_localKey);
    } catch (error) {
      _logError('clearLocal', error);
      throw _mapLocalException(error);
    }
  }

  // ============ CLOUD SYNC OPERATIONS ============

  /// Get Firestore document reference for user
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  @override
  Future<void> syncToCloud(String userId) async {
    try {
      final localSaved = await getSavedOffers();
      await _userDoc(userId).set({
        'saved_offers': localSaved,
        'saved_offers_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      _logError('syncToCloud', error);
      throw _mapCloudException(error, operation: 'syncToCloud');
    }
  }

  @override
  Future<void> syncFromCloud(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['saved_offers'] != null) {
          final cloudSaved = List<String>.from(data['saved_offers']);
          await _prefs.setStringList(_localKey, cloudSaved);
        }
      }
    } catch (error) {
      _logError('syncFromCloud', error);
      if (error is AppException) rethrow;
      if (error is FirebaseException || error is TimeoutException) {
        throw _mapCloudException(error, operation: 'syncFromCloud');
      }
      throw _mapLocalException(error);
    }
  }

  @override
  Future<void> mergeOnLogin(String userId) async {
    try {
      final localSaved = await getSavedOffers();
      final doc = await _userDoc(userId).get();
      final cloudSaved = <String>[];

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['saved_offers'] != null) {
          cloudSaved.addAll(List<String>.from(data['saved_offers']));
        }
      }

      final merged = {...localSaved, ...cloudSaved}.toList();

      await _userDoc(userId).set({
        'saved_offers': merged,
        'saved_offers_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _prefs.setStringList(_localKey, merged);
    } catch (error) {
      _logError('mergeOnLogin', error);
      if (error is AppException) rethrow;
      if (error is FirebaseException || error is TimeoutException) {
        throw _mapCloudException(error, operation: 'mergeOnLogin');
      }
      throw _mapLocalException(error);
    }
  }

  AppException _mapCloudException(Object error, {required String operation}) {
    if (error is AppException) return error;

    if (error is TimeoutException) {
      return const AppTimeoutException();
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'network-request-failed':
          return NetworkException(error.message ?? '$operation unavailable');
        case 'deadline-exceeded':
          return const AppTimeoutException();
        case 'permission-denied':
          return ServerException(statusCode: 403, message: error.message);
        default:
          return OfferException(error.message ?? '$operation failed');
      }
    }

    return OfferException('$operation failed: $error');
  }

  AppException _mapLocalException(Object error) {
    if (error is AppException) return error;
    return const CacheException();
  }

  void _logError(String operation, Object error) {
    debugPrint('SavedOffersRepository.$operation failed: $error');
  }
}
