import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/review.dart';
import '../../data/repositories/reviews_repository_impl.dart';

/// Repository provider
final reviewsRepositoryProvider = Provider<ReviewsRepositoryImpl>((ref) {
  return ReviewsRepositoryImpl();
});

/// Stream of reviews for a venue
final venueReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, venueId) {
  return ref.watch(reviewsRepositoryProvider).watchVenueReviews(venueId);
});

/// Rating summary for a venue
final venueRatingSummaryProvider = FutureProvider.family<
    ({double avgRating, int reviewCount}), String>((ref, venueId) {
  return ref.watch(reviewsRepositoryProvider).getVenueRatingSummary(venueId);
});

/// Check if current user has already reviewed this venue
final userReviewProvider = FutureProvider.family<Review?,
    ({String venueId, String userId})>((ref, params) {
  return ref
      .watch(reviewsRepositoryProvider)
      .getUserReview(params.venueId, params.userId);
});

/// Submit review action
final submitReviewProvider = FutureProvider.family<void,
    ({
      String venueId,
      String userId,
      String userName,
      String? userPhotoUrl,
      double rating,
      String text,
    })>((ref, params) async {
  await ref.read(reviewsRepositoryProvider).submitReview(
        venueId: params.venueId,
        userId: params.userId,
        userName: params.userName,
        userPhotoUrl: params.userPhotoUrl,
        rating: params.rating,
        text: params.text,
      );

  // Invalidate cache to refresh UI
  ref.invalidate(venueReviewsProvider(params.venueId));
  ref.invalidate(venueRatingSummaryProvider(params.venueId));
});

/// Delete review action
final deleteReviewProvider = FutureProvider.family<void,
    ({String venueId, String reviewId})>((ref, params) async {
  await ref
      .read(reviewsRepositoryProvider)
      .deleteReview(params.venueId, params.reviewId);

  // Invalidate cache
  ref.invalidate(venueReviewsProvider(params.venueId));
  ref.invalidate(venueRatingSummaryProvider(params.venueId));
});
