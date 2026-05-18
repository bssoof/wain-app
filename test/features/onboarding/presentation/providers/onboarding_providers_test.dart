import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/auth/presentation/providers/user_preference_scope_provider.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';

void main() {
  group('DiscoveryCompleted', () {
    test('defaults to false, completes, and resets persisted state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userPreferenceScopeProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(discoveryCompletedProvider), isFalse);

      await container.read(discoveryCompletedProvider.notifier).complete();
      expect(container.read(discoveryCompletedProvider), isTrue);
      expect(prefs.getBool('discoveryCompleted.local'), isTrue);
      expect(prefs.getBool('discoveryCompleted'), isTrue);

      await container.read(discoveryCompletedProvider.notifier).reset();
      expect(container.read(discoveryCompletedProvider), isFalse);
      expect(prefs.getBool('discoveryCompleted.local'), isFalse);
      expect(prefs.getBool('discoveryCompleted'), isFalse);
    });

    test('stores completion per signed-in user scope', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userAContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userPreferenceScopeProvider.overrideWithValue('user-a'),
        ],
      );
      addTearDown(userAContainer.dispose);

      expect(userAContainer.read(discoveryCompletedProvider), isFalse);

      await userAContainer.read(discoveryCompletedProvider.notifier).complete();
      expect(userAContainer.read(discoveryCompletedProvider), isTrue);
      expect(prefs.getBool('discoveryCompleted.user.user-a'), isTrue);

      final userBContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userPreferenceScopeProvider.overrideWithValue('user-b'),
        ],
      );
      addTearDown(userBContainer.dispose);

      expect(userBContainer.read(discoveryCompletedProvider), isFalse);
      expect(
        userBContainer
            .read(discoveryCompletedProvider.notifier)
            .isCompleteForScope('user-a'),
        isTrue,
      );
    });
  });
}
