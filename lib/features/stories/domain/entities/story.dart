import 'package:cloud_firestore/cloud_firestore.dart';

/// Story entity for venue daily stories
class Story {
  final String id;
  final String venueId;
  final String venueName;
  final String? venuePhotoUrl;
  final String type; // "image", "video", "offer", "text"
  final String? imageUrl;
  final String? videoUrl;
  final String text;
  final String? offerRef;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? promotedUntil;
  final int viewCount;
  final int durationSeconds; // story display duration (default 5s)

  const Story({
    required this.id,
    required this.venueId,
    required this.venueName,
    this.venuePhotoUrl,
    required this.type,
    this.imageUrl,
    this.videoUrl,
    this.text = '',
    this.offerRef,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.promotedUntil,
    this.durationSeconds = 5,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory Story.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime createdAt = DateTime.now();
    final ts = data['created_at'];
    if (ts is Timestamp) createdAt = ts.toDate();

    DateTime expiresAt = createdAt.add(const Duration(hours: 24));
    final exp = data['expires_at'];
    if (exp is Timestamp) expiresAt = exp.toDate();

    return Story(
      id: doc.id,
      venueId: data['venue_id'] ?? '',
      venueName: data['venue_name'] ?? '',
      venuePhotoUrl: data['venue_photo_url'],
      type: data['type'] ?? 'text',
      imageUrl: data['image_url'],
      videoUrl: data['video_url'],
      text: data['text'] ?? '',
      offerRef: data['offer_ref'],
      createdAt: createdAt,
      expiresAt: expiresAt,
      viewCount: (data['view_count'] as num?)?.toInt() ?? 0,
      promotedUntil: data['promoted_until'] is Timestamp 
          ? (data['promoted_until'] as Timestamp).toDate() 
          : null,
      durationSeconds: (data['duration_seconds'] as num?)?.toInt() ?? 5,
    );
  }
}
