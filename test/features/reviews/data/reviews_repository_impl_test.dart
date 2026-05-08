import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/reviews/data/repositories/reviews_repository_impl.dart';

void main() {
  group('ReviewsRepositoryImpl', () {
    test(
      'submitReview writes the review without mutating venue aggregates',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('venues').doc('venue-1').set({
          'rating': 2.0,
          'review_count': 4,
        });

        final repository = ReviewsRepositoryImpl(firestore: firestore);

        await repository.submitReview(
          venueId: 'venue-1',
          userId: 'user-1',
          userName: 'Reviewer',
          rating: 5,
          text: 'Great',
        );

        final reviewSnapshot = await firestore
            .collection('venues')
            .doc('venue-1')
            .collection('reviews')
            .where('user_id', isEqualTo: 'user-1')
            .get();
        expect(reviewSnapshot.docs, hasLength(1));
        expect(reviewSnapshot.docs.single.data()['rating'], 5);

        final venueSnapshot = await firestore
            .collection('venues')
            .doc('venue-1')
            .get();
        expect(venueSnapshot.data()?['rating'], 2.0);
        expect(venueSnapshot.data()?['review_count'], 4);
      },
    );

    test(
      'deleteReview deletes the review without mutating venue aggregates',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('venues').doc('venue-1').set({
          'rating': 4.5,
          'review_count': 2,
        });
        await firestore
            .collection('venues')
            .doc('venue-1')
            .collection('reviews')
            .doc('review-1')
            .set({
              'user_id': 'user-1',
              'user_name': 'Reviewer',
              'rating': 5,
              'text': 'Great',
              'venue_id': 'venue-1',
            });

        final repository = ReviewsRepositoryImpl(firestore: firestore);

        await repository.deleteReview('venue-1', 'review-1');

        final reviewSnapshot = await firestore
            .collection('venues')
            .doc('venue-1')
            .collection('reviews')
            .doc('review-1')
            .get();
        expect(reviewSnapshot.exists, isFalse);

        final venueSnapshot = await firestore
            .collection('venues')
            .doc('venue-1')
            .get();
        expect(venueSnapshot.data()?['rating'], 4.5);
        expect(venueSnapshot.data()?['review_count'], 2);
      },
    );

    test(
      'getVenueRatingSummary calculates current reviews locally for the UI',
      () async {
        final firestore = FakeFirebaseFirestore();
        final reviews = firestore
            .collection('venues')
            .doc('venue-1')
            .collection('reviews');
        await reviews.doc('review-1').set({'rating': 5});
        await reviews.doc('review-2').set({'rating': 4});

        final repository = ReviewsRepositoryImpl(firestore: firestore);

        final summary = await repository.getVenueRatingSummary('venue-1');

        expect(summary.avgRating, 4.5);
        expect(summary.reviewCount, 2);
      },
    );
  });
}
