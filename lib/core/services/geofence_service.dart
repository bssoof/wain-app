import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/core/services/notification_service.dart';
import 'dart:math';

/// Service that monitors user proximity to venues and triggers notifications
class GeofenceService {
  static const double _proximityRadiusMeters = 500.0;
  static const int _cooldownHours = 24;
  static const String _prefKey = 'geofence_notified_';

  StreamSubscription<Position>? _positionSubscription;
  final NotificationService _notificationService;
  List<GeofenceVenue> _monitoredVenues = [];
  bool _isActive = false;

  GeofenceService(this._notificationService);

  bool get isActive => _isActive;

  /// Start monitoring with a list of venues
  Future<void> start(List<GeofenceVenue> venues) async {
    _monitoredVenues = venues;

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('🔔 Geofence: Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('🔔 Geofence: Location permanently denied');
      return;
    }

    _isActive = true;

    // Listen to location changes
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // Only update every 100m moved
      ),
    ).listen(_onPositionUpdate, onError: (e) {
      debugPrint('🔔 Geofence error: $e');
    });

    debugPrint('🔔 Geofence started: monitoring ${venues.length} venues');
  }

  /// Stop monitoring
  void stop() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isActive = false;
    debugPrint('🔔 Geofence stopped');
  }

  /// Handle position updates
  Future<void> _onPositionUpdate(Position position) async {
    for (final venue in _monitoredVenues) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        venue.lat,
        venue.lng,
      );

      if (distance <= _proximityRadiusMeters) {
        // Check cooldown
        if (await _isOnCooldown(venue.id)) continue;

        // Trigger notification!
        await _notifyProximity(venue);
        await _setCooldown(venue.id);

        debugPrint(
            '🔔 Proximity alert: ${venue.name} (${distance.toInt()}m away)');
      }
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * (pi / 180);

  /// Check if a venue is on cooldown
  Future<bool> _isOnCooldown(String venueId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastNotified = prefs.getInt('$_prefKey$venueId');
    if (lastNotified == null) return false;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastNotified;
    return elapsed < (_cooldownHours * 3600 * 1000);
  }

  /// Set cooldown for a venue
  Future<void> _setCooldown(String venueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        '$_prefKey$venueId', DateTime.now().millisecondsSinceEpoch);
  }

  /// Send proximity notification
  Future<void> _notifyProximity(GeofenceVenue venue) async {
    await _notificationService.showLocalNotification(
      title: '📍 أنت قريب من ${venue.name}!',
      body: venue.hasOffers
          ? '🎁 في عروض حصرية بانتظارك!'
          : '⭐ اكتشف هذا المكان المميز',
      payload: 'venue_${venue.id}',
    );
  }
}

/// Simple venue data for geofencing
class GeofenceVenue {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final bool hasOffers;

  const GeofenceVenue({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.hasOffers = false,
  });
}
