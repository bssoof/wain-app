import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/domain/repositories/venue_repository.dart';

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
      debugPrint(
        '🔎 searchVenuesInBounds bounds: '
        'minLat=$minLat minLng=$minLng maxLat=$maxLat maxLng=$maxLng '
        'limit=$limit',
      );

      final result = await _functions
          .httpsCallable('searchVenuesInBounds')
          .call({
            'minLat': minLat,
            'minLng': minLng,
            'maxLat': maxLat,
            'maxLng': maxLng,
            'limit': limit,
            'deviceId': 'app_v1', // Should ideally pass real device ID
          });

      final data = result.data as Map<String, dynamic>;
      final venuesList = data['venues'] as List<dynamic>? ?? [];
      final rawVenues = venuesList
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
      final discoverableVenues = rawVenues
          .where(_isVenueDocumentDiscoverable)
          .toList();

      debugPrint('🔎 Cloud Function returned: ${rawVenues.length} raw venues');
      debugPrint('🔎 After discoverable filter: ${discoverableVenues.length}');
      if (rawVenues.isNotEmpty && discoverableVenues.isEmpty) {
        debugPrint(
          '⚠️ All bounds venues filtered out. '
          'Sample status: ${_venueStatusDebug(rawVenues.first)}',
        );
      }

      // Debug: Check offers flag from backend
      final withOffers = rawVenues
          .where((v) => v['has_active_offers'] == true)
          .length;
      debugPrint(
        '🔍 Repository: Fetched ${rawVenues.length} venues. With active offers: $withOffers',
      );

      return discoverableVenues.map(Venue.fromJson).toList();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Function Error: [${e.code}] ${e.message}');
      if (e.details != null) debugPrint('   Details: ${e.details}');
      throw ServerException(
        message: 'Function Error: ${e.message} (${e.code})',
      );
    } catch (e, stack) {
      debugPrint('❌ Repository Search Failed: $e');
      debugPrintStack(stackTrace: stack);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Venue>> getVenuesByCity(String city, {Source? source}) async {
    try {
      final options = source != null ? GetOptions(source: source) : null;
      final cityKey = _normalizeCityKey(city);
      final cityVariants = _cityVariantsForQuery(cityKey);

      final byCityKey = cityKey.isEmpty
          ? null
          : await _runVenueQuery(
              _firestore
                  .collection('venues')
                  .where('city_key', isEqualTo: cityKey),
              options,
            );

      QuerySnapshot<Map<String, dynamic>>? byCity;
      if (cityVariants.length == 1) {
        byCity = await _runVenueQuery(
          _firestore
              .collection('venues')
              .where('city', isEqualTo: cityVariants.first),
          options,
        );
      } else if (cityVariants.length > 1) {
        byCity = await _runVenueQuery(
          _firestore
              .collection('venues')
              .where('city', whereIn: cityVariants.take(10).toList()),
          options,
        );
      }

      final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      void collect(QuerySnapshot<Map<String, dynamic>>? snapshot) {
        if (snapshot == null) {
          return;
        }
        for (final doc in snapshot.docs) {
          merged[doc.id] = doc;
        }
      }

      collect(byCityKey);
      collect(byCity);

      final discoverableDocs = merged.values
          .where((doc) => _isVenueDocumentDiscoverable(doc.data()))
          .toList();
      debugPrint(
        '🏙️ getVenuesByCity city="$city" cityKey="$cityKey" '
        'cityKeyRaw=${byCityKey?.docs.length ?? 0} '
        'cityRaw=${byCity?.docs.length ?? 0} merged=${merged.length} '
        'discoverable=${discoverableDocs.length}',
      );
      if (merged.isNotEmpty && discoverableDocs.isEmpty) {
        debugPrint(
          '⚠️ All city venues filtered out. '
          'Sample status: ${_venueStatusDebug(merged.values.first.data())}',
        );
      }

      return discoverableDocs.map((doc) => Venue.fromDoc(doc)).toList();
    } catch (e) {
      throw const ServerException(); // Error: ${e.toString()}
    }
  }

  @override
  Future<Venue?> getVenueById(String id, {Source? source}) async {
    try {
      final options = source != null ? GetOptions(source: source) : null;
      final doc = options != null
          ? await _firestore.collection('venues').doc(id).get(options)
          : await _firestore.collection('venues').doc(id).get();
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
    debugPrint(
      '🔍 Ranking ${venues.length} venues. Filters: cat=$categories, mood=$moodTags, budget=$minBudget-$maxBudget',
    );

    final rankedVenues = venues
        .map((venue) {
          double score = 0;

          // 1. Budget Filter (Mandatory)
          // Venue is within budget if there's any overlap between ranges
          // User range: [minBudget, maxBudget], Venue range: [venue.minPrice, venue.maxPrice]
          final budgetMatch =
              venue.minPrice <= maxBudget && venue.maxPrice >= minBudget;
          if (!budgetMatch) {
            debugPrint(
              '  - ${venue.nameEn}: Budget mismatch (${venue.minPrice}-${venue.maxPrice} vs $minBudget-$maxBudget)',
            );
            return MapEntry(venue, -100.0);
          }

          // 2. Category/Cuisine Filter (Mandatory if specified)
          if (categories.isNotEmpty) {
            final hasCategory = venue.categories.any(
              (c) => categories.contains(c),
            );
            if (!hasCategory) {
              debugPrint(
                '  - ${venue.nameEn}: Category mismatch (Has: ${venue.categories}, Want: $categories)',
              );
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
        })
        .where(
          (entry) => entry.value > -50.0,
        ) // Filter out hard mismatches (budget/category = -100) but keep distant venues
        .toList();

    // Sort by score desc
    rankedVenues.sort((a, b) => b.value.compareTo(a.value));

    // Return top 3 matches only
    return rankedVenues.take(3).map((e) => e.key).toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _runVenueQuery(
    Query<Map<String, dynamic>> query,
    GetOptions? options,
  ) {
    return options != null ? query.get(options) : query.get();
  }

  String _venueStatusDebug(Map<String, dynamic> data) {
    final id = data['id'] ?? data['venue_id'] ?? data['doc_id'] ?? 'unknown';
    return 'id=$id '
        'visibility=${data['visibility_status']} '
        'operational=${data['operational_status']} '
        'subscription=${data['subscription_status']} '
        'city=${data['city']} city_key=${data['city_key']}';
  }

  bool _isVenueDocumentDiscoverable(Map<String, dynamic> data) {
    final visibility =
        (data['visibility_status']?.toString().toLowerCase() ?? 'visible');
    final operational =
        (data['operational_status']?.toString().toLowerCase() ?? 'active');
    final subscription =
        (data['subscription_status']?.toString().toLowerCase() ?? 'active');

    return visibility == 'visible' &&
        operational == 'active' &&
        subscription == 'active';
  }

  String _normalizeCityKey(String city) {
    final normalized = city.trim().toLowerCase();
    if (normalized.isEmpty) {
      return AppConstants.defaultCity;
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), '');
    const aliases = <String, List<String>>{
      'ramallah': ['ramallah', 'رام الله', 'رامالله'],
      'jerusalem': ['jerusalem', 'القدس'],
      'nablus': ['nablus', 'نابلس'],
      'bethlehem': ['bethlehem', 'بيت لحم', 'بيتلحم'],
    };

    for (final entry in aliases.entries) {
      for (final alias in entry.value) {
        final normalizedAlias = alias.trim().toLowerCase();
        final compactAlias = normalizedAlias.replaceAll(RegExp(r'\s+'), '');
        if (normalized == normalizedAlias || compact == compactAlias) {
          return entry.key;
        }
      }
    }

    return normalized.replaceAll(RegExp(r'\s+'), '_');
  }

  List<String> _cityVariantsForQuery(String cityKey) {
    if (cityKey.isEmpty) {
      return const [];
    }

    final variants = <String>{cityKey, cityKey.replaceAll('_', ' ')};
    final cityLabel = AppConstants.cities[cityKey];
    if (cityLabel != null && cityLabel.isNotEmpty) {
      variants.add(cityLabel);
      variants.add(cityLabel.replaceAll(' ', ''));
    }

    switch (cityKey) {
      case 'ramallah':
        variants.addAll(const ['ramallah', 'Ramallah', 'رام الله', 'رامالله']);
        break;
      case 'jerusalem':
        variants.addAll(const ['jerusalem', 'Jerusalem', 'القدس']);
        break;
      case 'nablus':
        variants.addAll(const ['nablus', 'Nablus', 'نابلس']);
        break;
      case 'bethlehem':
        variants.addAll(const ['bethlehem', 'Bethlehem', 'بيت لحم', 'بيتلحم']);
        break;
      default:
        break;
    }

    return variants.where((entry) => entry.trim().isNotEmpty).toList();
  }
}
