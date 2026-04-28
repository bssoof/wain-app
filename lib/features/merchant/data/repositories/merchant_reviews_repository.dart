import 'package:cloud_firestore/cloud_firestore.dart';

abstract class MerchantReviewsRepository {
  Future<void> submitReply({
    required String venueId,
    required String reviewId,
    required String replyText,
    required String authorIdentifier,
  });

  Future<void> deleteReply({required String venueId, required String reviewId});
}

class FirestoreMerchantReviewsRepository implements MerchantReviewsRepository {
  final FirebaseFirestore _firestore;

  FirestoreMerchantReviewsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitReply({
    required String venueId,
    required String reviewId,
    required String replyText,
    required String authorIdentifier,
  }) {
    return _reviewsRef(venueId).doc(reviewId).update({
      'merchant_reply': replyText.trim(),
      'merchant_reply_at': FieldValue.serverTimestamp(),
      'merchant_reply_by': authorIdentifier,
    });
  }

  @override
  Future<void> deleteReply({
    required String venueId,
    required String reviewId,
  }) {
    return _reviewsRef(venueId).doc(reviewId).update({
      'merchant_reply': FieldValue.delete(),
      'merchant_reply_at': FieldValue.delete(),
      'merchant_reply_by': FieldValue.delete(),
    });
  }

  CollectionReference<Map<String, dynamic>> _reviewsRef(String venueId) {
    return _firestore.collection('venues').doc(venueId).collection('reviews');
  }
}
