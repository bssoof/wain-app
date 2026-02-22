import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/services/deep_link_service.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/try_list/presentation/providers/try_list_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

class VenueHeroHeader extends ConsumerStatefulWidget {
  final Venue venue;
  final bool isFavorite;

  const VenueHeroHeader({
    super.key,
    required this.venue,
    required this.isFavorite,
  });

  @override
  ConsumerState<VenueHeroHeader> createState() => _VenueHeroHeaderState();
}

class _VenueHeroHeaderState extends ConsumerState<VenueHeroHeader> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final venue = widget.venue;

    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      snap: true,
      pinned: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/results');
          }
        },
      ),
      actions: [
        IconButton(
          icon: _circleIcon(
            Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
          ),
          onPressed: () {
            ref.read(favoritesListProvider.notifier).toggle(venue.id);
          },
        ),
        IconButton(
          icon: _circleIcon(
            ref
                .watch(isInTryListProvider(venue.id))
                .when(
                  data: (inList) => Icon(
                    inList ? Icons.flag : Icons.flag_outlined,
                    color: inList ? AppTheme.primaryColor : Colors.grey,
                  ),
                  loading: () =>
                      const Icon(Icons.flag_outlined, color: Colors.grey),
                  error: (_, _) =>
                      const Icon(Icons.flag_outlined, color: Colors.grey),
                ),
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final added = await ref
                .read(tryListNotifierProvider.notifier)
                .toggle(venue.id);
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  added ? l10n.tryListAdded : l10n.tryListRemoved(venue.nameAr),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: _circleIcon(const Icon(Icons.share, color: Colors.grey)),
          onPressed: () async {
            ref
                .read(analyticsServiceProvider)
                .logShareClick(
                  venueId: venue.id,
                  venueName: venue.nameAr,
                  city: venue.city,
                  source: 'venue_details',
                );
            await DeepLinkService.shareVenue(
              venueId: venue.id,
              venueName: venue.nameAr,
              city: venue.city,
              shareMessage: AppLocalizations.of(context)!.shareVenueText,
              rating: venue.rating,
              category: venue.categories.isNotEmpty
                  ? venue.categories.first
                  : null,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: venue.photos.isNotEmpty
            ? _buildPhotoGallery(venue)
            : Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  Widget _circleIcon(Widget child) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPhotoGallery(Venue venue) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio.clamp(1.0, 2.0);
    final cacheWidth = (mediaQuery.size.width * devicePixelRatio).round();
    final cacheHeight = (100 * devicePixelRatio).round();

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: venue.photos.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, index) {
            return CachedNetworkImage(
              imageUrl: venue.photos[index],
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              memCacheWidth: cacheWidth,
              memCacheHeight: cacheHeight,
              maxWidthDiskCache: cacheWidth,
              maxHeightDiskCache: cacheHeight,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, _) => Container(color: Colors.grey.shade300),
              errorWidget: (_, _, _) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
              ),
            );
          },
        ),
        if (venue.photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(venue.photos.length, (i) {
                return AnimatedContainer(
                  duration: kVenueUiMotionDuration,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        if (venue.photos.length > 1)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${venue.photos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
