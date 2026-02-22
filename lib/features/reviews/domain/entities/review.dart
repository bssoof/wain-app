import 'package:cloud_firestore/cloud_firestore.dart';

/// Review entity — plain Dart class (no code generation needed)
class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String text;
  final String venueId;
  final DateTime createdAt;

  /// Merchant reply (null = no reply yet)
  final String? merchantReply;
  final DateTime? merchantReplyAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    this.text = '',
    required this.venueId,
    required this.createdAt,
    this.merchantReply,
    this.merchantReplyAt,
  });

  /// Whether the merchant has replied to this review.
  bool get hasReply => merchantReply != null && merchantReply!.isNotEmpty;

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    // Handle Timestamp -> DateTime
    DateTime createdAt = DateTime.now();
    final ts = data['created_at'];
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    }

    // Parse merchant reply timestamp
    DateTime? replyAt;
    final replyTs = data['merchant_reply_at'];
    if (replyTs is Timestamp) {
      replyAt = replyTs.toDate();
    }

    return Review(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'user',
      userPhotoUrl: data['user_photo_url'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      text: data['text'] ?? '',
      venueId: data['venue_id'] ?? '',
      createdAt: createdAt,
      merchantReply: data['merchant_reply'] as String?,
      merchantReplyAt: replyAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'user_photo_url': userPhotoUrl,
        'rating': rating,
        'text': text,
        'venue_id': venueId,
        'created_at': Timestamp.fromDate(createdAt),
        if (merchantReply != null) 'merchant_reply': merchantReply,
        if (merchantReplyAt != null)
          'merchant_reply_at': Timestamp.fromDate(merchantReplyAt!),
      };
}
