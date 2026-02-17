import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

/// Service for logging analytics events to Firebase Analytics
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseFunctions _functions;

  AnalyticsService(this._analytics, this._functions);

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('📊 Analytics: $name');
    } catch (e) {
      debugPrint('❌ Analytics error: $e');
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // ============ PRE-DEFINED EVENTS ============

  /// Log when user views a venue
  Future<void> logVenueView(String venueId, String venueName) async {
    await logEvent(
      name: 'venue_view',
      parameters: {'venue_id': venueId, 'venue_name': venueName},
    );
  }

  /// Log navigation click
  Future<void> logNavigationClick({
    required String venueId,
    required String navApp,
  }) async {
    await logEvent(
      name: 'navigation_click',
      parameters: {'venue_id': venueId, 'nav_app': navApp},
    );
  }

  /// Log favorite action
  Future<void> logFavoriteToggle({
    required String venueId,
    required bool isFavorite,
  }) async {
    await logEvent(
      name: isFavorite ? 'add_to_favorites' : 'remove_from_favorites',
      parameters: {'venue_id': venueId},
    );
  }

  /// Log search/filter action
  Future<void> logSearch({
    List<String>? moods,
    List<String>? occasions,
    List<String>? times,
    List<String>? cuisines,
    int? minBudget,
    int? maxBudget,
  }) async {
    final params = <String, Object>{};
    if (moods != null) params['moods'] = moods.join(',');
    if (occasions != null) params['occasions'] = occasions.join(',');
    if (times != null) params['times'] = times.join(',');
    if (cuisines != null) params['cuisines'] = cuisines.join(',');
    if (minBudget != null) params['min_budget'] = minBudget;
    if (maxBudget != null) params['max_budget'] = maxBudget;

    await logEvent(name: 'search', parameters: params);
  }

  /// Track a venue interaction in Firestore via Cloud Functions.
  /// eventType must be one of: view, call, story_view.
  Future<void> trackVenueEvent({
    required String venueId,
    required String eventType,
    required String source,
    String? deviceId,
  }) async {
    final payload = <String, Object>{
      'venueId': venueId,
      'eventType': eventType,
      'source': source,
    };
    if (deviceId != null) payload['deviceId'] = deviceId;

    try {
      await _functions.httpsCallable('trackVenueEvent').call(payload);
    } catch (e) {
      debugPrint('❌ trackVenueEvent error: $e');
    }
  }

  /// Log sign in
  Future<void> logSignIn(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log sign up
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Log call click
  Future<void> logCallClick({
    required String venueId,
    required String venueName,
    required String city,
    required String source,
  }) async {
    await logEvent(
      name: 'call_click',
      parameters: {
        'venue_id': venueId,
        'venue_name': venueName,
        'city': city,
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log share click
  Future<void> logShareClick({
    required String venueId,
    required String venueName,
    required String city,
    required String source,
  }) async {
    await logEvent(
      name: 'share_click',
      parameters: {
        'venue_id': venueId,
        'venue_name': venueName,
        'city': city,
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log venue view with full details
  Future<void> logVenueViewFull({
    required String venueId,
    required String venueName,
    required String city,
    required String source,
  }) async {
    await logEvent(
      name: 'venue_view',
      parameters: {
        'venue_id': venueId,
        'venue_name': venueName,
        'city': city,
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log marker tap on map
  Future<void> logMarkerTap({
    required String venueId,
    required String venueName,
    required String city,
  }) async {
    await logEvent(
      name: 'marker_tap',
      parameters: {
        'venue_id': venueId,
        'venue_name': venueName,
        'city': city,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

// ============ PROVIDER ============

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService(
    FirebaseAnalytics.instance,
    FirebaseFunctions.instance,
  );
}
