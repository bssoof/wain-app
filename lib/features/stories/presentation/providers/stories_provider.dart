import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/story.dart';
// Repository provider is removed as we use direct streams
import 'package:cloud_firestore/cloud_firestore.dart';

/// Stream of all active stories (for home screen bar)
final activeStoriesProvider = StreamProvider<List<Story>>((ref) {
  final now = Timestamp.now();

  return FirebaseFirestore.instance
      .collection('stories')
      .where('expires_at', isGreaterThan: now)
      // Note: Firestore requires the first orderBy to match the inequality filter field
      // We order by expiry to satisfy the query requirement.
      // Client-side can re-sort by created_at if needed, or we add a composite index.
      .orderBy('expires_at', descending: false)
      .snapshots()
      .map((snapshot) {
        // Filter out any potential edge cases and convert
        return snapshot.docs
            .map((doc) => Story.fromDoc(doc))
            .where((s) => !s.isExpired) // Double check client-side
            .toList()
          // Optional: Sort by creation time (Newest first)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
});

/// Stream of promoted stories (Featured)
final promotedStoriesProvider = StreamProvider<List<Story>>((ref) {
  final now = Timestamp.now();

  return FirebaseFirestore.instance
      .collection('stories')
      .where('promoted_until', isGreaterThan: now)
      .orderBy('promoted_until', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) {
        // Debug logging
        final promoted = snapshot.docs
            .map((doc) => Story.fromDoc(doc))
            .where((s) => !s.isExpired)
            .toList();
        debugPrint('🔥 Promoted Stories Count: ${promoted.length}');
        return promoted;
      });
});

/// Stream of stories for a specific venue
final venueStoriesProvider = StreamProvider.family<List<Story>, String>((
  ref,
  venueId,
) {
  final now = Timestamp.now();

  return FirebaseFirestore.instance
      .collection('venues')
      .doc(venueId)
      .collection('stories')
      .where('expires_at', isGreaterThan: now)
      .orderBy('expires_at')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Story.fromDoc(doc)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
});

/// Group stories by venue for the stories bar
final groupedStoriesProvider = Provider<Map<String, List<Story>>>((ref) {
  final storiesAsync = ref.watch(activeStoriesProvider);
  return storiesAsync.when(
    data: (stories) {
      final grouped = <String, List<Story>>{};
      for (final story in stories) {
        grouped.putIfAbsent(story.venueId, () => []).add(story);
      }
      return grouped;
    },
    loading: () => {},
    error: (_, _) => {},
  );
});
