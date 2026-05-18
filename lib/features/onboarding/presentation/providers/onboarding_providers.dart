import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/auth/presentation/providers/user_preference_scope_provider.dart';
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

const _legacyDiscoveryCompletedKey = 'discoveryCompleted';
const _localDiscoveryCompletedKey = 'discoveryCompleted.local';
const _userDiscoveryCompletedKeyPrefix = 'discoveryCompleted.user.';

String _discoveryCompletedKey(String? userScope) {
  final scope = userScope?.trim();
  if (scope == null || scope.isEmpty) {
    return _localDiscoveryCompletedKey;
  }
  return '$_userDiscoveryCompletedKeyPrefix$scope';
}

bool _isLocalScope(String? userScope) {
  final scope = userScope?.trim();
  return scope == null || scope.isEmpty;
}

bool _readDiscoveryCompleted(SharedPreferences prefs, String? userScope) {
  final scopedValue = prefs.getBool(_discoveryCompletedKey(userScope));
  if (scopedValue != null) return scopedValue;

  // Preserve existing installs that used the original global key before this
  // became user-scoped. Authenticated users intentionally do not inherit it.
  if (_isLocalScope(userScope)) {
    return prefs.getBool(_legacyDiscoveryCompletedKey) ?? false;
  }
  return false;
}

/// Tracks whether the current user has completed the discovery flow at least once.
/// When `true`, the app routes directly to `/results` on launch instead of `/home`.
class DiscoveryCompleted extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final userScope = ref.watch(userPreferenceScopeProvider);
    return _readDiscoveryCompleted(prefs, userScope);
  }

  Future<void> complete() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final userScope = ref.read(userPreferenceScopeProvider);
    await prefs.setBool(_discoveryCompletedKey(userScope), true);
    if (_isLocalScope(userScope)) {
      await prefs.setBool(_legacyDiscoveryCompletedKey, true);
    }
    state = true;
  }

  /// Reset discovery state (for testing / re-onboarding).
  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final userScope = ref.read(userPreferenceScopeProvider);
    await prefs.setBool(_discoveryCompletedKey(userScope), false);
    if (_isLocalScope(userScope)) {
      await prefs.setBool(_legacyDiscoveryCompletedKey, false);
    }
    state = false;
  }

  bool isCompleteForScope([String? userScope]) {
    final prefs = ref.read(sharedPreferencesProvider);
    final resolvedScope = userScope?.trim().isNotEmpty == true
        ? userScope!.trim()
        : ref.read(userPreferenceScopeProvider);
    return _readDiscoveryCompleted(prefs, resolvedScope);
  }
}

final discoveryCompletedProvider = NotifierProvider<DiscoveryCompleted, bool>(
  DiscoveryCompleted.new,
);
