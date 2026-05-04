import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../entities/venue.dart';

abstract class VenueRepository {
  Future<List<Venue>> getVenuesByCity(String city, {Source? source});
  Future<Venue?> getVenueById(String id, {Source? source});
  Future<List<Venue>> getRecommendations({
    required String city,
    required List<String> moodTags,
    required List<String> occasionTags,
    required List<String> timeTags,
    List<String> categories = const [],
    int minBudget = 30,
    int maxBudget = 200,
    Position? userLocation,
  });

  Future<List<Venue>> searchVenuesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int limit = 50,
  });

  /// Rank a list of venues based on criteria (Memory Only)
  List<Venue> rankVenues({
    required List<Venue> venues,
    required List<String> moodTags,
    required List<String> occasionTags,
    required List<String> timeTags,
    List<String> categories = const [],
    int minBudget = 30,
    int maxBudget = 200,
    Position? userLocation,
  });
}
