import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../models/navigation_click.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../../../../core/services/device_service.dart';

/// Implementation of NavigationRepository
/// Logs navigation clicks to Firestore for analytics and commission tracking
class NavigationRepositoryImpl implements NavigationRepository {
  final FirebaseFirestore _firestore;
  final DeviceService _deviceService;

  static const String _collectionName = 'navigation_clicks';

  NavigationRepositoryImpl({
    required FirebaseFirestore firestore,
    required DeviceService deviceService,
  }) : _firestore = firestore,
       _deviceService = deviceService;

  /// Get reference to navigation_clicks collection
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  @override
  Future<String> getDeviceId() async {
    return _deviceService.getDeviceId();
  }

  @override
  Future<String> logNavigationClick({
    required String venueId,
    String? userId,
    required String navApp,
  }) async {
    try {
      final deviceId = await getDeviceId();

      final click = NavigationClick(
        venueId: venueId,
        userId: userId,
        deviceId: deviceId,
        timestamp: DateTime.now(),
        navApp: navApp,
        commissionAmount: 2,
        commissionStatus: 'pending',
      );

      final docRef = await _collection.add(click.toJson());
      debugPrint(
        '📍 Navigation click logged: ${docRef.id} -> $venueId via $navApp',
      );
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('❌ Navigation logClick failed: $e');
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<NavigationClick>> getClicksForVenue(String venueId) async {
    try {
      final snapshot = await _collection
          .where('venue_id', isEqualTo: venueId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      return snapshot.docs.map((doc) => NavigationClick.fromDoc(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('❌ Navigation getClicksForVenue failed: $e');
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<NavigationClick>> getClicksForUser(String userId) async {
    try {
      final snapshot = await _collection
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((doc) => NavigationClick.fromDoc(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('❌ Navigation getClicksForUser failed: $e');
      throw ServerException(message: e.message);
    }
  }
}
