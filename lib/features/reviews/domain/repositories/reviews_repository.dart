import '../entities/review.dart';

/// Abstract interface for reviews operations
abstract class ReviewsRepository {
  /// Get all reviews for a venue, ordered by newest first
  Stream<List<Review>> watchVenueReviews(String venueId);

  /// Get a single review by the current user for a venue
  Future<Review?> getUserReview(String venueId, String userId);

  /// Submit a new review or update existing one
  Future<void> submitReview({
    required String venueId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    required String text,
  });

  /// Delete a review
  Future<void> deleteReview(String venueId, String reviewId);

  /// Get venue rating summary (avg rating, count)
  Future<({double avgRating, int reviewCount})> getVenueRatingSummary(String venueId);
}
