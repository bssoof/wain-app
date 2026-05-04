import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/core/offline/timestamp_tracker.dart';

/// Indicates the origin of a data read.
enum OfflineDataSource {
  /// Data was fetched from the remote server.
  server,

  /// Data was read from local Firestore cache.
  cache,
}

/// A read result that carries metadata about its freshness and origin.
///
/// Used by providers to wrap data fetched via [fetchWithOfflineFallback]
/// so that the UI can display offline banners or stale warnings.
class OfflineSnapshot<T> {
  /// The actual data payload. May be `null` if both server and cache
  /// returned nothing.
  final T? data;

  /// Whether this snapshot came from the server or the local cache.
  final OfflineDataSource source;

  /// The last time a server-successful fetch was recorded for this
  /// cache key, as tracked by [TimestampTracker].
  final DateTime? fetchedAt;

  /// Duration after which this snapshot is considered stale.
  final Duration staleDuration;

  const OfflineSnapshot({
    required this.data,
    required this.source,
    this.fetchedAt,
    this.staleDuration = const Duration(hours: 1),
  });

  /// Convenience constructor for a completely empty (no-data) snapshot.
  const OfflineSnapshot.empty({this.staleDuration = const Duration(hours: 1)})
    : data = null,
      source = OfflineDataSource.cache,
      fetchedAt = null;

  /// Whether there is usable data in this snapshot.
  bool get hasData => data != null;

  /// Whether the snapshot is backed by the server.
  bool get isFromServer => source == OfflineDataSource.server;

  /// Whether the snapshot is backed by local cache only.
  bool get isFromCache => source == OfflineDataSource.cache;

  /// Whether the data is considered stale based on [staleDuration]
  /// and [fetchedAt]. Always stale if [fetchedAt] is unknown.
  bool get isStale {
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt!) > staleDuration;
  }
}

/// Attempts a server-first read with automatic cache fallback.
///
/// [cacheKey] is passed to [timestampTracker] for freshness tracking.
/// [fetcher] receives a Firestore [Source] and should execute the
/// read using that source.
/// [timestampTracker] writes a timestamp when the server succeeds.
/// [staleDuration] controls when cached results are marked stale.
/// [serverTimeout] limits how long the server attempt is allowed to
/// take before falling back to cache (default: 5 seconds).
Future<OfflineSnapshot<T>> fetchWithOfflineFallback<T>({
  required String cacheKey,
  required Future<T> Function(Source source) fetcher,
  required TimestampTracker timestampTracker,
  Duration staleDuration = const Duration(hours: 1),
  Duration serverTimeout = const Duration(seconds: 5),
}) async {
  // Try server first with a timeout to avoid long waits on
  // slow / captive-portal networks before showing cached data.
  try {
    final data = await fetcher(Source.server).timeout(serverTimeout);
    timestampTracker.write(cacheKey);
    return OfflineSnapshot<T>(
      data: data,
      source: OfflineDataSource.server,
      fetchedAt: DateTime.now(),
      staleDuration: staleDuration,
    );
  } catch (_) {
    // Server unavailable or timed out — fall through to cache.
  }

  // Try cache.
  try {
    final data = await fetcher(Source.cache);
    final fetchedAt = timestampTracker.read(cacheKey);
    return OfflineSnapshot<T>(
      data: data,
      source: OfflineDataSource.cache,
      fetchedAt: fetchedAt,
      staleDuration: staleDuration,
    );
  } catch (_) {
    // Cache empty or failed.
  }

  // Both failed — return empty snapshot.
  return OfflineSnapshot<T>.empty(staleDuration: staleDuration);
}
