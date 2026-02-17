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

final seenOnboardingProvider = NotifierProvider<SeenOnboarding, bool>(SeenOnboarding.new);
