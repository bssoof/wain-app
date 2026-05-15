import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';
import 'package:wain_app/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
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
      data: (rawStories) {
        if (rawStories.isEmpty) return const SizedBox.shrink();

        final storyObjects = rawStories.map((map) {
          final createdAt =
              (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          final expiresAt =
              (map['expires_at'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(hours: 24));
          return Story(
            id: map['id'] ?? '',
            venueId: map['venue_id'] ?? venueId,
            venueName: map['venue_name'] ?? '',
            venuePhotoUrl: map['venue_photo_url'],
            type: map['type'] ?? 'text',
            imageUrl: map['image_url'],
            videoUrl: map['video_url'],
            text: map['text'] ?? '',
            offerRef: map['offer_ref'],
            createdAt: createdAt,
            expiresAt: expiresAt,
            viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
            durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 5,
          );
        }).toList();

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
                Text(l10n.venueStories, style: theme.textTheme.titleMedium),
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
                    : CachedNetworkImage(
                        imageUrl: story.imageUrl!,
                        width: VenueStoriesSection._storyThumbSize,
                        height: VenueStoriesSection._storyThumbSize,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        memCacheWidth: VenueStoriesSection._storyThumbCacheSize,
                        memCacheHeight:
                            VenueStoriesSection._storyThumbCacheSize,
                        maxWidthDiskCache:
                            VenueStoriesSection._storyThumbCacheSize,
                        maxHeightDiskCache:
                            VenueStoriesSection._storyThumbCacheSize,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) =>
                            const _StoryFallback(isVideo: false),
                        errorWidget: (context, url, error) =>
                            _StoryFallback(isVideo: story.isVideo),
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
