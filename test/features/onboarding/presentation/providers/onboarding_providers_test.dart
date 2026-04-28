import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';

void main() {
  group('DiscoveryCompleted', () {
    test('defaults to false, completes, and resets persisted state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(discoveryCompletedProvider), isFalse);

      await container.read(discoveryCompletedProvider.notifier).complete();
      expect(container.read(discoveryCompletedProvider), isTrue);
      expect(prefs.getBool('discoveryCompleted'), isTrue);

      await container.read(discoveryCompletedProvider.notifier).reset();
      expect(container.read(discoveryCompletedProvider), isFalse);
      expect(prefs.getBool('discoveryCompleted'), isFalse);
    });
  });
}
