import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Result from OSRM route calculation
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Distance in kilometers
  double get distanceKm => distanceMeters / 1000;

  /// Duration in minutes
  double get durationMinutes => durationSeconds / 60;

  /// Formatted distance string
  String distanceFormatted(AppLocalizations l10n) {
    if (distanceKm < 1) {
      return l10n.distanceMeters('${distanceMeters.round()}');
    }
    return l10n.distanceKm(distanceKm.toStringAsFixed(1));
  }

  /// Formatted duration string
  String durationFormatted(AppLocalizations l10n) {
    final mins = durationMinutes.round();
    if (mins < 60) {
      return l10n.durationMins('$mins');
    }
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    return l10n.durationHoursMins('$hours', '$remainingMins');
  }
}

/// Service for fetching routes from OSRM
class RouteService {
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Get driving route between two points
  /// Returns null if request fails
  Future<RouteResult?> getRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      // OSRM expects lon,lat format (not lat,lon!)
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      debugPrint('🛣️ Fetching route from OSRM...');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ OSRM error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data['code'] != 'Ok') {
        debugPrint('❌ OSRM code: ${data['code']}');
        return null;
      }

      final routes = data['routes'] as List;
      if (routes.isEmpty) {
        debugPrint('❌ No routes found');
        return null;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;

      // Convert [lon, lat] to LatLng
      final points = coordinates.map((coord) {
        final c = coord as List;
        return LatLng(c[1].toDouble(), c[0].toDouble());
      }).toList();

      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();

      debugPrint('✅ Route: ${points.length} points, ${(distance / 1000).toStringAsFixed(1)} km, ${(duration / 60).round()} min');

      return RouteResult(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (e) {
      debugPrint('❌ Route error: $e');
      return null;
    }
  }
}
