import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/review.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';

/// Repository provider
final reviewsRepositoryProvider = Provider<ReviewsRepositoryImpl>((ref) {
  return ReviewsRepositoryImpl();
});

/// Stream of reviews for a venue
final venueReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  venueId,
) {
  // Demo reviews are local fixtures. Reading them from Firestore would be
  // harmless, but writing one back would move a real venue's rating, so the
  // whole surface is served from the catalog instead.
  if (DemoMode.isDemoVenue(venueId)) {
    return Stream<List<Review>>.value(buildDemoReviews());
  }
  return ref.watch(reviewsRepositoryProvider).watchVenueReviews(venueId);
});

/// Rating summary for a venue
final venueRatingSummaryProvider =
    FutureProvider.family<({double avgRating, int reviewCount}), String>((
      ref,
      venueId,
    ) {
      if (DemoMode.isDemoVenue(venueId)) {
        return Future.value((
          avgRating: demoReviewsAverage(),
          reviewCount: buildDemoReviews().length,
        ));
      }
      return ref
          .watch(reviewsRepositoryProvider)
          .getVenueRatingSummary(venueId);
    });

/// Check if current user has already reviewed this venue
final userReviewProvider =
    FutureProvider.family<Review?, ({String venueId, String userId})>((
      ref,
      params,
    ) {
      if (DemoMode.isDemoVenue(params.venueId)) {
        return Future<Review?>.value(demoSubmittedReview);
      }
      return ref
          .watch(reviewsRepositoryProvider)
          .getUserReview(params.venueId, params.userId);
    });

/// Submit review action
final submitReviewProvider =
    FutureProvider.family<
      void,
      ({
        String venueId,
        String userId,
        String userName,
        String? userPhotoUrl,
        double rating,
        String text,
      })
    >((ref, params) async {
      // A review write moves a venue's rating and review_count. For a venue
      // that does not exist that write has nowhere legitimate to land, so the
      // demo keeps it in memory and never reaches the repository.
      if (DemoMode.isDemoVenue(params.venueId)) {
        recordDemoSubmittedReview(
          rating: params.rating,
          text: params.text,
          userName: params.userName,
          userPhotoUrl: params.userPhotoUrl,
        );
        return;
      }
      await ref
          .read(reviewsRepositoryProvider)
          .submitReview(
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
final deleteReviewProvider =
    FutureProvider.family<void, ({String venueId, String reviewId})>((
      ref,
      params,
    ) async {
      await ref
          .read(reviewsRepositoryProvider)
          .deleteReview(params.venueId, params.reviewId);

      // Invalidate cache
      ref.invalidate(venueReviewsProvider(params.venueId));
      ref.invalidate(venueRatingSummaryProvider(params.venueId));
    });
