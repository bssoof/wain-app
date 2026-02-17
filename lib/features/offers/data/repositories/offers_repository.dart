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
  Future<List<OfferClaim>> getMyClaims({String? userId, required String deviceId});
}

/// Firestore implementation of OffersRepository
class OffersRepositoryImpl implements OffersRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  OffersRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _offersRef =>
      _firestore.collection('offers');

  @override
  Future<List<Offer>> getOffersByVenue(String venueId) async {
    try {
      // Query active offers for this venue
      final snapshot = await _offersRef
          .where('venue_id', isEqualTo: venueId)
          // .where('is_active', isEqualTo: true) // Index pending
          .get();

      final offers = snapshot.docs
          .map((doc) => Offer.fromFirestore(doc))
          .toList();

      debugPrint('🎁 Found ${offers.length} active offers for venue $venueId');
      return offers;
    } catch (e) {
      debugPrint('❌ Error fetching offers: $e');
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
      debugPrint('❌ Error fetching offer $offerId: $e');
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
        // userId is handled automatically by context.auth if logged in
      });
      
      final data = result.data as Map<Object?, Object?>;
      // Convert map to ensure String keys
      final map = data.cast<String, dynamic>();

      debugPrint('✅ Created claim via function: ${map['claimId']}');
      
      return ClaimResult(
        claimId: map['claimId'] as String,
        token: map['token'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Error creating claim (Functions): ${e.code} - ${e.message}');
      
      // Extract clean message
      String message = e.message ?? 'فشل في حفظ الطلب';
      
      // Override specific error codes for better UX
      if (e.code == 'failed-precondition') {
        message = 'لقد تمت الاستفاده من العرض من قبلكم';
      } else if (e.details is Map) {
        final details = e.details as Map;
        if (details.containsKey('message')) {
          message = details['message'] as String;
        }
      } else if (e.details is String) {
        message = e.details as String;
      }
      
      // Throw as simple Exception so Provider catches it safely
      throw Exception(message);
    } catch (e) {
      debugPrint('❌ Error creating claim: $e');
      return null;
    }
  }

  @override
  Future<List<OfferClaim>> getMyClaims({String? userId, required String deviceId}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('offer_claims');

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      } else {
        query = query.where('device_id', isEqualTo: deviceId);
      }
      
      // Order by latest first
      // Note: Needs composite index if mixed with where clause on some fields, 
      // but simplistic usage here usually fine or auto-suggested by SDK
      query = query.orderBy('timestamp', descending: true);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => OfferClaim.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching my claims: $e');
      return [];
    }
  }
}
