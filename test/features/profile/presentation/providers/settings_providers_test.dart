import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';

void main() {
  group('normalizeCityKey', () {
    test('keeps supported city keys unchanged', () {
      expect(normalizeCityKey('ramallah'), 'ramallah');
      expect(normalizeCityKey('nablus'), 'nablus');
    });

    test('migrates legacy Arabic labels to city keys', () {
      expect(normalizeCityKey('رام الله'), 'ramallah');
      expect(normalizeCityKey('القدس'), 'jerusalem');
      expect(normalizeCityKey('نابلس'), 'nablus');
      expect(normalizeCityKey('بيت لحم'), 'bethlehem');
    });

    test('falls back to default city for unknown values', () {
      expect(normalizeCityKey('unknown-city'), AppConstants.defaultCity);
      expect(normalizeCityKey(''), AppConstants.defaultCity);
    });
  });

  group('cityLabel', () {
    test('returns Arabic label for normalized key', () {
      expect(cityLabel('ramallah'), 'رام الله');
      expect(cityLabel('jerusalem'), 'القدس');
    });

    test('returns label after normalizing legacy values', () {
      expect(cityLabel('رام الله'), 'رام الله');
      expect(cityLabel('نابلس'), 'نابلس');
    });
  });

  group('notification settings', () {
    test('enables general notifications by default', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(settingsProvider).notificationsEnabled,
        kDefaultNotificationsEnabled,
      );
    });

    test('preserves an explicit disabled notification preference', () async {
      SharedPreferences.setMockInitialValues({kNotificationsKey: false});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).notificationsEnabled, isFalse);
    });

    test('persists notification toggles', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).toggleNotifications();

      expect(container.read(settingsProvider).notificationsEnabled, isFalse);
      expect(prefs.getBool(kNotificationsKey), isFalse);
    });
  });

  group('wallet notification preferences', () {
    test(
      'settings notifier persists wallet notification preferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('users').doc('user-a').set({
          'uid': 'user-a',
          'created_at': Timestamp.now(),
          kWalletNotificationsEnabledField: true,
          kWalletExpiryRemindersEnabledField: true,
          kAdminWalletNotificationsEnabledField: true,
        });

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            settingsFirestoreProvider.overrideWithValue(firestore),
            settingsCurrentUserUidProvider.overrideWith((ref) => 'user-a'),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(settingsProvider.notifier)
            .setWalletNotificationsEnabled(false);
        await container
            .read(settingsProvider.notifier)
            .setWalletExpiryRemindersEnabled(false);
        await container
            .read(settingsProvider.notifier)
            .setAdminWalletNotificationsEnabled(false);

        final userDoc = await firestore.collection('users').doc('user-a').get();
        expect(userDoc.data()![kWalletNotificationsEnabledField], isFalse);
        expect(userDoc.data()![kWalletExpiryRemindersEnabledField], isFalse);
        expect(userDoc.data()![kAdminWalletNotificationsEnabledField], isFalse);
      },
    );
  });
}
