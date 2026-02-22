import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import '../../domain/entities/story.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Full-screen Instagram-style story viewer.
/// Supports images, videos, text, and offers.
/// Features: progress bars, tap navigation, swipe between venues,
/// swipe down to dismiss, venue navigation, and precaching.
class StoryViewerScreen extends ConsumerStatefulWidget {
  /// Grouped stories: each inner list is one venue's stories
  final List<List<Story>> groupedStories;
  final int initialGroupIndex;
  final int initialStoryIndex;

  const StoryViewerScreen({
    super.key,
    required this.groupedStories,
    this.initialGroupIndex = 0,
    this.initialStoryIndex = 0,
  });

  /// Legacy constructor: single venue stories
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
  late PageController _pageController;
  late int _currentGroupIndex;
  late int _currentStoryIndex;
  late AnimationController _progressController;

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  // bool _imageLoaded = false; // Removed

  static const _defaultDuration = Duration(seconds: 5);

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
    // Defer loading until after first frame so context is available for precacheImage
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

  // ── Story lifecycle ──

  void _loadCurrentStory() {
    final story = _currentStory;
    // _imageLoaded = false;
    _videoInitialized = false;

    // Dispose previous video
    _videoController?.dispose();
    _videoController = null;

    _progressController.reset();

    if (story.isVideo) {
      _initVideoPlayer(story);
    } else if (story.imageUrl != null && story.imageUrl!.isNotEmpty) {
      // Image — start progress after image loads
      _progressController.duration = Duration(
        seconds: story.durationSeconds > 0 ? story.durationSeconds : 5,
      );
      // Precache will trigger _onImageLoaded once done
      _precacheCurrentImage();
    } else {
      // Text / offer: auto start
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
    if (url != null && url.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(url), context)
          .then((_) {
            if (mounted) {
              // setState(() => _imageLoaded = true);
              _progressController.forward();
            }
          })
          .catchError((_) {
            if (mounted) {
              // setState(() => _imageLoaded = true);
              _progressController.forward();
            }
          });
    }
  }

  void _precacheNextImage() {
    // Precache the next story image for instant loading
    Story? nextStory;
    if (_currentStoryIndex < _currentStories.length - 1) {
      nextStory = _currentStories[_currentStoryIndex + 1];
    } else if (_currentGroupIndex < widget.groupedStories.length - 1) {
      final nextGroup = widget.groupedStories[_currentGroupIndex + 1];
      if (nextGroup.isNotEmpty) nextStory = nextGroup.first;
    }
    if (nextStory != null && nextStory.imageUrl != null) {
      precacheImage(
        CachedNetworkImageProvider(nextStory.imageUrl!),
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
      if (!mounted) return;

      setState(() => _videoInitialized = true);

      // Set progress duration to video length
      final videoDuration = controller.value.duration;
      _progressController.duration = videoDuration;

      controller.play();
      _progressController.forward();
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        // Fallback: show as text story
        _progressController.duration = _defaultDuration;
        _progressController.forward();
      }
    }
  }

  void _incrementViewCount(Story story) {
    FirebaseFirestore.instance
        .collection('stories')
        .doc(story.id)
        .update({'view_count': FieldValue.increment(1)})
        .catchError((e) => debugPrint('Failed to increment view count: $e'));

    ref
        .read(analyticsServiceProvider)
        .trackVenueEvent(
          venueId: story.venueId,
          eventType: 'story_view',
          source: 'story_viewer',
        );
  }

  // ── Navigation ──

  void _nextStory() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      setState(() => _currentStoryIndex++);
      _loadCurrentStory();
    } else {
      // Move to next venue group
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
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _loadCurrentStory();
    } else if (_currentGroupIndex > 0) {
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
    final venueId = _currentStory.venueId;
    Navigator.pop(context);
    context.push('/venue/$venueId');
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
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
          // Swipe down to dismiss
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // ── Story content ──
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.groupedStories.length,
              itemBuilder: (ctx, groupIndex) {
                return RepaintBoundary(
                  child: Center(child: _buildStoryContent(_currentStory)),
                );
              },
            ),

            // ── Top overlay: progress bars + venue info ──
            SafeArea(
              child: Column(
                children: [
                  // Progress bars
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: List.generate(_currentStories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double value;
                                if (index < _currentStoryIndex) {
                                  value = 1.0;
                                } else if (index == _currentStoryIndex) {
                                  value = _progressController.value;
                                } else {
                                  value = 0.0;
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                    color: Colors.white,
                                    minHeight: 3,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Venue info bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        // Tappable venue avatar
                        GestureDetector(
                          onTap: _navigateToVenue,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade700,
                            backgroundImage: _currentStory.venuePhotoUrl != null
                                ? CachedNetworkImageProvider(
                                    _currentStory.venuePhotoUrl!,
                                  )
                                : null,
                            child: _currentStory.venuePhotoUrl == null
                                ? const Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToVenue,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentStory.venueName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatTime(_currentStory.createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom: "Visit Venue" button ──
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: GestureDetector(
                onTap: _navigateToVenue,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.store_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'زيارة ${_currentStory.venueName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content builders ──

  Widget _buildStoryContent(Story story) {
    if (story.isVideo) {
      return _buildVideoStory(story);
    } else if (story.imageUrl != null && story.imageUrl!.isNotEmpty) {
      return _buildImageStory(story);
    } else if (story.offerRef != null) {
      return _buildOfferStory(story);
    } else {
      return _buildTextStory(story.text.isNotEmpty ? story.text : '✨');
    }
  }

  Widget _buildImageStory(Story story) {
    return CachedNetworkImage(
      imageUrl: story.imageUrl!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (ctx, url) => const Center(child: WainLoadingIndicator()),
      errorWidget: (ctx, url, error) =>
          _buildTextStory(story.text.isNotEmpty ? story.text : '📷'),
    );
  }

  Widget _buildVideoStory(Story story) {
    if (!_videoInitialized || _videoController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WainLoadingIndicator(),
            SizedBox(height: 12),
            Text(
              'جاري تحميل الفيديو...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
    return Container(
      padding: const EdgeInsets.all(40),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOfferStory(Story story) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.9),
            Colors.amber.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'عرض خاص!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            story.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'افتح التطبيق للتفعيل',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'أمس';
  }
}
