import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

/// Service for caching venues locally for offline access
class VenueCacheService {
  static const String _venuesCacheKey = 'venues_cache';
  static const String _lastUpdatedKey = 'venues_last_updated';
  static const String _cityKey = 'venues_city';

  final SharedPreferences _prefs;

  VenueCacheService(this._prefs);

  /// Cache venues for a city
  Future<void> cacheVenues(String city, List<Venue> venues) async {
    try {
      final venuesJson = venues.map((v) {
        final json = v.toJson();
        json['id'] = v.id; // Explicitly add ID correctly
        return json;
      }).toList();
      await _prefs.setString('${_venuesCacheKey}_$city', jsonEncode(venuesJson));
      await _prefs.setString('${_lastUpdatedKey}_$city', DateTime.now().toIso8601String());
      await _prefs.setString(_cityKey, city);
      debugPrint('💾 Cached ${venues.length} venues for $city');
    } catch (e) {
      debugPrint('❌ Cache error: $e');
    }
  }

  /// Get cached venues for a city
  List<Venue> getCachedVenues(String city) {
    try {
      final json = _prefs.getString('${_venuesCacheKey}_$city');
      if (json == null) return [];

      final List<dynamic> decoded = jsonDecode(json);
      final venues = <Venue>[];
      
      for (final v in decoded) {
        try {
          if (v is Map<String, dynamic>) {
            venues.add(Venue.fromJson(v));
          }
        } catch (e) {
          debugPrint('⚠️ Skipping invalid cached venue: $e');
        }
      }
      
      debugPrint('📦 Loaded ${venues.length} venues from cache for $city');
      return venues;
    } catch (e) {
      debugPrint('❌ Cache read error (clearing cache): $e');
      // Auto-heal: clear corrupt cache
      clearCache(city); 
      return [];
    }
  }

  /// Get last updated timestamp for a city
  DateTime? getLastUpdated(String city) {
    final timestamp = _prefs.getString('${_lastUpdatedKey}_$city');
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Check if cache is stale (older than 1 hour)
  bool isCacheStale(String city, {Duration maxAge = const Duration(hours: 1)}) {
    final lastUpdated = getLastUpdated(city);
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated) > maxAge;
  }

  /// Clear cache for a city
  Future<void> clearCache(String city) async {
    await _prefs.remove('${_venuesCacheKey}_$city');
    await _prefs.remove('${_lastUpdatedKey}_$city');
    debugPrint('🗑️ Cleared cache for $city');
  }

  /// Get formatted "last updated" string
  String getLastUpdatedFormatted(String city, AppLocalizations l10n) {
    final lastUpdated = getLastUpdated(city);
    if (lastUpdated == null) return l10n.cacheUnknown;

    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inMinutes < 1) return l10n.cacheJustNow;
    if (diff.inMinutes < 60) return l10n.cacheMinsAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.cacheHoursAgo(diff.inHours);
    return l10n.cacheDaysAgo(diff.inDays);
  }
}
