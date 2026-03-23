import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/services/deep_link_service.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/utils/geo_utils.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/location/presentation/providers/location_provider.dart';
import 'package:wain_app/features/try_list/presentation/providers/try_list_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueHeroHeader extends ConsumerStatefulWidget {
  final Venue venue;
  final bool isFavorite;
  final List<String> displayTags;

  const VenueHeroHeader({
    super.key,
    required this.venue,
    required this.isFavorite,
    required this.displayTags,
  });

  @override
  ConsumerState<VenueHeroHeader> createState() => _VenueHeroHeaderState();
}

class _VenueHeroHeaderState extends ConsumerState<VenueHeroHeader> {
  static const double _expandedHeroHeight = 304;
  static const double _imageHeight = 304;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final venue = widget.venue;
    final distanceAsync = ref.watch(userLocationProvider);
    final distanceText = distanceAsync.when(
      data: (position) {
        if (position == null) {
          return l10n.venueSummaryNotAvailable;
        }
        final distanceKm = calculateDistanceKm(
          position.latitude,
          position.longitude,
          venue.lat,
          venue.lng,
        );
        if (distanceKm < 1) {
          return '${(distanceKm * 1000).toInt()} ${l10n.meterUnit}';
        }
        return '${distanceKm.toStringAsFixed(1)} ${l10n.kilometerUnit}';
      },
      loading: () => '...',
      error: (_, _) => l10n.venueSummaryNotAvailable,
    );

    return SliverAppBar(
      expandedHeight: _expandedHeroHeight,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: IconButton(
        icon: _circleIcon(
          context,
          Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
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
            context,
            Icon(
              widget.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: AppTheme.errorColor,
            ),
          ),
          onPressed: () {
            ref.read(favoritesListProvider.notifier).toggle(venue.id);
          },
        ),
        IconButton(
          icon: _circleIcon(
            context,
            ref
                .watch(isInTryListProvider(venue.id))
                .when(
                  data: (inList) => Icon(
                    inList ? Icons.flag_rounded : Icons.flag_outlined,
                    color: inList
                        ? AppTheme.primaryColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  loading: () => Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  error: (_, _) => Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
          icon: _circleIcon(
            context,
            Icon(
              Icons.share_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
              shareMessage: l10n.shareVenueText,
              rating: venue.rating,
              category: venue.categories.isNotEmpty
                  ? venue.categories.first
                  : null,
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroLayout(
          context,
          venue,
          distanceText: distanceText,
        ),
      ),
    );
  }

  Widget _buildHeroLayout(
    BuildContext context,
    Venue venue, {
    required String distanceText,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: venue.photos.isNotEmpty
                ? _buildPhotoGallery(context, venue)
                : _buildHeroFallback(context),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.darkSurface.withAlpha(40),
                      AppTheme.darkSurface.withAlpha(165),
                    ],
                    stops: const [0.35, 0.62, 1],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width > 720 ? 640 : width),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: _VenueHeroInfoOverlay(
                  venue: venue,
                  displayTags: widget.displayTags,
                  distanceText: distanceText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            AppTheme.primarySurfaceColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 68,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.venue.nameAr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(226),
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outline.withAlpha(110)),
        boxShadow: const [],
      ),
      child: child,
    );
  }

  Widget _buildPhotoGallery(BuildContext context, Venue venue) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio.clamp(1.0, 2.0);
    final cacheWidth = (mediaQuery.size.width * devicePixelRatio).round();
    final cacheHeight = (_imageHeight * devicePixelRatio).round();

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
              placeholder: (_, _) => _buildHeroFallback(context),
              errorWidget: (_, _, _) => _buildHeroFallback(context),
            );
          },
        ),
        if (venue.photos.length > 1)
          Positioned(
            top: 88,
            right: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs + 1,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withAlpha(170),
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Text(
                '${_currentPage + 1}/${venue.photos.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VenueHeroInfoOverlay extends StatelessWidget {
  final Venue venue;
  final List<String> displayTags;
  final String distanceText;

  const _VenueHeroInfoOverlay({
    required this.venue,
    required this.displayTags,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final chips = <String>[
      if (venue.categories.isNotEmpty) venue.categories.first,
      ...displayTags.take(2),
      if (displayTags.length > 2) '+${displayTags.length - 2}',
    ];
    final isOpenNow = venue.isOpenNow();
    final statusText = isOpenNow == null
        ? l10n.venueSummaryNotAvailable
        : (isOpenNow ? l10n.openNow : l10n.closed);
    final priceRange = _resolvePriceRange() ?? l10n.venueSummaryNotAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          venue.nameAr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.surface,
            fontWeight: FontWeight.w800,
            shadows: const [Shadow(blurRadius: 10, color: Colors.black45)],
          ),
        ),
        if (venue.nameEn.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            venue.nameEn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.surface.withAlpha(210),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs + 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InlineMetaItem(
              text: venue.rating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              iconColor: AppTheme.warningColor,
            ),
            _metaSeparator(theme),
            Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isOpenNow == true
                    ? AppTheme.successColor.withAlpha(235)
                    : isOpenNow == false
                    ? const Color(0xFFFFC6C6)
                    : theme.colorScheme.surface.withAlpha(210),
                fontWeight: FontWeight.w700,
              ),
            ),
            _metaSeparator(theme),
            _InlineMetaItem(
              text: distanceText,
              icon: Icons.near_me_outlined,
              textColor: theme.colorScheme.surface.withAlpha(210),
              iconColor: theme.colorScheme.surface.withAlpha(210),
            ),
            _metaSeparator(theme),
            Text(
              priceRange,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.surface.withAlpha(210),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: chips
                .map((chip) => _buildChip(context, chip))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _metaSeparator(ThemeData theme) {
    return Text(
      '•',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.surface.withAlpha(180),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isCategory =
        venue.categories.isNotEmpty && label == venue.categories.first;
    final isOverflow = label.startsWith('+');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isCategory
            ? theme.colorScheme.surface.withAlpha(234)
            : theme.colorScheme.surface.withAlpha(isOverflow ? 152 : 176),
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(
          color: theme.colorScheme.surface.withAlpha(isCategory ? 110 : 70),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isCategory
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          fontWeight: isCategory ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }

  String? _resolvePriceRange() {
    final min = venue.minPrice;
    final max = venue.maxPrice;
    if (min <= 0 || max <= 0 || max < min) {
      return null;
    }
    return '$min-$max ${venue.currency}';
  }
}

class _InlineMetaItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? textColor;
  final Color? iconColor;

  const _InlineMetaItem({
    required this.text,
    required this.icon,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor ?? theme.colorScheme.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(icon, size: 14, color: iconColor ?? theme.colorScheme.surface),
      ],
    );
  }
}
