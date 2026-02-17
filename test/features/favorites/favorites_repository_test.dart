import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:wain_app/features/favorites/data/repositories/favorites_repository_impl.dart';

void main() {
  late FavoritesRepositoryImpl repo;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeFirestore = FakeFirebaseFirestore();
    repo = FavoritesRepositoryImpl(
      firestore: fakeFirestore,
      prefs: prefs,
    );
  });

  group('FavoritesRepositoryImpl - Local Operations', () {
    test('getFavorites returns empty list initially', () async {
      final favorites = await repo.getFavorites();
      expect(favorites, isEmpty);
    });

    test('addFavorite adds a venue', () async {
      await repo.addFavorite('venue_1');

      final favorites = await repo.getFavorites();
      expect(favorites, contains('venue_1'));
      expect(favorites.length, 1);
    });

    test('addFavorite does not duplicate', () async {
      await repo.addFavorite('venue_1');
      await repo.addFavorite('venue_1');

      final favorites = await repo.getFavorites();
      expect(favorites.length, 1);
    });

    test('addFavorite adds multiple venues', () async {
      await repo.addFavorite('venue_1');
      await repo.addFavorite('venue_2');
      await repo.addFavorite('venue_3');

      final favorites = await repo.getFavorites();
      expect(favorites.length, 3);
      expect(favorites, containsAll(['venue_1', 'venue_2', 'venue_3']));
    });

    test('removeFavorite removes a venue', () async {
      await repo.addFavorite('venue_1');
      await repo.addFavorite('venue_2');

      await repo.removeFavorite('venue_1');

      final favorites = await repo.getFavorites();
      expect(favorites, isNot(contains('venue_1')));
      expect(favorites, contains('venue_2'));
    });

    test('removeFavorite on non-existent venue does nothing', () async {
      await repo.addFavorite('venue_1');
      await repo.removeFavorite('venue_999');

      final favorites = await repo.getFavorites();
      expect(favorites.length, 1);
    });

    test('isFavorite returns true for added venue', () async {
      await repo.addFavorite('venue_1');
      expect(await repo.isFavorite('venue_1'), true);
    });

    test('isFavorite returns false for non-added venue', () async {
      expect(await repo.isFavorite('venue_1'), false);
    });

    test('toggleFavorite adds if not present', () async {
      final result = await repo.toggleFavorite('venue_1');
      expect(result, true); // was added
      expect(await repo.isFavorite('venue_1'), true);
    });

    test('toggleFavorite removes if present', () async {
      await repo.addFavorite('venue_1');
      final result = await repo.toggleFavorite('venue_1');
      expect(result, false); // was removed
      expect(await repo.isFavorite('venue_1'), false);
    });

    test('clearLocal removes all favorites', () async {
      await repo.addFavorite('venue_1');
      await repo.addFavorite('venue_2');
      await repo.clearLocal();

      final favorites = await repo.getFavorites();
      expect(favorites, isEmpty);
    });
  });

  group('FavoritesRepositoryImpl - Cloud Sync', () {
    test('syncToCloud writes favorites to Firestore', () async {
      await repo.addFavorite('venue_1');
      await repo.addFavorite('venue_2');

      await repo.syncToCloud('user_123');

      final doc =
          await fakeFirestore.collection('users').doc('user_123').get();
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['favorites'], containsAll(['venue_1', 'venue_2']));
    });

    test('syncFromCloud loads favorites from Firestore', () async {
      // Set up Firestore data
      await fakeFirestore.collection('users').doc('user_123').set({
        'favorites': ['cloud_1', 'cloud_2'],
      });

      await repo.syncFromCloud('user_123');

      final favorites = await repo.getFavorites();
      expect(favorites, containsAll(['cloud_1', 'cloud_2']));
    });

    test('mergeOnLogin combines local and cloud favorites', () async {
      // Local favorites
      await repo.addFavorite('local_1');
      await repo.addFavorite('shared_1');

      // Cloud favorites
      await fakeFirestore.collection('users').doc('user_123').set({
        'favorites': ['cloud_1', 'shared_1'],
      });

      await repo.mergeOnLogin('user_123');

      // Check Firestore has merged set
      final doc =
          await fakeFirestore.collection('users').doc('user_123').get();
      final merged = List<String>.from(doc.data()!['favorites']);
      expect(merged, containsAll(['local_1', 'shared_1', 'cloud_1']));

      // Local should be cleared after merge
      final localFavorites = await repo.getFavorites();
      expect(localFavorites, isEmpty);
    });
  });
}
