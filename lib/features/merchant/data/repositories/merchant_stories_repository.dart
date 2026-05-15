import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';

class StoryPromotionPricing {
  final String currency;
  final double oneDayPrice;
  final double threeDayPrice;
  final double sevenDayPrice;

  const StoryPromotionPricing({
    required this.currency,
    required this.oneDayPrice,
    required this.threeDayPrice,
    required this.sevenDayPrice,
  });

  double priceForDuration(int durationDays) {
    switch (durationDays) {
      case 1:
        return oneDayPrice;
      case 3:
        return threeDayPrice;
      case 7:
        return sevenDayPrice;
      default:
        throw ArgumentError.value(
          durationDays,
          'durationDays',
          'Unsupported promotion duration',
        );
    }
  }
}

class StoryPromotionFailure implements Exception {
  final String code;
  final String message;

  const StoryPromotionFailure({required this.code, required this.message});

  @override
  String toString() => 'StoryPromotionFailure(code: $code, message: $message)';
}

abstract class MerchantStoriesRepository {
  Stream<List<MerchantStory>> watchStories({
    required String venueId,
    int limit = 20,
  });

  Future<StoryPromotionPricing> getStoryPromotionPricing();

  Future<void> promoteStory({
    required String storyId,
    required int durationDays,
    required String requestId,
  });

  Future<void> deleteStory({
    required String storyId,
    String? imageUrl,
    String? videoUrl,
  });

  Future<void> createStory({
    required String venueId,
    required String text,
    required int expiryHours,
    required String? createdBy,
    XFile? image,
    XFile? video,
  });

  Future<bool> hasActiveStory({required String venueId, DateTime? now});
}

class FirebaseMerchantStoriesRepository implements MerchantStoriesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  FirebaseMerchantStoriesRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Stream<List<MerchantStory>> watchStories({
    required String venueId,
    int limit = 20,
  }) {
    return _firestore
        .collection('stories')
        .where('venue_id', isEqualTo: venueId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _mapMerchantStory({'id': doc.id, ...doc.data()}))
              .toList();
        });
  }

  @override
  Future<StoryPromotionPricing> getStoryPromotionPricing() async {
    final snapshot = await _firestore
        .collection('wallet_feature_pricing')
        .doc('default')
        .get();
    final data = snapshot.data();
    if (data == null) {
      throw const StoryPromotionFailure(
        code: 'failed-precondition',
        message: 'pricing_unavailable',
      );
    }

    final oneDayPrice = (data['story_promote_1d'] as num?)?.toDouble();
    final threeDayPrice = (data['story_promote_3d'] as num?)?.toDouble();
    final sevenDayPrice = (data['story_promote_7d'] as num?)?.toDouble();
    final currency = (data['currency'] as String?)?.trim() ?? 'ILS';

    if (oneDayPrice == null ||
        threeDayPrice == null ||
        sevenDayPrice == null ||
        oneDayPrice <= 0 ||
        threeDayPrice <= 0 ||
        sevenDayPrice <= 0) {
      throw const StoryPromotionFailure(
        code: 'failed-precondition',
        message: 'pricing_unavailable',
      );
    }

    return StoryPromotionPricing(
      currency: currency,
      oneDayPrice: oneDayPrice,
      threeDayPrice: threeDayPrice,
      sevenDayPrice: sevenDayPrice,
    );
  }

  @override
  Future<void> promoteStory({
    required String storyId,
    required int durationDays,
    required String requestId,
  }) async {
    try {
      await _functions.httpsCallable('promoteStory').call({
        'storyId': storyId,
        'durationDays': durationDays,
        'requestId': requestId,
      });
    } on FirebaseFunctionsException catch (error) {
      final message = (error.message ?? error.code).trim();
      throw StoryPromotionFailure(
        code: error.code,
        message: message.isEmpty ? error.code : message,
      );
    }
  }

  @override
  Future<void> deleteStory({
    required String storyId,
    String? imageUrl,
    String? videoUrl,
  }) async {
    await _firestore.collection('stories').doc(storyId).delete();
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (_) {}
    }
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      try {
        await _storage.refFromURL(videoUrl).delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> createStory({
    required String venueId,
    required String text,
    required int expiryHours,
    required String? createdBy,
    XFile? image,
    XFile? video,
  }) async {
    final venueDoc = await _firestore.collection('venues').doc(venueId).get();
    final venueData = venueDoc.data() ?? <String, dynamic>{};
    final venueName = venueData['name_ar'] ?? venueData['name'] ?? '';
    final venuePhotos = venueData['photos'] as List?;
    final venuePhotoUrl = venuePhotos != null && venuePhotos.isNotEmpty
        ? venuePhotos.first as String?
        : null;

    String? imageUrl;
    String? videoUrl;

    if (image != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(
        'venues/$venueId/stories/$fileName',
      );
      await storageRef.putFile(File(image.path));
      imageUrl = await storageRef.getDownloadURL();
    }

    if (video != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final storageRef = _storage.ref().child(
        'venues/$venueId/stories/$fileName',
      );
      await storageRef.putFile(File(video.path));
      videoUrl = await storageRef.getDownloadURL();
    }

    var storyType = 'text';
    if (imageUrl != null) {
      storyType = 'image';
    }
    if (videoUrl != null) {
      storyType = 'video';
    }

    final now = DateTime.now();
    await _firestore.collection('stories').add({
      'venue_id': venueId,
      'venue_name': venueName,
      'venue_photo_url': venuePhotoUrl,
      'type': storyType,
      'text': text,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'created_at': Timestamp.fromDate(now),
      'expires_at': Timestamp.fromDate(now.add(Duration(hours: expiryHours))),
      'created_by': createdBy,
    });

    await _firestore.collection('venues').doc(venueId).update({
      'last_story_at': Timestamp.fromDate(now),
    });
  }

  @override
  Future<bool> hasActiveStory({required String venueId, DateTime? now}) async {
    final activeAfter = Timestamp.fromDate(now ?? DateTime.now());
    final snapshot = await _firestore
        .collection('stories')
        .where('venue_id', isEqualTo: venueId)
        .where('expires_at', isGreaterThan: activeAfter)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}

MerchantStory _mapMerchantStory(Map<String, dynamic> data) {
  return MerchantStory(
    id: (data['id'] as String? ?? '').trim(),
    type: (data['type'] as String? ?? 'text').trim(),
    text: (data['text'] as String? ?? '').trim(),
    imageUrl: (data['image_url'] as String?)?.trim(),
    videoUrl: (data['video_url'] as String?)?.trim(),
    createdAt: _parseDateTime(data['created_at']),
    expiresAt: _parseDateTime(data['expires_at']),
    promotedUntil: _parseDateTime(data['promoted_until']),
    isPromotedFlag: data['is_promoted'] == true,
    viewCount: (data['view_count'] as num?)?.toInt() ?? 0,
  );
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
