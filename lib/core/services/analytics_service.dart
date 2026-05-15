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

  /// Log a venue menu impression after menu content is rendered.
  Future<void> logVenueMenuView({
    required String venueId,
    required String source,
    required String menuMode,
    required int itemCount,
    required int sectionCount,
    required int featuredCount,
    required int imageCount,
  }) async {
    await logEvent(
      name: 'venue_menu_view',
      parameters: {
        'venue_id': venueId,
        'source': source,
        'menu_mode': menuMode,
        'item_count': itemCount,
        'section_count': sectionCount,
        'featured_count': featuredCount,
        'image_count': imageCount,
      },
    );
  }

  /// Log when a menu item details sheet is opened from any menu surface.
  Future<void> logVenueMenuItemOpen({
    required String venueId,
    required String itemId,
    required String sectionId,
    required String surface,
    required bool isFeatured,
  }) async {
    await logEvent(
      name: 'venue_menu_item_open',
      parameters: {
        'venue_id': venueId,
        'item_id': itemId,
        'section_id': sectionId,
        'surface': surface,
        'is_featured': isFeatured,
      },
    );
  }

  /// Log menu search without recording the raw user query.
  Future<void> logVenueMenuSearch({
    required String venueId,
    required int queryLength,
    required int resultCount,
    required int sectionCount,
  }) async {
    await logEvent(
      name: 'venue_menu_search',
      parameters: {
        'venue_id': venueId,
        'query_length': queryLength,
        'result_count': resultCount,
        'section_count': sectionCount,
        'has_results': resultCount > 0,
      },
    );
  }

  /// Log explicit category chip selections in the full menu.
  Future<void> logVenueMenuCategorySelect({
    required String venueId,
    required String sectionId,
    required int itemCount,
  }) async {
    await logEvent(
      name: 'venue_menu_category_select',
      parameters: {
        'venue_id': venueId,
        'section_id': sectionId,
        'item_count': itemCount,
      },
    );
  }

  /// Log when a rendered menu receives no meaningful menu action in time.
  Future<void> logVenueMenuNoInteraction({
    required String venueId,
    required String menuMode,
    required int timeoutSeconds,
  }) async {
    await logEvent(
      name: 'venue_menu_no_interaction',
      parameters: {
        'venue_id': venueId,
        'menu_mode': menuMode,
        'timeout_seconds': timeoutSeconds,
      },
    );
  }

  /// Log legacy menu image opens without sending the image URL.
  Future<void> logVenueMenuImageOpen({
    required String venueId,
    required int imageIndex,
    required String surface,
  }) async {
    await logEvent(
      name: 'venue_menu_image_open',
      parameters: {
        'venue_id': venueId,
        'image_index': imageIndex,
        'surface': surface,
      },
    );
  }

  /// Track a venue interaction in Firestore via Cloud Functions.
  /// eventType must be one of: view, call, story_view.
  Future<void> trackVenueEvent({
    required String venueId,
    required String eventType,
    required String source,
    String? deviceId,
    String? offerId,
    String? navApp,
    String? storyId,
  }) async {
    final payload = <String, Object>{
      'venueId': venueId,
      'eventType': eventType,
      'source': source,
    };
    if (deviceId != null) payload['deviceId'] = deviceId;
    if (offerId != null) payload['offerId'] = offerId;
    if (navApp != null) payload['navApp'] = navApp;
    if (storyId != null) payload['storyId'] = storyId;

    try {
      await _functions.httpsCallable('trackVenueEvent').call(payload);
    } catch (e) {
      debugPrint('❌ trackVenueEvent error: $e');
    }
  }

  Future<void> trackOfferDetailView({
    required String venueId,
    required String offerId,
    required String source,
  }) {
    return trackVenueEvent(
      venueId: venueId,
      eventType: 'offer_detail_view',
      source: source,
      offerId: offerId,
    );
  }

  Future<void> trackOfferClaimClick({
    required String venueId,
    required String offerId,
    required String source,
  }) {
    return trackVenueEvent(
      venueId: venueId,
      eventType: 'offer_claim_click',
      source: source,
      offerId: offerId,
    );
  }

  Future<void> trackNavClick({
    required String venueId,
    required String navApp,
    required String source,
    String? deviceId,
  }) {
    return trackVenueEvent(
      venueId: venueId,
      eventType: 'nav_click',
      source: source,
      deviceId: deviceId,
      navApp: navApp,
    );
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
