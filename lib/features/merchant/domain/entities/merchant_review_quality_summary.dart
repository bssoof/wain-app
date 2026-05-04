import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';

class MerchantReviewQualitySummary {
  final int totalReviews;
  final int repliedCount;
  final double replyRatePercent;
  final Duration? averageReplyTime;
  final MerchantReview? oldestUnanswered;

  const MerchantReviewQualitySummary({
    required this.totalReviews,
    required this.repliedCount,
    required this.replyRatePercent,
    required this.averageReplyTime,
    required this.oldestUnanswered,
  });

  bool get hasReviews => totalReviews > 0;
}

MerchantReviewQualitySummary buildMerchantReviewQualitySummary(
  List<MerchantReview> reviews,
) {
  final totalReviews = reviews.length;
  final replied = reviews.where((review) => review.hasReply).toList();
  final repliedCount = replied.length;
  final replyRatePercent = totalReviews == 0
      ? 0.0
      : (repliedCount / totalReviews) * 100;

  var totalReplyMillis = 0;
  var validReplyDurations = 0;
  for (final review in replied) {
    final createdAt = review.createdAt;
    final replyAt = review.merchantReplyAt;
    if (createdAt == null || replyAt == null || replyAt.isBefore(createdAt)) {
      continue;
    }
    totalReplyMillis += replyAt.difference(createdAt).inMilliseconds;
    validReplyDurations += 1;
  }

  final averageReplyTime = validReplyDurations == 0
      ? null
      : Duration(milliseconds: totalReplyMillis ~/ validReplyDurations);

  MerchantReview? oldestUnanswered;
  for (final review in reviews) {
    if (review.hasReply) {
      continue;
    }
    final createdAt = review.createdAt;
    if (createdAt == null) {
      continue;
    }
    if (oldestUnanswered == null ||
        createdAt.isBefore(oldestUnanswered.createdAt!)) {
      oldestUnanswered = review;
    }
  }

  return MerchantReviewQualitySummary(
    totalReviews: totalReviews,
    repliedCount: repliedCount,
    replyRatePercent: replyRatePercent,
    averageReplyTime: averageReplyTime,
    oldestUnanswered: oldestUnanswered,
  );
}
