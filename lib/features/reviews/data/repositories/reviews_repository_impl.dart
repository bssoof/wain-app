import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exceptions.dart';
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
        .handleError((Object error, StackTrace stackTrace) {
          throw _mapException(error, operation: 'watchVenueReviews');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) => Review.fromDoc(doc)).toList();
        });
  }

  @override
  Future<Review?> getUserReview(String venueId, String userId) async {
    try {
      final snapshot = await _reviewsRef(
        venueId,
      ).where('user_id', isEqualTo: userId).limit(1).get();

      if (snapshot.docs.isEmpty) return null;
      return Review.fromDoc(snapshot.docs.first);
    } catch (error) {
      _logError('getUserReview', error);
      throw _mapException(error, operation: 'getUserReview');
    }
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
        await _reviewsRef(venueId).doc(existing.id).update(reviewData);
        debugPrint('Review updated for venue $venueId');
      } else {
        await _reviewsRef(venueId).add(reviewData);
        debugPrint('New review added for venue $venueId');
      }
    } catch (error) {
      _logError('submitReview', error);
      throw _mapException(error, operation: 'submitReview');
    }
  }

  @override
  Future<void> deleteReview(String venueId, String reviewId) async {
    try {
      await _reviewsRef(venueId).doc(reviewId).delete();
      debugPrint('Review $reviewId deleted from venue $venueId');
    } catch (error) {
      _logError('deleteReview', error);
      throw _mapException(error, operation: 'deleteReview');
    }
  }

  @override
  Future<({double avgRating, int reviewCount})> getVenueRatingSummary(
    String venueId,
  ) async {
    try {
      final snapshot = await _reviewsRef(venueId).get();

      if (snapshot.docs.isEmpty) {
        return (avgRating: 0.0, reviewCount: 0);
      }

      var totalRating = 0.0;
      for (final doc in snapshot.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }

      final avg = totalRating / snapshot.docs.length;
      return (
        avgRating: double.parse(avg.toStringAsFixed(1)),
        reviewCount: snapshot.docs.length,
      );
    } catch (error) {
      _logError('getVenueRatingSummary', error);
      throw _mapException(error, operation: 'getVenueRatingSummary');
    }
  }

  AppException _mapException(Object error, {required String operation}) {
    if (error is AppException) return error;

    if (error is FirebaseException) {
      return _mapFirebaseException(error, operation: operation);
    }

    if (error is TimeoutException) {
      return const AppTimeoutException();
    }

    return ReviewException('$operation failed: $error');
  }

  AppException _mapFirebaseException(
    FirebaseException error, {
    required String operation,
  }) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
        return NetworkException(error.message ?? '$operation unavailable');
      case 'deadline-exceeded':
        return const AppTimeoutException();
      case 'permission-denied':
        return ServerException(statusCode: 403, message: error.message);
      default:
        return ReviewException(error.message ?? '$operation failed');
    }
  }

  void _logError(String operation, Object error) {
    debugPrint('ReviewsRepository.$operation failed: $error');
  }
}
