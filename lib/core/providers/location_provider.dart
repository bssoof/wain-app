import 'package:flutter/foundation.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';

part 'location_provider.g.dart';

/// Default fallback location: Ramallah city center
const double kRamallahLat = 31.9038;
const double kRamallahLng = 35.2034;

/// User location state
class UserLocation {
  final double latitude;
  final double longitude;
  final bool isRealLocation; // false if using fallback

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.isRealLocation = true,
  });

  /// Fallback location based on the selected city center.
  factory UserLocation.cityFallback(String cityKey) {
    final cityCenter =
        AppConstants.cityCenters[normalizeCityKey(cityKey)] ??
        const CityCoordinates(latitude: kRamallahLat, longitude: kRamallahLng);

    return UserLocation(
      latitude: cityCenter.latitude,
      longitude: cityCenter.longitude,
      isRealLocation: false,
    );
  }
}

final selectedCityFallbackLocationProvider = Provider<UserLocation>((ref) {
  final city = ref.watch(cityProvider);
  return UserLocation.cityFallback(city);
});

/// Provides the user's current location
/// Falls back to Ramallah center if permission denied or location unavailable
/// Provides the user's current location stream
/// Updates dynamically as the user moves
/// Provides the user's current location stream
/// Updates dynamically as the user moves
final userLocationProvider = StreamProvider<UserLocation>((ref) {
  ref.keepAlive();
  ref.watch(cityProvider);
  return _userLocationStream(ref);
});

// Internal stream function
Stream<UserLocation> _userLocationStream(Ref ref) async* {
  final fallbackLocation = ref.read(selectedCityFallbackLocationProvider);
  try {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('📍 Location services disabled, using fallback');
      yield fallbackLocation;
      return;
    }

    // Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('📍 Location permission denied, using fallback');
        yield fallbackLocation;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('📍 Location permission denied forever, using fallback');
      yield fallbackLocation;
      return;
    }

    // Yield initial location immediately (fastest available)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        yield UserLocation(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          isRealLocation: true,
        );
      }
    } catch (_) {}

    // Stream live location updates
    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );

    await for (final position in positionStream) {
      debugPrint('📍 Live location update: ${position.latitude}, ${position.longitude}');
      yield UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        isRealLocation: true,
      );
    }
  } catch (e) {
    debugPrint('📍 Error getting location stream: $e, using fallback');
    yield fallbackLocation;
  }
}

/// Calculate distance between user and venue
/// Returns distance in kilometers
@riverpod
double distanceToVenue(
  Ref ref, {
  required double venueLat,
  required double venueLng,
  required double userLat,
  required double userLng,
}) {
  final distanceInMeters = Geolocator.distanceBetween(
    userLat,
    userLng,
    venueLat,
    venueLng,
  );
  return distanceInMeters / 1000; // Convert to km
}

/// Format distance for display
String formatDistance(double distanceKm, AppLocalizations l10n) {
  if (distanceKm < 1) {
    return l10n.distanceMeters('${(distanceKm * 1000).round()}');
  } else {
    return l10n.distanceKm(distanceKm.toStringAsFixed(1));
  }
}
