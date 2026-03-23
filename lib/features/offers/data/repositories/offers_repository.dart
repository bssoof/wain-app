import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';

/// Repository for offers data
abstract class OffersRepository {
  /// Get all active offers for a venue
  Future<List<Offer>> getOffersByVenue(String venueId);

  /// Get single offer by ID
  Future<Offer?> getOfferById(String offerId);

  /// Create a claim intent via Cloud Function
  Future<ClaimResult?> createClaim(OfferClaim claim);

  /// Get my claims (by user ID or device ID)
  Future<List<OfferClaim>> getMyClaims({
    String? userId,
    required String deviceId,
  });
}

/// Firestore implementation of OffersRepository
class OffersRepositoryImpl implements OffersRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  OffersRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _offersRef =>
      _firestore.collection('offers');

  @override
  Future<List<Offer>> getOffersByVenue(String venueId) async {
    try {
      final snapshot = await _offersRef
          .where('venue_id', isEqualTo: venueId)
          .get();

      final offers = snapshot.docs
          .map((doc) => Offer.fromFirestore(doc))
          .toList();

      debugPrint('Found ${offers.length} offers for venue $venueId');
      return offers;
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      return [];
    }
  }

  @override
  Future<Offer?> getOfferById(String offerId) async {
    try {
      final doc = await _offersRef.doc(offerId).get();
      if (!doc.exists) return null;
      return Offer.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching offer $offerId: $e');
      return null;
    }
  }

  @override
  Future<ClaimResult?> createClaim(OfferClaim claim) async {
    try {
      final callable = _functions.httpsCallable('createClaimToken');

      final result = await callable.call({
        'offerId': claim.offerId,
        'venueId': claim.venueId,
        'city': claim.city,
        'source': claim.source,
        'deviceId': claim.deviceId,
      });

      final data = result.data as Map<Object?, Object?>;
      final map = data.cast<String, dynamic>();

      debugPrint('Created claim via function: ${map['claimId']}');

      return ClaimResult(
        claimId: map['claimId'] as String,
        token: map['token'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Error creating claim (Functions): ${e.code} - ${e.message} - ${e.details}',
      );
      throw Exception(
        _normalizeClaimError(
          code: e.code,
          message: e.message,
          details: e.details,
        ),
      );
    } catch (e) {
      debugPrint('Error creating claim: $e');
      final normalized = _normalizeClaimError(error: e);
      if (normalized != 'claim_save_failed') {
        throw Exception(normalized);
      }
      return null;
    }
  }

  @override
  Future<List<OfferClaim>> getMyClaims({
    String? userId,
    required String deviceId,
  }) async {
    try {
      final claimsById = <String, OfferClaim>{};

      final deviceSnapshot = await _firestore
          .collection('offer_claims')
          .where('device_id', isEqualTo: deviceId)
          .get();

      for (final doc in deviceSnapshot.docs) {
        claimsById[doc.id] = OfferClaim.fromFirestore(doc);
      }

      if (userId != null) {
        final userSnapshot = await _firestore
            .collection('offer_claims')
            .where('user_id', isEqualTo: userId)
            .get();

        for (final doc in userSnapshot.docs) {
          claimsById[doc.id] = OfferClaim.fromFirestore(doc);
        }
      }

      final claims = claimsById.values.toList()
        ..sort((a, b) {
          final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      return claims;
    } catch (e) {
      debugPrint('Error fetching my claims: $e');
      return [];
    }
  }
}

String _normalizeClaimError({
  String? code,
  String? message,
  Object? details,
  Object? error,
}) {
  final parts = <String>[
    if (code != null && code.isNotEmpty) code,
    if (message != null && message.isNotEmpty) message,
    if (details is String && details.isNotEmpty) details,
    if (details is Map && details['message'] != null)
      details['message'].toString(),
    if (error != null) error.toString(),
  ];

  final raw = parts.join(' | ');
  final lowered = raw.toLowerCase();

  if (raw.contains('offer_already_used') ||
      lowered.contains('already redeemed') ||
      lowered.contains('already processed')) {
    return 'offer_already_used';
  }

  if (raw.contains('offer_expired') || lowered.contains('token expired')) {
    return 'offer_expired';
  }

  if (raw.contains('offer_inactive')) {
    return 'offer_inactive';
  }

  if (raw.contains('offer_not_started') || lowered.contains('not started')) {
    return 'offer_not_started';
  }

  if (lowered.contains('resource-exhausted') ||
      lowered.contains('rate limit')) {
    return 'resource-exhausted';
  }

  if (lowered.contains('network')) {
    return 'network-request-failed';
  }

  if (code == 'failed-precondition') {
    return 'offer_already_used';
  }

  return 'claim_save_failed';
}
