import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/core/offline/timestamp_tracker.dart';

void main() {
  group('TimestampTracker', () {
    late TimestampTracker tracker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tracker = TimestampTracker(prefs);
    });

    test('read returns null for unknown key', () {
      expect(tracker.read('some_key'), isNull);
    });

    test('write then read returns recent DateTime', () {
      tracker.write('test_key');
      final result = tracker.read('test_key');
      expect(result, isNotNull);
      expect(DateTime.now().difference(result!).inSeconds, lessThan(2));
    });

    test('isStale returns true for unknown key', () {
      expect(tracker.isStale('unknown'), isTrue);
    });

    test('isStale returns false for freshly-written key', () {
      tracker.write('fresh_key');
      expect(
        tracker.isStale('fresh_key', staleDuration: const Duration(hours: 1)),
        isFalse,
      );
    });

    test('remove clears the timestamp', () {
      tracker.write('removable');
      expect(tracker.read('removable'), isNotNull);

      tracker.remove('removable');
      expect(tracker.read('removable'), isNull);
    });
  });
}
