import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/domain/repositories/venue_repository.dart';
import 'package:flutter/foundation.dart';

class VenueRepositoryImpl implements VenueRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  VenueRepositoryImpl(this._firestore, this._functions);

  @override
  Future<List<Venue>> searchVenuesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int limit = 50,
  }) async {
    try {
      final result = await _functions.httpsCallable('searchVenuesInBounds').call({
        'minLat': minLat,
        'minLng': minLng,
        'maxLat': maxLat,
        'maxLng': maxLng,
        'limit': limit,
        'deviceId': 'app_v1', // Should ideally pass real device ID
      });

      final data = result.data as Map<String, dynamic>;
      final venuesList = data['venues'] as List<dynamic>? ?? [];

      // Debug: Check offers flag from backend
      final withOffers = venuesList.where((v) => v['has_active_offers'] == true).length;
      debugPrint('🔍 Repository: Fetched ${venuesList.length} venues. With active offers: $withOffers');

      return venuesList
          .map((v) => Venue.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Function Error: [${e.code}] ${e.message}');
      if (e.details != null) debugPrint('   Details: ${e.details}');
      throw ServerException(message: 'Function Error: ${e.message} (${e.code})');
    } catch (e, stack) {
      debugPrint('❌ Repository Search Failed: $e');
      debugPrintStack(stackTrace: stack);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Venue>> getVenuesByCity(String city) async {
    try {
      final querySnapshot = await _firestore
          .collection('venues')
          .where('city', isEqualTo: city.toLowerCase())
          .get();

      return querySnapshot.docs
          .map((doc) => Venue.fromDoc(doc))
          .toList();
    } catch (e) {
      throw const ServerException(); // Error: ${e.toString()}
    }
  }

  @override
  Future<Venue?> getVenueById(String id) async {
    try {
      final doc = await _firestore.collection('venues').doc(id).get();
      if (!doc.exists) return null;
      return Venue.fromDoc(doc);
    } catch (e) {
      throw const ServerException(); // Error: ${e.toString()}
    }
  }

  @override
  Future<List<Venue>> getRecommendations({
    required String city,
    required List<String> moodTags,
    required List<String> occasionTags,
    required List<String> timeTags,
    List<String> categories = const [],
    int minBudget = 30,
    int maxBudget = 200,
    Position? userLocation,
  }) async {
    try {
      final allVenuesInCity = await getVenuesByCity(city);
      
      return rankVenues(
        venues: allVenuesInCity,
        moodTags: moodTags,
        occasionTags: occasionTags,
        timeTags: timeTags,
        categories: categories,
        minBudget: minBudget,
        maxBudget: maxBudget,
        userLocation: userLocation,
      );
    } catch (e) {
      throw const ServerException();
    }
  }

  @override
  List<Venue> rankVenues({
    required List<Venue> venues,
    required List<String> moodTags,
    required List<String> occasionTags,
    required List<String> timeTags,
    List<String> categories = const [],
    int minBudget = 30,
    int maxBudget = 200,
    Position? userLocation,
  }) {
    if (venues.isEmpty) return [];

    // Debug logging
    debugPrint('🔍 Ranking ${venues.length} venues. Filters: cat=$categories, mood=$moodTags, budget=$minBudget-$maxBudget');

    final rankedVenues = venues.map((venue) {
      double score = 0;
      
      // 1. Budget Filter (Mandatory)
      // Venue is within budget if there's any overlap between ranges
      // User range: [minBudget, maxBudget], Venue range: [venue.minPrice, venue.maxPrice]
      final budgetMatch = venue.minPrice <= maxBudget && venue.maxPrice >= minBudget;
      if (!budgetMatch) {
         debugPrint('  - ${venue.nameEn}: Budget mismatch (${venue.minPrice}-${venue.maxPrice} vs $minBudget-$maxBudget)');
         return MapEntry(venue, -100.0);
      }
      
      // 2. Category/Cuisine Filter (Mandatory if specified)
      if (categories.isNotEmpty) {
         final hasCategory = venue.categories.any((c) => categories.contains(c));
         if (!hasCategory) {
            debugPrint('  - ${venue.nameEn}: Category mismatch (Has: ${venue.categories}, Want: $categories)');
            return MapEntry(venue, -100.0);
         }
      }

      // 3. Tag Scoring (Higher weights)
      // Mood match usually most important
      for (final tag in moodTags) {
        if (venue.tags.mood.contains(tag)) score += 5;
      }
      
      // Occasion match
      for (final tag in occasionTags) {
        if (venue.tags.occasion.contains(tag)) score += 5;
      }
      
      // Time match
      for (final tag in timeTags) {
        if (venue.tags.timeOfDay.contains(tag)) score += 3;
      }

      // 4. Rating Boost
      score += (venue.rating * 2);

      // 5. Distance Penalty
      if (userLocation != null) {
        final distMeters = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          venue.lat,
          venue.lng,
        );
        final distKm = distMeters / 1000;
        
        // Penalty: -0.1 points per km (less severe)
        score -= (distKm * 0.1);
      }

      debugPrint('  + ${venue.nameEn}: Score $score');
      return MapEntry(venue, score);
    }).where((entry) => entry.value > -50.0) // Filter out hard mismatches (budget/category = -100) but keep distant venues
      .toList();

    // Sort by score desc
    rankedVenues.sort((a, b) => b.value.compareTo(a.value));

    // Return top 3 matches only
    return rankedVenues.take(3).map((e) => e.key).toList();
  }
}
