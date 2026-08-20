import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

void main() {
  group('Venue JSON compatibility', () {
    test(
      'parses legacy seeded venue documents with missing optional fields',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('venues').doc('legacy-cafe').set({
          'name_ar': 'كافيه زمان',
          'name_en': 'Zaman Cafe',
          'city': 'رام الله',
          'lat': 31.9038,
          'lng': 35.2034,
          'categories': ['cafe', 'dessert'],
          'phone': '022963001',
          'average_rating': 4.3,
          'has_offers': true,
          'external_source': {
            'provider': 'google_places',
            'place_id': 'google-place-1',
          },
        });

        final doc = await firestore
            .collection('venues')
            .doc('legacy-cafe')
            .get();
        final venue = Venue.fromDoc(doc);

        expect(venue.id, 'legacy-cafe');
        expect(venue.nameAr, 'كافيه زمان');
        expect(venue.nameEn, 'Zaman Cafe');
        expect(venue.rating, 4.3);
        expect(venue.minPrice, 0);
        expect(venue.maxPrice, 0);
        expect(venue.tags, const VenueTags());
        expect(venue.hasActiveOffers, isTrue);
        expect(venue.googlePlaceId, 'google-place-1');
      },
    );

    test('parses fallback payloads without crashing discovery lists', () {
      final venue = Venue.fromJson({
        'venue_id': 'function-venue',
        'name': 'Fallback Cafe',
        'city': 'ramallah',
        'location': {'latitude': 31.9, 'longitude': 35.2},
        'image_url': 'https://example.test/image.jpg',
      });

      expect(venue.id, 'function-venue');
      expect(venue.nameAr, 'Fallback Cafe');
      expect(venue.nameEn, 'Fallback Cafe');
      expect(venue.lat, 31.9);
      expect(venue.lng, 35.2);
      expect(venue.phone, '');
      expect(venue.categories, isEmpty);
      expect(venue.tags, const VenueTags());
      expect(venue.photos, ['https://example.test/image.jpg']);
    });
  });
}
