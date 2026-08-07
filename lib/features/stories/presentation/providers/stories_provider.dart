import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/story.dart';
// Repository provider is removed as we use direct streams
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/features/demo/data/demo_stories_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';

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

/// Stream of active stories for a specific venue.
///
/// Reads the top-level `stories` collection — the one `MerchantStoriesRepository`
/// writes to. Until this was consolidated, a second provider of the same name
/// lived in `venue_providers.dart` serving raw maps, and it was that one
/// `VenueStoriesSection` actually watched; this one queried a
/// `venues/{id}/stories` subcollection nothing has ever written to. The
/// collision hid a demo leak — intercepting this provider left the other one
/// reaching Firestore for the demo venue while the tests stayed green.
///
/// Filtering and ordering stay client-side, as they were on the surviving
/// provider, so no composite index is required.
final venueStoriesProvider = StreamProvider.family<List<Story>, String>((
  ref,
  venueId,
) {
  // Local catalog, so the demo neither reads the stories collection nor writes
  // a view_count back to it.
  if (DemoMode.isDemoVenue(venueId)) {
    return Stream<List<Story>>.value(buildDemoStories());
  }

  return FirebaseFirestore.instance
      .collection('stories')
      .where('venue_id', isEqualTo: venueId)
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();

        return snapshot.docs
            // Read off the raw field rather than `Story.expiresAt`, which
            // falls back to created_at + 24h: a story with no expiry counts as
            // expired here, which is the stricter reading and what this stream
            // did before the merge.
            .where((doc) {
              final expiresAt = doc.data()['expires_at'];
              return expiresAt is Timestamp && expiresAt.toDate().isAfter(now);
            })
            .map(Story.fromDoc)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
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
