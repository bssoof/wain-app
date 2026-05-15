import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/blur_container.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../../domain/entities/story.dart';

@visibleForTesting
Map<String, Object> buildStoryVenueRouteExtra({
  required Story story,
  required Set<String> attributedStoryIds,
}) {
  final isFirstAttribution = attributedStoryIds.add(story.id);
  return <String, Object>{
    'source': isFirstAttribution ? 'story_viewer' : 'venue_details',
    if (isFirstAttribution) 'storyId': story.id,
  };
}

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<List<Story>> groupedStories;
  final int initialGroupIndex;
  final int initialStoryIndex;

  const StoryViewerScreen({
    super.key,
    required this.groupedStories,
    this.initialGroupIndex = 0,
    this.initialStoryIndex = 0,
  });

  factory StoryViewerScreen.single({
    Key? key,
    required List<Story> stories,
    int initialIndex = 0,
  }) {
    return StoryViewerScreen(
      key: key,
      groupedStories: [stories],
      initialGroupIndex: 0,
      initialStoryIndex: initialIndex,
    );
  }

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _defaultDuration = Duration(seconds: 5);

  late final PageController _pageController;
  late final AnimationController _progressController;
  late int _currentGroupIndex;
  late int _currentStoryIndex;
  final Set<String> _attributedStoryIds = <String>{};

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _currentStoryIndex = widget.initialStoryIndex;
    _pageController = PageController(initialPage: _currentGroupIndex);
    _progressController =
        AnimationController(vsync: this, duration: _defaultDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStory();
            }
          });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStory();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Story> get _currentStories => widget.groupedStories[_currentGroupIndex];
  Story get _currentStory => _currentStories[_currentStoryIndex];

  void _loadCurrentStory() {
    final story = _currentStory;
    _videoInitialized = false;
    _videoController?.dispose();
    _videoController = null;
    _progressController.reset();

    if (story.isVideo) {
      _initVideoPlayer(story);
    } else if (story.imageUrl != null && story.imageUrl!.isNotEmpty) {
      _progressController.duration = Duration(
        seconds: story.durationSeconds > 0 ? story.durationSeconds : 5,
      );
      _precacheCurrentImage();
    } else {
      _progressController.duration = Duration(
        seconds: story.durationSeconds > 0 ? story.durationSeconds : 5,
      );
      _progressController.forward();
    }

    _incrementViewCount(story);
    _precacheNextImage();
  }

  void _precacheCurrentImage() {
    final url = _currentStory.imageUrl;
    if (url == null || url.isEmpty) {
      _progressController.forward();
      return;
    }

    precacheImage(CachedNetworkImageProvider(url), context)
        .then((_) {
          if (mounted) {
            _progressController.forward();
          }
        })
        .catchError((_) {
          if (mounted) {
            _progressController.forward();
          }
        });
  }

  void _precacheNextImage() {
    Story? nextStory;

    if (_currentStoryIndex < _currentStories.length - 1) {
      nextStory = _currentStories[_currentStoryIndex + 1];
    } else if (_currentGroupIndex < widget.groupedStories.length - 1) {
      final nextGroup = widget.groupedStories[_currentGroupIndex + 1];
      if (nextGroup.isNotEmpty) {
        nextStory = nextGroup.first;
      }
    }

    if (nextStory?.imageUrl case final String nextUrl when nextUrl.isNotEmpty) {
      precacheImage(
        CachedNetworkImageProvider(nextUrl),
        context,
      ).catchError((_) {});
    }
  }

  Future<void> _initVideoPlayer(Story story) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(story.videoUrl!),
    );
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        return;
      }

      setState(() => _videoInitialized = true);
      _progressController.duration = controller.value.duration;
      controller.play();
      _progressController.forward();
    } catch (error) {
      debugPrint('Video init error: $error');
      if (mounted) {
        _progressController.duration = _defaultDuration;
        _progressController.forward();
      }
    }
  }

  void _incrementViewCount(Story story) {
    try {
      FirebaseFirestore.instance
          .collection('stories')
          .doc(story.id)
          .update({'view_count': FieldValue.increment(1)})
          .catchError((error) {
            debugPrint('Failed to increment view count: $error');
          });
    } catch (error) {
      debugPrint('Failed to increment view count: $error');
    }

    ref
        .read(analyticsServiceProvider)
        .trackVenueEvent(
          venueId: story.venueId,
          eventType: 'story_view',
          source: 'story_viewer',
        );
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      setState(() => _currentStoryIndex++);
      _loadCurrentStory();
      return;
    }

    if (_currentGroupIndex < widget.groupedStories.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStory();
      return;
    }

    Navigator.of(context).pop();
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _loadCurrentStory();
      return;
    }

    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex =
            widget.groupedStories[_currentGroupIndex].length - 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStory();
    }
  }

  void _navigateToVenue() {
    final story = _currentStory;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final extra = buildStoryVenueRouteExtra(
      story: story,
      attributedStoryIds: _attributedStoryIds,
    );

    if (navigator.canPop()) {
      navigator.pop();
    }
    router.push('/venue/${story.venueId}', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final screenWidth = mediaQuery.size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) {
          _progressController.stop();
          _videoController?.pause();
        },
        onLongPressEnd: (_) {
          _progressController.forward();
          _videoController?.play();
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.groupedStories.length,
              itemBuilder: (context, pageIndex) => RepaintBoundary(
                child: Center(child: _buildStoryContent(_currentStory)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _buildProgressBars(),
                    const SizedBox(height: AppSpacing.md),
                    _buildTopOverlay(),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.xl,
              end: AppSpacing.xl,
              bottom: mediaQuery.padding.bottom + AppSpacing.lg,
              child: _buildBottomOverlay(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(_currentStories.length, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                double value;
                if (index < _currentStoryIndex) {
                  value = 1;
                } else if (index == _currentStoryIndex) {
                  value = _progressController.value;
                } else {
                  value = 0;
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    backgroundColor: Colors.white.withAlpha(70),
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopOverlay() {
    return BlurContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderRadius: AppSpacing.radiusLg,
      sigma: 14,
      color: Colors.black.withAlpha(95),
      border: Border.all(color: Colors.white.withAlpha(35)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToVenue,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withAlpha(28),
              backgroundImage: _currentStory.venuePhotoUrl != null
                  ? CachedNetworkImageProvider(_currentStory.venuePhotoUrl!)
                  : null,
              child: _currentStory.venuePhotoUrl == null
                  ? const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: _navigateToVenue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStory.venueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(_currentStory.createdAt),
                    style: TextStyle(
                      color: Colors.white.withAlpha(190),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _navigateToVenue,
      child: BlurContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        borderRadius: AppSpacing.radiusFull,
        sigma: 14,
        color: Colors.black.withAlpha(100),
        border: Border.all(color: Colors.white.withAlpha(40)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.storyViewerVisitVenue(_currentStory.venueName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    if (story.isVideo) {
      return _buildVideoStory(story);
    }
    if (story.imageUrl != null && story.imageUrl!.isNotEmpty) {
      return _buildImageStory(story);
    }
    if (story.offerRef != null) {
      return _buildOfferStory(story);
    }
    return _buildTextStory(story.text.isNotEmpty ? story.text : '...');
  }

  Widget _buildImageStory(Story story) {
    return CachedNetworkImage(
      imageUrl: story.imageUrl!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) =>
          const Center(child: WainLoadingIndicator()),
      errorWidget: (context, url, error) =>
          _buildTextStory(story.text.isNotEmpty ? story.text : '...'),
    );
  }

  Widget _buildVideoStory(Story story) {
    if (!_videoInitialized || _videoController == null) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WainLoadingIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.storyViewerLoadingVideo,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildTextStory(String text) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildOfferStory(Story story) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.black.withAlpha(160), Colors.black.withAlpha(70)],
            ),
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: Colors.white.withAlpha(36)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(28),
                    borderRadius: AppSpacing.radiusLg,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.storyViewerSpecialOffer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  story.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  child: Text(
                    l10n.storyViewerOpenAppToActivate,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      return l10n.storyViewerMinsAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.storyViewerHoursAgo(difference.inHours);
    }
    return l10n.storyViewerYesterday;
  }
}
