import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  })  : _firestore = firestore,
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
    final deviceId = await getDeviceId();

    final click = NavigationClick(
      venueId: venueId,
      userId: userId,
      deviceId: deviceId,
      timestamp: DateTime.now(),
      navApp: navApp,
      commissionAmount: 2, // Default commission per PRD
      commissionStatus: 'pending',
    );

    final docRef = await _collection.add(click.toJson());
    
    debugPrint('📍 Navigation click logged: ${docRef.id} -> $venueId via $navApp');
    
    return docRef.id;
  }

  @override
  Future<List<NavigationClick>> getClicksForVenue(String venueId) async {
    final snapshot = await _collection
        .where('venue_id', isEqualTo: venueId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit for performance
        .get();

    return snapshot.docs.map((doc) => NavigationClick.fromDoc(doc)).toList();
  }

  @override
  Future<List<NavigationClick>> getClicksForUser(String userId) async {
    final snapshot = await _collection
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => NavigationClick.fromDoc(doc)).toList();
  }
}
