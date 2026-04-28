import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wain_app/core/offline/offline_snapshot.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import '../../data/models/venue_busy_times_model.dart';
import '../../domain/entities/venue_busy_times.dart';
import '../../domain/entities/venue.dart';
import '../../domain/repositories/venue_repository.dart';
import '../../data/repositories/venue_repository_impl.dart';
import '../../../../core/constants/app_constants.dart';

import 'package:cloud_functions/cloud_functions.dart';

part 'venue_providers.g.dart';

// REPOSITORY PROVIDER
@Riverpod(keepAlive: true)
VenueRepository venueRepository(Ref ref) {
  return VenueRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
}

// DATA PROVIDERS

final venueByIdSnapshotProvider = FutureProvider.autoDispose
    .family<OfflineSnapshot<Venue?>, String>((ref, id) async {
      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<Venue?>(
        cacheKey: 'venue:$id',
        fetcher: (source) =>
            ref.watch(venueRepositoryProvider).getVenueById(id, source: source),
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.venueDetail,
      );
    });

@riverpod
Future<Venue?> venueById(Ref ref, String id) async {
  final snapshot = await ref.watch(venueByIdSnapshotProvider(id).future);
  return snapshot.data;
}

final venueBusyTimesSnapshotProvider = FutureProvider.autoDispose
    .family<OfflineSnapshot<VenueBusyTimes?>, String>((ref, venueId) async {
      final tracker = ref.read(timestampTrackerProvider);
      return fetchWithOfflineFallback<VenueBusyTimes?>(
        cacheKey: 'venue_busy_times:$venueId',
        fetcher: (source) async {
          final doc = await FirebaseFirestore.instance
              .collection('venue_busy_times')
              .doc(venueId)
              .get(GetOptions(source: source));
          return VenueBusyTimesModel.fromDoc(doc);
        },
        timestampTracker: tracker,
        staleDuration: OfflineStaleDurations.venueDetail,
      );
    });

final venueBusyTimesProvider = FutureProvider.family<VenueBusyTimes?, String>((
  ref,
  venueId,
) async {
  final snapshot = await ref.watch(
    venueBusyTimesSnapshotProvider(venueId).future,
  );
  return snapshot.data;
});

/// Cache-first venues loading state
class VenuesState {
  final List<Venue> venues;
  final bool isLoading;
  final OfflineDataSource? dataSource;
  final DateTime? fetchedAt;
  final String? error;

  const VenuesState({
    this.venues = const [],
    this.isLoading = true,
    this.dataSource,
    this.fetchedAt,
    this.error,
  });

  /// Whether the current data was served from local cache.
  bool get isOffline => dataSource == OfflineDataSource.cache;

