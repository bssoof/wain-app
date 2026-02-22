import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';
import 'package:wain_app/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueStoriesSection extends ConsumerWidget {
  final String venueId;
  static const double _storyThumbSize = 70;
  static const int _storyThumbCacheSize = 140;

  const VenueStoriesSection({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.venueStories,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: storyObjects.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final story = storyObjects[index];
                  final imageUrl = story.imageUrl;
                  final isVideo = story.isVideo;

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen.single(
                            stories: storyObjects,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: _storyThumbSize,
                          height: _storyThumbSize,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: imageUrl == null
                                ? Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      isVideo
                                          ? Icons.videocam
                                          : Icons.text_fields,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: _storyThumbSize,
                                    height: _storyThumbSize,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.low,
                                    memCacheWidth: _storyThumbCacheSize,
                                    memCacheHeight: _storyThumbCacheSize,
                                    maxWidthDiskCache: _storyThumbCacheSize,
                                    maxHeightDiskCache: _storyThumbCacheSize,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey.shade200),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.grey.shade200,
                                          child: Icon(
                                            isVideo
                                                ? Icons.videocam
                                                : Icons.text_fields,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 70,
                          child: Text(
                            story.text.isNotEmpty
                                ? story.text
                                : (isVideo ? l10n.video : l10n.story),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
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
