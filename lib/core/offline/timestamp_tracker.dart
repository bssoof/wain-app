import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight tracker that records the last time a server-successful
/// fetch occurred for a given cache key.
///
/// Stored in [SharedPreferences] as ISO-8601 strings keyed by
/// `_ts:{cacheKey}`. No JSON blobs, no serialized data — timestamps only.
class TimestampTracker {
  final SharedPreferences _prefs;

  static const String _prefix = '_ts:';

  TimestampTracker(this._prefs);

  /// Records "now" as the last server-success time for [cacheKey].
  void write(String cacheKey) {
    _prefs.setString('$_prefix$cacheKey', DateTime.now().toIso8601String());
  }

  /// Returns the last server-success time for [cacheKey], or `null`
  /// if it was never recorded.
  DateTime? read(String cacheKey) {
    final raw = _prefs.getString('$_prefix$cacheKey');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Whether the cached data for [cacheKey] is considered stale.
  ///
  /// Returns `true` if no timestamp exists or the elapsed time
  /// exceeds [staleDuration].
  bool isStale(
    String cacheKey, {
    Duration staleDuration = const Duration(hours: 1),
  }) {
    final fetchedAt = read(cacheKey);
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) > staleDuration;
  }

  /// Removes the timestamp for [cacheKey].
  void remove(String cacheKey) {
    _prefs.remove('$_prefix$cacheKey');
  }
}
