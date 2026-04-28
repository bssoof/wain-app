import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_reviews_repository.dart';

void main() {
  group('FirestoreMerchantReviewsRepository', () {
    test('submitReply updates reply fields', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('venues')
          .doc('venue-1')
          .collection('reviews')
          .doc('review-1')
          .set({'text': 'review'});

      final repository = FirestoreMerchantReviewsRepository(
        firestore: firestore,
      );

      await repository.submitReply(
        venueId: 'venue-1',
        reviewId: 'review-1',
        replyText: 'Thanks for visiting',
        authorIdentifier: 'Merchant Owner',
      );

      final snapshot = await firestore
          .collection('venues')
          .doc('venue-1')
          .collection('reviews')
          .doc('review-1')
          .get();

      expect(snapshot.data()?['merchant_reply'], 'Thanks for visiting');
      expect(snapshot.data()?['merchant_reply_by'], 'Merchant Owner');
      expect(snapshot.data()?['merchant_reply_at'], isNotNull);
    });

    test('deleteReply removes reply fields', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('venues')
          .doc('venue-1')
          .collection('reviews')
          .doc('review-2')
          .set({
            'merchant_reply': 'Thanks',
            'merchant_reply_by': 'Merchant Owner',
            'merchant_reply_at': DateTime(2026, 4, 2).toIso8601String(),
          });

      final repository = FirestoreMerchantReviewsRepository(
        firestore: firestore,
      );

      await repository.deleteReply(venueId: 'venue-1', reviewId: 'review-2');

      final snapshot = await firestore
          .collection('venues')
          .doc('venue-1')
          .collection('reviews')
          .doc('review-2')
          .get();

      expect(snapshot.data()?['merchant_reply'], isNull);
      expect(snapshot.data()?['merchant_reply_by'], isNull);
      expect(snapshot.data()?['merchant_reply_at'], isNull);
    });
  });
}
