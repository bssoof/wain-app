import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:wain_app/core/services/analytics_service.dart';

// A simple mock for FirebaseAnalytics using Fake to avoid constructor issues
class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  final List<Map<String, dynamic>> loggedEvents = [];
  String? lastUserId;
  final Map<String, String?> userProperties = {};

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    loggedEvents.add({'name': name, 'parameters': parameters});
  }

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {
    lastUserId = id;
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    userProperties[name] = value;
  }

  @override
  Future<void> logLogin({
    String? loginMethod,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    loggedEvents.add({
      'name': 'login',
      'parameters': {'method': loginMethod},
    });
  }

  @override
  Future<void> logSignUp({
    required String signUpMethod,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    loggedEvents.add({
      'name': 'sign_up',
      'parameters': {'method': signUpMethod},
    });
  }
}

class MockFirebaseFunctions extends Fake implements FirebaseFunctions {
  String? callableName;
  Object? parameters;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    callableName = name;
    return _RecordingHttpsCallable(this);
  }
}

class _RecordingHttpsCallable extends Fake implements HttpsCallable {
  final MockFirebaseFunctions owner;

  _RecordingHttpsCallable(this.owner);

  @override
  Future<HttpsCallableResult<T>> call<T>([Object? parameters]) async {
    owner.parameters = parameters;
    return _FakeHttpsCallableResult<T>();
  }
}

class _FakeHttpsCallableResult<T> extends Fake
    implements HttpsCallableResult<T> {}

