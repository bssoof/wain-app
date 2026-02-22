import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/services/device_service.dart';
import 'package:wain_app/features/offers/data/repositories/offers_repository.dart';
import 'package:wain_app/features/offers/data/repositories/saved_offers_repository_impl.dart';
import 'package:wain_app/features/offers/domain/repositories/saved_offers_repository.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'offers_providers.g.dart';

/// Provider for OffersRepository
@riverpod
OffersRepository offersRepository(Ref ref) {
  return OffersRepositoryImpl();
}

/// Provider for offers by venue
@riverpod
Future<List<Offer>> offersByVenue(Ref ref, {required String venueId}) async {
  final repo = ref.watch(offersRepositoryProvider);
  return repo.getOffersByVenue(venueId);
}

/// Provider for single offer by ID
@riverpod
Future<Offer?> offerById(Ref ref, {required String offerId}) async {
  final repo = ref.watch(offersRepositoryProvider);
  return repo.getOfferById(offerId);
}

/// State for claim operation
class ClaimState {
  final bool isLoading;
  final ClaimResult? result;
  final String? error;

  const ClaimState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  ClaimState copyWith({
    bool? isLoading,
    ClaimResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return ClaimState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for claiming offers
@riverpod
class ClaimOffer extends _$ClaimOffer {
  @override
  ClaimState build() => const ClaimState();

  /// Claim an offer
  Future<ClaimResult?> claim({
    required Offer offer,
    required String source,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    // Capture services locally
    final analytics = ref.read(analyticsServiceProvider);

    try {
      final repo = ref.read(offersRepositoryProvider);
      
      // Get device ID
      final deviceService = ref.read(deviceServiceProvider);
      final deviceId = await deviceService.getDeviceId();

      // Get user ID if logged in
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      // Log click event
      analytics.logEvent(
        name: 'offer_claim_click',
        parameters: {
          'offer_id': offer.id,
          'venue_id': offer.venueId,
          'source': source,
          'is_partner': offer.isPartner.toString(),
          'city': city,
        },
      );

      // Create claim
      final claim = OfferClaim(
        offerId: offer.id,
        venueId: offer.venueId,
        userId: userId,
        deviceId: deviceId,
        status: 'pending',
        source: source,
        city: city,
      );

      final result = await repo.createClaim(claim);

      if (result == null) {
        try {
          state = state.copyWith(isLoading: false, error: 'claim_save_failed');
        } catch (_) {}
        
        analytics.logEvent(
          name: 'offer_claim_failed',
          parameters: {
            'offer_id': offer.id,
            'venue_id': offer.venueId,
            'reason': 'create_failed',
          },
        );
        return null;
      }

      try {
        state = state.copyWith(isLoading: false, result: result);
      } catch (_) {}

      // Log success
      analytics.logEvent(
        name: 'offer_claim_created',
        parameters: {
          'offer_id': offer.id,
          'venue_id': offer.venueId,
          'claim_id': result.claimId,
          'source': source,
          'city': city,
        },
      );

      return result;
    } catch (e) {
      debugPrint('❌ Claim error: $e');
      
      // Clean up error message
      String message = e.toString();
      if (message.contains(']')) {
        message = message.split(']').last.trim();
      } else if (message.startsWith('Exception: ')) {
        message = message.substring(11).trim();
      }
      
      try {
        state = state.copyWith(isLoading: false, error: message);
      } catch (_) {}

      try {
        analytics.logEvent(
            name: 'offer_claim_failed',
            parameters: {
            'offer_id': offer.id,
            'venue_id': offer.venueId,
            'reason': e.toString(),
            },
        );
      } catch (_) {}
      return null;
    }
  }

  void reset() {
    state = const ClaimState();
  }
}

/// Provider for my claims (reactive to auth state)
/// Provider for my claims (reactive to auth state)
final myClaimsProvider = FutureProvider<List<OfferClaim>>((ref) async {
  // Watch auth state to re-fetch on login/logout
  final authState = ref.watch(authStateProvider);
  // manual provider might handle AsyncValue differently? 
  // authStateProvider is StreamProvider<User?>? Usually StreamProvider<User?> returns AsyncValue<User?>.
  final userId = authState.asData?.value?.uid;
  
  // Get device ID
  final deviceId = await ref.watch(deviceServiceProvider).getDeviceId();
  
  return ref.watch(offersRepositoryProvider).getMyClaims(
    userId: userId,
    deviceId: deviceId,
  );
});

// ============ SAVED OFFERS ============

/// Provides SavedOffersRepository instance
@Riverpod(keepAlive: true)
SavedOffersRepository savedOffersRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SavedOffersRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    prefs: prefs,
  );
}

/// Holds the current list of saved offer IDs
@riverpod
class SavedOffersList extends _$SavedOffersList {
  @override
  Future<List<String>> build() async {
    final saved = await ref.watch(savedOffersRepositoryProvider).getSavedOffers();
    debugPrint('📚 SavedOffersList.build() - Loaded ${saved.length} saved offers: $saved');
    return saved;
  }

  /// Save an offer
  Future<void> save(String offerId) async {
    debugPrint('💾 SavedOffersList.save($offerId)');
    await ref.read(savedOffersRepositoryProvider).saveOffer(offerId);
    ref.invalidateSelf();
  }

  /// Unsave an offer
  Future<void> unsave(String offerId) async {
    debugPrint('🗑️ SavedOffersList.unsave($offerId)');
    await ref.read(savedOffersRepositoryProvider).unsaveOffer(offerId);
    ref.invalidateSelf();
  }

  /// Toggle saved status
  Future<bool> toggle(String offerId) async {
    debugPrint('🔄 SavedOffersList.toggle($offerId) - START');
    final result = await ref.read(savedOffersRepositoryProvider).toggleSaved(offerId);
    debugPrint('🔄 SavedOffersList.toggle($offerId) - Result: $result');
    ref.invalidateSelf();
    
    // Sync to cloud if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      debugPrint('☁️ Syncing to cloud for user: ${user.uid}');
      await ref.read(savedOffersRepositoryProvider).syncToCloud(user.uid);
    }
    
    return result;
  }

  /// Sync from cloud (for logged-in users)
  Future<void> syncFromCloud(String userId) async {
    await ref.read(savedOffersRepositoryProvider).syncFromCloud(userId);
    ref.invalidateSelf();
  }
}

/// Check if a specific offer is saved
@riverpod
Future<bool> isOfferSaved(Ref ref, String offerId) async {
  final saved = await ref.watch(savedOffersListProvider.future);
  final isSaved = saved.contains(offerId);
  debugPrint('❓ isOfferSaved($offerId) = $isSaved (saved: $saved)');
  return isSaved;
}

/// Provider to get full Offer objects for saved offer IDs
@riverpod
Future<List<Offer>> savedOffersFull(Ref ref) async {
  final savedIds = await ref.watch(savedOffersListProvider.future);
  debugPrint('📦 savedOffersFull - Loading ${savedIds.length} offers: $savedIds');
  
  if (savedIds.isEmpty) {
    debugPrint('📦 savedOffersFull - No saved offers, returning empty list');
    return [];
  }
  
  final repo = ref.watch(offersRepositoryProvider);
  final offers = <Offer>[];
  
  for (final offerId in savedIds) {
    final offer = await repo.getOfferById(offerId);
    debugPrint('📦 Fetching offer $offerId: ${offer != null ? 'found' : 'NOT FOUND'}');
    if (offer != null && offer.isValid) {
      offers.add(offer);
    }
  }
  
  debugPrint('📦 savedOffersFull - Returning ${offers.length} valid offers');
  return offers;
}
