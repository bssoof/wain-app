import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/core/offline/offline_snapshot.dart';
import 'package:wain_app/core/offline/timestamp_tracker.dart';

void main() {
  group('OfflineSnapshot', () {
    test('empty snapshot has no data and is from cache', () {
      const snapshot = OfflineSnapshot<String>.empty();
      expect(snapshot.hasData, isFalse);
      expect(snapshot.isFromCache, isTrue);
      expect(snapshot.isFromServer, isFalse);
      expect(snapshot.isStale, isTrue);
    });

    test('server snapshot has correct source', () {
      final snapshot = OfflineSnapshot<String>(
        data: 'hello',
        source: OfflineDataSource.server,
        fetchedAt: DateTime.now(),
      );
      expect(snapshot.hasData, isTrue);
      expect(snapshot.isFromServer, isTrue);
      expect(snapshot.isFromCache, isFalse);
      expect(snapshot.isStale, isFalse);
    });

    test('cache snapshot with no fetchedAt is always stale', () {
      const snapshot = OfflineSnapshot<String>(
        data: 'cached',
        source: OfflineDataSource.cache,
      );
      expect(snapshot.hasData, isTrue);
      expect(snapshot.isStale, isTrue);
    });

    test('cache snapshot with recent fetchedAt is not stale', () {
      final snapshot = OfflineSnapshot<String>(
        data: 'cached',
        source: OfflineDataSource.cache,
        fetchedAt: DateTime.now(),
        staleDuration: const Duration(hours: 1),
      );
      expect(snapshot.isStale, isFalse);
    });

    test('cache snapshot with old fetchedAt is stale', () {
      final snapshot = OfflineSnapshot<String>(
        data: 'cached',
        source: OfflineDataSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        staleDuration: const Duration(hours: 1),
      );
      expect(snapshot.isStale, isTrue);
    });
  });

  group('OfflineDataSource', () {
    test('enum values exist', () {
      expect(OfflineDataSource.values.length, 2);
      expect(OfflineDataSource.server, isNotNull);
      expect(OfflineDataSource.cache, isNotNull);
    });
  });

  group('fetchWithOfflineFallback', () {
    late TimestampTracker tracker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tracker = TimestampTracker(prefs);
    });

    test(
      'returns server snapshot and writes timestamp on server success',
      () async {
        final snapshot = await fetchWithOfflineFallback<String>(
          cacheKey: 'test:key',
          fetcher: (source) async {
            expect(source, Source.server);
            return 'server-data';
          },
          timestampTracker: tracker,
        );

        expect(snapshot.data, 'server-data');
        expect(snapshot.isFromServer, isTrue);
        expect(tracker.read('test:key'), isNotNull);
      },
    );

    test('falls back to cache when server fails', () async {
      var calls = 0;
      final snapshot = await fetchWithOfflineFallback<String>(
        cacheKey: 'test:key',
        fetcher: (source) async {
          calls += 1;
          if (source == Source.server) {
            throw Exception('server failed');
          }
          return 'cache-data';
        },
        timestampTracker: tracker,
      );

      expect(calls, 2);
      expect(snapshot.data, 'cache-data');
      expect(snapshot.isFromCache, isTrue);
    });

    test('returns empty snapshot when server and cache both fail', () async {
      final snapshot = await fetchWithOfflineFallback<String>(
        cacheKey: 'test:key',
        fetcher: (_) => throw Exception('failed'),
        timestampTracker: tracker,
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.isFromCache, isTrue);
      expect(snapshot.fetchedAt, isNull);
    });
  });
}
