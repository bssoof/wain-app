import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/data/repositories/venue_repository_impl.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

void main() {
  group('VenueRepositoryImpl city loading', () {
    late FakeFirebaseFirestore firestore;
    late VenueRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = VenueRepositoryImpl(firestore, _FakeFirebaseFunctions());
    });

    Future<void> seedVenue(String id, {Map<String, dynamic> data = const {}}) {
      return firestore.collection('venues').doc(id).set({
        'name': id,
        'lat': 31.9,
        'lng': 35.2,
        'categories': ['cafe'],
        'tags': {
          'mood': <String>[],
          'occasion': <String>[],
          'time_of_day': <String>[],
        },
        'min_price': 50,
        'max_price': 100,
        'average_rating': 4.2,
        'phone': '',
        ...data,
      });
    }

    test(
      'keeps legacy default-city venues when city metadata is missing',
      () async {
        await seedVenue('legacy-no-city');
        await seedVenue('arabic-city-field', data: {'city_ar': 'رام الله'});
        await seedVenue('nablus-venue', data: {'city': 'Nablus'});
        await seedVenue('hidden-venue', data: {'visibility_status': 'hidden'});

        final ramallahVenues = await repository.getVenuesByCity('ramallah');
        final ramallahIds = ramallahVenues.map((venue) => venue.id);
        expect(
          ramallahIds,
          containsAll(['legacy-no-city', 'arabic-city-field']),
        );
        expect(ramallahIds, isNot(contains('nablus-venue')));
        expect(ramallahIds, isNot(contains('hidden-venue')));

        final nablusIds = (await repository.getVenuesByCity(
          'nablus',
        )).map((venue) => venue.id);
        expect(nablusIds, contains('nablus-venue'));
        expect(nablusIds, isNot(contains('legacy-no-city')));
      },
    );
  });

  group('VenueRepositoryImpl ranking', () {
    late VenueRepositoryImpl repository;

    setUp(() {
      repository = VenueRepositoryImpl(
        FakeFirebaseFirestore(),
        _FakeFirebaseFunctions(),
      );
    });

    test('keeps legacy venues with unknown prices in discovery results', () {
      final legacyUnknownPrice = Venue.fromJson({
        'venue_id': 'legacy-cafe',
        'name': 'Legacy Cafe',
        'city': 'ramallah',
        'lat': 31.9,
        'lng': 35.2,
        'average_rating': 4.2,
      });
      final outsideBudget = Venue.fromJson({
        'venue_id': 'outside-budget',
        'name': 'Outside Budget',
        'city': 'ramallah',
        'lat': 31.9,
        'lng': 35.2,
        'min_price': 5,
        'max_price': 10,
        'average_rating': 5,
      });

      final ranked = repository.rankVenues(
        venues: [legacyUnknownPrice, outsideBudget],
        moodTags: const [],
        occasionTags: const [],
        timeTags: const [],
        minBudget: 30,
        maxBudget: 200,
      );

      expect(ranked.map((venue) => venue.id), contains('legacy-cafe'));
      expect(
        ranked.map((venue) => venue.id),
        isNot(contains('outside-budget')),
      );
    });
  });
}
