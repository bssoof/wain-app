import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_hours_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_photos_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_venue_profile_repository.dart';

class _FakeFirebaseStorage extends Fake implements FirebaseStorage {}

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

void main() {
  group('merchant content repositories', () {
    test('photos repository moves selected photo to front', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('venues').doc('venue-1').set({
        'photos': ['a', 'b', 'c'],
      });

      final repository = FirebaseMerchantPhotosRepository(
        firestore: firestore,
        storage: _FakeFirebaseStorage(),
      );

      await repository.setPrimaryPhoto(
        venueId: 'venue-1',
        currentPhotos: const ['a', 'b', 'c'],
        targetUrl: 'c',
      );

      final venue = await firestore.collection('venues').doc('venue-1').get();
      expect(venue.data()?['photos'], ['c', 'a', 'b']);
    });

    test('hours repository saves shifts and spans_midnight flag', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('venues').doc('venue-1').set({});

      final repository = FirebaseMerchantHoursRepository(firestore: firestore);

      await repository.saveHours(
        venueId: 'venue-1',
        is24Hours: false,
        hours: const {
          'monday': [
            {'open': '09:00', 'close': '18:00'},
          ],
          'tuesday': [
            {'open': '18:00', 'close': '02:00'},
          ],
        },
      );

      final venue = await firestore.collection('venues').doc('venue-1').get();
      final data = venue.data()!;
      final hours = data['hours'] as Map<String, dynamic>;
      expect(data['is_24h'], isFalse);
      expect((hours['monday'] as List).first['spans_midnight'], isFalse);
      expect((hours['tuesday'] as List).first['spans_midnight'], isTrue);
    });

    test('venue profile repository trims and updates profile fields', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('venues').doc('venue-1').set({});

      final repository = FirebaseMerchantVenueProfileRepository(
        firestore: firestore,
      );

      await repository.updateVenueProfile(
        venueId: 'venue-1',
        nameAr: '  الاسم العربي  ',
        nameEn: '  English Name  ',
        phone: ' 0591234567 ',
        city: '  Ramallah ',
      );

      final venue = await firestore.collection('venues').doc('venue-1').get();
      final data = venue.data()!;
      expect(data['name_ar'], 'الاسم العربي');
      expect(data['name_en'], 'English Name');
      expect(data['phone'], '0591234567');
      expect(data['city'], 'Ramallah');
    });

    test(
      'stories repository detects an active story via limit(1) query',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('stories').add({
          'venue_id': 'venue-1',
          'expires_at': Timestamp.fromDate(DateTime(2026, 4, 6, 12)),
        });
        await firestore.collection('stories').add({
          'venue_id': 'venue-1',
          'expires_at': Timestamp.fromDate(DateTime(2026, 4, 1, 12)),
        });

        final repository = FirebaseMerchantStoriesRepository(
          firestore: firestore,
          functions: _FakeFirebaseFunctions(),
          storage: _FakeFirebaseStorage(),
        );

        final hasActive = await repository.hasActiveStory(
          venueId: 'venue-1',
          now: DateTime(2026, 4, 5, 12),
        );

        expect(hasActive, isTrue);
      },
    );

    test('stories repository maps story view_count from Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('stories').doc('story-1').set({
        'venue_id': 'venue-1',
        'type': 'text',
        'text': 'Promoted story',
        'created_at': Timestamp.fromDate(DateTime(2026, 4, 6, 12)),
        'expires_at': Timestamp.fromDate(DateTime(2026, 4, 7, 12)),
        'view_count': 42,
      });

      final repository = FirebaseMerchantStoriesRepository(
        firestore: firestore,
        functions: _FakeFirebaseFunctions(),
        storage: _FakeFirebaseStorage(),
      );

      final stories = await repository.watchStories(venueId: 'venue-1').first;

      expect(stories.single.id, 'story-1');
      expect(stories.single.viewCount, 42);
    });

    test(
      'stories repository defaults missing story view_count to zero',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('stories').doc('story-1').set({
          'venue_id': 'venue-1',
          'type': 'text',
          'text': 'Legacy story',
          'created_at': Timestamp.fromDate(DateTime(2026, 4, 6, 12)),
          'expires_at': Timestamp.fromDate(DateTime(2026, 4, 7, 12)),
        });

        final repository = FirebaseMerchantStoriesRepository(
          firestore: firestore,
          functions: _FakeFirebaseFunctions(),
          storage: _FakeFirebaseStorage(),
        );

        final stories = await repository.watchStories(venueId: 'venue-1').first;

        expect(stories.single.viewCount, 0);
      },
    );
  });
}
