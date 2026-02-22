import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/story.dart';
import '../providers/stories_provider.dart';
import '../screens/story_viewer_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Horizontal scrollable stories bar (Instagram-style circles)
class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotedAsync = ref.watch(promotedStoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return promotedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stories) {
        if (stories.isEmpty) return const SizedBox.shrink();

        // Group promoted stories by venue
        final grouped = <String, List<Story>>{};
        for (final story in stories) {
          grouped.putIfAbsent(story.venueId, () => []).add(story);
        }

        final venueIds = grouped.keys.toList();
        final allGroups = venueIds.map((id) => grouped[id]!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8),
          child: Text(
            l10n.storiesBarTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: venueIds.length,
            itemBuilder: (context, index) {
              final venueId = venueIds[index];
              final venueStories = grouped[venueId]!;
              final firstStory = venueStories.first;
              final venueName = firstStory.venueName.isNotEmpty ? firstStory.venueName : l10n.storiesBarDefaultVenue;

              return RepaintBoundary(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          groupedStories: allGroups,
                          initialGroupIndex: index,
                          initialStoryIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        // Circle avatar with gradient ring
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.amber, Colors.orange, Colors.deepOrange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: firstStory.venuePhotoUrl != null
                                      ? CachedNetworkImageProvider(firstStory.venuePhotoUrl!)
                                      : null,
                                  child: firstStory.venuePhotoUrl == null
                                      ? Icon(Icons.store,
                                          color: Colors.grey.shade400, size: 24)
                                      : null,
                                ),
                              ),
                            ),
                            // Promoted badge
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(Icons.star, size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Venue name
                        SizedBox(
                          width: 70,
                          child: Text(
                            venueName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
      },
    );
  }
}
