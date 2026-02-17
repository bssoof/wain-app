import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/venue_cache_service.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

/// Provider for VenueCacheService
final venueCacheServiceProvider = Provider<VenueCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VenueCacheService(prefs);
});
