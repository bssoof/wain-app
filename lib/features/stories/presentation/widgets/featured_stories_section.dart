import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/stories_provider.dart';
import '../screens/story_viewer_screen.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class FeaturedStoriesSection extends ConsumerWidget {
  const FeaturedStoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(promotedStoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return storiesAsync.when(
      data: (stories) {
        if (stories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.storiesFeaturedBadge,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo', // Ensure font consistency
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160, // Taller than standard stories
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen.single(
                            stories: stories,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: story.imageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  story.imageUrl!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade200,
                        border: Border.all(
                          color: Colors.amber,
                          width: 2,
                        ), // Gold border
                      ),
                      child: Stack(
                        children: [
                          if (story.imageUrl == null)
                            Center(
                              child: Icon(
                                Icons.text_fields,
                                color: Colors.grey,
                              ),
                            ),

                          // Gradient Overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(10),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                            ),
                          ),

                          // Venue Name
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Text(
                              story.venueName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: WainLoadingIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          l10n.storiesFeaturedError(error.toString()),
          style: const TextStyle(fontSize: 11, color: Colors.red),
        ),
      ),
    );
  }
}
