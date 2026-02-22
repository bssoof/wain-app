import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import 'package:wain_app/core/services/route_service.dart';
import 'package:wain_app/core/services/analytics_service.dart';

part 'route_providers.g.dart';

/// State for route preview
class RouteState {
  final bool isLoading;
  final RouteResult? result;
  final String? error;
  final String? lastKey;

  const RouteState({
    this.isLoading = false,
    this.result,
    this.error,
    this.lastKey,
  });

  RouteState copyWith({
    bool? isLoading,
    RouteResult? result,
    String? error,
    String? lastKey,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return RouteState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      lastKey: lastKey ?? this.lastKey,
    );
  }
}

/// Provider for RouteService
@riverpod
RouteService routeService(Ref ref) {
  return RouteService();
}

/// Notifier for managing route state
/// Notifier for managing route state
class RouteNotifier extends Notifier<RouteState> {
  Timer? _debounceTimer;

  @override
  RouteState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const RouteState();
  }

  /// Build route between two points with debounce
  Future<void> buildRoute({
    required LatLng from,
    required LatLng to,
    required String venueId,
    required String city,
    required String source,
  }) async {
    _debounceTimer?.cancel();

    // Create unique key for this route
    final key = '${from.latitude},${from.longitude}|${to.latitude},${to.longitude}';

    // Guard: skip if same route already cached
    if (state.lastKey == key && state.result != null) {
      return;
    }

    // Debounce: Wait 300ms before fetching
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
       // Set loading
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        lastKey: key,
      );

      try {
        final service = ref.read(routeServiceProvider);
        final result = await service.getRoute(from: from, to: to);

        if (result == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'route_fetch_failed',
          );
          
          ref.read(analyticsServiceProvider).logEvent(
            name: 'route_fetch_failed',
            parameters: {'venue_id': venueId, 'reason': 'null_result'},
          );
          return;
        }

        state = state.copyWith(
          isLoading: false,
          result: result,
        );
        
        ref.read(analyticsServiceProvider).logEvent(
            name: 'route_preview',
            parameters: {
              'venue_id': venueId, 
              'distance_km': result.distanceKm,
            },
        );

      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    });
  }

  /// Clear route state
  void clearRoute() {
    state = const RouteState();
  }

  /// Log navigation start event
  void logNavStart({
    required String venueId,
    required String city,
    required String navApp,
  }) {
    ref.read(analyticsServiceProvider).logEvent(
      name: 'nav_start',
      parameters: {
        'venue_id': venueId,
        'city': city,
        'nav_app': navApp,
      },
    );
  }
}

final routeNotifierProvider = NotifierProvider<RouteNotifier, RouteState>(RouteNotifier.new);
