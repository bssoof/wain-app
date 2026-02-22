import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/app_exceptions.dart';
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
  }) : _firestore = firestore,
       _prefs = prefs;

  // ============ LOCAL OPERATIONS ============

  @override
  Future<List<String>> getFavorites() async {
    try {
      final list = _prefs.getStringList(_localKey);
      return list ?? <String>[];
    } catch (error) {
      _logError('getFavorites', error);
      throw _mapLocalException(error, operation: 'getFavorites');
    }
  }

  @override
  Future<void> addFavorite(String venueId) async {
    try {
      final favorites = await getFavorites();
      if (!favorites.contains(venueId)) {
        favorites.add(venueId);
        await _prefs.setStringList(_localKey, favorites);
      }
    } catch (error) {
      _logError('addFavorite', error);
      throw _mapLocalException(error, operation: 'addFavorite');
    }
  }

  @override
  Future<void> removeFavorite(String venueId) async {
    try {
      final favorites = await getFavorites();
      favorites.remove(venueId);
      await _prefs.setStringList(_localKey, favorites);
    } catch (error) {
      _logError('removeFavorite', error);
      throw _mapLocalException(error, operation: 'removeFavorite');
    }
  }

  @override
  Future<bool> isFavorite(String venueId) async {
    try {
      final favorites = await getFavorites();
      return favorites.contains(venueId);
    } catch (error) {
      _logError('isFavorite', error);
      throw _mapLocalException(error, operation: 'isFavorite');
    }
  }

  @override
  Future<bool> toggleFavorite(String venueId) async {
    try {
      final isFav = await isFavorite(venueId);
      if (isFav) {
        await removeFavorite(venueId);
        return false;
      }

      await addFavorite(venueId);
      return true;
    } catch (error) {
      _logError('toggleFavorite', error);
      throw _mapLocalException(error, operation: 'toggleFavorite');
    }
  }

  @override
  Future<void> clearLocal() async {
    try {
      await _prefs.remove(_localKey);
    } catch (error) {
      _logError('clearLocal', error);
      throw _mapLocalException(error, operation: 'clearLocal');
    }
  }

  // ============ CLOUD SYNC OPERATIONS ============

  /// Get Firestore document reference for user favorites
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  @override
  Future<void> syncToCloud(String userId) async {
    try {
      final localFavorites = await getFavorites();
      await _userDoc(userId).set({
        'favorites': localFavorites,
        'favorites_updated_at': FieldValue.serverTimestamp(),
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
        if (data != null && data['favorites'] != null) {
          final cloudFavorites = List<String>.from(data['favorites']);
          await _prefs.setStringList(_localKey, cloudFavorites);
        }
      }
    } catch (error) {
      _logError('syncFromCloud', error);
      if (error is AppException) rethrow;
      if (error is FirebaseException || error is TimeoutException) {
        throw _mapCloudException(error, operation: 'syncFromCloud');
      }
      throw _mapLocalException(error, operation: 'syncFromCloud');
    }
  }

  @override
  Future<void> mergeOnLogin(String userId) async {
    try {
      final localFavorites = await getFavorites();
      final doc = await _userDoc(userId).get();
      final cloudFavorites = <String>[];

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['favorites'] != null) {
          cloudFavorites.addAll(List<String>.from(data['favorites']));
        }
      }

      final merged = {...localFavorites, ...cloudFavorites}.toList();

      await _userDoc(userId).set({
        'favorites': merged,
        'favorites_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await clearLocal();
    } catch (error) {
      _logError('mergeOnLogin', error);
      if (error is AppException) rethrow;
      if (error is FirebaseException || error is TimeoutException) {
        throw _mapCloudException(error, operation: 'mergeOnLogin');
      }
      throw _mapLocalException(error, operation: 'mergeOnLogin');
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
          return ServerException(message: error.message);
      }
    }

    return ServerException(message: '$operation failed: $error');
  }

  AppException _mapLocalException(Object error, {required String operation}) {
    if (error is AppException) return error;
    return const CacheException();
  }

  void _logError(String operation, Object error) {
    debugPrint('FavoritesRepository.$operation failed: $error');
  }
}
