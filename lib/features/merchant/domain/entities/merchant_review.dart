class MerchantReview {
  final String id;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String text;
  final DateTime? createdAt;
  final String? merchantReply;
  final DateTime? merchantReplyAt;
  final String? merchantReplyBy;

  const MerchantReview({
    required this.id,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.text,
    required this.createdAt,
    required this.merchantReply,
    required this.merchantReplyAt,
    required this.merchantReplyBy,
  });

  bool get hasReply =>
      merchantReply != null && merchantReply!.trim().isNotEmpty;

  int get starBucket {
    final rounded = rating.round();
    if (rounded < 1) {
      return 1;
    }
    if (rounded > 5) {
      return 5;
    }
    return rounded;
  }

  String get trimmedUserName => userName.trim();
  String get trimmedText => text.trim();
}
