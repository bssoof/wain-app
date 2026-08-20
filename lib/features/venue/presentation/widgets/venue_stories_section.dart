import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';
import 'package:wain_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:wain_app/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_image.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueStoriesSection extends ConsumerWidget {
  final String venueId;
  static const double _storyThumbSize = 76;
  static const int _storyThumbCacheSize = 152;

  const VenueStoriesSection({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final storiesAsync = ref.watch(venueStoriesProvider(venueId));

    return storiesAsync.when(
      data: (storyObjects) {
        if (storyObjects.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    l10n.venueStories,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: storyObjects.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final story = storyObjects[index];
                  return _StoryThumb(
                    story: story,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen.single(
                            stories: storyObjects,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _StoryThumb extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const _StoryThumb({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = story.text.isNotEmpty
        ? story.text
        : (story.isVideo ? l10n.video : l10n.story);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: VenueStoriesSection._storyThumbSize,
              height: VenueStoriesSection._storyThumbSize,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: ClipOval(
                child: story.imageUrl == null
                    ? _StoryFallback(isVideo: story.isVideo)
                    // Same reason as the hero gallery: a story thumbnail may be
                    // a bundled `asset://` path, which CachedNetworkImage
                    // cannot resolve — it fell through to the text fallback.
                    : VenueMenuItemImage(
                        imageUrl: story.imageUrl!,
                        width: VenueStoriesSection._storyThumbSize,
                        height: VenueStoriesSection._storyThumbSize,
                        cacheWidth: VenueStoriesSection._storyThumbCacheSize,
                        placeholder: _StoryFallback(isVideo: story.isVideo),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryFallback extends StatelessWidget {
  final bool isVideo;

  const _StoryFallback({required this.isVideo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.text_fields_rounded,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
