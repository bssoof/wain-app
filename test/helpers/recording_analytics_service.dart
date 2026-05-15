import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/services/analytics_service.dart';

class RecordedAnalyticsEvent {
  final String name;
  final Map<String, Object>? parameters;

  const RecordedAnalyticsEvent({required this.name, this.parameters});
}

class RecordingAnalyticsService extends AnalyticsService {
  final List<RecordedAnalyticsEvent> events = <RecordedAnalyticsEvent>[];

  RecordingAnalyticsService()
    : super(_FakeFirebaseAnalytics(), _FakeFirebaseFunctions());

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add(RecordedAnalyticsEvent(name: name, parameters: parameters));
  }

  RecordedAnalyticsEvent? eventNamed(String name) {
    for (final event in events.reversed) {
      if (event.name == name) return event;
    }
    return null;
  }

  Iterable<RecordedAnalyticsEvent> eventsNamed(String name) {
    return events.where((event) => event.name == name);
  }
}

class _FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {}

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}
