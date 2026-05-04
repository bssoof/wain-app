import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart'; // For sharedPreferencesProvider

class SeenOnboarding extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('seenOnboarding') ?? false;
  }

  Future<void> complete() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('seenOnboarding', true);
    state = true;
  }
}

final seenOnboardingProvider = NotifierProvider<SeenOnboarding, bool>(
  SeenOnboarding.new,
);

/// Tracks whether the user has completed the discovery flow at least once.
/// When `true`, the app routes directly to `/results` on launch instead of `/home`.
class DiscoveryCompleted extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('discoveryCompleted') ?? false;
  }

  Future<void> complete() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('discoveryCompleted', true);
    state = true;
  }

  /// Reset discovery state (for testing / re-onboarding).
  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('discoveryCompleted', false);
    state = false;
  }
}

final discoveryCompletedProvider = NotifierProvider<DiscoveryCompleted, bool>(
  DiscoveryCompleted.new,
);
