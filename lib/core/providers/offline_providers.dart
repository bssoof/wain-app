import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/offline/timestamp_tracker.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

/// Stream of connectivity status changes.
///
/// Emits `true` when the device has at least one non-"none" connectivity
/// interface. Note: a `true` value does not guarantee real internet access;
/// the actual offline fallback is handled by [fetchWithOfflineFallback].
final offlineStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});

/// Exposes the current connectivity as a synchronous boolean.
/// Returns `true` if the latest known status is "connected".
/// Defaults to `true` (optimistic) if no emission has occurred yet.
final isOnlineProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(offlineStatusProvider);
  return asyncValue.maybeWhen(data: (value) => value, orElse: () => true);
});

/// Singleton [TimestampTracker] backed by the same [SharedPreferences]
/// instance used elsewhere in the app.
final timestampTrackerProvider = Provider<TimestampTracker>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TimestampTracker(prefs);
});

/// Canonical stale durations per surface type.
abstract final class OfflineStaleDurations {
  /// Venue list / map — data changes less frequently.
  static const Duration venueList = Duration(hours: 2);

  /// Single venue or offer detail.
  static const Duration venueDetail = Duration(hours: 1);

  /// Merchant dashboard aggregate.
  static const Duration merchantDashboard = Duration(hours: 1);

  /// Merchant analytics drilldown.
  static const Duration merchantAnalytics = Duration(hours: 1);

  /// Merchant offers / reviews / profile.
  static const Duration merchantData = Duration(hours: 1);
}