void main() {
  late AnalyticsService service;
  late MockFirebaseAnalytics mockAnalytics;
  late MockFirebaseFunctions mockFunctions;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    mockFunctions = MockFirebaseFunctions();
    service = AnalyticsService(mockAnalytics, mockFunctions);
  });

  group('AnalyticsService', () {
    test('logEvent records event with parameters', () async {
      await service.logEvent(name: 'test_event', parameters: {'key': 'value'});

      expect(mockAnalytics.loggedEvents, hasLength(1));
      expect(mockAnalytics.loggedEvents.first['name'], 'test_event');
      expect(
        (mockAnalytics.loggedEvents.first['parameters'] as Map)['key'],
        'value',
      );
    });

    test('setUserId sets the user ID', () async {
      await service.setUserId('user-123');
      expect(mockAnalytics.lastUserId, 'user-123');
    });

    test('setUserId with null clears ID', () async {
      await service.setUserId('user-123');
      await service.setUserId(null);
      expect(mockAnalytics.lastUserId, isNull);
    });

    test('setUserProperty sets a property', () async {
      await service.setUserProperty(name: 'city', value: 'ramallah');
      expect(mockAnalytics.userProperties['city'], 'ramallah');
    });

    test('logVenueView logs correct event', () async {
      await service.logVenueView('venue_1', 'مطعم ازهار');

      expect(mockAnalytics.loggedEvents, hasLength(1));
      expect(mockAnalytics.loggedEvents.first['name'], 'venue_view');
      final params = mockAnalytics.loggedEvents.first['parameters'] as Map;
      expect(params['venue_id'], 'venue_1');
      expect(params['venue_name'], 'مطعم ازهار');
    });

    test('logNavigationClick logs correct event', () async {
      await service.logNavigationClick(
        venueId: 'venue_2',
        navApp: 'google_maps',
      );

      expect(mockAnalytics.loggedEvents, hasLength(1));
      expect(mockAnalytics.loggedEvents.first['name'], 'navigation_click');
    });

    test('logFavoriteToggle logs add_to_favorites when true', () async {
      await service.logFavoriteToggle(venueId: 'venue_3', isFavorite: true);

      expect(mockAnalytics.loggedEvents.first['name'], 'add_to_favorites');
    });

    test('logFavoriteToggle logs remove_from_favorites when false', () async {
      await service.logFavoriteToggle(venueId: 'venue_3', isFavorite: false);

      expect(mockAnalytics.loggedEvents.first['name'], 'remove_from_favorites');
    });

    test('logSignIn logs login event', () async {
      await service.logSignIn('google');

      expect(mockAnalytics.loggedEvents, hasLength(1));
      expect(mockAnalytics.loggedEvents.first['name'], 'login');
    });

    test('logSignUp logs sign_up event', () async {
      await service.logSignUp('email');

      expect(mockAnalytics.loggedEvents, hasLength(1));
      expect(mockAnalytics.loggedEvents.first['name'], 'sign_up');
    });

    test('logSearch logs search with filters', () async {
      await service.logSearch(
        moods: ['chill', 'romantic'],
        cuisines: ['traditional'],
        minBudget: 50,
        maxBudget: 150,
      );

      expect(mockAnalytics.loggedEvents, hasLength(1));
      expect(mockAnalytics.loggedEvents.first['name'], 'search');
      final params = mockAnalytics.loggedEvents.first['parameters'] as Map;
      expect(params['moods'], 'chill,romantic');
      expect(params['cuisines'], 'traditional');
    });

    test('logVenueMenuView logs structured menu impression', () async {
      await service.logVenueMenuView(
        venueId: 'venue-menu',
        source: 'full_menu',
        menuMode: 'structured',
        itemCount: 12,
        sectionCount: 3,
        featuredCount: 4,
        imageCount: 2,
      );

      expect(mockAnalytics.loggedEvents.single['name'], 'venue_menu_view');
      final params = mockAnalytics.loggedEvents.single['parameters'] as Map;
      expect(params['venue_id'], 'venue-menu');
      expect(params['source'], 'full_menu');
      expect(params['menu_mode'], 'structured');
      expect(params['item_count'], 12);
      expect(params['section_count'], 3);
      expect(params['featured_count'], 4);
      expect(params['image_count'], 2);
    });

    test('logVenueMenuItemOpen logs item surface and featured flag', () async {
      await service.logVenueMenuItemOpen(
        venueId: 'venue-menu',
        itemId: 'item-1',
        sectionId: 'desserts',
        surface: 'featured_strip',
        isFeatured: true,
      );

      expect(mockAnalytics.loggedEvents.single['name'], 'venue_menu_item_open');
      final params = mockAnalytics.loggedEvents.single['parameters'] as Map;
      expect(params['venue_id'], 'venue-menu');
      expect(params['item_id'], 'item-1');
      expect(params['section_id'], 'desserts');
      expect(params['surface'], 'featured_strip');
      expect(params['is_featured'], isTrue);
    });

    test('logVenueMenuSearch does not log raw query text', () async {
      await service.logVenueMenuSearch(
        venueId: 'venue-menu',
        queryLength: 6,
        resultCount: 0,
        sectionCount: 0,
      );

      expect(mockAnalytics.loggedEvents.single['name'], 'venue_menu_search');
      final params = mockAnalytics.loggedEvents.single['parameters'] as Map;
      expect(params['venue_id'], 'venue-menu');
      expect(params['query_length'], 6);
      expect(params['result_count'], 0);
      expect(params['section_count'], 0);
      expect(params['has_results'], isFalse);
      expect(params.containsKey('query'), isFalse);
    });

    test('logVenueMenuCategorySelect logs section and count', () async {
      await service.logVenueMenuCategorySelect(
        venueId: 'venue-menu',
        sectionId: 'hot_drinks',
        itemCount: 5,
      );

      expect(
        mockAnalytics.loggedEvents.single['name'],
        'venue_menu_category_select',
      );
      final params = mockAnalytics.loggedEvents.single['parameters'] as Map;
      expect(params['venue_id'], 'venue-menu');
      expect(params['section_id'], 'hot_drinks');
      expect(params['item_count'], 5);
    });

    test('logVenueMenuNoInteraction logs timeout measurement', () async {
      await service.logVenueMenuNoInteraction(
        venueId: 'venue-menu',
        menuMode: 'image_only',
        timeoutSeconds: 10,
      );

      expect(
        mockAnalytics.loggedEvents.single['name'],
        'venue_menu_no_interaction',
      );
      final params = mockAnalytics.loggedEvents.single['parameters'] as Map;
      expect(params['venue_id'], 'venue-menu');
      expect(params['menu_mode'], 'image_only');
      expect(params['timeout_seconds'], 10);
    });

    test('logVenueMenuImageOpen does not log image URL', () async {
      await service.logVenueMenuImageOpen(
        venueId: 'venue-menu',
        imageIndex: 2,
        surface: 'full_menu_gallery',
      );

      expect(
        mockAnalytics.loggedEvents.single['name'],
        'venue_menu_image_open',
      );
      final params = mockAnalytics.loggedEvents.single['parameters'] as Map;
      expect(params['venue_id'], 'venue-menu');
      expect(params['image_index'], 2);
      expect(params['surface'], 'full_menu_gallery');
      expect(params.containsKey('url'), isFalse);
    });

    test('trackVenueEvent includes storyId when provided', () async {
      await service.trackVenueEvent(
        venueId: 'venue-story',
        eventType: 'view',
        source: 'story_viewer',
        storyId: 'story-1',
      );

      expect(mockFunctions.callableName, 'trackVenueEvent');
      final params = mockFunctions.parameters as Map<String, Object>;
      expect(params['venueId'], 'venue-story');
      expect(params['eventType'], 'view');
      expect(params['source'], 'story_viewer');
      expect(params['storyId'], 'story-1');
    });

    test('trackVenueEvent omits storyId when not provided', () async {
      await service.trackVenueEvent(
        venueId: 'venue-direct',
        eventType: 'view',
        source: 'venue_details',
      );

      expect(mockFunctions.callableName, 'trackVenueEvent');
      final params = mockFunctions.parameters as Map<String, Object>;
      expect(params['venueId'], 'venue-direct');
      expect(params['source'], 'venue_details');
      expect(params.containsKey('storyId'), isFalse);
    });

    test('logMarkerTap logs marker_tap event', () async {
      await service.logMarkerTap(
        venueId: 'venue_5',
        venueName: 'كافيه ستوري',
        city: 'رام الله',
      );

      expect(mockAnalytics.loggedEvents.first['name'], 'marker_tap');
    });

    test('multiple events are recorded in order', () async {
      await service.logVenueView('v1', 'Place 1');
      await service.logSignIn('phone');
      await service.logSearch(moods: ['fun']);

      expect(mockAnalytics.loggedEvents, hasLength(3));
      expect(mockAnalytics.loggedEvents[0]['name'], 'venue_view');
      expect(mockAnalytics.loggedEvents[1]['name'], 'login');
      expect(mockAnalytics.loggedEvents[2]['name'], 'search');
    });
  });
}
