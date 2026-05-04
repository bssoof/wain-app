import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review_quality_summary.dart';

MerchantReview _review({
  required String id,
  DateTime? createdAt,
  String? merchantReply,
  DateTime? merchantReplyAt,
}) {
  return MerchantReview(
    id: id,
    userName: 'User $id',
    userPhotoUrl: null,
    rating: 4,
    text: 'review',
    createdAt: createdAt,
    merchantReply: merchantReply,
    merchantReplyAt: merchantReplyAt,
    merchantReplyBy: merchantReply == null ? null : 'merchant',
  );
}

void main() {
  group('buildMerchantReviewQualitySummary', () {
    test(
      'calculates reply rate, average reply time, and oldest unanswered',
      () {
        final now = DateTime(2026, 4, 5, 12);
        final summary = buildMerchantReviewQualitySummary([
          _review(
            id: '1',
            createdAt: now.subtract(const Duration(hours: 6)),
            merchantReply: 'thanks',
            merchantReplyAt: now.subtract(const Duration(hours: 4)),
          ),
          _review(
            id: '2',
            createdAt: now.subtract(const Duration(hours: 10)),
            merchantReply: 'welcome',
            merchantReplyAt: now.subtract(const Duration(hours: 4)),
          ),
          _review(id: '3', createdAt: now.subtract(const Duration(days: 2))),
        ]);

        expect(summary.totalReviews, 3);
        expect(summary.repliedCount, 2);
        expect(summary.replyRatePercent, closeTo(66.67, 0.01));
        expect(summary.averageReplyTime, const Duration(hours: 4));
        expect(summary.oldestUnanswered?.id, '3');
      },
    );

    test('ignores invalid reply timings when averaging', () {
      final now = DateTime(2026, 4, 5, 12);
      final summary = buildMerchantReviewQualitySummary([
        _review(
          id: '1',
          createdAt: now.subtract(const Duration(hours: 4)),
          merchantReply: 'thanks',
          merchantReplyAt: now.subtract(const Duration(hours: 6)),
        ),
        _review(
          id: '2',
          createdAt: now.subtract(const Duration(hours: 6)),
          merchantReply: 'welcome',
          merchantReplyAt: now.subtract(const Duration(hours: 3)),
        ),
      ]);

      expect(summary.repliedCount, 2);
      expect(summary.averageReplyTime, const Duration(hours: 3));
      expect(summary.oldestUnanswered, isNull);
    });

    test('returns empty-friendly values when there are no replies', () {
      final now = DateTime(2026, 4, 5, 12);
      final summary = buildMerchantReviewQualitySummary([
        _review(id: '1', createdAt: now.subtract(const Duration(hours: 3))),
        _review(id: '2', createdAt: now.subtract(const Duration(hours: 1))),
      ]);

      expect(summary.totalReviews, 2);
      expect(summary.repliedCount, 0);
      expect(summary.replyRatePercent, 0);
      expect(summary.averageReplyTime, isNull);
      expect(summary.oldestUnanswered?.id, '1');
    });
  });
}