  VenuesState copyWith({
    List<Venue>? venues,
    bool? isLoading,
    OfflineDataSource? dataSource,
    DateTime? fetchedAt,
    String? error,
    bool clearError = false,
  }) {
    return VenuesState(
      venues: venues ?? this.venues,
      isLoading: isLoading ?? this.isLoading,
      dataSource: dataSource ?? this.dataSource,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Cache-first venues provider with offline support via Firestore persistence.
@Riverpod(keepAlive: true)
class CachedVenues extends _$CachedVenues {
  @override
  VenuesState build({String city = AppConstants.defaultCity}) {
    _loadVenues(city);
    return const VenuesState();
  }

  Future<void> _loadVenues(String city) async {
    final tracker = ref.read(timestampTrackerProvider);
    final repo = ref.read(venueRepositoryProvider);

    final snapshot = await fetchWithOfflineFallback<List<Venue>>(
      cacheKey: 'venues_city:$city',
      fetcher: (source) => repo.getVenuesByCity(city, source: source),
      timestampTracker: tracker,
      staleDuration: OfflineStaleDurations.venueList,
    );

    if (snapshot.hasData) {
      state = state.copyWith(
        venues: snapshot.data!,
        isLoading: false,
        dataSource: snapshot.source,
        fetchedAt: snapshot.fetchedAt,
        clearError: true,
      );
      debugPrint(
        '${snapshot.isFromServer ? '🌐' : '📦'} Loaded ${snapshot.data!.length} '
        'venues from ${snapshot.source.name} for $city',
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        dataSource: OfflineDataSource.cache,
        error: 'venues_load_failed',
      );
    }
  }

  /// Refresh venues from Firestore
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadVenues(city);
  }

  /// Merge new venues with Smart Eviction
  /// Keeps venues closest to the [center] when capping logic applies.
  void mergeVenues(
    List<Venue> newVenues, {
    required double centerLat,
    required double centerLng,
  }) {
    if (newVenues.isEmpty) return;

    final currentIds = state.venues.map((v) => v.id).toSet();
    final uniqueNew = newVenues
        .where((v) => !currentIds.contains(v.id))
        .toList();

    // Always add new ones
    var updatedList = [...state.venues, ...uniqueNew];

    // Memory Cap: 300 Venues
    if (updatedList.length > 300) {
      final overflow = updatedList.length - 300;

      // Smart Eviction: Calculate distance from current search center
      // We want to KEEP closest ones, so we DROP farthest ones.
      final venuesWithDist = updatedList.map((v) {
        final dist = _simpleDiff(v.lat, v.lng, centerLat, centerLng);
        return MapEntry(v, dist);
      }).toList();

      // Sort: Ascending distance (Index 0 = Closest)
      venuesWithDist.sort((a, b) => a.value.compareTo(b.value));

      // Take top 300 (Closest)
      updatedList = venuesWithDist.take(300).map((e) => e.key).toList();

      debugPrint('🧹 Smart Eviction: Dropped $overflow farthest venues');
    }

    state = state.copyWith(venues: updatedList);
    debugPrint(
      '🗺️ Merged ${uniqueNew.length} new geo-search venues. Total: ${updatedList.length}',
    );
  }

  // Simple Euclidean diff for sorting/eviction is faster/sufficient for this scale
  double _simpleDiff(double lat1, double lng1, double lat2, double lng2) {
    return (lat1 - lat2).abs() + (lng1 - lng2).abs();
  }
}

/// Simple venues provider (for backward compatibility)
@riverpod
Future<List<Venue>> venuesByCity(
  Ref ref, {
  String city = AppConstants.defaultCity,
}) {
  final state = ref.watch(cachedVenuesProvider(city: city));
  if (state.venues.isNotEmpty) {
    return Future.value(state.venues);
  }
  return ref.watch(venueRepositoryProvider).getVenuesByCity(city);
}

@Riverpod(keepAlive: true)
Future<List<Venue>> recommendations(
  Ref ref, {
  required List<String> moodTags,
  required List<String> occasionTags,
  required List<String> timeTags,
  int minBudget = 30,
  int maxBudget = 200,
  List<String> cuisineTypes = const [],
  String city = AppConstants.defaultCity,
  SortBy sortBy = SortBy.rating,
  double? userLat,
  double? userLng,
}) async {
  // 1. Get venues from memory cache (Fast!)
  final venuesState = ref.watch(cachedVenuesProvider(city: city));

  if (venuesState.isLoading && venuesState.venues.isEmpty) {
    return []; // Still loading initial data
  }

  // 2. Rank in memory using the repository helper
  final ranked = ref
      .read(venueRepositoryProvider)
      .rankVenues(
        venues: venuesState.venues,
        moodTags: moodTags,
        occasionTags: occasionTags,
        timeTags: timeTags,
        minBudget: minBudget,
        maxBudget: maxBudget,
        categories: cuisineTypes,
      );

  // Fallback: If no strict matches, return top rated venues
  List<Venue> results;
  if (ranked.isEmpty && venuesState.venues.isNotEmpty) {
    final fallback = venuesState.venues.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    results = fallback.take(5).toList();
  } else {
    results = ranked.toList();
  }

  // 3. Apply sort order
  switch (sortBy) {
    case SortBy.distance:
      if (userLat != null && userLng != null) {
        results.sort((a, b) {
          final dA = _calculateDistance(userLat, userLng, a.lat, a.lng);
          final dB = _calculateDistance(userLat, userLng, b.lat, b.lng);
          return dA.compareTo(dB);
        });
      }
      // If no location, keep default ranking (rating-based)
      break;
    case SortBy.budgetLow:
      results.sort((a, b) => a.minPrice.compareTo(b.minPrice));
      break;
    case SortBy.budgetHigh:
      results.sort((a, b) => b.minPrice.compareTo(a.minPrice));
      break;
    case SortBy.rating:
      results.sort((a, b) => b.rating.compareTo(a.rating));
      break;
  }

  return results;
}

/// Venue with calculated distance
class VenueWithDistance {
  final Venue venue;
  final double distanceKm;

  VenueWithDistance({required this.venue, required this.distanceKm});
}

/// Get nearest 5 venues sorted by distance
@riverpod
Future<List<VenueWithDistance>> nearbyVenues(
  Ref ref, {
  required double userLat,
  required double userLng,
  int limit = 5,
  String city = AppConstants.defaultCity,
}) async {
  final tracker = ref.read(timestampTrackerProvider);
  final snapshot = await fetchWithOfflineFallback<List<Venue>>(
    cacheKey: 'venues_city:$city',
    fetcher: (source) => ref
        .watch(venueRepositoryProvider)
        .getVenuesByCity(city, source: source),
    timestampTracker: tracker,
    staleDuration: OfflineStaleDurations.venueList,
  );
  final venues = snapshot.data ?? const <Venue>[];

  // Calculate distance for each venue
  final venuesWithDistance = venues.map((venue) {
    final distanceKm = _calculateDistance(
      userLat,
      userLng,
      venue.lat,
      venue.lng,
    );
    return VenueWithDistance(venue: venue, distanceKm: distanceKm);
  }).toList();

  // Sort by distance
  venuesWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  // Return top N
  return venuesWithDistance.take(limit).toList();
}

/// Haversine distance calculation (in km)
double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  const double earthRadius = 6371; // km

  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);

  final a =
      _sin(dLat / 2) * _sin(dLat / 2) +
      _cos(_toRadians(lat1)) *
          _cos(_toRadians(lat2)) *
          _sin(dLng / 2) *
          _sin(dLng / 2);

  final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

  return earthRadius * c;
}

double _toRadians(double deg) => deg * 3.141592653589793 / 180;
double _sin(double x) => math.sin(x);
double _cos(double x) => math.cos(x);
double _sqrt(double x) => math.sqrt(x);
double _atan2(double y, double x) => math.atan2(y, x);

/// Get active stories for a venue
@riverpod
Stream<List<Map<String, dynamic>>> venueStories(Ref ref, String venueId) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('stories')
      .where('venue_id', isEqualTo: venueId)
      // Remove complex queries to avoid index errors
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Client-side Filter & Sort
        final activeStories = docs.where((story) {
          final expiresAt = (story['expires_at'] as Timestamp?)?.toDate();
          return expiresAt != null && expiresAt.isAfter(now);
        }).toList();

        // Sort by newest first
        activeStories.sort((a, b) {
          final tA = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tB = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tB.compareTo(tA);
        });

        return activeStories;
      });
}
