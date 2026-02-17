import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';

/// Firestore implementation of ReviewsRepository
class ReviewsRepositoryImpl implements ReviewsRepository {
  final FirebaseFirestore _firestore;

  ReviewsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String venueId) =>
      _firestore.collection('venues').doc(venueId).collection('reviews');

  @override
  Stream<List<Review>> watchVenueReviews(String venueId) {
    return _reviewsRef(venueId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromDoc(doc)).toList());
  }

  @override
  Future<Review?> getUserReview(String venueId, String userId) async {
    final snapshot = await _reviewsRef(venueId)
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Review.fromDoc(snapshot.docs.first);
  }

  @override
  Future<void> submitReview({
    required String venueId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    required String text,
  }) async {
    try {
      // Check if user already has a review (update instead of create)
      final existing = await getUserReview(venueId, userId);

      final reviewData = <String, dynamic>{
        'user_id': userId,
        'user_name': userName,
        'user_photo_url': userPhotoUrl,
        'rating': rating,
        'text': text,
        'venue_id': venueId,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (existing != null) {
        // Update existing review
        await _reviewsRef(venueId).doc(existing.id).update(reviewData);
        debugPrint('✅ Review updated for venue $venueId');
      } else {
        // Create new review
        await _reviewsRef(venueId).add(reviewData);
        debugPrint('✅ New review added for venue $venueId');

        // Increment user's review count is now handled by Cloud Functions

      }

      // Update venue aggregate rating
      await _updateVenueRating(venueId);
    } catch (e) {
      debugPrint('❌ Error submitting review: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(String venueId, String reviewId) async {
    // Get the review to find the user_id before deleting
    // final doc = await _reviewsRef(venueId).doc(reviewId).get();
    // final userId = doc.data()?['user_id'] as String?;

    await _reviewsRef(venueId).doc(reviewId).delete();
    await _updateVenueRating(venueId);

    // Decrement user's review count is now handled by Cloud Functions


    debugPrint('🗑️ Review $reviewId deleted from venue $venueId');
  }

  @override
  Future<({double avgRating, int reviewCount})> getVenueRatingSummary(
      String venueId) async {
    final snapshot = await _reviewsRef(venueId).get();

    if (snapshot.docs.isEmpty) {
      return (avgRating: 0.0, reviewCount: 0);
    }

    double totalRating = 0;
    for (final doc in snapshot.docs) {
      totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
    }

    final avg = totalRating / snapshot.docs.length;
    return (
      avgRating: double.parse(avg.toStringAsFixed(1)),
      reviewCount: snapshot.docs.length
    );
  }

  /// Recalculate and update venue's aggregate rating
  Future<void> _updateVenueRating(String venueId) async {
    final summary = await getVenueRatingSummary(venueId);

    await _firestore.collection('venues').doc(venueId).update({
      'rating': summary.avgRating,
      'review_count': summary.reviewCount,
    });

    debugPrint(
        '📊 Venue $venueId rating updated: ${summary.avgRating} (${summary.reviewCount} reviews)');
  }
}
