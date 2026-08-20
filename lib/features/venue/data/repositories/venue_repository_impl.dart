import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/domain/entities/venue_place_photo.dart';
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

      // Debug: Check offers flag from backend
      final withOffers = venuesList
          .where((v) => v['has_active_offers'] == true)
          .length;
      debugPrint(
        '🔍 Repository: Fetched ${venuesList.length} venues. With active offers: $withOffers',
      );

      return venuesList
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .where(_isVenueDocumentDiscoverable)
          .map(Venue.fromJson)
          .toList();
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

      await _collectLegacyCityFallback(merged, cityKey, options);

      return merged.values
          .where((doc) => _isVenueDocumentDiscoverable(doc.data()))
          .map(_venueFromDocOrNull)
          .whereType<Venue>()
          .toList();
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
  Future<List<VenuePlacePhoto>> getPlacePhotos(
    String venueId, {
    int limit = 3,
  }) async {
    try {
      final result = await _functions.httpsCallable('getVenuePlacePhotos').call(
        {'venueId': venueId, 'limit': limit},
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      final rawPhotos = data['photos'];
      if (rawPhotos is! List) return const [];

      return rawPhotos
          .whereType<Map>()
          .map(
            (photo) =>
                VenuePlacePhoto.fromJson(Map<String, dynamic>.from(photo)),
          )
          .where((photo) => photo.photoUri.startsWith('https://'))
          .toList(growable: false);
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Place photos unavailable: ${error.code}');
      return const [];
    } catch (error, stack) {
      debugPrint('Place photos response invalid: $error');
      debugPrintStack(stackTrace: stack);
      return const [];
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

          // Missing legacy prices are stored as 0-0. Treat that as unknown,
          // not as a hard mismatch, so seeded venues still appear in results.
          final hasKnownBudget = venue.minPrice > 0 || venue.maxPrice > 0;
          if (hasKnownBudget) {
            final rawMin = venue.minPrice > 0 ? venue.minPrice : venue.maxPrice;
            final rawMax = venue.maxPrice > 0 ? venue.maxPrice : venue.minPrice;
            final venueMin = rawMin <= rawMax ? rawMin : rawMax;
            final venueMax = rawMax >= rawMin ? rawMax : rawMin;
            final budgetMatch = venueMin <= maxBudget && venueMax >= minBudget;
            if (!budgetMatch) {
              debugPrint(
                '  - ${venue.nameEn}: Budget mismatch ($venueMin-$venueMax vs $minBudget-$maxBudget)',
              );
              return MapEntry(venue, -100.0);
            }
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

  Future<void> _collectLegacyCityFallback(
    Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> merged,
    String cityKey,
    GetOptions? options,
  ) async {
    try {
      final snapshot = await _runVenueQuery(
        _firestore.collection('venues').limit(300),
        options,
      );

      for (final doc in snapshot.docs) {
        if (merged.containsKey(doc.id)) {
          continue;
        }

        final data = doc.data();
        if (_isVenueDocumentDiscoverable(data) &&
            _isVenueInCity(data, cityKey)) {
          merged[doc.id] = doc;
        }
      }
    } catch (e, stack) {
      debugPrint('⚠️ Legacy venue city fallback failed: $e');
      debugPrintStack(stackTrace: stack);
    }
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

  bool _isVenueInCity(Map<String, dynamic> data, String cityKey) {
    var hasCitySignal = false;

    for (final candidate in _cityCandidateTexts(data)) {
      final text = candidate.trim();
      if (text.isEmpty) {
        continue;
      }

      hasCitySignal = true;
      if (_cityTextMatchesKey(text, cityKey)) {
        return true;
      }
    }

    // Legacy MVP venue records sometimes omitted city metadata entirely. They
    // belong to the default city list instead of disappearing from discovery.
    return !hasCitySignal && cityKey == AppConstants.defaultCity;
  }

  Iterable<String> _cityCandidateTexts(Map<String, dynamic> data) sync* {
    final directFields = [
      data['city_key'],
      data['cityKey'],
      data['city_key_normalized'],
      data['cityKeyNormalized'],
      data['city'],
      data['city_ar'],
      data['city_en'],
      data['address_city'],
      data['addressCity'],
    ];

    for (final value in directFields) {
      yield* _flattenCityCandidate(value);
    }

    final address = data['address'];
    if (address is Map) {
      yield* _flattenCityCandidate(address['city_key']);
      yield* _flattenCityCandidate(address['cityKey']);
      yield* _flattenCityCandidate(address['city']);
      yield* _flattenCityCandidate(address['city_ar']);
      yield* _flattenCityCandidate(address['city_en']);
    } else {
      yield* _flattenCityCandidate(address);
    }
  }

  Iterable<String> _flattenCityCandidate(Object? value) sync* {
    if (value == null) {
      return;
    }
    if (value is Iterable) {
      for (final entry in value) {
        yield* _flattenCityCandidate(entry);
      }
      return;
    }
    yield value.toString();
  }

  bool _cityTextMatchesKey(String text, String cityKey) {
    if (_normalizeCityKey(text) == cityKey) {
      return true;
    }

    final normalizedText = text.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    for (final variant in _cityVariantsForQuery(cityKey)) {
      final normalizedVariant = variant.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      if (normalizedVariant.isNotEmpty &&
          normalizedText.contains(normalizedVariant)) {
        return true;
      }
    }

    return false;
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

  Venue? _venueFromDocOrNull(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return Venue.fromDoc(doc);
    } catch (e, stack) {
      debugPrint('⚠️ Skipping malformed venue ${doc.id}: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }
}
