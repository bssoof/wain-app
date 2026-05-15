class MerchantStory {
  final String id;
  final String type;
  final String text;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? promotedUntil;
  final bool isPromotedFlag;
  final int viewCount;

  const MerchantStory({
    required this.id,
    required this.type,
    required this.text,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    required this.expiresAt,
    required this.promotedUntil,
    required this.isPromotedFlag,
    this.viewCount = 0,
  });

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;
  bool get hasText => text.trim().isNotEmpty;

  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && expiry.isBefore(now);
  }

  bool isPromotedAt(DateTime now) {
    final until = promotedUntil;
    if (until != null) {
      return until.isAfter(now);
    }

    return isPromotedFlag && !isExpiredAt(now);
  }
}
